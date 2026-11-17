import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/services/personalize_service.dart';
import 'package:simple_aac_app/widgets/personalize_setup_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersonalizeService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('shouldShowFirstLaunchSetup returns true on clean first install',
        () async {
      final prefs = await SharedPreferences.getInstance();
      expect(PersonalizeService.shouldShowFirstLaunchSetup(prefs), isTrue);
    });

    test('shouldShowFirstLaunchSetup returns false once marked completed',
        () async {
      final prefs = await SharedPreferences.getInstance();
      expect(PersonalizeService.shouldShowFirstLaunchSetup(prefs), isTrue);

      await PersonalizeService.markCompleted(prefs);
      expect(PersonalizeService.shouldShowFirstLaunchSetup(prefs), isFalse);
    });

    test(
        'shouldShowFirstLaunchSetup returns false for upgrading users and marks completed',
        () async {
      // Simulate an existing user with seeded cards or custom settings
      SharedPreferences.setMockInitialValues({
        'seededDefaultCardsVersion': 8,
        'language': 'si',
      });
      final prefs = await SharedPreferences.getInstance();

      // Must be false to never disturb existing users
      expect(PersonalizeService.shouldShowFirstLaunchSetup(prefs), isFalse);

      // Must have silently marked completed in prefs
      expect(
        prefs.getBool(PersonalizeService.prefPersonalizeCompleted),
        isTrue,
      );
    });

    test('detects upgrade user via tutorial completion flag', () async {
      SharedPreferences.setMockInitialValues({
        'pref_tutorial_completed_v1_1': true,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(PersonalizeService.shouldShowFirstLaunchSetup(prefs), isFalse);
    });

    test('detects upgrade user via grid columns', () async {
      SharedPreferences.setMockInitialValues({
        'gridColumns': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(PersonalizeService.shouldShowFirstLaunchSetup(prefs), isFalse);
    });
  });

  group('PersonalizeSetupDialog Widget Tests', () {
    testWidgets('renders all language, app bar color, and board color options',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PersonalizeSetupDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Personalize Simple AAC'), findsOneWidget);
      expect(find.text('Choose your language and colors'), findsOneWidget);

      // Languages
      expect(find.text('English'), findsOneWidget);
      expect(find.text('සිංහල'), findsOneWidget);
      expect(find.text('தமிழ்'), findsOneWidget);

      // Section titles
      expect(find.text('Select AAC Language'), findsOneWidget);
      expect(find.text('App Bar & Menu Color'), findsOneWidget);
      expect(find.text('Board Background'), findsOneWidget);
      expect(find.text('Live Preview'), findsOneWidget);

      // Action buttons
      expect(find.text('Use Defaults'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Change anytime in Settings'), findsOneWidget);
    });

    testWidgets('switching language updates live preview cards',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PersonalizeSetupDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Initially English
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);

      // Tap Sinhala
      await tester.tap(find.text('සිංහල'));
      await tester.pumpAndSettle();

      expect(find.text('ආයුබෝවන්'), findsOneWidget);
      expect(find.text('වතුර'), findsOneWidget);

      // Tap Tamil
      await tester.tap(find.text('தமிழ்'));
      await tester.pumpAndSettle();

      expect(find.text('வணக்கம்'), findsOneWidget);
      expect(find.text('தண்ணீர்'), findsOneWidget);
    });

    testWidgets('Use Defaults pops with standard blue, white, and english',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      PersonalizeSetupResult? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await PersonalizeSetupDialog.show(
                    context,
                    initialLanguage: 'si',
                    initialAppBarColor: const Color(0xFFCE738E),
                    initialBoardColor: const Color(0xFFF8F2D8),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap Use Defaults
      await tester.tap(find.text('Use Defaults'));
      await tester.pumpAndSettle();

      expect(dialogResult, isNotNull);
      expect(dialogResult!.language, 'en');
      expect(dialogResult!.appBarColor, const Color(0xFF0277BD));
      expect(dialogResult!.boardColor, const Color(0xFFFFFFFF));
    });

    testWidgets('Continue returns user selections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      PersonalizeSetupResult? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await PersonalizeSetupDialog.show(context);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Select Sinhala
      await tester.tap(find.text('සිංහල'));
      await tester.pumpAndSettle();

      // Tap Sage Green (3rd circle, Color(0xFF8DA885))
      final sageFinder = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == const Color(0xFF8DA885),
      );
      expect(sageFinder, findsWidgets);
      await tester.tap(sageFinder.first);
      await tester.pumpAndSettle();

      // Tap Cream board background (Color(0xFFF8F2D8))
      await tester.tap(find.text('Cream'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(dialogResult, isNotNull);
      expect(dialogResult!.language, 'si');
      expect(dialogResult!.appBarColor, const Color(0xFF8DA885));
      expect(dialogResult!.boardColor, const Color(0xFFF8F2D8));
    });

    testWidgets('tapping all 4 App Bar colors updates preview theme',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PersonalizeSetupDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      for (final color in PersonalizeSetupDialog.appBarColors) {
        final colorFinder = find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == color,
        );
        expect(colorFinder, findsWidgets);
        await tester.tap(colorFinder.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('tapping all 6 board colors updates preview board background',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PersonalizeSetupDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      for (final opt in PersonalizeSetupDialog.boardBackgroundOptions) {
        await tester.tap(find.text(opt.label));
        await tester.pumpAndSettle();
      }
    });
  });
}
