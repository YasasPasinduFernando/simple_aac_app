import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tutorial_step.dart';

class TutorialService {
  static const String prefCompleted = 'pref_tutorial_completed_v1_1';
  static const String prefSkipped = 'pref_tutorial_skipped_v1_1';

  static TutorialService? _instance;
  static TutorialService get instance => _instance ??= TutorialService._();

  static void resetForTesting() {
    _instance?.onActionRequested = null;
    _instance = null;
  }

  TutorialService._();

  final ValueNotifier<TutorialStepType?> currentStepNotifier =
      ValueNotifier<TutorialStepType?>(null);
  final ValueNotifier<bool> isWelcomeVisibleNotifier =
      ValueNotifier<bool>(false);

  String? targetNewCardId;
  void Function(TutorialStepType step)? onActionRequested;

  void requestAction(TutorialStepType step) {
    onActionRequested?.call(step);
  }

  final Map<String, GlobalKey> _targetKeys = {};

  void registerKey(String name, GlobalKey key) {
    _targetKeys[name] = key;
  }

  GlobalKey? getKey(String name) => _targetKeys[name];

  bool get isTourActive =>
      currentStepNotifier.value != null &&
      currentStepNotifier.value != TutorialStepType.completed;

  static const List<TutorialStepType> _stepsSequence = [
    TutorialStepType.openMenu,
    TutorialStepType.drawerExplore,
    TutorialStepType.enableEditMode,
    TutorialStepType.addNewCard,
    TutorialStepType.chooseMedia,
    TutorialStepType.multilingualLabels,
    TutorialStepType.voiceRecording,
    TutorialStepType.saveCard,
    TutorialStepType.testNewCard,
  ];

  int get totalSteps => 8; // Main card creation flow steps 1 to 8

  int get currentStepIndex {
    final current = currentStepNotifier.value;
    if (current == null) return 0;
    final index = _stepsSequence.indexOf(current);
    if (index < 0) return 0;
    return index + 1;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(prefCompleted) ?? false;
    final skipped = prefs.getBool(prefSkipped) ?? false;

    if (!completed && !skipped) {
      isWelcomeVisibleNotifier.value = true;
    } else {
      isWelcomeVisibleNotifier.value = false;
    }
  }

  void startTour() {
    isWelcomeVisibleNotifier.value = false;
    targetNewCardId = null;
    currentStepNotifier.value = TutorialStepType.openMenu;
  }

  Future<void> skipTour() async {
    isWelcomeVisibleNotifier.value = false;
    currentStepNotifier.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefSkipped, true);
  }

  void nextStep() {
    final current = currentStepNotifier.value;
    if (current == null) return;
    final idx = _stepsSequence.indexOf(current);
    if (idx >= 0 && idx < _stepsSequence.length - 1) {
      currentStepNotifier.value = _stepsSequence[idx + 1];
    }
  }

  void previousStep() {
    final current = currentStepNotifier.value;
    if (current == null) return;
    final idx = _stepsSequence.indexOf(current);
    if (idx > 0) {
      currentStepNotifier.value = _stepsSequence[idx - 1];
    }
  }

  Future<void> completeTour() async {
    currentStepNotifier.value = TutorialStepType.completed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefCompleted, true);
  }

  void resetAndReplayTour() {
    isWelcomeVisibleNotifier.value = false;
    targetNewCardId = null;
    currentStepNotifier.value = TutorialStepType.openMenu;
  }

  void endTour() {
    currentStepNotifier.value = null;
  }

  // --- Guided User Action Notifiers ---

  void notifyMenuOpened() {
    if (currentStepNotifier.value == TutorialStepType.openMenu) {
      currentStepNotifier.value = TutorialStepType.drawerExplore;
    }
  }

  void notifyDrawerResized() {
    if (currentStepNotifier.value == TutorialStepType.drawerExplore) {
      currentStepNotifier.value = TutorialStepType.enableEditMode;
    }
  }

  void notifyEditModeEnabled() {
    if (currentStepNotifier.value == TutorialStepType.enableEditMode) {
      currentStepNotifier.value = TutorialStepType.addNewCard;
    }
  }

  void notifyCardEditorOpened() {
    if (currentStepNotifier.value == TutorialStepType.addNewCard) {
      currentStepNotifier.value = TutorialStepType.chooseMedia;
    }
  }

  void notifyMediaSelected() {
    if (currentStepNotifier.value == TutorialStepType.chooseMedia) {
      currentStepNotifier.value = TutorialStepType.multilingualLabels;
    }
  }

  void notifyCardSaved(String cardId) {
    targetNewCardId = cardId;
    if (currentStepNotifier.value != null &&
        currentStepNotifier.value != TutorialStepType.completed) {
      currentStepNotifier.value = TutorialStepType.testNewCard;
    }
  }

  void notifyNewCardTapped(String cardId) {
    if (currentStepNotifier.value == TutorialStepType.testNewCard) {
      completeTour();
    }
  }
}
