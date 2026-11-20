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
import 'package:simple_aac_app/models/aac_card_model.dart';
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
    tempDir = await Directory.systemTemp.createTemp('folder_card_filling_test_');
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
      'useImageOverlayLabel': true,
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

  test('1. Manifest & Harmonized Colors Match Image Asset Perimeter', () {
    const expectedColors = {
      'simpleaac.starter.v2.animals': 0xFFE0EED0,
      'simpleaac.starter.v2.food': 0xFFFEE2A0,
      'simpleaac.starter.v2.snacks': 0xFFFFD8BC,
      'simpleaac.starter.v2.needs': 0xFFBFE6D5,
      'simpleaac.starter.v2.school_places': 0xFFD1E2FA,
    };

    expect(StarterPackService.harmonizedCategoryFolderColors, equals(expectedColors));

    final root = StarterPackService.buildStarterPack();
    for (final entry in expectedColors.entries) {
      final folder = root.subCards.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => throw StateError('Missing folder ${entry.key}'),
      );
      expect(folder.colorValue, equals(entry.value),
          reason: '${entry.key} must be initialized with harmonized color ${entry.value}');
    }
  });

  test('2. Existing Install Safety: resolveCardColorValue Resolves Legacy Cards', () {
    // Simulate cards saved on disk with legacy mismatched colors
    final legacyAnimals = AACCard(
      id: 'simpleaac.starter.v2.animals',
      label: 'Animals',
      imagePath: 'assets/images/starter_pack_v8/animals_dog.webp',
      colorValue: 0xFFE8F4DD, // Legacy color
      type: 'folder',
    );

    final legacyFood = AACCard(
      id: 'simpleaac.starter.v2.food',
      label: 'Food',
      imagePath: 'assets/images/starter_pack_v8/food_food.webp',
      colorValue: 0xFFFFF0B7, // Legacy color
      type: 'folder',
    );

    final legacySnacks = AACCard(
      id: 'simpleaac.starter.v2.snacks',
      label: 'Snacks',
      imagePath: 'assets/images/starter_pack_v8/snacks_cookies.webp',
      colorValue: 0xFFFFE6D4, // Legacy color
      type: 'folder',
    );

    final legacyNeeds = AACCard(
      id: 'simpleaac.starter.v2.needs',
      label: 'Needs',
      imagePath: 'assets/images/starter_pack_v8/needs_needs.webp',
      colorValue: 0xFFDDF5ED, // Legacy color
      type: 'folder',
    );

    final legacySchool = AACCard(
      id: 'simpleaac.starter.v2.school_places',
      label: 'School & Places',
      imagePath: 'assets/images/starter_pack_v8/school_places_school.webp',
      colorValue: 0xFFD9EDFF, // Legacy color
      type: 'folder',
    );

    expect(StarterPackService.resolveCardColorValue(legacyAnimals), equals(0xFFE0EED0));
    expect(StarterPackService.resolveCardColorValue(legacyFood), equals(0xFFFEE2A0));
    expect(StarterPackService.resolveCardColorValue(legacySnacks), equals(0xFFFFD8BC));
    expect(StarterPackService.resolveCardColorValue(legacyNeeds), equals(0xFFBFE6D5));
    expect(StarterPackService.resolveCardColorValue(legacySchool), equals(0xFFD1E2FA));
  });

  test('3. Caregiver Customization Preservation: Custom Photos & Colors Kept', () {
    // Caregiver assigned personal photo to Animals folder
    final customAnimals = AACCard(
      id: 'simpleaac.starter.v2.animals',
      label: 'My Pets',
      imagePath: '/data/user/0/lk.yasas.simpleaac/app_flutter/caregiver_dog.jpg',
      colorValue: 0xFF4CAF50, // Custom green
      type: 'folder',
    );

    // Unrelated custom card
    final customCard = AACCard(
      id: 'custom_user_card',
      label: 'Custom',
      imagePath: '/data/user/0/lk.yasas.simpleaac/app_flutter/custom.png',
      colorValue: 0xFFFF5722,
      type: 'word',
    );

    expect(StarterPackService.resolveCardColorValue(customAnimals), equals(0xFF4CAF50));
    expect(StarterPackService.resolveCardColorValue(customCard), equals(0xFFFF5722));
  });

  testWidgets('4. Default Folder UI: Category Cards Render Harmonized Backgrounds', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(MaterialApp(home: HomePage(key: UniqueKey())));
    await tester.pumpAndSettle();

    // Tap Default folder
    final defaultFinder = find.text('Default');
    expect(defaultFinder, findsOneWidget);
    await tester.tap(defaultFinder);
    await tester.pumpAndSettle();

    // Verify Animals folder card is visible
    final animalsFinder = find.text('Animals');
    expect(animalsFinder, findsOneWidget);

    // Find AnimatedContainer for Animals card and check background color
    final animalsContainers = tester.widgetList<AnimatedContainer>(
      find.descendant(
        of: find.ancestor(of: animalsFinder, matching: find.byType(GestureDetector)),
        matching: find.byType(AnimatedContainer),
      ),
    );

    expect(animalsContainers.isNotEmpty, isTrue);
    final boxDecoration = animalsContainers.first.decoration as BoxDecoration;
    expect(boxDecoration.color, equals(const Color(0xFFE0EED0)),
        reason: 'Animals folder card background must match the 0xFFE0EED0 asset background');

    // Verify Food folder card
    final foodFinder = find.text('Food');
    expect(foodFinder, findsOneWidget);
    final foodContainers = tester.widgetList<AnimatedContainer>(
      find.descendant(
        of: find.ancestor(of: foodFinder, matching: find.byType(GestureDetector)),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(foodContainers.isNotEmpty, isTrue);
    final foodDecoration = foodContainers.first.decoration as BoxDecoration;
    expect(foodDecoration.color, equals(const Color(0xFFFEE2A0)),
        reason: 'Food folder card background must match the 0xFFFEE2A0 asset background');

    // Verify Snacks folder card
    final snacksFinder = find.text('Snacks');
    expect(snacksFinder, findsOneWidget);
    final snacksContainers = tester.widgetList<AnimatedContainer>(
      find.descendant(
        of: find.ancestor(of: snacksFinder, matching: find.byType(GestureDetector)),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(snacksContainers.isNotEmpty, isTrue);
    final snacksDecoration = snacksContainers.first.decoration as BoxDecoration;
    expect(snacksDecoration.color, equals(const Color(0xFFFFD8BC)),
        reason: 'Snacks folder card background must match the 0xFFFFD8BC asset background');
  });

  testWidgets('5. Visual Evidence Capture: Inside Default Folder', (tester) async {
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
    await tester.tap(find.text('Default'));
    await tester.pumpAndSettle();

    // Capture screenshot of Default folder showing harmonized cards
    final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      const outDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
      await File('$outDir/default_folder_harmonized_cards.png').writeAsBytes(bytes);
      await File('docs/qa/default_folder_cover/default_folder_harmonized_cards.png').create(recursive: true);
      await File('docs/qa/default_folder_cover/default_folder_harmonized_cards.png').writeAsBytes(bytes);
    });
  });
}
