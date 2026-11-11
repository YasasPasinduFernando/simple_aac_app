import 'package:flutter/material.dart';

import '../models/tts_token.dart';
import '../utils/card_image.dart';

class TtsBar extends StatelessWidget {
  final List<TtsToken> tokens;
  final bool isTablet;
  final VoidCallback onDelete;
  final VoidCallback onClear;
  final VoidCallback onSpeak;
  final Color? speakerColor;
  final double sizeFactor;
  final bool showActions;
  final bool showText;

  const TtsBar({
    Key? key,
    required this.tokens,
    required this.isTablet,
    required this.onDelete,
    required this.onClear,
    required this.onSpeak,
    this.speakerColor,
    this.sizeFactor = 1.0,
    this.showActions = true,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = speakerColor ?? colorScheme.primary;
    final barBg = isDark ? const Color(0xFF1B2027) : Colors.grey.shade100;
    final chipBg = isDark ? const Color(0xFF252B34) : Colors.white;
    final borderColor = isDark ? const Color(0xFF333B47) : Colors.grey.shade300;
    final hasTokens = tokens.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (isTablet ? 16 : 12) * sizeFactor,
        vertical: (isTablet ? 10 : 8) * sizeFactor,
      ),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: !hasTokens
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4 * sizeFactor),
                    child: Text(
                      'Tap cards to build a sentence...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: (isTablet ? 15 : 13) * sizeFactor,
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: tokens.map((token) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * sizeFactor,
                              vertical: 4 * sizeFactor,
                            ),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: SizedBox(
                                    width: 26 * sizeFactor,
                                    height: 26 * sizeFactor,
                                    child: token.imagePath != null
                                        ? buildCardImage(
                                            token.imagePath!,
                                            fit: BoxFit.cover,
                                            cacheWidth: 120,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(Icons.image,
                                                  size: 16 * sizeFactor);
                                            },
                                          )
                                        : Icon(Icons.image,
                                            size: 16 * sizeFactor),
                                  ),
                                ),
                                if (showText) ...[
                                  SizedBox(width: 6 * sizeFactor),
                                  Text(
                                    token.label,
                                    style: TextStyle(
                                      fontSize:
                                          (isTablet ? 14 : 12) * sizeFactor,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          SizedBox(width: 6 * sizeFactor),
          if (showActions)
            Row(
              children: [
                _TtsActionPill(
                  icon: Icons.backspace_outlined,
                  label: 'Delete',
                  sizeFactor: sizeFactor,
                  enabled: hasTokens,
                  backgroundColor: chipBg,
                  borderColor: borderColor,
                  onTap: onDelete,
                ),
                SizedBox(width: 4 * sizeFactor),
                _TtsActionPill(
                  icon: Icons.clear_rounded,
                  label: 'Clear',
                  sizeFactor: sizeFactor,
                  enabled: hasTokens,
                  backgroundColor: chipBg,
                  borderColor: borderColor,
                  onTap: onClear,
                ),
              ],
            ),
          SizedBox(width: 6 * sizeFactor),
          Material(
            color: accent,
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              tooltip: 'Speak sentence',
              icon: Icon(Icons.volume_up_rounded,
                  size: (isTablet ? 34 : 26) * sizeFactor),
              color: ThemeData.estimateBrightnessForColor(accent) ==
                      Brightness.light
                  ? Colors.black87
                  : Colors.white,
              onPressed: onSpeak,
            ),
          ),
        ],
      ),
    );
  }
}

class _TtsActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final double sizeFactor;
  final bool enabled;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _TtsActionPill({
    required this.icon,
    required this.label,
    required this.sizeFactor,
    required this.enabled,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.45);
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 7 * sizeFactor,
            vertical: 5 * sizeFactor,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16 * sizeFactor, color: color),
              SizedBox(height: 1 * sizeFactor),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9 * sizeFactor,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
