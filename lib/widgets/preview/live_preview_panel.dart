import 'package:flutter/material.dart';

/// A reusable, responsive live preview container used across Simple AAC settings dialogs.
/// Displays an authentic "LIVE PREVIEW" badge and contains an immediate reactive miniature preview.
class LivePreviewPanel extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;
  final double minHeight;
  final double maxHeight;
  final EdgeInsetsGeometry padding;

  const LivePreviewPanel({
    Key? key,
    this.title = 'LIVE PREVIEW',
    this.icon,
    required this.child,
    this.trailing,
    this.minHeight = 110.0,
    this.maxHeight = 220.0,
    this.padding = const EdgeInsets.all(10.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final panelBg = isDark ? const Color(0xFF1E2836) : const Color(0xFFF2F7FD);
    final borderColor = isDark
        ? const Color(0xFF3B82F6).withValues(alpha: 0.35)
        : const Color(0xFF0267C1).withValues(alpha: 0.25);
    final badgeBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFF0267C1);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with LIVE badge and optional actions/controls
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Live Badge
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                        ] else ...[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF00E676),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: trailing!,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Bounded interactive child area
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: minHeight,
              maxHeight: maxHeight,
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
