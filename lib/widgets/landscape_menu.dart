import 'package:flutter/material.dart';

class LandscapeMenu extends StatelessWidget {
  final bool showPin;
  final bool isPinned;
  final bool canGoBack;
  final Color? baseColor;
  final Color? textColor;
  final VoidCallback onTogglePin;
  final VoidCallback? onUnpinLongPress;
  final VoidCallback? onPinTapWhenPinned;
  final VoidCallback onOpenMenu;
  final VoidCallback onGoBack;
  final VoidCallback onHome;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onSearch;
  final bool showHorizontalArrows;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;
  final bool canScrollLeft;
  final bool canScrollRight;
  final VoidCallback? onOrientation;

  const LandscapeMenu({
    Key? key,
    this.showPin = true,
    required this.isPinned,
    required this.canGoBack,
    this.baseColor,
    this.textColor,
    required this.onTogglePin,
    this.onUnpinLongPress,
    this.onPinTapWhenPinned,
    required this.onOpenMenu,
    required this.onGoBack,
    required this.onHome,
    required this.onUp,
    required this.onDown,
    required this.onSearch,
    this.showHorizontalArrows = false,
    this.onLeft,
    this.onRight,
    this.canScrollLeft = false,
    this.canScrollRight = false,
    this.onOrientation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final resolvedBaseColor = baseColor ?? const Color(0xFF0277BD);
    final disabledColor = resolvedBaseColor.withValues(alpha: 0.42);
    final resolvedTextColor = textColor ?? Colors.white;
    final disabledTextColor = resolvedTextColor.withValues(alpha: 0.55);
    final double menuWidth = showHorizontalArrows ? 108.0 : 96.0;

    return Container(
      width: menuWidth,
      color: resolvedBaseColor.withValues(alpha: 0.94),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                if (showPin)
                  _MenuButton(
                    key: const ValueKey('landscape_nav_pin'),
                    icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    label: isPinned ? 'Pinned' : 'Pin',
                    onTap: isPinned ? onPinTapWhenPinned : onTogglePin,
                    onLongPress: isPinned ? onUnpinLongPress : null,
                    color: resolvedBaseColor,
                    textColor: resolvedTextColor,
                    width: showHorizontalArrows ? 96 : 84,
                  ),
                _MenuButton(
                  key: const ValueKey('landscape_nav_menu'),
                  icon: Icons.menu_rounded,
                  label: 'Menu',
                  onTap: isPinned ? null : onOpenMenu,
                  color: isPinned ? disabledColor : resolvedBaseColor,
                  textColor: isPinned ? disabledTextColor : resolvedTextColor,
                  width: showHorizontalArrows ? 96 : 84,
                ),
                _MenuButton(
                  key: const ValueKey('landscape_nav_back'),
                  icon: Icons.arrow_back_rounded,
                  label: 'Go back',
                  onTap: !isPinned && canGoBack ? onGoBack : null,
                  color:
                      !isPinned && canGoBack ? resolvedBaseColor : disabledColor,
                  textColor: !isPinned && canGoBack
                      ? resolvedTextColor
                      : disabledTextColor,
                  width: showHorizontalArrows ? 96 : 84,
                ),
                _MenuButton(
                  key: const ValueKey('landscape_nav_home'),
                  icon: Icons.home_rounded,
                  label: 'Home',
                  onTap: isPinned ? null : onHome,
                  color: isPinned ? disabledColor : resolvedBaseColor,
                  textColor: isPinned ? disabledTextColor : resolvedTextColor,
                  width: showHorizontalArrows ? 96 : 84,
                ),
                if (!showHorizontalArrows) ...[
                  _MenuButton(
                    key: const ValueKey('landscape_nav_up'),
                    icon: Icons.arrow_upward_rounded,
                    label: 'Up',
                    onTap: isPinned ? null : onUp,
                    color: isPinned ? disabledColor : resolvedBaseColor,
                    textColor: isPinned ? disabledTextColor : resolvedTextColor,
                    width: 84,
                  ),
                  _MenuButton(
                    key: const ValueKey('landscape_nav_down'),
                    icon: Icons.arrow_downward_rounded,
                    label: 'Down',
                    onTap: isPinned ? null : onDown,
                    color: isPinned ? disabledColor : resolvedBaseColor,
                    textColor: isPinned ? disabledTextColor : resolvedTextColor,
                    width: 84,
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: _CompactMenuButton(
                            key: const ValueKey('landscape_nav_up'),
                            icon: Icons.arrow_upward_rounded,
                            label: 'Up',
                            onTap: isPinned ? null : onUp,
                            color: isPinned ? disabledColor : resolvedBaseColor,
                            textColor: isPinned ? disabledTextColor : resolvedTextColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _CompactMenuButton(
                            key: const ValueKey('landscape_nav_right'),
                            icon: Icons.arrow_forward_rounded,
                            label: 'Right',
                            onTap: isPinned || !canScrollRight ? null : onRight,
                            color: isPinned || !canScrollRight ? disabledColor : resolvedBaseColor,
                            textColor: isPinned || !canScrollRight ? disabledTextColor : resolvedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: _CompactMenuButton(
                            key: const ValueKey('landscape_nav_left'),
                            icon: Icons.arrow_back_rounded,
                            label: 'Left',
                            onTap: isPinned || !canScrollLeft ? null : onLeft,
                            color: isPinned || !canScrollLeft ? disabledColor : resolvedBaseColor,
                            textColor: isPinned || !canScrollLeft ? disabledTextColor : resolvedTextColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _CompactMenuButton(
                            key: const ValueKey('landscape_nav_down'),
                            icon: Icons.arrow_downward_rounded,
                            label: 'Down',
                            onTap: isPinned ? null : onDown,
                            color: isPinned ? disabledColor : resolvedBaseColor,
                            textColor: isPinned ? disabledTextColor : resolvedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _MenuButton(
                  key: const ValueKey('landscape_nav_search'),
                  icon: Icons.search_rounded,
                  label: 'Search',
                  onTap: isPinned ? null : onSearch,
                  color: isPinned ? disabledColor : resolvedBaseColor,
                  textColor: isPinned ? disabledTextColor : resolvedTextColor,
                  width: showHorizontalArrows ? 96 : 84,
                ),
                if (!isPinned)
                  _MenuButton(
                    key: const ValueKey('landscape_nav_orientation'),
                    icon: Icons.screen_rotation_rounded,
                    label: 'Orientation',
                    onTap: onOrientation,
                    color: resolvedBaseColor,
                    textColor: resolvedTextColor,
                    width: showHorizontalArrows ? 96 : 84,
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
  final VoidCallback? onLongPress;
  final Color color;
  final Color textColor;
  final double width;

  const _MenuButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
    required this.color,
    required this.textColor,
    this.width = 84,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        width: width,
        child: ElevatedButton(
          onPressed: onTap,
          onLongPress: onLongPress,
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

class _CompactMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;

  const _CompactMenuButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: onTap == null ? 0 : 1,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
