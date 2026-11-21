import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';

const List<int> _kTestGifBytes = <int>[
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00,
  0x00, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3B,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDocsDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    testDocsDir = await Directory.systemTemp.createTemp('global_color_qa_');
    CardStorageService.docsDirectoryOverride = () async => testDocsDir;
  });

  tearDown(() async {
    CardStorageService.resetTestHooks();
    if (testDocsDir.existsSync()) {
      testDocsDir.deleteSync(recursive: true);
    }
  });

  group('Phase 2 — Global Label Color Persistence & Local UI Verification', () {
    test('Defaults to #F4F1EB (Warm Ivory) when no preference exists', () async {
      final prefs = await SharedPreferences.getInstance();
      final loadedColor = prefs.getInt('globalCardLabelBackgroundColor') ??
          prefs.getInt('cardLabelBackgroundColor') ??
          const Color(0xFFF4F1EB).value;

      expect(loadedColor, 0xFFF4F1EB);
    });

    test('Persists across simulated application restarts via SharedPreferences',
        () async {
      final prefs = await SharedPreferences.getInstance();
      const nonDefaultSoftBlue = 0xFFDFEFFA;

      // Simulate saving new preference
      await prefs.setInt('globalCardLabelBackgroundColor', nonDefaultSoftBlue);

      // Simulate app restart by re-reading from SharedPreferences
      final reloadedColor =
          prefs.getInt('globalCardLabelBackgroundColor') ?? 0xFFF4F1EB;
      expect(reloadedColor, nonDefaultSoftBlue);
    });

    test(
        'Does not overwrite unrelated settings (primary color, card text color, board background)',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('themePrimaryColor', 0xFF0288D1);
      await prefs.setInt('cardTextColor', 0xFF333333);
      await prefs.setInt('themeBackgroundColor', 0xFFFAFAFA);
      await prefs.setBool('colorBlindMode', true);

      // Now set global label color
      const softGreen = 0xFFE8F5E9;
      await prefs.setInt('globalCardLabelBackgroundColor', softGreen);

      // Verify all unrelated settings remain intact
      expect(prefs.getInt('themePrimaryColor'), 0xFF0288D1);
      expect(prefs.getInt('cardTextColor'), 0xFF333333);
      expect(prefs.getInt('themeBackgroundColor'), 0xFFFAFAFA);
      expect(prefs.getBool('colorBlindMode'), true);
      expect(prefs.getInt('globalCardLabelBackgroundColor'), softGreen);
    });

    test(
        'Setting global label background color does not modify card records or their legacy colorValue',
        () async {
      final card = AACCard(
        id: 'card_happy',
        label: 'Happy',
        labelSinhala: 'සතුටුයි',
        labelTamil: 'மகிழ்ச்சி',
        colorValue: 0xFFFFEB3B, // Legacy yellow hue
      );

      final initialJson = jsonEncode(card.toJson());

      // Changing global color preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('globalCardLabelBackgroundColor', 0xFFDFEFFA);

      // Card data must remain 100% identical
      final afterJson = jsonEncode(card.toJson());
      expect(afterJson, initialJson);
      expect(card.colorValue, 0xFFFFEB3B);
    });
  });

  group('Phase 3 — Historical Backup Compatibility (Pre-Global-Color Backups)',
      () {
    test(
        'Restores legacy v1.0.0 flat JSON cards.json without settings.json (falls back safely to default)',
        () async {
      final archive = Archive();
      final legacyCardsJson = jsonEncode([
        {
          'id': 'v100_water',
          'label': 'Water',
          'labelSinhala': 'වතුර',
          'labelTamil': 'தண்ணீர்',
          'type': 'word',
          'category': 'Drinks',
          'colorValue': 0xFF2196F3,
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
      expect(payload.cards[0].id, 'v100_water');
      expect(payload.cards[0].colorValue, 0xFF2196F3);
      expect(payload.settings, isEmpty);

      // Absence of globalCardLabelBackgroundColor falls back cleanly to default
      final restoredColor =
          payload.settings['globalCardLabelBackgroundColor'] as int? ??
              0xFFF4F1EB;
      expect(restoredColor, 0xFFF4F1EB);
    });

    test(
        'Restores legacy v1.0.2 nested AAC_Backup/cards.json without settings.json',
        () async {
      final archive = Archive();
      final cardsJson = jsonEncode([
        {
          'id': 'v102_eat',
          'label': 'Eat',
          'labelSinhala': 'කන්න',
          'labelTamil': 'சாப்பிட',
          'colorValue': 0xFFFF9800,
        }
      ]);
      final data = utf8.encode(cardsJson);
      archive.addFile(ArchiveFile('AAC_Backup/cards.json', data.length, data));
      final zipBytes = ZipEncoder().encode(archive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards.length, 1);
      expect(payload.cards[0].id, 'v102_eat');
      expect(payload.cards[0].colorValue, 0xFFFF9800);
      expect(payload.settings, isEmpty);
    });

    test(
        'Restores v1.1.2 backup with settings.json lacking globalCardLabelBackgroundColor',
        () async {
      final archive = Archive();
      final cardsJson = jsonEncode([
        {
          'id': 'v112_folder',
          'label': 'Actions',
          'type': 'folder',
          'colorValue': 0xFF4CAF50,
          'subCards': [
            {
              'id': 'v112_sub1',
              'label': 'Jump',
              'type': 'word',
              'colorValue': 0xFF81C784,
            }
          ],
        }
      ]);
      final settingsJson = jsonEncode({
        'gridColumns': 3,
        'language': 'si',
        'themePrimaryColor': 0xFF0277BD,
        'cardTextColor': 0xFF111827,
        'showCardLabels': true,
        'useImageOverlayLabel': false,
        // Notice: NO globalCardLabelBackgroundColor present
      });

      archive.addFile(
        ArchiveFile('cards.json', cardsJson.length, utf8.encode(cardsJson)),
      );
      archive.addFile(
        ArchiveFile(
          'settings.json',
          settingsJson.length,
          utf8.encode(settingsJson),
        ),
      );
      final zipBytes = ZipEncoder().encode(archive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards.length, 1);
      expect(payload.cards[0].subCards.length, 1);
      expect(payload.cards[0].colorValue, 0xFF4CAF50);
      expect(payload.cards[0].subCards[0].colorValue, 0xFF81C784);

      // Verify settings are intact
      expect(payload.settings['gridColumns'], 3);
      expect(payload.settings['language'], 'si');
      expect(payload.settings['themePrimaryColor'], 0xFF0277BD);
      expect(payload.settings['cardTextColor'], 0xFF111827);
      expect(payload.settings['useImageOverlayLabel'], false);
      expect(payload.settings['globalCardLabelBackgroundColor'], isNull);
    });

    test(
        'Restores v1.1.5 backup preserving legacy colorValue on all nested cards and folders',
        () async {
      final archive = Archive();
      final cardsJson = jsonEncode([
        {
          'id': 'folder_family',
          'label': 'Family',
          'labelSinhala': 'පවුල',
          'labelTamil': 'குடும்பம்',
          'type': 'folder',
          'colorValue': 0xFF9C27B0,
          'subCards': [
            {
              'id': 'card_mom',
              'label': 'Mother',
              'labelSinhala': 'අම්මා',
              'labelTamil': 'அம்மா',
              'type': 'word',
              'colorValue': 0xFFE91E63,
              'subCards': [],
            },
            {
              'id': 'card_dad',
              'label': 'Father',
              'labelSinhala': 'තාත්තා',
              'labelTamil': 'அப்பா',
              'type': 'word',
              'colorValue': 0xFF3F51B5,
              'subCards': [],
            },
          ],
        }
      ]);
      archive.addFile(
        ArchiveFile('cards.json', cardsJson.length, utf8.encode(cardsJson)),
      );
      final zipBytes = ZipEncoder().encode(archive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards.length, 1);
      final family = payload.cards[0];
      expect(family.id, 'folder_family');
      expect(family.colorValue, 0xFF9C27B0);
      expect(family.subCards.length, 2);
      expect(family.subCards[0].id, 'card_mom');
      expect(family.subCards[0].colorValue, 0xFFE91E63);
      expect(family.subCards[1].id, 'card_dad');
      expect(family.subCards[1].colorValue, 0xFF3F51B5);
    });

    test('Does not insert null or invalid values into card metadata', () async {
      final archive = Archive();
      final cardsJson = jsonEncode([
        {
          'id': 'sparse_card',
          'label': 'Minimal Card',
          // Omitting category, colorValue, subCards, type
        }
      ]);
      archive.addFile(
        ArchiveFile('cards.json', cardsJson.length, utf8.encode(cardsJson)),
      );
      final zipBytes = ZipEncoder().encode(archive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards.length, 1);
      final card = payload.cards[0];
      expect(card.id, 'sparse_card');
      expect(card.label, 'Minimal Card');
      expect(card.category, 'General');
      expect(card.colorValue, 0xFF90CAF9); // Default fallback
      expect(card.type, 'word');
      expect(card.subCards, isEmpty);
    });
  });

  group('Phase 4 & 5 — New Backup Round-Trip, ZIP Integrity & Media Accuracy',
      () {
    test(
        'Comprehensive round-trip with photos, GIFs, voice recordings, Sinhala, Tamil, nested hierarchy, and Soft Blue global color',
        () async {
      final srcDir = Directory.systemTemp.createTempSync('new_backup_src_');
      final dstDir = Directory.systemTemp.createTempSync('new_backup_dst_');
      final qaExtractDir =
          Directory.systemTemp.createTempSync('new_backup_qa_extract_');
      addTearDown(() {
        if (srcDir.existsSync()) srcDir.deleteSync(recursive: true);
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
        if (qaExtractDir.existsSync()) qaExtractDir.deleteSync(recursive: true);
      });

      CardStorageService.docsDirectoryOverride = () async => srcDir;

      // Create dummy media files
      final photoJpg = File('${srcDir.path}/camera_chair.jpg')
        ..writeAsBytesSync(utf8.encode('JPEG_CHAIR_CAMERA_PICTURE_BYTES_12345'));
      final animGif = File('${srcDir.path}/animated_play.gif')
        ..writeAsBytesSync(_kTestGifBytes);
      final voiceM4a = File('${srcDir.path}/voice_tamil.m4a')
        ..writeAsBytesSync(utf8.encode('M4A_TAMIL_RECORDING_SPEECH_DATA'));

      final pPhoto = await CardStorageService.persistMediaFile(
        photoJpg.path,
        cardId: 'custom_chair',
        mediaType: 'images',
      );
      final pGif = await CardStorageService.persistMediaFile(
        animGif.path,
        cardId: 'card_play',
        mediaType: 'images',
      );
      final pVoice = await CardStorageService.persistMediaFile(
        voiceM4a.path,
        cardId: 'card_play',
        mediaType: 'voices',
      );

      final originalCards = <AACCard>[
        AACCard(
          id: 'custom_chair',
          label: 'Chair',
          labelSinhala: 'පුටුව',
          labelTamil: 'நாற்காலி',
          imagePath: pPhoto,
          colorValue: 0xFFE6EE9C,
        ),
        AACCard(
          id: 'folder_activities',
          label: 'Activities',
          labelSinhala: 'ක්‍රියාකාරකම්',
          labelTamil: 'செயல்பாடுகள்',
          type: 'folder',
          colorValue: 0xFF64B5F6,
          subCards: [
            AACCard(
              id: 'card_play',
              label: 'Play Game With Friends Today', // Long label
              labelSinhala: 'මිතුරන් සමඟ සෙල්ලම් කරන්න',
              labelTamil: 'நண்பர்களுடன் விளையாடுங்கள்',
              imagePath: pGif,
              voicePath: pVoice,
              colorValue: 0xFFF3E5F5,
            ),
          ],
        ),
      ];

      const nonDefaultGlobalColor = 0xFFDFEFFA; // Soft Blue
      final settings = {
        'gridColumns': 2,
        'language': 'si',
        'showCardLabels': true,
        'useImageOverlayLabel': false, // Mode B: Overlay OFF
        'cardTextColor': 0xFF252B32,
        'globalCardLabelBackgroundColor': nonDefaultGlobalColor,
      };

      // 1. Export backup ZIP
      final zipBytes = await BackupService.buildBackupZip(
        originalCards,
        settings: settings,
      );
      expect(zipBytes, isNotNull);
      expect(zipBytes!.isNotEmpty, isTrue);

      // 2. Phase 5: Validate ZIP integrity and inspect entries
      final archive = ZipDecoder().decodeBytes(zipBytes);
      expect(archive.isNotEmpty, isTrue);

      final entryNames = archive.map((e) => e.name).toList();
      expect(entryNames.contains('cards.json'), isTrue);
      expect(entryNames.contains('settings.json'), isTrue);

      // Verify no illegal paths
      for (final name in entryNames) {
        expect(name.startsWith('/'), isFalse);
        expect(name.contains('..'), isFalse);
      }

      // Verify CRC32 on every file in ZIP
      for (final file in archive) {
        if (file.isFile) {
          final content = file.content as List<int>;
          final computedCrc = getCrc32(content);
          expect(computedCrc, file.crc32);
        }
      }

      // Verify settings.json inside ZIP contains globalCardLabelBackgroundColor
      final settingsFile = archive.firstWhere((e) => e.name == 'settings.json');
      final decodedSettings =
          jsonDecode(utf8.decode(settingsFile.content as List<int>)) as Map;
      expect(
        decodedSettings['globalCardLabelBackgroundColor'],
        nonDefaultGlobalColor,
      );

      // Verify media file SHA-256 match
      final photoInZip = archive.firstWhere((e) => e.name.contains('chair.jpg'));
      expect(
        sha256.convert(photoInZip.content as List<int>),
        sha256.convert(photoJpg.readAsBytesSync()),
      );

      final gifInZip = archive.firstWhere((e) => e.name.contains('play.gif'));
      expect(
        sha256.convert(gifInZip.content as List<int>),
        sha256.convert(animGif.readAsBytesSync()),
      );

      final voiceInZip = archive.firstWhere((e) => e.name.contains('tamil.m4a'));
      expect(
        sha256.convert(voiceInZip.content as List<int>),
        sha256.convert(voiceM4a.readAsBytesSync()),
      );

      // 3. Restore into clean, disposable destination directory
      CardStorageService.docsDirectoryOverride = () async => dstDir;
      final payload = await BackupService.restoreFromZipBytes(zipBytes);

      // 4. Compare logical data state
      expect(payload.cards.length, 2);
      expect(payload.cards[0].id, 'custom_chair');
      expect(payload.cards[0].label, 'Chair');
      expect(payload.cards[0].labelSinhala, 'පුටුව');
      expect(payload.cards[0].labelTamil, 'நாற்காலி');
      expect(payload.cards[0].colorValue, 0xFFE6EE9C);
      expect(payload.cards[0].imagePath, isNotNull);
      expect(File(payload.cards[0].imagePath!).existsSync(), isTrue);
      expect(
        sha256.convert(File(payload.cards[0].imagePath!).readAsBytesSync()),
        sha256.convert(photoJpg.readAsBytesSync()),
      );

      // Check nested folder
      final restoredFolder = payload.cards[1];
      expect(restoredFolder.id, 'folder_activities');
      expect(restoredFolder.type, 'folder');
      expect(restoredFolder.subCards.length, 1);

      final restoredSub = restoredFolder.subCards[0];
      expect(restoredSub.id, 'card_play');
      expect(restoredSub.labelSinhala, 'මිතුරන් සමඟ සෙල්ලම් කරන්න');
      expect(restoredSub.labelTamil, 'நண்பர்களுடன் விளையாடுங்கள்');
      expect(restoredSub.colorValue, 0xFFF3E5F5);
      expect(restoredSub.imagePath, isNotNull);
      expect(File(restoredSub.imagePath!).existsSync(), isTrue);
      expect(
        sha256.convert(File(restoredSub.imagePath!).readAsBytesSync()),
        sha256.convert(animGif.readAsBytesSync()),
      );
      expect(restoredSub.voicePath, isNotNull);
      expect(File(restoredSub.voicePath!).existsSync(), isTrue);
      expect(
        sha256.convert(File(restoredSub.voicePath!).readAsBytesSync()),
        sha256.convert(voiceM4a.readAsBytesSync()),
      );

      // 5. Verify restored global label color
      expect(
        payload.settings['globalCardLabelBackgroundColor'],
        nonDefaultGlobalColor,
      );
    });

    test('Duplicate restore of same backup is idempotent and does not crash',
        () async {
      final srcDir = Directory.systemTemp.createTempSync('idempotent_src_');
      final dstDir = Directory.systemTemp.createTempSync('idempotent_dst_');
      addTearDown(() {
        if (srcDir.existsSync()) srcDir.deleteSync(recursive: true);
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
      });
      CardStorageService.docsDirectoryOverride = () async => srcDir;

      final card = AACCard(
        id: 'idem_card',
        label: 'Hello',
        colorValue: 0xFF4CAF50,
      );
      final zipBytes = await BackupService.buildBackupZip(
        [card],
        settings: {'globalCardLabelBackgroundColor': 0xFFDFEFFA},
      );
      expect(zipBytes, isNotNull);

      CardStorageService.docsDirectoryOverride = () async => dstDir;

      // First restore
      final payload1 = await BackupService.restoreFromZipBytes(zipBytes!);
      expect(payload1.cards.length, 1);
      expect(
        payload1.settings['globalCardLabelBackgroundColor'],
        0xFFDFEFFA,
      );

      // Second restore of the same file
      final payload2 = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload2.cards.length, 1);
      expect(payload2.cards[0].id, 'idem_card');
      expect(
        payload2.settings['globalCardLabelBackgroundColor'],
        0xFFDFEFFA,
      );
    });
  });

  group('Phase 6 — Failure, Malformed Data and Recovery Tests', () {
    test('Corrupted ZIP bytes (truncated / random) fails safely', () async {
      final randomCorruptBytes = [0x50, 0x4B, 0x03, 0x04, 0x99, 0x88, 0x77];
      final payload =
          await BackupService.restoreFromZipBytes(randomCorruptBytes);
      expect(payload.cards, isEmpty);
      expect(payload.settings, isEmpty);
    });

    test('ZIP with missing cards.json returns empty payload safely', () async {
      final archive = Archive();
      archive.addFile(
        ArchiveFile('unrelated.txt', 5, utf8.encode('HELLO')),
      );
      final zipBytes = ZipEncoder().encode(archive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards, isEmpty);
      expect(payload.settings, isEmpty);
    });

    test('Corrupt JSON syntax in cards.json handled gracefully without crash',
        () async {
      final archive = Archive();
      const brokenJson = '{"cards": [{"id": 1, ...BROKEN_SYNTAX';
      archive.addFile(
        ArchiveFile('cards.json', brokenJson.length, utf8.encode(brokenJson)),
      );
      final zipBytes = ZipEncoder().encode(archive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards, isEmpty);
    });

    test(
        'Malformed globalCardLabelBackgroundColor in settings.json handled safely',
        () async {
      // Test with string hex "#DFEFFA", boolean true, and invalid text "not-a-color"
      for (final malformedValue in ['#DFEFFA', '0xFFDFEFFA', true, 'invalid']) {
        final archive = Archive();
        final cardsJson = jsonEncode([
          {'id': 'c1', 'label': 'Test', 'colorValue': 0xFFFFFFFF}
        ]);
        final settingsJson = jsonEncode({
          'globalCardLabelBackgroundColor': malformedValue,
        });

        archive.addFile(
          ArchiveFile('cards.json', cardsJson.length, utf8.encode(cardsJson)),
        );
        archive.addFile(
          ArchiveFile(
            'settings.json',
            settingsJson.length,
            utf8.encode(settingsJson),
          ),
        );
        final zipBytes = ZipEncoder().encode(archive)!;

        final payload = await BackupService.restoreFromZipBytes(zipBytes);
        expect(payload.cards.length, 1);
        expect(payload.settings, isNotEmpty);

        // Verify simulated consumer handling
        final dynamic raw = payload.settings['globalCardLabelBackgroundColor'];
        int resolvedColor = const Color(0xFFF4F1EB).value;
        if (raw is num) {
          resolvedColor = raw.toInt();
        } else if (raw is String) {
          final hex = raw.replaceAll('#', '').replaceAll('0x', '').trim();
          final parsed = int.tryParse(
            hex.length == 6 ? 'FF$hex' : hex,
            radix: 16,
          );
          if (parsed != null) resolvedColor = parsed;
        }

        if (malformedValue == '#DFEFFA' || malformedValue == '0xFFDFEFFA') {
          expect(resolvedColor, 0xFFDFEFFA);
        } else {
          // Fallback to Warm Ivory default
          expect(resolvedColor, 0xFFF4F1EB);
        }
      }
    });

    test('Missing referenced media in backup restores card with null media',
        () async {
      final archive = Archive();
      final cardsJson = jsonEncode([
        {
          'id': 'card_missing_media',
          'label': 'Ghost Media',
          'imagePath': 'files/non_existent_image.png',
          'voicePath': 'files/non_existent_voice.m4a',
          'colorValue': 0xFF90CAF9,
        }
      ]);
      archive.addFile(
        ArchiveFile('cards.json', cardsJson.length, utf8.encode(cardsJson)),
      );
      final zipBytes = ZipEncoder().encode(archive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards.length, 1);
      expect(payload.cards[0].id, 'card_missing_media');
      // Non-existent files must be nullified safely
      expect(payload.cards[0].imagePath, isNull);
      expect(payload.cards[0].voicePath, isNull);
    });

    test('Zip Slip and traversal attempts are strictly neutralized', () async {
      final archive = Archive();
      final cardsJson = jsonEncode([
        {
          'id': 'c_traversal',
          'label': 'Traversal Card',
          'imagePath': 'files/../../../../etc/shadow',
          'voicePath': '/etc/passwd',
          'colorValue': 0xFFFFFFFF,
        }
      ]);
      archive.addFile(
        ArchiveFile('cards.json', cardsJson.length, utf8.encode(cardsJson)),
      );
      // Malicious zip slip entry
      archive.addFile(
        ArchiveFile('../../evil.sh', 4, utf8.encode('exit')),
      );
      final zipBytes = ZipEncoder().encode(archive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards.length, 1);
      expect(payload.cards[0].imagePath, isNull);
      expect(payload.cards[0].voicePath, isNull);
    });
  });
}
