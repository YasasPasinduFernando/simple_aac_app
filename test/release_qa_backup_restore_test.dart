import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';

const List<int> _sampleGif = <int>[
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00,
  0x00, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3B,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    CardStorageService.resetTestHooks();
  });

  group('Release QA: Backup & Restore Comprehensive Verification', () {
    test(
        'Round-trip multilingual cards, nested subfolders, and media SHA-256 match',
        () async {
      final srcDir = Directory.systemTemp.createTempSync('qa_src_');
      final dstDir = Directory.systemTemp.createTempSync('qa_dst_');
      addTearDown(() {
        if (srcDir.existsSync()) srcDir.deleteSync(recursive: true);
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
      });

      CardStorageService.docsDirectoryOverride = () async => srcDir;

      final jpgBytes = utf8.encode('FAKE_JPEG_IMAGE_CONTENT_FOR_TEST_PURPOSES');
      const gifBytes = _sampleGif;
      final voiceBytes = utf8.encode('FAKE_M4A_VOICE_RECORDING_BYTES');

      final jpgSrc = File('${srcDir.path}/photo.jpg')..writeAsBytesSync(jpgBytes);
      final gifSrc = File('${srcDir.path}/anim.gif')..writeAsBytesSync(gifBytes);
      final voiceSrc = File('${srcDir.path}/voice.m4a')
        ..writeAsBytesSync(voiceBytes);

      final pJpg = await CardStorageService.persistMediaFile(
        jpgSrc.path,
        cardId: 'card_water',
        mediaType: 'images',
      );
      final pGif = await CardStorageService.persistMediaFile(
        gifSrc.path,
        cardId: 'card_eat',
        mediaType: 'images',
      );
      final pVoice = await CardStorageService.persistMediaFile(
        voiceSrc.path,
        cardId: 'card_eat',
        mediaType: 'voices',
      );

      final originalCards = <AACCard>[
        AACCard(
          id: 'card_water',
          label: 'Water',
          labelSinhala: 'වතුර',
          labelTamil: 'தண்ணீர்',
          imagePath: pJpg,
          colorValue: 0xFF2196F3,
        ),
        AACCard(
          id: 'folder_needs',
          label: 'Needs',
          labelSinhala: 'අවශ්‍යතා',
          labelTamil: 'தேவைகள்',
          type: 'folder',
          colorValue: 0xFF4CAF50,
          subCards: [
            AACCard(
              id: 'folder_food',
              label: 'Food',
              labelSinhala: 'කෑම',
              labelTamil: 'உணவு',
              type: 'folder',
              colorValue: 0xFFFF9800,
              subCards: [
                AACCard(
                  id: 'card_eat',
                  label: 'Eat',
                  labelSinhala: 'කන්න',
                  labelTamil: 'சாப்பிட',
                  imagePath: pGif,
                  voicePath: pVoice,
                  colorValue: 0xFFFFC107,
                ),
              ],
            ),
          ],
        ),
      ];

      final settings = {
        'selectedCategory': 'Food',
        'isDarkMode': true,
        'offlineAudioCacheEnabled': true,
      };

      final zipBytes = await BackupService.buildBackupZip(
        originalCards,
        settings: settings,
      );
      expect(zipBytes, isNotNull);
      expect(zipBytes!.isNotEmpty, isTrue);

      // Now restore into fresh destination directory
      CardStorageService.docsDirectoryOverride = () async => dstDir;
      final payload = await BackupService.restoreFromZipBytes(zipBytes);

      expect(payload.cards.length, 2);
      expect(payload.settings['selectedCategory'], 'Food');
      expect(payload.settings['isDarkMode'], true);

      // Verify top-level card
      final rWater = payload.cards[0];
      expect(rWater.id, 'card_water');
      expect(rWater.label, 'Water');
      expect(rWater.labelSinhala, 'වතුර');
      expect(rWater.labelTamil, 'தண்ணீர்');
      expect(rWater.imagePath, isNotNull);
      expect(File(rWater.imagePath!).existsSync(), isTrue);
      expect(
        sha256.convert(File(rWater.imagePath!).readAsBytesSync()),
        sha256.convert(jpgBytes),
      );

      // Verify nested folders
      final rNeeds = payload.cards[1];
      expect(rNeeds.type, 'folder');
      expect(rNeeds.subCards.length, 1);

      final rFood = rNeeds.subCards[0];
      expect(rFood.type, 'folder');
      expect(rFood.labelSinhala, 'කෑම');
      expect(rFood.labelTamil, 'உணவு');
      expect(rFood.subCards.length, 1);

      final rEat = rFood.subCards[0];
      expect(rEat.id, 'card_eat');
      expect(rEat.labelSinhala, 'කන්න');
      expect(rEat.labelTamil, 'சாப்பிட');
      expect(rEat.imagePath, isNotNull);
      expect(rEat.imagePath!.endsWith('.gif'), isTrue);
      expect(
        sha256.convert(File(rEat.imagePath!).readAsBytesSync()),
        sha256.convert(gifBytes),
      );
      expect(rEat.voicePath, isNotNull);
      expect(
        sha256.convert(File(rEat.voicePath!).readAsBytesSync()),
        sha256.convert(voiceBytes),
      );
    });

    test('Restores legacy v1.0.2 format (plain JSON list at top-level)',
        () async {
      final dstDir = Directory.systemTemp.createTempSync('legacy_dst_');
      addTearDown(() {
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
      });
      CardStorageService.docsDirectoryOverride = () async => dstDir;

      final archive = Archive();
      final legacyCardsJson = jsonEncode([
        {
          'id': 'legacy_1',
          'label': 'Hello',
          'labelSinhala': 'ආයුබෝවන්',
          'labelTamil': 'வணக்கம்',
          'type': 'card',
          'category': 'General',
          'colorValue': 0xFFFFFFFF,
          'imagePath': null,
          'voicePath': null,
          'subCards': [],
        }
      ]);
      final data = utf8.encode(legacyCardsJson);
      archive.addFile(ArchiveFile('cards.json', data.length, data));
      final zipBytes = ZipEncoder().encode(archive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards.length, 1);
      expect(payload.cards[0].label, 'Hello');
      expect(payload.cards[0].labelSinhala, 'ආයුබෝවන්');
      expect(payload.cards[0].labelTamil, 'வணக்கம்');
    });

    test('Restores wrapped Map format ({"version": 1, "cards": [...]})',
        () async {
      final dstDir = Directory.systemTemp.createTempSync('wrapped_dst_');
      addTearDown(() {
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
      });
      CardStorageService.docsDirectoryOverride = () async => dstDir;

      final archive = Archive();
      final wrappedJson = jsonEncode({
        'version': 2,
        'exportDate': '2026-11-12T12:00:00Z',
        'cards': [
          {
            'id': 'wrapped_1',
            'label': 'Thank you',
            'labelSinhala': 'ස්තූතියි',
            'labelTamil': 'நன்றி',
            'type': 'card',
            'colorValue': 0xFFFFFFFF,
            'subCards': [],
          }
        ],
      });
      final data = utf8.encode(wrappedJson);
      archive.addFile(ArchiveFile('cards.json', data.length, data));
      final zipBytes = ZipEncoder().encode(archive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards.length, 1);
      expect(payload.cards[0].label, 'Thank you');
      expect(payload.cards[0].labelSinhala, 'ස්තූතියි');
      expect(payload.cards[0].labelTamil, 'நன்றி');
    });

    test('Rejects Zip Slip paths in ZIP entries safely', () async {
      final dstDir = Directory.systemTemp.createTempSync('zip_slip_dst_');
      final canaryFile = File('${dstDir.parent.path}/canary.txt');
      addTearDown(() {
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
        if (canaryFile.existsSync()) canaryFile.deleteSync();
      });
      CardStorageService.docsDirectoryOverride = () async => dstDir;

      final archive = Archive();
      final cardsData = utf8.encode('[]');
      archive.addFile(ArchiveFile('cards.json', cardsData.length, cardsData));

      // Attempt zip-slip entry
      final evilData = utf8.encode('EVIL_PAYLOAD');
      archive.addFile(
        ArchiveFile('../../canary.txt', evilData.length, evilData),
      );

      final zipBytes = ZipEncoder().encode(archive)!;
      final payload = await BackupService.restoreFromZipBytes(zipBytes);

      expect(payload.cards, isEmpty);
      expect(canaryFile.existsSync(), isFalse);
    });

    test('Blocks path traversal in cards.json media references', () async {
      final dstDir = Directory.systemTemp.createTempSync('traversal_dst_');
      final secretFile = File('${dstDir.parent.path}/secret_file.txt')
        ..writeAsStringSync('TOP_SECRET');
      addTearDown(() {
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
        if (secretFile.existsSync()) secretFile.deleteSync();
      });
      CardStorageService.docsDirectoryOverride = () async => dstDir;

      final archive = Archive();
      final evilCardsJson = jsonEncode([
        {
          'id': 'traversal_card',
          'label': 'Secret Card',
          'imagePath': 'files/../../secret_file.txt',
          'voicePath': '/etc/passwd',
          'type': 'card',
          'colorValue': 0xFFFFFFFF,
          'subCards': [],
        }
      ]);
      final data = utf8.encode(evilCardsJson);
      archive.addFile(ArchiveFile('cards.json', data.length, data));
      final zipBytes = ZipEncoder().encode(archive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards.length, 1);
      // Both path traversal attempts must be blocked and sanitized to null
      expect(payload.cards[0].imagePath, isNull);
      expect(payload.cards[0].voicePath, isNull);
    });

    test('Gracefully handles missing media without crashing', () async {
      final dstDir = Directory.systemTemp.createTempSync('missing_media_dst_');
      addTearDown(() {
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
      });
      CardStorageService.docsDirectoryOverride = () async => dstDir;

      final archive = Archive();
      final cardsJson = jsonEncode([
        {
          'id': 'c1',
          'label': 'Card with missing media',
          'imagePath': 'files/non_existent.jpg',
          'voicePath': 'files/non_existent.m4a',
          'type': 'card',
          'colorValue': 0xFFFFFFFF,
          'subCards': [],
        }
      ]);
      final data = utf8.encode(cardsJson);
      archive.addFile(ArchiveFile('cards.json', data.length, data));
      final zipBytes = ZipEncoder().encode(archive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards.length, 1);
      expect(payload.cards[0].imagePath, isNull);
      expect(payload.cards[0].voicePath, isNull);
    });

    test('Corrupted ZIP bytes or invalid JSON return empty payload safely',
        () async {
      final dstDir = Directory.systemTemp.createTempSync('corrupt_dst_');
      addTearDown(() {
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
      });
      CardStorageService.docsDirectoryOverride = () async => dstDir;

      // 1. Empty bytes
      final emptyPayload = await BackupService.restoreFromZipBytes([]);
      expect(emptyPayload.cards, isEmpty);
      expect(emptyPayload.settings, isEmpty);

      // 2. Corrupt garbage bytes
      final garbagePayload = await BackupService.restoreFromZipBytes(
        utf8.encode('NOT_A_ZIP_FILE_AT_ALL'),
      );
      expect(garbagePayload.cards, isEmpty);
      expect(garbagePayload.settings, isEmpty);

      // 3. ZIP with syntax error in cards.json
      final archive = Archive();
      final brokenJson = utf8.encode('{ "cards": [ {"id": 1, ...BROKEN_SYNTAX');
      archive.addFile(ArchiveFile('cards.json', brokenJson.length, brokenJson));
      final zipBytes = ZipEncoder().encode(archive)!;

      final brokenPayload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(brokenPayload.cards, isEmpty);
      expect(brokenPayload.settings, isEmpty);
    });

    test('Duplicate restore idempotence does not collide or crash', () async {
      final srcDir = Directory.systemTemp.createTempSync('idem_src_');
      final dstDir = Directory.systemTemp.createTempSync('idem_dst_');
      addTearDown(() {
        if (srcDir.existsSync()) srcDir.deleteSync(recursive: true);
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
      });

      CardStorageService.docsDirectoryOverride = () async => srcDir;
      final img = File('${srcDir.path}/item.jpg')
        ..writeAsBytesSync(utf8.encode('SAME_IMG'));
      final pImg = await CardStorageService.persistMediaFile(
        img.path,
        cardId: 'c_idem',
        mediaType: 'images',
      );

      final cards = <AACCard>[
        AACCard(
          id: 'c_idem',
          label: 'Item',
          imagePath: pImg,
          colorValue: 0xFF2196F3,
        ),
      ];
      final zipBytes = (await BackupService.buildBackupZip(cards))!;

      // Restore first time
      CardStorageService.docsDirectoryOverride = () async => dstDir;
      final payload1 = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload1.cards.length, 1);
      final firstPath = payload1.cards[0].imagePath!;
      expect(File(firstPath).existsSync(), isTrue);

      // Restore second time
      final payload2 = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload2.cards.length, 1);
      final secondPath = payload2.cards[0].imagePath!;
      expect(File(secondPath).existsSync(), isTrue);
    });
  });
}
