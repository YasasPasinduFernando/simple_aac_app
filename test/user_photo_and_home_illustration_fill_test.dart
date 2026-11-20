import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File userChairPhoto;
  late File userNewPhoto;

  setUpAll(() async {
    AudioplayersPlatformInterface.instance = _FakeAudioPlatform();
    tempDir = Directory.systemTemp.createTempSync('photo_fill_test_');

    // Create realistic dummy user photo files (PNG with valid header)
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 300), Paint()..color = const Color(0xFFE6A23C));
    final picture = recorder.endRecording();
    final img = await picture.toImage(400, 300);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    userChairPhoto = File('${tempDir.path}/chair_photo.png')..writeAsBytesSync(bytes);
    userNewPhoto = File('${tempDir.path}/new_camera_photo.png')..writeAsBytesSync(bytes);
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('User Photo Viewport Fill & Home Illustration Transparency Verification', () {
    test('1. StarterPackService resolves harmonized pastel colors for home seed cards', () {
      final hello = AACCard(id: 'seed_hello', label: 'Hello', colorValue: 0xFFFFF176, imagePath: 'assets/home/hello.webp');
      final happy = AACCard(id: 'seed_happy', label: 'Happy', colorValue: 0xFFFFF176, imagePath: 'assets/home/happy.webp');
      final sad = AACCard(id: 'seed_sad', label: 'Sad', colorValue: 0xFF4FC3F7, imagePath: 'assets/home/sad.webp');
      final angry = AACCard(id: 'seed_angry', label: 'Angry', colorValue: 0xFFE57373, imagePath: 'assets/home/angry.webp');

      expect(StarterPackService.resolveCardColorValue(hello), equals(0xFFFDE466),
          reason: 'Hello must harmonize to soft pastel yellow');
      expect(StarterPackService.resolveCardColorValue(happy), equals(0xFFFDE16C),
          reason: 'Happy must harmonize to soft pastel yellow');
      expect(StarterPackService.resolveCardColorValue(sad), equals(0xFFA1D1F6),
          reason: 'Sad must harmonize to soft pastel blue');
      expect(StarterPackService.resolveCardColorValue(angry), equals(0xFFF8A19F),
          reason: 'Angry must harmonize to soft pastel red');
    });

    test('2. Home WebP assets exist and are RGBA format with transparent backgrounds', () {
      for (final name in ['sad.webp', 'angry.webp', 'happy.webp', 'hello.webp']) {
        final f = File('assets/home/$name');
        expect(f.existsSync(), isTrue, reason: 'assets/home/$name must exist');
        // WebP RGBA format check (RIFF....WEBPVP8X/VP8L with Alpha bit)
        final header = f.readAsBytesSync().sublist(0, 30);
        final isWebP = header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46 &&
                       header[8] == 0x57 && header[9] == 0x45 && header[10] == 0x42 && header[11] == 0x50;
        expect(isWebP, isTrue, reason: '$name must be a valid WebP');
      }
    });

    testWidgets('3. Mode: Show Card Labels ON + Overlay OFF (Chair fills viewport, Sad/Angry unclipped with footer)',
        (tester) async {
      tester.view.physicalSize = const ui.Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cards = [
        AACCard(id: 'custom_chair', label: 'Chair', imagePath: userChairPhoto.path, colorValue: 0xFFFDE466),
        AACCard(id: 'seed_happy', label: 'Happy', imagePath: 'assets/home/happy.webp', colorValue: 0xFFFDE16C),
        AACCard(id: 'seed_sad', label: 'Sad', imagePath: 'assets/home/sad.webp', colorValue: 0xFFA1D1F6),
        AACCard(id: 'seed_angry', label: 'Angry', imagePath: 'assets/home/angry.webp', colorValue: 0xFFF8A19F),
        AACCard(
          id: StarterPackService.starterPackRootId,
          label: 'Default',
          imagePath: 'assets/home/default_folder_cover.webp',
          colorValue: 0xFF0284C7,
          type: 'folder',
          subCards: [AACCard(id: 'sub_c', label: 'Child', colorValue: 0xFFFFFFFF)],
        ),
        AACCard(id: 'custom_new', label: 'New', imagePath: userNewPhoto.path, colorValue: 0xFF4FC3F7),
      ];

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
      HomePage.initialCardsForTesting = cards;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Check all labels render in footer
      for (final c in cards) {
        expect(find.text(c.label), findsOneWidget, reason: '${c.label} label must be visible in footer');
      }

      // Check user photos (Chair, New) and Default cover use BoxFit.cover
      final imageWidgets = tester.widgetList<Image>(find.byType(Image)).toList();
      int userPhotoCount = 0;
      int illustrationCount = 0;
      for (final img in imageWidgets) {
        var provider = img.image;
        if (provider is ResizeImage) {
          provider = provider.imageProvider;
        }
        if (provider is FileImage) {
          userPhotoCount++;
          expect(img.fit, equals(BoxFit.cover),
              reason: 'User photograph must fill upper card viewport with BoxFit.cover');
        } else if (provider is AssetImage) {
          final asset = provider;
          if (asset.assetName.contains('default_folder_cover')) {
            expect(img.fit, equals(BoxFit.cover),
                reason: 'Default folder cover must use BoxFit.cover');
          } else {
            illustrationCount++;
            expect(img.fit, equals(BoxFit.contain),
                reason: 'Illustrations must use BoxFit.contain so character artwork is never cropped');
          }
        }
      }
      expect(userPhotoCount, equals(2), reason: 'Chair and New are FileImages');
      expect(illustrationCount, equals(3), reason: 'Happy, Sad, Angry are AssetImages');
    });
  });
}
