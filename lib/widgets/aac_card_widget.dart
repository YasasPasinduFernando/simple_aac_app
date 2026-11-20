import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';
import '../services/starter_pack_service.dart';
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
    final effectiveColorValue = StarterPackService.resolveCardColorValue(card);
    final surfaceColor = ThemeAccessibility.resolveCardSurface(
      Color(effectiveColorValue),
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

    final isDefaultFolderCover = card.id == 'simpleaac.starter.v2.default' &&
        (card.imagePath == null ||
            card.imagePath!.isEmpty ||
            card.imagePath == 'assets/images/starter_pack_v8/starter_default.webp' ||
            card.imagePath == 'assets/home/default_folder_cover.webp');

    final effectiveImagePath = isDefaultFolderCover
        ? 'assets/home/default_folder_cover.webp'
        : card.imagePath;

    final isUserPhoto = effectiveImagePath != null &&
        effectiveImagePath.isNotEmpty &&
        !isAssetImagePath(effectiveImagePath);

    final isHomeChildCard = (card.id == 'seed_hello' ||
            card.id == 'seed_happy' ||
            card.id == 'seed_sad' ||
            card.id == 'seed_angry' ||
            card.id == 'seed_more') &&
        (effectiveImagePath != null &&
            (effectiveImagePath.startsWith('assets/home/') ||
                effectiveImagePath.contains('home/hello') ||
                effectiveImagePath.contains('home/happy') ||
                effectiveImagePath.contains('home/sad') ||
                effectiveImagePath.contains('home/angry') ||
                effectiveImagePath.contains('seed_v2/more') ||
                effectiveImagePath.contains('seed/blocks')));

    final isFullBleedCard =
        isUserPhoto || isDefaultFolderCover || isHomeChildCard;

    final effectiveSurfaceColor = isFullBleedCard
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
        : surfaceColor;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: effectiveSurfaceColor,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: isFullBleedCard && effectiveImagePath != null
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: buildCardImage(
                        effectiveImagePath,
                        fit: BoxFit.cover,
                        targetLogicalWidth: 160,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.white70,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(6, 16, 6, 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.40),
                              Colors.black.withOpacity(0.80),
                            ],
                            stops: const [0.0, 0.40, 1.0],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                card.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black,
                                      offset: Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (card.subCards.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
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
                                  fit: (isUserPhoto || isDefaultFolderCover)
                                      ? BoxFit.cover
                                      : BoxFit.contain,
                                  width: double.infinity,
                                  targetLogicalWidth: 160,
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
      ),
    );
  }
}
