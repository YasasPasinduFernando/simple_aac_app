import 'package:flutter/material.dart';

/// Shared Material 3 dialog title header with a tinted icon badge.
class StyledDialogHeader extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String? subtitle;
  final Color? accentColor;
  final Widget? trailing;

  const StyledDialogHeader({
    Key? key,
    this.icon,
    this.iconWidget,
    required this.title,
    this.subtitle,
    this.accentColor,
    this.trailing,
  }) : assert(icon != null || iconWidget != null),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = accentColor ?? colorScheme.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: iconWidget ?? Icon(icon!, color: tint, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 4),
          trailing!,
        ],
      ],
    );
  }
}

/// Reusable Material 3 selectable list option card with leading icon badge.
class DialogOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badgeText;
  final bool selected;
  final Color? accentColor;
  final VoidCallback onTap;

  const DialogOptionTile({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.selected = false,
    this.accentColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = accentColor ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: selected
            ? tint.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? tint : colorScheme.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? tint.withValues(alpha: 0.18)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: badgeText != null
                      ? Text(
                          badgeText!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected ? tint : colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Icon(
                          icon,
                          size: 20,
                          color: selected ? tint : colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  size: 20,
                  color: selected ? tint : colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Crisp magnifying-glass lens icon with a subtle glass reflection highlight
/// for Smart Image Search controls.
class SmartSearchIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SmartSearchIcon({
    Key? key,
    this.size = 20,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _MagnifierLensPainter(
            color: color,
            glossOpacity: isDark ? 0.55 : 0.85,
          ),
        ),
      ),
    );
  }
}

class _MagnifierLensPainter extends CustomPainter {
  final Color color;
  final double glossOpacity;

  const _MagnifierLensPainter({
    required this.color,
    required this.glossOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(s * 0.42, s * 0.42);
    final radius = s * 0.275;

    final lensRect = Rect.fromCircle(center: center, radius: radius);
    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0.08),
        ],
      ).createShader(lensRect);
    canvas.drawCircle(center, radius, glassPaint);

    // Curved specular highlight inside the upper-left glass surface.
    final glarePaint = Paint()
      ..color = Colors.white.withValues(alpha: glossOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.065
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.58),
      -2.55,
      1.15,
      false,
      glarePaint,
    );

    final rimPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.115;
    canvas.drawCircle(center, radius, rimPaint);

    final rimAttach = Offset(
      center.dx + radius * 0.7071,
      center.dy + radius * 0.7071,
    );
    final handlePaint = Paint()
      ..color = color
      ..strokeWidth = s * 0.145
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(rimAttach, Offset(s * 0.87, s * 0.87), handlePaint);
  }

  @override
  bool shouldRepaint(_MagnifierLensPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glossOpacity != glossOpacity;
}
