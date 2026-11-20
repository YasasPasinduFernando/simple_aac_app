import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';
import 'package:simple_aac_app/services/tutorial_service.dart';

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

Future<void> captureScreen(WidgetTester tester, GlobalKey key, String filename) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.runAsync(() async {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final pngBytes = byteData.buffer.asUint8List();
    
    final qaDir = Directory('docs/qa/three_visual_modes');
    if (!qaDir.existsSync()) {
      qaDir.createSync(recursive: true);
    }
    File('docs/qa/three_visual_modes/$filename').writeAsBytesSync(pngBytes);

    const artifactDirPath = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
    File('$artifactDirPath/$filename').writeAsBytesSync(pngBytes);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File userChairPhoto;
  late File userNewPhoto;

  setUpAll(() async {
    AudioplayersPlatformInterface.instance = _FakeAudioPlatform();
    tempDir = Directory.systemTemp.createTempSync('render_modes_');

    // Create realistic sample camera photo (warm bedroom colors)
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 600, 600), Paint()..color = const Color(0xFFD4A373));
    canvas.drawRect(const Rect.fromLTWH(50, 50, 500, 500), Paint()..color = const Color(0xFFCCD5AE));
    canvas.drawCircle(const Offset(300, 300), 120, Paint()..color = const Color(0xFFFAEDCD));
    final picture = recorder.endRecording();
    final img = await picture.toImage(600, 600);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    userChairPhoto = File('${tempDir.path}/chair_camera.png')..writeAsBytesSync(bytes);
    userNewPhoto = File('${tempDir.path}/new_camera.png')..writeAsBytesSync(bytes);
  });

  setUp(() {
    HomePage.skipSplashForTesting = true;
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.hapticPerformer = () async {};
  });

  tearDown(() {
    HomePage.skipSplashForTesting = false;
    HomePage.initialCardsForTesting = null;
  });

  List<AACCard> getCards() => [
    AACCard(id: 'custom_chair', label: 'Chair', imagePath: userChairPhoto.path, colorValue: 0xFFFDE466),
    AACCard(id: 'seed_happy', label: 'Happy', imagePath: 'assets/home/happy.webp', colorValue: 0xFFFDE16C),
    AACCard(id: 'seed_sad', label: 'Sad', imagePath: 'assets/home/sad.webp', colorValue: 0xFFA1D1F6),
    AACCard(id: 'seed_angry', label: 'Angry', imagePath: 'assets/home/angry.webp', colorValue: 0xFFF8A19F),
    AACCard(
      id: 'seed_more',
      label: 'More',
      imagePath: 'assets/images/seed_v2/more.webp',
      colorValue: 0xFF475CC5,
      type: 'folder',
      subCards: [AACCard(id: 'sub_1', label: 'Sub', colorValue: 0xFFFFFFFF)],
    ),
    AACCard(
      id: StarterPackService.starterPackRootId,
      label: 'Default',
      imagePath: 'assets/home/default_folder_cover.webp',
      colorValue: 0xFF0284C7,
      type: 'folder',
      subCards: [AACCard(id: 'sub_2', label: 'Child', colorValue: 0xFFFFFFFF)],
    ),
    AACCard(id: 'custom_new', label: 'New', imagePath: userNewPhoto.path, colorValue: 0xFF4FC3F7),
  ];

  testWidgets('Render Mode 1: Overlay ON (User Preferred: Full-bleed image, bottom label over image with subtle dark gradient, no solid footer)',
      (tester) async {
    tester.view.physicalSize = const ui.Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      'hasSeededDefaultCards': true,
      'isTutorialCompleted': true,
      'isBoardTutorialDismissed': true,
      TutorialService.prefCompleted: true,
      TutorialService.prefSkipped: true,
      'showCardLabels': true,
      'useImageOverlayLabel': true, // Overlay ON!
      'gridColumns': 2,
    });
    await NetworkPolicyService.instance.init();
    HomePage.initialCardsForTesting = getCards();

    final repaintKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: RepaintBoundary(key: repaintKey, child: const HomePage()),
    ));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify all cards have label overlaid
    for (final c in getCards()) {
      expect(find.text(c.label), findsOneWidget);
    }

    await captureScreen(tester, repaintKey, 'mode_1_overlay_on.png');
  });

  testWidgets('Render Mode 2: Overlay OFF (Separate footer below unclipped image)',
      (tester) async {
    tester.view.physicalSize = const ui.Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      'hasSeededDefaultCards': true,
      'isTutorialCompleted': true,
      'isBoardTutorialDismissed': true,
      TutorialService.prefCompleted: true,
      TutorialService.prefSkipped: true,
      'showCardLabels': true,
      'useImageOverlayLabel': false, // Overlay OFF!
      'gridColumns': 2,
    });
    await NetworkPolicyService.instance.init();
    HomePage.initialCardsForTesting = getCards();

    final repaintKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: RepaintBoundary(key: repaintKey, child: const HomePage()),
    ));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    for (final c in getCards()) {
      expect(find.text(c.label), findsOneWidget);
    }

    await captureScreen(tester, repaintKey, 'mode_2_overlay_off.png');
  });

  testWidgets('Render Mode 3: Image-Only (Show Card Labels OFF)',
      (tester) async {
    tester.view.physicalSize = const ui.Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      'hasSeededDefaultCards': true,
      'isTutorialCompleted': true,
      'isBoardTutorialDismissed': true,
      TutorialService.prefCompleted: true,
      TutorialService.prefSkipped: true,
      'showCardLabels': false, // Show Card Labels OFF!
      'useImageOverlayLabel': true,
      'gridColumns': 2,
    });
    await NetworkPolicyService.instance.init();
    HomePage.initialCardsForTesting = getCards();

    final repaintKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: RepaintBoundary(key: repaintKey, child: const HomePage()),
    ));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify zero labels visible
    for (final c in getCards()) {
      expect(find.text(c.label), findsNothing);
    }

    await captureScreen(tester, repaintKey, 'mode_3_image_only.png');
  });
}
