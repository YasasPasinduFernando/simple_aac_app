import 'package:flutter/material.dart';

class LandscapeMenu extends StatelessWidget {
  final bool isPinned;
  final bool canGoBack;
  final Color? baseColor;
  final Color? textColor;
  final VoidCallback onTogglePin;
  final VoidCallback onOpenMenu;
  final VoidCallback onGoBack;
  final VoidCallback onHome;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onSearch;

  const LandscapeMenu({
    Key? key,
    required this.isPinned,
    required this.canGoBack,
    this.baseColor,
    this.textColor,
    required this.onTogglePin,
    required this.onOpenMenu,
    required this.onGoBack,
    required this.onHome,
    required this.onUp,
    required this.onDown,
    required this.onSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final resolvedBaseColor = baseColor ?? const Color(0xFF0277BD);
    final disabledColor = resolvedBaseColor.withValues(alpha: 0.42);
    final resolvedTextColor = textColor ?? Colors.white;
    final disabledTextColor = resolvedTextColor.withValues(alpha: 0.55);
    return Container(
      width: 96,
      color: resolvedBaseColor.withValues(alpha: 0.94),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _MenuButton(
                  icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  label: 'Pin',
                  onTap: onTogglePin,
                  color: resolvedBaseColor,
                  textColor: resolvedTextColor,
                ),
                _MenuButton(
                  icon: Icons.menu_rounded,
                  label: 'Menu',
                  onTap: isPinned ? null : onOpenMenu,
                  color: isPinned ? disabledColor : resolvedBaseColor,
                  textColor: isPinned ? disabledTextColor : resolvedTextColor,
                ),
                _MenuButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Go back',
                  onTap: !isPinned && canGoBack ? onGoBack : null,
                  color:
                      !isPinned && canGoBack ? resolvedBaseColor : disabledColor,
                  textColor: !isPinned && canGoBack
                      ? resolvedTextColor
                      : disabledTextColor,
                ),
                _MenuButton(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  onTap: isPinned ? null : onHome,
                  color: isPinned ? disabledColor : resolvedBaseColor,
                  textColor: isPinned ? disabledTextColor : resolvedTextColor,
                ),
                _MenuButton(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Up',
                  onTap: isPinned ? null : onUp,
                  color: isPinned ? disabledColor : resolvedBaseColor,
                  textColor: isPinned ? disabledTextColor : resolvedTextColor,
                ),
                _MenuButton(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Down',
                  onTap: isPinned ? null : onDown,
                  color: isPinned ? disabledColor : resolvedBaseColor,
                  textColor: isPinned ? disabledTextColor : resolvedTextColor,
                ),
                _MenuButton(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  onTap: isPinned ? null : onSearch,
                  color: isPinned ? disabledColor : resolvedBaseColor,
                  textColor: isPinned ? disabledTextColor : resolvedTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        width: 84,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            elevation: onTap == null ? 0 : 1,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
