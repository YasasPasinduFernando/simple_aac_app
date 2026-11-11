import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/image_search_result.dart';
import 'card_storage_service.dart';
import 'multilingual_concept_service.dart';
import 'network_policy_service.dart';

abstract class ImageSearchProvider {
  Future<List<ImageSearchResult>> searchImages(String query, {int pageSize = 20});
  Future<String> downloadAndPersistImage(String imageUrl, {required String cardId});
}

class SearchRateLimitException implements Exception {
  final String message;
  const SearchRateLimitException([
    this.message = 'Search rate limit reached. Please wait a few seconds before searching again.',
  ]);
  @override
  String toString() => message;
}

class SearchServiceException implements Exception {
  final String message;
  const SearchServiceException(this.message);
  @override
  String toString() => message;
}

class _RankedResult {
  final int score;
  final ImageSearchResult item;

  const _RankedResult(this.score, this.item);
}

class OpenverseSearchProvider implements ImageSearchProvider {
  static const String _openverseBaseUrl = 'https://api.openverse.org/v1/images/';

  /// Required by Wikimedia REST / Commons CDN to avoid anonymous 403/429 throttling.
  static const Map<String, String> mediaHeaders = {
    'User-Agent':
        'SimpleAACApp/1.1.0 (https://github.com/YasasPasinduFernando/simple_aac_app; contact@simpleaac.org)',
  };

  static final RegExp _noiseDescriptionRegex = RegExp(
    r'disambiguation|given name|surname|politician|diplomat|senator|president|'
    r'singer|songwriter|rapper|actor|actress|footballer|cricketer|player|rugby|baseball|'
    r'airline|company|corporation|system on a chip|historian|novelist|poet|author|'
    r'city in|town in|village in|commune in|municipality|county,|railway station|somerset|'
    r'film festival|television|tv series|rock band|musical group|episode|album|song by|single by|'
    r'novel by|book by|chivalry|hurricane|tornado|damage|tabletop game|board game|video game|'
    r'idiomatic expression|foundation area|fast-food|geograph\.org',
    caseSensitive: false,
  );

  static final RegExp _noiseFilenameRegex = RegExp(
    r'(^|\W)(flag|coat_of_arms|coat of arms|logo|map|diagram|chart|signature|grave|cemetery|'
    r'damage|tornado|bridge|panorama|ceremony|festival|coin|stamp|manuscript|ruins|monument|'
    r'geograph)(\W|$)',
    caseSensitive: false,
  );

  final http.Client? _customClient;
  final bool _enableMultiSource;

  OpenverseSearchProvider([this._customClient, bool? multiSource])
      : _enableMultiSource = multiSource ?? (_customClient == null);

  http.Client get _client =>
      _customClient ?? NetworkPolicyService.instance.createGatedClient();

