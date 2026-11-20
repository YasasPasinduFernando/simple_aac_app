import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';

// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';

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
    tempDir = await Directory.systemTemp.createTemp('pin_header_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
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
    HomePage.hapticPerformer = HapticFeedback.lightImpact;
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

  void setLandscape(WidgetTester tester) {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Pin Mode Header Consistency: Tests 1 - 7 (Folder Depths, Controls & Caregiver Unpin)', () {
    testWidgets('Test 1-5: Pin icon visible and Orientation shortcut hidden across Root Home, Default, and Family', (tester) async {
      setPortrait(tester);

      final familyCategory = AACCard(
        id: 'cat_family',
        label: 'Family',
        type: 'folder',
        colorValue: 0xFFD7C6E9,
        subCards: [
          AACCard(
            id: 'item_mother',
            label: 'Mother',
            colorValue: 0xFFE9D5FF,
          ),
          AACCard(
            id: 'item_father',
            label: 'Father',
            colorValue: 0xFFE9D5FF,
          ),
        ],
      );

      final defaultRoot = AACCard(
        id: StarterPackService.starterPackRootId,
        label: 'Default',
        type: 'folder',
        colorValue: 0xFF0277BD,
        subCards: [familyCategory],
      );

      final initialCards = [
        AACCard(id: 'seed_hello', label: 'Hello', colorValue: 0xFFFFF176),
        defaultRoot,
      ];

      HomePage.initialCardsForTesting = initialCards;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Prior to pinning: Orientation button is visible, Pin button is outline
      expect(find.byKey(const ValueKey('home_app_bar_orientation_button')), findsOneWidget);
      final pinButton = find.byIcon(Icons.push_pin_outlined);
      expect(pinButton, findsOneWidget);

      // --- TEST 1: Open Home, enable Pin Mode ---
      await tester.tap(pinButton);
      await tester.pumpAndSettle();

      // Expected: Pin icon visible (filled); orientation shortcut hidden; Menu hidden
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.byKey(const ValueKey('home_app_bar_orientation_button')), findsNothing);
      expect(find.byIcon(Icons.menu_rounded), findsNothing);

      // --- TEST 2: Navigate Home > Default ---
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();

      // Expected: Pin icon remains visible; orientation hidden; back button in AppBar hidden
      expect(find.byIcon(Icons.push_pin), findsOneWidget, reason: 'Pin control must remain visible in Default folder');
      expect(find.byKey(const ValueKey('home_app_bar_orientation_button')), findsNothing, reason: 'Orientation shortcut must be hidden in Default folder');
      expect(find.byTooltip('Back'), findsNothing);
      expect(find.text('Default'), findsOneWidget);
      expect(find.byKey(const ValueKey('grid_back_card')), findsOneWidget);

      // --- TEST 3: Navigate Default > Family ---
      await tester.tap(find.text('Family'));
      await tester.pumpAndSettle();

      // Expected: Pin icon remains visible; orientation hidden
      expect(find.byIcon(Icons.push_pin), findsOneWidget, reason: 'Pin control must remain visible in Family folder');
      expect(find.byKey(const ValueKey('home_app_bar_orientation_button')), findsNothing, reason: 'Orientation shortcut must be hidden in Family folder');
      expect(find.byTooltip('Back'), findsNothing);
      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Mother'), findsOneWidget);
      expect(find.byKey(const ValueKey('grid_back_card')), findsOneWidget);

      // --- TEST 5: Navigate back to Home ---
      // Tap Back card in Family -> returns to Default
      await tester.tap(find.byKey(const ValueKey('grid_back_card')));
      await tester.pumpAndSettle();
      expect(find.text('Default'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);

      // Tap Back card in Default -> returns to Root Home
      await tester.tap(find.byKey(const ValueKey('grid_back_card')));
      await tester.pumpAndSettle();
      expect(find.text('Simple AAC'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.byKey(const ValueKey('home_app_bar_orientation_button')), findsNothing);

      // --- TEST 6: Normal tap does NOT unpin; Long-press exits Pin Mode ---
      // Normal tap triggers notice dialog/snackbar, does not unpin
      await tester.tap(find.byIcon(Icons.push_pin));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.push_pin), findsOneWidget, reason: 'Short tap must NOT unpin board');

      int haptics = 0;
      HomePage.hapticPerformer = () async => haptics++;

      // Long press unpins the board
      await tester.longPress(find.byIcon(Icons.push_pin));
      await tester.pumpAndSettle();
      expect(haptics, greaterThanOrEqualTo(1));

      // --- TEST 7: After unpinning, normal header controls restored ---
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget, reason: 'Unpinned board displays outline pin');
      expect(find.byKey(const ValueKey('home_app_bar_orientation_button')), findsOneWidget, reason: 'Orientation shortcut restored');
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget, reason: 'Menu button restored');
    });

    testWidgets('Test 4: Deep nested custom folders display Pin icon and hide Orientation at every depth', (tester) async {
      setPortrait(tester);

      final deepFolder = AACCard(
        id: 'depth_1',
        label: 'Depth 1',
        type: 'folder',
        colorValue: 0xFFE1BEE7,
        subCards: [
          AACCard(
            id: 'depth_2',
            label: 'Depth 2',
            type: 'folder',
            colorValue: 0xFFC5CAE9,
            subCards: [
              AACCard(
                id: 'depth_3',
                label: 'Depth 3',
                type: 'folder',
                colorValue: 0xFFB2DFDB,
                subCards: [
                  AACCard(id: 'deep_treasure', label: 'Treasure', colorValue: 0xFFFFF59D),
                ],
              ),
            ],
          ),
        ],
      );

      HomePage.initialCardsForTesting = [deepFolder];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Pin board
      await tester.tap(find.byIcon(Icons.push_pin_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.push_pin), findsOneWidget);

      // Depth 1
      await tester.tap(find.text('Depth 1'));
      await tester.pumpAndSettle();
      expect(find.text('Depth 1'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.byKey(const ValueKey('home_app_bar_orientation_button')), findsNothing);

      // Depth 2
      await tester.tap(find.text('Depth 2'));
      await tester.pumpAndSettle();
      expect(find.text('Depth 2'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.byKey(const ValueKey('home_app_bar_orientation_button')), findsNothing);

      // Depth 3
      await tester.tap(find.text('Depth 3'));
      await tester.pumpAndSettle();
      expect(find.text('Depth 3'), findsOneWidget);
      expect(find.text('Treasure'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.byKey(const ValueKey('home_app_bar_orientation_button')), findsNothing);

      // Unpin directly from Depth 3 via long-press!
      await tester.longPress(find.byIcon(Icons.push_pin));
      await tester.pumpAndSettle();

      // Once unpinned at Depth 3:
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
      expect(find.byKey(const ValueKey('home_app_bar_orientation_button')), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
    });
  });

  group('Test 8: Landscape Layout & Rotation in Pin Mode', () {
    testWidgets('Landscape rail shows Pin button and hides Orientation button in Pin Mode', (tester) async {
      setLandscape(tester);

      final folder = AACCard(
        id: 'ls_folder',
        label: 'Things',
        type: 'folder',
        colorValue: 0xFF81D4FA,
        subCards: [
          AACCard(id: 'toy_car', label: 'Car', colorValue: 0xFFFFCC80),
        ],
      );

      HomePage.initialCardsForTesting = [folder];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Landscape rail has Pin button and Orientation button
      expect(find.byKey(const ValueKey('landscape_nav_pin')), findsOneWidget);
      expect(find.byKey(const ValueKey('landscape_nav_orientation')), findsOneWidget);

      // Pin the board
      await tester.tap(find.byKey(const ValueKey('landscape_nav_pin')));
      await tester.pumpAndSettle();

      // In Pin Mode:
      // Pin button is visible
      expect(find.byKey(const ValueKey('landscape_nav_pin')), findsOneWidget);
      // Orientation button is completely hidden from rail
      expect(find.byKey(const ValueKey('landscape_nav_orientation')), findsNothing);

      // Navigate into folder in landscape
      await tester.tap(find.text('Things'));
      await tester.pumpAndSettle();

      // Inside folder: Pin button remains visible; Orientation button remains hidden
      expect(find.byKey(const ValueKey('landscape_nav_pin')), findsOneWidget);
      expect(find.byKey(const ValueKey('landscape_nav_orientation')), findsNothing);
      expect(find.text('Car'), findsOneWidget);
    });
  });

  group('Test 9: Sentence Bar & Touch Interactions in Pin Mode', () {
    testWidgets('Sentence bar, speech tokens, and card tapping build sentence normally in Pin Mode', (tester) async {
      setPortrait(tester);

      final cardHello = AACCard(id: 'seed_hello', label: 'Hello', colorValue: 0xFFFFF176);
      final cardHappy = AACCard(id: 'seed_happy', label: 'Happy', colorValue: 0xFF81D4FA);

      HomePage.initialCardsForTesting = [cardHello, cardHappy];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Pin the board
      await tester.tap(find.byIcon(Icons.push_pin_outlined));
      await tester.pumpAndSettle();

      // Tap cards to build sentence
      await tester.tap(find.text('Hello'));
      await tester.pump();
      await tester.tap(find.text('Happy'));
      await tester.pump();

      // Sentence bar contains tokens
      expect(find.byKey(const ValueKey('tts_bar')), findsOneWidget);
      expect(find.text('Hello'), findsNWidgets(2)); // Card + Sentence token
      expect(find.text('Happy'), findsNWidgets(2)); // Card + Sentence token
    });
  });

  group('Visual Artifact Capture for Documentation', () {
    testWidgets('Renders and captures screenshots of Root Home and Nested Folders in Pin Mode', (tester) async {
      setPortrait(tester);

      final familyCategory = AACCard(
        id: 'cat_family',
        label: 'Family',
        type: 'folder',
        colorValue: 0xFFD7C6E9,
        subCards: [
          AACCard(id: 'item_mother', label: 'Mother', colorValue: 0xFFE9D5FF),
          AACCard(id: 'item_father', label: 'Father', colorValue: 0xFFE9D5FF),
        ],
      );

      final defaultRoot = AACCard(
        id: StarterPackService.starterPackRootId,
        label: 'Default',
        type: 'folder',
        colorValue: 0xFF0277BD,
        subCards: [familyCategory],
      );

      final initialCards = [
        AACCard(id: 'seed_hello', label: 'Hello', colorValue: 0xFFFFF176),
        defaultRoot,
      ];

      HomePage.initialCardsForTesting = initialCards;

      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: repaintKey,
            child: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> saveScreenshot(String filename) async {
        final boundary = repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final imgData = await boundary.toImage(pixelRatio: 2.0);
          final byteData = await imgData.toByteData(format: ui.ImageByteFormat.png);
          final bytes = byteData!.buffer.asUint8List();

          const artifactDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
          File('$artifactDir/$filename').writeAsBytesSync(bytes);

          final outDir = Directory('docs/qa/pin_header_consistency');
          if (!outDir.existsSync()) {
            outDir.createSync(recursive: true);
          }
          File('docs/qa/pin_header_consistency/$filename').writeAsBytesSync(bytes);
        });
      }

      // 1. Pin the board on Root Home
      await tester.tap(find.byIcon(Icons.push_pin_outlined));
      await tester.pumpAndSettle();

      // Capture Screenshot 1: Root Home in Pin Mode
      await saveScreenshot('pin_mode_root_home.png');

      // 2. Open Default Folder
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();

      // Capture Screenshot 2: Nested folder "Default" in Pin Mode
      await saveScreenshot('pin_mode_nested_default.png');

      // 3. Open Family Folder
      await tester.tap(find.text('Family'));
      await tester.pumpAndSettle();

      // Capture Screenshot 3: Nested folder "Family" in Pin Mode
      await saveScreenshot('pin_mode_nested_family.png');

      // 4. Return to Root Home and unpin
      await tester.tap(find.byKey(const ValueKey('grid_back_card')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('grid_back_card')));
      await tester.pumpAndSettle();

      await tester.longPress(find.byIcon(Icons.push_pin));
      await tester.pumpAndSettle();

      // Capture Screenshot 4: Root Home after unpinning (normal controls restored)
      await saveScreenshot('normal_mode_root_home_restored.png');
    });
  });
}
