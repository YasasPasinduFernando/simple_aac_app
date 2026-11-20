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
import 'package:simple_aac_app/widgets/home_app_bar.dart';
import 'package:simple_aac_app/widgets/landscape_menu.dart';

class FakeAudioplayerPlatform extends AudioplayersPlatformInterface {
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
    AudioplayersPlatformInterface.instance = FakeAudioplayerPlatform();
    tempDir = await Directory.systemTemp.createTemp('pinned_child_test_');
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
  });

  tearDown(() {
    HomePage.skipSplashForTesting = false;
    HomePage.initialCardsForTesting = null;
  });

  tearDownAll(() async {
    CardStorageService.resetTestHooks();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  void setPortrait(WidgetTester tester) {
    tester.view.physicalSize = const ui.Size(400 * 2.0, 800 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }



  group('1. HomeAppBar Header Visibility in Pin & Normal Modes', () {
    testWidgets('Normal Mode Root Home: Pin button visible, Back button hidden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: HomeAppBar(
              title: 'Simple AAC',
              showBack: false,
              onBack: () {},
              showPin: true,
              isPinned: false,
              onTogglePin: () {},
              isEditMode: false,
              showMenu: true,
              onOpenMenu: () {},
              backgroundColor: const Color(0xFF0277BD),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
      expect(find.byTooltip('Back'), findsNothing);
      expect(find.text('Simple AAC'), findsOneWidget);
    });

    testWidgets('Normal Mode Nested Folder: Both Pin and Back buttons visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: HomeAppBar(
              title: 'Animals',
              showBack: true,
              onBack: () {},
              showPin: true,
              isPinned: false,
              onTogglePin: () {},
              isEditMode: false,
              showMenu: true,
              onOpenMenu: () {},
              backgroundColor: const Color(0xFF0277BD),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.text('Animals'), findsOneWidget);
    });

    testWidgets('Pin Mode Root Home: Pin button visible (push_pin), Back button hidden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: HomeAppBar(
              title: 'Simple AAC',
              showBack: false,
              onBack: () {},
              showPin: true,
              isPinned: true,
              onTogglePin: () {},
              isEditMode: false,
              showMenu: false,
              onOpenMenu: () {},
              backgroundColor: const Color(0xFF0277BD),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.byTooltip('Back'), findsNothing);
      expect(find.text('Simple AAC'), findsOneWidget);
    });

    testWidgets('Pin Mode Nested Folder: Top-left Pin button is visible, Back and Orientation buttons are hidden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: HomeAppBar(
              title: 'Animals',
              showBack: false,
              onBack: () {},
              showPin: true,
              isPinned: true,
              onTogglePin: () {},
              isEditMode: false,
              showMenu: false,
              onOpenMenu: () {},
              onOrientation: () {},
              backgroundColor: const Color(0xFF0277BD),
            ),
          ),
        ),
      );

      // Top-left Pin button is visible
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      // Header Back button is hidden
      expect(find.byTooltip('Back'), findsNothing);
      // Header Orientation button is hidden
      expect(find.byKey(const ValueKey('home_app_bar_orientation_button')), findsNothing);
      expect(find.text('Animals'), findsOneWidget);
    });
  });

  group('2. LandscapeMenu Pin Button Visibility in Pin & Normal Modes', () {
    testWidgets('Landscape Root Home: Pin button visible in Pin Mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LandscapeMenu(
              showPin: true,
              isPinned: true,
              canGoBack: false,
              onTogglePin: () {},
              onOpenMenu: () {},
              onGoBack: () {},
              onHome: () {},
              onUp: () {},
              onDown: () {},
              onSearch: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('landscape_nav_pin')), findsOneWidget);
    });

    testWidgets('Landscape Nested Folder: Pin button visible in Pin Mode, Orientation button hidden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LandscapeMenu(
              showPin: true,
              isPinned: true,
              canGoBack: true,
              onTogglePin: () {},
              onOpenMenu: () {},
              onGoBack: () {},
              onHome: () {},
              onUp: () {},
              onDown: () {},
              onSearch: () {},
              onOrientation: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('landscape_nav_pin')), findsOneWidget);
      expect(find.byKey(const ValueKey('landscape_nav_orientation')), findsNothing);
    });
  });

  group('3. HomePage Full Integration: Navigation, Back Card & Empty State', () {
    testWidgets('Populated folder in Pin Mode: hides breadcrumb, shows Back card at index 0, and navigates', (tester) async {
      setPortrait(tester);
      final folderCard = AACCard(
        id: 'folder_animals',
        label: 'Animals',
        labelSinhala: 'සතුන්',
        labelTamil: 'விலங்குகள்',
        type: 'folder',
        colorValue: Colors.lightGreen.value,
        subCards: [
          AACCard(
            id: 'sub_dog',
            label: 'Dog',
            labelSinhala: 'බල්ලා',
            labelTamil: 'நாய்',
            colorValue: Colors.amber.value,
          ),
          AACCard(
            id: 'sub_cat',
            label: 'Cat',
            labelSinhala: 'පූසා',
            labelTamil: 'பூனை',
            colorValue: Colors.orange.value,
          ),
        ],
      );

      HomePage.initialCardsForTesting = [folderCard];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // 1. Enter Pin Mode on Root Home
      final pinButton = find.byIcon(Icons.push_pin_outlined);
      expect(pinButton, findsOneWidget);
      await tester.tap(pinButton);
      await tester.pumpAndSettle();

      // Verify board is pinned
      expect(find.byIcon(Icons.push_pin), findsOneWidget);

      // 2. Open the "Animals" folder
      final folderItem = find.text('Animals');
      expect(folderItem, findsOneWidget);
      await tester.tap(folderItem);
      await tester.pumpAndSettle();

      // Inside nested folder in Pin Mode:
      // A. Top-left Pin button is consistently visible for caregivers to unpin
      expect(find.byIcon(Icons.push_pin), findsOneWidget);

      // B. Top-left Header Back button is hidden (Back card in grid is used)
      expect(find.byTooltip('Back'), findsNothing);

      // C. Orientation button is completely hidden in Pin Mode
      expect(find.byKey(const ValueKey('home_app_bar_orientation_button')), findsNothing);

      // D. Breadcrumb bar is completely hidden
      expect(find.byKey(const ValueKey('normal_mode_breadcrumb_bar')), findsNothing);

      // D. Header title "Animals" is visible
      expect(find.text('Animals'), findsOneWidget);

      // E. Special Back navigation card is displayed at index 0!
      final gridBackCard = find.byKey(const ValueKey('grid_back_card'));
      expect(gridBackCard, findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // F. The child cards (Dog, Cat) are also present in the grid
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Cat'), findsOneWidget);

      // G. Tap the Back card -> navigates back to Root Home
      await tester.tap(gridBackCard);
      await tester.pumpAndSettle();

      // H. On Root Home: Back card is NOT present, folder is shown, Pin button is restored!
      expect(find.byKey(const ValueKey('grid_back_card')), findsNothing);
      expect(find.text('Simple AAC'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('Empty folder: displays friendly empty state and Back card, tapping navigates to parent', (tester) async {
      setPortrait(tester);
      final emptyFolder = AACCard(
        id: 'folder_empty',
        label: 'Empty Box',
        type: 'folder',
        colorValue: Colors.blue.value,
        subCards: [], // empty folder
      );

      HomePage.initialCardsForTesting = [emptyFolder];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Pin the board
      await tester.tap(find.byIcon(Icons.push_pin_outlined));
      await tester.pumpAndSettle();

      // Open empty folder
      await tester.tap(find.text('Empty Box'));
      await tester.pumpAndSettle();

      // Verify Empty State elements
      expect(find.text('No cards in this folder'), findsOneWidget);
      expect(find.text('Choose Back to return'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_rounded), findsOneWidget);

      final emptyBackCard = find.byKey(const ValueKey('empty_folder_back_card'));
      expect(emptyBackCard, findsOneWidget);

      // Tap Back card
      await tester.tap(emptyBackCard);
      await tester.pumpAndSettle();

      // Navigated back to Root Home
      expect(find.text('Simple AAC'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('Deep nested folders return one level at a time', (tester) async {
      setPortrait(tester);
      final deepFolder = AACCard(
        id: 'level_1',
        label: 'Level 1',
        type: 'folder',
        colorValue: Colors.purple.value,
        subCards: [
          AACCard(
            id: 'level_2',
            label: 'Level 2',
            type: 'folder',
            colorValue: Colors.indigo.value,
            subCards: [
              AACCard(
                id: 'deep_item',
                label: 'Gem',
                colorValue: Colors.amber.value,
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

      // Open Level 1
      await tester.tap(find.text('Level 1'));
      await tester.pumpAndSettle();
      expect(find.text('Level 1'), findsOneWidget);

      // Open Level 2
      await tester.tap(find.text('Level 2'));
      await tester.pumpAndSettle();
      expect(find.text('Level 2'), findsOneWidget);
      expect(find.text('Gem'), findsOneWidget);

      // Tap Back at Level 2 -> returns to Level 1
      await tester.tap(find.byKey(const ValueKey('grid_back_card')));
      await tester.pumpAndSettle();
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Level 2'), findsOneWidget);

      // Tap Back at Level 1 -> returns to Root Home
      await tester.tap(find.byKey(const ValueKey('grid_back_card')));
      await tester.pumpAndSettle();
      expect(find.text('Simple AAC'), findsOneWidget);
      expect(find.byKey(const ValueKey('grid_back_card')), findsNothing);
    });

    testWidgets('Caregiver can securely exit Pin Mode from Root Home', (tester) async {
      setPortrait(tester);
      int hapticCallCount = 0;
      HomePage.hapticPerformer = () async {
        hapticCallCount++;
      };

      HomePage.initialCardsForTesting = [
        AACCard(id: 'c1', label: 'Hello', colorValue: Colors.yellow.value),
      ];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // 1. Single tap pins
      final pinButton = find.byIcon(Icons.push_pin_outlined);
      await tester.tap(pinButton);
      await tester.pumpAndSettle();

      // 2. Single tap while pinned shows notice
      final pinnedButton = find.byIcon(Icons.push_pin);
      await tester.tap(pinnedButton);
      await tester.pump();
      expect(find.text('Press and hold to unpin'), findsOneWidget);

      // 3. Long press while pinned triggers haptic and unpins
      await tester.longPress(pinnedButton);
      await tester.pumpAndSettle();

      expect(hapticCallCount, greaterThanOrEqualTo(1));
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    });
  });

  group('4. Render High-Resolution Visual Evidence Screenshots', () {
    testWidgets('Render high-res screenshots for A (Pinned populated), B (Pinned empty), C (Normal unpinned)', (tester) async {
      tester.view.physicalSize = const ui.Size(400 * 2.2, 850 * 2.2);
      tester.view.devicePixelRatio = 2.2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testCards = [
        AACCard(
          id: 'f_default',
          label: 'Default',
          type: 'folder',
          colorValue: 0xFF0284C7,
          subCards: [
            AACCard(id: 'c_drinks', label: 'Drinks', type: 'folder', colorValue: 0xFF38BDF8),
            AACCard(id: 'c_activities', label: 'Activities', type: 'folder', colorValue: 0xFFC084FC),
            AACCard(id: 'c_care', label: 'Personal Care', type: 'folder', colorValue: 0xFFFBBF24),
            AACCard(id: 'c_family', label: 'Family', type: 'folder', colorValue: 0xFFF472B6),
          ],
        ),
        AACCard(
          id: 'f_empty_animals',
          label: 'Animals',
          type: 'folder',
          colorValue: 0xFF10B981,
          subCards: [],
        ),
      ];

      HomePage.initialCardsForTesting = testCards;

      final renderRepaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: renderRepaintKey,
            child: const HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final outDir = Directory('docs/qa/pinned_child_mode');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }

      // Helper to capture RepaintBoundary as PNG
      Future<void> captureScreen(String fileName) async {
        final boundary = renderRepaintKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final pngBytes = byteData.buffer.asUint8List();
            final localFile = File('docs/qa/pinned_child_mode/$fileName');
            localFile.writeAsBytesSync(pngBytes);
            final artifactFile = File('/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013/$fileName');
            artifactFile.writeAsBytesSync(pngBytes);
          }
        }
      }

      // --- SCREEN C: Normal unpinned folder with breadcrumbs ---
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await captureScreen('screen_c_normal_unpinned_folder.png');
      });

      // Return to home
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Pin the board
      await tester.tap(find.byIcon(Icons.push_pin_outlined));
      await tester.pumpAndSettle();

      // --- SCREEN A: Pinned populated folder (Clean header, no breadcrumb, Back card at index 0) ---
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await captureScreen('screen_a_pinned_populated_folder.png');
      });

      // Tap Back card to return home
      await tester.tap(find.byKey(const ValueKey('grid_back_card')));
      await tester.pumpAndSettle();

      // --- SCREEN B: Pinned empty folder (Clean header, empty state illustration + Back card) ---
      await tester.tap(find.text('Animals'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await captureScreen('screen_b_pinned_empty_folder.png');
      });
    });
  });
}
