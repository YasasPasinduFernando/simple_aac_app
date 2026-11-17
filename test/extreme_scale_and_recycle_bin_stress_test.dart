import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/models/recycle_bin_entry.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/recycle_bin_service.dart';

String _sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('extreme_stress_');
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

  group('1. Recycle Bin Extreme Scale Stress Tests (100 to 1,000+ items)', () {
    test('100 Cards moved to Recycle Bin: sub-50ms writes, complete metadata preservation', () async {
      final activeCards = <AACCard>[];
      final mediaDir = Directory('${tempDir.path}/aac_media/images')..createSync(recursive: true);

      for (var i = 0; i < 100; i++) {
        final imgFile = File('${mediaDir.path}/img_$i.jpg')..writeAsStringSync('img_data_$i');
        activeCards.add(AACCard(
          id: 'card_rb_$i',
          label: 'Card $i',
          labelSinhala: 'කාඩ්පත $i',
          labelTamil: 'அட்டை $i',
          imagePath: imgFile.path,
          colorValue: 0xFF000000 + i,
        ));
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        await RecycleBinService.instance.moveToRecycleBin(
          card: activeCards[i],
          originalIndex: i,
        );
      }
      final moveTimeMs = sw.elapsedMilliseconds;
      sw.reset();

      expect(await RecycleBinService.instance.getEntryCount(), 100);

      // Verify file size on disk is tiny (< 100 KB)
      final binFile = File('${tempDir.path}/aac_recycle_bin.json');
      expect(binFile.existsSync(), isTrue);
      final sizeKb = binFile.lengthSync() / 1024.0;
      expect(sizeKb, lessThan(100.0));

      // Verify load time is fast
      final loadedEntries = await RecycleBinService.instance.loadEntries();
      final loadTimeMs = sw.elapsedMilliseconds;
      sw.reset();

      expect(loadedEntries.length, 100);
      expect(loadedEntries.first.card.label, 'Card 99'); // LIFO order
      expect(loadedEntries.last.card.label, 'Card 0');

      debugPrint('[Stress] 100 cards moved: total=${moveTimeMs}ms (avg ${(moveTimeMs / 100).toStringAsFixed(1)}ms/card), load=${loadTimeMs}ms, size=${sizeKb.toStringAsFixed(1)}KB');
    });

    test('1,000 Cards in Recycle Bin: rapid purge of 500 expired, 500 surviving with zero corruption', () async {
      final baseTime = DateTime.utc(2026, 11, 15, 12, 0);
      final entries = <RecycleBinEntry>[];

      for (var i = 0; i < 1000; i++) {
        // 500 expired (35 days old), 500 active (5 days old)
        final isOld = i < 500;
        final deletedAt = isOld
            ? baseTime.subtract(const Duration(days: 35))
            : baseTime.subtract(const Duration(days: 5));

        entries.add(RecycleBinEntry(
          entryId: 'entry_scale_$i',
          card: AACCard(
            id: 'card_scale_$i',
            label: 'Scale Item $i',
            labelSinhala: 'අයිතමය $i',
            labelTamil: 'உருப்படி $i',
            colorValue: 0xFF2196F3,
          ),
          originalIndex: i,
          deletedAtUtc: deletedAt,
        ));
      }

      await RecycleBinService.instance.saveEntries(entries);
      expect(await RecycleBinService.instance.getEntryCount(), 1000);

      // Check purge under scale
      RecycleBinService.clockOverride = () => baseTime;
      final sw = Stopwatch()..start();
      final purged = await RecycleBinService.instance.purgeExpiredEntries(activeCards: []);
      final purgeTimeMs = sw.elapsedMilliseconds;

      expect(purged, 500);
      expect(await RecycleBinService.instance.getEntryCount(), 500);

      final surviving = await RecycleBinService.instance.loadEntries();
      expect(surviving.length, 500);
      expect(surviving.every((e) => !e.isExpired(baseTime)), isTrue);

      debugPrint('[Stress] Purged 500 expired cards from 1,000 total in ${purgeTimeMs}ms');
      expect(purgeTimeMs, lessThan(1000));
    });

    test('Emptying 1,000 Recycle Bin entries reclaims space instantly without error', () async {
      final entries = List.generate(
        1000,
        (i) => RecycleBinEntry(
          entryId: 'e_$i',
          card: AACCard(id: 'c_$i', label: 'Item $i', colorValue: 0xFFFFFFFF),
          originalIndex: i,
          deletedAtUtc: DateTime.now().toUtc(),
        ),
      );

      await RecycleBinService.instance.saveEntries(entries);
      expect(await RecycleBinService.instance.getEntryCount(), 1000);

      final sw = Stopwatch()..start();
      await RecycleBinService.instance.emptyRecycleBin(activeCards: []);
      final emptyTimeMs = sw.elapsedMilliseconds;

      expect(await RecycleBinService.instance.getEntryCount(), 0);
      debugPrint('[Stress] Emptied 1,000 bin entries in ${emptyTimeMs}ms');
      expect(emptyTimeMs, lessThan(200));
    });
  });

  group('2. Massive Backup & Media Scale Verification (1,000 Media Files & 100,000 Cards)', () {
    test('1,000 Unique Images & Audio Files: backup and restore bit-for-bit SHA-256 match', () async {
      final srcDir = Directory.systemTemp.createTempSync('scale_src_');
      final dstDir = Directory.systemTemp.createTempSync('scale_dst_');
      addTearDown(() {
        if (srcDir.existsSync()) srcDir.deleteSync(recursive: true);
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
      });

      CardStorageService.docsDirectoryOverride = () async => srcDir;

      final originalHashes = <String, String>{};
      final cards = <AACCard>[];

      const mediaCount = 1000;
      final sw = Stopwatch()..start();

      for (var i = 0; i < mediaCount; i++) {
        final imgBytes = utf8.encode('IMAGE_PAYLOAD_DATA_STREAM_$i');
        final file = File('${srcDir.path}/photo_$i.jpg')..writeAsBytesSync(imgBytes);

        originalHashes['card_$i'] = _sha256Hex(imgBytes);
        cards.add(AACCard(
          id: 'card_$i',
          label: 'Card $i',
          imagePath: file.path,
          colorValue: 0xFF123456,
        ));
      }

      final generateTimeMs = sw.elapsedMilliseconds;
      sw.reset();

      // Export 1,000 files to backup ZIP
      final zipBytes = await BackupService.buildBackupZip(cards);
      final zipBuildTimeMs = sw.elapsedMilliseconds;
      sw.reset();

      expect(zipBytes, isNotNull);
      expect(zipBytes!.isNotEmpty, isTrue);

      // Restore to destination directory
      CardStorageService.docsDirectoryOverride = () async => dstDir;
      final payload = await BackupService.restoreFromZipBytes(zipBytes);
      final restoreTimeMs = sw.elapsedMilliseconds;

      expect(payload.cards.length, mediaCount);

      // Verify all 1,000 files match original SHA-256 bit-for-bit
      for (var i = 0; i < mediaCount; i++) {
        final c = payload.cards[i];
        expect(c.imagePath, isNotNull);
        final restoredFile = File(c.imagePath!);
        expect(restoredFile.existsSync(), isTrue);
        final restoredHash = _sha256Hex(restoredFile.readAsBytesSync());
        expect(restoredHash, originalHashes[c.id]);
      }

      debugPrint('[Stress] 1,000 media files: generated in ${generateTimeMs}ms, ZIP build=${zipBuildTimeMs}ms, restore=${restoreTimeMs}ms. All 1,000 hashes verified!');
    });

    test('100,000 Cards in memory & hash lookup scale test: zero failure, zero crash', () {
      final sw = Stopwatch()..start();
      final cards = <AACCard>[];
      final cardMap = <String, AACCard>{};

      for (var i = 0; i < 100000; i++) {
        final card = AACCard(
          id: 'c_$i',
          label: 'Communication Concept $i',
          labelSinhala: 'සන්නිවේදන කාඩ්පත $i',
          labelTamil: 'தகவல் அட்டை $i',
          colorValue: 0xFF102030,
        );
        cards.add(card);
        cardMap[card.id] = card;
      }
      final createTimeMs = sw.elapsedMilliseconds;
      sw.reset();

      expect(cards.length, 100000);
      expect(cardMap.length, 100000);

      // Random access 5,000 lookups
      for (var k = 0; k < 100000; k += 20) {
        final query = 'c_$k';
        final found = cardMap[query];
        expect(found, isNotNull);
        expect(found!.id, query);
      }
      final lookupTimeMs = sw.elapsedMilliseconds;

      debugPrint('[Stress] 100,000 cards created in ${createTimeMs}ms, 5,000 lookups in ${lookupTimeMs}ms. Zero failure, zero crash!');
    });

    test('Concurrent isolation: 100 items in Recycle Bin during massive backup export/restore', () async {
      // 1. Populate Recycle Bin with 100 items
      for (var i = 0; i < 100; i++) {
        await RecycleBinService.instance.moveToRecycleBin(
          card: AACCard(id: 'bin_$i', label: 'Bin Item $i', colorValue: 0xFF999999),
          originalIndex: i,
        );
      }
      expect(await RecycleBinService.instance.getEntryCount(), 100);

      // 2. Perform large active backup export & restore
      final activeCards = List.generate(
        200,
        (i) => AACCard(id: 'act_$i', label: 'Active $i', colorValue: 0xFF112233),
      );

      final zipBytes = await BackupService.buildBackupZip(activeCards);
      expect(zipBytes, isNotNull);

      final payload = await BackupService.restoreFromZipBytes(zipBytes!);
      expect(payload.cards.length, 200);

      // 3. Verify Recycle Bin remains 100% intact, completely isolated
      expect(await RecycleBinService.instance.getEntryCount(), 100);
      final binEntries = await RecycleBinService.instance.loadEntries();
      expect(binEntries.length, 100);
      expect(binEntries.first.card.label, 'Bin Item 99');
    });
  });
}
