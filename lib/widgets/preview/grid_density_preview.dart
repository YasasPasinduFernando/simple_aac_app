import 'package:flutter/material.dart';

import '../../models/aac_card_model.dart';
import '../../utils/card_image.dart';

/// Live preview widget for the Select Grid Size dialog.
/// Reactively reflows sample cards into 1 to 30 columns.
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
          labelTamil: 'மகிழ்ச்சි',
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
          id: 'preview_water',
          label: 'Water',
          labelSinhala: 'වතුර',
          labelTamil: 'தண்ணீர்',
          colorValue: 0xFF38BDF8,
        ),
        AACCard(
          id: 'preview_food',
          label: 'Food',
          labelSinhala: 'කෑම',
          labelTamil: 'உணவு',
          colorValue: 0xFF86EFAC,
        ),
        AACCard(
          id: 'preview_more',
          label: 'More',
          labelSinhala: 'තව',
          labelTamil: 'மேலும்',
          colorValue: 0xFFFEE685,
          type: 'folder',
        ),
        AACCard(
          id: 'preview_eat',
          label: 'Eat',
          labelSinhala: 'කන්න',
          labelTamil: 'சாப்பிடு',
          colorValue: 0xFF86EFAC,
        ),
        AACCard(
          id: 'preview_drink',
          label: 'Drink',
          labelSinhala: 'බොන්න',
          labelTamil: 'குடி',
          colorValue: 0xFF38BDF8,
        ),
        AACCard(
          id: 'preview_finish',
          label: 'Finish',
          labelSinhala: 'ඉවරයි',
          labelTamil: 'முடிந்தது',
          colorValue: 0xFFE2E8F0,
        ),
        AACCard(
          id: 'preview_play',
          label: 'Play',
          labelSinhala: 'සෙල්ලම්',
          labelTamil: 'விளையாடு',
          colorValue: 0xFFFDE047,
        ),
        AACCard(
          id: 'preview_again',
          label: 'Again',
          labelSinhala: 'ආයෙත්',
          labelTamil: 'மீண்டும்',
          colorValue: 0xFFFEE685,
        ),
        AACCard(
          id: 'preview_please',
          label: 'Please',
          labelSinhala: 'කරුණාකර',
          labelTamil: 'தயவுசெய்து',
          colorValue: 0xFFB9DCFE,
        ),
        AACCard(
          id: 'preview_angry',
          label: 'Angry',
          labelSinhala: 'තරහයි',
          labelTamil: 'கோபம்',
          colorValue: 0xFFFCA5A5,
        ),
        AACCard(
          id: 'preview_help',
          label: 'Help',
          labelSinhala: 'උදව්',
          labelTamil: 'உதவி',
          colorValue: 0xFFFCA5A5,
        ),
        AACCard(
          id: 'preview_yes',
          label: 'Yes',
          labelSinhala: 'ඔව්',
          labelTamil: 'ஆம்',
          colorValue: 0xFF86EFAC,
        ),
        AACCard(
          id: 'preview_no',
          label: 'No',
          labelSinhala: 'නැහැ',
          labelTamil: 'இல்லை',
          colorValue: 0xFFFCA5A5,
        ),
        AACCard(
          id: 'preview_sleep',
          label: 'Sleep',
          labelSinhala: 'නිදාගන්න',
          labelTamil: 'தூங்கு',
          colorValue: 0xFFC7D2FE,
        ),
        AACCard(
          id: 'preview_toilet',
          label: 'Toilet',
          labelSinhala: 'වැසිකිලිය',
          labelTamil: 'கழிப்பறை',
          colorValue: 0xFFBAE6FD,
        ),
        AACCard(
          id: 'preview_home',
          label: 'Home',
          labelSinhala: 'ගෙදර',
          labelTamil: 'வீடு',
          colorValue: 0xFFFED7AA,
        ),
        AACCard(
          id: 'preview_school',
          label: 'School',
          labelSinhala: 'ඉස්කෝලේ',
          labelTamil: 'பள்ளி',
          colorValue: 0xFFFEF08A,
        ),
        AACCard(
          id: 'preview_car',
          label: 'Car',
          labelSinhala: 'කාර් එක',
          labelTamil: 'கார்',
          colorValue: 0xFFFDE047,
        ),
        AACCard(
          id: 'preview_music',
          label: 'Music',
          labelSinhala: 'සංගීතය',
          labelTamil: 'இசை',
          colorValue: 0xFFE9D5FF,
        ),
        AACCard(
          id: 'preview_book',
          label: 'Book',
          labelSinhala: 'පොත',
          labelTamil: 'புத்தகம்',
          colorValue: 0xFFDDD6FE,
        ),
        AACCard(
          id: 'preview_love',
          label: 'Love',
          labelSinhala: 'ආදරෙයි',
          labelTamil: 'அன்பு',
          colorValue: 0xFFFBCFE8,
        ),
        AACCard(
          id: 'preview_i',
          label: 'I',
          labelSinhala: 'මම',
          labelTamil: 'நான்',
          colorValue: 0xFFBAE6FD,
        ),
        AACCard(
          id: 'preview_you',
          label: 'You',
          labelSinhala: 'ඔයා',
          labelTamil: 'நீ',
          colorValue: 0xFFBAE6FD,
        ),
        AACCard(
          id: 'preview_go',
          label: 'Go',
          labelSinhala: 'යන්න',
          labelTamil: 'போ',
          colorValue: 0xFF86EFAC,
        ),
        AACCard(
          id: 'preview_stop',
          label: 'Stop',
          labelSinhala: 'නවත්තන්න',
          labelTamil: 'நிறுத்து',
          colorValue: 0xFFFCA5A5,
        ),
        AACCard(
          id: 'preview_thanks',
          label: 'Thanks',
          labelSinhala: 'ස්තූතියි',
          labelTamil: 'நன்றி',
          colorValue: 0xFFFEE685,
        ),
        AACCard(
          id: 'preview_ball',
          label: 'Ball',
          labelSinhala: 'බෝලය',
          labelTamil: 'பந்து',
          colorValue: 0xFFFCA5A5,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final cols = columns.clamp(1, 30);
    final sourceCards = cards.isNotEmpty ? cards : defaultSampleCards;

    // For densities > 5, render a horizontal scrollable row with accessible mini cards
    if (cols > 5) {
      final List<AACCard> previewCards;
      if (sourceCards.length >= cols) {
        previewCards = sourceCards.take(cols).toList();
      } else {
        final combined = List<AACCard>.from(sourceCards);
        while (combined.length < cols) {
          combined.addAll(defaultSampleCards);
        }
        previewCards = combined.take(cols).toList();
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final card in previewCards)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: SizedBox(
                    width: 64,
                    height: 78,
                    child: _buildMiniCard(card, 5),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Densities 1..5: reflow into dynamic aspect ratio grid
    final previewCards =
        sourceCards.length >= cols ? sourceCards.take(cols * 2).toList() : sourceCards;

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
        iconSize = 16.0;
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
    } else if (label.contains('water') || label.contains('drink')) {
      return Icon(Icons.local_drink_rounded,
          size: iconSize, color: const Color(0xFF0284C7));
    } else if (label.contains('food') || label.contains('eat')) {
      return Icon(Icons.restaurant_rounded,
          size: iconSize, color: const Color(0xFF15803D));
    } else if (label.contains('finish')) {
      return Icon(Icons.sports_score_rounded,
          size: iconSize, color: const Color(0xFF475569));
    } else if (label.contains('play')) {
      return Icon(Icons.sports_esports_rounded,
          size: iconSize, color: const Color(0xFFB45309));
    } else if (label.contains('again')) {
      return Icon(Icons.replay_rounded,
          size: iconSize, color: const Color(0xFFB45309));
    } else if (label.contains('please')) {
      return Icon(Icons.pan_tool_alt_rounded,
          size: iconSize, color: const Color(0xFF1D4ED8));
    } else if (label.contains('help')) {
      return Icon(Icons.help_outline_rounded,
          size: iconSize, color: const Color(0xFFB91C1C));
    } else if (label.contains('sleep')) {
      return Icon(Icons.bedtime_rounded,
          size: iconSize, color: const Color(0xFF4338CA));
    } else if (label.contains('home')) {
      return Icon(Icons.home_rounded,
          size: iconSize, color: const Color(0xFFC2410C));
    } else if (label.contains('school')) {
      return Icon(Icons.school_rounded,
          size: iconSize, color: const Color(0xFF854D0E));
    } else if (label.contains('car')) {
      return Icon(Icons.directions_car_rounded,
          size: iconSize, color: const Color(0xFFB45309));
    } else if (label.contains('music')) {
      return Icon(Icons.music_note_rounded,
          size: iconSize, color: const Color(0xFF7E22CE));
    } else if (label.contains('book')) {
      return Icon(Icons.menu_book_rounded,
          size: iconSize, color: const Color(0xFF6B21A8));
    } else if (label.contains('toilet')) {
      return Icon(Icons.wc_rounded,
          size: iconSize, color: const Color(0xFF0369A1));
    } else if (label.contains('love')) {
      return Icon(Icons.favorite_rounded,
          size: iconSize, color: const Color(0xFFBE185D));
    }
    return Icon(Icons.widgets_rounded, size: iconSize, color: Colors.black54);
  }
}
