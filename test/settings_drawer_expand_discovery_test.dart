import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DrawerGestureHintHelper.reset();
  });

  tearDown(() async {
    await DrawerGestureHintHelper.reset();
  });

  Widget buildTestSettingsDrawer({
    bool isExpanded = false,
    ValueChanged<bool>? onToggleExpanded,
    VoidCallback? onClose,
    bool? showGestureHint,
    bool isCaregiverLockEnabled = false,
    ValueChanged<bool>? onToggleCaregiverLock,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0267C1)),
      ),
      home: Builder(
        builder: (context) {
          final currentMq = MediaQuery.of(context);
          return MediaQuery(
            data: currentMq.copyWith(disableAnimations: disableAnimations),
            child: Scaffold(
              body: HomeDrawer(
                selectedCategory: 'All',
                currentLanguageLabel: 'English',
                gridColumns: 2,
                visibleCardsLabel: 'All cards',
                isEditMode: false,
                showTtsInput: true,
                orientationLabel: 'Portrait',
                fullScreen: true,
                headerColor: const Color(0xFF0267C1),
                headerTextColor: Colors.white,
                hideTtsText: false,
                useImageOverlayLabel: true,
                applyTextColorToCards: false,
                isDarkMode: false,
                isColorBlindMode: false,
                primaryColorSwatch: const Color(0xFF0267C1),
                textColorSwatch: const Color(0xFF111827),
                backgroundColorSwatch: const Color(0xFFFFF9E6),
                cardTextColorSwatch: const Color(0xFF111827),
                isOnlineEnabled: true,
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
                isExpanded: isExpanded,
                onToggleExpanded: onToggleExpanded,
                onClose: onClose,
                showGestureHint: showGestureHint,
                isCaregiverLockEnabled: isCaregiverLockEnabled,
                onToggleCaregiverLock: onToggleCaregiverLock,
              ),
            ),
          );
        },
      ),
    );
  }

  group('Settings Drawer Expand Discovery 15-Point Verification Suite', () {
    testWidgets('1. Settings partially opens normally in compact mode', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Swipe left to expand'), findsOneWidget);
      final drawerFinder = find.byType(Drawer);
      expect(drawerFinder, findsOneWidget);
      final drawerSize = tester.getSize(drawerFinder);
      expect(drawerSize.width, (400 * 0.82).clamp(280.0, 360.0));
    });

    testWidgets('2. Scrolling briefly (<3s) does NOT immediately trigger the nudge animation', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      // Perform a brief scroll (200ms)
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pump(const Duration(milliseconds: 200));

      final transform = tester.widget<Transform>(find.byType(Transform).first);
      expect(transform.transform.getTranslation().x, equals(0.0));
    });

    testWidgets('3. Sustained scrolling triggers one gentle 12px nudge animation after scrolling stops',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      // Trigger scroll start
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 100));

      // Advance time past the 2.8s sustained scroll threshold while finger is down
      await tester.pump(const Duration(milliseconds: 2900));

      // Release finger so scrolling stops
      await gesture.up();
      await tester.pump(); // frame 0 of animation

      // In the middle of 400ms nudge animation (at ~160ms), drawer moves 12px left
      await tester.pump(const Duration(milliseconds: 160));
      final transformMid = tester.widget<Transform>(find.byType(Transform).first);
      expect(transformMid.transform.getTranslation().x, closeTo(-12.0, 1.0));

      // At end of 400ms, returns cleanly to 0
      await tester.pump(const Duration(milliseconds: 240));
      final transformEnd = tester.widget<Transform>(find.byType(Transform).first);
      expect(transformEnd.transform.getTranslation().x, equals(0.0));
    });

    testWidgets('4. The animation runs only when eligible (not when already expanded)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: true));
      await tester.pumpAndSettle();

      // When expanded, hint bar is hidden and nudge never triggers
      expect(find.text('Swipe left to expand'), findsNothing);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
      await gesture.moveBy(const Offset(0, -50));
      await tester.pump(const Duration(seconds: 3));
      await gesture.up();
      await tester.pump();

      final transform = tester.widget<Transform>(find.byType(Transform).first);
      expect(transform.transform.getTranslation().x, equals(0.0));
    });

    testWidgets('5. Drawer remains partially expanded after nudge finishes', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool expanded = false;
      await tester.pumpWidget(
        buildTestSettingsDrawer(
          isExpanded: expanded,
          onToggleExpanded: (val) => expanded = val,
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(seconds: 3));
      await gesture.up();
      await tester.pumpAndSettle();

      // Still compact, was not forced to expand automatically
      expect(expanded, isFalse);
      final drawerSize = tester.getSize(find.byType(Drawer));
      expect(drawerSize.width, (400 * 0.82).clamp(280.0, 360.0));
    });

    testWidgets('6. Tapping the suggestion expands the drawer and marks discovery', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool expanded = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestSettingsDrawer(
              isExpanded: expanded,
              onToggleExpanded: (val) {
                setState(() => expanded = val);
              },
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      final hintTapFinder = find.byKey(const ValueKey('drawer_gesture_hint_bar_tap'));
      expect(hintTapFinder, findsOneWidget);

      await tester.tap(hintTapFinder);
      await tester.pumpAndSettle();

      expect(expanded, isTrue);
      expect(DrawerGestureHintHelper.hasDiscoveredExpansion, isTrue);
      // When expanded, the unnecessary suggestion is cleanly hidden
      expect(find.text('Swipe left to expand'), findsNothing);
    });

    testWidgets('7. Swiping left on the drawer still expands normally', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool expanded = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestSettingsDrawer(
              isExpanded: expanded,
              onToggleExpanded: (val) {
                setState(() => expanded = val);
              },
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('Settings'), const Offset(-60, 0));
      await tester.pumpAndSettle();

      expect(expanded, isTrue);
      expect(DrawerGestureHintHelper.hasDiscoveredExpansion, isTrue);
    });

    testWidgets('8. Suggestion dismissal via close icon is respected and silences hints', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      final dismissBtn = find.byKey(const ValueKey('drawer_gesture_hint_dismiss_button'));
      expect(dismissBtn, findsOneWidget);

      await tester.tap(dismissBtn);
      await tester.pumpAndSettle();

      expect(find.text('Swipe left to expand'), findsNothing);
      expect(DrawerGestureHintHelper.isSessionDismissed, isTrue);

      // Scroll after dismissal does not trigger nudge
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(seconds: 3));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 160));

      final transform = tester.widget<Transform>(find.byType(Transform).first);
      expect(transform.transform.getTranslation().x, equals(0.0));
    });

    testWidgets('9. Successful expansion prevents repeated hints in future sessions', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await DrawerGestureHintHelper.markExpansionDiscovered();

      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      // Since expansion was discovered, hint bar is silenced
      expect(find.text('Swipe left to expand'), findsNothing);
    });

    testWidgets('10. Reopening Settings does not cause animation spam (at most once per opening)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      // Trigger first nudge
      var gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(seconds: 3));
      await gesture.up();
      await tester.pumpAndSettle();

      // Attempt second scroll in same session
      gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(seconds: 3));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 160));

      final transform = tester.widget<Transform>(find.byType(Transform).first);
      // Stays 0.0 because it already nudged once this session
      expect(transform.transform.getTranslation().x, equals(0.0));
    });

    testWidgets('11. Portrait layout works cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Swipe left to expand'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('12. Landscape layout works cleanly and clamps compact drawer width', (tester) async {
      tester.view.physicalSize = const Size(2400, 1080);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      final drawerSize = tester.getSize(find.byType(Drawer));
      // In landscape (width 1200dp), clamped to max compact width 360.0
      expect(drawerSize.width, 360.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('13. Reduced-motion / disableAnimations preference suppresses translation but retains tap',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool expanded = false;
      await tester.pumpWidget(
        buildTestSettingsDrawer(
          isExpanded: false,
          disableAnimations: true,
          onToggleExpanded: (val) => expanded = val,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll with reduced motion
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(seconds: 3));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 160));

      final transform = tester.widget<Transform>(find.byType(Transform).first);
      // Movement is completely suppressed
      expect(transform.transform.getTranslation().x, equals(0.0));

      // But tapping the hint still expands!
      await tester.tap(find.byKey(const ValueKey('drawer_gesture_hint_bar_tap')));
      await tester.pumpAndSettle();
      expect(expanded, isTrue);
    });

    testWidgets('14. Caregiver Lock integration is preserved and unaffected', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool lockToggled = false;
      await tester.pumpWidget(
        buildTestSettingsDrawer(
          isExpanded: false,
          isCaregiverLockEnabled: true,
          onToggleCaregiverLock: (val) => lockToggled = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Caregiver Lock'), findsOneWidget);
      expect(find.text('Lock active: Phone biometrics or PIN required'), findsOneWidget);

      await tester.tap(find.text('Caregiver Lock'));
      await tester.pump();
      expect(lockToggled, isTrue);
    });

    testWidgets('15. Visual Screenshot Capture: Generates before & after drawer expansion artifacts',
        (tester) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final outDir = Directory(
          '/home/yasas/HomeCloud-Transfer/PersonalProjects/simple aac/simple_aac_play_release/docs/qa/drawer_expand_discovery');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }

      // 1. Capture Compact Drawer with hint
      final compactKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: compactKey,
          child: buildTestSettingsDrawer(isExpanded: false),
        ),
      );
      await tester.pumpAndSettle();

      final compactBoundary =
          compactKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final img = await compactBoundary.toImage(pixelRatio: 2.0);
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        File('${outDir.path}/drawer_01_compact_with_hint.png')
            .writeAsBytesSync(byteData!.buffer.asUint8List());
      });

      // 2. Capture Expanded Drawer
      final expandedKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: expandedKey,
          child: buildTestSettingsDrawer(isExpanded: true),
        ),
      );
      await tester.pumpAndSettle();

      final expandedBoundary =
          expandedKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final img = await expandedBoundary.toImage(pixelRatio: 2.0);
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        File('${outDir.path}/drawer_02_expanded_fullscreen.png')
            .writeAsBytesSync(byteData!.buffer.asUint8List());
      });

      expect(File('${outDir.path}/drawer_01_compact_with_hint.png').existsSync(), isTrue);
      expect(File('${outDir.path}/drawer_02_expanded_fullscreen.png').existsSync(), isTrue);
    });
  });

  group('Phase 6 — Settings Drawer Gesture Discovery Two-Session Specification', () {
    testWidgets('1. First eligible session shows the hint and increments session count to 1',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      expect(find.text('Swipe left to expand'), findsOneWidget);
      expect(DrawerGestureHintHelper.sessionCount, equals(1));
      expect(DrawerGestureHintHelper.hasRecordedCurrentSession, isTrue);
    });

    testWidgets('2. Second eligible session shows reminder and increments count to 2',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Session 1
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();
      expect(DrawerGestureHintHelper.sessionCount, equals(1));

      // Simulate App Restart (Session 2)
      DrawerGestureHintHelper.resetSessionForTesting();
      await tester.pumpWidget(Container()); // unmount
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      expect(find.text('Swipe left to expand'), findsOneWidget);
      expect(DrawerGestureHintHelper.sessionCount, equals(2));
    });

    testWidgets('3. Third session automatically stops showing discovery hint',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Session 1
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      // Session 2
      DrawerGestureHintHelper.resetSessionForTesting();
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      // Session 3
      DrawerGestureHintHelper.resetSessionForTesting();
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      // In Session 3, hint is permanently hidden
      expect(find.text('Swipe left to expand'), findsNothing);
      expect(DrawerGestureHintHelper.isDiscoveryExhausted, isTrue);
      expect(DrawerGestureHintHelper.sessionCount, equals(2));
    });

    testWidgets('4. Repeated Settings openings in same session do NOT increase session count',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // First opening in Session 1
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();
      expect(find.text('Swipe left to expand'), findsOneWidget);
      expect(DrawerGestureHintHelper.sessionCount, equals(1));

      // Close / unmount drawer
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      // Second opening in same session
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();
      expect(find.text('Swipe left to expand'), findsOneWidget);
      expect(DrawerGestureHintHelper.sessionCount, equals(1)); // STILL 1

      // Third opening in same session
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();
      expect(find.text('Swipe left to expand'), findsOneWidget);
      expect(DrawerGestureHintHelper.sessionCount, equals(1)); // STILL 1
    });

    testWidgets('5. Opening in expanded mode does not count toward eligible sessions',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Open directly in expanded mode
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: true));
      await tester.pumpAndSettle();

      expect(find.text('Swipe left to expand'), findsNothing);
      expect(DrawerGestureHintHelper.sessionCount, equals(0)); // Not counted
      expect(DrawerGestureHintHelper.hasRecordedCurrentSession, isFalse);
    });

    testWidgets('6. Header expand button does NOT mark swipe discovery',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool isExpanded = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestSettingsDrawer(
              isExpanded: isExpanded,
              onToggleExpanded: (val) => setState(() => isExpanded = val),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Swipe left to expand'), findsOneWidget);

      // Tap header resize/expand button
      final expandBtn = find.byTooltip('Expand Settings');
      expect(expandBtn, findsOneWidget);
      await tester.tap(expandBtn);
      await tester.pumpAndSettle();

      expect(isExpanded, isTrue);
      // Crucial: Header expand must NOT mark swipe gesture discovered!
      expect(DrawerGestureHintHelper.hasDiscoveredExpansion, isFalse);

      // Close and restart app session
      DrawerGestureHintHelper.resetSessionForTesting();
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      // Reopening in Session 2 still shows hint because gesture was not discovered
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      expect(find.text('Swipe left to expand'), findsOneWidget);
      expect(DrawerGestureHintHelper.sessionCount, equals(2));
    });

    testWidgets('7. Successful swipe-left permanently marks discovery',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool isExpanded = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestSettingsDrawer(
              isExpanded: isExpanded,
              onToggleExpanded: (val) => setState(() => isExpanded = val),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Swipe left
      await tester.drag(find.text('Settings'), const Offset(-60, 0));
      await tester.pumpAndSettle();

      expect(isExpanded, isTrue);
      expect(DrawerGestureHintHelper.hasDiscoveredExpansion, isTrue);

      // Restart session
      DrawerGestureHintHelper.resetSessionForTesting();
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      // Session 2 will NOT show hint because gesture was discovered
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();
      expect(find.text('Swipe left to expand'), findsNothing);
    });

    testWidgets('8. Hint banner interaction permanently marks discovery',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool isExpanded = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestSettingsDrawer(
              isExpanded: isExpanded,
              onToggleExpanded: (val) => setState(() => isExpanded = val),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap hint banner
      await tester.tap(find.byKey(const ValueKey('drawer_gesture_hint_bar_tap')));
      await tester.pumpAndSettle();

      expect(isExpanded, isTrue);
      expect(DrawerGestureHintHelper.hasDiscoveredExpansion, isTrue);

      // Restart session
      DrawerGestureHintHelper.resetSessionForTesting();
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      // Reopening in Session 2 will NOT show hint
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();
      expect(find.text('Swipe left to expand'), findsNothing);
    });

    testWidgets('9. X dismissal hides hint for current session but leaves Session 2 eligible',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      expect(find.text('Swipe left to expand'), findsOneWidget);
      expect(DrawerGestureHintHelper.sessionCount, equals(1));

      // Tap X dismiss
      await tester.tap(find.byKey(const ValueKey('drawer_gesture_hint_dismiss_button')));
      await tester.pumpAndSettle();

      expect(find.text('Swipe left to expand'), findsNothing);
      expect(DrawerGestureHintHelper.isSessionDismissed, isTrue);
      expect(DrawerGestureHintHelper.hasDiscoveredExpansion, isFalse);

      // Reopen within same session: remains hidden
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();
      expect(find.text('Swipe left to expand'), findsNothing);

      // Simulate App Restart (Session 2)
      DrawerGestureHintHelper.resetSessionForTesting();
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      // In Session 2, hint appears as reminder
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();
      expect(find.text('Swipe left to expand'), findsOneWidget);
      expect(DrawerGestureHintHelper.sessionCount, equals(2));
    });

    testWidgets('10. Scroll micro-nudge is silenced when discovery is exhausted after 2 sessions',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Complete 2 sessions
      SharedPreferences.setMockInitialValues({
        DrawerGestureHintHelper.prefKeySessionCount: 2,
      });
      await DrawerGestureHintHelper.loadPreferences();

      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();

      // Hint is not shown
      expect(find.text('Swipe left to expand'), findsNothing);

      // Sustained scroll
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(seconds: 3));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 160));

      // Nudge did NOT trigger
      final transform = tester.widget<Transform>(find.byType(Transform).first);
      expect(transform.transform.getTranslation().x, equals(0.0));
    });

    testWidgets('11. Legacy devices with has_discovered_drawer_expansion=true receive 2 discovery sessions',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Simulate legacy device where user tapped header button in older version
      SharedPreferences.setMockInitialValues({
        'has_discovered_drawer_expansion': true,
      });
      await DrawerGestureHintHelper.loadPreferences();

      // Legacy user has NOT discovered v2 gesture yet
      expect(DrawerGestureHintHelper.hasDiscoveredExpansion, isFalse);

      // Session 1 shows hint
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();
      expect(find.text('Swipe left to expand'), findsOneWidget);
      expect(DrawerGestureHintHelper.sessionCount, equals(1));

      // Session 2 shows reminder
      DrawerGestureHintHelper.resetSessionForTesting();
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();
      expect(find.text('Swipe left to expand'), findsOneWidget);
      expect(DrawerGestureHintHelper.sessionCount, equals(2));

      // Session 3 stops
      DrawerGestureHintHelper.resetSessionForTesting();
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(buildTestSettingsDrawer(isExpanded: false));
      await tester.pumpAndSettle();
      expect(find.text('Swipe left to expand'), findsNothing);
    });
  });
}
