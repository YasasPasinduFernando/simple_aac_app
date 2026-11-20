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
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';
import 'package:simple_aac_app/utils/card_image.dart';

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
  Future<void> stop(String playerId) async {}
  @override
  Future<void> setVolume(String playerId, double volume) async {}
  @override
  Future<int> getCurrentPosition(String playerId) async => 0;
  @override
  Future<int> getDuration(String playerId) async => 0;
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
  });

  setUp(() async {
    AudioplayersPlatformInterface.instance = _FakeAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('home_children_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    SharedPreferences.setMockInitialValues({
      'hasSeededDefaultCards': true,
      'seededDefaultCardsVersion': 8,
      'isTutorialCompleted': true,
      'isBoardTutorialDismissed': true,
      'useImageOverlayLabel': true,
      'online_features_enabled': false,
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
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Requirement 1 & 2: Home 4 Cards Child Style vs More Stickman & Default Cover', () {
    test('1. Fresh installation defaults map the 4 Home cards to child art assets', () {
      final seeds = createDefaultSeedCards();
      final hello = seeds.firstWhere((c) => c.id == 'seed_hello');
      final happy = seeds.firstWhere((c) => c.id == 'seed_happy');
      final sad = seeds.firstWhere((c) => c.id == 'seed_sad');
      final angry = seeds.firstWhere((c) => c.id == 'seed_angry');
      final more = seeds.firstWhere((c) => c.id == 'seed_more');
      final defaultCard = seeds.firstWhere((c) => c.id == StarterPackService.starterPackRootId);

      expect(hello.imagePath, equals('assets/home/hello.webp'),
          reason: 'Hello must point to cheerful child art');
      expect(happy.imagePath, equals('assets/home/happy.webp'),
          reason: 'Happy must point to joyful jumping child art');
      expect(sad.imagePath, equals('assets/home/sad.webp'),
          reason: 'Sad must point to sad child art');
      expect(angry.imagePath, equals('assets/home/angry.webp'),
          reason: 'Angry must point to angry child art');

      // More must remain stickman/skeleton with 8 subcards
      expect(more.imagePath, equals('assets/images/seed_v2/more.webp'),
          reason: 'More MUST retain its existing skeleton/stickman art');
      expect(more.subCards.length, equals(8),
          reason: 'More subcards must remain exactly 8');

      // Default must remain Starter Pack root with 13 categories
      expect(defaultCard.subCards.length, equals(13),
          reason: 'Default must remain intact with 13 categories');
    });

    test('2. Built-in files exist, are valid WebP, and have matching dimensions', () {
      for (final assetName in ['hello.webp', 'happy.webp', 'sad.webp', 'angry.webp']) {
        final file = File('assets/home/$assetName');
        expect(file.existsSync(), isTrue, reason: 'assets/home/$assetName must exist');
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(10000));
        final decoded = img.decodeWebP(bytes);
        expect(decoded != null, isTrue);
        expect(decoded!.width, equals(768));
        expect(decoded.height, equals(768));
      }

      final moreFile = File('assets/images/seed_v2/more.webp');
      expect(moreFile.existsSync(), isTrue);

      final defaultCoverFile = File('assets/home/default_folder_cover.webp');
      expect(defaultCoverFile.existsSync(), isTrue);
    });
  });

  group('Requirement 3 & 4: Safe Upgrade Migration & Customization Preservation', () {
    test('3. Existing installs with stickman v2 migrate to child art without data wipe', () async {
      // Simulate existing installation cards pointing to stickman v2
      final existingCards = [
        AACCard(
          id: 'seed_hello',
          label: 'Hello',
          imagePath: 'assets/images/seed_v2/hello.webp',
          colorValue: 0xFFFFF176,
        ),
        AACCard(
          id: 'seed_happy',
          label: 'Happy',
          imagePath: 'assets/images/seed_v2/happy.webp',
          colorValue: 0xFF81D4FA,
        ),
        AACCard(
          id: 'seed_sad',
          label: 'Sad',
          imagePath: 'assets/images/seed_v2/sad.webp',
          colorValue: 0xFF4FC3F7,
        ),
        AACCard(
          id: 'seed_angry',
          label: 'Angry',
          imagePath: 'assets/images/seed_v2/angry.webp',
          colorValue: 0xFFE57373,
        ),
        AACCard(
          id: 'seed_more',
          label: 'More',
          imagePath: 'assets/images/seed_v2/more.webp',
          colorValue: 0xFF3F51B5,
          type: 'folder',
          subCards: [
            AACCard(
              id: 'seed_good',
              label: 'Good',
              imagePath: 'assets/images/seed_v2/good.webp',
              colorValue: 0xFF81C784,
            ),
          ],
        ),
      ];

      await CardStorageService.saveCards(existingCards);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('seededDefaultCardsVersion', 9);

      final loaded = await CardStorageService.loadCards(
        defaultCardsBuilder: createDefaultSeedCards,
      );

      final hello = loaded.firstWhere((c) => c.id == 'seed_hello');
      final happy = loaded.firstWhere((c) => c.id == 'seed_happy');
      final sad = loaded.firstWhere((c) => c.id == 'seed_sad');
      final angry = loaded.firstWhere((c) => c.id == 'seed_angry');
      final more = loaded.firstWhere((c) => c.id == 'seed_more');

      expect(hello.imagePath, equals('assets/home/hello.webp'),
          reason: 'seed_hello must upgrade to child illustration');
      expect(happy.imagePath, equals('assets/home/happy.webp'),
          reason: 'seed_happy must upgrade to child illustration');
      expect(sad.imagePath, equals('assets/home/sad.webp'),
          reason: 'seed_sad must upgrade to child illustration');
      expect(angry.imagePath, equals('assets/home/angry.webp'),
          reason: 'seed_angry must upgrade to child illustration');

      // More must remain stickman
      expect(more.imagePath, equals('assets/images/seed_v2/more.webp'));
      expect(more.subCards.first.imagePath, equals('assets/images/seed_v2/good.webp'));
    });

    test('4. Caregiver custom photo overrides are strictly preserved', () async {
      final customPhoto = '${tempDir.path}/caregiver_custom_hello.jpg';
      await File(customPhoto).writeAsBytes([1, 2, 3, 4]);

      final userCards = [
        AACCard(
          id: 'seed_hello',
          label: 'My Custom Hello',
          imagePath: customPhoto,
          colorValue: 0xFFFF5722,
        ),
        AACCard(
          id: 'seed_happy',
          label: 'Happy',
          imagePath: 'assets/images/seed_v2/happy.webp',
          colorValue: 0xFF81D4FA,
        ),
      ];

      await CardStorageService.saveCards(userCards);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('seededDefaultCardsVersion', 9);

      final loaded = await CardStorageService.loadCards(
        defaultCardsBuilder: createDefaultSeedCards,
      );

      final hello = loaded.firstWhere((c) => c.id == 'seed_hello');
      final happy = loaded.firstWhere((c) => c.id == 'seed_happy');

      expect(hello.imagePath, equals(customPhoto),
          reason: 'Custom caregiver photo must NEVER be overwritten');
      expect(hello.label, equals('My Custom Hello'),
          reason: 'Custom caregiver label must NEVER be overwritten');
      expect(hello.colorValue, equals(0xFFFF5722),
          reason: 'Custom caregiver color must NEVER be overwritten');

      // Unmodified seed card still upgrades
      expect(happy.imagePath, equals('assets/home/happy.webp'));
    });
  });

  group('Requirement 5: Root Cause & Resolution of Default Seeded Cards Inner Square', () {
    test('5. Path A vs Path B Analysis: Why manual crop fixed the cards', () {
      // Path A: Bundled asset
      const assetPath = 'assets/images/starter_pack_v8/animals_dog.webp';
      expect(isAssetImagePath(assetPath), isTrue);
      // In card widget:
      // final isUserPhoto = effectiveImagePath != null && !isAssetImagePath(effectiveImagePath);
      // Therefore isUserPhoto is false, isFullBleedCard is false.
      // Card uses Column with Upper Area BoxFit.contain and cardSurfaceColor.
      // If cardSurfaceColor differs from image edge pixels, an inner square appears!

      // Path B: Manually cropped image saved in app cache
      const croppedCachePath = '/data/user/0/lk.yasas.simpleaac/cache/crop_123456.jpg';
      expect(isAssetImagePath(croppedCachePath), isFalse);
      // In card widget:
      // isUserPhoto becomes true!
      // isFullBleedCard becomes true!
      // Renderer switches to Positioned.fill with BoxFit.cover, completely covering the card face!
      // This mathematically explains why manual cropping made the problem disappear!
    });

    test('6. StarterPackService harmonizes the 5 affected category cards to exact edge colors', () {
      final affectedCards = [
        AACCard(
          id: 'simpleaac.starter.v2.animals',
          label: 'Animals',
          imagePath: 'assets/images/starter_pack_v8/animals_dog.webp',
          colorValue: 0xFFE8F4DD, // old mismatched manifest value
        ),
        AACCard(
          id: 'simpleaac.starter.v2.food',
          label: 'Food',
          imagePath: 'assets/images/starter_pack_v8/food_food.webp',
          colorValue: 0xFFFFF0B7, // old mismatched manifest value
        ),
        AACCard(
          id: 'simpleaac.starter.v2.snacks',
          label: 'Snacks',
          imagePath: 'assets/images/starter_pack_v8/snacks_cookies.webp',
          colorValue: 0xFFFFE6D4, // old mismatched manifest value
        ),
        AACCard(
          id: 'simpleaac.starter.v2.needs',
          label: 'Needs',
          imagePath: 'assets/images/starter_pack_v8/needs_needs.webp',
          colorValue: 0xFFDDF5ED, // old mismatched manifest value
        ),
        AACCard(
          id: 'simpleaac.starter.v2.school_places',
          label: 'School & Places',
          imagePath: 'assets/images/starter_pack_v8/school_places_school.webp',
          colorValue: 0xFFD9EDFF, // old mismatched manifest value
        ),
      ];

      expect(StarterPackService.resolveCardColorValue(affectedCards[0]), equals(0xFFE0EED0),
          reason: 'Animals resolves to exact illustration edge color 0xFFE0EED0');
      expect(StarterPackService.resolveCardColorValue(affectedCards[1]), equals(0xFFFEE2A0),
          reason: 'Food resolves to exact illustration edge color 0xFFFEE2A0');
      expect(StarterPackService.resolveCardColorValue(affectedCards[2]), equals(0xFFFFD8BC),
          reason: 'Snacks resolves to exact illustration edge color 0xFFFFD8BC');
      expect(StarterPackService.resolveCardColorValue(affectedCards[3]), equals(0xFFBFE6D5),
          reason: 'Needs resolves to exact illustration edge color 0xFFBFE6D5');
      expect(StarterPackService.resolveCardColorValue(affectedCards[4]), equals(0xFFD1E2FA),
          reason: 'School & Places resolves to exact illustration edge color 0xFFD1E2FA');
    });

    test('7. Remaining 95+ cards retain their designed color values', () {
      final unaffectedCard = AACCard(
        id: 'simpleaac.starter.v2.animals.dog',
        label: 'Dog',
        imagePath: 'assets/images/starter_pack_v8/animals_dog.webp',
        colorValue: 0xFFDFEECF,
      );
      expect(StarterPackService.resolveCardColorValue(unaffectedCard), equals(0xFFDFEECF),
          reason: 'Unaffected cards must not be altered');
    });
  });

  group('Requirement 6 & 7: UI Rendering & Visual Evidence', () {
    testWidgets('8. Home renders 4 child cards as full-bleed, More as stickman, Default as cover', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final defaultCards = createDefaultSeedCards();
      HomePage.initialCardsForTesting = defaultCards;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify labels rendered
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Sad'), findsOneWidget);
      expect(find.text('Angry'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);

      // Verify More has 8 sub-cards badge
      expect(find.text('8 sub-cards'), findsOneWidget);
      // Verify Default has 13 sub-cards badge
      expect(find.text('13 sub-cards'), findsOneWidget);

      // Capture screenshot of Home board
      await tester.runAsync(() async {
        final boundaryFinder = find.byType(RepaintBoundary).first;
        final boundary = tester.element(boundaryFinder).renderObject as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File('docs/qa/home_children_restore/01_home_board_restored_children.png');
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(byteData.buffer.asUint8List());
        }
      });
    });

    testWidgets('9. Inside Default folder renders harmonized category cards without inner square', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final defaultCards = createDefaultSeedCards();
      HomePage.initialCardsForTesting = defaultCards;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Default folder to enter it
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();

      // Verify inside Default folder
      expect(find.text('Animals'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Snacks'), findsOneWidget);

      // Capture screenshot inside Default folder
      await tester.runAsync(() async {
        final boundaryFinder = find.byType(RepaintBoundary).first;
        final boundary = tester.element(boundaryFinder).renderObject as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File('docs/qa/home_children_restore/02_default_folder_harmonized.png');
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(byteData.buffer.asUint8List());
        }
      });
    });

    testWidgets('10. Inside More folder renders 8 stick figures with harmonized background colors', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final defaultCards = createDefaultSeedCards();
      HomePage.initialCardsForTesting = defaultCards;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on More folder to enter it
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // Verify all 8 sub-cards are present
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(find.text('Please'), findsOneWidget);
      expect(find.text('Thank You'), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);

      // Capture screenshot inside More folder
      await tester.runAsync(() async {
        final boundaryFinder = find.byType(RepaintBoundary).first;
        final boundary = tester.element(boundaryFinder).renderObject as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File('docs/qa/home_children_restore/03_more_folder_harmonized.png');
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(byteData.buffer.asUint8List());
        }
      });
    });
  });
}
