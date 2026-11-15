import 'package:flutter/material.dart';

import '../../models/aac_card_model.dart';
import '../../utils/card_image.dart';

/// Live preview mini-board for the Visible Cards dialog.
/// Displays only the cards currently checked in draft, reflowed into a responsive mini-grid.
class VisibleCardsPreview extends StatelessWidget {
  final List<AACCard> cards;
  final Set<String> selectedIds;
  final String language;
  final int columns;
  final bool isDarkMode;

  const VisibleCardsPreview({
    Key? key,
    required this.cards,
    required this.selectedIds,
    this.language = 'en',
    this.columns = 2,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visibleList = cards.where((c) => selectedIds.contains(c.id)).toList();

    if (cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.style_outlined,
                size: 28,
                color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
              ),
              const SizedBox(height: 6),
              Text(
                'No cards in this category',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Create cards first in Edit Mode to manage visibility',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (visibleList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_off_rounded,
                size: 28,
                color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
              ),
              const SizedBox(height: 6),
              Text(
                'No cards visible',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap "Select all" or check cards below to show them on your board',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode ? Colors.white38 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final previewCols = columns.clamp(2, 3);

    final rows = <Widget>[];
    for (int i = 0; i < visibleList.length; i += previewCols) {
      final chunk = visibleList.sublist(
          i, (i + previewCols).clamp(0, visibleList.length));
      rows.add(
        Row(
          children: [
            for (final card in chunk)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2.5),
                  child: AspectRatio(
                    aspectRatio: 1.15,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Color(card.colorValue),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.black
                              .withValues(alpha: isDarkMode ? 0.25 : 0.08),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: _buildCardIcon(
                                  card, 22.0, card.type == 'folder'),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              card.getLabel(language),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            for (int j = 0; j < previewCols - chunk.length; j++)
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }

  Widget _buildCardIcon(AACCard card, double iconSize, bool isFolder) {
    if (card.imagePath != null && card.imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: iconSize,
          height: iconSize,
          child: buildCardImage(
            card.imagePath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _fallbackIcon(card, iconSize, isFolder),
          ),
        ),
      );
    }
    return _fallbackIcon(card, iconSize, isFolder);
  }

  Widget _fallbackIcon(AACCard card, double iconSize, bool isFolder) {
    if (isFolder) {
      return Icon(Icons.folder_rounded,
          size: iconSize, color: const Color(0xFFB45309));
    }
    final label = card.getLabel('en').toLowerCase();
    if (label.contains('hello')) {
      return Icon(Icons.waving_hand_rounded,
          size: iconSize, color: const Color(0xFFB45309));
    } else if (label.contains('happy')) {
      return Icon(Icons.sentiment_very_satisfied_rounded,
          size: iconSize, color: const Color(0xFF1D4ED8));
    } else if (label.contains('sad')) {
      return Icon(Icons.sentiment_dissatisfied_rounded,
          size: iconSize, color: const Color(0xFF0369A1));
    } else if (label.contains('angry')) {
      return Icon(Icons.sentiment_very_dissatisfied_rounded,
          size: iconSize, color: const Color(0xFFB91C1C));
    }
    return Icon(Icons.widgets_rounded, size: iconSize, color: Colors.black54);
  }
}
