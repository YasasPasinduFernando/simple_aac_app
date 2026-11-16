import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';
import '../models/category_metadata.dart';
import '../utils/card_image.dart';
import 'preview/live_preview_panel.dart';
import 'styled_dialog_header.dart';

/// Redesigned, modern Category Selector Dialog for Simple AAC Sri Lanka.
///
/// Features:
/// - Real category icons and accent colors for every category.
/// - Live compact preview of the selected category, its cards, or helpful empty-state message.
/// - Clear "All Cards" option with total card count.
/// - Support for empty categories ("0 cards") with friendly guidance.
/// - Single-category selection with immediate preview and Apply / Cancel commitment.
class SelectCategoryDialog extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final List<AACCard> availableCards;
  final Map<String, CategoryMetadata> customMetadata;
  final String currentLanguage;
  final ValueChanged<String> onApply;

  const SelectCategoryDialog({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.availableCards,
    required this.customMetadata,
    required this.currentLanguage,
    required this.onApply,
  }) : super(key: key);

  @override
  State<SelectCategoryDialog> createState() => _SelectCategoryDialogState();
}

class _SelectCategoryDialogState extends State<SelectCategoryDialog> {
  late String _pendingCategory;

  @override
  void initState() {
    super.initState();
    _pendingCategory = widget.selectedCategory;
  }

  /// Total count of all cards (including root and subCards)
  int get _totalAllCardCount {
    int count = 0;
    for (final card in widget.availableCards) {
      count += 1 + card.subCards.length;
    }
    return count;
  }

  /// Calculates card count for a specific category name
  int _cardCountFor(String category) {
    if (category == 'All' || category == 'All Cards') {
      return _totalAllCardCount;
    }
    final clean = category.trim().toLowerCase();
    int count = 0;
    for (final card in widget.availableCards) {
      if (card.category.trim().toLowerCase() == clean) {
        count++;
      }
      for (final sub in card.subCards) {
        if (sub.category.trim().toLowerCase() == clean) {
          count++;
        }
      }
    }
    return count;
  }

  /// Retrieves up to [limit] cards belonging to [category] for the preview thumbnail strip
  List<AACCard> _cardsForPreview(String category, {int limit = 6}) {
    if (category == 'All' || category == 'All Cards') {
      return widget.availableCards.take(limit).toList();
    }
    final clean = category.trim().toLowerCase();
    final matches = <AACCard>[];
    for (final card in widget.availableCards) {
      if (card.category.trim().toLowerCase() == clean) {
        matches.add(card);
        if (matches.length >= limit) return matches;
      }
      for (final sub in card.subCards) {
        if (sub.category.trim().toLowerCase() == clean) {
          matches.add(sub);
          if (matches.length >= limit) return matches;
        }
      }
    }
    return matches;
  }

