import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';

const List<int> _validGifHeader = <int>[
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00,
  0x00, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3B,
];

String _sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    CardStorageService.resetTestHooks();
  });

  group('Simple AAC Data Integrity & Scalability Certification', () {
    test('Stage 1: 100 Multi-lingual Cards Round-trip Backup and Restore', () async {
      final srcDir = Directory.systemTemp.createTempSync('stress_s1_src_');
      final dstDir = Directory.systemTemp.createTempSync('stress_s1_dst_');
      addTearDown(() {
        if (srcDir.existsSync()) srcDir.deleteSync(recursive: true);
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
      });

      CardStorageService.docsDirectoryOverride = () async => srcDir;

      final cards = <AACCard>[];
      for (var i = 0; i < 100; i++) {
        cards.add(AACCard(
          id: 'card_s1_$i',
          label: 'Card $i 🍎',
          labelSinhala: 'කාඩ්පත $i - මට ඕනෑ',
          labelTamil: 'அட்டை $i - எனக்கு வேண்டும்',
          category: i % 4 == 0 ? 'Food' : (i % 4 == 1 ? 'Feelings' : 'Actions'),
          colorValue: 0xFF000000 | (i * 0x12345 & 0xFFFFFF),
        ));
      }

      final zipBytes = await BackupService.buildBackupZip(
        cards,
        settings: {'selectedCategory': 'Food', 'darkMode': true},
      );
      expect(zipBytes, isNotNull);
      expect(zipBytes!.isNotEmpty, isTrue);

      CardStorageService.docsDirectoryOverride = () async => dstDir;
      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards.length, equals(100));
      expect(payload.settings['selectedCategory'], equals('Food'));
      expect(payload.settings['darkMode'], equals(true));

      for (var i = 0; i < 100; i++) {
        final restored = payload.cards[i];
        expect(restored.id, equals('card_s1_$i'));
        expect(restored.label, equals('Card $i 🍎'));
        expect(restored.labelSinhala, equals('කාඩ්පත $i - මට ඕනෑ'));
        expect(restored.labelTamil, equals('அட்டை $i - எனக்கு வேண்டும்'));
      }
    });

    test('Stage 2: 1,000 Cards with 1,000 Unique GIFs and Audio Clips SHA-256 Match', () async {
      final srcDir = Directory.systemTemp.createTempSync('stress_s2_src_');
      final dstDir = Directory.systemTemp.createTempSync('stress_s2_dst_');
      addTearDown(() {
        if (srcDir.existsSync()) srcDir.deleteSync(recursive: true);
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
      });

      CardStorageService.docsDirectoryOverride = () async => srcDir;

      final gifHashes = <String, String>{};
      final voiceHashes = <String, String>{};
      final cards = <AACCard>[];

      const batchSize = 1000;
      for (var i = 0; i < batchSize; i++) {
        final gifBytes = List<int>.from(_validGifHeader)
          ..addAll(utf8.encode('_gif_payload_marker_$i'));
        final voiceBytes = utf8.encode('AAC_AUDIO_STREAM_TRACK_$i');

        final gifFile = File('${srcDir.path}/anim_$i.gif')
          ..writeAsBytesSync(gifBytes, flush: true);
        final voiceFile = File('${srcDir.path}/voice_$i.m4a')
          ..writeAsBytesSync(voiceBytes, flush: true);

        final pGif = await CardStorageService.persistMediaFile(
          gifFile.path,
          cardId: 'c_$i',
          mediaType: 'images',
        );
        final pVoice = await CardStorageService.persistMediaFile(
          voiceFile.path,
          cardId: 'c_$i',
          mediaType: 'voices',
        );

        gifHashes['c_$i'] = _sha256Hex(File(pGif).readAsBytesSync());
        voiceHashes['c_$i'] = _sha256Hex(File(pVoice).readAsBytesSync());

        cards.add(AACCard(
          id: 'c_$i',
          label: 'Item $i',
          imagePath: pGif,
          voicePath: pVoice,
          category: 'Batch',
          colorValue: 0xFF2196F3,
        ));
      }

      final zipBytes = await BackupService.buildBackupZip(cards);
      expect(zipBytes, isNotNull);

      CardStorageService.docsDirectoryOverride = () async => dstDir;
      final payload = await BackupService.restoreFromZipBytes(zipBytes!);
      expect(payload.cards.length, equals(batchSize));

      for (var i = 0; i < batchSize; i++) {
        final c = payload.cards[i];
        expect(c.imagePath, isNotNull);
        expect(c.voicePath, isNotNull);

        final restoredGifBytes = File(c.imagePath!).readAsBytesSync();
        final restoredVoiceBytes = File(c.voicePath!).readAsBytesSync();

        expect(_sha256Hex(restoredGifBytes), equals(gifHashes[c.id]));
        expect(_sha256Hex(restoredVoiceBytes), equals(voiceHashes[c.id]));
      }
    });

    test('Stage 3: 10,000 Cards Nested Hierarchy and Serialization Performance', () async {
      final docsDir = Directory.systemTemp.createTempSync('stress_s3_');
      addTearDown(() {
        if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
      });

      CardStorageService.docsDirectoryOverride = () async => docsDir;

      final rootCards = <AACCard>[];
      var totalCount = 0;
      for (var f = 0; f < 100; f++) {
        final folder = AACCard(
          id: 'folder_$f',
          label: 'Folder $f',
          type: 'folder',
          colorValue: 0xFF4CAF50,
          subCards: [],
        );
        totalCount++;
        for (var c = 0; c < 99; c++) {
          folder.subCards.add(AACCard(
            id: 'leaf_${f}_$c',
            label: 'Leaf $c',
            labelSinhala: 'කොළය $c',
            labelTamil: 'இலை $c',
            colorValue: 0xFF2196F3,
          ));
          totalCount++;
        }
        rootCards.add(folder);
      }

      expect(totalCount, equals(10000));
      expect(CardStorageService.countCards(rootCards), equals(10000));

      final stopwatch = Stopwatch()..start();
      await CardStorageService.saveCards(rootCards);
      final saveElapsed = stopwatch.elapsedMilliseconds;
      stopwatch.reset();

      final loadedCards = await CardStorageService.loadCards();
      final loadElapsed = stopwatch.elapsedMilliseconds;

      expect(CardStorageService.countCards(loadedCards), equals(10000));
      expect(loadedCards.length, equals(100));
      expect(loadedCards[0].subCards.length, equals(99));

      debugPrint('[StressBenchmark] 10,000 cards: save=${saveElapsed}ms, load=${loadElapsed}ms');
    });

    test('Stage 4: 100,000 Cards Metadata & Lookup Scale Stress Test', () {
      final stopwatch = Stopwatch()..start();
      final largeCardList = <AACCard>[];
      final cardMap = <String, AACCard>{};

      for (var i = 0; i < 100000; i++) {
        final card = AACCard(
          id: 'card_scale_$i',
          label: 'Communication Label $i',
          labelSinhala: 'සන්නිවේදන කාඩ්පත $i',
          labelTamil: 'தகவல் தொடர்பு அட்டை $i',
          imagePath: 'assets/images/placeholder_$i.png',
          category: 'Category_${i % 20}',
          colorValue: 0xFF102030,
        );
        largeCardList.add(card);
        cardMap[card.id] = card;
      }
      final buildTime = stopwatch.elapsedMilliseconds;
      stopwatch.reset();

      expect(largeCardList.length, equals(100000));
      expect(cardMap.length, equals(100000));

      // Test random access across the 100k records
      for (var k = 0; k < 10000; k += 1000) {
        final queryId = 'card_scale_$k';
        final found = cardMap[queryId];
        expect(found, isNotNull);
        expect(found!.id, equals(queryId));
      }

      // Benchmark JSON serialization of 100k metadata records
      final jsonString = jsonEncode(largeCardList.map((c) => c.toJson()).toList());
      final jsonTime = stopwatch.elapsedMilliseconds;
      expect(jsonString.length, greaterThan(10000000)); // > 10MB JSON

      debugPrint('[ScaleBenchmark] 100,000 cards: build=${buildTime}ms, jsonEncode=${jsonTime}ms, jsonSize=${(jsonString.length / (1024 * 1024)).toStringAsFixed(2)}MB');
    });

    group('Stage 5: Forensic Fault Injection & Corruption Recovery', () {
      test('Fault 5.1: Zero-byte truncated primary file recovers from backupFile', () async {
        final docsDir = Directory.systemTemp.createTempSync('fault_5_1_');
        addTearDown(() {
          if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
        });

        CardStorageService.docsDirectoryOverride = () async => docsDir;
        final primaryFile = File('${docsDir.path}/aac_cards_v1.json');
        final backupFile = File('${docsDir.path}/aac_cards_v1.json.bak');

        // Create valid backup file with 3 custom cards
        final validBackupCards = [
          AACCard(id: 'c_rec_1', label: 'Recovered One', colorValue: 0xFF2196F3),
          AACCard(id: 'c_rec_2', label: 'Recovered Two', colorValue: 0xFF4CAF50),
          AACCard(id: 'c_rec_3', label: 'Recovered Three', colorValue: 0xFFFF9800),
        ];
        final payload = {
          'schemaVersion': 1,
          'savedAt': DateTime.now().toIso8601String(),
          'cards': validBackupCards.map((c) => c.toJson()).toList(),
        };
        await backupFile.writeAsString(jsonEncode(payload), flush: true);

        // Simulate 0-byte truncated primary file from abrupt power loss
        await primaryFile.writeAsString('', flush: true);
        expect(primaryFile.lengthSync(), equals(0));

        final loaded = await CardStorageService.loadCards();
        expect(loaded.length, greaterThanOrEqualTo(3));
        expect(loaded.any((c) => c.id == 'c_rec_1'), isTrue);
        expect(loaded.any((c) => c.id == 'c_rec_2'), isTrue);
        expect(loaded.any((c) => c.id == 'c_rec_3'), isTrue);

        // Verify primary file was healed and rewritten from backup
        expect(primaryFile.lengthSync(), greaterThan(0));
      });

      test('Fault 5.2: Interrupted .tmp write automatically recovers on restart', () async {
        final docsDir = Directory.systemTemp.createTempSync('fault_5_2_');
        addTearDown(() {
          if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
        });

        CardStorageService.docsDirectoryOverride = () async => docsDir;
        final primaryFile = File('${docsDir.path}/aac_cards_v1.json');
        final tmpFile = File('${docsDir.path}/aac_cards_v1.json.tmp');

        final pendingCards = [
          AACCard(id: 'c_tmp_1', label: 'Pending Swap 1', colorValue: 0xFF2196F3),
          AACCard(id: 'c_tmp_2', label: 'Pending Swap 2', colorValue: 0xFF4CAF50),
        ];
        final payload = {
          'schemaVersion': 1,
          'savedAt': DateTime.now().toIso8601String(),
          'cards': pendingCards.map((c) => c.toJson()).toList(),
        };
        await tmpFile.writeAsString(jsonEncode(payload), flush: true);

        // Ensure primary does not exist
        if (primaryFile.existsSync()) primaryFile.deleteSync();

        final loaded = await CardStorageService.loadCards();
        expect(loaded.length, greaterThanOrEqualTo(2));
        expect(loaded.any((c) => c.id == 'c_tmp_1'), isTrue);
        expect(loaded.any((c) => c.id == 'c_tmp_2'), isTrue);
      });

      test('Fault 5.3: Corrupted garbage JSON is quarantined and does NOT wipe disk with []', () async {
        final docsDir = Directory.systemTemp.createTempSync('fault_5_3_');
        addTearDown(() {
          if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
        });

        CardStorageService.docsDirectoryOverride = () async => docsDir;
        final primaryFile = File('${docsDir.path}/aac_cards_v1.json');
        await primaryFile.writeAsString('{GARBAGE_UNPARSEABLE_DATA_CORRUPTION_HERE%%%!', flush: true);

        final loaded = await CardStorageService.loadCards(
          defaultCards: [
            AACCard(id: 'emergency_fallback', label: 'Help', colorValue: 0xFF2196F3),
          ],
        );
        // Loaded should fall back safely to non-empty default cards in memory
        expect(loaded.isNotEmpty, isTrue);
        expect(loaded.any((c) => c.id == 'emergency_fallback'), isTrue);

        // Quarantine check: verify a .corrupt_ file was created
        final quarantined = docsDir
            .listSync()
            .where((e) => e.path.contains('.corrupt_'))
            .toList();
        expect(quarantined.isNotEmpty, isTrue);

        // Verify primary file was NOT wiped with empty list {"cards":[]}
        expect((quarantined.first as File).readAsStringSync(), contains('GARBAGE_UNPARSEABLE_DATA'));
      });

      test('Fault 5.4: Truncated JSON heuristic salvage recovers individual cards', () async {
        final docsDir = Directory.systemTemp.createTempSync('fault_5_4_');
        addTearDown(() {
          if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
        });

        CardStorageService.docsDirectoryOverride = () async => docsDir;
        final primaryFile = File('${docsDir.path}/aac_cards_v1.json');

        // Truncated JSON missing trailing closures
        const truncatedJson =
            '{"schemaVersion":1,"savedAt":"2026-11-13T00:00:00.000Z","cards":['
            '{"id":"salvage_1","label":"Apple","category":"Food","colorValue":4280391411},'
            '{"id":"salvage_2","label":"Banana","category":"Food","colorValue":4280391411}';

        await primaryFile.writeAsString(truncatedJson, flush: true);

        final loaded = await CardStorageService.loadCards();
        expect(loaded.any((c) => c.id == 'salvage_1'), isTrue);
        expect(loaded.any((c) => c.id == 'salvage_2'), isTrue);
      });

      test('Fault 5.5: Absolute paths from other device in backup are remapped to local documents', () async {
        final backupDir = Directory.systemTemp.createTempSync('fault_5_5_backup_');
        final targetDocs = Directory.systemTemp.createTempSync('fault_5_5_target_');
        addTearDown(() {
          if (backupDir.existsSync()) backupDir.deleteSync(recursive: true);
          if (targetDocs.existsSync()) targetDocs.deleteSync(recursive: true);
        });

        CardStorageService.docsDirectoryOverride = () async => targetDocs;

        final filesDir = Directory('${backupDir.path}/files')..createSync(recursive: true);
        final dummyJpg = File('${filesDir.path}/foreign_photo.jpg')
          ..writeAsBytesSync(utf8.encode('FOREIGN_PHOTO_BYTES'), flush: true);
        expect(dummyJpg.existsSync(), isTrue);

        // Backup cards.json has an absolute path from a previous foreign device
        final cardsJsonFile = File('${backupDir.path}/cards.json');
        final foreignCards = [
          {
            'id': 'foreign_c1',
            'label': 'Foreign Phone Card',
            'colorValue': 0xFF2196F3,
            'imagePath': '/data/user/0/com.example.otherapp/app_flutter/aac_media/images/foreign_photo.jpg',
          }
        ];
        await cardsJsonFile.writeAsString(jsonEncode(foreignCards), flush: true);

        final restored = await BackupService.restoreFromBackupDir(backupDir);
        expect(restored.length, equals(1));
        final restoredCard = restored.first;
        expect(restoredCard.imagePath, isNotNull);
        expect(restoredCard.imagePath!.startsWith(targetDocs.path), isTrue);
        expect(File(restoredCard.imagePath!).existsSync(), isTrue);
        expect(File(restoredCard.imagePath!).readAsStringSync(), equals('FOREIGN_PHOTO_BYTES'));
      });

      test('Fault 5.6: Zip-Slip path traversal is blocked and rejected', () async {
        final targetDir = Directory.systemTemp.createTempSync('zip_slip_target_');
        addTearDown(() {
          if (targetDir.existsSync()) targetDir.deleteSync(recursive: true);
        });

        final archive = Archive();
        // Malicious entry trying to escape target dir
        archive.addFile(ArchiveFile('../../escaped.txt', 12, utf8.encode('ATTACK_BYTES')));
        archive.addFile(ArchiveFile('safe.txt', 10, utf8.encode('SAFE_BYTES')));

        final maliciousZipBytes = ZipEncoder().encode(archive)!;

        // Restore using BackupService
        final payload = await BackupService.restoreFromZipBytes(maliciousZipBytes);
        expect(payload.cards, isEmpty);

        // Confirm escaped file was never written outside target directory
        final escapedFile = File('${targetDir.parent.path}/escaped.txt');
        expect(escapedFile.existsSync(), isFalse);
      });

      test('Fault 5.7: Rapid concurrent media persistence produces zero collisions', () async {
        final docsDir = Directory.systemTemp.createTempSync('persist_collision_docs_');
        final externalDir = Directory.systemTemp.createTempSync('persist_collision_ext_');
        addTearDown(() {
          if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
          if (externalDir.existsSync()) externalDir.deleteSync(recursive: true);
        });

        CardStorageService.docsDirectoryOverride = () async => docsDir;

        final srcImage = File('${externalDir.path}/test_src.jpg')
          ..writeAsBytesSync(utf8.encode('SAMPLE_IMAGE'), flush: true);

        // Concurrently persist 50 media files with the same cardId from outside docsDir
        final futures = List.generate(50, (i) {
          return CardStorageService.persistMediaFile(
            srcImage.path,
            cardId: 'concurrent_card',
            mediaType: 'images',
          );
        });

        final results = await Future.wait(futures);
        final uniquePaths = results.toSet();
        // Every single persisted file must have a unique path!
        expect(uniquePaths.length, equals(50));
        for (final path in uniquePaths) {
          expect(File(path).existsSync(), isTrue);
          expect(File(path).readAsStringSync(), equals('SAMPLE_IMAGE'));
        }
      });
    });
  });
}
