import 'package:flutter/material.dart';

import '../../models/aac_card_model.dart';
import '../../utils/card_image.dart';

/// Live preview widget for the Select Grid Size dialog.
/// Reactively reflows sample cards into 1, 2, 3, 4, or 5 columns.
class GridDensityPreview extends StatelessWidget {
  final int columns;
  final List<AACCard> cards;
  final String language;
  final double cardTextScale;
  final int cardTextColor;
  final bool isDarkMode;

  const GridDensityPreview({
    Key? key,
    required this.columns,
    this.cards = const [],
    this.language = 'en',
    this.cardTextScale = 1.0,
    this.cardTextColor = 0xFF111827,
    this.isDarkMode = false,
  }) : super(key: key);

  static List<AACCard> get defaultSampleCards => [
        AACCard(
          id: 'preview_hello',
          label: 'Hello',
          labelSinhala: 'හෙලෝ',
          labelTamil: 'வணக்கம்',
          colorValue: 0xFFFEE685,
        ),
        AACCard(
          id: 'preview_happy',
          label: 'Happy',
          labelSinhala: 'සතුටුයි',
          labelTamil: 'மகிழ்ச்சி',
          colorValue: 0xFFB9DCFE,
        ),
        AACCard(
          id: 'preview_sad',
          label: 'Sad',
          labelSinhala: 'දුකයි',
          labelTamil: 'சோகம்',
          colorValue: 0xFFBAE6FD,
        ),
        AACCard(
          id: 'preview_angry',
          label: 'Angry',
          labelSinhala: 'තරහයි',
          labelTamil: 'கோபம்',
          colorValue: 0xFFFCA5A5,
        ),
        AACCard(
          id: 'preview_more',
          label: 'More',
          labelSinhala: 'තව',
          labelTamil: 'மேலும்',
          colorValue: 0xFFFEE685,
          type: 'folder',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final previewCards =
        cards.isNotEmpty ? cards.take(6).toList() : defaultSampleCards;

    final cols = columns.clamp(1, 5);

    // Dynamic aspect ratios tailored per density
    final double childAspectRatio;
    switch (cols) {
      case 1:
        childAspectRatio = 2.4;
        break;
      case 2:
        childAspectRatio = 1.1;
        break;
      case 3:
        childAspectRatio = 0.95;
        break;
      case 4:
        childAspectRatio = 0.85;
        break;
      case 5:
      default:
        childAspectRatio = 0.78;
        break;
    }

    final rows = <Widget>[];
    for (int i = 0; i < previewCards.length; i += cols) {
      final chunk =
          previewCards.sublist(i, (i + cols).clamp(0, previewCards.length));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final card in chunk)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2.5),
                  child: AspectRatio(
                    aspectRatio: childAspectRatio,
                    child: _buildMiniCard(card, cols),
                  ),
                ),
              ),
            for (int j = 0; j < cols - chunk.length; j++)
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

  Widget _buildMiniCard(AACCard card, int cols) {
    final label = card.getLabel(language);
    final isFolder = card.type == 'folder';

    final double fontSize;
    final double iconSize;
    switch (cols) {
      case 1:
        fontSize = 13.0 * cardTextScale;
        iconSize = 28.0;
        break;
      case 2:
        fontSize = 11.5 * cardTextScale;
        iconSize = 26.0;
        break;
      case 3:
        fontSize = 10.0 * cardTextScale;
        iconSize = 22.0;
        break;
      case 4:
        fontSize = 8.5 * cardTextScale;
        iconSize = 18.0;
        break;
      case 5:
      default:
        fontSize = 7.5 * cardTextScale;
        iconSize = 15.0;
        break;
    }

    final cardBg = Color(card.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.08),
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
      child: cols == 1
          ? Row(
              children: [
                const SizedBox(width: 12),
                _buildCardIcon(card, iconSize, isFolder),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Color(cardTextColor),
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isFolder) ...[
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.black54),
                  const SizedBox(width: 12),
                ],
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: _buildCardIcon(card, iconSize, isFolder),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Color(cardTextColor),
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
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
