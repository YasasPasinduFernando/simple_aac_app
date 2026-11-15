import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../models/tutorial_step.dart';
import '../../services/tutorial_service.dart';
import 'tutorial_hand_pointer.dart';
import 'tutorial_speech_bubble.dart';
import 'tutorial_spotlight_painter.dart';

class TutorialOverlay extends StatelessWidget {
  final String language;
  final bool isDialog;

  static const Set<TutorialStepType> dialogSteps = {
    TutorialStepType.chooseMedia,
    TutorialStepType.multilingualLabels,
    TutorialStepType.voiceRecording,
    TutorialStepType.saveCard,
  };

  const TutorialOverlay({
    Key? key,
    required this.language,
    this.isDialog = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TutorialStepType?>(
      valueListenable: TutorialService.instance.currentStepNotifier,
      builder: (context, currentStep, _) {
        if (currentStep == null) {
          return const SizedBox.shrink();
        }
        final isStepForDialog = dialogSteps.contains(currentStep);
        if (isDialog != isStepForDialog) {
          return const SizedBox.shrink();
        }
        return _ActiveTutorialOverlay(
          currentStep: currentStep,
          language: language,
          isDialog: isDialog,
        );
      },
    );
  }
}

class _ActiveTutorialOverlay extends StatefulWidget {
  final TutorialStepType currentStep;
  final String language;
  final bool isDialog;

  const _ActiveTutorialOverlay({
    Key? key,
    required this.currentStep,
    required this.language,
    this.isDialog = false,
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
    _ensureTargetVisible();
  }

  @override
  void didUpdateWidget(covariant _ActiveTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _ensureTargetVisible();
    }
  }

  void _ensureTargetVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.currentStep == TutorialStepType.addNewCard) {
        final scaffoldState = Scaffold.maybeOf(context);
        if (scaffoldState != null && scaffoldState.isEndDrawerOpen) {
          scaffoldState.closeEndDrawer();
        }
      }
      final keyName = _getKeyNameForStep(widget.currentStep);
      final targetKey = TutorialService.instance.getKey(keyName);
      final ctx = targetKey?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.5,
        );
      }
    });
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
    // Always permit manual navigation (Back/Next) so user can never get trapped,
    // while action listeners also execute and live buttons remain clickable!
    return true;
  }

  Rect? _measureTargetRect(GlobalKey? key) {
    if (key == null) return null;
    final targetContext = key.currentContext;
    if (targetContext == null || !targetContext.mounted) return null;
    final targetRenderBox = targetContext.findRenderObject() as RenderBox?;
    if (targetRenderBox == null ||
        !targetRenderBox.hasSize ||
        !targetRenderBox.attached ||
        targetRenderBox.size.isEmpty) {
      return null;
    }

    final globalOffset = targetRenderBox.localToGlobal(Offset.zero);
    final overlayRenderBox = context.findRenderObject() as RenderBox?;
    final localOffset = overlayRenderBox != null &&
            overlayRenderBox.hasSize &&
            overlayRenderBox.attached
        ? overlayRenderBox.globalToLocal(globalOffset)
        : globalOffset;

    return Rect.fromLTWH(
      localOffset.dx,
      localOffset.dy,
      targetRenderBox.size.width,
      targetRenderBox.size.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepIndex = TutorialService.instance.currentStepIndex;
    final totalSteps = TutorialService.instance.totalSteps;
    final allowsManual = _isManualAdvanceAllowed(widget.currentStep);

    if (widget.currentStep == TutorialStepType.completed) {
      return Container(
        color: Colors.black.withOpacity(0.70),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: TutorialSpeechBubble(
          stepType: widget.currentStep,
          language: widget.language,
          stepIndex: totalSteps,
          totalSteps: totalSteps,
          isArrowUp: false,
          arrowHorizontalOffset: 0,
          allowsManualAdvance: false,
          onBack: () => TutorialService.instance.previousStep(),
          onNext: () => TutorialService.instance.finishTour(),
          onSkip: () => TutorialService.instance.finishTour(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final overlaySize = Size(constraints.maxWidth, constraints.maxHeight);
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final keyName = _getKeyNameForStep(widget.currentStep);
            final targetKey = TutorialService.instance.getKey(keyName);
            final targetRect = _measureTargetRect(targetKey);

            // Determine bubble layout above or below target
            final bool isAbove;
            if (targetRect != null) {
              isAbove = targetRect.center.dy > (overlaySize.height * 0.48);
            } else {
              isAbove = false;
            }

            final double arrowHorizontalOffset = targetRect != null
                ? (targetRect.center.dx - 24.0).clamp(24.0, overlaySize.width - 60.0)
                : 48.0;

            return _SpotlightHitTestBlocker(
              targetRect: targetRect,
              child: Stack(
                children: [
                  // 1. Scrim with spotlight cutout and pulsing halo
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: TutorialSpotlightPainter(
                          targetRect: targetRect,
                          pulseProgress: _pulseController.value,
                          padding: 4.0,
                          borderRadius: 14.0,
                        ),
                      ),
                    ),
                  ),

                  // 2. Animated Hand Pointer
                  if (targetRect != null &&
                      widget.currentStep != TutorialStepType.completed)
                    Positioned(
                      left: (targetRect.center.dx - 16)
                          .clamp(16.0, overlaySize.width - 50.0),
                      top: isAbove ? (targetRect.top - 46) : (targetRect.bottom + 10),
                      child: IgnorePointer(
                        child: TutorialHandPointer(
                          animationValue: _pulseController.value,
                          pointsDown: isAbove,
                        ),
                      ),
                    ),

                  // 3. Speech Bubble Card
                  Positioned(
                    left: 14,
                    right: 14,
                    top: isAbove
                        ? null
                        : (targetRect != null
                            ? (targetRect.bottom + 50)
                                .clamp(10.0, (overlaySize.height - 230.0).clamp(10.0, overlaySize.height))
                            : 100),
                    bottom: isAbove
                        ? ((overlaySize.height - (targetRect?.top ?? 300) + 50))
                            .clamp(10.0, (overlaySize.height - 230.0).clamp(10.0, overlaySize.height))
                        : null,
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
                        onBack: () {
                          if (widget.currentStep == TutorialStepType.chooseMedia &&
                              widget.isDialog) {
                            Navigator.of(context).maybePop();
                          }
                          TutorialService.instance.previousStep();
                        },
                        onNext: () {
                          TutorialService.instance.requestAction(widget.currentStep);
                          TutorialService.instance.nextStep();
                        },
                        onSkip: () {
                          if (widget.isDialog) {
                            Navigator.of(context).maybePop();
                          }
                          TutorialService.instance.skipTour();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
    if (targetRect != null && targetRect!.inflate(10).contains(position)) {
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