  CategoryMetadata _resolveMeta(String categoryName) {
    return CategoryMetadata.resolve(
      categoryName,
      customMetadata: widget.customMetadata,
      fallbackColorValue: 0xFF0277BD,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context).size;

    final isPreviewingCurrent = _pendingCategory == widget.selectedCategory;
    final pendingMeta = _resolveMeta(_pendingCategory);
    final pendingCardCount = _cardCountFor(_pendingCategory);
    final previewCards = _cardsForPreview(_pendingCategory);

    // Build the ordered list of category options:
    // "All Cards" is first, followed by "General" (if present), then user-created custom categories.
    final displayCategories = <String>[];
    displayCategories.add('All Cards');

    for (final cat in widget.categories) {
      final lower = cat.trim().toLowerCase();
      if (lower == 'all' || lower == 'all cards') continue;
      if (!displayCategories.any((c) => c.toLowerCase() == lower)) {
        displayCategories.add(cat);
      }
    }

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      title: StyledDialogHeader(
        icon: Icons.category_rounded,
        accentColor: pendingMeta.color,
        title: 'Select Category',
        subtitle: 'Choose which cards appear on your board',
        trailing: IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          tooltip: 'Close',
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (media.width - 32).clamp(280.0, 480.0),
          maxHeight: (media.height * 0.65).clamp(260.0, 560.0),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. COMPACT LIVE PREVIEW SECTION
              LivePreviewPanel(
                title: isPreviewingCurrent
                    ? 'CURRENTLY SHOWING'
                    : 'PREVIEWING SELECTION',
                icon: Icons.visibility_rounded,
                accentColor: pendingMeta.color,
                minHeight: 85,
                maxHeight: 140,
                trailing: Text(
                  '$pendingCardCount cards',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category Banner
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: pendingMeta.color,
                          child: Icon(
                            pendingMeta.icon,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _pendingCategory == 'All'
                                    ? 'All Cards'
                                    : _pendingCategory,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _pendingCategory == 'All' ||
                                        _pendingCategory == 'All Cards'
                                    ? 'Showing cards from every category'
                                    : (pendingCardCount == 0
                                        ? 'Empty category'
                                        : '$pendingCardCount card${pendingCardCount == 1 ? '' : 's'} in this category'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Card thumbnails OR empty state guidance
                    if (pendingCardCount == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E2836)
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
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
                              size: 16,
                              color: isDark
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade800,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No cards in this category yet.\nCreate cards in Edit Mode to get started.',
                                style: TextStyle(
                                  fontSize: 11,
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
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < previewCards.length; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              Builder(
                                builder: (context) {
                                  final card = previewCards[i];
                                  final label = card
                                      .getLabel(widget.currentLanguage);
                                  return Tooltip(
                                    message: label,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Color(card.colorValue),
                                        borderRadius:
                                            BorderRadius.circular(9),
                                        border: Border.all(
                                          color: Colors.black
                                              .withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: card.imagePath != null &&
                                                card.imagePath!.isNotEmpty
                                            ? buildCardImage(
                                                card.imagePath!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context,
                                                        error, stackTrace) =>
                                                    const Icon(Icons.image,
                                                        size: 16),
                                              )
                                            : const Icon(Icons.image,
                                                size: 16),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                            if (pendingCardCount > previewCards.length) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${pendingCardCount - previewCards.length}',
                                    style: TextStyle(
                                      fontSize: 10.5,
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
                ),
              ),

              const SizedBox(height: 12),

              // 2. CATEGORY LIST
              for (final cat in displayCategories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Builder(
                    builder: (context) {
                      final isAllCards = cat == 'All Cards';
                      final isSelected = isAllCards
                          ? (_pendingCategory == 'All' ||
                              _pendingCategory == 'All Cards')
                          : _pendingCategory.trim().toLowerCase() ==
                              cat.trim().toLowerCase();

                      final meta = _resolveMeta(cat);
                      final count = _cardCountFor(cat);

                      final rowBg = isSelected
                          ? (isDark
                              ? meta.color.withValues(alpha: 0.22)
                              : meta.color.withValues(alpha: 0.12))
                          : (isDark
                              ? const Color(0xFF1E2836)
                              : colorScheme.surfaceContainerLowest);

                      final borderColor = isSelected
                          ? meta.color
                          : colorScheme.outlineVariant.withValues(alpha: 0.50);

                      return Material(
                        color: rowBg,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            setState(() {
                              _pendingCategory = isAllCards ? 'All' : cat;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: borderColor,
                                width: isSelected ? 1.8 : 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Category Icon avatar with accent color
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? meta.color
                                        : meta.color
                                            .withValues(alpha: isDark ? 0.35 : 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    meta.icon,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white : meta.color),
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Title & Description / Card count
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
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : (isSelected
                                                  ? colorScheme.primary
                                                  : const Color(0xFF1E293B)),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        isAllCards
                                            ? 'Show cards from every category • $count cards'
                                            : '$count card${count == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white60
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Selection indicator
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 21,
                                    color: meta.color,
                                  )
                                else
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.grey.shade400,
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: pendingMeta.color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Apply'),
          onPressed: () {
            widget.onApply(_pendingCategory);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
