import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final bool isEditMode;
  final VoidCallback onAdd;
  final VoidCallback onDone;
  final VoidCallback onCancel;
  final VoidCallback onOpenMenu;
  final Color backgroundColor;

  const HomeAppBar({
    Key? key,
    required this.title,
    required this.showBack,
    required this.onBack,
    required this.isEditMode,
    required this.onAdd,
    required this.onDone,
    required this.onCancel,
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
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            )
          : null,
      actions: isEditMode
          ? [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: onAdd,
              ),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: onDone,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onCancel,
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onOpenMenu,
              ),
            ],
    );
  }
}
