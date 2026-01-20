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
    final resolvedBaseColor = baseColor ?? Colors.brown.shade600;
    final disabledColor = Colors.brown.shade300;
    final resolvedTextColor = textColor ?? Colors.white;
    return Container(
      width: 96,
      color: (baseColor ?? Colors.brown.shade600).withOpacity(0.9),
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
                  icon: Icons.menu,
                  label: 'Menu',
                  onTap: isPinned ? null : onOpenMenu,
                  color: isPinned ? disabledColor : resolvedBaseColor,
                  textColor: resolvedTextColor,
                ),
                _MenuButton(
                  icon: Icons.arrow_back,
                  label: 'Go back',
                  onTap: !isPinned && canGoBack ? onGoBack : null,
                  color:
                      !isPinned && canGoBack ? resolvedBaseColor : disabledColor,
                  textColor: resolvedTextColor,
                ),
                _MenuButton(
                  icon: Icons.home,
                  label: 'Home',
                  onTap: isPinned ? null : onHome,
                  color: isPinned ? disabledColor : resolvedBaseColor,
                  textColor: resolvedTextColor,
                ),
                _MenuButton(
                  icon: Icons.arrow_upward,
                  label: 'Up',
                  onTap: isPinned ? null : onUp,
                  color: isPinned ? disabledColor : resolvedBaseColor,
                  textColor: resolvedTextColor,
                ),
                _MenuButton(
                  icon: Icons.arrow_downward,
                  label: 'Down',
                  onTap: isPinned ? null : onDown,
                  color: isPinned ? disabledColor : resolvedBaseColor,
                  textColor: resolvedTextColor,
                ),
                _MenuButton(
                  icon: Icons.search,
                  label: 'Search',
                  onTap: isPinned ? null : onSearch,
                  color: isPinned ? disabledColor : resolvedBaseColor,
                  textColor: resolvedTextColor,
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: 84,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Column(
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
