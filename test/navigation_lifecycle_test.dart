import 'dart:io';
import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/data/default_seed_cards.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/navigation_state_service.dart';
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
    tempDir = await Directory.systemTemp.createTemp('nav_lifecycle_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;
  });

  tearDownAll(() async {
    CardStorageService.resetTestHooks();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HomePage.skipSplashForTesting = true;
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.initialCardsForTesting = null;
    NavigationStateService.testRestoreInfoOverride = null;
    StarterPackService.clearCache();
  });

  tearDown(() {
    HomePage.skipSplashForTesting = false;
    HomePage.initialCardsForTesting = null;
    NavigationStateService.testRestoreInfoOverride = null;
  });

  group('A. NavigationStateService Unit Tests', () {
    test('1. validateFolderChain resolves valid nested folder path correctly', () {
      final subFolder = AACCard(
        id: 'animals',
        label: 'Animals',
        type: 'folder',
        colorValue: 0xFFFFFFFF,
        subCards: [AACCard(id: 'dog', label: 'Dog', colorValue: 0xFFFFFFFF)],
      );
      final rootFolder = AACCard(
        id: 'default_root',
        label: 'Default',
        type: 'folder',
        colorValue: 0xFFFFFFFF,
        subCards: [subFolder],
      );
      final List<AACCard> cards = [rootFolder];

      final chain = NavigationStateService.validateFolderChain(
        ['default_root', 'animals'],
        cards,
      );

      expect(chain, isNotNull);
      expect(chain!.length, equals(2));
      expect(chain[0].id, equals('default_root'));
      expect(chain[1].id, equals('animals'));
    });

    test('2. validateFolderChain returns null when folder was deleted or missing', () {
      final rootFolder = AACCard(
        id: 'default_root',
        label: 'Default',
        type: 'folder',
        colorValue: 0xFFFFFFFF,
        subCards: [],
      );
      final List<AACCard> cards = [rootFolder];

      final chain = NavigationStateService.validateFolderChain(
        ['default_root', 'deleted_folder'],
        cards,
      );

      expect(chain, isNull, reason: 'Broken chain must safely return null for Home fallback');
    });

    test('3. validateFolderChain returns null when target card is a word card not a folder', () {
      final wordCard = AACCard(
        id: 'apple',
        label: 'Apple',
        type: 'word',
        colorValue: 0xFFFFFFFF,
        subCards: [],
      );
      final rootFolder = AACCard(
        id: 'food',
        label: 'Food',
        type: 'folder',
        colorValue: 0xFFFFFFFF,
        subCards: [wordCard],
      );
      final List<AACCard> cards = [rootFolder];

      final chain = NavigationStateService.validateFolderChain(
        ['food', 'apple'],
        cards,
      );

      expect(chain, isNull, reason: 'Non-folder leaf must return null');
    });

    test('4. syncFolderStack updates SharedPreferences persistence', () async {
      await NavigationStateService.syncFolderStack(['root', 'sub']);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList(NavigationStateService.prefFolderStackKey),
        equals(['root', 'sub']),
      );

      // Clearing stack removes preference
      await NavigationStateService.syncFolderStack([]);
      expect(
        prefs.getStringList(NavigationStateService.prefFolderStackKey),
        isNull,
      );
    });
  });

  group('B. System Process Recreation & Resume Verification', () {
    testWidgets('1. Process recreation restores user to exact nested folder path', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final cards = createDefaultSeedCards();
      // Ensure Default -> Animals path exists in seed cards
      final defaultFolder = cards.firstWhere(
        (c) => c.id == StarterPackService.starterPackRootId,
      );
      expect(defaultFolder, isNotNull);

      // Simulate system process recreation with saved folder path
      NavigationStateService.testRestoreInfoOverride = const NavigationRestoreInfo(
        isSystemProcessRecreation: true,
        folderStackIds: [
          'simpleaac.starter.v2.default',
          'simpleaac.starter.v2.animals',
        ],
      );

      HomePage.initialCardsForTesting = cards;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Verify that Animals breadcrumb / title is active
      expect(find.text('Animals'), findsWidgets);
      // Verify Dog & Cat cards inside Animals are visible
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Cat'), findsOneWidget);

      // Verify Edit Mode is NOT opened
      expect(find.text('Tap to customize board'), findsNothing);
      expect(find.byIcon(Icons.edit_rounded), findsNothing);
    });

    testWidgets('2. Invalid saved folder safely falls back to root Home screen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final cards = createDefaultSeedCards();

      // Simulate system process recreation with a deleted/invalid folder ID
      NavigationStateService.testRestoreInfoOverride = const NavigationRestoreInfo(
        isSystemProcessRecreation: true,
        folderStackIds: ['non_existent_folder_999'],
      );

      HomePage.initialCardsForTesting = cards;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Root cards should be visible
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
    });

    testWidgets('3. Fresh app launch (isSystemProcessRecreation = false) always opens Home', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      final cards = createDefaultSeedCards();

      // Even if SharedPreferences had an old stack, fresh launch must open Home
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        NavigationStateService.prefFolderStackKey,
        ['simpleaac.starter.v2.default', 'simpleaac.starter.v2.animals'],
      );

      NavigationStateService.testRestoreInfoOverride = const NavigationRestoreInfo(
        isSystemProcessRecreation: false,
        folderStackIds: [],
      );

      HomePage.initialCardsForTesting = cards;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Should open root Home screen
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      // Dog & Cat should NOT be visible on root
      expect(find.text('Dog'), findsNothing);
    });
  });
}
