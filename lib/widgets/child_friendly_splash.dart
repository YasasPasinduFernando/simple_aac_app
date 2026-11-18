import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Child-friendly animated splash screen widget for Simple AAC Sri Lanka.
///
/// Features:
/// 1. Subtle breathing animation for the circular Simple AAC logo.
/// 2. Three gently bouncing AAC picture cards (Happy smiley, Love heart, Red apple).
/// 3. Smooth animated loading dots.
/// 4. Soft pastel sky-blue gradient background with decorative pastel shapes.
/// 5. Localized loading text in English, Sinhala, and Tamil.
/// 6. Automatic reduced-motion accessibility support (`MediaQuery.disableAnimations`).
/// 7. Single lightweight AnimationController driving all animations with zero extra dependencies.
class ChildFriendlySplash extends StatefulWidget {
  final String language;
  final VoidCallback? onAnimationReady;

  const ChildFriendlySplash({
    Key? key,
    this.language = 'en',
    this.onAnimationReady,
  }) : super(key: key);

  @override
  State<ChildFriendlySplash> createState() => _ChildFriendlySplashState();
}

class _ChildFriendlySplashState extends State<ChildFriendlySplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A single 2400ms repeating controller drives breathing, card bouncing, and dots.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    widget.onAnimationReady?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getLoadingText(String lang) {
    switch (lang.toLowerCase()) {
      case 'si':
        return 'ඔබගේ පින්තූර කාඩ්පත් සූදානම් කරමින්...';
      case 'ta':
        return 'உங்கள் பட அட்டைகள் தயாராகின்றன...';
      case 'en':
      default:
        return 'Getting your picture cards ready...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;
    final size = media.size;
    final isLandscape = size.width > size.height;

    // Responsive dimensions
    final logoSize = (isLandscape ? size.height * 0.36 : size.width * 0.52)
        .clamp(140.0, 230.0);
    final cardSize = (logoSize * 0.36).clamp(58.0, 78.0);
    final loadingText = _getLoadingText(widget.language);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF5FE),
      body: Stack(
        children: [
          // 1. Soft pastel background gradient and decorative shapes
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEBF5FF),
                    Color(0xFFF3F9FF),
                    Color(0xFFEAF2FD),
                  ],
                ),
              ),
              child: CustomPaint(
                painter: _SoftPastelBackgroundPainter(),
              ),
            ),
          ),

          // 2. Central content layout
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isLandscape) SizedBox(height: size.height * 0.04),

                    // Logo with subtle breathing pulse
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final t = _controller.value;
                        // Smooth sinusoidal scale pulse between 0.98 and 1.025
                        final scale = reduceMotion
                            ? 1.0
                            : 1.0 + 0.022 * math.sin(t * 2 * math.pi);
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.28),
                              blurRadius: 28,
                              spreadRadius: 4,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/starter_pack_v8/starter_default.webp',
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF0284C7),
                                child: const Center(
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Colors.white,
                                    size: 56,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isLandscape ? 12 : 24),

                    // Three gently bouncing AAC picture cards
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final t = _controller.value;
                        // Staggered sinusoidal bounce offsets for the 3 cards
                        final bounce1 = reduceMotion
                            ? 0.0
                            : -6.5 * math.max(0.0, math.sin(t * 2 * math.pi));
                        final bounce2 = reduceMotion
                            ? 0.0
                            : -8.0 *
                                math.max(
                                    0.0,
                                    math.sin(
                                        (t * 2 * math.pi) + (math.pi / 3)));
                        final bounce3 = reduceMotion
                            ? 0.0
                            : -6.5 *
                                math.max(
                                    0.0,
                                    math.sin(
                                        (t * 2 * math.pi) + (2 * math.pi / 3)));

                        return Row(
                          key: const ValueKey('splash_cards_row'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Card 1: Happy Smiley (Yellow pastel, tilted left)
                            Transform.translate(
                              offset: Offset(0, bounce1),
                              child: Transform.rotate(
                                angle: -0.07,
                                child: _buildMiniCard(
                                  cardSize: cardSize,
                                  bgColor: const Color(0xFFFFF9C4),
                                  borderColor: const Color(0xFFFFF176),
                                  sparkleColor: const Color(0xFFFBC02D),
                                  hasSparkleLeft: true,
                                  imagePath:
                                      'assets/images/starter_pack_v8/feelings_happy.webp',
                                  fallbackIcon: Icons.sentiment_satisfied_alt_rounded,
                                  fallbackIconColor: const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Card 2: Speech Heart (Mint pastel, slight tilt)
                            Transform.translate(
                              offset: Offset(0, bounce2),
                              child: Transform.rotate(
                                angle: 0.03,
                                child: _buildMiniCard(
                                  cardSize: cardSize,
                                  bgColor: const Color(0xFFE0F2F1),
                                  borderColor: const Color(0xFFB2DFDB),
                                  sparkleColor: const Color(0xFF26A69A),
                                  hasSparkleLeft: false,
                                  imagePath:
                                      'assets/images/starter_pack_v8/feelings_love.webp',
                                  fallbackIcon: Icons.favorite_rounded,
                                  fallbackIconColor: const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Card 3: Apple (Pink pastel, tilted right)
                            Transform.translate(
                              offset: Offset(0, bounce3),
                              child: Transform.rotate(
                                angle: 0.08,
                                child: _buildMiniCard(
                                  cardSize: cardSize,
                                  bgColor: const Color(0xFFFCE4EC),
                                  borderColor: const Color(0xFFF8BBD0),
                                  sparkleColor: const Color(0xFFEC4899),
                                  hasSparkleLeft: false,
                                  hasSparkleRight: true,
                                  imagePath:
                                      'assets/images/starter_pack_v8/food_apple.webp',
                                  fallbackIcon: Icons.apple_rounded,
                                  fallbackIconColor: const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    SizedBox(height: isLandscape ? 12 : 24),

                    // Localized child-friendly loading text
                    Text(
                      loadingText,
                      key: const ValueKey('splash_loading_text'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F2C59),
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Smooth animated loading dots
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final t = _controller.value;
                        return Row(
                          key: const ValueKey('splash_dots_row'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPulsingDot(0, t, reduceMotion),
                            const SizedBox(width: 8),
                            _buildPulsingDot(1, t, reduceMotion),
                            const SizedBox(width: 8),
                            _buildPulsingDot(2, t, reduceMotion),
                          ],
                        );
                      },
                    ),

                    if (!isLandscape) SizedBox(height: size.height * 0.04),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard({
    required double cardSize,
    required Color bgColor,
    required Color borderColor,
    required Color sparkleColor,
    required String imagePath,
    required IconData fallbackIcon,
    required Color fallbackIconColor,
    bool hasSparkleLeft = false,
    bool hasSparkleRight = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    fallbackIcon,
                    color: fallbackIconColor,
                    size: cardSize * 0.55,
                  ),
                );
              },
            ),
          ),
        ),

        // Little sparkle rays (decorative accents matching visual reference)
        if (hasSparkleLeft)
          Positioned(
            top: -6,
            left: -6,
            child: Icon(Icons.auto_awesome, size: 14, color: sparkleColor),
          ),
        if (hasSparkleRight)
          Positioned(
            top: -6,
            right: -6,
            child: Icon(Icons.auto_awesome, size: 14, color: sparkleColor),
          ),
      ],
    );
  }

  Widget _buildPulsingDot(int index, double progress, bool reduceMotion) {
    if (reduceMotion) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF38BDF8),
          shape: BoxShape.circle,
        ),
      );
    }

    // Staggered phase offset for 3 dots: 0, 0.28, 0.56
    final phase = index * 0.28;
    final wave = math.sin((progress * 2 * math.pi) + (phase * 2 * math.pi));
    final scale = 0.75 + (0.35 * (wave + 1) / 2);
    final opacity = 0.35 + (0.65 * (wave + 1) / 2);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFF38BDF8).withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Custom painter for the soft pastel background shapes matching the design mockup.
class _SoftPastelBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft pastel cyan bubble top-right
    final cyanPaint = Paint()
      ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.16),
      size.width * 0.14,
      cyanPaint,
    );

    // 2. Soft pastel purple/pink bubble middle-right
    final pinkPaint = Paint()
      ..color = const Color(0xFFFBCFE8).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.94, size.height * 0.55),
      size.width * 0.10,
      pinkPaint,
    );

    // 3. Soft pastel lavender bubble middle-left
    final lavenderPaint = Paint()
      ..color = const Color(0xFFDDD6FE).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.38),
      size.width * 0.11,
      lavenderPaint,
    );

    // 4. Soft wave at the bottom
    final wavePaint = Paint()
      ..color = const Color(0xFFC7D2FE).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.93)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.89,
        size.width * 0.70,
        size.height * 0.94,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.96,
        size.width,
        size.height * 0.92,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
