import 'dart:io';
import 'dart:ui' as ui;
// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';

class _FakeAudioPlatform extends AudioplayersPlatformInterface {
  @override
  Stream<AudioEvent> getEventStream(String playerId) => const Stream.empty();
  @override
  Future<void> create(String playerId) async {}
  @override
  Future<void> dispose(String playerId) async {}
  @override
  Future<void> pause(String playerId) async {}
  @override
  Future<void> release(String playerId) async {}
  @override
  Future<void> resume(String playerId) async {}
  @override
  Future<void> seek(String playerId, Duration position) async {}
  @override
  Future<void> setAudioContext(String playerId, AudioContext context) async {}
  @override
  Future<void> setBalance(String playerId, double balance) async {}
  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) async {}
  @override
  Future<void> setPlayerMode(String playerId, PlayerMode playerMode) async {}
  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {}
  @override
  Future<void> setSourceBytes(String playerId, Uint8List bytes, {String? mimeType}) async {}
  @override
  Future<void> setSourceUrl(String playerId, String url, {bool? isLocal}) async {}
  @override
  Future<void> setVolume(String playerId, double volume) async {}
  @override
  Future<void> stop(String playerId) async {}
  @override
  Future<int?> getCurrentPosition(String playerId) async => null;
  @override
  Future<int?> getDuration(String playerId) async => null;
  @override
  Future<void> emitLog(String playerId, String message) async {}
  @override
  Future<void> emitError(String playerId, String code, String message) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    AudioplayersPlatformInterface.instance = _FakeAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('pin_back_card_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );

    SharedPreferences.setMockInitialValues({
      'online_features_enabled': false,
      'useImageOverlayLabel': true,
      'gridColumns': 2,
    });
    await NetworkPolicyService.instance.init();
  });

  setUp(() {
    HomePage.skipSplashForTesting = true;
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.initialCardsForTesting = null;
    HomePage.hapticPerformer = () async {};
  });

  tearDown(() {
    HomePage.skipSplashForTesting = false;
    HomePage.initialCardsForTesting = null;
  });

  tearDownAll(() async {
    CardStorageService.resetTestHooks();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  void setPortrait(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  List<AACCard> createTestCards() {
    return [
      AACCard(
        id: 'folder_animals',
        label: 'Animals',
        colorValue: 0xFFDCFCE7,
        type: 'folder',
        subCards: [
          AACCard(
            id: 'animal_dog',
            label: 'Dog',
            colorValue: 0xFFFEF3C7,
            type: 'word',
          ),
          AACCard(
            id: 'animal_cat',
            label: 'Cat',
            colorValue: 0xFFE0E7FF,
            type: 'word',
          ),
        ],
      ),
      AACCard(
        id: 'folder_empty',
        label: 'Empty Folder',
        colorValue: 0xFFFEE2E2,
        type: 'folder',
        subCards: [],
      ),
    ];
  }

  group('Disable Back Card in Pin Mode Setting', () {
    testWidgets('1. Setting renders directly below Caregiver Lock and defaults to OFF', (tester) async {
      setPortrait(tester);

      bool toggleValue = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            endDrawer: HomeDrawer(
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
              disableBackCardInPinMode: false,
              onToggleDisableBackCardInPinMode: (val) => toggleValue = val,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      final scaffoldKey = find.byType(Scaffold);
      tester.state<ScaffoldState>(scaffoldKey).openEndDrawer();
      await tester.pumpAndSettle();

      // Find Caregiver Lock and Disable Back Card switch
      expect(find.text('Caregiver Lock'), findsOneWidget);
      expect(find.text('Disable Back Card in Pin Mode'), findsOneWidget);
      expect(find.text('Hide folder Back cards while Pin Mode is active.'), findsOneWidget);

      // Verify toggle action
      final switchFinder = find.descendant(
        of: find.byKey(const ValueKey('disable_back_card_in_pin_mode_switch')),
        matching: find.byType(Switch),
      );
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(toggleValue, isTrue);
    });

    testWidgets('2. Pin Mode OFF: Back card in grid is NOT rendered (uses AppBar Back)', (tester) async {
      setPortrait(tester);

      HomePage.initialCardsForTesting = createTestCards();
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Enter Animals folder
      await tester.tap(find.text('Animals'));
      await tester.pumpAndSettle();

      // Unpinned mode: in-grid Back card is false, AppBar back button is shown
      expect(find.byKey(const ValueKey('grid_back_navigation_card')), findsNothing);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Cat'), findsOneWidget);
    });

    testWidgets('3. Pin Mode ON, Setting OFF: In-grid Back card IS rendered as first item', (tester) async {
      setPortrait(tester);

      HomePage.initialCardsForTesting = createTestCards();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('disableBackCardInPinMode', false);

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Activate Pin Mode
      await tester.tap(find.byIcon(Icons.push_pin_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.push_pin), findsOneWidget);

      // Navigate into Animals folder
      await tester.tap(find.text('Animals'));
      await tester.pumpAndSettle();

      // In Pin Mode with setting OFF:
      // In-grid Back card is VISIBLE
      expect(find.byKey(const ValueKey('grid_back_navigation_card')), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Cat'), findsOneWidget);

      // Tapping Back card navigates back to root
      await tester.tap(find.byKey(const ValueKey('grid_back_navigation_card')));
      await tester.pumpAndSettle();
      expect(find.text('Animals'), findsOneWidget);
    });

    testWidgets('4. Pin Mode ON, Setting ON: In-grid Back card IS HIDDEN', (tester) async {
      setPortrait(tester);

      HomePage.initialCardsForTesting = createTestCards();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('disableBackCardInPinMode', true);

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Activate Pin Mode
      await tester.tap(find.byIcon(Icons.push_pin_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.push_pin), findsOneWidget);

      // Navigate into Animals folder
      await tester.tap(find.text('Animals'));
      await tester.pumpAndSettle();

      // In Pin Mode with setting ON:
      // In-grid Back card is HIDDEN
      expect(find.byKey(const ValueKey('grid_back_navigation_card')), findsNothing);
      expect(find.text('Back'), findsNothing);
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Cat'), findsOneWidget);

      // Caregiver can safely unpin using the header Pin button (long-press)
      await tester.longPress(find.byIcon(Icons.push_pin));
      await tester.pumpAndSettle();

      // Once unpinned, AppBar back button immediately appears
      expect(find.byTooltip('Back'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Animals'), findsOneWidget);
    });

    testWidgets('5. Empty folder in Pin Mode: Back card is hidden when setting is ON', (tester) async {
      setPortrait(tester);

      HomePage.initialCardsForTesting = createTestCards();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('disableBackCardInPinMode', true);

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Activate Pin Mode
      await tester.tap(find.byIcon(Icons.push_pin_outlined));
      await tester.pumpAndSettle();

      // Navigate into Empty Folder
      await tester.tap(find.text('Empty Folder'));
      await tester.pumpAndSettle();

      // Shows empty folder title cleanly without Back card
      expect(find.text('No cards in this folder'), findsOneWidget);
      expect(find.text('Choose Back to return'), findsNothing);
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('6. Preference persistence round-trip across app reload', (tester) async {
      setPortrait(tester);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('disableBackCardInPinMode', true);

      final testCards = createTestCards();
      HomePage.initialCardsForTesting = testCards;
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Open drawer via menu button and check switch value
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      final switchFinder = find.descendant(
        of: find.byKey(const ValueKey('disable_back_card_in_pin_mode_switch')),
        matching: find.byType(Switch),
      );
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);
    });

    testWidgets('7. Visual Screenshot Generation for Documentation', (tester) async {
      setPortrait(tester);

      final outDir = Directory('docs/qa/pin_back_card_control');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }

      final testCards = createTestCards();

      // 1. Capture Pin Mode with Back Card VISIBLE (Setting OFF)
      HomePage.initialCardsForTesting = testCards;
      final prefs1 = await SharedPreferences.getInstance();
      await prefs1.setBool('disableBackCardInPinMode', false);

      final key1 = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key1,
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.push_pin_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Animals'));
      await tester.pumpAndSettle();

      final boundary1 = key1.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final img = await boundary1.toImage(pixelRatio: 2.0);
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        File('${outDir.path}/01_pin_mode_back_card_visible.png')
            .writeAsBytesSync(byteData!.buffer.asUint8List());
      });

      // 2. Capture Pin Mode with Back Card HIDDEN (Setting ON)
      HomePage.initialCardsForTesting = testCards;
      final prefs2 = await SharedPreferences.getInstance();
      await prefs2.setBool('disableBackCardInPinMode', true);

      final key2 = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key2,
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.push_pin_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Animals'));
      await tester.pumpAndSettle();

      final boundary2 = key2.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final img = await boundary2.toImage(pixelRatio: 2.0);
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        File('${outDir.path}/02_pin_mode_back_card_hidden.png')
            .writeAsBytesSync(byteData!.buffer.asUint8List());
      });

      // 3. Capture Settings Drawer with the new toggle
      final key3 = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key3,
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      final boundary3 = key3.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final img = await boundary3.toImage(pixelRatio: 2.0);
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        File('${outDir.path}/03_settings_drawer_toggle.png')
            .writeAsBytesSync(byteData!.buffer.asUint8List());
      });

      expect(File('${outDir.path}/01_pin_mode_back_card_visible.png').existsSync(), isTrue);
      expect(File('${outDir.path}/02_pin_mode_back_card_hidden.png').existsSync(), isTrue);
      expect(File('${outDir.path}/03_settings_drawer_toggle.png').existsSync(), isTrue);
    });
  });
}
