import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Child-friendly animated startup loading view for Simple AAC Sri Lanka.
///
/// Features:
/// 1. Subtle breathing scale pulse for the circular Simple AAC logo medallion.
/// 2. Three gently bobbing miniature AAC picture cards:
///    - Hello (butter-yellow #FFF1A2, 'assets/loading/hello_384.webp')
///    - Happy (powder-blue #C6EFFF, 'assets/loading/happy_384.webp')
///    - Play (pale peach #FFE1CA, 'assets/loading/play_384.webp')
/// 3. Three smooth pulsating blue loading dots.
/// 4. Solid pale ice-blue background (#EAF5FE) matching Android 12+ launch background.
/// 5. Localized loading copy in English, Sinhala, and Tamil.
/// 6. Automatic reduced-motion accessibility support (`MediaQuery.disableAnimations`).
/// 7. Single lightweight AnimationController with WidgetsBindingObserver pause/resume.
/// 8. Non-destructive error state with localized retry action if startup fails.
class ChildFriendlySplash extends StatefulWidget {
  final String language;
  final VoidCallback? onAnimationReady;
  final String? loadingTextOverride;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ChildFriendlySplash({
    Key? key,
    this.language = 'en',
    this.onAnimationReady,
    this.loadingTextOverride,
    this.errorMessage,
    this.onRetry,
  }) : super(key: key);

  @override
  State<ChildFriendlySplash> createState() => _ChildFriendlySplashState();
}

/// Typedef providing semantic clarity per ANIMATION_SPEC.md while preserving
/// full backward-compatibility with existing tests and call-sites.
typedef StartupLoadingView = ChildFriendlySplash;

