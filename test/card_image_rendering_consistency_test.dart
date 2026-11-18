import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/data/default_seed_cards.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/utils/card_image.dart';

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

final Uint8List k1x1PngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    AudioplayersPlatformInterface.instance = FakeAudioplayerPlatform();
    tempDir = await Directory.systemTemp.createTemp('card_image_consistency_test_');
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
    HomePage.initialCardsForTesting = null;
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

  group('Adaptive Card Image Decoding & Resolution Configuration (Phase 3)', () {
    test('computeAdaptiveCacheWidth bounds decoding resolution to rendered card dimensions and DPR', () {
      // 4-column phone: 85dp width @ 2.6 DPR -> 221px
      expect(computeAdaptiveCacheWidth(targetLogicalWidth: 85, devicePixelRatio: 2.6), equals(221));

      // 2-column phone: 180dp width @ 2.5 DPR -> 450px
      expect(computeAdaptiveCacheWidth(targetLogicalWidth: 180, devicePixelRatio: 2.5), equals(450));

      // Tiny chip (e.g. sentence strip): 30dp width @ 2.0 DPR -> clamped to min 120px
      expect(computeAdaptiveCacheWidth(targetLogicalWidth: 30, devicePixelRatio: 2.0), equals(120));

      // Large single-column / tablet: 500dp width @ 3.0 DPR -> clamped to max 1024px
      expect(computeAdaptiveCacheWidth(targetLogicalWidth: 500, devicePixelRatio: 3.0), equals(1024));
    });

    test('buildCardImage adaptively sizes cacheWidth and sets FilterQuality.medium for GPU mipmapping', () {
      // 1. Adaptive decoding for card on grid (targetLogicalWidth: 100, DPR: 2.5 -> 250px)
      final adaptiveWidget = buildCardImage(
        'assets/images/starter_pack_v8/basic_words_hello.webp',
        targetLogicalWidth: 100,
        devicePixelRatio: 2.5,
      ) as Image;
      expect(adaptiveWidget.filterQuality, equals(FilterQuality.medium));
      expect(adaptiveWidget.gaplessPlayback, isTrue);
      expect(adaptiveWidget.image, isA<ResizeImage>());
      final adaptiveResize = adaptiveWidget.image as ResizeImage;
      expect(adaptiveResize.width, equals(250), reason: 'Adaptive decoding reduces memory footprint by >80%');

      // 2. User camera/storage file with adaptive width
      final fileWidget = buildCardImage(
        '/tmp/user_custom_photo.jpg',
        targetLogicalWidth: 150,
        devicePixelRatio: 2.0,
      ) as Image;
      expect(fileWidget.image, isA<ResizeImage>());
      final fileResize = fileWidget.image as ResizeImage;
      expect(fileResize.width, equals(300));

      // 3. Fallback bounded dimensions when no target width is given (512 for assets, 640 for files)
      final fallbackAsset = buildCardImage('assets/images/starter_pack_v8/basic_words_hello.webp') as Image;
      expect((fallbackAsset.image as ResizeImage).width, equals(512));

      final fallbackFile = buildCardImage('/tmp/user_custom_photo.jpg') as Image;
      expect((fallbackFile.image as ResizeImage).width, equals(640));

      // 4. Animated GIF preserves null cacheWidth to prevent flattening frames
      final gifWidget = buildCardImage('/tmp/animated_action.gif') as Image;
      expect(gifWidget.image, isA<FileImage>(), reason: 'GIFs must not be wrapped in ResizeImage');

      // 5. Explicit cacheWidth override is respected
      final customWidget = buildCardImage('assets/images/starter_pack_v8/feelings_happy.webp', cacheWidth: 640) as Image;
      expect((customWidget.image as ResizeImage).width, equals(640));
    });
  });

  group('User-Uploaded Photograph Presentation (Computer Card Mockup Match)', () {
    testWidgets('User photo fills entire card with BoxFit.cover and bottom gradient overlay in Normal & Edit modes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Create a simulated user-uploaded photo path (non-asset) with valid 1x1 image bytes
      final userPhotoFile = File('${tempDir.path}/computer.jpg');
      userPhotoFile.writeAsBytesSync(k1x1PngBytes);

      final computerCard = AACCard(
        id: 'user_card_computer',
        label: 'Computer',
        imagePath: userPhotoFile.path,
        colorValue: 0xFF228ED3,
      );

      final starterCard = AACCard(
        id: 'starter_rabbit_card',
        label: 'Rabbit',
        imagePath: 'assets/images/starter_pack_v8/animals_rabbit.webp',
        colorValue: 0xFFE8F4DD,
      );

      HomePage.initialCardsForTesting = [computerCard, starterCard];
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify Computer card renders with BoxFit.cover
      final computerCardFinder = find.byKey(const ValueKey('user_card_computer'));
      expect(computerCardFinder, findsOneWidget);

      final computerImgFinder = find.descendant(
        of: computerCardFinder,
        matching: find.byType(Image),
      );
      expect(computerImgFinder, findsOneWidget);
      final computerImg = tester.widget<Image>(computerImgFinder);
      expect(computerImg.fit, equals(BoxFit.cover),
          reason: 'User photographs must fill the card using BoxFit.cover without empty margins');

      // 2. Verify Rabbit card keeps standard BoxFit.contain
      final rabbitCardFinder = find.byKey(const ValueKey('starter_rabbit_card'));
      expect(rabbitCardFinder, findsOneWidget);

      final rabbitImgFinder = find.descendant(
        of: rabbitCardFinder,
        matching: find.byType(Image),
      );
      expect(rabbitImgFinder, findsOneWidget);
      final rabbitImg = tester.widget<Image>(rabbitImgFinder);
      expect(rabbitImg.fit, equals(BoxFit.contain),
          reason: 'Starter pack illustrations must remain BoxFit.contain');

      // 3. Verify label 'Computer' is displayed as overlay
      expect(find.text('Computer'), findsOneWidget);

      // 4. Enter Edit Words Mode and verify presentation is preserved with action tray
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      final editComputerCardFinder = find.byKey(const ValueKey('user_card_computer'));
      expect(editComputerCardFinder, findsOneWidget);

      // Action tray exists under the card
      expect(find.byKey(const ValueKey('card_drag_handle_user_card_computer')), findsOneWidget);
      expect(find.byKey(const ValueKey('card_edit_pencil_user_card_computer')), findsOneWidget);
      expect(find.byKey(const ValueKey('card_delete_btn_user_card_computer')), findsOneWidget);

      // Image still has BoxFit.cover
      final editComputerImgFinder = find.descendant(
        of: editComputerCardFinder,
        matching: find.byType(Image),
      );
      expect(editComputerImgFinder, findsOneWidget);
      expect(tester.widget<Image>(editComputerImgFinder).fit, equals(BoxFit.cover));

      expect(tester.takeException(), isNull);
    });
  });

  group('Safe Idempotent Seed Migration (Option A)', () {
    test('Unchanged legacy seed cards migrate to Starter Pack WebP assets, while preserving user edits and deletions', () async {
      // 1. Setup simulated existing user cards:
      // - Hello has legacy PNG -> should migrate to basic_words_hello.webp
      // - Happy has custom label 'Very Happy' with legacy PNG -> image migrates, custom label preserved
      // - Sad has custom user photo -> image must NOT be overwritten!
      // - Angry was deleted by user -> must NOT be restored!
      // - More has custom color -> image migrates, custom color preserved
      final userPhoto = '${tempDir.path}/my_sad_photo.jpg';

      final existingCards = [
        AACCard(
          id: 'seed_hello',
          label: 'Hello',
          imagePath: 'assets/images/seed/hello.png',
          colorValue: 0xFFFFF176,
        ),
        AACCard(
          id: 'seed_happy',
          label: 'Very Happy', // Custom user label
          imagePath: 'assets/images/seed/happy.png',
          colorValue: 0xFF81D4FA,
        ),
        AACCard(
          id: 'seed_sad',
          label: 'Sad',
          imagePath: userPhoto, // Custom user photo
          colorValue: 0xFF4FC3F7,
        ),
        // seed_angry intentionally deleted by user!
        AACCard(
          id: 'seed_more',
          label: 'More',
          imagePath: 'assets/images/seed/blocks.png',
          colorValue: 0xFF00FF00, // Custom user green color
          type: 'folder',
        ),
      ];

      // Save to disk pretending this was catalog version 6
      await CardStorageService.saveCards(existingCards);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeededDefaultCards', true);
      await prefs.setInt('seededDefaultCardsVersion', 6);

      // Now load cards with new code (catalog version 7)
      final loadedCards = await CardStorageService.loadCards(
        defaultCardsBuilder: createDefaultSeedCards,
      );

      // 1. Verify seed_hello migrated to basic_words_hello.webp
      final hello = loadedCards.firstWhere((c) => c.id == 'seed_hello');
      expect(hello.imagePath, equals('assets/images/starter_pack_v8/basic_words_hello.webp'));

      // 2. Verify seed_happy migrated image but preserved custom label
      final happy = loadedCards.firstWhere((c) => c.id == 'seed_happy');
      expect(happy.imagePath, equals('assets/images/starter_pack_v8/feelings_happy.webp'));
      expect(happy.label, equals('Very Happy'), reason: 'Custom user label must never be overwritten');

      // 3. Verify seed_sad preserved custom user photo
      final sad = loadedCards.firstWhere((c) => c.id == 'seed_sad');
      expect(sad.imagePath, equals(userPhoto), reason: 'Custom user photo must never be overwritten');

      // 4. Verify seed_angry was NOT automatically restored
      expect(loadedCards.any((c) => c.id == 'seed_angry'), isFalse,
          reason: 'Deleted default card must never be restored automatically');

      // 5. Verify seed_more migrated image but preserved custom color
      final more = loadedCards.firstWhere((c) => c.id == 'seed_more');
      expect(more.imagePath, equals('assets/images/starter_pack_v8/basic_words_more.webp'));
      expect(more.colorValue, equals(0xFF00FF00), reason: 'Custom user color must be preserved');

      // 6. Verify seededDefaultCardsVersion was updated to 7
      expect(prefs.getInt('seededDefaultCardsVersion'), equals(7));

      // 7. Re-running loadCards is completely idempotent
      final reloadedCards = await CardStorageService.loadCards(
        defaultCardsBuilder: createDefaultSeedCards,
      );
      expect(reloadedCards.length, equals(loadedCards.length));
      expect(reloadedCards.firstWhere((c) => c.id == 'seed_hello').imagePath,
          equals('assets/images/starter_pack_v8/basic_words_hello.webp'));
    });
  });
}
