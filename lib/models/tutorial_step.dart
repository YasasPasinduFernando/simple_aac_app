enum TutorialStepType {
  openMenu,
  drawerExplore,
  enableEditMode,
  addNewCard,
  chooseMedia,
  multilingualLabels,
  voiceRecording,
  saveCard,
  testNewCard,
  completed,
}

enum SpeechBubblePosition {
  auto,
  above,
  below,
  left,
  right,
}

class TutorialStep {
  final TutorialStepType type;
  final String keyName;
  final SpeechBubblePosition bubblePosition;
  final bool allowsManualAdvance;
  final bool showHandPointer;

  const TutorialStep({
    required this.type,
    required this.keyName,
    this.bubblePosition = SpeechBubblePosition.auto,
    this.allowsManualAdvance = false,
    this.showHandPointer = true,
  });
}
