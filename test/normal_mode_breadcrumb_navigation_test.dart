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

  setUp(() async {
    AudioplayersPlatformInterface.instance = FakeAudioplayerPlatform();
    tempDir = await Directory.systemTemp.createTemp('normal_breadcrumb_test_');
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
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
  });

  tearDown(() async {
    CardStorageService.resetTestHooks();
    HomePage.initialCardsForTesting = null;
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  List<AACCard> createSampleHierarchy() {
    final dog = AACCard(
      id: 'c_dog',
      label: 'Dog',
      colorValue: 0xFFDCEDC8,
    );
    final cat = AACCard(
      id: 'c_cat',
      label: 'Cat',
      colorValue: 0xFFDCEDC8,
    );
    final animalsFolder = AACCard(
      id: 'f_animals',
      label: 'Animals',
      type: 'folder',
      colorValue: 0xFF81C784,
      subCards: [dog, cat],
    );
    final foodFolder = AACCard(
      id: 'f_food',
      label: 'Food',
      type: 'folder',
      colorValue: 0xFFFFB74D,
      subCards: [],
    );
    final defaultFolder = AACCard(
      id: 'f_default',
      label: 'Default',
      type: 'folder',
      colorValue: 0xFF1E88E5,
      subCards: [animalsFolder, foodFolder],
    );
    final hello = AACCard(
      id: 'c_hello',
      label: 'Hello',
      colorValue: 0xFFFEE685,
    );
    return [hello, defaultFolder];
  }

  testWidgets(
    'Normal Mode Breadcrumb: hidden on root Home board, visible inside folder, preserves sentence state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      HomePage.initialCardsForTesting = createSampleHierarchy();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Root Board: Breadcrumb should NOT be visible
      expect(find.byKey(const ValueKey('normal_mode_breadcrumb_bar')), findsNothing);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);

      // Tap 'Hello' card to build sentence token
      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle();

      // Verify TTS bar contains 'Hello'
      expect(find.text('Hello'), findsNWidgets(2)); // Card + TTS bar token

      // 2. Open 'Default' folder in Normal Mode
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();

      // Breadcrumb bar must now be visible
      expect(find.byKey(const ValueKey('normal_mode_breadcrumb_bar')), findsOneWidget);
      expect(find.text('Animals'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      // No edit mode drop hints in Normal Mode
      expect(find.text('Drop card to move up'), findsNothing);

      // Sentence token 'Hello' MUST be preserved across folder entry
      expect(find.text('Hello'), findsOneWidget); // in TTS bar

      // 3. Open nested 'Animals' folder
      await tester.tap(find.text('Animals'));
      await tester.pumpAndSettle();

      // Inside Animals: Dog and Cat are visible
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Cat'), findsOneWidget);

      // Breadcrumb shows: Home > Default > Animals
      expect(find.byKey(const ValueKey('normal_mode_breadcrumb_home')), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Animals'), findsNWidgets(2)); // Breadcrumb + AppBar title

      // Tap 'Dog' to add to sentence
      await tester.tap(find.text('Dog'));
      await tester.pumpAndSettle();

      // Sentence tokens 'Hello' and 'Dog' are both active
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Dog'), findsNWidgets(2)); // Card + TTS bar token

      // 4. Test clicking ancestor 'Default' in breadcrumb trail
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();

      // We should now be back inside 'Default'
      expect(find.text('Animals'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.byKey(const ValueKey('normal_mode_breadcrumb_bar')), findsOneWidget);
      // Sentence tokens still preserved!
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Dog'), findsOneWidget);

      // 5. Test clicking 'Home' in breadcrumb trail
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Root board reached: breadcrumb hidden, root cards visible
      expect(find.byKey(const ValueKey('normal_mode_breadcrumb_bar')), findsNothing);
      expect(find.text('Default'), findsOneWidget);
      // Sentence tokens still preserved!
      expect(find.text('Hello'), findsNWidgets(2)); // Card + TTS bar
      expect(find.text('Dog'), findsOneWidget); // TTS bar token
    },
  );

  testWidgets(
    'Normal Mode Breadcrumb: back arrow navigates up one level to parent folder',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      HomePage.initialCardsForTesting = createSampleHierarchy();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter 'Default' -> then 'Animals'
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Animals'));
      await tester.pumpAndSettle();

      expect(find.text('Dog'), findsOneWidget);

      // Tap breadcrumb back button
      final breadcrumbBack = find.byKey(const ValueKey('normal_mode_breadcrumb_back'));
      expect(breadcrumbBack, findsOneWidget);
      await tester.tap(breadcrumbBack);
      await tester.pumpAndSettle();

      // Should be back in 'Default'
      expect(find.text('Animals'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);

      // Tap breadcrumb back button again
      await tester.tap(breadcrumbBack);
      await tester.pumpAndSettle();

      // Should be back at Root Home
      expect(find.byKey(const ValueKey('normal_mode_breadcrumb_bar')), findsNothing);
      expect(find.text('Default'), findsOneWidget);
    },
  );

  testWidgets(
    'Render Normal Mode Breadcrumb inside Animals matching user mockup reference',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      HomePage.initialCardsForTesting = createSampleHierarchy();

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

      // Enter 'Default' -> then 'Animals'
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Animals'));
      await tester.pumpAndSettle();

      final breadcrumbBar = find.byKey(const ValueKey('normal_mode_breadcrumb_bar'));
      expect(breadcrumbBar, findsOneWidget);

      // Capture screenshot artifact
      final boundary = repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();

        const artifactDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
        if (Directory(artifactDir).existsSync()) {
          File('$artifactDir/normal_mode_breadcrumb_rendered.png').writeAsBytesSync(bytes);
        }
      });
    },
  );

  testWidgets(
    'Normal Mode Breadcrumb: 4-level deep nesting with long labels scrolls without overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final leaf = AACCard(
        id: 'leaf_card',
        label: 'Golden Retriever Dog',
        colorValue: 0xFFDCEDC8,
      );
      final level3 = AACCard(
        id: 'f_level3',
        label: 'Domestic Mammals and Pets',
        type: 'folder',
        colorValue: 0xFF81C784,
        subCards: [leaf],
      );
      final level2 = AACCard(
        id: 'f_level2',
        label: 'Wild and Domestic Animals',
        type: 'folder',
        colorValue: 0xFF4DD0E1,
        subCards: [level3],
      );
      final level1 = AACCard(
        id: 'f_level1',
        label: 'Nature and Living Creatures',
        type: 'folder',
        colorValue: 0xFF1E88E5,
        subCards: [level2],
      );

      HomePage.initialCardsForTesting = [level1];

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate down all 3 levels
      await tester.tap(find.text('Nature and Living Creatures'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wild and Domestic Animals'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Domestic Mammals and Pets'));
      await tester.pumpAndSettle();

      expect(find.text('Golden Retriever Dog'), findsOneWidget);

      // Verify breadcrumb bar is present and all ancestor text widgets exist
      expect(find.byKey(const ValueKey('normal_mode_breadcrumb_bar')), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Nature and Living Creatures'), findsOneWidget);
      expect(find.text('Wild and Domestic Animals'), findsOneWidget);
      expect(find.text('Domestic Mammals and Pets'), findsNWidgets(2)); // Breadcrumb + AppBar

      // Direct tap on intermediate ancestor 'Nature and Living Creatures' jumps back 2 levels
      await tester.tap(find.text('Nature and Living Creatures'));
      await tester.pumpAndSettle();

      // Verify we are now back in Level 1
      expect(find.text('Wild and Domestic Animals'), findsOneWidget);
      expect(find.text('Golden Retriever Dog'), findsNothing);
    },
  );

  testWidgets(
    'Normal Mode Breadcrumb: functions smoothly in landscape orientation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2400, 1080);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      HomePage.initialCardsForTesting = createSampleHierarchy();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Open 'Default' folder in landscape
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();

      // Breadcrumb bar must be visible in landscape
      expect(find.byKey(const ValueKey('normal_mode_breadcrumb_bar')), findsOneWidget);
      expect(find.text('Animals'), findsOneWidget);

      // Tap 'Home' in breadcrumb
      await tester.tap(find.byKey(const ValueKey('normal_mode_breadcrumb_home')));
      await tester.pumpAndSettle();

      // Should be back at Root
      expect(find.byKey(const ValueKey('normal_mode_breadcrumb_bar')), findsNothing);
      expect(find.text('Default'), findsOneWidget);
    },
  );
}
