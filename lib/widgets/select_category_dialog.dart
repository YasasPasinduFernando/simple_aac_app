import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';
import '../models/category_metadata.dart';
import '../utils/card_image.dart';
import '../utils/category_helper.dart';
import 'styled_dialog_header.dart';

/// Redesigned, modern Multi-Category Selection Dialog ("Choose Categories")
/// for Simple AAC Sri Lanka, matching the official design specification.
///
/// Features:
/// - Select one, two, three or more categories simultaneously.
/// - "All Cards" option mutually exclusive with individual category selections.
/// - Checkbox indicators on the right of each category row.
/// - Live "BOARD PREVIEW" panel with category chips, unique card count,
///   and card thumbnail previews with labels.
/// - Removable selection chips inside the preview.
/// - Union of unique cards belonging to selected categories (no duplicates).
/// - Helpful empty-state guidance when selected categories contain 0 cards.
/// - Clean Cancel and Apply commitment model.
class SelectCategoryDialog extends StatefulWidget {
  final List<String> categories;
  final Set<String> selectedCategories;
  final String? selectedCategory;
  final List<AACCard> availableCards;
  final Map<String, CategoryMetadata> customMetadata;
  final String currentLanguage;
  final ValueChanged<Set<String>> onApply;
  final ValueChanged<String>? onApplySingle;

  const SelectCategoryDialog({
    Key? key,
    required this.categories,
    this.selectedCategories = const {'All'},
    this.selectedCategory,
    required this.availableCards,
    required this.customMetadata,
    required this.currentLanguage,
    required this.onApply,
    this.onApplySingle,
  }) : super(key: key);

  @override
  State<SelectCategoryDialog> createState() => _SelectCategoryDialogState();
}

typedef ChooseCategoriesDialog = SelectCategoryDialog;

class _SelectCategoryDialogState extends State<SelectCategoryDialog> {
  late Set<String> _pendingCategories;

  @override
  void initState() {
    super.initState();
    if (widget.selectedCategories.isNotEmpty) {
      _pendingCategories = Set.from(widget.selectedCategories);
    } else if (widget.selectedCategory != null &&
        widget.selectedCategory!.isNotEmpty) {
      _pendingCategories = {widget.selectedCategory!};
    } else {
      _pendingCategories = {'All'};
    }
  }

  bool get _isAllCardsSelected =>
      _pendingCategories.contains('All') ||
      _pendingCategories.contains('All Cards');

  /// Total count of all cards (including root and subCards)
  int get _totalAllCardCount =>
      CategoryHelper.countWordCardsForCategory(widget.availableCards, 'All');

  /// Calculates card count for a specific category name
  int _cardCountFor(String category) {
    if (category == 'All' || category == 'All Cards') {
      return _totalAllCardCount;
    }
    return CategoryHelper.countWordCardsForCategory(
      widget.availableCards,
      category,
    );
  }

  /// Resolves the unique union of cards belonging to the selected categories.
  /// Guarantees zero duplicate cards (by ID).
  List<AACCard> _getUniqueCardsForSelection() {
    if (_isAllCardsSelected) {
      return CategoryHelper.getWordCardsForCategories(widget.availableCards);
    }
    if (_pendingCategories.isEmpty) {
      return [];
    }
    return CategoryHelper.getWordCardsForCategories(
      widget.availableCards,
      selectedCategories: _pendingCategories,
    );
  }

  CategoryMetadata _resolveMeta(String categoryName) {
    return CategoryMetadata.resolve(
      categoryName,
      customMetadata: widget.customMetadata,
      fallbackColorValue: 0xFF0277BD,
    );
  }

