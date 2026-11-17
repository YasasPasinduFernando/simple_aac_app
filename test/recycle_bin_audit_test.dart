import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/models/recycle_bin_entry.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/recycle_bin_service.dart';

String _sha256Bytes(List<int> bytes) => sha256.convert(bytes).toString();
String _sha256File(File file) => sha256.convert(file.readAsBytesSync()).toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('recycle_bin_audit_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;
    RecycleBinService.docsDirectoryOverride = () async => tempDir;
    RecycleBinService.clockOverride = null;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    CardStorageService.resetTestHooks();
    RecycleBinService.resetTestHooks();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('PHASE 2 — Data Integrity & Relationship Audit', () {
    test('Rule 1: Card ID uniqueness and deduplication upon restore', () async {
      final activeCard = AACCard(id: 'card_collision_1', label: 'Active Apple', colorValue: 0xFFFF0000);
      final activeList = <AACCard>[activeCard];

      // A card in recycle bin has identical ID
      final deletedCard = AACCard(id: 'card_collision_1', label: 'Restored Apple', colorValue: 0xFFFF5555);
      final entry = await RecycleBinService.instance.moveToRecycleBin(
        card: deletedCard,
        originalIndex: 1,
      );

      final restored = await RecycleBinService.instance.restoreEntry(
        entryId: entry.entryId,
        activeCards: activeList,
      );

      expect(restored, isNotNull);
      expect(activeList.length, 2);
      expect(activeList[0].id, 'card_collision_1');
      expect(activeList[1].id, isNot('card_collision_1'));
      expect(activeList[1].id, startsWith('card_'));
      expect(activeList[1].label, 'Restored Apple');
    });

    test('Rule 2: Hierarchy preservation across nested folders and missing parent fallback', () async {
      final subCardA = AACCard(id: 'child_1', label: 'Child 1', colorValue: 0xFF111111);
      final subCardB = AACCard(id: 'child_2', label: 'Child 2', colorValue: 0xFF222222);
      final parentFolder = AACCard(
        id: 'parent_folder_1',
        label: 'Activities',
        type: 'folder',
        colorValue: 0xFFFFAA00,
        subCards: [subCardA, subCardB],
      );

      final activeList = <AACCard>[parentFolder];

      // 1. Delete folder
      final entry = await RecycleBinService.instance.moveToRecycleBin(
        card: parentFolder,
        originalIndex: 0,
      );
      activeList.remove(parentFolder);

      expect(activeList, isEmpty);
      expect(entry.card.subCards.length, 2);

      // 2. Restore folder
      final restoredFolder = await RecycleBinService.instance.restoreEntry(
        entryId: entry.entryId,
        activeCards: activeList,
      );

      expect(restoredFolder, isNotNull);
      expect(restoredFolder!.type, 'folder');
      expect(restoredFolder.subCards.length, 2);
      expect(restoredFolder.subCards[0].id, 'child_1');
      expect(restoredFolder.subCards[1].id, 'child_2');

      // 3. Delete subcard, delete and empty parent folder, restore subcard -> fallback to root
      final subEntry = await RecycleBinService.instance.moveToRecycleBin(
        card: subCardA,
        parentId: 'parent_folder_1',
        originalIndex: 0,
      );
      restoredFolder.subCards.remove(subCardA);

      // Parent folder permanently removed
      activeList.clear();

      final restoredSub = await RecycleBinService.instance.restoreEntry(
        entryId: subEntry.entryId,
        activeCards: activeList,
      );

      expect(restoredSub, isNotNull);
      expect(activeList.length, 1);
      expect(activeList.first.id, 'child_1');
      expect(activeList.first.label, 'Child 1');
    });

    test('Rule 3 & 4: Multilingual labels (EN/SI/TA) and all card properties survive intact', () async {
      final card = AACCard(
        id: 'multi_card_1',
        label: 'Water',
        labelSinhala: 'වතුර',
        labelTamil: 'தண்ணீர்',
        colorValue: 0xFF29B6F6,
        category: 'Needs',
        type: 'word',
        imagePath: '/mock/path/water.webp',
        voicePath: '/mock/path/water_si.m4a',
      );

      final entry = await RecycleBinService.instance.moveToRecycleBin(card: card);
      final json = entry.toJson();
      final roundTrip = RecycleBinEntry.fromJson(json);

      expect(roundTrip.card.label, 'Water');
      expect(roundTrip.card.labelSinhala, 'වතුර');
      expect(roundTrip.card.labelTamil, 'தண்ணீர்');
      expect(roundTrip.card.colorValue, 0xFF29B6F6);
      expect(roundTrip.card.category, 'Needs');
      expect(roundTrip.card.type, 'word');
      expect(roundTrip.card.imagePath, '/mock/path/water.webp');
      expect(roundTrip.card.voicePath, '/mock/path/water_si.m4a');
    });
  });

  group('PHASE 3 — Functional Verification (Test Cases 01–08)', () {
    test('Test Case 01: Delete Single Word Card', () async {
      final mediaDir = Directory('${tempDir.path}/aac_media/images')..createSync(recursive: true);
      final mediaFile = File('${mediaDir.path}/apple.jpg')..writeAsStringSync('apple-img-bytes');

      final card = AACCard(
        id: 'c_apple',
        label: 'Apple',
        colorValue: 0xFFFF0000,
        imagePath: mediaFile.path,
      );
      final activeCards = [card];

      final entry = await RecycleBinService.instance.moveToRecycleBin(
        card: card,
        originalIndex: 0,
      );
      activeCards.remove(card);

      expect(activeCards, isEmpty);
      expect(await RecycleBinService.instance.getEntryCount(), 1);
      expect(entry.card.label, 'Apple');
      expect(entry.getDaysRemaining(DateTime.now().toUtc()), 30);
      expect(await mediaFile.exists(), isTrue); // Media NOT deleted
    });

    test('Test Case 02: Restore Single Word Card', () async {
      final mediaDir = Directory('${tempDir.path}/aac_media/images')..createSync(recursive: true);
      final mediaFile = File('${mediaDir.path}/apple.jpg')..writeAsStringSync('apple-img-bytes');

      final card = AACCard(
        id: 'c_apple',
        label: 'Apple',
        colorValue: 0xFFFF0000,
        imagePath: mediaFile.path,
      );
      final activeCards = <AACCard>[];

      final entry = await RecycleBinService.instance.moveToRecycleBin(
        card: card,
        originalIndex: 0,
      );

      final restored = await RecycleBinService.instance.restoreEntry(
        entryId: entry.entryId,
        activeCards: activeCards,
      );

      expect(await RecycleBinService.instance.getEntryCount(), 0);
      expect(activeCards.length, 1);
      expect(restored!.label, 'Apple');
      expect(await mediaFile.exists(), isTrue);
    });

    test('Test Case 03 & 04: Delete & Restore Folder Card with Sub-Cards', () async {
      final sub1 = AACCard(id: 'sub_1', label: 'Item 1', colorValue: 0xFF123456);
      final sub2 = AACCard(id: 'sub_2', label: 'Item 2', colorValue: 0xFF654321);
      final folder = AACCard(
        id: 'folder_f',
        label: 'My Folder',
        type: 'folder',
        colorValue: 0xFFFFCC00,
        subCards: [sub1, sub2],
      );

      final activeCards = [folder];

      // Delete folder
      final entry = await RecycleBinService.instance.moveToRecycleBin(card: folder, originalIndex: 0);
      activeCards.remove(folder);

      expect(activeCards, isEmpty);
      expect(entry.card.subCards.length, 2);
      expect(await RecycleBinService.instance.getEntryCount(), 1);

      // Restore folder
      final restored = await RecycleBinService.instance.restoreEntry(
        entryId: entry.entryId,
        activeCards: activeCards,
      );

      expect(restored, isNotNull);
      expect(activeCards.length, 1);
      expect(activeCards[0].subCards.length, 2);
      expect(activeCards[0].subCards[0].label, 'Item 1');
      expect(activeCards[0].subCards[1].label, 'Item 2');
    });

    test('Test Case 05: Delete and Restore Card with Missing Parent', () async {
      final subCard = AACCard(id: 'orphan_child', label: 'Orphan Child', colorValue: 0xFFFFFFFF);
      final activeCards = <AACCard>[];

      final entry = await RecycleBinService.instance.moveToRecycleBin(
        card: subCard,
        parentId: 'deleted_parent_id',
        originalIndex: 0,
      );

      final restored = await RecycleBinService.instance.restoreEntry(
        entryId: entry.entryId,
        activeCards: activeCards,
      );

      expect(restored, isNotNull);
      expect(activeCards.length, 1);
      expect(activeCards.first.id, 'orphan_child');
      expect(activeCards.first.label, 'Orphan Child');
    });

    test('Test Case 06: Multiple Cards Delete and Restore', () async {
      final c1 = AACCard(id: 'c1', label: 'Card 1', colorValue: 0xFF111111);
      final c2 = AACCard(id: 'c2', label: 'Card 2', colorValue: 0xFF222222);
      final c3 = AACCard(id: 'c3', label: 'Card 3', colorValue: 0xFF333333);

      final activeCards = [c1, c2, c3];

      final e1 = await RecycleBinService.instance.moveToRecycleBin(card: c1, originalIndex: 0);
      activeCards.remove(c1);
      final e2 = await RecycleBinService.instance.moveToRecycleBin(card: c2, originalIndex: 0);
      activeCards.remove(c2);
      final e3 = await RecycleBinService.instance.moveToRecycleBin(card: c3, originalIndex: 0);
      activeCards.remove(c3);

      expect(activeCards, isEmpty);
      expect(await RecycleBinService.instance.getEntryCount(), 3);

      // Restore e2 first, then e1, then e3
      await RecycleBinService.instance.restoreEntry(entryId: e2.entryId, activeCards: activeCards);
      await RecycleBinService.instance.restoreEntry(entryId: e1.entryId, activeCards: activeCards);
      await RecycleBinService.instance.restoreEntry(entryId: e3.entryId, activeCards: activeCards);

      expect(activeCards.length, 3);
      expect(await RecycleBinService.instance.getEntryCount(), 0);
    });

    test('Test Case 07: Recycle Bin Persistence Across App Restart', () async {
      final card = AACCard(id: 'c_persist', label: 'Persist Me', colorValue: 0xFF445566);
      await RecycleBinService.instance.moveToRecycleBin(card: card);

      // Simulate app restart by loading raw entries from disk directly
      final binFile = File('${tempDir.path}/aac_recycle_bin.json');
      expect(await binFile.exists(), isTrue);

      final entries = await RecycleBinService.instance.loadEntries();
      expect(entries.length, 1);
      expect(entries.first.card.label, 'Persist Me');
      expect(entries.first.card.id, 'c_persist');
    });

    test('Test Case 08: Undo and Cancel Operations Integration', () async {
      final card = AACCard(id: 'c_transactional', label: 'Transactional Card', colorValue: 0xFF00FFCC);
      final activeCards = [card];

      // Step 1: User deletes card in edit mode
      final entry = await RecycleBinService.instance.moveToRecycleBin(card: card, originalIndex: 0);
      activeCards.remove(card);
      expect(await RecycleBinService.instance.getEntryCount(), 1);

      // Step 2: User taps Undo -> card restored to active, bin entry purged
      activeCards.insert(0, card);
      await RecycleBinService.instance.removeEntry(entry.entryId, activeCards: activeCards);

      expect(await RecycleBinService.instance.getEntryCount(), 0);
      expect(activeCards.length, 1);
      expect(activeCards.first.id, 'c_transactional');
    });
  });

  group('PHASE 4 — 30-Day Retention & Expiration Verification', () {
    test('Exact time boundary calculations: 0d, 1d, 29d, 30d, 31d', () {
      final base = DateTime.utc(2026, 11, 1, 10, 0);
      final card = AACCard(id: 'c', label: 'Card', colorValue: 0xFF000000);
      final entry = RecycleBinEntry(entryId: 'e', card: card, originalIndex: 0, deletedAtUtc: base);

      // 0 days
      expect(entry.getDaysRemaining(base), 30);
      expect(entry.isExpired(base), isFalse);

      // 1 day
      final day1 = base.add(const Duration(days: 1));
      expect(entry.getDaysRemaining(day1), 29);
      expect(entry.isExpired(day1), isFalse);

      // 29 days
      final day29 = base.add(const Duration(days: 29));
      expect(entry.getDaysRemaining(day29), 1);
      expect(entry.isExpired(day29), isFalse);

      // 30 days exact
      final day30 = base.add(const Duration(days: 30));
      expect(entry.getDaysRemaining(day30), 0);
      expect(entry.isExpired(day30), isTrue);

      // 31 days
      final day31 = base.add(const Duration(days: 31));
      expect(entry.getDaysRemaining(day31), 0);
      expect(entry.isExpired(day31), isTrue);
    });

    test('purgeExpiredEntries automatically purges >= 30-day items and cleans unreferenced media', () async {
      final mediaDir = Directory('${tempDir.path}/aac_media/images')..createSync(recursive: true);
      final expiredMedia = File('${mediaDir.path}/expired.jpg')..writeAsStringSync('expired_bytes');
      final survivingMedia = File('${mediaDir.path}/surviving.jpg')..writeAsStringSync('surviving_bytes');

      final baseTime = DateTime.utc(2026, 11, 1, 12, 0);

      final cardSurviving = AACCard(
        id: 'c_surviving',
        label: 'Surviving',
        colorValue: 0xFF00FF00,
        imagePath: survivingMedia.path,
      );
      final cardExpired = AACCard(
        id: 'c_expired',
        label: 'Expired',
        colorValue: 0xFFFF0000,
        imagePath: expiredMedia.path,
      );

      // Add surviving at day 0
      RecycleBinService.clockOverride = () => baseTime;
      await RecycleBinService.instance.moveToRecycleBin(card: cardSurviving);

      // Add expired at day -31
      RecycleBinService.clockOverride = () => baseTime.subtract(const Duration(days: 31));
      await RecycleBinService.instance.moveToRecycleBin(card: cardExpired);

      // Check current state at baseTime
      RecycleBinService.clockOverride = () => baseTime;
      expect(await RecycleBinService.instance.getEntryCount(), 2);

      final purged = await RecycleBinService.instance.purgeExpiredEntries(activeCards: []);
      expect(purged, 1);
      expect(await RecycleBinService.instance.getEntryCount(), 1);

      // Check remaining entry is Surviving
      final entries = await RecycleBinService.instance.loadEntries();
      expect(entries.first.card.label, 'Surviving');

      // Check media cleanup
      expect(await expiredMedia.exists(), isFalse); // Purged
      expect(await survivingMedia.exists(), isTrue); // Kept
    });
  });

  group('PHASE 5 — Backup & Restore Compatibility Audit (Tests A–G)', () {
    test('Test Case A: Export Backup with Active Recycle Bin (Recycle Bin excluded from backup)', () async {
      final activeCard = AACCard(id: 'active_1', label: 'Active Card', colorValue: 0xFF123456);
      final deletedCard = AACCard(id: 'deleted_1', label: 'Deleted Card', colorValue: 0xFF654321);

      await RecycleBinService.instance.moveToRecycleBin(card: deletedCard);
      expect(await RecycleBinService.instance.getEntryCount(), 1);

      final zipBytes = await BackupService.buildBackupZip([activeCard]);
      expect(zipBytes, isNotNull);

      // Inspect ZIP contents
      final archive = ZipDecoder().decodeBytes(zipBytes!);
      final manifestFile = archive.findFile('cards.json');
      expect(manifestFile, isNotNull);

      final cardsJson = jsonDecode(utf8.decode(manifestFile!.content as List<int>)) as List;
      expect(cardsJson.length, 1);
      expect(cardsJson[0]['id'], 'active_1');

      // Recycle bin cards MUST NOT be in the backup ZIP!
      final hasDeletedInZip = cardsJson.any((c) => c['id'] == 'deleted_1');
      expect(hasDeletedInZip, isFalse);

      // Recycle bin file remains untouched
      expect(await RecycleBinService.instance.getEntryCount(), 1);
    });

    test('Test Case B: Import Restore from Previous Version Backup (Legacy ZIP format)', () async {
      // Create a legacy zip without any recycle bin structure
      final archive = Archive();
      final legacyCards = [
        {'id': 'legacy_1', 'label': 'Legacy Card', 'colorValue': 0xFF0088AA, 'type': 'word'}
      ];
      final jsonBytes = utf8.encode(jsonEncode(legacyCards));
      archive.addFile(ArchiveFile('cards.json', jsonBytes.length, jsonBytes));

      final zipBytes = ZipEncoder().encode(archive)!;

      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(payload.cards.length, 1);
      expect(payload.cards.first.label, 'Legacy Card');
      expect(payload.cards.first.id, 'legacy_1');
    });

    test('Test Case C & D: Import Restore with Existing Recycle Bin Data & Round-Trip', () async {
      final c1 = AACCard(id: 'orig_1', label: 'Original 1', colorValue: 0xFF112233);
      final c2 = AACCard(id: 'orig_2', label: 'Original 2', colorValue: 0xFF445566);

      // Export backup
      final zipBytes = await BackupService.buildBackupZip([c1, c2]);
      expect(zipBytes, isNotNull);

      // User deletes c2 into recycle bin
      await RecycleBinService.instance.moveToRecycleBin(card: c2);
      expect(await RecycleBinService.instance.getEntryCount(), 1);

      // User restores backup
      final restoredPayload = await BackupService.restoreFromZipBytes(zipBytes!);
      expect(restoredPayload.cards.length, 2);
      expect(restoredPayload.cards.map((c) => c.id), containsAll(['orig_1', 'orig_2']));

      // Existing recycle bin data is preserved and not corrupted
      expect(await RecycleBinService.instance.getEntryCount(), 1);
    });

    test('Test Case E: Backup ZIP File Structure Verification', () async {
      final mediaDir = Directory('${tempDir.path}/aac_media/images')..createSync(recursive: true);
      final mediaFile = File('${mediaDir.path}/structure_test.jpg')..writeAsStringSync('media_structure');

      final card = AACCard(
        id: 'struct_card',
        label: 'Structure Card',
        colorValue: 0xFF778899,
        imagePath: mediaFile.path,
      );

      final zipBytes = await BackupService.buildBackupZip([card], settings: {'test': true});
      final archive = ZipDecoder().decodeBytes(zipBytes!);

      final fileNames = archive.map((f) => f.name).toList();
      expect(fileNames, contains('cards.json'));
      expect(fileNames, contains('settings.json'));
      expect(fileNames, contains('files/structure_test.jpg'));

      // Ensure no altered or unescaped paths
      for (final name in fileNames) {
        expect(name.contains('..'), isFalse);
      }
    });

    test('Test Case F: Large Backup Test (50+ cards across nested folders)', () async {
      final largeCards = <AACCard>[];
      for (var f = 0; f < 5; f++) {
        final subCards = <AACCard>[];
        for (var s = 0; s < 10; s++) {
          subCards.add(AACCard(
            id: 'sub_${f}_$s',
            label: 'Word ${f}_$s',
            labelSinhala: 'වචනය ${f}_$s',
            labelTamil: 'வார்த்தை ${f}_$s',
            colorValue: 0xFF000000 + f * 1000 + s,
          ));
        }
        largeCards.add(AACCard(
          id: 'folder_$f',
          label: 'Folder $f',
          type: 'folder',
          colorValue: 0xFFFFAA00,
          subCards: subCards,
        ));
      }

      expect(CardStorageService.countCards(largeCards), 55);

      final stopwatch = Stopwatch()..start();
      final zipBytes = await BackupService.buildBackupZip(largeCards);
      final buildTime = stopwatch.elapsedMilliseconds;
      stopwatch.reset();

      expect(zipBytes, isNotNull);
      expect(buildTime, lessThan(3000)); // Well within performance SLA

      final payload = await BackupService.restoreFromZipBytes(zipBytes!);
      final restoreTime = stopwatch.elapsedMilliseconds;
      stopwatch.stop();

      expect(CardStorageService.countCards(payload.cards), 55);
      expect(restoreTime, lessThan(3000));
    });

    test('Test Case G: Repeated Backup/Restore Cycles (3 cycles without drift)', () async {
      var currentCards = [
        AACCard(id: 'c1', label: 'Cycle 1', colorValue: 0xFF123456),
        AACCard(id: 'c2', label: 'Cycle 2', colorValue: 0xFF654321),
      ];

      for (var i = 0; i < 3; i++) {
        final zipBytes = await BackupService.buildBackupZip(currentCards);
        expect(zipBytes, isNotNull);
        final payload = await BackupService.restoreFromZipBytes(zipBytes!);
        expect(payload.cards.length, 2);
        expect(payload.cards[0].label, 'Cycle 1');
        expect(payload.cards[1].label, 'Cycle 2');
        currentCards = payload.cards;
      }
    });
  });

  group('PHASE 6 — Media File Integrity & SHA-256 Verification', () {
    test('SHA-256 bit-for-bit preservation across active, recycle bin, and restore lifecycle', () async {
      final mediaDir = Directory('${tempDir.path}/aac_media/images')..createSync(recursive: true);
      final testFile = File('${mediaDir.path}/sha_test.jpg');
      final testBytes = utf8.encode('DETERMINISTIC_MEDIA_PAYLOAD_FOR_SHA256_AUDIT_VERIFICATION');
      testFile.writeAsBytesSync(testBytes);

      final initialSha = _sha256Bytes(testBytes);
      expect(_sha256File(testFile), initialSha);

      final card = AACCard(
        id: 'sha_card',
        label: 'SHA Card',
        colorValue: 0xFFABCDEF,
        imagePath: testFile.path,
      );
      final activeCards = [card];

      // 1. Move to Recycle Bin
      final entry = await RecycleBinService.instance.moveToRecycleBin(card: card, originalIndex: 0);
      activeCards.remove(card);

      // Verify file still exists on disk during retention with identical SHA-256
      expect(testFile.existsSync(), isTrue);
      expect(_sha256File(testFile), initialSha);

      // 2. Restore from Recycle Bin
      final restored = await RecycleBinService.instance.restoreEntry(
        entryId: entry.entryId,
        activeCards: activeCards,
      );

      // Verify file still exists and SHA-256 is 100% bit-for-bit identical
      expect(restored, isNotNull);
      expect(testFile.existsSync(), isTrue);
      expect(_sha256File(testFile), initialSha);
    });

    test('Shared Media Safety: Deleting Card A does not delete media referenced by Card B', () async {
      final mediaDir = Directory('${tempDir.path}/aac_media/images')..createSync(recursive: true);
      final sharedFile = File('${mediaDir.path}/shared_icon.png')..writeAsStringSync('shared_pixels');

      final cardA = AACCard(id: 'cA', label: 'Card A', imagePath: sharedFile.path, colorValue: 0xFF111111);
      final cardB = AACCard(id: 'cB', label: 'Card B', imagePath: sharedFile.path, colorValue: 0xFF222222);

      final activeCards = [cardA, cardB];

      // Move Card A to Recycle Bin
      await RecycleBinService.instance.moveToRecycleBin(card: cardA, originalIndex: 0);
      activeCards.remove(cardA);

      // Empty Recycle Bin (permanent deletion of Card A)
      await RecycleBinService.instance.emptyRecycleBin(activeCards: activeCards);

      // sharedFile MUST survive because Card B is still in activeCards!
      expect(sharedFile.existsSync(), isTrue);
    });

    test('Bundled assets and remote URLs are strictly exempt from deletion', () async {
      const assetPath = 'assets/images/starter/kottu.webp';
      const webUrl = 'https://example.com/sound.mp3';

      final docsDir = await Directory.systemTemp.createTemp('docs_media_');
      expect(RecycleBinService.isAppOwnedMedia(assetPath, docsDir), isFalse);
      expect(RecycleBinService.isAppOwnedMedia(webUrl, docsDir), isFalse);

      final cardWithAssets = AACCard(
        id: 'asset_card',
        label: 'Asset Card',
        imagePath: assetPath,
        voicePath: webUrl,
        colorValue: 0xFFFFFFFF,
      );

      final entry = await RecycleBinService.instance.moveToRecycleBin(card: cardWithAssets);
      await RecycleBinService.instance.removeEntry(entry.entryId, activeCards: []);

      // No exception thrown, safety verified
      await docsDir.delete(recursive: true);
    });
  });

  group('PHASE 7 — Restore Failure & Corruption Resilience', () {
    test('Corrupted backup ZIP bytes return empty payload safely without crash', () async {
      final corruptBytes = [0x50, 0x4B, 0x03, 0x04, 0x99, 0x88, 0x77];
      final payload = await BackupService.restoreFromZipBytes(corruptBytes);
      expect(payload.cards, isEmpty);
      expect(payload.settings, isEmpty);
    });

    test('Missing media in backup restores card safely with fallback', () async {
      final archive = Archive();
      final cards = [
        {
          'id': 'missing_media_card',
          'label': 'Missing Media',
          'imagePath': 'files/non_existent.jpg',
          'colorValue': 0xFFFFFFFF,
        }
      ];
      final jsonBytes = utf8.encode(jsonEncode(cards));
      archive.addFile(ArchiveFile('cards.json', jsonBytes.length, jsonBytes));

      final zipBytes = ZipEncoder().encode(archive)!;
      final payload = await BackupService.restoreFromZipBytes(zipBytes);

      expect(payload.cards.length, 1);
      expect(payload.cards.first.label, 'Missing Media');
    });

    test('Corrupted recycle bin persistence file recovers gracefully as empty', () async {
      final binFile = File('${tempDir.path}/aac_recycle_bin.json');
      await binFile.writeAsString('{ MALFORMED_JSON: true, invalid... ');

      // Should not throw, should return empty list and self-heal
      final entries = await RecycleBinService.instance.loadEntries();
      expect(entries, isEmpty);

      // Verify saving a new entry overwrites the malformed file cleanly
      final newCard = AACCard(id: 'c_heal', label: 'Healed Card', colorValue: 0xFFFFFFFF);
      await RecycleBinService.instance.moveToRecycleBin(card: newCard);
      expect(await RecycleBinService.instance.getEntryCount(), 1);
    });
  });

  group('PHASE 8 — Upgrade & Migration Safety', () {
    test('Existing user without aac_recycle_bin.json loads normally and initializes clean bin', () async {
      final binFile = File('${tempDir.path}/aac_recycle_bin.json');
      expect(await binFile.exists(), isFalse);

      final count = await RecycleBinService.instance.getEntryCount();
      expect(count, 0);

      final card = AACCard(id: 'c_upgrade', label: 'First Upgrade Delete', colorValue: 0xFF123456);
      final entry = await RecycleBinService.instance.moveToRecycleBin(card: card);

      expect(entry.entryId, isNotEmpty);
      expect(await binFile.exists(), isTrue);
      expect(await RecycleBinService.instance.getEntryCount(), 1);
    });
  });

  group('PHASE 9 — Storage Overhead & Operation Timing', () {
    test('Metadata storage overhead for 100 entries is negligible (< 100 KB)', () async {
      final entries = <RecycleBinEntry>[];
      final now = DateTime.now().toUtc();
      for (var i = 0; i < 100; i++) {
        entries.add(RecycleBinEntry(
          entryId: 'entry_$i',
          card: AACCard(
            id: 'card_$i',
            label: 'Card Label $i',
            labelSinhala: 'සිංහල ලේබලය $i',
            labelTamil: 'தமிழ் லேபிள் $i',
            colorValue: 0xFF102030,
            imagePath: '/data/user/0/lk.yasas.simpleaac/app_flutter/aac_media/images/img_$i.jpg',
            voicePath: '/data/user/0/lk.yasas.simpleaac/app_flutter/aac_media/voices/voice_$i.m4a',
          ),
          originalIndex: i,
          deletedAtUtc: now,
        ));
      }

      await RecycleBinService.instance.saveEntries(entries);
      final binFile = File('${tempDir.path}/aac_recycle_bin.json');
      expect(await binFile.exists(), isTrue);

      final sizeBytes = await binFile.length();
      final sizeKb = sizeBytes / 1024.0;
      debugPrint('[RecycleBin Audit] 100 entries file size: ${sizeKb.toStringAsFixed(2)} KB');

      // Requirement: < 100 KB for typical usage
      expect(sizeKb, lessThan(100.0));
    });

    test('Operation timing: move (<50ms), restore (<100ms), purge (<200ms)', () async {
      final card = AACCard(id: 'c_perf', label: 'Perf Card', colorValue: 0xFF00FF00);
      final activeCards = <AACCard>[];

      // Measure move
      final sw = Stopwatch()..start();
      final entry = await RecycleBinService.instance.moveToRecycleBin(card: card, originalIndex: 0);
      final moveTimeMs = sw.elapsedMilliseconds;
      sw.reset();

      expect(moveTimeMs, lessThan(50));

      // Measure restore
      final restored = await RecycleBinService.instance.restoreEntry(
        entryId: entry.entryId,
        activeCards: activeCards,
      );
      final restoreTimeMs = sw.elapsedMilliseconds;
      sw.reset();

      expect(restored, isNotNull);
      expect(restoreTimeMs, lessThan(100));

      // Measure purge
      final purgeCount = await RecycleBinService.instance.purgeExpiredEntries(activeCards: activeCards);
      final purgeTimeMs = sw.elapsedMilliseconds;
      sw.stop();

      expect(purgeCount, 0);
      expect(purgeTimeMs, lessThan(200));
    });
  });
}