  @override
  Future<List<ImageSearchResult>> searchImages(
    String query, {
    int pageSize = 20,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    if (!_enableMultiSource) {
      return _searchOpenverseSingle(cleanQuery, pageSize);
    }

    var latest = <ImageSearchResult>[];
    await for (final batch in searchImagesStream(cleanQuery, pageSize: pageSize)) {
      latest = batch;
    }
    return latest;
  }

  /// Progressive async search stream: emits ranked batches as fast providers
  /// finish (~0.4-0.7s) without blocking the UI behind slower timeouts.
  Stream<List<ImageSearchResult>> searchImagesStream(
    String query, {
    int pageSize = 20,
  }) {
    final cleanQuery = query.trim();
    final controller = StreamController<List<ImageSearchResult>>();

    if (cleanQuery.isEmpty) {
      controller.add(const []);
      controller.close();
      return controller.stream;
    }

    if (!_enableMultiSource) {
      _searchOpenverseSingle(cleanQuery, pageSize).then((items) {
        if (!controller.isClosed) {
          controller.add(items);
          controller.close();
        }
      }, onError: (Object error, StackTrace stack) {
        if (!controller.isClosed) {
          controller.addError(error, stack);
          controller.close();
        }
      });
      return controller.stream;
    }

    _runStreamingMultiSource(cleanQuery, pageSize, controller);
    return controller.stream;
  }

  Future<List<ImageSearchResult>> _searchOpenverseSingle(
    String cleanQuery,
    int pageSize,
  ) async {
    final uri = Uri.parse(_openverseBaseUrl).replace(queryParameters: {
      'q': cleanQuery,
      'license': 'cc0,pdm,by',
      'mature': 'false',
      'page_size': pageSize.clamp(1, 25).toString(),
    });

    try {
      final response = await _client
          .get(uri, headers: mediaHeaders)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 429) {
        throw const SearchRateLimitException();
      }
      if (response.statusCode != 200) {
        throw SearchServiceException(
          'Openverse search returned HTTP ${response.statusCode}',
        );
      }

      final parsed = _parseOpenverseJson(utf8.decode(response.bodyBytes));
      parsed.sort((a, b) {
        if (a.isPublicDomainOrCc0 && !b.isPublicDomainOrCc0) return -1;
        if (!a.isPublicDomainOrCc0 && b.isPublicDomainOrCc0) return 1;
        return 0;
      });
      return parsed;
    } on OfflineModeException {
      rethrow;
    } on TimeoutException {
      throw const SearchServiceException(
        'Image search timed out. Please check your connection.',
      );
    } on SocketException {
      throw const SearchServiceException(
        'Could not connect to image search service.',
      );
    } catch (e) {
      if (e is SearchRateLimitException ||
          e is SearchServiceException ||
          e is OfflineModeException) {
        rethrow;
      }
      throw SearchServiceException('Failed to retrieve images: $e');
    }
  }

  Future<void> _runStreamingMultiSource(
    String rawQuery,
    int pageSize,
    StreamController<List<ImageSearchResult>> controller,
  ) async {
    var searchTerm = MultilingualConceptService.toSearchCore(rawQuery);
    final accumulated = <_RankedResult>[];

    // If Sinhala/Tamil input was outside our offline glossary, bridge via Wikipedia langlinks.
    if (!MultilingualConceptService.isLatinScript(searchTerm)) {
      try {
        final bridge = await _resolveNonLatinWikiConcept(searchTerm);
        if (controller.isClosed) return;
        if (bridge.results.isNotEmpty) {
          accumulated.addAll(bridge.results);
          controller.add(_rankAndInterleave(accumulated, pageSize));
        }
        if (bridge.englishTitle != null && bridge.englishTitle!.isNotEmpty) {
          searchTerm = MultilingualConceptService.toSearchCore(bridge.englishTitle!);
        }
      } on OfflineModeException catch (e, stack) {
        if (!controller.isClosed) {
          controller.addError(e, stack);
          await controller.close();
        }
        return;
      } catch (_) {}
    }

    if (controller.isClosed) return;

    final providers = <Future<List<_RankedResult>>>[
      _searchArasaac(searchTerm),
      _searchWikipediaTopic('simple.wikipedia.org', searchTerm, baseScore: 38),
      _searchWikipediaTopic('en.wikipedia.org', searchTerm, baseScore: 30),
      _searchWikimediaCommons(searchTerm),
      _searchOpenverseRanked(searchTerm, pageSize),
    ];

    var remaining = providers.length;
    var rateLimited = false;
    var failedCount = 0;
    OfflineModeException? offlineError;

    void finalizeProvider() {
      remaining--;
      if (remaining > 0 || controller.isClosed) return;
      if (accumulated.isEmpty) {
        if (offlineError != null) {
          controller.addError(offlineError!);
        } else if (rateLimited) {
          controller.addError(const SearchRateLimitException());
        } else if (failedCount >= 4) {
          controller.addError(
            const SearchServiceException(
              'Could not connect to image search service. Check your internet connection.',
            ),
          );
        } else {
          controller.add(const []);
        }
      }
      controller.close();
    }

    for (final future in providers) {
      future.then((batch) {
        if (!controller.isClosed && batch.isNotEmpty) {
          accumulated.addAll(batch);
          controller.add(_rankAndInterleave(accumulated, pageSize));
        }
      }).catchError((Object e) {
        if (e is OfflineModeException) {
          offlineError ??= e;
        } else if (e is SearchRateLimitException) {
          rateLimited = true;
        } else {
          failedCount++;
        }
      }).whenComplete(finalizeProvider);
    }
  }