  void _toggleAllCards() {
    setState(() {
      if (_isAllCardsSelected) {
        _pendingCategories.clear();
      } else {
        _pendingCategories.clear();
        _pendingCategories.add('All');
      }
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      // Selecting any individual category deselects All Cards
      _pendingCategories.remove('All');
      _pendingCategories.remove('All Cards');

      final canonical = CategoryHelper.canonicalCategoryName(category);
      final existing = _pendingCategories.firstWhere(
        (c) => CategoryHelper.matchesCategory(c, category),
        orElse: () => '',
      );

      if (existing.isNotEmpty) {
        _pendingCategories.remove(existing);
      } else {
        _pendingCategories.add(canonical);
      }
    });
  }

  void _removeCategory(String category) {
    setState(() {
      _pendingCategories.removeWhere(
        (c) => CategoryHelper.matchesCategory(c, category),
      );
    });
  }

  void _commitSelection() {
    final finalSelection =
        _pendingCategories.isEmpty ? {'All'} : _pendingCategories;
    widget.onApply(finalSelection);
    if (widget.onApplySingle != null) {
      final single = finalSelection.contains('All')
          ? 'All'
          : (finalSelection.length == 1 ? finalSelection.first : 'All');
      widget.onApplySingle!(single);
    }
    Navigator.pop(context);
  }

