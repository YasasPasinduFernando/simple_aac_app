import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return AppBar(
      title: titleWidget ??
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: titleTextColor,
            ),
          ),
      backgroundColor: base,
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
      leadingWidth: showPin && showBack ? 96 : 56,
      leading: (showPin || showBack)
          ? Row(
              children: [
                if (showPin)
                  _AppBarIconButton(
                    icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    onPressed: onTogglePin,
                  ),
                if (showBack)
                  _AppBarIconButton(
                    icon: Icons.arrow_back,
                    onPressed: onBack,
                  ),
              ],
            )
          : null,
      actions: isEditMode
          ? []
          : showMenu
              ? [
                  _AppBarIconButton(
                    icon: Icons.menu,
                    onPressed: onOpenMenu,
                  ),
                ]
              : [],
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _AppBarIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