  Future<({String? englishTitle, List<_RankedResult> results})>
      _resolveNonLatinWikiConcept(String query) async {
    final isSinhala = RegExp(r'[\u0D80-\u0DFF]').hasMatch(query);
    final host = isSinhala ? 'si.wikipedia.org' : 'ta.wikipedia.org';
    final uri = Uri.parse(
      'https://$host/w/api.php?action=query&generator=search'
      '&gsrsearch=${Uri.encodeComponent(query)}&gsrlimit=4'
      '&prop=langlinks|pageimages|description&lllang=en'
      '&piprop=thumbnail|original&pithumbsize=450&format=json',
    );

    try {
      final resp = await _client
          .get(uri, headers: mediaHeaders)
          .timeout(const Duration(seconds: 3));
      if (resp.statusCode != 200) {
        return (englishTitle: null, results: const <_RankedResult>[]);
      }

      final data = json.decode(utf8.decode(resp.bodyBytes));
      if (data is! Map<String, dynamic>) {
        return (englishTitle: null, results: const <_RankedResult>[]);
      }

      final pages = _sortedWikiPages(data);
      String? firstEn;
      final out = <_RankedResult>[];

      for (final page in pages) {
        final langlinks = page['langlinks'] as List<dynamic>?;
        final enTitle = langlinks != null && langlinks.isNotEmpty
            ? (langlinks.first as Map<String, dynamic>)['*']?.toString()
            : null;
        if (firstEn == null && enTitle != null && enTitle.isNotEmpty) {
          firstEn = enTitle;
        }

        final thumb = (page['thumbnail'] as Map<String, dynamic>?)?['source'] as String?;
        final orig = ((page['original'] as Map<String, dynamic>?)?['source'] as String?) ?? thumb ?? '';
        if (thumb == null || thumb.isEmpty || orig.toLowerCase().contains('.svg')) {
          continue;
        }
        final title = page['title']?.toString() ?? query;
        final idx = (page['index'] as num?)?.toInt() ?? 5;
        out.add(_RankedResult(
          36 - idx * 3,
          ImageSearchResult(
            id: 'wiki_${host.split('.').first}_${page['pageid'] ?? idx}',
            title: enTitle ?? title,
            imageUrl: orig,
            thumbnail: thumb,
            creator: 'Wikipedia',
            license: 'cc0',
          ),
        ));
      }

      return (englishTitle: firstEn, results: out);
    } on OfflineModeException {
      rethrow;
    } catch (_) {
      return (englishTitle: null, results: const <_RankedResult>[]);
    }
  }

  Future<List<_RankedResult>> _searchArasaac(String query) async {
    if (!MultilingualConceptService.isLatinScript(query)) return const [];
    final uri = Uri.parse(
      'https://api.arasaac.org/v1/pictograms/en/search/${Uri.encodeComponent(query)}',
    );
    final resp = await _client
        .get(uri, headers: mediaHeaders)
        .timeout(const Duration(seconds: 4));

    if (resp.statusCode == 404) return const [];
    if (resp.statusCode == 429) throw const SearchRateLimitException();
    if (resp.statusCode != 200) {
      throw SearchServiceException('ARASAAC HTTP ${resp.statusCode}');
    }

    final decoded = json.decode(utf8.decode(resp.bodyBytes));
    if (decoded is! List) return const [];

    final tokens = _extractTokens(query);
    final lowerQuery = query.toLowerCase();
    final results = <_RankedResult>[];

    for (var i = 0; i < decoded.length && i < 16; i++) {
      final raw = decoded[i];
      if (raw is! Map<String, dynamic>) continue;
      final pid = raw['_id']?.toString() ?? '';
      if (pid.isEmpty) continue;

      final kwList = (raw['keywords'] as List<dynamic>? ?? [])
          .map((e) => (e as Map<String, dynamic>)['keyword']?.toString().trim() ?? '')
          .where((k) => k.isNotEmpty)
          .toList();

      if (kwList.isEmpty || !_keywordsMatchTokens(kwList, tokens)) continue;

      final isAac = raw['aac'] == true;
      final hasExact = kwList.any((k) => k.toLowerCase() == lowerQuery);
      final hasWordTokenMatch = kwList.any(
        (k) => tokens.any((tok) => RegExp(r'\b' + RegExp.escape(tok) + r'\b', caseSensitive: false).hasMatch(k)),
      );
      if (!hasWordTokenMatch) continue;

      final url = 'https://static.arasaac.org/pictograms/$pid/${pid}_500.png';
      final score = 38 - i * 3 + (isAac ? 14 : 0) + (hasExact ? 22 : 0);

      results.add(_RankedResult(
        score,
        ImageSearchResult(
          id: 'arasaac_$pid',
          title: '${kwList.take(2).join(', ')} (AAC Symbol)',
          imageUrl: url,
          thumbnail: url,
          creator: 'ARASAAC',
          license: 'cc-by-nc-sa',
        ),
      ));
    }

    return results;
  }

