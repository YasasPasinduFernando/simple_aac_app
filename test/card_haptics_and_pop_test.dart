import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    HomePage.enableTtsInit = false;
    HomePage.speakPerformer = (_) async {};
  });

  tearDown(() {
    HomePage.hapticPerformer = () async {};
    HomePage.speakPerformer = null;
    HomePage.enableTtsInit = true;
    HomePage.initialCardsForTesting = null;
    CardStorageService.resetTestHooks();
  });

  testWidgets('HomeDrawer displays Haptic Feedback switch and invokes onToggleHaptics',
      (tester) async {
    tester.view.physicalSize = const Size(384, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var toggledValue = false;
    var invoked = false;

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
            enableHaptics: true,
            onToggleHaptics: (val) {
              invoked = true;
              toggledValue = val;
            },
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
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Haptic Feedback'), 100);

    expect(find.text('Haptic Feedback'), findsOneWidget);
    expect(find.text('Vibration and pop feel when tapping cards'), findsOneWidget);

    await tester.tap(find.text('Haptic Feedback'));
    await tester.pumpAndSettle();

    expect(invoked, isTrue);
    expect(toggledValue, isFalse);
  });

  testWidgets('Card tap fires haptic feedback and triggers enhanced pop scale',
      (tester) async {
    HomePage.initialCardsForTesting = [
      AACCard(
        id: 'c1',
        label: 'Hello',
        colorValue: Colors.amber.value,
        imagePath: null,
      ),
    ];

    var hapticCount = 0;
    HomePage.hapticPerformer = () async {
      hapticCount++;
    };

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsWidgets);

    // Initial scale at rest should be 1.0
    final initialScaleFinder = find.byWidgetPredicate(
      (w) => w is AnimatedScale && w.scale == 1.0,
    );
    expect(initialScaleFinder, findsWidgets);

    // Tap on the card
    await tester.tap(find.text('Hello').first);
    await tester.pump(); // Advance into animation frame

    // Haptic feedback should have been executed
    expect(hapticCount, 1);

    // AnimatedScale should now target 1.08 (enhanced pop)
    final poppedScaleFinder = find.byWidgetPredicate(
      (w) => w is AnimatedScale && w.scale == 1.08,
    );
    expect(poppedScaleFinder, findsOneWidget);

    // Advance animation past timer (180ms + 160ms = 340ms)
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // Scale returns back to 1.0
    expect(
      find.byWidgetPredicate((w) => w is AnimatedScale && w.scale == 1.0),
      findsWidgets,
    );
  });

  testWidgets('When Haptic Feedback is disabled, tapping a card does not fire haptic feedback',
      (tester) async {
    HomePage.initialCardsForTesting = [
      AACCard(
        id: 'c2',
        label: 'Water',
        colorValue: Colors.blue.value,
        imagePath: null,
      ),
    ];

    var hapticCount = 0;
    HomePage.hapticPerformer = () async {
      hapticCount++;
    };

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    final homeState = tester.state(find.byType(HomePage)) as dynamic;
    homeState.enableHapticsForTesting = false;

    await tester.tap(find.text('Water').first);
    await tester.pump();

    // Haptic feedback should NOT be invoked
    expect(hapticCount, 0);

    // Pop scale animation still occurs
    expect(
      find.byWidgetPredicate((w) => w is AnimatedScale && w.scale == 1.08),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('Folder cards also trigger haptics and pop animation on tap',
      (tester) async {
    HomePage.initialCardsForTesting = [
      AACCard(
        id: 'f1',
        label: 'Actions',
        type: 'folder',
        colorValue: Colors.green.value,
        imagePath: null,
        subCards: [
          AACCard(id: 's1', label: 'Eat', colorValue: Colors.orange.value),
        ],
      ),
    ];

    var hapticCount = 0;
    HomePage.hapticPerformer = () async {
      hapticCount++;
    };

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Actions'), findsWidgets);

    await tester.tap(find.text('Actions').first);
    await tester.pump();

    // Haptics fired for folder card
    expect(hapticCount, 1);

    // Folder navigation transitioned to sub-cards
    expect(find.text('Eat'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('Settings reset restores enableHaptics to default true',
      (tester) async {
    HomePage.initialCardsForTesting = const [];

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    final homeState = tester.state(find.byType(HomePage)) as dynamic;
    homeState.enableHapticsForTesting = false;
    expect(homeState.enableHapticsForTesting, isFalse);

    // Reset settings to defaults
    homeState.resetSettingsForTesting();
    await tester.pumpAndSettle();

    expect(homeState.enableHapticsForTesting, isTrue,
        reason: 'Reset settings must restore enableHaptics to default true');
  });
}
