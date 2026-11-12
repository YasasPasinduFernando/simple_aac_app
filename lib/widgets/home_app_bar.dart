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

    final screenWidth = MediaQuery.sizeOf(context).width;
    final titleFontSize = screenWidth < 360
        ? 21.0
        : (screenWidth < 400 ? 23.0 : 25.0);

    final showLeading = showPin || showBack;

    return AppBar(
      backgroundColor: base,
      foregroundColor: fgColor,
      elevation: 2,
      shadowColor: Colors.black26,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [lighter, darker],
              ),
            ),
          ),
          const CustomPaint(
            painter: _HeaderWavePainter(waveColor: Colors.white),
          ),
        ],
      ),
      leadingWidth: (showPin && showBack)
          ? 116.0
          : (showLeading ? 64.0 : 0.0),
      leading: showLeading
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
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showLeading)
            Container(
              height: 24,
              width: 1.2,
              margin: const EdgeInsets.only(left: 4, right: 12),
              decoration: BoxDecoration(
                color: fgColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          Expanded(
            child: titleWidget ??
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: titleFontSize,
                    letterSpacing: 0.2,
                    color: fgColor,
                  ),
                ),
          ),
        ],
      ),
      actions: isEditMode
          ? const []
          : (showMenu
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
              : const []),
    );
  }
}

class _HeaderWavePainter extends CustomPainter {
  final Color waveColor;

  const _HeaderWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Back gentle wave crest
    final path1 = Path()
      ..moveTo(0, size.height * 0.30)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.08,
        size.width * 0.50,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.80,
        size.width,
        size.height * 0.42,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final paint1 = Paint()
      ..color = waveColor.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path1, paint1);

    // Front soft organic wave accent (top-left)
    final path2 = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.16,
        size.height * 0.22,
        size.width * 0.38,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.78,
        size.width * 0.82,
        0,
      )
      ..lineTo(0, 0)
      ..close();

    final paint2 = Paint()
      ..color = waveColor.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _HeaderWavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor;
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
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.28),
              width: 1.0,
            ),
          ),
          child: IconButton(
            tooltip: tooltip,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: EdgeInsets.zero,
            splashRadius: 24,
            icon: Icon(icon, size: 23, color: color),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
