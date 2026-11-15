import 'package:flutter/material.dart';

class TutorialSpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final double pulseProgress;
  final Color scrimColor;
  final Color pulseColor;
  final double borderRadius;
  final double padding;

  TutorialSpotlightPainter({
    required this.targetRect,
    required this.pulseProgress,
    this.scrimColor = const Color(0xB3000000), // 70% black
    this.pulseColor = const Color(0xFF2196F3),
    this.borderRadius = 14.0,
    this.padding = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullScreenRect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (targetRect == null) {
      // Draw plain scrim if no target measured yet
      canvas.drawRect(fullScreenRect, Paint()..color = scrimColor);
      return;
    }

    // Inflate target rect with padding
    final inflatedTarget = targetRect!.inflate(padding);

    // 1. Draw darkened backdrop with rounded cutout
    final backgroundPath = Path()..addRect(fullScreenRect);
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          inflatedTarget,
          Radius.circular(borderRadius),
        ),
      );

    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(combinedPath, Paint()..color = scrimColor);

    // 2. Draw border around cutout
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        inflatedTarget,
        Radius.circular(borderRadius),
      ),
      borderPaint,
    );

    // 3. Draw animated pulsing halo rings
    if (pulseProgress > 0) {
      final pulseInflation = 4.0 + (pulseProgress * 8.0);
      final pulseOpacity = (1.0 - pulseProgress).clamp(0.0, 1.0) * 0.75;

      final pulsePaint = Paint()
        ..color = pulseColor.withOpacity(pulseOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          inflatedTarget.inflate(pulseInflation),
          Radius.circular(borderRadius + (pulseProgress * 6.0)),
        ),
        pulsePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TutorialSpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.scrimColor != scrimColor ||
        oldDelegate.pulseColor != pulseColor;
  }
}
