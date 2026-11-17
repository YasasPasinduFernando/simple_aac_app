import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/models/recycle_bin_entry.dart';
import 'package:simple_aac_app/pages/recycle_bin_page.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/recycle_bin_service.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('recycle_bin_test_');
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

  group('1. RecycleBinEntry Model & Status Formatting', () {
    test('Calculates remaining days and expiration accurately', () {
      final baseTime = DateTime.utc(2026, 11, 1, 12, 0);
      final card = AACCard(
        id: 'c1',
        label: 'Sad',
        colorValue: 0xFF90CAF9,
      );

      final entry = RecycleBinEntry(
        entryId: 'e1',
        card: card,
        originalIndex: 0,
        deletedAtUtc: baseTime,
      );

      // Same day (0 days elapsed)
      expect(entry.getDaysRemaining(baseTime), 30);
      expect(entry.isExpired(baseTime), isFalse);
      expect(entry.getDeletionStatusText(baseTime), 'Deleted today · 30 days left');

      // 1 day elapsed
      final plus1Day = baseTime.add(const Duration(days: 1));
      expect(entry.getDaysRemaining(plus1Day), 29);
      expect(entry.isExpired(plus1Day), isFalse);
      expect(entry.getDeletionStatusText(plus1Day), 'Deleted 1 day ago · 29 days left');

      // 3 days elapsed
      final plus3Days = baseTime.add(const Duration(days: 3));
      expect(entry.getDaysRemaining(plus3Days), 27);
      expect(entry.isExpired(plus3Days), isFalse);
      expect(entry.getDeletionStatusText(plus3Days), 'Deleted 3 days ago · 27 days left');

      // 29 days elapsed
      final plus29Days = baseTime.add(const Duration(days: 29));
      expect(entry.getDaysRemaining(plus29Days), 1);
      expect(entry.isExpired(plus29Days), isFalse);
      expect(entry.getDeletionStatusText(plus29Days), 'Deleted 29 days ago · 1 day left');

      // 30 days elapsed -> expired
      final plus30Days = baseTime.add(const Duration(days: 30));
      expect(entry.getDaysRemaining(plus30Days), 0);
      expect(entry.isExpired(plus30Days), isTrue);

      // 35 days elapsed -> expired
      final plus35Days = baseTime.add(const Duration(days: 35));
      expect(entry.getDaysRemaining(plus35Days), 0);
      expect(entry.isExpired(plus35Days), isTrue);
    });

    test('Serializes and deserializes preserving all card properties and subCards', () {
      final card = AACCard(
        id: 'folder_1',
        label: 'More',
        labelSinhala: 'තව',
        labelTamil: 'மேலும்',
        colorValue: 0xFFFFCA28,
        type: 'folder',
        category: 'Actions',
        imagePath: '/path/to/folder.png',
        voicePath: '/path/to/voice.m4a',
        subCards: [
          AACCard(
            id: 'sub_1',
            label: 'Water',
            colorValue: 0xFF81D4FA,
          ),
          AACCard(
            id: 'sub_2',
            label: 'Food',
            colorValue: 0xFFA5D6A7,
          ),
        ],
      );

      final entry = RecycleBinEntry(
        entryId: 'entry_test_1',
        card: card,
        parentId: 'root_parent',
        originalIndex: 2,
        deletedAtUtc: DateTime.utc(2026, 11, 10, 8, 30),
      );

      final json = entry.toJson();
      final roundTrip = RecycleBinEntry.fromJson(json);

      expect(roundTrip.entryId, 'entry_test_1');
      expect(roundTrip.parentId, 'root_parent');
      expect(roundTrip.originalIndex, 2);
      expect(roundTrip.card.id, 'folder_1');
      expect(roundTrip.card.label, 'More');
      expect(roundTrip.card.labelSinhala, 'තව');
      expect(roundTrip.card.labelTamil, 'மேலும்');
      expect(roundTrip.card.type, 'folder');
      expect(roundTrip.card.subCards.length, 2);
      expect(roundTrip.card.subCards[0].label, 'Water');
      expect(roundTrip.card.subCards[1].label, 'Food');
      expect(roundTrip.referencedMediaPaths, containsAll(['/path/to/folder.png', '/path/to/voice.m4a']));
    });
  });

  group('2. RecycleBinService Operations', () {
    test('moveToRecycleBin persists to disk and loadEntries retrieves items in order', () async {
      final card1 = AACCard(id: 'c1', label: 'Hello', colorValue: 0xFFFFEB3B);
      final card2 = AACCard(id: 'c2', label: 'Water', colorValue: 0xFF29B6F6);

      await RecycleBinService.instance.moveToRecycleBin(card: card1, originalIndex: 0);
      await RecycleBinService.instance.moveToRecycleBin(card: card2, originalIndex: 1);

      final entries = await RecycleBinService.instance.loadEntries();
      expect(entries.length, 2);
      // Newest on top
      expect(entries[0].card.label, 'Water');
      expect(entries[1].card.label, 'Hello');

      final count = await RecycleBinService.instance.getEntryCount();
      expect(count, 2);
    });

    test('restoreEntry restores word card to root cards at original index', () async {
      final card1 = AACCard(id: 'c1', label: 'Hello', colorValue: 0xFFFFEB3B);
      final card2 = AACCard(id: 'c2', label: 'Sad', colorValue: 0xFF90CAF9);
      final card3 = AACCard(id: 'c3', label: 'Play', colorValue: 0xFFA5D6A7);

      final activeCards = [card1, card3];
      final entry = await RecycleBinService.instance.moveToRecycleBin(
        card: card2,
        originalIndex: 1,
      );

      expect(await RecycleBinService.instance.getEntryCount(), 1);

      final restored = await RecycleBinService.instance.restoreEntry(
        entryId: entry.entryId,
        activeCards: activeCards,
      );

      expect(restored, isNotNull);
      expect(restored!.label, 'Sad');
      expect(activeCards.length, 3);
      expect(activeCards[1].label, 'Sad');
      expect(await RecycleBinService.instance.getEntryCount(), 0);
    });

    test('restoreEntry restores subcard into parent folder at original position', () async {
      final sub1 = AACCard(id: 's1', label: 'Item 1', colorValue: 0xFFFFFFFF);
      final sub2 = AACCard(id: 's2', label: 'Item 2', colorValue: 0xFFFFFFFF);
      final parentFolder = AACCard(
        id: 'parent_f',
        label: 'Folder',
        colorValue: 0xFFFFCA28,
        type: 'folder',
        subCards: [sub1],
      );

      final activeCards = [parentFolder];

      final entry = await RecycleBinService.instance.moveToRecycleBin(
        card: sub2,
        parentId: 'parent_f',
        originalIndex: 1,
      );

      final restored = await RecycleBinService.instance.restoreEntry(
        entryId: entry.entryId,
        activeCards: activeCards,
      );

      expect(restored, isNotNull);
      expect(parentFolder.subCards.length, 2);
      expect(parentFolder.subCards[1].label, 'Item 2');
    });

    test('restoreEntry falls back to root board if parent folder was deleted', () async {
      final subCard = AACCard(id: 'orphan', label: 'Orphan', colorValue: 0xFFFFFFFF);
      final activeCards = <AACCard>[];

      final entry = await RecycleBinService.instance.moveToRecycleBin(
        card: subCard,
        parentId: 'non_existent_folder',
        originalIndex: 0,
      );

      final restored = await RecycleBinService.instance.restoreEntry(
        entryId: entry.entryId,
        activeCards: activeCards,
      );

      expect(restored, isNotNull);
      expect(activeCards.length, 1);
      expect(activeCards.first.label, 'Orphan');
    });

    test('restoreEntry resolves ID collisions cleanly', () async {
      final existingCard = AACCard(id: 'same_id', label: 'Existing', colorValue: 0xFF000000);
      final activeCards = [existingCard];

      final incomingCard = AACCard(id: 'same_id', label: 'Restored', colorValue: 0xFFFFFFFF);
      final entry = await RecycleBinService.instance.moveToRecycleBin(
        card: incomingCard,
        originalIndex: 1,
      );

      final restored = await RecycleBinService.instance.restoreEntry(
        entryId: entry.entryId,
        activeCards: activeCards,
      );

      expect(restored, isNotNull);
      expect(activeCards.length, 2);
      expect(activeCards[0].id, 'same_id');
      expect(activeCards[1].id, isNot('same_id'));
      expect(activeCards[1].id, startsWith('card_'));
    });

    test('Folder deletion preserves entire subtree with all subcards intact', () async {
      final sub1 = AACCard(id: 'sub_a', label: 'Sub A', colorValue: 0xFF111111);
      final sub2 = AACCard(id: 'sub_b', label: 'Sub B', colorValue: 0xFF222222);
      final folder = AACCard(
        id: 'main_folder',
        label: 'Main Folder',
        colorValue: 0xFFFFCA28,
        type: 'folder',
        subCards: [sub1, sub2],
      );

      final entry = await RecycleBinService.instance.moveToRecycleBin(card: folder);
      expect(entry.card.subCards.length, 2);

      final activeCards = <AACCard>[];
      final restored = await RecycleBinService.instance.restoreEntry(
        entryId: entry.entryId,
        activeCards: activeCards,
      );

      expect(restored, isNotNull);
      expect(restored!.type, 'folder');
      expect(restored.subCards.length, 2);
      expect(restored.subCards[0].label, 'Sub A');
      expect(restored.subCards[1].label, 'Sub B');
    });

    test('purgeExpiredEntries purges entries >= 30 days old using injectable clock', () async {
      final now = DateTime.utc(2026, 11, 1, 12, 0);
      RecycleBinService.clockOverride = () => now;

      final cardRecent = AACCard(id: 'c_recent', label: 'Recent', colorValue: 0xFF123456);
      final cardOld = AACCard(id: 'c_old', label: 'Old', colorValue: 0xFF654321);

      // Add recent (day 0)
      await RecycleBinService.instance.moveToRecycleBin(card: cardRecent);

      // Advance clock by 31 days and add old entry with earlier timestamp
      RecycleBinService.clockOverride = () => now.subtract(const Duration(days: 31));
      await RecycleBinService.instance.moveToRecycleBin(card: cardOld);

      // Set clock back to "now"
      RecycleBinService.clockOverride = () => now;

      expect(await RecycleBinService.instance.getEntryCount(), 2);

      final purgedCount = await RecycleBinService.instance.purgeExpiredEntries();
      expect(purgedCount, 1);

      final remaining = await RecycleBinService.instance.loadEntries();
      expect(remaining.length, 1);
      expect(remaining.first.card.label, 'Recent');
    });

    test('Reference-aware media safety: unreferenced files deleted, referenced kept', () async {
      final mediaDir = Directory('${tempDir.path}/aac_media/images');
      await mediaDir.create(recursive: true);

      final sharedImageFile = File('${mediaDir.path}/shared.jpg');
      await sharedImageFile.writeAsString('image data');

      final exclusiveImageFile = File('${mediaDir.path}/exclusive.jpg');
      await exclusiveImageFile.writeAsString('exclusive data');

      final activeCard = AACCard(
        id: 'active_1',
        label: 'Active Card',
        imagePath: sharedImageFile.path,
        colorValue: 0xFF00FF00,
      );

      final deletedCard = AACCard(
        id: 'deleted_1',
        label: 'Deleted Card',
        imagePath: sharedImageFile.path,
        voicePath: exclusiveImageFile.path,
        colorValue: 0xFFFF0000,
      );

      final entry = await RecycleBinService.instance.moveToRecycleBin(card: deletedCard);

      // Permanently remove the entry
      await RecycleBinService.instance.removeEntry(
        entry.entryId,
        activeCards: [activeCard],
      );

      // Shared image should still exist because activeCard references it
      expect(await sharedImageFile.exists(), isTrue);

      // Exclusive image should have been safely deleted because nothing references it
      expect(await exclusiveImageFile.exists(), isFalse);
    });

    test('External gallery and asset paths are never deleted', () async {
      final externalDir = await Directory.systemTemp.createTemp('external_gallery_');
      final externalFile = File('${externalDir.path}/my_photo.jpg');
      await externalFile.writeAsString('photo bytes');

      final card = AACCard(
        id: 'ext_card',
        label: 'External Image',
        imagePath: externalFile.path,
        colorValue: 0xFF000000,
      );

      final entry = await RecycleBinService.instance.moveToRecycleBin(card: card);
      await RecycleBinService.instance.removeEntry(entry.entryId, activeCards: []);

      // External file outside aac_media/ MUST stay untouched!
      expect(await externalFile.exists(), isTrue);
      await externalDir.delete(recursive: true);
    });
  });

  group('3. Backup & Storage Isolation', () {
    test('Standard backup ZIP does not include recycle bin entries or deleted cards', () async {
      final activeCard = AACCard(id: 'active_card', label: 'Active', colorValue: 0xFF112233);
      final deletedCard = AACCard(id: 'bin_card', label: 'In Recycle Bin', colorValue: 0xFF445566);

      await RecycleBinService.instance.moveToRecycleBin(card: deletedCard);
      expect(await RecycleBinService.instance.getEntryCount(), 1);

      // Build backup for active cards
      final zipBytes = await BackupService.buildBackupZip(
        [activeCard],
        settings: {'language': 'en'},
      );

      expect(zipBytes, isNotNull);
      // Restore payload from zip
      final payload = await BackupService.restoreFromZipBytes(zipBytes!);
      expect(payload.cards.length, 1);
      expect(payload.cards.first.label, 'Active');

      // Recycle bin remains completely intact and unaffected
      expect(await RecycleBinService.instance.getEntryCount(), 1);
    });
  });

  group('4. Widget Tests - Drawer & RecycleBinPage UI', () {
    testWidgets('HomeDrawer displays Recycle Bin between Import Restore and Reset Settings', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool openedRecycleBin = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeDrawer(
              selectedCategory: 'All',
              currentLanguageLabel: 'English',
              gridColumns: 2,
              visibleCardsLabel: 'All Cards',
              isEditMode: false,
              showTtsInput: true,
              orientationLabel: 'Portrait',
              fullScreen: false,
              headerColor: Colors.blue,
              headerTextColor: Colors.white,
              hideTtsText: false,
              useImageOverlayLabel: true,
              applyTextColorToCards: false,
              isDarkMode: false,
              isColorBlindMode: false,
              primaryColorSwatch: Colors.blue,
              textColorSwatch: Colors.white,
              backgroundColorSwatch: Colors.white,
              isOnlineEnabled: false,
              onToggleOnline: (_) {},
              onToggleDarkMode: (_) {},
              onChangeColorBlindMode: (_) {},
              onSelectCategory: () {},
              onAddCategory: () {},
              onToggleEdit: () {},
              onToggleTtsInput: () {},
              onToggleTtsText: () {},
              onToggleCardImageLabel: () {},
              onToggleApplyTextColorToCards: () {},
              onChangeOrientation: () {},
              onPickPrimaryColor: () {},
              onPickTextColor: () {},
              onPickBackgroundColor: () {},
              onShowTtsBarSize: () {},
              onToggleFullScreen: () {},
              onShowLanguage: () {},
              onShowGrid: () {},
              onShowVisibleCount: () {},
              onBackup: () {},
              onRestore: () {},
              onOpenRecycleBin: () => openedRecycleBin = true,
              onResetSettings: () {},
              onShowAbout: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Recycle Bin item
      final recycleBinFinder = find.byKey(const ValueKey('drawer_recycle_bin_item'));
      await tester.scrollUntilVisible(recycleBinFinder, 150);
      expect(recycleBinFinder, findsOneWidget);
      expect(find.text('Recycle Bin'), findsOneWidget);
      expect(find.text('Recover deleted cards for up to 30 days'), findsOneWidget);

      await tester.tap(recycleBinFinder);
      await tester.pumpAndSettle();

      expect(openedRecycleBin, isTrue);
    });

    testWidgets('RecycleBinPage displays empty state when bin has no items', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: RecycleBinPage(
            activeCards: [],
            initialEntriesForTesting: [],
            currentLanguage: 'en',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recycle Bin'), findsOneWidget);
      expect(find.text('Deleted cards stay here for 30 days.'), findsOneWidget);
      expect(find.text('Your Recycle Bin is empty'), findsOneWidget);
      expect(find.text('Deleted cards will appear here for up to 30 days.'), findsOneWidget);
      expect(find.text('Empty Recycle Bin'), findsNothing);
    });

    testWidgets('RecycleBinPage displays items, badges, metadata, restore and empty actions', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.utc(2026, 11, 15, 12, 0);
      RecycleBinService.clockOverride = () => now;

      final cardWord = AACCard(id: 'c1', label: 'Sad', colorValue: 0xFF90CAF9);
      final cardFolder = AACCard(
        id: 'f1',
        label: 'More',
        colorValue: 0xFFFFCA28,
        type: 'folder',
        subCards: [
          AACCard(id: 's1', label: 'Water', colorValue: 0xFF81D4FA),
          AACCard(id: 's2', label: 'Food', colorValue: 0xFFA5D6A7),
        ],
      );

      final entries = [
        RecycleBinEntry(
          entryId: 'e1',
          card: cardWord,
          originalIndex: 0,
          deletedAtUtc: now,
        ),
        RecycleBinEntry(
          entryId: 'e2',
          card: cardFolder,
          originalIndex: 1,
          deletedAtUtc: now,
        ),
      ];

      final activeCards = <AACCard>[];
      AACCard? restoredResult;

      await tester.pumpWidget(
        MaterialApp(
          home: RecycleBinPage(
            activeCards: activeCards,
            initialEntriesForTesting: entries,
            currentLanguage: 'en',
            onRestoreCard: (restored, parentId, index) {
              restoredResult = restored;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check section header count
      expect(find.text('RECENTLY DELETED'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);

      // Check items
      expect(find.text('Sad'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      expect(find.text('2 sub-cards'), findsOneWidget);
      expect(find.text('Deleted today · 30 days left'), findsNWidgets(2));

      // Test Restore button on first item (Sad)
      final restoreBtn = find.text('Restore').first;
      await tester.tap(restoreBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(restoredResult, isNotNull);
      expect(restoredResult!.label, 'Sad');
      expect(find.text('1 item'), findsOneWidget);

      // Test Empty Recycle Bin
      final emptyBtn = find.byKey(const ValueKey('empty_recycle_bin_btn'));
      await tester.scrollUntilVisible(emptyBtn, 100);
      expect(emptyBtn, findsOneWidget);
      await tester.tap(emptyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check confirmation dialog
      expect(find.text('Empty Recycle Bin?'), findsOneWidget);
      await tester.tap(find.text('Empty'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Now empty state
      expect(find.text('Your Recycle Bin is empty'), findsOneWidget);
    });
  });

  group('5. Edit Mode Session & Undo Coordination', () {
    test('Undo removes corresponding Recycle Bin entry when card delete is undone', () async {
      final card = AACCard(id: 'c_undo', label: 'Undo Me', colorValue: 0xFF123456);
      final binEntry = await RecycleBinService.instance.moveToRecycleBin(card: card);
      expect(await RecycleBinService.instance.getEntryCount(), 1);

      // Simulating user hitting Undo: removeEntry is called with the binEntry ID
      await RecycleBinService.instance.removeEntry(binEntry.entryId, activeCards: [card]);
      expect(await RecycleBinService.instance.getEntryCount(), 0);
    });

    test('Cancel Edit Session purges all uncommitted Recycle Bin entries', () async {
      final card1 = AACCard(id: 'c_del1', label: 'Deleted 1', colorValue: 0xFF111111);
      final card2 = AACCard(id: 'c_del2', label: 'Deleted 2', colorValue: 0xFF222222);

      final entry1 = await RecycleBinService.instance.moveToRecycleBin(card: card1);
      final entry2 = await RecycleBinService.instance.moveToRecycleBin(card: card2);
      expect(await RecycleBinService.instance.getEntryCount(), 2);

      final sessionBinIds = {entry1.entryId, entry2.entryId};

      // Simulating Cancel: purges session created bin entries
      for (final id in sessionBinIds) {
        await RecycleBinService.instance.removeEntry(id, activeCards: [card1, card2]);
      }
      expect(await RecycleBinService.instance.getEntryCount(), 0);
    });
  });
}
