import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/aac_card_model.dart';

class CardStorageService {
  static const int defaultCatalogVersion = 5;

  static const String _cardsFileName = 'aac_cards_v1.json';
  static const String _cardsBackupFileName = 'aac_cards_v1.json.bak';
  static const String _legacyCardsKey = 'cards';
  static const String _hasSeededDefaultsKey = 'hasSeededDefaultCards';
  static const String _seededDefaultVersionKey = 'seededDefaultCardsVersion';

  static String _join(String parent, String child) {
    return '$parent${Platform.pathSeparator}$child';
  }

  static Future<File> _cardsFile(Directory docsDir) async {
    return File(_join(docsDir.path, _cardsFileName));
  }

  static Future<File> _cardsBackupFile(Directory docsDir) async {
    return File(_join(docsDir.path, _cardsBackupFileName));
  }

  static int countCards(List<AACCard> cards) {
    var count = 0;
    for (final card in cards) {
      count++;
      count += countCards(card.subCards);
    }
    return count;
  }

  static AACCard _cloneCard(AACCard card) {
    return AACCard.fromJson(card.toJson());
  }

  static Future<List<AACCard>> loadCards({
    required List<AACCard> defaultCards,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final docsDir = await getApplicationDocumentsDirectory();
    final file = await _cardsFile(docsDir);
    final backupFile = await _cardsBackupFile(docsDir);
    final hasSeeded = prefs.getBool(_hasSeededDefaultsKey) ?? false;
    final seededVersion = prefs.getInt(_seededDefaultVersionKey);

    debugPrint(
      '[CardStorage] startup init: docs=${docsDir.path}, '
      'cardsFile=${file.path}, exists=${await file.exists()}, '
      'backupExists=${await backupFile.exists()}, '
      'hasSeeded=$hasSeeded, seededVersion=$seededVersion',
    );

    final primaryCards = await _readCardsFile(file, source: 'primary');
    if (primaryCards != null) {
      final cards = await _applyDefaultCatalogMigration(
        primaryCards,
        defaultCards,
        prefs,
        file,
        backupFile,
      );
      final seedCatalogChanged = _normalizeSeedCatalog(
        cards,
        defaultCards,
      );
      final mediaChanged = await _migrateMediaFilesToDocuments(cards);
      if (seedCatalogChanged || mediaChanged) {
        await _writeCardsFile(file, backupFile, cards);
      }
      await _markSeeded(prefs);
      await _syncLegacyCards(prefs, cards);
      debugPrint(
        '[CardStorage] loaded ${cards.length} top-level cards '
        '(${countCards(cards)} total) from ${file.path}',
      );
      return cards;
    }

    final backupCards = await _readCardsFile(backupFile, source: 'backup');
    if (backupCards != null) {
      _mergeMissingDefaults(backupCards, defaultCards);
      _normalizeSeedCatalog(backupCards, defaultCards);
      await _migrateMediaFilesToDocuments(backupCards);
      await _writeCardsFile(file, backupFile, backupCards);
      await _markSeeded(prefs);
      await _syncLegacyCards(prefs, backupCards);
      debugPrint(
        '[CardStorage] recovered ${backupCards.length} top-level cards '
        '(${countCards(backupCards)} total) from backup',
      );
      return backupCards;
    }

    final legacyCards = _readLegacyPrefsCards(prefs);
    if (legacyCards != null) {
      _mergeMissingDefaults(legacyCards, defaultCards);
      _normalizeSeedCatalog(legacyCards, defaultCards);
      await _migrateMediaFilesToDocuments(legacyCards);
      await _writeCardsFile(file, backupFile, legacyCards);
      await _markSeeded(prefs);
      await _syncLegacyCards(prefs, legacyCards);
      debugPrint(
        '[CardStorage] migrated ${legacyCards.length} top-level cards '
        '(${countCards(legacyCards)} total) from SharedPreferences key '
        '"$_legacyCardsKey" to ${file.path}',
      );
      return legacyCards;
    }

    if (hasSeeded) {
      debugPrint(
        '[CardStorage] defaults were already seeded but no card store was '
        'found; returning an empty list instead of reseeding defaults',
      );
      const emptyCards = <AACCard>[];
      await _writeCardsFile(file, backupFile, emptyCards);
      await _syncLegacyCards(prefs, emptyCards);
      return emptyCards;
    }

    final seededCards = defaultCards.map(_cloneCard).toList();
    await _writeCardsFile(file, backupFile, seededCards);
    await _markSeeded(prefs);
    await _syncLegacyCards(prefs, seededCards);
    debugPrint(
      '[CardStorage] first launch seed wrote ${seededCards.length} '
      'top-level cards (${countCards(seededCards)} total) to ${file.path}',
    );
    return seededCards;
  }

  static Future<void> saveCards(List<AACCard> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final docsDir = await getApplicationDocumentsDirectory();
    final file = await _cardsFile(docsDir);
    final backupFile = await _cardsBackupFile(docsDir);

    debugPrint(
      '[CardStorage] saving ${cards.length} top-level cards '
      '(${countCards(cards)} total) to ${file.path}',
    );

    await _migrateMediaFilesToDocuments(cards);
    await _writeCardsFile(file, backupFile, cards);
    await _markSeeded(prefs);
    await _syncLegacyCards(prefs, cards);

    debugPrint('[CardStorage] save complete: ${file.path}');
  }

  static Future<Directory> mediaDirectory(String mediaType) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final mediaDir =
        Directory(_join(_join(docsDir.path, 'aac_media'), mediaType));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  static Future<String> persistMediaFile(
    String sourcePath, {
    required String cardId,
    required String mediaType,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source media file not found', sourcePath);
    }

    final docsDir = await getApplicationDocumentsDirectory();
    if (_isInsideDirectory(sourcePath, docsDir.path)) {
      debugPrint(
        '[CardStorage] $mediaType file already in app documents: $sourcePath',
      );
      return sourcePath;
    }

    final mediaDir = await mediaDirectory(mediaType);
    final safeId = _safeFileComponent(cardId);
    final extension =
        _extension(sourcePath, fallback: mediaType == 'images' ? '.jpg' : '');
    final fileName =
        '${mediaType}_${safeId}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetPath = _join(mediaDir.path, fileName);

    await sourceFile.copy(targetPath);
    debugPrint(
      '[CardStorage] persisted $mediaType file: source=$sourcePath, '
      'target=$targetPath',
    );
    return targetPath;
  }

  static Future<bool> _migrateMediaFilesToDocuments(
    List<AACCard> cards,
  ) async {
    var changed = false;
    for (final card in cards) {
      changed = await _migrateCardMediaFiles(card) || changed;
    }
    if (changed) {
      debugPrint('[CardStorage] migrated media paths into app documents');
    }
    return changed;
  }

  static bool _normalizeSeedCatalog(
    List<AACCard> cards,
    List<AACCard> defaultCards,
  ) {
    if (defaultCards.isEmpty) return false;

    final defaultsById = _indexDefaultsById(defaultCards);
    var changed = _migrateDeprecatedSeedCards(cards, defaultsById);
    changed = _normalizeKnownSeedCards(cards, defaultsById) || changed;
    return changed;
  }

  static Map<String, AACCard> _indexDefaultsById(List<AACCard> defaultCards) {
    final indexed = <String, AACCard>{};

    void visit(AACCard card) {
      indexed[card.id] = card;
      for (final subCard in card.subCards) {
        visit(subCard);
      }
    }

    for (final card in defaultCards) {
      visit(card);
    }
    return indexed;
  }

  static bool _migrateDeprecatedSeedCards(
    List<AACCard> cards,
    Map<String, AACCard> defaultsById,
  ) {
    final more = _findDirectChild(cards, 'seed_more');
    if (more == null) {
      final removedRotation =
          _removeDirectChild(cards, 'seed_rotation_turn_change') != null;
      final removedBlocks =
          _removeDirectChild(cards, 'seed_blocks_toys_play') != null;
      if (removedRotation || removedBlocks) {
        debugPrint(
          '[CardStorage] removed deprecated seed cards without reseeding More',
        );
      }
      return removedRotation || removedBlocks;
    }

    var changed = false;
    changed = _replaceDeprecatedSeed(
          cards,
          more,
          deprecatedId: 'seed_rotation_turn_change',
          replacement: defaultsById['seed_good'],
        ) ||
        changed;
    changed = _replaceDeprecatedSeed(
          cards,
          more,
          deprecatedId: 'seed_blocks_toys_play',
          replacement: defaultsById['seed_play'],
        ) ||
        changed;
    changed = _moveTopLevelSeedUnderMore(
          cards,
          more,
          seedId: 'seed_good',
        ) ||
        changed;
    changed = _moveTopLevelSeedUnderMore(
          cards,
          more,
          seedId: 'seed_play',
        ) ||
        changed;
    return changed;
  }

  static bool _replaceDeprecatedSeed(
    List<AACCard> cards,
    AACCard more, {
    required String deprecatedId,
    required AACCard? replacement,
  }) {
    final removed = _removeDirectChild(cards, deprecatedId);
    if (removed == null) return false;

    if (replacement != null &&
        _findDirectChild(more.subCards, replacement.id) == null) {
      more.subCards.add(_cloneCard(replacement));
    }
    debugPrint(
      '[CardStorage] removed deprecated seed card $deprecatedId '
      'and migrated it to ${replacement?.id ?? 'no replacement'}',
    );
    return true;
  }

  static bool _moveTopLevelSeedUnderMore(
    List<AACCard> cards,
    AACCard more, {
    required String seedId,
  }) {
    final stray = _removeDirectChild(cards, seedId);
    if (stray == null) return false;

    if (_findDirectChild(more.subCards, seedId) == null) {
      more.subCards.add(stray);
      debugPrint('[CardStorage] moved $seedId under seed_more');
    } else {
      debugPrint('[CardStorage] removed duplicate top-level $seedId');
    }
    return true;
  }

  static AACCard? _removeDirectChild(List<AACCard> cards, String id) {
    for (var i = 0; i < cards.length; i++) {
      if (cards[i].id == id) {
        return cards.removeAt(i);
      }
    }
    return null;
  }

  static bool _normalizeKnownSeedCards(
    List<AACCard> cards,
    Map<String, AACCard> defaultsById,
  ) {
    var changed = false;
    for (final card in cards) {
      final defaultCard = defaultsById[card.id];
      if (defaultCard != null) {
        changed = _normalizeSeedCardData(card, defaultCard) || changed;
      }
      changed =
          _normalizeKnownSeedCards(card.subCards, defaultsById) || changed;
    }
    return changed;
  }

  static bool _normalizeSeedCardData(AACCard card, AACCard defaultCard) {
    var changed = false;

    if (_shouldRefreshSeedText(
        card.id, 'label', card.label, defaultCard.label)) {
      card.label = defaultCard.label;
      changed = true;
    }
    if (_shouldRefreshSeedText(
      card.id,
      'labelSinhala',
      card.labelSinhala,
      defaultCard.labelSinhala,
      localized: true,
    )) {
      card.labelSinhala = defaultCard.labelSinhala;
      changed = true;
    }
    if (_shouldRefreshSeedText(
      card.id,
      'labelTamil',
      card.labelTamil,
      defaultCard.labelTamil,
      localized: true,
    )) {
      card.labelTamil = defaultCard.labelTamil;
      changed = true;
    }

    if (_shouldRefreshSeedImage(card.imagePath, defaultCard.imagePath)) {
      card.imagePath = defaultCard.imagePath;
      changed = true;
      debugPrint(
        '[CardStorage] refreshed bundled seed image path for ${card.id}',
      );
    }

    if (card.id == 'seed_more' && card.type != defaultCard.type) {
      card.type = defaultCard.type;
      changed = true;
      debugPrint('[CardStorage] normalized seed_more as folder navigation');
    }

    if (defaultCard.subCards.isNotEmpty) {
      changed =
          _mergeMissingDefaults(card.subCards, defaultCard.subCards) || changed;
    }

    if (changed) {
      debugPrint('[CardStorage] normalized seed data for ${card.id}');
    }
    return changed;
  }

  static bool _shouldRefreshSeedText(
    String cardId,
    String field,
    String? current,
    String? desired, {
    bool localized = false,
  }) {
    if (desired == null || desired.isEmpty) return false;

    final value = current?.trim() ?? '';
    if (value.isEmpty) return true;
    if (value == desired) return false;
    if (_previousSeedTextValues(cardId, field).contains(value)) return true;
    if (localized && _looksCorruptLocalizedText(value)) return true;
    return false;
  }

  static bool _shouldRefreshSeedImage(
    String? current,
    String? desired,
  ) {
    if (desired == null || desired.isEmpty) return false;
    if (current == null || current.isEmpty) return true;
    if (current == desired) return false;
    return isAssetImagePath(current);
  }

  static Set<String> _previousSeedTextValues(String cardId, String field) {
    if (field == 'label') {
      return switch (cardId) {
        'seed_sad' => {'sad'},
        'seed_good' => {'Rotation/Turn/Change'},
        'seed_play' => {'Blocks/Toys/Play'},
        _ => const <String>{},
      };
    }
    return const <String>{};
  }

  static bool _looksCorruptLocalizedText(String value) {
    return value.contains('?') ||
        value.runes.any(
          (codePoint) =>
              codePoint == 0x00C3 ||
              codePoint == 0x00C2 ||
              codePoint == 0x00E0 ||
              codePoint == 0xFFFD,
        );
  }

  static Future<bool> _migrateCardMediaFiles(AACCard card) async {
    var changed = false;

    final imagePath = await _migrateOneMediaPath(
      card.imagePath,
      cardId: card.id,
      mediaType: 'images',
    );
    if (imagePath != card.imagePath) {
      card.imagePath = imagePath;
      changed = true;
    }

    final voicePath = await _migrateOneMediaPath(
      card.voicePath,
      cardId: card.id,
      mediaType: 'voices',
    );
    if (voicePath != card.voicePath) {
      card.voicePath = voicePath;
      changed = true;
    }

    for (final subCard in card.subCards) {
      changed = await _migrateCardMediaFiles(subCard) || changed;
    }
    return changed;
  }

  static Future<String?> _migrateOneMediaPath(
    String? sourcePath, {
    required String cardId,
    required String mediaType,
  }) async {
    if (sourcePath == null || sourcePath.isEmpty) return sourcePath;
    if (isAssetImagePath(sourcePath)) {
      debugPrint(
        '[CardStorage] media path is bundled asset: '
        'cardId=$cardId, type=$mediaType, path=$sourcePath',
      );
      return sourcePath;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    if (_isInsideDirectory(sourcePath, docsDir.path)) {
      debugPrint(
        '[CardStorage] media path already permanent: '
        'cardId=$cardId, type=$mediaType, path=$sourcePath',
      );
      return sourcePath;
    }

    if (!await File(sourcePath).exists()) {
      debugPrint(
        '[CardStorage] media path is outside documents and missing: '
        'cardId=$cardId, type=$mediaType, path=$sourcePath',
      );
      return sourcePath;
    }

    return persistMediaFile(
      sourcePath,
      cardId: cardId,
      mediaType: mediaType,
    );
  }

  static Future<List<AACCard>?> _readCardsFile(
    File file, {
    required String source,
  }) async {
    if (!await file.exists()) return null;
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        debugPrint('[CardStorage] $source card file is empty: ${file.path}');
        return <AACCard>[];
      }

      final decoded = jsonDecode(raw);
      final List<dynamic> cardJson;
      if (decoded is List) {
        cardJson = decoded;
      } else if (decoded is Map && decoded['cards'] is List) {
        cardJson = decoded['cards'] as List<dynamic>;
      } else {
        throw const FormatException('Unexpected card storage shape');
      }

      final cards = cardJson
          .whereType<Map>()
          .map((card) => AACCard.fromJson(Map<String, dynamic>.from(card)))
          .toList();
      debugPrint(
        '[CardStorage] decoded ${cards.length} top-level cards '
        '(${countCards(cards)} total) from $source file ${file.path}',
      );
      return cards;
    } catch (error, stackTrace) {
      debugPrint(
        '[CardStorage] failed to read $source card file ${file.path}: $error',
      );
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  static List<AACCard>? _readLegacyPrefsCards(SharedPreferences prefs) {
    final raw = prefs.getString(_legacyCardsKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      final cards = decoded
          .whereType<Map>()
          .map((card) => AACCard.fromJson(Map<String, dynamic>.from(card)))
          .toList();
      debugPrint(
        '[CardStorage] decoded ${cards.length} legacy SharedPreferences '
        'top-level cards (${countCards(cards)} total)',
      );
      return cards;
    } catch (error, stackTrace) {
      debugPrint('[CardStorage] failed to decode legacy cards: $error');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  static Future<void> _writeCardsFile(
    File file,
    File backupFile,
    List<AACCard> cards,
  ) async {
    await file.parent.create(recursive: true);

    if (await file.exists()) {
      await file.copy(backupFile.path);
      debugPrint('[CardStorage] updated card backup: ${backupFile.path}');
    }

    final tempFile = File('${file.path}.tmp');
    final payload = <String, dynamic>{
      'schemaVersion': 1,
      'savedAt': DateTime.now().toIso8601String(),
      'cards': cards.map((card) => card.toJson()).toList(),
    };

    await tempFile.writeAsString(jsonEncode(payload), flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  static Future<void> _markSeeded(SharedPreferences prefs) async {
    await prefs.setBool(_hasSeededDefaultsKey, true);
    await prefs.setInt(_seededDefaultVersionKey, defaultCatalogVersion);
  }

  static Future<void> _syncLegacyCards(
    SharedPreferences prefs,
    List<AACCard> cards,
  ) async {
    try {
      await prefs.setString(
        _legacyCardsKey,
        jsonEncode(cards.map((card) => card.toJson()).toList()),
      );
    } catch (error) {
      debugPrint('[CardStorage] legacy SharedPreferences sync failed: $error');
    }
  }

  static Future<List<AACCard>> _applyDefaultCatalogMigration(
    List<AACCard> cards,
    List<AACCard> defaultCards,
    SharedPreferences prefs,
    File file,
    File backupFile,
  ) async {
    final seededVersion = prefs.getInt(_seededDefaultVersionKey) ?? 0;
    if (seededVersion >= defaultCatalogVersion) return cards;

    final changed = _mergeMissingDefaults(cards, defaultCards);
    await prefs.setInt(_seededDefaultVersionKey, defaultCatalogVersion);
    if (changed) {
      await _writeCardsFile(file, backupFile, cards);
      debugPrint(
        '[CardStorage] merged new default cards for catalog version '
        '$defaultCatalogVersion without overwriting user cards',
      );
    }
    return cards;
  }

  static bool _mergeMissingDefaults(
    List<AACCard> target,
    List<AACCard> defaults,
  ) {
    var changed = false;
    for (final defaultCard in defaults) {
      final existing = _findDirectChild(target, defaultCard.id);
      if (existing == null) {
        target.add(_cloneCard(defaultCard));
        changed = true;
      } else if (defaultCard.subCards.isNotEmpty) {
        changed =
            _mergeMissingDefaults(existing.subCards, defaultCard.subCards) ||
                changed;
      }
    }
    return changed;
  }

  static AACCard? _findDirectChild(List<AACCard> cards, String id) {
    for (final card in cards) {
      if (card.id == id) return card;
    }
    return null;
  }

  static bool _isInsideDirectory(String filePath, String directoryPath) {
    var normalizedFile = filePath.replaceAll('\\', '/');
    var normalizedDirectory = directoryPath.replaceAll('\\', '/');
    if (Platform.isWindows) {
      normalizedFile = normalizedFile.toLowerCase();
      normalizedDirectory = normalizedDirectory.toLowerCase();
    }
    return normalizedFile == normalizedDirectory ||
        normalizedFile.startsWith('$normalizedDirectory/');
  }

  static bool isAssetImagePath(String? path) {
    if (path == null) return false;
    return path.startsWith('assets/');
  }

  static String _extension(String path, {required String fallback}) {
    final normalized = path.replaceAll('\\', '/');
    final fileName = normalized.split('/').last;
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return fallback;
    return fileName.substring(dot);
  }

  static String _safeFileComponent(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
