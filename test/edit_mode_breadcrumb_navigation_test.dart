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
    tempDir = await Directory.systemTemp.createTemp('breadcrumb_test_');
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

  testWidgets(
    'Edit Mode Breadcrumb Bar: displays interactive pill button and navigates back to Home on tap',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sampleCards = [
        AACCard(
          id: 'c_hello',
          label: 'Hello',
          colorValue: 0xFFFEE685,
        ),
        AACCard(
          id: 'f_more',
          label: 'More',
          type: 'folder',
          colorValue: 0xFF3F51B5,
          subCards: [
            AACCard(
              id: 'c_good',
              label: 'Good',
              colorValue: 0xFF81C784,
            ),
            AACCard(
              id: 'c_play',
              label: 'Play',
              colorValue: 0xFFFFB74D,
            ),
          ],
        ),
      ];

      HomePage.initialCardsForTesting = List.of(sampleCards);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Edit Words Mode via Drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      // In Edit Mode, tap on 'More' folder card to navigate inside it
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // Verify we are now inside 'More'
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);

      // Verify the breadcrumb pill button is visible
      final breadcrumbBack = find.byKey(const ValueKey('edit_mode_breadcrumb_back'));
      expect(breadcrumbBack, findsOneWidget);
      expect(find.text('Drop card to move up'), findsOneWidget);
      expect(find.descendant(of: breadcrumbBack, matching: find.byIcon(Icons.arrow_back_rounded)), findsOneWidget);

      // Tap on the breadcrumb back button
      await tester.tap(breadcrumbBack);
      await tester.pumpAndSettle();

      // Verify we have navigated back to Home (root level)
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    },
  );

  testWidgets(
    'Edit Mode Breadcrumb Bar: nested folder direct Home tap jumps to root',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final leaf = AACCard(
        id: 'leaf_water',
        label: 'Water',
        colorValue: 0xFF29B6F6,
      );
      final childFolder = AACCard(
        id: 'folder_drinks',
        label: 'Drinks',
        colorValue: 0xFF4DD0E1,
        type: 'folder',
        subCards: [leaf],
      );
      final rootFolder = AACCard(
        id: 'folder_root',
        label: 'Default',
        colorValue: 0xFF1E88E5,
        type: 'folder',
        subCards: [childFolder],
      );

      HomePage.initialCardsForTesting = [rootFolder];

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Edit Words Mode via Drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      // Enter 'Default'
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();

      // Enter 'Drinks'
      await tester.tap(find.text('Drinks'));
      await tester.pumpAndSettle();
      expect(find.text('Water'), findsOneWidget);

      // Direct tap on 'Home' text inside breadcrumb
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Verify direct jump to root Home
      expect(find.text('Default'), findsOneWidget);
    },
  );

  testWidgets(
    'Render Edit Mode Breadcrumb Pill inside More folder matching user reference',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sampleCards = [
        AACCard(
          id: 'c_hello',
          label: 'Hello',
          colorValue: 0xFFFEE685,
        ),
        AACCard(
          id: 'f_more',
          label: 'More',
          type: 'folder',
          colorValue: 0xFF3F51B5,
          subCards: [
            AACCard(
              id: 'c_good',
              label: 'Good',
              imagePath: 'assets/images/starter_pack_v8/feelings_happy.webp',
              colorValue: 0xFF81C784,
            ),
            AACCard(
              id: 'c_play',
              label: 'Play',
              imagePath: 'assets/images/starter_pack_v8/activities_play.webp',
              colorValue: 0xFFFFB74D,
            ),
          ],
        ),
      ];

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

      // Enter Edit Words Mode
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      // Enter 'More' folder
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // Save screenshot
      final boundary = repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final img = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();

        const artifactDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
        File('$artifactDir/edit_mode_breadcrumb_pill_rendered.png').writeAsBytesSync(bytes);
      });
    },
  );
}
