import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_aac_app/data/default_seed_cards.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';
import 'package:simple_aac_app/utils/image_crop_helper.dart';

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

  setUp(() async {
    AudioplayersPlatformInterface.instance = _FakeAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('home_cards_reg_test_');
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
    StarterPackService.clearCache();
    await NetworkPolicyService.instance.init();
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.skipSplashForTesting = true;
    HomePage.initialCardsForTesting = null;
  });

  tearDown(() async {
    CardStorageService.resetTestHooks();
    HomePage.initialCardsForTesting = null;
    HomePage.skipSplashForTesting = false;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Requirement 1 & 2: Original Home Card Mapping and Separation', () {
    test('createDefaultSeedCards maps Home cards to stickman v2 WebPs', () {
      final seeds = createDefaultSeedCards();
      final hello = seeds.firstWhere((c) => c.id == 'seed_hello');
      final happy = seeds.firstWhere((c) => c.id == 'seed_happy');
      final sad = seeds.firstWhere((c) => c.id == 'seed_sad');
      final angry = seeds.firstWhere((c) => c.id == 'seed_angry');
      final more = seeds.firstWhere((c) => c.id == 'seed_more');

      expect(hello.imagePath, equals('assets/home/hello.webp'));
      expect(happy.imagePath, equals('assets/home/happy.webp'));
      expect(sad.imagePath, equals('assets/home/sad.webp'));
      expect(angry.imagePath, equals('assets/home/angry.webp'));
      expect(more.imagePath, equals('assets/images/seed_v2/more.webp'));

      expect(more.subCards.length, equals(8));
      final good = more.subCards.firstWhere((c) => c.id == 'seed_good');
      final play = more.subCards.firstWhere((c) => c.id == 'seed_play');
      final yes = more.subCards.firstWhere((c) => c.id == 'seed_yes');
      final no = more.subCards.firstWhere((c) => c.id == 'seed_no');
      final please = more.subCards.firstWhere((c) => c.id == 'seed_please');
      final thankYou = more.subCards.firstWhere((c) => c.id == 'seed_thank_you');
      final help = more.subCards.firstWhere((c) => c.id == 'seed_help');
      final stop = more.subCards.firstWhere((c) => c.id == 'seed_stop');

      expect(good.imagePath, equals('assets/images/seed_v2/good.webp'));
      expect(play.imagePath, equals('assets/images/seed_v2/play.webp'));
      expect(yes.imagePath, equals('assets/images/seed_v2/yes.webp'));
      expect(no.imagePath, equals('assets/images/seed_v2/no.webp'));
      expect(please.imagePath, equals('assets/images/seed_v2/please.webp'));
      expect(thankYou.imagePath, equals('assets/images/seed_v2/thank_you.webp'));
      expect(help.imagePath, equals('assets/images/seed_v2/help.webp'));
      expect(stop.imagePath, equals('assets/images/seed_v2/stop.webp'));
    });

    test('Starter pack root clone remains isolated in Default folder', () {
      final seeds = createDefaultSeedCards();
      final defaultFolder = seeds.firstWhere((c) => c.id == StarterPackService.starterPackRootId);

      expect(defaultFolder.label, equals('Default'));
      expect(defaultFolder.imagePath, equals('assets/images/starter_pack_v8/starter_default.webp'));
      expect(defaultFolder.subCards.length, equals(13));
      // None of the Starter Pack category IDs should match any Home seed card ID
      final homeIds = seeds.where((c) => c.id != StarterPackService.starterPackRootId).map((c) => c.id).toSet();
      for (final cat in defaultFolder.subCards) {
        expect(homeIds.contains(cat.id), isFalse);
      }
    });
  });

  group('Requirement 3 & 9: Migration and Preservation of User Edits', () {
    test('Mistaken Starter Pack paths on Home cards restore to seed PNGs, preserving custom edits', () async {
      final userCustomPhoto = '${tempDir.path}/custom_photo.jpg';
      await File(userCustomPhoto).writeAsBytes([1, 2, 3]);

      final initialCards = [
        AACCard(
          id: 'seed_hello',
          label: 'Hello',
          imagePath: 'assets/images/starter_pack_v8/basic_words_hello.webp', // mistaken
          colorValue: Colors.yellow.shade300.value,
        ),
        AACCard(
          id: 'seed_happy',
          label: 'My Custom Happy',
          imagePath: userCustomPhoto, // deliberate user custom photo
          colorValue: Colors.lightBlue.shade200.value,
        ),
      ];

      await CardStorageService.saveCards(initialCards);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeededDefaultCards', true);
      await prefs.setInt('seededDefaultCardsVersion', 7); // Previous regression version

      final loaded = await CardStorageService.loadCards(
        defaultCardsBuilder: createDefaultSeedCards,
      );

      final hello = loaded.firstWhere((c) => c.id == 'seed_hello');
      final happy = loaded.firstWhere((c) => c.id == 'seed_happy');

      expect(hello.imagePath, equals('assets/home/hello.webp'),
          reason: 'Mistakenly migrated seed card should restore to child WebP');
      expect(happy.imagePath, equals(userCustomPhoto),
          reason: 'Custom user photo on seed card must NEVER be overwritten');
      expect(happy.label, equals('My Custom Happy'),
          reason: 'Custom user label must NEVER be overwritten');

      // Subsequent reload is idempotent
      final reloaded = await CardStorageService.loadCards(
        defaultCardsBuilder: createDefaultSeedCards,
      );
      expect(reloaded.firstWhere((c) => c.id == 'seed_hello').imagePath,
          equals('assets/home/hello.webp'));
    });
  });

  group('Requirement 8: No Black Artifacts on Transparent Crops', () {
    test('ImageCropHelper composites transparent alpha onto white, preventing black rectangles', () async {
      // Create a transparent 100x100 RGBA image
      final transparentImg = img.Image(width: 100, height: 100, numChannels: 4);
      img.fill(transparentImg, color: img.ColorRgba8(0, 0, 0, 0));
      // Draw a solid circle in the center
      img.fillCircle(transparentImg, x: 50, y: 50, radius: 30, color: img.ColorRgba8(255, 0, 0, 255));

      final testWebp = '${tempDir.path}/test_circle.webp';
      final encodedWebp = img.encodePng(transparentImg); // Use png bytes with webp name
      await File(testWebp).writeAsBytes(encodedWebp);

      final croppedFile = await ImageCropHelper.cropNormalized(
        sourcePath: testWebp,
        normLeft: 0.1,
        normTop: 0.1,
        normWidth: 0.8,
        normHeight: 0.8,
        isSquare: true,
      );

      expect(await croppedFile.exists(), isTrue);

      final croppedBytes = await croppedFile.readAsBytes();
      final decodedCrop = img.decodeImage(croppedBytes)!;

      // The corner pixel (0,0) was transparent in the source.
      // In the output JPEG, it must be WHITE (255, 255, 255) rather than solid black (0, 0, 0)!
      final cornerPixel = decodedCrop.getPixel(0, 0);
      expect(cornerPixel.r, greaterThan(230), reason: 'Transparent area must be white, not black');
      expect(cornerPixel.g, greaterThan(230), reason: 'Transparent area must be white, not black');
      expect(cornerPixel.b, greaterThan(230), reason: 'Transparent area must be white, not black');
    });
  });

  group('Requirement 6 & 7: User Photograph Full-Bleed vs Built-in Cards', () {
    testWidgets('User photo renders with BoxFit.cover and gradient, while asset illustration renders with BoxFit.contain', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final userPhoto = '${tempDir.path}/user_camera_shot.jpg';
      final pngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);
      File(userPhoto).writeAsBytesSync(pngBytes);

      final testCards = [
        AACCard(
          id: 'user_card_1',
          label: 'My Cat',
          imagePath: userPhoto,
          colorValue: Colors.blue.value,
        ),
        AACCard(
          id: 'seed_hello',
          label: 'Hello',
          imagePath: 'assets/images/seed/hello.png',
          colorValue: Colors.yellow.shade300.value,
        ),
      ];

      HomePage.initialCardsForTesting = testCards;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final userCardFinder = find.byKey(const ValueKey('user_card_1'));
      expect(userCardFinder, findsOneWidget);

      final userImgFinder = find.descendant(
        of: userCardFinder,
        matching: find.byType(Image),
      );
      expect(userImgFinder, findsOneWidget);
      final userImg = tester.widget<Image>(userImgFinder);
      expect(userImg.fit, equals(BoxFit.cover), reason: 'User photograph must render full-bleed with BoxFit.cover');

      final seedCardFinder = find.byKey(const ValueKey('seed_hello'));
      expect(seedCardFinder, findsOneWidget);

      final seedImgFinder = find.descendant(
        of: seedCardFinder,
        matching: find.byType(Image),
      );
      expect(seedImgFinder, findsOneWidget);
      final seedImg = tester.widget<Image>(seedImgFinder);
      expect(seedImg.fit, equals(BoxFit.contain), reason: 'Asset illustration must render with BoxFit.contain to prevent cropping');
    });
  });

  group('Requirement 10: Backup and Restore Verification', () {
    test('Backup round-trip preserves restored images and seed cards', () async {
      final seeds = createDefaultSeedCards();
      await CardStorageService.saveCards(seeds);

      final zipBytes = await BackupService.buildBackupZip(seeds);
      expect(zipBytes != null && zipBytes.isNotEmpty, isTrue);

      final payload = await BackupService.restoreFromZipBytes(zipBytes!);
      final restoredCards = payload.cards;

      final restoredHello = restoredCards.firstWhere((c) => c.id == 'seed_hello');
      expect(restoredHello.imagePath, equals('assets/home/hello.webp'));

      final restoredDefault = restoredCards.firstWhere((c) => c.id == StarterPackService.starterPackRootId);
      expect(restoredDefault.imagePath, equals('assets/images/starter_pack_v8/starter_default.webp'));
    });
  });

  group('Requirement 11: Visual Screenshot Artifact Generation', () {
    testWidgets('Renders Home, More folder, and Default folder visual evidence', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final defaultSeeds = createDefaultSeedCards();
      HomePage.initialCardsForTesting = defaultSeeds;

      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: repaintKey,
            child: const HomePage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Precache Home cards
      await tester.runAsync(() async {
        final ctx = repaintKey.currentContext!;
        await precacheImage(const AssetImage('assets/home/hello.webp'), ctx);
        await precacheImage(const AssetImage('assets/home/happy.webp'), ctx);
        await precacheImage(const AssetImage('assets/home/sad.webp'), ctx);
        await precacheImage(const AssetImage('assets/home/angry.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/seed_v2/more.webp'), ctx);
        await precacheImage(const AssetImage('assets/home/default_folder_cover.webp'), ctx);
      });
      await tester.pump(const Duration(milliseconds: 200));

      Future<void> saveShot(String filename) async {
        final boundary = repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final imgData = await boundary.toImage(pixelRatio: 2.0);
          final byteData = await imgData.toByteData(format: ui.ImageByteFormat.png);
          final bytes = byteData!.buffer.asUint8List();

          const artifactDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
          File('$artifactDir/$filename').writeAsBytesSync(bytes);

          final outDir = Directory('docs/qa/home_cards_presentation');
          if (!outDir.existsSync()) {
            outDir.createSync(recursive: true);
          }
          File('docs/qa/home_cards_presentation/$filename').writeAsBytesSync(bytes);
        });
      }

      // 1. Capture Home Screen
      await saveShot('home_board_stick_figures_restored.png');

      // 2. Open "More" folder
      final moreFinder = find.text('More');
      expect(moreFinder, findsOneWidget);
      await tester.tap(moreFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.runAsync(() async {
        final ctx = repaintKey.currentContext!;
        await precacheImage(const AssetImage('assets/images/seed_v2/good.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/seed_v2/play.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/seed_v2/yes.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/seed_v2/no.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/seed_v2/please.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/seed_v2/thank_you.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/seed_v2/help.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/seed_v2/stop.webp'), ctx);
      });
      await tester.pump(const Duration(milliseconds: 200));

      // Capture More folder (Good and Play stick figures)
      await saveShot('more_folder_stick_figures_restored.png');

      // 3. Return to Home
      final backFinder = find.byIcon(Icons.arrow_back_rounded).first;
      await tester.tap(backFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 4. Open "Default" folder
      final defaultFinder = find.text('Default');
      expect(defaultFinder, findsOneWidget);
      await tester.tap(defaultFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.runAsync(() async {
        final ctx = repaintKey.currentContext!;
        await precacheImage(const AssetImage('assets/images/starter_pack_v8/family_people.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/starter_pack_v8/starter_colours.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/starter_pack_v8/starter_shapes.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/starter_pack_v8/animals_dog.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/starter_pack_v8/food_food.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/starter_pack_v8/snacks_cookies.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/starter_pack_v8/drinks_water.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/starter_pack_v8/feelings_happy.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/starter_pack_v8/needs_needs.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/starter_pack_v8/basic_words_more.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/starter_pack_v8/activities_play.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/starter_pack_v8/school_places_school.webp'), ctx);
        await precacheImage(const AssetImage('assets/images/starter_pack_v8/personal_care_brush_teeth.webp'), ctx);
      });
      await tester.pump(const Duration(milliseconds: 200));

      // Capture Default folder (Drinks, Activities, Personal Care, Family, etc.)
      await saveShot('default_folder_harmonized_cards.png');
    });
  });
}
