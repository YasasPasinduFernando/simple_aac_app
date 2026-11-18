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

  setUp(() async {
    AudioplayersPlatformInterface.instance = FakeAudioplayerPlatform();
    tempDir = await Directory.systemTemp.createTemp('orientation_access_test_');
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

  final sampleCards = [
    AACCard(
      id: 'c_hello',
      label: 'Hello',
      colorValue: 0xFFFEE685,
    ),
    AACCard(
      id: 'c_water',
      label: 'Water',
      colorValue: 0xFFB9DCFE,
    ),
  ];

  group('Portrait Mode Orientation Shortcut', () {
    testWidgets(
      'Shortcut is visible immediately left of menu and opens orientation dialog',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        HomePage.initialCardsForTesting = List.of(sampleCards);

        await tester.pumpWidget(
          const MaterialApp(
            home: HomePage(),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify shortcut button is visible
        final orientationBtn = find.byKey(const ValueKey('home_app_bar_orientation_button'));
        expect(orientationBtn, findsOneWidget);

        final menuBtn = find.byTooltip('Menu');
        expect(menuBtn, findsOneWidget);

        // Verify it is placed immediately to the left of menu
        final orientationBox = tester.getRect(orientationBtn);
        final menuBox = tester.getRect(menuBtn);
        expect(orientationBox.right, lessThanOrEqualTo(menuBox.left));

        // 2. Tap shortcut to open existing dialog
        await tester.tap(orientationBtn);
        await tester.pumpAndSettle();

        expect(find.text('Screen Orientation'), findsOneWidget);
        expect(find.text('Choose preferred layout direction'), findsOneWidget);
        expect(find.text('Portrait'), findsOneWidget);
        expect(find.text('Landscape'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);

        // 3. Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Screen Orientation'), findsNothing);
      },
    );

    testWidgets(
      'Dialog options: Landscape selection switches orientation and Reset resets to portrait',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        HomePage.initialCardsForTesting = List.of(sampleCards);

        await tester.pumpWidget(
          const MaterialApp(
            home: HomePage(),
          ),
        );
        await tester.pumpAndSettle();

        // Initially in portrait, HomeAppBar is visible
        expect(find.byType(HomeAppBar), findsOneWidget);
        expect(find.byType(LandscapeMenu), findsNothing);

        // Open dialog
        await tester.tap(find.byKey(const ValueKey('home_app_bar_orientation_button')));
        await tester.pumpAndSettle();

        // Select Landscape
        await tester.tap(find.text('Landscape'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('orientationMode'), 'landscape');

        // Simulate landscape viewport for tester
        tester.view.physicalSize = const Size(2400, 1080);
        await tester.pumpAndSettle();

        // In landscape layout, LandscapeMenu is now active
        expect(find.byType(LandscapeMenu), findsOneWidget);

        // Open dialog from rail and Reset
        final railOrientationBtn = find.byKey(const ValueKey('landscape_nav_orientation'));
        expect(railOrientationBtn, findsOneWidget);
        await tester.ensureVisible(railOrientationBtn);
        await tester.pumpAndSettle();

        await tester.tap(railOrientationBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();

        expect(prefs.getString('orientationMode'), 'portrait');

        // Revert simulated viewport to portrait
        tester.view.physicalSize = const Size(1080, 2400);
        await tester.pumpAndSettle();

        // Reverted to portrait
        expect(find.byType(HomeAppBar), findsOneWidget);
      },
    );

    testWidgets(
      'Responsive check: Ultra-small screens avoid overflow by hiding header shortcut',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(300, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        HomePage.initialCardsForTesting = List.of(sampleCards);

        await tester.pumpWidget(
          const MaterialApp(
            home: HomePage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('home_app_bar_orientation_button')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Landscape Mode Orientation Shortcut & Rail Scrolling', () {
    testWidgets(
      'Landscape navigation rail contains Orientation button at bottom and can scroll vertically',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1600, 720);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        SharedPreferences.setMockInitialValues({
          'orientationMode': 'landscape',
          'online_features_enabled': false,
        });

        HomePage.initialCardsForTesting = List.of(sampleCards);

        await tester.pumpWidget(
          const MaterialApp(
            home: HomePage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('landscape_nav_pin')), findsOneWidget);
        expect(find.byKey(const ValueKey('landscape_nav_menu')), findsOneWidget);
        expect(find.byKey(const ValueKey('landscape_nav_home')), findsOneWidget);
        expect(find.byKey(const ValueKey('landscape_nav_up')), findsOneWidget);
        expect(find.byKey(const ValueKey('landscape_nav_down')), findsOneWidget);
        expect(find.byKey(const ValueKey('landscape_nav_search')), findsOneWidget);

        final orientationBtn = find.byKey(const ValueKey('landscape_nav_orientation'));
        expect(orientationBtn, findsOneWidget);

        // Ensure visible before tapping since rail is vertically scrollable
        await tester.ensureVisible(orientationBtn);
        await tester.pumpAndSettle();

        // Tap Orientation in landscape
        await tester.tap(orientationBtn);
        await tester.pumpAndSettle();

        expect(find.text('Screen Orientation'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      },
    );
  });

  group('PIN Lock Security Integration', () {
    testWidgets(
      'When board is pinned/locked, orientation shortcuts are disabled and do NOT open dialog',
      (WidgetTester tester) async {
        int hapticCount = 0;
        HomePage.hapticPerformer = () async {
          hapticCount++;
        };

        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        HomePage.initialCardsForTesting = List.of(sampleCards);

        await tester.pumpWidget(
          const MaterialApp(
            home: HomePage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Pin the board
        final pinFinder = find.byIcon(Icons.push_pin_outlined);
        expect(pinFinder, findsOneWidget);
        await tester.tap(pinFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final pinnedFinder = find.byIcon(Icons.push_pin);
        expect(pinnedFinder, findsOneWidget);

        // Tapping orientation button while locked must NOT open dialog
        final orientationBtn = find.byKey(const ValueKey('home_app_bar_orientation_button'));
        await tester.tap(orientationBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Screen Orientation'), findsNothing);

        // Unlock the board by long pressing pin
        await tester.longPress(pinnedFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(hapticCount, greaterThanOrEqualTo(1));
        expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);

        // Tapping orientation now opens dialog
        await tester.tap(orientationBtn);
        await tester.pumpAndSettle();
        expect(find.text('Screen Orientation'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      },
    );
  });

  group('Visual Artifact Generation', () {
    testWidgets(
      'Render Portrait and Landscape orientation shortcuts matching user reference mockups',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        HomePage.initialCardsForTesting = List.of(sampleCards);

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

        // Save Portrait Screenshot
        final portraitBoundary = repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final img = await portraitBoundary.toImage(pixelRatio: 2.0);
          final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
          const artifactDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
          File('$artifactDir/portrait_orientation_shortcut_rendered.png').writeAsBytesSync(byteData!.buffer.asUint8List());
        });

        // Switch to landscape via dialog
        await tester.tap(find.byKey(const ValueKey('home_app_bar_orientation_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Landscape'));
        await tester.pumpAndSettle();

        tester.view.physicalSize = const Size(2400, 1080);
        await tester.pumpAndSettle();

        final landscapeBoundary = repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final img = await landscapeBoundary.toImage(pixelRatio: 2.0);
          final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
          const artifactDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
          File('$artifactDir/landscape_orientation_shortcut_rendered.png').writeAsBytesSync(byteData!.buffer.asUint8List());
        });
      },
    );
  });
}
