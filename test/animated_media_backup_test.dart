import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/utils/animated_media_helper.dart';
import 'package:simple_aac_app/utils/app_permissions_helper.dart';
import 'package:simple_aac_app/utils/card_image.dart';
import 'package:simple_aac_app/widgets/card_editor_dialog.dart';

class _FakeAudioPlayer extends Fake implements AudioPlayer {}

// Valid minimal 1x1 white GIF89a image (35 bytes)
const List<int> _sampleGifBytes = <int>[
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00,
  0x00, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3B,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'online_features_enabled': false});
    await NetworkPolicyService.instance.init();
    AppPermissionsHelper.statusReader = (_) async => PermissionStatus.granted;
    AppPermissionsHelper.sdkVersionReader = () async => 34;
  });

  tearDown(() {
    AppPermissionsHelper.resetTestHooks();
    AnimatedMediaHelper.resetTestHooks();
    CardStorageService.resetTestHooks();
  });

  test('buildCardImage preserves native codec for GIFs and bounds static images',
      () {
    expect(isGifImagePath('/tmp/wave.gif'), isTrue);
    expect(isGifImagePath('/tmp/wave.GIF'), isTrue);
    expect(isGifImagePath('/tmp/photo.jpg'), isFalse);

    final gifWidget = buildCardImage('/tmp/wave.gif', cacheWidth: 480) as Image;
    expect(gifWidget.image, isA<FileImage>());

    final jpgWidget = buildCardImage('/tmp/photo.jpg', cacheWidth: 480) as Image;
    expect(jpgWidget.image, isA<ResizeImage>());
  });

  test('AnimatedMediaHelper.isValidGifHeader validates GIF signatures strictly',
      () {
    expect(AnimatedMediaHelper.isValidGifHeader(_sampleGifBytes), isTrue);
    expect(
      AnimatedMediaHelper.isValidGifHeader('GIF87a........'.codeUnits),
      isTrue,
    );
    expect(
      AnimatedMediaHelper.isValidGifHeader(<int>[0x89, 0x50, 0x4E, 0x47]),
      isFalse,
    );
    expect(AnimatedMediaHelper.isValidGifHeader(<int>[]), isFalse);
  });

  group('AnimatedMediaHelper video/GIF selection & >30s guard', () {
    testWidgets(
        'warns when video >30s and lets user Cancel or Use First 30s cleanly',
        (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('gif_trim_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
      CardStorageService.docsDirectoryOverride = () async => tempDir;

      final longVideo = File('${tempDir.path}/long.mp4')
        ..writeAsBytesSync([1, 2, 3, 4]);
      final persistedTrimmed = File('${tempDir.path}/persisted_trim.gif');

      Duration? capturedMaxDuration;
      bool converterCalled = false;
      bool capturedTrimFlag = false;

      AnimatedMediaHelper.videoPickerOverride =
          (source, {Duration? maxDuration}) async {
        capturedMaxDuration = maxDuration;
        return XFile(longVideo.path);
      };
      AnimatedMediaHelper.durationProbeOverride = (_) async => 42000;
      AnimatedMediaHelper.converterOverride = ({
        required String inputPath,
        required String outputPath,
        bool trimToLimit = false,
      }) async {
        converterCalled = true;
        capturedTrimFlag = trimToLimit;
        File(outputPath).writeAsBytesSync(_sampleGifBytes);
        return GifConversionResult(
          outputPath: outputPath,
          durationMs: 42000,
          encodedDurationMs: trimToLimit ? 30000 : 42000,
          trimmed: trimToLimit,
          frameCount: 90,
          sizeBytes: _sampleGifBytes.length,
        );
      };
      AnimatedMediaHelper.persistMediaOverride =
          (sourcePath, {required String cardId}) async {
        persistedTrimmed.writeAsBytesSync(File(sourcePath).readAsBytesSync());
        return persistedTrimmed.path;
      };

      late BuildContext savedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                savedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      // 1) User cancels when warned about >30s video.
      final cancelFuture = AnimatedMediaHelper.pickOrCreateAnimatedGif(
        savedContext,
        cardId: 'card_long_cancel',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose Video (Max 30s)'));
      await tester.pumpAndSettle();

      expect(find.text('Video Longer Than 30s'), findsOneWidget);
      expect(find.textContaining('42s'), findsOneWidget);
      expect(find.text('Use First 30s'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await cancelFuture, isNull);
      expect(converterCalled, isFalse);

      // 2) User confirms 'Use First 30s' -> trims cleanly and persists .gif.
      final trimFuture = AnimatedMediaHelper.pickOrCreateAnimatedGif(
        savedContext,
        cardId: 'card_long_trim',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose Video (Max 30s)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use First 30s'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      final trimmedPath = await trimFuture;
      expect(capturedMaxDuration, const Duration(seconds: 30));
      expect(converterCalled, isTrue);
      expect(capturedTrimFlag, isTrue);
      expect(trimmedPath, persistedTrimmed.path);
      expect(File(trimmedPath!).readAsBytesSync(), _sampleGifBytes);
    });

    testWidgets(
        'converts <=30s video to valid persisted GIF and rejects corrupt GIF pick',
        (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('gif_ok_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
      CardStorageService.docsDirectoryOverride = () async => tempDir;

      final shortVideo = File('${tempDir.path}/short.mp4')
        ..writeAsBytesSync([1, 2, 3, 4]);
      final badGif = File('${tempDir.path}/fake.gif')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);

      AnimatedMediaHelper.videoPickerOverride =
          (source, {Duration? maxDuration}) async => XFile(shortVideo.path);
      AnimatedMediaHelper.converterOverride = ({
        required String inputPath,
        required String outputPath,
        bool trimToLimit = false,
      }) async {
        File(outputPath).writeAsBytesSync(_sampleGifBytes);
        return GifConversionResult(
          outputPath: outputPath,
          durationMs: 4200,
          frameCount: 24,
          sizeBytes: _sampleGifBytes.length,
        );
      };
      final persistedOk = File('${tempDir.path}/persisted_short.gif');
      AnimatedMediaHelper.persistMediaOverride =
          (sourcePath, {required String cardId}) async {
        persistedOk.writeAsBytesSync(File(sourcePath).readAsBytesSync());
        return persistedOk.path;
      };
      AnimatedMediaHelper.gifFilePickerOverride = () async => badGif.path;

      late BuildContext savedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                savedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final okFuture = AnimatedMediaHelper.pickOrCreateAnimatedGif(
        savedContext,
        cardId: 'card_short',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record Video (Max 30s)'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      final savedGifPath = await okFuture;
      expect(savedGifPath, isNotNull);
      expect(savedGifPath!.endsWith('.gif'), isTrue);
      expect(File(savedGifPath).readAsBytesSync(), _sampleGifBytes);

      final badFuture = AnimatedMediaHelper.pickOrCreateAnimatedGif(
        savedContext,
        cardId: 'card_bad_gif',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose Existing GIF'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      expect(await badFuture, isNull);
      expect(find.textContaining('valid animated .gif'), findsOneWidget);
    });
  });

  testWidgets(
      'CardEditorDialog attaches GIF clip on compact 320x640 layout without overflow',
      (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('gif_editor_');
    addTearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });
    CardStorageService.docsDirectoryOverride = () async => tempDir;

    final validGif = File('${tempDir.path}/wave.gif')
      ..writeAsBytesSync(_sampleGifBytes);
    final persistedEditorGif = File('${tempDir.path}/editor_wave.gif');
    AnimatedMediaHelper.gifFilePickerOverride = () async => validGif.path;
    AnimatedMediaHelper.persistMediaOverride =
        (sourcePath, {required String cardId}) async {
      persistedEditorGif.writeAsBytesSync(File(sourcePath).readAsBytesSync());
      return persistedEditorGif.path;
    };

    final card = AACCard(
      id: 'wave_card',
      label: 'Wave',
      colorValue: 0xFF90CAF9,
      category: 'General',
    );

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.25),
          ),
          child: Scaffold(
            body: CardEditorDialog(
              card: card,
              isNew: false,
              categories: const ['General'],
              audioPlayer: _FakeAudioPlayer(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('GIF / Short Video (Max 30s)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose Existing GIF'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(card.imagePath, isNotNull);
    expect(card.imagePath!.endsWith('.gif'), isTrue);
    expect(find.text('GIF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('Backup & Storage integrity for GIFs, photos, voice & nested cards',
      () {
    test('rejects 0-byte empty media files on persistMediaFile', () async {
      final tempDir = Directory.systemTemp.createTempSync('empty_media_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
      CardStorageService.docsDirectoryOverride = () async => tempDir;

      final emptyFile = File('${tempDir.path}/empty.gif')..writeAsBytesSync([]);
      await expectLater(
        () => CardStorageService.persistMediaFile(
          emptyFile.path,
          cardId: 'c1',
          mediaType: 'images',
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test(
        'full round-trip saveCards -> buildBackupZip -> restoreFromZipBytes preserves exact GIF & voice bytes for cards and subCards',
        () async {
      final sourceDocs = Directory.systemTemp.createTempSync('backup_src_');
      final restoreDocs = Directory.systemTemp.createTempSync('backup_dst_');
      addTearDown(() {
        if (sourceDocs.existsSync()) sourceDocs.deleteSync(recursive: true);
        if (restoreDocs.existsSync()) restoreDocs.deleteSync(recursive: true);
      });

      CardStorageService.docsDirectoryOverride = () async => sourceDocs;

      final customGifBytes1 = <int>[..._sampleGifBytes, 0x00];
      final customGifBytes2 = <int>[..._sampleGifBytes];
      final sampleAudioBytes = <int>[0x49, 0x44, 0x33, 0x01, 0x02, 0x03];

      final rawGif1 = File('${sourceDocs.path}/raw_wave.gif')
        ..writeAsBytesSync(customGifBytes1);
      final rawGif2 = File('${sourceDocs.path}/raw_drink.gif')
        ..writeAsBytesSync(customGifBytes2);
      final rawVoice = File('${sourceDocs.path}/raw_voice.m4a')
        ..writeAsBytesSync(sampleAudioBytes);

      final persistedGif1 = await CardStorageService.persistMediaFile(
        rawGif1.path,
        cardId: 'card_wave',
        mediaType: 'images',
      );
      final persistedGif2 = await CardStorageService.persistMediaFile(
        rawGif2.path,
        cardId: 'card_drink',
        mediaType: 'images',
      );
      final persistedVoice = await CardStorageService.persistMediaFile(
        rawVoice.path,
        cardId: 'card_drink',
        mediaType: 'voices',
      );

      final cards = <AACCard>[
        AACCard(
          id: 'card_wave',
          label: 'Wave',
          imagePath: persistedGif1,
          colorValue: 0xFF90CAF9,
        ),
        AACCard(
          id: 'folder_actions',
          label: 'Actions',
          type: 'folder',
          colorValue: 0xFFA5D6A7,
          subCards: [
            AACCard(
              id: 'card_drink',
              label: 'Drink',
              imagePath: persistedGif2,
              voicePath: persistedVoice,
              colorValue: 0xFFFFF59D,
            ),
          ],
        ),
      ];

      await CardStorageService.saveCards(cards);
      final settings = {
        'ttsVoiceProfile': 'girl',
        'darkModeEnabled': true,
      };
      final zipBytes =
          await BackupService.buildBackupZip(cards, settings: settings);
      expect(zipBytes, isNotNull);
      expect(zipBytes!, isNotEmpty);

      // Verify ZIP manifest contains relative files/*.gif entries.
      final archive = ZipDecoder().decodeBytes(zipBytes);
      expect(
        archive.files.any((f) => f.name.startsWith('files/') && f.name.endsWith('.gif')),
        isTrue,
      );

      // Restore into a completely fresh device documents directory.
      CardStorageService.docsDirectoryOverride = () async => restoreDocs;
      final restored = await BackupService.restoreFromZipBytes(zipBytes);
      expect(restored.cards.length, 2);
      expect(restored.settings['ttsVoiceProfile'], 'girl');
      expect(restored.settings['darkModeEnabled'], isTrue);

      final restoredWave = restored.cards[0];
      expect(restoredWave.imagePath, isNotNull);
      expect(restoredWave.imagePath!.endsWith('.gif'), isTrue);
      expect(restoredWave.imagePath!.startsWith(restoreDocs.path), isTrue);
      expect(File(restoredWave.imagePath!).readAsBytesSync(), customGifBytes1);

      final restoredSub = restored.cards[1].subCards.single;
      expect(restoredSub.imagePath, isNotNull);
      expect(restoredSub.imagePath!.endsWith('.gif'), isTrue);
      expect(File(restoredSub.imagePath!).readAsBytesSync(), customGifBytes2);
      expect(restoredSub.voicePath, isNotNull);
      expect(File(restoredSub.voicePath!).readAsBytesSync(), sampleAudioBytes);

      // Save & reload restored cards on clean docsDir to verify storage parity.
      await CardStorageService.saveCards(restored.cards);
      final reloaded = await CardStorageService.loadCards(defaultCards: const []);
      expect(reloaded.length, 2);
      expect(reloaded[0].imagePath, restoredWave.imagePath);
      expect(reloaded[1].subCards.single.imagePath, restoredSub.imagePath);
    });

    test('restoreFromZipBytes blocks Zip Slip path traversal entries',
        () async {
      final restoreDocs = Directory.systemTemp.createTempSync('zipslip_dst_');
      final outsideTarget = File('${restoreDocs.parent.path}/escaped_evil.txt');
      if (outsideTarget.existsSync()) outsideTarget.deleteSync();
      addTearDown(() {
        if (restoreDocs.existsSync()) restoreDocs.deleteSync(recursive: true);
        if (outsideTarget.existsSync()) outsideTarget.deleteSync();
      });
      CardStorageService.docsDirectoryOverride = () async => restoreDocs;

      final maliciousArchive = Archive()
        ..addFile(ArchiveFile('cards.json', 2, utf8.encode('[]')))
        ..addFile(
          ArchiveFile('../escaped_evil.txt', 4, utf8.encode('evil')),
        );
      final zipBytes = ZipEncoder().encode(maliciousArchive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards, isEmpty);
      expect(outsideTarget.existsSync(), isFalse);
    });

    test('concurrent saveCards calls serialize safely without race errors',
        () async {
      final tempDir = Directory.systemTemp.createTempSync('save_serial_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
      CardStorageService.docsDirectoryOverride = () async => tempDir;

      await Future.wait([
        for (var i = 1; i <= 5; i++)
          CardStorageService.saveCards([
            AACCard(
              id: 'card_$i',
              label: 'Word $i',
              colorValue: 0xFF90CAF9,
            ),
          ]),
      ]);

      final loaded = await CardStorageService.loadCards(defaultCards: const []);
      expect(loaded.length, 1);
      expect(loaded.single.id, 'card_5');
    });
  });
}
