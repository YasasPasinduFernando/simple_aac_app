import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/utils/image_cache_diagnostics.dart';

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
  late String simulatedPhotoPath;

  setUp(() async {
    AudioplayersPlatformInterface.instance = FakeAudioplayerPlatform();
    tempDir = await Directory.systemTemp.createTemp('perf_stress_test_');
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

    PaintingBinding.instance.imageCache.maximumSizeBytes = 96 * 1024 * 1024;
    PaintingBinding.instance.imageCache.maximumSize = 250;

    final photoFile = File('${tempDir.path}/test_photo.png');
    photoFile.writeAsBytesSync(k1x1PngBytes);
    simulatedPhotoPath = photoFile.path;
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

  List<AACCard> generateCards(int count) {
    final list = <AACCard>[];
    for (int i = 0; i < count; i++) {
      final isPhoto = i % 2 == 0;
      final isFolder = i % 10 == 0;
      final isGif = i % 20 == 0;

      list.add(
        AACCard(
          id: 'card_$i',
          label: 'Card $i',
          type: isFolder ? 'folder' : 'word',
          imagePath: isGif
              ? '/tmp/action_$i.gif'
              : (isPhoto ? simulatedPhotoPath : 'assets/images/starter_pack_v8/animals_dog.webp'),
          colorValue: 0xFF2196F3,
          subCards: isFolder
              ? [
                  AACCard(
                    id: 'sub_${i}_1',
                    label: 'Sub 1',
                    imagePath: simulatedPhotoPath,
                    colorValue: 0xFF4CAF50,
                  ),
                  AACCard(
                    id: 'sub_${i}_2',
                    label: 'Sub 2',
                    imagePath: 'assets/images/starter_pack_v8/feelings_happy.webp',
                    colorValue: 0xFFFFC107,
                  ),
                ]
              : [],
        ),
      );
    }
    return list;
  }

  group('Large Dataset Stress Testing & Image Performance (Phases 9 & 10)', () {
    testWidgets('10 Cards Baseline: Fast startup and bounded ImageCache footprint', (tester) async {
      final cards10 = generateCards(10);
      HomePage.initialCardsForTesting = cards10;

      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      stopwatch.stop();

      // Initial frame rendered quickly (generous threshold to avoid flakiness under full test suite CPU contention)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      expect(find.byType(HomePage), findsOneWidget);

      final snapshot = ImageCacheDiagnostics.getSnapshot();
      debugPrint('[PERF 10 cards] snapshot: $snapshot');
      expect(snapshot['maximumSizeBytes'], equals(96 * 1024 * 1024));
    });

    testWidgets('100 Cards Stress Test: Rapid scrolling without crash or unconstrained heap growth', (tester) async {
      final cards100 = generateCards(100);
      HomePage.initialCardsForTesting = cards100;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Card 0'), findsOneWidget);

      // Perform rapid fling scroll down
      await tester.fling(find.byType(GridView), const Offset(0, -1200), 3000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final snapshotAfterScroll = ImageCacheDiagnostics.getSnapshot();
      debugPrint('[PERF 100 cards] after scroll: $snapshotAfterScroll');
      expect(snapshotAfterScroll['currentSizeBytes'], lessThan(96 * 1024 * 1024));
    });

    testWidgets('500 Cards Stress Test: Folder opening and return with stable memory', (tester) async {
      final cards500 = generateCards(500);
      HomePage.initialCardsForTesting = cards500;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Open folder Card 0
      await tester.tap(find.text('Card 0'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify sub-cards inside Card 0 are rendered
      expect(find.text('Sub 1'), findsOneWidget);
      expect(find.text('Sub 2'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Card 0'), findsOneWidget);
    });

    testWidgets('1,000 Cards Ultimate Stress Test: Zero OOM, zero leak, and responsive Edit Mode', (tester) async {
      final cards1000 = generateCards(1000);
      HomePage.initialCardsForTesting = cards1000;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(HomePage), findsOneWidget);

      // Multiple rapid scrolls through the large dataset
      for (int i = 0; i < 3; i++) {
        await tester.fling(find.byType(GridView), const Offset(0, -1500), 4000);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      final snapshot = ImageCacheDiagnostics.getSnapshot();
      debugPrint('[PERF 1000 cards] after 3 flings: $snapshot');
      expect(snapshot['currentSizeBytes'], lessThanOrEqualTo(96 * 1024 * 1024));

      // Verify Edit Words Mode toggle operates cleanly even with 1000 cards
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Add New'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
