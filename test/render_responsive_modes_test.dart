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
    tempDir = await Directory.systemTemp.createTemp('render_modes_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    SharedPreferences.setMockInitialValues({'online_features_enabled': false});
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
      labelSinhala: 'ආයුබෝවන්',
      labelTamil: 'வணக்கம்',
      imagePath: 'assets/images/starter_pack_v8/feelings_happy.webp',
      colorValue: 0xFFFEE685,
    ),
    AACCard(
      id: 'c_water',
      label: 'Water',
      labelSinhala: 'වතුර',
      labelTamil: 'தண்ணீர்',
      imagePath: 'assets/images/starter_pack_v8/drinks_water.webp',
      colorValue: 0xFFB9DCFE,
    ),
    AACCard(
      id: 'c_eat',
      label: 'Eat',
      labelSinhala: 'කෑම',
      labelTamil: 'சாப்பாடு',
      imagePath: 'assets/images/starter_pack_v8/activities_eat.webp',
      colorValue: 0xFFBBF7D0,
    ),
    AACCard(
      id: 'c_sad',
      label: 'Sad',
      labelSinhala: 'දුකයි',
      labelTamil: 'வருத்தம்',
      imagePath: 'assets/images/starter_pack_v8/feelings_sad.webp',
      colorValue: 0xFFFFD1D1,
    ),
    AACCard(
      id: 'f_food',
      label: 'Food',
      type: 'folder',
      colorValue: 0xFFFEE685,
      subCards: [
        AACCard(
          id: 'sub_kottu',
          label: 'Kottu',
          imagePath: 'assets/images/starter_pack_v8/food_kottu.webp',
          colorValue: 0xFFFEE685,
        ),
      ],
    ),
    AACCard(
      id: 'c_play',
      label: 'Play',
      imagePath: 'assets/images/starter_pack_v8/activities_play.webp',
      colorValue: 0xFFE9D5FF,
    ),
  ];

  Future<void> saveScreenshot(WidgetTester tester, GlobalKey repaintKey, String filename) async {
    final boundary = repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final outDir = Directory('docs/qa/responsive_cards');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      File('docs/qa/responsive_cards/$filename').writeAsBytesSync(bytes);

      const artifactDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
      File('$artifactDir/$filename').writeAsBytesSync(bytes);
    });
  }

  testWidgets('Render Mode 01: Board with Text ON (Portrait 2-col)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      'useImageOverlayLabel': true,
      'gridColumns': 2,
    });
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
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
    await tester.pumpAndSettle();

    await saveScreenshot(tester, repaintKey, 'responsive_01_board_text_on.png');
  });

  testWidgets('Render Mode 02: Board with Text OFF (Portrait 2-col)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      'useImageOverlayLabel': false,
      'gridColumns': 2,
    });
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

    await saveScreenshot(tester, repaintKey, 'responsive_02_board_text_off.png');
  });

  testWidgets('Render Mode 03: Edit Words Mode with Text ON (Portrait 2-col)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      'useImageOverlayLabel': true,
      'gridColumns': 2,
    });
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

    // Enter Edit Mode
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable Edit Mode'));
    await tester.pumpAndSettle();

    await saveScreenshot(tester, repaintKey, 'responsive_03_edit_mode_text_on.png');
  });

  testWidgets('Render Mode 04: Edit Words Mode with Text OFF (Portrait 2-col)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      'useImageOverlayLabel': false,
      'gridColumns': 2,
    });
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

    // Enter Edit Mode
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable Edit Mode'));
    await tester.pumpAndSettle();

    await saveScreenshot(tester, repaintKey, 'responsive_04_edit_mode_text_off.png');
  });

  testWidgets('Render Mode 05: Speech Therapist Landscape Verification (4 Cards per row)', (tester) async {
    tester.view.physicalSize = const Size(2340, 1080);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      'useImageOverlayLabel': true,
      'gridColumns': 4,
    });
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

    await saveScreenshot(tester, repaintKey, 'responsive_05_landscape_4cols.png');
  });
}
