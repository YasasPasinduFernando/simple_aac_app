import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/image_search_result.dart';
import 'card_storage_service.dart';
import 'network_policy_service.dart';

abstract class ImageSearchProvider {
  Future<List<ImageSearchResult>> searchImages(String query, {int pageSize = 12});
  Future<String> downloadAndPersistImage(String imageUrl, {required String cardId});
}

class SearchRateLimitException implements Exception {
  final String message;
  const SearchRateLimitException([this.message = 'Search rate limit reached. Please wait a few seconds before searching again.']);
  @override
  String toString() => message;
}

class SearchServiceException implements Exception {
  final String message;
  const SearchServiceException(this.message);
  @override
  String toString() => message;
}

class OpenverseSearchProvider implements ImageSearchProvider {
  static const String _baseUrl = 'https://api.openverse.org/v1/images/';

  final http.Client? _customClient;

  OpenverseSearchProvider([this._customClient]);

  http.Client get _client =>
      _customClient ?? NetworkPolicyService.instance.createGatedClient();

  @override
  Future<List<ImageSearchResult>> searchImages(String query, {int pageSize = 12}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // Official Openverse parameters:
    // license: comma-separated list. We prioritize cc0, pdm (Public Domain) and by.
    // mature: false (Child safe filter)
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': cleanQuery,
      'license': 'cc0,pdm,by',
      'mature': 'false',
      'page_size': pageSize.clamp(1, 25).toString(),
    });

    try {
      final headers = {
        'User-Agent': 'SimpleAACApp/1.1.0 (https://github.com/YasasPasinduFernando/simple_aac_app; contact@simpleaac.org)',
      };
      final timeoutDuration = _customClient == null
          ? const Duration(seconds: 5)
          : const Duration(seconds: 15);
      final response = await _client.get(uri, headers: headers).timeout(timeoutDuration);

      if (response.statusCode == 429) {
        throw const SearchRateLimitException();
      }

      if (response.statusCode != 200) {
        if (_customClient == null) {
          return await _searchWikimediaCommonsFallback(cleanQuery, pageSize);
        }
        throw SearchServiceException('Openverse search returned HTTP ${response.statusCode}');
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic> || !data.containsKey('results')) {
        return [];
      }

      final resultsList = data['results'] as List<dynamic>? ?? [];
      final results = resultsList
          .map((item) => ImageSearchResult.fromJson(item as Map<String, dynamic>))
          .where((item) =>
              item.imageUrl.isNotEmpty &&
              item.thumbnail.isNotEmpty &&
              _isSupportedRasterUrl(item.imageUrl))
          .toList();

      // Rank results: Prioritize CC0 / Public Domain first for child AAC cards
      results.sort((a, b) {
        if (a.isPublicDomainOrCc0 && !b.isPublicDomainOrCc0) return -1;
        if (!a.isPublicDomainOrCc0 && b.isPublicDomainOrCc0) return 1;
        return 0;
      });

      if (results.isEmpty && _customClient == null) {
        return await _searchWikimediaCommonsFallback(cleanQuery, pageSize);
      }

      return results;
    } on OfflineModeException {
      rethrow;
    } on TimeoutException {
      if (_customClient == null) {
        try {
          return await _searchWikimediaCommonsFallback(cleanQuery, pageSize);
        } catch (_) {
          throw const SearchServiceException('Image search timed out. Please check your connection.');
        }
      }
      throw const SearchServiceException('Image search timed out. Please check your connection.');
    } on SocketException {
      if (_customClient == null) {
        try {
          return await _searchWikimediaCommonsFallback(cleanQuery, pageSize);
        } catch (_) {
          throw const SearchServiceException('Could not connect to image search service.');
        }
      }
      throw const SearchServiceException('Could not connect to image search service.');
    } catch (e) {
      if (e is SearchRateLimitException || e is SearchServiceException || e is OfflineModeException) {
        rethrow;
      }
      if (_customClient == null) {
        try {
          return await _searchWikimediaCommonsFallback(cleanQuery, pageSize);
        } catch (_) {}
      }
      throw SearchServiceException('Failed to retrieve images: $e');
    }
  }

  bool _isSupportedRasterUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return !lower.endsWith('.svg') &&
        !lower.endsWith('.tif') &&
        !lower.endsWith('.tiff') &&
        !lower.endsWith('.djvu') &&
        !lower.endsWith('.pdf') &&
        !lower.endsWith('.ogg') &&
        !lower.endsWith('.mp3') &&
        !lower.endsWith('.webm');
  }

  /// High-reliability public domain / CC0 educational image search fallback
  /// via Wikimedia Commons API.
  Future<List<ImageSearchResult>> _searchWikimediaCommonsFallback(String query, int pageSize) async {
    final wikiUri = Uri.parse(
      'https://commons.wikimedia.org/w/api.php?action=query&generator=search'
      '&gsrnamespace=6&gsrsearch=${Uri.encodeComponent(query)}&gsrlimit=${(pageSize * 2).clamp(1, 30)}'
      '&prop=imageinfo&iiprop=url|mime|thumburl&iiurlwidth=400&format=json',
    );

    final headers = {
      'User-Agent': 'SimpleAACApp/1.1.0 (https://github.com/YasasPasinduFernando/simple_aac_app; contact@simpleaac.org)',
    };

    final resp = await _client.get(wikiUri, headers: headers).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw SearchServiceException('Image search provider returned HTTP ${resp.statusCode}');
    }

    final data = json.decode(utf8.decode(resp.bodyBytes));
    if (data is! Map<String, dynamic> || !data.containsKey('query')) {
      return [];
    }

    final queryMap = data['query'] as Map<String, dynamic>? ?? {};
    final pagesMap = queryMap['pages'] as Map<String, dynamic>? ?? {};
    final results = <ImageSearchResult>[];

    const allowedMimes = {'image/jpeg', 'image/png', 'image/webp'};

    for (final entry in pagesMap.entries) {
      final page = entry.value as Map<String, dynamic>? ?? {};
      final rawTitle = page['title'] as String? ?? '';
      final infoList = page['imageinfo'] as List<dynamic>?;
      if (infoList == null || infoList.isEmpty) continue;

      final info = infoList.first as Map<String, dynamic>? ?? {};
      final mime = (info['mime'] as String? ?? '').toLowerCase();
      final fullUrl = info['url'] as String? ?? '';
      final thumbUrl = info['thumburl'] as String? ?? fullUrl;

      // Reject document scans (.djvu, .pdf, .tiff), vector SVGs, and audio/video.
      if (!allowedMimes.contains(mime) || !_isSupportedRasterUrl(fullUrl)) {
        continue;
      }

      final cleanTitle = rawTitle.replaceFirst(RegExp(r'^File:\s*', caseSensitive: false), '').replaceAll('_', ' ');

      if (thumbUrl.isNotEmpty) {
        results.add(ImageSearchResult(
          id: page['pageid']?.toString() ?? entry.key,
          title: cleanTitle.isEmpty ? query : cleanTitle,
          imageUrl: fullUrl,
          thumbnail: thumbUrl,
          creator: 'Wikimedia Commons',
          license: 'cc0',
        ));
      }
      if (results.length >= pageSize) break;
    }

    return results;
  }

  @override
  Future<String> downloadAndPersistImage(String imageUrl, {required String cardId}) async {
    final uri = Uri.parse(imageUrl);
    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw SearchServiceException('Image download failed with status ${response.statusCode}');
      }

      // Write temporarily to cache
      final tempDir = await getTemporaryDirectory();
      final ext = _resolveExtension(response.headers['content-type'], imageUrl);
      final tempFile = File('${tempDir.path}/temp_dl_${cardId}_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Persist permanently into app storage
      final permanentPath = await CardStorageService.persistMediaFile(
        tempFile.path,
        cardId: cardId,
        mediaType: 'images',
      );

      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      debugPrint('[OpenverseSearchProvider] Image downloaded and persisted permanently to: $permanentPath');
      return permanentPath;
    } on OfflineModeException {
      rethrow;
    } on TimeoutException {
      throw const SearchServiceException('Image download timed out.');
    } catch (e) {
      if (e is OfflineModeException || e is SearchServiceException) rethrow;
      throw SearchServiceException('Failed to download image: $e');
    }
  }

  String _resolveExtension(String? contentType, String url) {
    if (contentType != null) {
      if (contentType.contains('png')) return 'png';
      if (contentType.contains('jpeg') || contentType.contains('jpg')) return 'jpg';
      if (contentType.contains('webp')) return 'webp';
    }
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.png')) return 'png';
    if (lowerUrl.endsWith('.webp')) return 'webp';
    return 'jpg';
  }
}