class _ChildFriendlySplashState extends State<ChildFriendlySplash>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Continuous 1200ms repeating controller drives breathing, staggered card bobbing, and dots.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 380ms smooth ease-out entrance controller creates seamless handoff from native splash
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    final bool disableAnimations =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (disableAnimations) {
      _controller.value = 0.5;
      _entranceController.value = 1.0;
    } else {
      _controller.repeat();
      _entranceController.forward();
    }

    widget.onAnimationReady?.call();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final bool disableAnimations =
          WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
      if (!disableAnimations && !_controller.isAnimating && mounted) {
        _controller.repeat();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  String _getLoadingText(String lang) {
    if (widget.loadingTextOverride != null) {
      return widget.loadingTextOverride!;
    }
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

  String _getErrorText(String lang) {
    switch (lang.toLowerCase()) {
      case 'si':
        return 'කාඩ්පත් ලබාගැනීමට නොහැකි විය. කරුණාකර නැවත උත්සාහ කරන්න.';
      case 'ta':
        return 'பட அட்டைகளை ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';
      case 'en':
      default:
        return 'Unable to load cards. Please tap Retry.';
    }
  }

  String _getRetryButtonLabel(String lang) {
    switch (lang.toLowerCase()) {
      case 'si':
        return 'නැවත උත්සාහ කරන්න';
      case 'ta':
        return 'மீண்டும் முயற்சிக்கவும்';
      case 'en':
      default:
        return 'Retry';
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;
    final size = media.size;
    final isLandscape = size.width > size.height;

    // Responsive dimensions matching Android 12+ native splash 184dp medallion
    final logoSize = (isLandscape ? size.height * 0.36 : 184.0).clamp(150.0, 205.0);
    final cardSize = (logoSize * 0.38).clamp(58.0, 76.0);
    final loadingText = _getLoadingText(widget.language);

    final subContentGap = isLandscape ? 12.0 : 22.0;
    final textGap = isLandscape ? 12.0 : 20.0;
    final dotsGap = isLandscape ? 8.0 : 12.0;
    // Total vertical space occupied by content below the logo
    final subContentHeight = subContentGap + cardSize + textGap + 22.0 + dotsGap + 10.0;
    final initialLogoOffset = isLandscape ? (subContentHeight / 2.0) : 90.0;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF5FE),
      body: Stack(
        children: [
          // 1. Soft pastel background gradient and decorative shapes matching launch background
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEBF5FF),
                    Color(0xFFF3F9FF),
                    Color(0xFFEAF5FE),
                  ],
                ),
              ),
              child: CustomPaint(
                painter: _SoftPastelBackgroundPainter(),
              ),
            ),
          ),

          // 2. Central content layout perfectly aligned with native splash
          Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with subtle breathing pulse and seamless glide from screen center
                  AnimatedBuilder(
                    animation: Listenable.merge([_controller, _entranceController]),
                    builder: (context, child) {
                      final t = _controller.value;
                      final entrance = _entranceAnimation.value;
                      // Smooth sinusoidal scale pulse between 0.985 and 1.02
                      final scale = reduceMotion
                          ? 1.0
                          : 1.0 + 0.018 * math.sin(t * 2 * math.pi);
                      final offsetY = reduceMotion ? 0.0 : initialLogoOffset * (1.0 - entrance);
                      return Transform.translate(
                        offset: Offset(0, offsetY),
                        child: Transform.scale(
                          scale: scale,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: const ValueKey('splash_logo_container'),
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFBAE6FD).withValues(alpha: 0.6),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.28),
                            blurRadius: 28,
                            spreadRadius: 4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all((logoSize * 0.08).clamp(12.0, 18.0)),
                      child: Image.asset(
                        'assets/loading/logo_transparent_640.webp',
                        key: const ValueKey('splash_logo_image'),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/simple_aac_logo_transparent.png',
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
                          );
                        },
                      ),
                    ),
                  ),

                  // Sub-content: cards, loading text, and dots gracefully fade and float in
                  AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) {
                      final entrance = _entranceAnimation.value;
                      final opacity = reduceMotion ? 1.0 : entrance.clamp(0.0, 1.0);
                      final slideY = reduceMotion ? 0.0 : 18.0 * (1.0 - entrance);
                      return Opacity(
                        key: const ValueKey('splash_subcontent_opacity'),
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, slideY),
                          child: child,
                        ),
                      );
                    },
                    child: widget.errorMessage != null
                        ? _buildErrorView()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: subContentGap),

                              // Three gently bobbing miniature AAC picture cards: Hello, Happy, Play
                              AnimatedBuilder(
                                animation: _controller,
                                builder: (context, _) {
                                  final t = _controller.value;
                                  // Staggered sinusoidal bounce offsets (0 -> -4dp -> 0) and subtle scale (1 -> 1.025 -> 1)
                                  // Card 1: Hello (phase 0)
                                  final wave1 = math.max(0.0, math.sin(t * 2 * math.pi));
                                  final bounce1 = reduceMotion ? 0.0 : -4.5 * wave1;
                                  final scale1 = reduceMotion ? 1.0 : 1.0 + 0.025 * wave1;

                                  // Card 2: Happy (offset by 160ms -> phase 0.133)
                                  final t2 = (t + (160.0 / 1200.0)) % 1.0;
                                  final wave2 = math.max(0.0, math.sin(t2 * 2 * math.pi));
                                  final bounce2 = reduceMotion ? 0.0 : -4.5 * wave2;
                                  final scale2 = reduceMotion ? 1.0 : 1.0 + 0.025 * wave2;

                                  // Card 3: Play (offset by 320ms -> phase 0.267)
                                  final t3 = (t + (320.0 / 1200.0)) % 1.0;
                                  final wave3 = math.max(0.0, math.sin(t3 * 2 * math.pi));
                                  final bounce3 = reduceMotion ? 0.0 : -4.5 * wave3;
                                  final scale3 = reduceMotion ? 1.0 : 1.0 + 0.025 * wave3;

                                  return ExcludeSemantics(
                                    child: Row(
                                      key: const ValueKey('splash_cards_row'),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Card 1: Hello (Butter-yellow pastel #FFF1A2, tilted left)
                                        Transform.translate(
                                          offset: Offset(0, bounce1),
                                          child: Transform.scale(
                                            scale: scale1,
                                            child: Transform.rotate(
                                              angle: -0.06,
                                              child: _buildMiniCard(
                                                cardSize: cardSize,
                                                bgColor: const Color(0xFFFFF1A2),
                                                borderColor: const Color(0xFFFFE082),
                                                sparkleColor: const Color(0xFFFBC02D),
                                                hasSparkleLeft: true,
                                                imagePath: 'assets/loading/hello_384.webp',
                                                fallbackImagePath: 'assets/images/starter_pack_v8/feelings_happy.webp',
                                                fallbackIcon: Icons.waving_hand_rounded,
                                                fallbackIconColor: const Color(0xFFF59E0B),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Card 2: Happy (Powder-blue pastel #C6EFFF, center)
                                        Transform.translate(
                                          offset: Offset(0, bounce2),
                                          child: Transform.scale(
                                            scale: scale2,
                                            child: Transform.rotate(
                                              angle: 0.02,
                                              child: _buildMiniCard(
                                                cardSize: cardSize,
                                                bgColor: const Color(0xFFC6EFFF),
                                                borderColor: const Color(0xFF90CAF9),
                                                sparkleColor: const Color(0xFF0284C7),
                                                hasSparkleLeft: false,
                                                imagePath: 'assets/loading/happy_384.webp',
                                                fallbackImagePath: 'assets/images/starter_pack_v8/feelings_happy.webp',
                                                fallbackIcon: Icons.sentiment_satisfied_alt_rounded,
                                                fallbackIconColor: const Color(0xFF0284C7),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Card 3: Play (Pale peach pastel #FFE1CA, tilted right)
                                        Transform.translate(
                                          offset: Offset(0, bounce3),
                                          child: Transform.scale(
                                            scale: scale3,
                                            child: Transform.rotate(
                                              angle: 0.07,
                                              child: _buildMiniCard(
                                                cardSize: cardSize,
                                                bgColor: const Color(0xFFFFE1CA),
                                                borderColor: const Color(0xFFFFCCBC),
                                                sparkleColor: const Color(0xFFF97316),
                                                hasSparkleLeft: false,
                                                hasSparkleRight: true,
                                                imagePath: 'assets/loading/play_384.webp',
                                                fallbackImagePath: 'assets/images/starter_pack_v8/activities_play_games.webp',
                                                fallbackIcon: Icons.sports_esports_rounded,
                                                fallbackIconColor: const Color(0xFFEA580C),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: textGap),

                              // Localized child-friendly loading text with accessible semantics
                              Semantics(
                                label: loadingText,
                                child: Text(
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
                              ),

                              SizedBox(height: dotsGap),

                              // Smooth animated loading dots (ExcludeSemantics prevents spamming screen readers)
                              ExcludeSemantics(
                                child: AnimatedBuilder(
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
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final errorText = _getErrorText(widget.language);
    final retryLabel = _getRetryButtonLabel(widget.language);

    return Container(
      key: const ValueKey('splash_error_container'),
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(
            errorText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              key: const ValueKey('splash_retry_button'),
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                retryLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
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
    required String fallbackImagePath,
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
          padding: const EdgeInsets.all(7),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  fallbackImagePath,
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
