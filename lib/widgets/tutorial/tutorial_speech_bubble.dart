import 'package:flutter/material.dart';
import '../../models/tutorial_step.dart';
import '../../utils/tutorial_strings.dart';

class TutorialSpeechBubble extends StatelessWidget {
  final TutorialStepType stepType;
  final String language;
  final int stepIndex;
  final int totalSteps;
  final bool isArrowUp;
  final double arrowHorizontalOffset;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool allowsManualAdvance;

  const TutorialSpeechBubble({
    Key? key,
    required this.stepType,
    required this.language,
    required this.stepIndex,
    required this.totalSteps,
    required this.isArrowUp,
    required this.arrowHorizontalOffset,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    this.allowsManualAdvance = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = TutorialStrings.getStepTitle(stepType, language);
    final desc = TutorialStrings.getStepDesc(stepType, language);
    final isFinalStep = stepType == TutorialStepType.completed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isArrowUp && !isFinalStep)
          Padding(
            padding: EdgeInsets.only(left: arrowHorizontalOffset.clamp(24.0, 280.0)),
            child: const CustomPaint(
              size: Size(18, 10),
              painter: _TriangleArrowPainter(isArrowUp: true),
            ),
          ),
        Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF64B5F6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top meta row: Step badge on left, close icon on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF90CAF9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          size: 13,
                          color: Color(0xFF1565C0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isFinalStep
                              ? TutorialStrings.getFinishLabel(language)
                              : 'Step $stepIndex of $totalSteps',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    tooltip: TutorialStrings.getSkipLabel(language),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onSkip,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Full-width step title - never truncated with ellipsis!
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              // Footer Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (stepIndex > 1 && !isFinalStep)
                    OutlinedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: Text(
                        TutorialStrings.getBackLabel(language),
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(60, 32),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (isFinalStep)
                    FilledButton.icon(
                      onPressed: onSkip, // Ends the tour
                      icon: const Icon(Icons.celebration_rounded, size: 16),
                      label: Text(
                        TutorialStrings.getFinishLabel(language),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else if (allowsManualAdvance)
                    FilledButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(
                        TutorialStrings.getNextLabel(language),
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(60, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_outlined, size: 13, color: Color(0xFF475569)),
                          SizedBox(width: 4),
                          Text(
                            'Tap button to continue',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF475569),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (!isArrowUp && !isFinalStep)
          Padding(
            padding: EdgeInsets.only(left: arrowHorizontalOffset.clamp(24.0, 280.0)),
            child: const CustomPaint(
              size: Size(18, 10),
              painter: _TriangleArrowPainter(isArrowUp: false),
            ),
          ),
      ],
    );
  }
}

class _TriangleArrowPainter extends CustomPainter {
  final bool isArrowUp;

  const _TriangleArrowPainter({required this.isArrowUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF64B5F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    if (isArrowUp) {
      // Points up: base at bottom, apex at top center
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      // Points down: base at top, apex at bottom center
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
      path.close();
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _TriangleArrowPainter oldDelegate) =>
      oldDelegate.isArrowUp != isArrowUp;
}
