import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/tutorial_step.dart';
import 'package:simple_aac_app/services/tutorial_service.dart';
import 'package:simple_aac_app/widgets/tutorial/mini_guides_dialog.dart';
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
      expect(find.text('Caregiver PIN Protection'), findsOneWidget);
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
      expect(find.text('பாதுகாப்பு PIN (Caregiver PIN)'), findsOneWidget);
      expect(find.text('காப்புப்பிரதி மற்றும் மீட்டமை (Backup & Restore)'), findsOneWidget);
    });
  });
}