  Future<List<_RankedResult>> _searchWikipediaTopic(
    String host,
    String query, {
    required int baseScore,
  }) async {
    final uri = Uri.parse(
      'https://$host/w/api.php?action=query&generator=search'
      '&gsrsearch=${Uri.encodeComponent(query)}&gsrlimit=6'
      '&prop=pageimages|description&piprop=thumbnail|original&pithumbsize=450&format=json',
    );
    final resp = await _client
        .get(uri, headers: mediaHeaders)
        .timeout(const Duration(seconds: 4));

    if (resp.statusCode == 429) throw const SearchRateLimitException();
    if (resp.statusCode != 200) {
      throw SearchServiceException('Wikipedia HTTP ${resp.statusCode}');
    }

    final data = json.decode(utf8.decode(resp.bodyBytes));
    if (data is! Map<String, dynamic>) return const [];

    final tokens = _extractTokens(query);
    final lowerQuery = query.toLowerCase();
    final pages = _sortedWikiPages(data);
    final out = <_RankedResult>[];

    for (final page in pages) {
      final thumb = (page['thumbnail'] as Map<String, dynamic>?)?['source'] as String?;
      final orig = ((page['original'] as Map<String, dynamic>?)?['source'] as String?) ?? thumb ?? '';
      if (thumb == null || thumb.isEmpty) continue;

      // Skip vector diagrams/logos on Wikipedia when looking for clear photo thumbnails.
      if (!_isSupportedRasterUrl(orig) || _isNoisyTitle(orig, query)) continue;

      final title = page['title']?.toString() ?? '';
      final desc = page['description']?.toString() ?? '';
      if (_isNoisyTopic(title, desc, query)) continue;

      final idx = (page['index'] as num?)?.toInt() ?? 8;
      final lowerTitle = title.toLowerCase();
      var score = baseScore - idx * 3;
      if (lowerTitle == lowerQuery) {
        score += 28;
      } else if (tokens.any((t) => lowerTitle.contains(t))) {
        score += 12;
      }

      out.add(_RankedResult(
        score,
        ImageSearchResult(
          id: 'wiki_${host.split('.').first}_${page['pageid'] ?? idx}',
          title: desc.isEmpty ? title : '$title — $desc',
          imageUrl: orig,
          thumbnail: thumb,
          creator: 'Wikipedia',
          license: 'cc0',
        ),
      ));
    }

    return out;
  }

