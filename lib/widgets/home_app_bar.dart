import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showPin;
  final bool isPinned;
  final VoidCallback? onTogglePin;
  final bool isEditMode;
  final bool showMenu;
  final VoidCallback onOpenMenu;
  final Color backgroundColor;
  final Widget? titleWidget;
  final Color? titleTextColor;

  const HomeAppBar({
    Key? key,
    required this.title,
    required this.showBack,
    required this.onBack,
    required this.showPin,
    required this.isPinned,
    required this.onTogglePin,
    required this.isEditMode,
    required this.showMenu,
    required this.onOpenMenu,
    required this.backgroundColor,
    this.titleWidget,
    this.titleTextColor,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final base = backgroundColor;
    final lighter = Color.lerp(base, Colors.white, 0.08)!;
    final darker = Color.lerp(base, Colors.black, 0.12)!;
    final fgColor = titleTextColor ??
        (ThemeData.estimateBrightnessForColor(base) == Brightness.dark
            ? Colors.white
            : Colors.black87);

    return AppBar(
      title: titleWidget ??
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: 0.3,
              color: fgColor,
            ),
          ),
      backgroundColor: base,
      foregroundColor: fgColor,
      elevation: 2,
      shadowColor: Colors.black26,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [lighter, darker],
          ),
        ),
      ),
      automaticallyImplyLeading: false,
      leadingWidth: showPin && showBack ? 124 : 68,
      leading: (showPin || showBack)
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showPin)
                    _AppBarIconButton(
                      icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: fgColor,
                      tooltip: isPinned ? 'Unlock board' : 'Pin board',
                      onPressed: onTogglePin,
                    ),
                  if (showBack)
                    _AppBarIconButton(
                      icon: Icons.arrow_back_rounded,
                      color: fgColor,
                      tooltip: 'Back',
                      onPressed: onBack,
                    ),
                ],
              ),
            )
          : null,
      actions: isEditMode
          ? []
          : showMenu
              ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _AppBarIconButton(
                      icon: Icons.menu_rounded,
                      color: fgColor,
                      tooltip: 'Menu',
                      onPressed: onOpenMenu,
                    ),
                  ),
                ]
              : [],
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  const _AppBarIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Ink(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: IconButton(
          tooltip: tooltip,
          constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 22, color: color),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
