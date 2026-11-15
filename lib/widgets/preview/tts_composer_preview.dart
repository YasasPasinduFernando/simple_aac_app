import 'package:flutter/material.dart';

/// Live preview widget for the TTS / Speech Composer bar sizing dialog.
/// Displays an authentic sample sentence ("I want", "Water") with speaker button
/// and reflects height scaling and Delete/Clear toggle in real time.
class TtsComposerPreview extends StatelessWidget {
  final double sizeFactor;
  final bool showActions;
  final bool showDelete;
  final bool showClear;
  final bool showText;
  final Color? speakerColor;

  const TtsComposerPreview({
    Key? key,
    required this.sizeFactor,
    this.showActions = true,
    bool? showDelete,
    bool? showClear,
    this.showText = true,
    this.speakerColor,
  })  : showDelete = showDelete ?? showActions,
        showClear = showClear ?? showActions,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = speakerColor ??
        (isDark ? const Color(0xFF60A5FA) : const Color(0xFF0267C1));

    final barBg = isDark ? const Color(0xFF1E2632) : Colors.white;
    final barBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    // Clamped responsive dimensions so extreme scale factors remain readable and non-overflowing
    final clampedFactor = sizeFactor.clamp(0.5, 2.5);
    final barHeight = (54.0 * clampedFactor).clamp(40.0, 95.0);
    final iconBoxSize = (22.0 * clampedFactor).clamp(14.0, 32.0);
    final labelFontSize = (11.5 * clampedFactor).clamp(9.0, 14.5);
    final speakerDiameter = (36.0 * clampedFactor).clamp(26.0, 48.0);
    final speakerIconSize = (19.0 * clampedFactor).clamp(14.0, 26.0);

    return Container(
      width: double.infinity,
      height: barHeight,
      padding: EdgeInsets.symmetric(
        horizontal: (8.0 * clampedFactor).clamp(6.0, 14.0),
        vertical: (4.0 * clampedFactor).clamp(2.0, 8.0),
      ),
      decoration: BoxDecoration(
        color: barBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: barBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tokens scrollable area (matches real TtsBar)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Token 1: "I want"
                  _buildSampleToken(
                    context: context,
                    text: 'I want',
                    bgColor: isDark
                        ? const Color(0xFF4A3814)
                        : const Color(0xFFFFF1C2),
                    borderColor: isDark
                        ? const Color(0xFF785917)
                        : const Color(0xFFFDE047),
                    textColor: isDark
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFF713F12),
                    iconBoxSize: iconBoxSize,
                    fontSize: labelFontSize,
                    clampedFactor: clampedFactor,
                    isDark: isDark,
                    icon: Icons.person_rounded,
                  ),
                  SizedBox(width: (6.0 * clampedFactor).clamp(4.0, 10.0)),
                  // Token 2: "Water"
                  _buildSampleToken(
                    context: context,
                    text: 'Water',
                    bgColor: isDark
                        ? const Color(0xFF1E3A5F)
                        : const Color(0xFFD6E9FC),
                    borderColor: isDark
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF93C5FD),
                    textColor: isDark
                        ? const Color(0xFFBFDBFE)
                        : const Color(0xFF1E40AF),
                    iconBoxSize: iconBoxSize,
                    fontSize: labelFontSize,
                    clampedFactor: clampedFactor,
                    isDark: isDark,
                    icon: Icons.water_drop_rounded,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: (4.0 * clampedFactor).clamp(3.0, 8.0)),
          // Delete and Clear actions (matches real TtsBar)
          if (showDelete || showClear) ...[
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showDelete) ...[
                      _buildSampleActionPill(
                        icon: Icons.backspace_outlined,
                        label: 'Delete',
                        isDark: isDark,
                        clampedFactor: clampedFactor,
                      ),
                      if (showClear)
                        SizedBox(width: (4.0 * clampedFactor).clamp(3.0, 6.0)),
                    ],
                    if (showClear)
                      _buildSampleActionPill(
                        icon: Icons.clear_rounded,
                        label: 'Clear',
                        isDark: isDark,
                        clampedFactor: clampedFactor,
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: (4.0 * clampedFactor).clamp(3.0, 8.0)),
          ],
          // Speaker Action Button
          Container(
            width: speakerDiameter,
            height: speakerDiameter,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.volume_up_rounded,
              color: Colors.white,
              size: speakerIconSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleActionPill({
    required IconData icon,
    required String label,
    required bool isDark,
    required double clampedFactor,
  }) {
    final pillBg = isDark ? const Color(0xFF283548) : Colors.grey.shade100;
    final pillBorder = isDark ? const Color(0xFF475569) : Colors.grey.shade300;
    final textColor = isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (6.0 * clampedFactor).clamp(3.5, 8.0),
        vertical: (3.0 * clampedFactor).clamp(2.0, 6.0),
      ),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pillBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: (11.0 * clampedFactor).clamp(9.0, 14.0), color: textColor),
          SizedBox(width: (3.0 * clampedFactor).clamp(2.0, 4.0)),
          Text(
            label,
            style: TextStyle(
              fontSize: (9.5 * clampedFactor).clamp(8.0, 12.0),
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleToken({
    required BuildContext context,
    required String text,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required double iconBoxSize,
    required double fontSize,
    required double clampedFactor,
    required bool isDark,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (7.0 * clampedFactor).clamp(4.0, 12.0),
        vertical: (3.0 * clampedFactor).clamp(2.0, 6.0),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.65),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: (iconBoxSize * 0.75).clamp(10.0, 28.0),
              color: textColor,
            ),
          ),
          if (showText) ...[
            SizedBox(width: (5.0 * clampedFactor).clamp(3.0, 8.0)),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Compact header actions preview chip showing Delete and Clear when enabled.
  static Widget buildActionChips({
    bool? showActions,
    bool? showDelete,
    bool? showClear,
    required bool isDark,
  }) {
    final effectiveDelete = showDelete ?? showActions ?? true;
    final effectiveClear = showClear ?? showActions ?? true;

    if (!effectiveDelete && !effectiveClear) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (effectiveDelete) ...[
          _buildMiniChip(
            icon: Icons.backspace_outlined,
            label: 'Delete',
            isDark: isDark,
          ),
          if (effectiveClear) const SizedBox(width: 4),
        ],
        if (effectiveClear)
          _buildMiniChip(
            icon: Icons.close_rounded,
            label: 'Clear',
            isDark: isDark,
          ),
      ],
    );
  }

  static Widget _buildMiniChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final chipBg = isDark ? const Color(0xFF283548) : Colors.white;
    final chipBorder =
        isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
    final textColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