  Future<List<_RankedResult>> _searchWikimediaCommons(String query) async {
    final searchQuery =
        '$query filetype:bitmap -intitle:flag -intitle:logo -intitle:coat -intitle:map';
    final uri = Uri.parse(
      'https://commons.wikimedia.org/w/api.php?action=query&generator=search'
      '&gsrnamespace=6&gsrsearch=${Uri.encodeComponent(searchQuery)}&gsrlimit=12'
      '&prop=imageinfo&iiprop=url|mime|thumburl&iiurlwidth=450&format=json',
    );
    final resp = await _client
        .get(uri, headers: mediaHeaders)
        .timeout(const Duration(seconds: 5));

    if (resp.statusCode == 429) throw const SearchRateLimitException();
    if (resp.statusCode != 200) {
      throw SearchServiceException('Commons HTTP ${resp.statusCode}');
    }

    final data = json.decode(utf8.decode(resp.bodyBytes));
    if (data is! Map<String, dynamic>) return const [];

    const allowedMimes = {'image/jpeg', 'image/png', 'image/webp'};
    final tokens = _extractTokens(query);
    final pages = _sortedWikiPages(data);
    final out = <_RankedResult>[];

    for (final page in pages) {
      final infoList = page['imageinfo'] as List<dynamic>?;
      if (infoList == null || infoList.isEmpty) continue;
      final info = infoList.first as Map<String, dynamic>? ?? {};

      final mime = (info['mime'] as String? ?? '').toLowerCase();
      final fullUrl = info['url'] as String? ?? '';
      final thumbUrl = info['thumburl'] as String? ?? fullUrl;
      if (!allowedMimes.contains(mime) || !_isSupportedRasterUrl(fullUrl) || thumbUrl.isEmpty) {
        continue;
      }

      final cleanTitle = (page['title']?.toString() ?? '')
          .replaceFirst(RegExp(r'^File:\s*', caseSensitive: false), '')
          .replaceAll('_', ' ');
      if (_isNoisyTitle(cleanTitle, query) || _isNoisyTopic(cleanTitle, '', query)) {
        continue;
      }

      final idx = (page['index'] as num?)?.toInt() ?? 10;
      final lowerTitle = cleanTitle.toLowerCase();
      final tokenMatch = tokens.any((t) => lowerTitle.contains(t));
      final score = 22 - idx * 2 + (tokenMatch ? 14 : 0);

      out.add(_RankedResult(
        score,
        ImageSearchResult(
          id: 'commons_${page['pageid'] ?? idx}',
          title: cleanTitle.isEmpty ? query : cleanTitle,
          imageUrl: fullUrl,
          thumbnail: thumbUrl,
          creator: 'Wikimedia Commons',
          license: 'cc0',
        ),
      ));
    }

    return out;
  }

