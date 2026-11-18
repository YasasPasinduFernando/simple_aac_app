import '../models/aac_card_model.dart';
import '../services/starter_pack_service.dart';

/// Helper utility for category discovery, canonical normalization,
/// accurate card counting, and virtual category filtering across
/// deeply nested card hierarchies.
class CategoryHelper {
  /// Known starter pack group identifiers mapped to their canonical display names.
  static const Map<String, String> _knownGroupDisplayNames = {
    'basic_words': 'Basic Words',
    'school_places': 'School & Places',
    'personal_care': 'Personal Care',
    'food': 'Food',
    'feelings': 'Feelings',
    'family': 'Family',
    'colours': 'Colours',
    'shapes': 'Shapes',
    'animals': 'Animals',
    'snacks': 'Snacks',
    'drinks': 'Drinks',
    'needs': 'Needs',
    'activities': 'Activities',
  };

  /// Normalizes a raw category string to its canonical display name.
  /// If it matches a known starter pack group or preset, returns the canonical Title Case.
  /// Otherwise, preserves user-created category names as trimmed strings.
  static String canonicalCategoryName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'General';
    final lower = trimmed.toLowerCase();
    if (lower == 'all' || lower == 'all cards') return 'All Cards';

    if (_knownGroupDisplayNames.containsKey(lower)) {
      return _knownGroupDisplayNames[lower]!;
    }

    // Match with underscores replaced by spaces
    final withSpaces = lower.replaceAll('_', ' ');
    for (final entry in _knownGroupDisplayNames.entries) {
      if (entry.value.toLowerCase() == withSpaces ||
          entry.key.replaceAll('_', ' ') == withSpaces) {
        return entry.value;
      }
    }

    return trimmed;
  }

  /// Determines whether a card's category matches the target category name.
  /// Comparison is case-insensitive, matches canonical display names,
  /// and tolerates underscore vs space variations (e.g. basic_words vs Basic Words).
  static bool matchesCategory(String cardCategory, String targetCategory) {
    final trimmedTarget = targetCategory.trim();
    if (trimmedTarget.isEmpty ||
        trimmedTarget.toLowerCase() == 'all' ||
        trimmedTarget.toLowerCase() == 'all cards') {
      return true;
    }

    final cardLower = cardCategory.trim().toLowerCase();
    final targetLower = trimmedTarget.toLowerCase();

    // 1. Direct exact or case-insensitive match
    if (cardLower == targetLower) return true;

    // 2. Canonical name match
    final cardCanonical = canonicalCategoryName(cardCategory).toLowerCase();
    final targetCanonical = canonicalCategoryName(trimmedTarget).toLowerCase();
    if (cardCanonical == targetCanonical ||
        cardCanonical == targetLower ||
        cardLower == targetCanonical) {
      return true;
    }

    // 3. Underscore vs space tolerance
    final cardNoUnderscore = cardLower.replaceAll('_', ' ');
    final targetNoUnderscore = targetLower.replaceAll('_', ' ');
    if (cardNoUnderscore == targetNoUnderscore) return true;

    return false;
  }

  /// Determines whether a card matches ANY of the categories in [targetCategories].
  /// If [targetCategories] is empty or contains 'All' / 'All Cards', returns true.
  static bool matchesAnyCategory(
    String cardCategory,
    Set<String> targetCategories,
  ) {
    if (targetCategories.isEmpty ||
        targetCategories.contains('All') ||
        targetCategories.contains('All Cards')) {
      return true;
    }
    return targetCategories.any((target) => matchesCategory(cardCategory, target));
  }

  /// Discovers all unique categories from the given card hierarchy via safe recursive traversal.
  ///
  /// Safe safeguards:
  /// - Cycle detection via [seenCardIds] prevents infinite loops.
  /// - Excludes the starter pack container root folder ('simpleaac.starter.v2.default')
  ///   from being treated as an ordinary content category.
  /// - Preserves user-created categories (even if named "Default") when their ID
  ///   is not the starter pack container root.
  static Set<String> discoverCategories(List<AACCard> rootCards) {
    final discovered = <String>{};
    final seenCardIds = <String>{};

    void traverse(AACCard card) {
      if (!seenCardIds.add(card.id)) return;

      final isStarterPackRoot = card.id == StarterPackService.starterPackRootId;
      if (!isStarterPackRoot) {
        final cat = card.category.trim();
        if (cat.isNotEmpty &&
            cat.toLowerCase() != 'all' &&
            cat.toLowerCase() != 'all cards') {
          discovered.add(canonicalCategoryName(cat));
        }
      }

      for (final sub in card.subCards) {
        traverse(sub);
      }
    }

    for (final card in rootCards) {
      traverse(card);
    }

    return discovered;
  }

  /// Traverses cards recursively to find all unique word cards matching the category filter.
  ///
  /// Policy:
  /// - Only counts/returns actual word cards (!card.isFolder).
  /// - Category container folders are NOT included as word cards.
  /// - Uses stable card IDs to guarantee zero duplicates.
  /// - Traverses deeply into nested subCards so cards at any depth are discovered.
  static List<AACCard> getWordCardsForCategories(
    List<AACCard> rootCards, {
    Set<String>? selectedCategories,
  }) {
    final isAll = selectedCategories == null ||
        selectedCategories.isEmpty ||
        selectedCategories.contains('All') ||
        selectedCategories.contains('All Cards');

    final seenCardIds = <String>{};
    final result = <AACCard>[];

    void traverse(AACCard card) {
      if (!seenCardIds.add(card.id)) return;

      if (!card.isFolder) {
        if (isAll || matchesAnyCategory(card.category, selectedCategories)) {
          result.add(card);
        }
      }

      for (final sub in card.subCards) {
        traverse(sub);
      }
    }

    for (final card in rootCards) {
      traverse(card);
    }

    return result;
  }

  /// Counts the total number of unique word cards matching a specific category.
  /// If [category] is 'All' or 'All Cards', returns the total count of all word cards.
  static int countWordCardsForCategory(
    List<AACCard> rootCards,
    String category,
  ) {
    if (category == 'All' || category == 'All Cards') {
      return getWordCardsForCategories(rootCards).length;
    }
    return getWordCardsForCategories(
      rootCards,
      selectedCategories: {category},
    ).length;
  }
}
