import 'package:flutter/material.dart';

class TutorialHandPointer extends StatelessWidget {
  final double animationValue; // 0.0 to 1.0 bounce
  final bool pointsDown;

  const TutorialHandPointer({
    Key? key,
    required this.animationValue,
    this.pointsDown = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final bounceOffset = disableAnimations ? 0.0 : (animationValue * 8.0);

    return Transform.translate(
      offset: Offset(0, pointsDown ? -bounceOffset : bounceOffset),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse halo behind finger
          if (!disableAnimations)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2196F3).withOpacity(0.35 * (1.0 - animationValue)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          // Inner tap ring
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.92),
              border: Border.all(
                color: const Color(0xFF1976D2),
                width: 2.0,
              ),
            ),
            child: Icon(
              pointsDown ? Icons.touch_app_rounded : Icons.pan_tool_alt_rounded,
              size: 19,
              color: const Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }
}