  Future<List<_RankedResult>> _searchOpenverseRanked(String query, int pageSize) async {
    final uri = Uri.parse(_openverseBaseUrl).replace(queryParameters: {
      'q': query,
      'license': 'cc0,pdm,by',
      'mature': 'false',
      'page_size': pageSize.clamp(1, 20).toString(),
    });
    // Short timeout so live Openverse stalls never slow down Wikipedia/ARASAAC/Commons.
    final resp = await _client
        .get(uri, headers: mediaHeaders)
        .timeout(const Duration(milliseconds: 2500));

    if (resp.statusCode == 429) throw const SearchRateLimitException();
    if (resp.statusCode != 200) return const [];

    final items = _parseOpenverseJson(utf8.decode(resp.bodyBytes));
    final out = <_RankedResult>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      out.add(_RankedResult(
        38 - i * 2 + (item.isPublicDomainOrCc0 ? 6 : 0),
        item,
      ));
    }
    return out;
  }

  List<ImageSearchResult> _parseOpenverseJson(String body) {
    final data = json.decode(body);
    if (data is! Map<String, dynamic> || !data.containsKey('results')) {
      return [];
    }
    final resultsList = data['results'] as List<dynamic>? ?? [];
    return resultsList
        .map((item) => ImageSearchResult.fromJson(item as Map<String, dynamic>))
        .where((item) =>
            item.imageUrl.isNotEmpty &&
            item.thumbnail.isNotEmpty &&
            _isSupportedRasterUrl(item.imageUrl))
        .toList();
  }

  List<Map<String, dynamic>> _sortedWikiPages(Map<String, dynamic> data) {
    final queryMap = data['query'] as Map<String, dynamic>? ?? {};
    final pagesMap = queryMap['pages'] as Map<String, dynamic>? ?? {};
    final list = pagesMap.values.whereType<Map<String, dynamic>>().toList();
    list.sort((a, b) {
      final ia = (a['index'] as num?)?.toInt() ?? 9999;
      final ib = (b['index'] as num?)?.toInt() ?? 9999;
      return ia.compareTo(ib);
    });
    return list;
  }

  List<_RankedResult> _dedupSorted(List<_RankedResult> list) {
    final sorted = list.toList()..sort((a, b) => b.score.compareTo(a.score));
    final seen = <String>{};
    final out = <_RankedResult>[];
    for (final entry in sorted) {
      final key = _mediaDedupKey(entry.item);
      if (seen.add(key)) {
        out.add(entry);
      }
    }
    return out;
  }

  List<ImageSearchResult> _rankAndInterleave(
    List<_RankedResult> candidates,
    int pageSize,
  ) {
    final symbols = _dedupSorted(candidates.where((c) => c.item.isSymbol).toList());
    final photos = _dedupSorted(candidates.where((c) => !c.item.isSymbol).toList());

    final out = <ImageSearchResult>[];
    var pi = 0;
    var si = 0;
    final topPhotoStrong = photos.isNotEmpty && photos.first.score >= 42;

    while ((pi < photos.length || si < symbols.length) && out.length < pageSize) {
      if (topPhotoStrong) {
        if (pi < photos.length) out.add(photos[pi++].item);
        if (si < symbols.length && out.length < pageSize) out.add(symbols[si++].item);
      } else {
        if (si < symbols.length) out.add(symbols[si++].item);
        if (pi < photos.length && out.length < pageSize) out.add(photos[pi++].item);
      }
    }

    return out;
  }

  String _mediaDedupKey(ImageSearchResult item) {
    if (item.id.startsWith('arasaac_')) return item.id;
    final pathOnly = item.imageUrl.split('?').first;
    final fileName = Uri.decodeComponent(pathOnly.split('/').last)
        .replaceFirst(RegExp(r'^\d+px-'), '')
        .toLowerCase();
    return fileName.isNotEmpty ? fileName : pathOnly.toLowerCase();
  }

  List<String> _extractTokens(String query) {
    return RegExp(r'[a-zA-Z]+')
        .allMatches(query.toLowerCase())
        .map((m) => m.group(0)!)
        .where((w) => w.length >= 2)
        .toList();
  }

  bool _keywordsMatchTokens(List<String> keywords, List<String> tokens) {
    if (tokens.isEmpty) return true;
    for (final kw in keywords) {
      final lower = kw.toLowerCase();
      for (final tok in tokens) {
        if (lower.contains(tok)) return true;
      }
    }
    return false;
  }

  bool _isNoisyTopic(String title, String description, String rawQuery) {
    final qLower = rawQuery.toLowerCase();
    // Respect explicit searches for places/people/media if user asked for them.
    if (qLower.contains('city') || qLower.contains('film') || qLower.contains('singer')) {
      return false;
    }
    return _noiseDescriptionRegex.hasMatch(title) ||
        _noiseDescriptionRegex.hasMatch(description);
  }

  bool _isNoisyTitle(String text, String rawQuery) {
    final qLower = rawQuery.toLowerCase();
    if (qLower.contains('flag') || qLower.contains('map') || qLower.contains('bridge')) {
      return false;
    }
    return _noiseFilenameRegex.hasMatch(text);
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

  @override
  Future<String> downloadAndPersistImage(
    String imageUrl, {
    required String cardId,
  }) async {
    final uri = Uri.parse(imageUrl);
    try {
      final response = await _client
          .get(uri, headers: mediaHeaders)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw SearchServiceException(
          'Image download failed with status ${response.statusCode}',
        );
      }

      final tempDir = await getTemporaryDirectory();
      final ext = _resolveExtension(response.headers['content-type'], imageUrl);
      final tempFile = File(
        '${tempDir.path}/temp_dl_${cardId}_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await tempFile.writeAsBytes(response.bodyBytes);

      final permanentPath = await CardStorageService.persistMediaFile(
        tempFile.path,
        cardId: cardId,
        mediaType: 'images',
      );

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      debugPrint(
        '[OpenverseSearchProvider] Image downloaded and persisted permanently to: $permanentPath',
      );
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
