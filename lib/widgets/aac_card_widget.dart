import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';
import '../utils/card_image.dart';
import '../utils/theme_accessibility.dart';

class AACCardWidget extends StatelessWidget {
  final AACCard card;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AACCardWidget({
    Key? key,
    required this.card,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isColorBlind = ThemeAccessibility.colorBlindMode;
    final isDark = ThemeAccessibility.darkModeNotifier.value;
    final surfaceColor = ThemeAccessibility.resolveCardSurface(
      Color(card.colorValue),
      isDarkMode: isDark,
      isColorBlindMode: isColorBlind,
    );
    final borderColor = ThemeAccessibility.resolveCardBorderColor(
      isDarkMode: isDark,
      isColorBlindMode: isColorBlind,
    );
    final borderWidth = ThemeAccessibility.resolveCardBorderWidth(
      isColorBlindMode: isColorBlind,
    );
    final textColor = ThemeAccessibility.resolveCardTextColor(
      surfaceColor,
      isDarkMode: isDark,
      isColorBlindMode: isColorBlind,
      applyCustomTextColor: false,
      customTextColor: Colors.white,
    );
    final textShadows = ThemeAccessibility.resolveCardTextShadow(
      cardSurface: surfaceColor,
      isColorBlindMode: isColorBlind,
      isBold: ThemeAccessibility.colorBlindBoldText,
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: isColorBlind
              ? Border.all(color: borderColor, width: borderWidth)
              : Border.all(
                  color: isDark ? Colors.white24 : Colors.transparent,
                  width: 1.0,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: card.imagePath != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: buildCardImage(
                          card.imagePath!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 60,
                                color: Colors.white70,
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image,
                          size: 60,
                          color: Colors.white70,
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  card.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: isColorBlind && ThemeAccessibility.colorBlindBoldText
                        ? FontWeight.w900
                        : FontWeight.bold,
                    color: textColor,
                    shadows: textShadows,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (card.subCards.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