  Widget _build4ColorGridIcon() {
    return SizedBox(
      width: 22,
      height: 22,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 9.5,
                height: 9.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                width: 9.5,
                height: 9.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 9.5,
                height: 9.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                width: 9.5,
                height: 9.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context).size;

    final uniqueCards = _getUniqueCardsForSelection();

    // Ordered list of categories with 'All Cards' at top
    final displayCategories = <String>[];
    displayCategories.add('All Cards');

    for (final cat in widget.categories) {
      final canonical = CategoryHelper.canonicalCategoryName(cat);
      final lower = canonical.toLowerCase();
      if (lower == 'all' || lower == 'all cards') continue;
      if (!displayCategories.any(
        (c) => CategoryHelper.matchesCategory(c, canonical),
      )) {
        displayCategories.add(canonical);
      }
    }

    // Headline calculation
    final String headline;
    if (_isAllCardsSelected) {
      headline = '${uniqueCards.length} cards from All Categories';
    } else if (_pendingCategories.isEmpty) {
      headline = '0 cards from 0 categories';
    } else {
      headline =
          '${uniqueCards.length} cards from ${_pendingCategories.length} ${_pendingCategories.length == 1 ? 'category' : 'categories'}';
    }

    // Apply button label
    final String applyLabel;
    if (_isAllCardsSelected) {
      applyLabel = 'Apply (All)';
    } else if (_pendingCategories.isEmpty) {
      applyLabel = 'Apply';
    } else {
      applyLabel = 'Apply (${_pendingCategories.length})';
    }

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      title: StyledDialogHeader(
        iconWidget: _build4ColorGridIcon(),
        title: 'Choose Categories',
        subtitle: 'Select the categories to show on your board',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (media.width - 32).clamp(280.0, 500.0),
          maxHeight: (media.height * 0.70).clamp(300.0, 620.0),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // 1. BOARD PREVIEW PANEL (Matching Mockup)
              // ==========================================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2836)
                      : const Color(0xFFF0F6FE),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.35)
                        : const Color(0xFFBFDBFE),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge: BOARD PREVIEW
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF78350F)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFB45309)
                              : const Color(0xFFFDE68A),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'BOARD PREVIEW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFF92400E),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Headline: e.g. "8 cards from 3 categories ✨"
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            headline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '✨',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),

                    // Selected Category Chips Row (Removable via 'x')
                    if (!_isAllCardsSelected && _pendingCategories.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final cat in _pendingCategories) ...[
                              Builder(
                                builder: (context) {
                                  final meta = _resolveMeta(cat);
                                  final chipBg = isDark
                                      ? meta.color.withValues(alpha: 0.30)
                                      : meta.color.withValues(alpha: 0.14);
                                  final chipBorder = meta.color.withValues(
                                      alpha: isDark ? 0.65 : 0.40);

                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.fromLTRB(
                                        8, 4, 4, 4),
                                    decoration: BoxDecoration(
                                      color: chipBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: chipBorder,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          meta.icon,
                                          size: 14,
                                          color: isDark
                                              ? Colors.white
                                              : meta.color,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          cat,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          onTap: () => _removeCategory(cat),
                                          child: Padding(
                                            padding: const EdgeInsets.all(3.0),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 14,
                                              color: isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Card Thumbnail Cards Strip OR Empty Guidance
                    if (uniqueCards.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF161F2E)
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.amber.shade700.withValues(alpha: 0.4)
                                : Colors.amber.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: isDark
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade800,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _pendingCategories.isEmpty
                                    ? 'No categories selected.\nCheck categories below to show them on your board.'
                                    : 'No cards in the selected categories yet.\nCreate cards in Edit Mode to get started.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.amber.shade200
                                      : Colors.amber.shade900,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0;
                                i <
                                    (uniqueCards.length > 8
                                        ? 8
                                        : uniqueCards.length);
                                i++) ...[
                              if (i > 0) const SizedBox(width: 10),
                              Builder(
                                builder: (context) {
                                  final card = uniqueCards[i];
                                  final label = card
                                      .getLabel(widget.currentLanguage);

                                  return Container(
                                    width: 74,
                                    height: 84,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF161F2E)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white12
                                            : const Color(0xFFE2E8F0),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                              alpha: isDark ? 0.25 : 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: card.imagePath != null &&
                                                    card.imagePath!.isNotEmpty
                                                ? buildCardImage(
                                                    card.imagePath!,
                                                    fit: BoxFit.contain,
                                                  )
                                                : Container(
                                                    color:
                                                        Color(card.colorValue),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.image,
                                                        size: 22,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                            if (uniqueCards.length > 8) ...[
                              const SizedBox(width: 10),
                              Container(
                                width: 74,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF161F2E)
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${uniqueCards.length - 8}\nmore',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ==========================================
              // 2. CATEGORY LIST WITH CHECKBOXES
              // ==========================================
              for (final cat in displayCategories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Builder(
                    builder: (context) {
                      final isAllCards = cat == 'All Cards';
                      final isChecked = isAllCards
                          ? _isAllCardsSelected
                          : _pendingCategories.any(
                              (p) => CategoryHelper.matchesCategory(p, cat),
                            );

                      final meta = _resolveMeta(cat);
                      final count = _cardCountFor(cat);

                      final rowBg = isChecked
                          ? (isDark
                              ? meta.color.withValues(alpha: 0.18)
                              : meta.color.withValues(alpha: 0.08))
                          : (isDark
                              ? const Color(0xFF1E2836)
                              : colorScheme.surfaceContainerLowest);

                      final borderColor = isChecked
                          ? meta.color
                          : colorScheme.outlineVariant.withValues(alpha: 0.50);

                      return Material(
                        color: rowBg,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (isAllCards) {
                              _toggleAllCards();
                            } else {
                              _toggleCategory(cat);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: borderColor,
                                width: isChecked ? 1.6 : 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Category Icon avatar
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isChecked
                                        ? meta.color
                                        : meta.color.withValues(
                                            alpha: isDark ? 0.35 : 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isAllCards
                                        ? Icons.layers_rounded
                                        : meta.icon,
                                    color: isChecked
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white
                                            : meta.color),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Category Title & Subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        cat,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: isChecked
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : (isChecked
                                                  ? colorScheme.primary
                                                  : const Color(0xFF1E293B)),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isAllCards
                                            ? 'Show cards from every category • $count cards'
                                            : '$count card${count == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark
                                              ? Colors.white60
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Right Checkbox
                                Checkbox(
                                  value: isChecked,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  activeColor: meta.color,
                                  onChanged: (_) {
                                    if (isAllCards) {
                                      _toggleAllCards();
                                    } else {
                                      _toggleCategory(cat);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF), // Bright Blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _commitSelection,
              child: Text(
                applyLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
