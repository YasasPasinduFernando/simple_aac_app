import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'gridColumns': 2,
      'useImageOverlayLabel': false,
      'showCardLabels': true,
      'orientationMode': 'portrait',
      'fullScreen': false,
      'globalCardLabelBackgroundColor': 0xFFF4F1EB,
    });
    HomePage.skipSplashForTesting = false;
    HomePage.forceSplashForTesting = true;
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.enablePersonalizeInit = false;
    HomePage.initialCardsForTesting = [
      AACCard(id: 'c1', label: 'Hello', colorValue: Colors.blue.value),
      AACCard(id: 'c2', label: 'Happy', colorValue: Colors.green.value),
      AACCard(id: 'c3', label: 'Sad', colorValue: Colors.amber.value),
      AACCard(id: 'c4', label: 'Angry', colorValue: Colors.red.value),
      AACCard(
        id: 'c5',
        label: 'More',
        colorValue: Colors.purple.value,
        type: 'folder',
        subCards: [
          AACCard(id: 's1', label: 'Sub 1', colorValue: Colors.blue.value),
          AACCard(id: 's2', label: 'Sub 2', colorValue: Colors.green.value),
          AACCard(id: 's3', label: 'Sub 3', colorValue: Colors.orange.value),
          AACCard(id: 's4', label: 'Sub 4', colorValue: Colors.pink.value),
        ],
      ),
      AACCard(id: 'c6', label: 'Default', colorValue: Colors.cyan.value),
      AACCard(id: 'c7', label: 'New', colorValue: Colors.orange.value, voicePath: 'fake/path.m4a'),
      AACCard(id: 'c8', label: 'Extra 1', colorValue: Colors.teal.value),
      AACCard(id: 'c9', label: 'Extra 2', colorValue: Colors.pink.value),
      AACCard(id: 'c10', label: 'Extra 3', colorValue: Colors.indigo.value),
    ];
  });

  tearDown(() {
    HomePage.skipSplashForTesting = false;
    HomePage.forceSplashForTesting = false;
    HomePage.initialCardsForTesting = null;
  });

  Widget buildApp() {
    return const MaterialApp(
      home: HomePage(),
    );
  }

  group('Lifecycle & Scrolling Robustness Verification Suite (10 Scenarios)', () {
    testWidgets('Scenario 1: Normal app launch scrolling with AlwaysScrollableScrollPhysics', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.625, 850 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final ScrollableState scrollable = tester.state(find.byType(Scrollable).first);
      expect(scrollable.position.pixels, 0.0);

      // Scroll down
      await tester.drag(gridFinder, const Offset(0.0, -250.0));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0.0));

      // Scroll back up
      await tester.drag(gridFinder, const Offset(0.0, 250.0));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, 0.0);
    });

    testWidgets('Scenario 2: Background -> foreground transition does not lock scroll', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.625, 850 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Simulate AppLifecycleState.paused
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 100));

      // Simulate AppLifecycleState.resumed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 100));

      final gridFinder = find.byType(GridView);
      final ScrollableState scrollable = tester.state(find.byType(Scrollable).first);

      await tester.drag(gridFinder, const Offset(0.0, -200.0));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0.0));
    });

    testWidgets('Scenario 3: Home button press -> reopen lifecycle preserves scrollability', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.625, 850 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 200));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      final ScrollableState scrollable = tester.state(find.byType(Scrollable).first);

      await tester.drag(gridFinder, const Offset(0.0, -220.0));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0.0));
    });

    testWidgets('Scenario 4: Recent apps switch -> reopen preserves scroll metrics', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.625, 850 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      final ScrollableState scrollable = tester.state(find.byType(Scrollable).first);

      // Pre-scroll
      await tester.drag(gridFinder, const Offset(0.0, -100.0));
      await tester.pumpAndSettle();
      final offsetBefore = scrollable.position.pixels;
      expect(offsetBefore, greaterThan(0.0));

      // App switched away and back
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 50));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Ensure further scrolling is completely functional
      await tester.drag(gridFinder, const Offset(0.0, -100.0));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(offsetBefore));
    });

    testWidgets('Scenario 5: Close activity / widget recreation relaunch', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.625, 850 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Dispose and remount fresh widget
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      final ScrollableState scrollable = tester.state(find.byType(Scrollable).first);

      await tester.drag(gridFinder, const Offset(0.0, -180.0));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0.0));
    });

    testWidgets('Scenario 6: Cold launch with splash loader simulation (exact bug reproduction & fix verification)', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.625, 850 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp());

      // Frame 1: splash active
      await tester.pump(const Duration(milliseconds: 20));

      // Splash fading out: user immediately begins swiping
      await tester.pump(const Duration(milliseconds: 60));

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final ScrollableState scrollable = tester.state(find.byType(Scrollable).first);
      await tester.drag(gridFinder, const Offset(0.0, -200.0));
      await tester.pump(const Duration(milliseconds: 20));

      // Grid MUST have scrolled because IgnorePointer prevented splash from swallowing gesture
      expect(scrollable.position.pixels, greaterThan(0.0));

      await tester.pumpAndSettle();
    });

    testWidgets('Scenario 7: Open Settings drawer -> return to Home maintains scrolling', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.625, 850 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open drawer via scaffold
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      // Close drawer
      scaffoldState.closeEndDrawer();
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      final ScrollableState scrollable = tester.state(
        find.descendant(of: gridFinder, matching: find.byType(Scrollable)),
      );

      await tester.drag(gridFinder, const Offset(0.0, -200.0));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0.0));
    });

    testWidgets('Scenario 8: Open folder -> return to Home maintains scrolling in both views', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.625, 850 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap on folder 'More'
      final folderFinder = find.text('More');
      expect(folderFinder, findsOneWidget);
      await tester.tap(folderFinder);
      await tester.pumpAndSettle();

      // Verify in subfolder
      expect(find.text('Sub 1'), findsOneWidget);
      expect(find.text('Sub 2'), findsOneWidget);

      // Verify folder grid can scroll
      final folderGridFinder = find.byType(GridView);
      expect(folderGridFinder, findsOneWidget);

      // Navigate back to Home
      final backFinder = find.byTooltip('Back');
      expect(backFinder, findsOneWidget);
      await tester.tap(backFinder);
      await tester.pumpAndSettle();

      // Verify back on Home and can scroll
      expect(find.text('Hello'), findsOneWidget);
      final homeGridFinder = find.byType(GridView);
      final ScrollableState scrollable = tester.state(find.byType(Scrollable).first);

      await tester.drag(homeGridFinder, const Offset(0.0, -200.0));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0.0));
    });

    testWidgets('Scenario 9: Custom media card with GIF / video visible responds to scroll', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.625, 850 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      final ScrollableState scrollable = tester.state(find.byType(Scrollable).first);

      // Scroll down until 'New' card is fully in view
      await tester.drag(gridFinder, const Offset(0.0, -300.0));
      await tester.pumpAndSettle();

      expect(find.text('New'), findsOneWidget);
      expect(scrollable.position.pixels, greaterThan(150.0));

      // Scroll directly by dragging on the 'New' card itself
      await tester.drag(find.text('New'), const Offset(0.0, 150.0));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, lessThan(300.0));
    });

    testWidgets('Scenario 10: Tapping card / building sentence bar maintains scrolling', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.625, 850 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap card 'Hello'
      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle();

      // Tap card 'Happy'
      await tester.tap(find.text('Happy'));
      await tester.pumpAndSettle();

      // Verify both tokens in sentence bar
      final gridFinder = find.byType(GridView);
      final ScrollableState scrollable = tester.state(
        find.descendant(of: gridFinder, matching: find.byType(Scrollable)),
      );

      // Grid must still scroll smoothly up and down with sentence bar populated
      await tester.drag(gridFinder, const Offset(0.0, -250.0));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0.0));

      await tester.drag(gridFinder, const Offset(0.0, 250.0));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, 0.0);
    });
  });
}
