import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/tutorial_step.dart';
import 'package:simple_aac_app/services/tutorial_service.dart';
import 'package:simple_aac_app/utils/tutorial_strings.dart';
import 'package:simple_aac_app/widgets/tutorial/tutorial_speech_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TutorialService.resetForTesting();
  });

  group('TutorialStrings Trilingual Tests', () {
    test('Returns non-empty strings across English, Sinhala and Tamil', () {
      for (final lang in ['en', 'si', 'ta']) {
        expect(TutorialStrings.getWelcomeTitle(lang).isNotEmpty, isTrue);
        expect(TutorialStrings.getWelcomeDesc(lang).isNotEmpty, isTrue);
        expect(TutorialStrings.getStartTourLabel(lang).isNotEmpty, isTrue);
        expect(TutorialStrings.getNotNowLabel(lang).isNotEmpty, isTrue);
        expect(TutorialStrings.getSkipLabel(lang).isNotEmpty, isTrue);
        expect(TutorialStrings.getStepTitle(TutorialStepType.openMenu, lang).isNotEmpty, isTrue);
        expect(TutorialStrings.getStepDesc(TutorialStepType.openMenu, lang).isNotEmpty, isTrue);
        expect(TutorialStrings.getStepTitle(TutorialStepType.enableEditMode, lang).isNotEmpty, isTrue);
        expect(TutorialStrings.getStepTitle(TutorialStepType.addNewCard, lang).isNotEmpty, isTrue);
        expect(TutorialStrings.getStepTitle(TutorialStepType.saveCard, lang).isNotEmpty, isTrue);
        expect(TutorialStrings.getStepTitle(TutorialStepType.testNewCard, lang).isNotEmpty, isTrue);
      }
    });

    test('Sinhala strings contain valid Sinhala Unicode characters', () {
      final titleSi = TutorialStrings.getWelcomeTitle('si');
      // Sinhala Unicode block: 0x0D80 to 0x0DFF
      final hasSinhala = titleSi.runes.any((r) => r >= 0x0D80 && r <= 0x0DFF);
      expect(hasSinhala, isTrue);
    });

    test('Tamil strings contain valid Tamil Unicode characters', () {
      final titleTa = TutorialStrings.getWelcomeTitle('ta');
      // Tamil Unicode block: 0x0B80 to 0x0BFF
      final hasTamil = titleTa.runes.any((r) => r >= 0x0B80 && r <= 0x0BFF);
      expect(hasTamil, isTrue);
    });
  });

  group('TutorialService State Machine & Persistence', () {
    test('First launch with empty preferences offers welcome sheet', () async {
      final service = TutorialService.instance;
      await service.init();

      expect(service.isWelcomeVisibleNotifier.value, isTrue);
      expect(service.currentStepNotifier.value, isNull);
      expect(service.isTourActive, isFalse);
    });

    test('First launch startTour starts at openMenu step', () async {
      final service = TutorialService.instance;
      await service.init();
      service.startTour();

      expect(service.isWelcomeVisibleNotifier.value, isFalse);
      expect(service.currentStepNotifier.value, TutorialStepType.openMenu);
      expect(service.isTourActive, isTrue);
      expect(service.currentStepIndex, 1);
    });

    test('Skip tour dismisses welcome, terminates tour, and persists skipped flag', () async {
      final service = TutorialService.instance;
      await service.init();
      await service.skipTour();

      expect(service.isWelcomeVisibleNotifier.value, isFalse);
      expect(service.isTourActive, isFalse);
      expect(service.currentStepNotifier.value, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(TutorialService.prefSkipped), isTrue);

      // Re-init does not re-open welcome
      TutorialService.resetForTesting();
      final freshService = TutorialService.instance;
      await freshService.init();
      expect(freshService.isWelcomeVisibleNotifier.value, isFalse);
    });

    test('Step forward and backward navigation works correctly', () async {
      final service = TutorialService.instance;
      await service.init();
      service.startTour();

      expect(service.currentStepNotifier.value, TutorialStepType.openMenu);
      service.nextStep();
      expect(service.currentStepNotifier.value, TutorialStepType.drawerExplore);
      service.nextStep();
      expect(service.currentStepNotifier.value, TutorialStepType.enableEditMode);
      service.previousStep();
      expect(service.currentStepNotifier.value, TutorialStepType.drawerExplore);
    });

    test('Event notifications advance appropriate tutorial steps', () async {
      final service = TutorialService.instance;
      await service.init();
      service.startTour();

      // In openMenu step: menu opened advances to drawerExplore
      expect(service.currentStepNotifier.value, TutorialStepType.openMenu);
      service.notifyMenuOpened();
      expect(service.currentStepNotifier.value, TutorialStepType.drawerExplore);

      // In drawerExplore step: drawer resized or continued advances to enableEditMode
      service.notifyDrawerResized();
      expect(service.currentStepNotifier.value, TutorialStepType.enableEditMode);

      // In enableEditMode step: edit mode toggled advances to addNewCard
      service.notifyEditModeEnabled();
      expect(service.currentStepNotifier.value, TutorialStepType.addNewCard);

      // In addNewCard step: editor opened advances to chooseMedia
      service.notifyCardEditorOpened();
      expect(service.currentStepNotifier.value, TutorialStepType.chooseMedia);

      // In chooseMedia step: media picked advances to multilingualLabels
      service.notifyMediaSelected();
      expect(service.currentStepNotifier.value, TutorialStepType.multilingualLabels);

      // User advances through voice and save
      service.nextStep(); // voiceRecording
      expect(service.currentStepNotifier.value, TutorialStepType.voiceRecording);
      service.nextStep(); // saveCard
      expect(service.currentStepNotifier.value, TutorialStepType.saveCard);

      // Card saved advances to testNewCard with target card id
      service.notifyCardSaved('test_card_123');
      expect(service.currentStepNotifier.value, TutorialStepType.testNewCard);
      expect(service.targetNewCardId, 'test_card_123');

      // Tapping the new card completes the tour
      service.notifyNewCardTapped('test_card_123');
      expect(service.currentStepNotifier.value, TutorialStepType.completed);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(TutorialService.prefCompleted), isTrue);
    });

    test('Replay tour restarts clean even after previous completion', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(TutorialService.prefCompleted, true);

      final service = TutorialService.instance;
      await service.init();
      expect(service.isWelcomeVisibleNotifier.value, isFalse);

      service.resetAndReplayTour();
      expect(service.isTourActive, isTrue);
      expect(service.currentStepNotifier.value, TutorialStepType.openMenu);
    });

    testWidgets('TutorialSpeechBubble displays full step titles without ellipsis on narrow screen',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testSteps = [
        TutorialStepType.chooseMedia,
        TutorialStepType.multilingualLabels,
        TutorialStepType.voiceRecording,
      ];

      for (final step in testSteps) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TutorialSpeechBubble(
                  stepType: step,
                  language: 'en',
                  stepIndex: 5,
                  totalSteps: 9,
                  isArrowUp: true,
                  arrowHorizontalOffset: 48,
                  onBack: () {},
                  onNext: () {},
                  onSkip: () {},
                  allowsManualAdvance: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final expectedTitle = TutorialStrings.getStepTitle(step, 'en');
        // The full title must be found in the widget tree without any truncation '...'
        expect(find.text(expectedTitle), findsOneWidget);
        expect(expectedTitle.contains('...'), isFalse);
      }
    });
  });
}
