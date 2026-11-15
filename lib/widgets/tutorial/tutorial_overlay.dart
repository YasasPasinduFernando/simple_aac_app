import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../models/tutorial_step.dart';
import '../../services/tutorial_service.dart';
import 'tutorial_hand_pointer.dart';
import 'tutorial_speech_bubble.dart';
import 'tutorial_spotlight_painter.dart';

class TutorialOverlay extends StatelessWidget {
  final String language;

  const TutorialOverlay({
    Key? key,
    required this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TutorialStepType?>(
      valueListenable: TutorialService.instance.currentStepNotifier,
      builder: (context, currentStep, _) {
        if (currentStep == null) {
          return const SizedBox.shrink();
        }
        return _ActiveTutorialOverlay(
          currentStep: currentStep,
          language: language,
        );
      },
    );
  }
}

class _ActiveTutorialOverlay extends StatefulWidget {
  final TutorialStepType currentStep;
  final String language;

  const _ActiveTutorialOverlay({
    Key? key,
    required this.currentStep,
    required this.language,
  }) : super(key: key);

  @override
  State<_ActiveTutorialOverlay> createState() => _ActiveTutorialOverlayState();
}

class _ActiveTutorialOverlayState extends State<_ActiveTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getKeyNameForStep(TutorialStepType step) {
    switch (step) {
      case TutorialStepType.openMenu:
        return 'app_bar_menu_button';
      case TutorialStepType.drawerExplore:
        return 'drawer_resize_button';
      case TutorialStepType.enableEditMode:
        return 'drawer_edit_mode_toggle';
      case TutorialStepType.addNewCard:
        return 'edit_mode_add_new_button';
      case TutorialStepType.chooseMedia:
        return 'card_editor_media_section';
      case TutorialStepType.multilingualLabels:
        return 'card_editor_labels_section';
      case TutorialStepType.voiceRecording:
        return 'card_editor_voice_section';
      case TutorialStepType.saveCard:
        return 'card_editor_save_button';
      case TutorialStepType.testNewCard:
        final cardId = TutorialService.instance.targetNewCardId;
        return cardId != null ? 'aac_card_$cardId' : 'aac_first_card';
      case TutorialStepType.completed:
        return '';
    }
  }

  bool _isManualAdvanceAllowed(TutorialStepType step) {
    switch (step) {
      case TutorialStepType.chooseMedia:
      case TutorialStepType.multilingualLabels:
      case TutorialStepType.voiceRecording:
      case TutorialStepType.drawerExplore:
        return true;
      default:
        return false;
    }
  }

  Rect? _measureTargetRect(GlobalKey? key) {
    if (key == null) return null;
    final context = key.currentContext;
    if (context == null) return null;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;

    final offset = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final keyName = _getKeyNameForStep(widget.currentStep);
    final targetKey = TutorialService.instance.getKey(keyName);
    final targetRect = _measureTargetRect(targetKey);

    final stepIndex = TutorialService.instance.currentStepIndex;
    final totalSteps = TutorialService.instance.totalSteps;
    final allowsManual = _isManualAdvanceAllowed(widget.currentStep);

    // Determine bubble layout above or below target
    final bool isAbove;
    if (targetRect != null) {
      isAbove = targetRect.center.dy > (screenSize.height * 0.48);
    } else {
      isAbove = false;
    }

    final double arrowHorizontalOffset = targetRect != null
        ? (targetRect.center.dx - 24.0).clamp(24.0, screenSize.width - 60.0)
        : 48.0;

    return _SpotlightHitTestBlocker(
      targetRect: targetRect,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            children: [
              // 1. Scrim with spotlight cutout and pulsing halo
              Positioned.fill(
                child: CustomPaint(
                  painter: TutorialSpotlightPainter(
                    targetRect: targetRect,
                    pulseProgress: _pulseController.value,
                  ),
                ),
              ),

              // 2. Animated Hand Pointer
              if (targetRect != null && widget.currentStep != TutorialStepType.completed)
                Positioned(
                  left: (targetRect.center.dx - 26).clamp(16.0, screenSize.width - 60.0),
                  top: isAbove
                      ? (targetRect.top - 46)
                      : (targetRect.bottom + 8),
                  child: IgnorePointer(
                    child: TutorialHandPointer(
                      animationValue: _pulseController.value,
                      pointsDown: isAbove,
                    ),
                  ),
                ),

              // 3. Speech Bubble Card
              Positioned(
                left: 16,
                right: 16,
                top: isAbove ? null : (targetRect != null ? (targetRect.bottom + 48) : 120),
                bottom: isAbove ? (screenSize.height - (targetRect?.top ?? 300) + 48) : null,
                child: Align(
                  alignment: Alignment.center,
                  child: TutorialSpeechBubble(
                    stepType: widget.currentStep,
                    language: widget.language,
                    stepIndex: stepIndex,
                    totalSteps: totalSteps,
                    isArrowUp: !isAbove,
                    arrowHorizontalOffset: arrowHorizontalOffset,
                    allowsManualAdvance: allowsManual,
                    onBack: () => TutorialService.instance.previousStep(),
                    onNext: () => TutorialService.instance.nextStep(),
                    onSkip: () => TutorialService.instance.skipTour(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Allows touch events to pass through directly to the underlying live widget
/// when tapping inside [targetRect], while capturing events elsewhere.
class _SpotlightHitTestBlocker extends SingleChildRenderObjectWidget {
  final Rect? targetRect;

  const _SpotlightHitTestBlocker({
    Key? key,
    required this.targetRect,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSpotlightHitTestBlocker(targetRect);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSpotlightHitTestBlocker renderObject,
  ) {
    renderObject.targetRect = targetRect;
  }
}

class _RenderSpotlightHitTestBlocker extends RenderProxyBox {
  Rect? targetRect;

  _RenderSpotlightHitTestBlocker(this.targetRect);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // If inside target rect, pass through to underlying widgets behind this overlay!
    if (targetRect != null && targetRect!.inflate(6).contains(position)) {
      return false;
    }

    // Outside the target rect: test children (e.g. Speech Bubble buttons)
    if (child?.hitTest(result, position: position) == true) {
      return true;
    }

    // Absorb click so background outside target is guarded
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}
