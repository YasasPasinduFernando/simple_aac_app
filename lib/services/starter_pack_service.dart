import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../data/starter_pack_manifest_data.dart';
import '../models/aac_card_model.dart';

class ImportStarterPackResult {
  final bool alreadyInstalled;
  final int cardsAdded;
  final AACCard rootFolder;

  const ImportStarterPackResult({
    required this.alreadyInstalled,
    required this.cardsAdded,
    required this.rootFolder,
  });
}

class StarterPackService {
  static const String starterPackRootId = 'simpleaac.starter.v2.default';
  static const String assetImagePrefix = 'assets/images/starter_pack_v8/';

  /// Exact background colors matching the solid edge pixels of built-in category folder assets.
  /// Eliminates visible inner rectangles without cropping illustrations.
  static const Map<String, int> harmonizedCategoryFolderColors = {
    'simpleaac.starter.v2.animals': 0xFFE0EED0,
    'simpleaac.starter.v2.food': 0xFFFEE2A0,
    'simpleaac.starter.v2.snacks': 0xFFFFD8BC,
    'simpleaac.starter.v2.needs': 0xFFBFE6D5,
    'simpleaac.starter.v2.school_places': 0xFFD1E2FA,
  };

  /// Exact background colors matching the solid edge pixels of built-in seed cards.
  static const Map<String, int> harmonizedSeedColors = {
    'seed_hello': 0xFFFDE466,
    'seed_happy': 0xFFFDE16C,
    'seed_sad': 0xFFA1D1F6,
    'seed_angry': 0xFFF8A19F,
    'seed_more': 0xFF475CC5,
    'seed_good': 0xFF7CCA7E,
    'seed_play': 0xFFFEAE3E,
    'seed_yes': 0xFF9ADEA7,
    'seed_no': 0xFFEB9698,
    'seed_please': 0xFFCF99DB,
    'seed_thank_you': 0xFFFDE473,
    'seed_help': 0xFF70E3EC,
    'seed_stop': 0xFFFC877C,
  };

  static const Set<int> legacySeedColorValues = {
    0xFFFFF176, // seed_hello & seed_happy legacy (yellow.shade300)
    0xFF4FC3F7, // seed_sad legacy (lightBlue.shade300)
    0xFFE57373, // seed_angry legacy (red.shade300)
    0xFF3F51B5, // seed_more legacy (indigo.shade500)
    0xFF81C784, // seed_good legacy (green.shade300)
    0xFFFFB74D, // seed_play legacy (orange.shade300)
    0xFFA5D6A7, // seed_yes legacy
    0xFFEF9A9A, // seed_no legacy
    0xFFCE93D8, // seed_please legacy
    0xFFFFE082, // seed_thank_you legacy
    0xFF80DEEA, // seed_help legacy
    0xFFFF8A80, // seed_stop legacy
  };

  /// Resolves the effective presentation color for a card, ensuring built-in category folders
  /// and seed cards match their native illustration background across fresh and existing installations.
  static int resolveCardColorValue(AACCard card) {
    final harmonized = harmonizedCategoryFolderColors[card.id] ?? harmonizedSeedColors[card.id];
    if (harmonized != null) {
      final img = card.imagePath;
      final isBuiltIn = img == null ||
          img.isEmpty ||
          img.contains('assets/images/starter_pack_v8/') ||
          img.contains('assets/images/seed_v2/') ||
          img.contains('assets/home/') ||
          img.contains('images/');
      if (isBuiltIn) {
        // If it's a seed card and user customized the color away from legacy defaults, keep custom color
        if (card.id.startsWith('seed_')) {
          if (card.colorValue != harmonized &&
              !legacySeedColorValues.contains(card.colorValue)) {
            return card.colorValue;
          }
        }
        return harmonized;
      }
    }
    return card.colorValue;
  }

  static AACCard? _cachedPackRoot;

  /// Clear the in-memory cache (e.g. for testing)
  @visibleForTesting
  static void clearCache() {
    _cachedPackRoot = null;
  }

