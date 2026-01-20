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
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor,
      automaticallyImplyLeading: false,
      leadingWidth: showPin && showBack ? 96 : 56,
      leading: (showPin || showBack)
          ? Row(
              children: [
                if (showPin)
                  IconButton(
                    icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                    onPressed: onTogglePin,
                  ),
                if (showBack)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onBack,
                  ),
              ],
            )
          : null,
      actions: isEditMode
          ? []
          : showMenu
              ? [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: onOpenMenu,
                  ),
                ]
              : [],
    );
  }
}
