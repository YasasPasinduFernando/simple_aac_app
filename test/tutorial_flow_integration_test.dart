import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/tutorial_step.dart';
import 'package:simple_aac_app/services/tutorial_service.dart';
import 'package:simple_aac_app/utils/tutorial_strings.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';
import 'package:simple_aac_app/widgets/tutorial/mini_guides_dialog.dart';
import 'package:simple_aac_app/widgets/tutorial/tutorial_overlay.dart';
import 'package:simple_aac_app/widgets/tutorial/welcome_tour_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TutorialService.resetForTesting();
  });

  group('Interactive Tutorial Flow Integration Tests', () {
    testWidgets('WelcomeTourDialog shows trilingual text and starts tour', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WelcomeTourDialog(language: 'en'),
          ),
        ),
      );

      expect(find.text('Welcome to Simple AAC Sri Lanka!'), findsOneWidget);
      expect(find.text('Start Quick Tour'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);

      await tester.tap(find.text('Start Quick Tour'));
      await tester.pump();

      expect(TutorialService.instance.isTourActive, isTrue);
      expect(TutorialService.instance.currentStepNotifier.value, TutorialStepType.openMenu);
    });

    testWidgets('WelcomeTourDialog "Not Now" dismisses and skips tour without blocking app', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WelcomeTourDialog(language: 'si'),
          ),
        ),
      );

      expect(find.text('Simple AAC වෙත සාදරයෙන් පිළිගනිමු!'), findsOneWidget);
      expect(find.text('දැනට අවශ්‍ය නැත'), findsOneWidget);

      await tester.tap(find.text('දැනට අවශ්‍ය නැත'));
      await tester.pump();

      expect(TutorialService.instance.isTourActive, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(TutorialService.prefSkipped), isTrue);
    });

    testWidgets('MiniGuidesDialog displays all 5 feature guides', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniGuidesDialog(language: 'en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help & Feature Guides'), findsOneWidget);
      expect(find.text(TutorialStrings.getPinGuideTitle('en')), findsOneWidget);
      expect(find.text('Backup & Restore Data'), findsOneWidget);
      expect(find.text('Permissions & Privacy'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Animated GIFs & Short Videos'), 150);
      expect(find.text('Smart Search & Privacy'), findsOneWidget);
      expect(find.text('Animated GIFs & Short Videos'), findsOneWidget);
    });

    testWidgets('MiniGuidesDialog in Tamil renders authentic Tamil guides', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniGuidesDialog(language: 'ta'),
          ),
        ),
      );

      expect(find.text('உதவி வழிகாட்டிகள்'), findsOneWidget);
      expect(find.text(TutorialStrings.getPinGuideTitle('ta')), findsOneWidget);
      expect(find.text('காப்புப்பிரதி மற்றும் மீட்டமை (Backup & Restore)'), findsOneWidget);
    });

    testWidgets('HomeDrawer presents Interactive App Guide before About and restarts guide on tap', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var replayed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeDrawer(
              selectedCategory: 'All',
              currentLanguageLabel: 'English',
              gridColumns: 2,
              visibleCardsLabel: 'All cards',
              isEditMode: false,
              showTtsInput: true,
              orientationLabel: 'Portrait',
              fullScreen: true,
              headerColor: Colors.blue,
              headerTextColor: Colors.white,
              hideTtsText: false,
              useImageOverlayLabel: true,
              applyTextColorToCards: false,
              isDarkMode: false,
              isColorBlindMode: false,
              primaryColorSwatch: Colors.blue,
              textColorSwatch: Colors.white,
              backgroundColorSwatch: Colors.white,
              isOnlineEnabled: false,
              onToggleOnline: (_) {},
              onToggleDarkMode: (_) {},
              onChangeColorBlindMode: (_) {},
              onSelectCategory: () {},
              onAddCategory: () {},
              onToggleEdit: () {},
              onToggleTtsInput: () {},
              onToggleTtsText: () {},
              onToggleCardImageLabel: () {},
              onToggleApplyTextColorToCards: () {},
              onChangeOrientation: () {},
              onPickPrimaryColor: () {},
              onPickTextColor: () {},
              onPickBackgroundColor: () {},
              onShowTtsBarSize: () {},
              onToggleFullScreen: () {},
              onShowLanguage: () {},
              onShowGrid: () {},
              onShowVisibleCount: () {},
              onBackup: () {},
              onRestore: () {},
              onResetSettings: () {},
              onShowAbout: () {},
              onReplayTutorial: () {
                replayed = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('About Simple AAC'), 150);
      expect(find.text('Interactive App Guide'), findsOneWidget);
      expect(find.text('Replay step-by-step walkthrough anytime'), findsOneWidget);
      expect(find.text('About Simple AAC'), findsOneWidget);

      await tester.tap(find.text('Interactive App Guide'));
      await tester.pump();

      expect(replayed, isTrue);
    });

    testWidgets('Completed step renders centered celebration modal and terminates tour on Finish', (tester) async {
      TutorialService.instance.startTour();
      TutorialService.instance.currentStepNotifier.value = TutorialStepType.completed;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(language: 'en'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Awesome Job!'), findsOneWidget);
      expect(find.text('Finish'), findsWidgets);

      await tester.tap(find.text('Finish').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(TutorialService.instance.currentStepNotifier.value, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(TutorialService.prefCompleted), isTrue);
    });

    test('Search tutorial hints return valid strings in EN, SI, TA', () {
      for (final lang in ['en', 'si', 'ta']) {
        expect(TutorialStrings.getSearchPickImageHint(lang).isNotEmpty, isTrue);
        expect(TutorialStrings.getSearchSaveOfflineHint(lang).isNotEmpty, isTrue);
      }
    });
  });
}
