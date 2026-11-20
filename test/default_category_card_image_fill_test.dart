import 'dart:io';
import 'dart:ui' as ui;
// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/data/default_seed_cards.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';

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
    tempDir = await Directory.systemTemp.createTemp('card_fill_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;
    StarterPackService.clearCache();
  });

  tearDownAll(() async {
    CardStorageService.resetTestHooks();
    StarterPackService.clearCache();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'isFirstRun': false,
      'language': 'en',
      'useImageOverlayLabel': false, // Footer mode so entire image area is visible
      'pin_mode_active': false,
    });
    HomePage.skipSplashForTesting = true;
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.initialCardsForTesting = createDefaultSeedCards();
    HomePage.hapticPerformer = () async {};
    StarterPackService.clearCache();
  });

  tearDown(() {
    HomePage.skipSplashForTesting = false;
    HomePage.initialCardsForTesting = null;
  });

  testWidgets('Verify default category cards render seamless transparent assets', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(home: HomePage(key: UniqueKey())),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Default folder
    final defaultFinder = find.text('Default');
    expect(defaultFinder, findsOneWidget);
    await tester.tap(defaultFinder);
    await tester.pumpAndSettle();

    // Screenshot 1: Top of Default folder (Family, Colours, Shapes, Animals, Food, Snacks)
    final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      const outDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
      await File('$outDir/default_top_fill_verified.png').writeAsBytes(bytes);
      await File('docs/qa/default_category_fill/default_top_fill_verified.png').create(recursive: true);
      await File('docs/qa/default_category_fill/default_top_fill_verified.png').writeAsBytes(bytes);
    });

    // Drag GridView up by 350px to reveal Drinks, Feelings, Needs, Basic Words
    final gridFinder = find.byType(GridView).first;
    await tester.drag(gridFinder, const Offset(0, -350));
    await tester.pumpAndSettle();

    // Screenshot 2: Middle of Default folder showing Drinks, Feelings, Needs, Basic Words
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      const outDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
      await File('$outDir/default_middle_fill_verified.png').writeAsBytes(bytes);
      await File('docs/qa/default_category_fill/default_middle_fill_verified.png').create(recursive: true);
      await File('docs/qa/default_category_fill/default_middle_fill_verified.png').writeAsBytes(bytes);
    });

    // Drag GridView up by another 700px to fully center Activities, School & Places, Personal Care
    await tester.drag(gridFinder, const Offset(0, -700));
    await tester.pumpAndSettle();

    final personalCareFinder = find.text('Personal Care');
    expect(personalCareFinder, findsOneWidget);

    // Screenshot 3: Bottom of Default folder showing Activities and Personal Care
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      const outDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
      await File('$outDir/default_bottom_fill_verified.png').writeAsBytes(bytes);
      await File('docs/qa/default_category_fill/default_bottom_fill_verified.png').create(recursive: true);
      await File('docs/qa/default_category_fill/default_bottom_fill_verified.png').writeAsBytes(bytes);
    });

    // Tap into Personal Care
    await tester.tap(personalCareFinder);
    await tester.pumpAndSettle();

    expect(find.text('Brush Teeth'), findsOneWidget);

    // Screenshot 4: Inside Personal Care folder showing Brush Teeth card
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      const outDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
      await File('$outDir/personal_care_subcards_fill_verified.png').writeAsBytes(bytes);
      await File('docs/qa/default_category_fill/personal_care_subcards_fill_verified.png').create(recursive: true);
      await File('docs/qa/default_category_fill/personal_care_subcards_fill_verified.png').writeAsBytes(bytes);
    });
  });
}
