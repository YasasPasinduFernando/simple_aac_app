import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/services/tutorial_service.dart';
import 'package:simple_aac_app/widgets/tutorial/tutorial_overlay.dart';
import 'package:simple_aac_app/widgets/tutorial/tutorial_speech_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TutorialService.resetForTesting();
  });

  group('TutorialOverlay Widget Tests', () {
    testWidgets('Renders nothing when tutorial is not active', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(language: 'en'),
          ),
        ),
      );

      expect(find.byType(TutorialSpeechBubble), findsNothing);
      expect(find.text('Open App Menu'), findsNothing);
    });

    testWidgets('Renders speech bubble and spotlight when step is active', (tester) async {
      final key = GlobalKey();
      TutorialService.instance.registerKey('app_bar_menu_button', key);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    key: key,
                    width: 48,
                    height: 48,
                    color: Colors.blue,
                  ),
                ),
                const TutorialOverlay(language: 'en'),
              ],
            ),
          ),
        ),
      );

      // Start tour
      TutorialService.instance.startTour();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TutorialSpeechBubble), findsOneWidget);
      expect(find.text('Open App Menu'), findsOneWidget);
      expect(find.text('Step 1 of 8'), findsOneWidget);
    });

    testWidgets('Skip button in speech bubble terminates the tour', (tester) async {
      TutorialService.instance.startTour();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(language: 'en'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TutorialSpeechBubble), findsOneWidget);

      final skipBtn = find.byTooltip('Skip');
      expect(skipBtn, findsOneWidget);
      await tester.tap(skipBtn);
      await tester.pump();

      expect(TutorialService.instance.isTourActive, isFalse);
      expect(find.byType(TutorialSpeechBubble), findsNothing);
    });

    testWidgets('Sinhala language renders Sinhala step title and description', (tester) async {
      TutorialService.instance.startTour();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TutorialOverlay(language: 'si'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('මෙනුව විවෘත කරන්න'), findsOneWidget);
    });
  });
}