  /// Parses hex color string like "#D8C5EB" or "#228ED3" into a 32-bit ARGB integer.
  static int parseHexColor(String? hexString, {int defaultColor = 0xFF90CAF9}) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    try {
      final clean = hexString.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return int.parse('FF$clean', radix: 16);
      } else if (clean.length == 8) {
        return int.parse(clean, radix: 16);
      }
    } catch (_) {}
    return defaultColor;
  }

  /// Builds the complete Starter Pack hierarchy from manifest JSON.
  /// Root card: simpleaac.starter.v2.default
  /// Children: 13 Category Folders
  /// Leaves: 114 Word Cards
  /// Total nodes = 128
  static AACCard buildStarterPack({String? jsonString}) {
    if (jsonString == null && _cachedPackRoot != null) {
      return AACCard.fromJson(_cachedPackRoot!.toJson());
    }

    final raw = jsonString ?? starterPackManifestJson;
    final Map<String, dynamic> manifest = jsonDecode(raw) as Map<String, dynamic>;
    final List<dynamic> cardsList = manifest['cards'] as List<dynamic>;

    final Map<String, Map<String, dynamic>> rawById = {};
    for (final item in cardsList) {
      if (item is Map<String, dynamic>) {
        final id = item['id']?.toString();
        if (id != null) {
          rawById[id] = item;
        }
      }
    }

    final rootData = rawById[starterPackRootId];
    if (rootData == null) {
      throw const FormatException('Starter pack manifest missing root card: $starterPackRootId');
    }

    AACCard parseNode(Map<String, dynamic> data) {
      final id = data['id'].toString();
      final labels = (data['labels'] as Map<String, dynamic>?) ?? {};
      final labelEn = labels['en-US']?.toString() ?? 'Untitled';
      final labelSi = labels['si-LK']?.toString();
      final labelTa = labels['ta-LK']?.toString();
      final type = data['type']?.toString() ?? 'word';
      final group = data['group']?.toString() ?? labelEn;
      final colorHex = data['suggestedTileColor']?.toString();
      final colorVal = parseHexColor(colorHex);

      final rawImage = data['image']?.toString();
      final String? imagePath;
      if (rawImage != null && rawImage.isNotEmpty) {
        final fileName = rawImage.replaceFirst('images/', '');
        imagePath = '$assetImagePrefix$fileName';
      } else {
        imagePath = null;
      }

      final childrenIds = (data['childrenIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];

      final List<AACCard> subCards = [];
      for (final childId in childrenIds) {
        final childData = rawById[childId];
        if (childData != null) {
          subCards.add(parseNode(childData));
        }
      }

      return AACCard(
        id: id,
        label: labelEn,
        labelSinhala: labelSi,
        labelTamil: labelTa,
        imagePath: imagePath,
        category: group,
        colorValue: colorVal,
        type: type,
        subCards: subCards,
      );
    }

    final builtRoot = parseNode(rootData);

    if (jsonString == null) {
      _cachedPackRoot = AACCard.fromJson(builtRoot.toJson());
    }

    return builtRoot;
  }

  /// Returns a fresh deep clone of the Starter Pack root card.
  static AACCard getStarterPackRootClone({String? jsonString}) {
    final pack = buildStarterPack(jsonString: jsonString);
    return AACCard.fromJson(pack.toJson());
  }

  /// Checks if the starter pack root folder already exists anywhere in the card tree.
  static bool isStarterPackInstalled(List<AACCard> cards) {
    for (final card in cards) {
      if (card.id == starterPackRootId) return true;
      if (isStarterPackInstalled(card.subCards)) return true;
    }
    return false;
  }

  /// Finds the starter pack root folder if installed, or null otherwise.
  static AACCard? findStarterPackRoot(List<AACCard> cards) {
    for (final card in cards) {
      if (card.id == starterPackRootId) return card;
      final nested = findStarterPackRoot(card.subCards);
      if (nested != null) return nested;
    }
    return null;
  }

  /// Imports the starter pack into currentCards safely:
  /// - If not present, appends the root folder to currentCards.
  /// - If already present, safely merges any missing categories or word cards
  ///   WITHOUT overwriting any existing cards or user edits.
  /// - Returns an ImportStarterPackResult detailing what was added.
  static ImportStarterPackResult importStarterPack(
    List<AACCard> currentCards, {
    AACCard? packRoot,
  }) {
    final rootToImport = packRoot ?? getStarterPackRootClone();
    final existingRoot = findStarterPackRoot(currentCards);

    if (existingRoot == null) {
      currentCards.add(rootToImport);
      // Count total cards in rootToImport
      int countAll(AACCard c) {
        var count = 1;
        for (final sub in c.subCards) {
          count += countAll(sub);
        }
        return count;
      }

      final totalAdded = countAll(rootToImport);
      return ImportStarterPackResult(
        alreadyInstalled: false,
        cardsAdded: totalAdded,
        rootFolder: rootToImport,
      );
    }

    // Already present: safe non-destructive merge of missing items
    var addedCount = 0;
    final Map<String, AACCard> existingCategoriesById = {
      for (final cat in existingRoot.subCards) cat.id: cat,
    };

    for (final packCategory in rootToImport.subCards) {
      final existingCat = existingCategoriesById[packCategory.id];
      if (existingCat == null) {
        existingRoot.subCards.add(AACCard.fromJson(packCategory.toJson()));
        addedCount += 1 + packCategory.subCards.length;
      } else {
        final existingWordsById = {
          for (final word in existingCat.subCards) word.id: word,
        };
        for (final packWord in packCategory.subCards) {
          if (!existingWordsById.containsKey(packWord.id)) {
            existingCat.subCards.add(AACCard.fromJson(packWord.toJson()));
            addedCount++;
          }
        }
      }
    }

    return ImportStarterPackResult(
      alreadyInstalled: true,
      cardsAdded: addedCount,
      rootFolder: existingRoot,
    );
  }
}
