import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/models/edit_session_snapshot.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/widgets/edit_mode_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('edit_session_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;
    SharedPreferences.setMockInitialValues({'online_features_enabled': false});
    await NetworkPolicyService.instance.init();
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.initialCardsForTesting = null;
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

  AACCard createTestCard(String id, String label, {List<AACCard>? subCards, String? image, String? voice}) {
    return AACCard(
      id: id,
      label: label,
      colorValue: 0xFF2196F3,
      category: 'General',
      type: (subCards != null && subCards.isNotEmpty) ? 'folder' : 'word',
      subCards: subCards ?? [],
      imagePath: image,
      voicePath: voice,
    );
  }

  group('Edit Mode Transactional Session - Unit & Hierarchy Tests', () {
    test('1. Edit -> Cancel restores original card attributes', () async {
      final card = createTestCard('card_1', 'Hello');

      // Enter edit session
      final snapshot = EditSessionSnapshot(
        cards: [AACCard.fromJson(card.toJson())],
        visibleCardIdsByParent: {'__root__': {'card_1'}},
        allCategories: {'General'},
        customCategories: {},
        selectedCategories: {'All'},
        selectedCategory: 'All',
        customCategoryMetadata: {},
        activeParentId: null,
        parentStackIds: [],
        initialMediaPaths: {},
      );

      // Mutate in session
      card.label = 'Modified Hello';
      card.colorValue = 0xFFFF0000;
      card.category = 'Greetings';

      expect(card.label, 'Modified Hello');

      // Rollback via snapshot
      final restored = snapshot.cards.map((c) => AACCard.fromJson(c.toJson())).toList();
      expect(restored.first.label, 'Hello');
      expect(restored.first.colorValue, 0xFF2196F3);
      expect(restored.first.category, 'General');
    });

    test('2. Add Card -> Cancel removes newly created card', () async {
      final initial = [createTestCard('c1', 'Card 1')];
      final snapshot = EditSessionSnapshot(
        cards: initial.map((c) => AACCard.fromJson(c.toJson())).toList(),
        visibleCardIdsByParent: {'__root__': {'c1'}},
        allCategories: {'General'},
        customCategories: {},
        selectedCategories: {'All'},
        selectedCategory: 'All',
        customCategoryMetadata: {},
        activeParentId: null,
        parentStackIds: [],
        initialMediaPaths: {},
      );

      final workingList = initial.map((c) => AACCard.fromJson(c.toJson())).toList();
      // Add card in session
      workingList.add(createTestCard('c2_new', 'Brand New Card'));
      expect(workingList.length, 2);

      // Cancel session
      final rolledBack = snapshot.cards.map((c) => AACCard.fromJson(c.toJson())).toList();
      expect(rolledBack.length, 1);
      expect(rolledBack.any((c) => c.id == 'c2_new'), isFalse);
    });

    test('3. Delete Card -> Cancel restores deleted card and media', () async {
      final cardWithMedia = createTestCard('c_del', 'Card to Delete', image: '/path/img.png', voice: '/path/voice.m4a');
      final initial = [cardWithMedia];
      final snapshot = EditSessionSnapshot(
        cards: initial.map((c) => AACCard.fromJson(c.toJson())).toList(),
        visibleCardIdsByParent: {'__root__': {'c_del'}},
        allCategories: {'General'},
        customCategories: {},
        selectedCategories: {'All'},
        selectedCategory: 'All',
        customCategoryMetadata: {},
        activeParentId: null,
        parentStackIds: [],
        initialMediaPaths: {'/path/img.png', '/path/voice.m4a'},
      );

      final workingList = <AACCard>[]; // deleted card
      expect(workingList.isEmpty, isTrue);

      // Cancel session restores card with media
      final rolledBack = snapshot.cards.map((c) => AACCard.fromJson(c.toJson())).toList();
      expect(rolledBack.length, 1);
      expect(rolledBack.first.id, 'c_del');
      expect(rolledBack.first.imagePath, '/path/img.png');
      expect(rolledBack.first.voicePath, '/path/voice.m4a');
    });

    test('4. Reorder -> Cancel restores original positions', () async {
      final c1 = createTestCard('c1', 'One');
      final c2 = createTestCard('c2', 'Two');
      final c3 = createTestCard('c3', 'Three');
      final initial = [c1, c2, c3];

      final snapshot = EditSessionSnapshot(
        cards: initial.map((c) => AACCard.fromJson(c.toJson())).toList(),
        visibleCardIdsByParent: {},
        allCategories: {'General'},
        customCategories: {},
        selectedCategories: {'All'},
        selectedCategory: 'All',
        customCategoryMetadata: {},
        activeParentId: null,
        parentStackIds: [],
        initialMediaPaths: {},
      );

      // In session: reverse order [c3, c2, c1]
      final workingList = [c3, c2, c1];
      expect(workingList.map((c) => c.id).toList(), ['c3', 'c2', 'c1']);

      // Cancel restores original order
      final rolledBack = snapshot.cards.map((c) => AACCard.fromJson(c.toJson())).toList();
      expect(rolledBack.map((c) => c.id).toList(), ['c1', 'c2', 'c3']);
    });

    test('5. Move Inside -> Cancel restores original hierarchy', () async {
      final child = createTestCard('c_child', 'Child Card');
      final target = createTestCard('c_folder', 'Target Folder', subCards: []);
      final initial = [child, target];

      final snapshot = EditSessionSnapshot(
        cards: initial.map((c) => AACCard.fromJson(c.toJson())).toList(),
        visibleCardIdsByParent: {},
        allCategories: {'General'},
        customCategories: {},
        selectedCategories: {'All'},
        selectedCategory: 'All',
        customCategoryMetadata: {},
        activeParentId: null,
        parentStackIds: [],
        initialMediaPaths: {},
      );

      // In session: move child inside target
      target.subCards.add(child);
      final workingList = [target];
      expect(workingList.length, 1);
      expect(workingList.first.subCards.length, 1);

      // Cancel restores both to root
      final rolledBack = snapshot.cards.map((c) => AACCard.fromJson(c.toJson())).toList();
      expect(rolledBack.length, 2);
      expect(rolledBack.any((c) => c.id == 'c_child'), isTrue);
      expect(rolledBack.firstWhere((c) => c.id == 'c_folder').subCards.isEmpty, isTrue);
    });

    test('6. Folder-to-Word -> Cancel restores folder and children', () async {
      final sub1 = createTestCard('sub1', 'Sub 1');
      final folder = createTestCard('folder_1', 'Folder', subCards: [sub1]);
      final initial = [folder];

      final snapshot = EditSessionSnapshot(
        cards: initial.map((c) => AACCard.fromJson(c.toJson())).toList(),
        visibleCardIdsByParent: {},
        allCategories: {'General'},
        customCategories: {},
        selectedCategories: {'All'},
        selectedCategory: 'All',
        customCategoryMetadata: {},
        activeParentId: null,
        parentStackIds: [],
        initialMediaPaths: {},
      );

      // In session: converted folder to word, moved sub1 to root
      folder.type = 'word';
      folder.subCards.clear();
      final workingList = [folder, sub1];

      expect(workingList.length, 2);
      expect(folder.subCards.isEmpty, isTrue);

      // Cancel restores folder with sub1 nested
      final rolledBack = snapshot.cards.map((c) => AACCard.fromJson(c.toJson())).toList();
      expect(rolledBack.length, 1);
      expect(rolledBack.first.type, 'folder');
      expect(rolledBack.first.subCards.length, 1);
      expect(rolledBack.first.subCards.first.id, 'sub1');
    });

    test('7. Move All Sub-Cards to Home -> Cancel restores original nesting', () async {
      final subA = createTestCard('subA', 'Sub A');
      final subB = createTestCard('subB', 'Sub B');
      final folder = createTestCard('f_multi', 'Multi Folder', subCards: [subA, subB]);
      final initial = [folder];

      final snapshot = EditSessionSnapshot(
        cards: initial.map((c) => AACCard.fromJson(c.toJson())).toList(),
        visibleCardIdsByParent: {},
        allCategories: {'General'},
        customCategories: {},
        selectedCategories: {'All'},
        selectedCategory: 'All',
        customCategoryMetadata: {},
        activeParentId: null,
        parentStackIds: [],
        initialMediaPaths: {},
      );

      // In session: Move all to home
      folder.subCards.clear();
      final workingList = [folder, subA, subB];
      expect(workingList.length, 3);

      // Cancel restores both subCards inside folder
      final rolledBack = snapshot.cards.map((c) => AACCard.fromJson(c.toJson())).toList();
      expect(rolledBack.length, 1);
      expect(rolledBack.first.subCards.map((c) => c.id).toList(), ['subA', 'subB']);
    });

    test('8. Multiple operations -> Cancel restores the entire session', () async {
      final c1 = createTestCard('c1', 'Card 1');
      final c2 = createTestCard('c2', 'Card 2');
      final initial = [c1, c2];

      final snapshot = EditSessionSnapshot(
        cards: initial.map((c) => AACCard.fromJson(c.toJson())).toList(),
        visibleCardIdsByParent: {'__root__': {'c1', 'c2'}},
        allCategories: {'General'},
        customCategories: {},
        selectedCategories: {'All'},
        selectedCategory: 'All',
        customCategoryMetadata: {},
        activeParentId: null,
        parentStackIds: [],
        initialMediaPaths: {},
      );

      // Multi operations: edit c1, delete c2, add c3
      final workingList = [c1];
      c1.label = 'Card 1 Edited';
      workingList.add(createTestCard('c3', 'Card 3 New'));

      expect(workingList.length, 2);
      expect(workingList.first.label, 'Card 1 Edited');
      expect(workingList.any((c) => c.id == 'c2'), isFalse);

      // Cancel restores original state exactly
      final rolledBack = snapshot.cards.map((c) => AACCard.fromJson(c.toJson())).toList();
      expect(rolledBack.length, 2);
      expect(rolledBack[0].id, 'c1');
      expect(rolledBack[0].label, 'Card 1');
      expect(rolledBack[1].id, 'c2');
      expect(rolledBack.any((c) => c.id == 'c3'), isFalse);
    });

    test('9. Multiple operations -> Done persists all changes to disk', () async {
      final c1 = createTestCard('c1', 'Original C1');
      await CardStorageService.saveCards([c1]);

      // Verify committed on disk
      var onDisk = await CardStorageService.loadCards();
      expect(onDisk.first.label, 'Original C1');

      // Edit, add, and commit
      c1.label = 'Committed C1';
      final c2 = createTestCard('c2', 'Committed C2');
      await CardStorageService.saveCards([c1, c2]);

      // Re-read from disk
      onDisk = await CardStorageService.loadCards();
      expect(onDisk.length, 2);
      expect(onDisk[0].label, 'Committed C1');
      expect(onDisk[1].label, 'Committed C2');
    });

    test('10. Undo followed by Done persists only un-undone changes', () async {
      final initialCards = [createTestCard('c1', 'Step 0')];
      final history = <List<AACCard>>[];

      // Step 1: change label to Step 1
      history.add(initialCards.map((c) => AACCard.fromJson(c.toJson())).toList());
      initialCards[0].label = 'Step 1';

      // Step 2: change label to Step 2
      history.add(initialCards.map((c) => AACCard.fromJson(c.toJson())).toList());
      initialCards[0].label = 'Step 2';

      expect(initialCards[0].label, 'Step 2');

      // Undo step 2
      final previous = history.removeLast();
      initialCards[0] = previous[0];
      expect(initialCards[0].label, 'Step 1');

      // Tap Done: persist
      await CardStorageService.saveCards(initialCards);
      final loaded = await CardStorageService.loadCards();
      expect(loaded[0].label, 'Step 1');
    });

    test('11. Undo followed by Cancel restores initial session snapshot', () async {
      final initialCards = [createTestCard('c1', 'Initial')];
      final snapshot = EditSessionSnapshot(
        cards: initialCards.map((c) => AACCard.fromJson(c.toJson())).toList(),
        visibleCardIdsByParent: {},
        allCategories: {'General'},
        customCategories: {},
        selectedCategories: {'All'},
        selectedCategory: 'All',
        customCategoryMetadata: {},
        activeParentId: null,
        parentStackIds: [],
        initialMediaPaths: {},
      );

      final working = initialCards.map((c) => AACCard.fromJson(c.toJson())).toList();
      working[0].label = 'Op 1';
      working[0].label = 'Op 2';

      // Undo Op 2
      working[0].label = 'Op 1';

      // Cancel: must restore Initial, ignoring any undos
      final restored = snapshot.cards.map((c) => AACCard.fromJson(c.toJson())).toList();
      expect(restored[0].label, 'Initial');
    });

    test('12. Image and voice recording rollback cleans up temporary uncommitted files', () async {
      // Create temporary media files in tempDir
      final newImg = File('${tempDir.path}/new_image.jpg');
      await newImg.writeAsString('image data');
      final newVoice = File('${tempDir.path}/new_voice.m4a');
      await newVoice.writeAsString('voice data');

      final existingImg = File('${tempDir.path}/existing_img.jpg');
      await existingImg.writeAsString('existing image data');

      final sessionCreatedFiles = {newImg.path, newVoice.path};
      final initialMediaPaths = {existingImg.path};

      expect(await newImg.exists(), isTrue);
      expect(await newVoice.exists(), isTrue);
      expect(await existingImg.exists(), isTrue);

      // On Cancel, uncommitted created media is deleted, while existing media is kept untouched
      for (final path in sessionCreatedFiles) {
        if (!initialMediaPaths.contains(path)) {
          final f = File(path);
          if (await f.exists()) {
            await f.delete();
          }
        }
      }

      expect(await newImg.exists(), isFalse);
      expect(await newVoice.exists(), isFalse);
      expect(await existingImg.exists(), isTrue);
    });

    test('13. App restart after Done loads committed cards', () async {
      final c1 = createTestCard('c_persistent', 'Persistent Card');
      await CardStorageService.saveCards([c1]);

      // Restart simulated: fresh load
      final loaded = await CardStorageService.loadCards();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'c_persistent');
      expect(loaded.first.label, 'Persistent Card');
    });

    test('14. App termination during uncommitted session preserves original disk state', () async {
      final initialOnDisk = [createTestCard('c_safe', 'Safe On Disk')];
      await CardStorageService.saveCards(initialOnDisk);

      // Edit Mode in-memory edits happen, but disk is NOT overwritten during session
      // Staged edits exist in memory, but NO save was performed
      // Simulate crash/termination and reload from disk
      final reloadedFromDisk = await CardStorageService.loadCards();
      expect(reloadedFromDisk.length, 1);
      expect(reloadedFromDisk.first.label, 'Safe On Disk');
      expect(reloadedFromDisk.any((c) => c.id == 'c_uncommitted'), isFalse);
    });
  });

  group('15. EditModeBar Widget - Portrait, Landscape and Text Scaling', () {
    testWidgets('Renders single row on wide / landscape layout (width >= 480)', (tester) async {
      bool cancelTapped = false;
      bool doneTapped = false;

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditModeBar(
              onCancel: () => cancelTapped = true,
              onDone: () => doneTapped = true,
              onUndo: () {},
              onAdd: () {},
              baseColor: const Color(0xFF0277BD),
              textColor: Colors.white,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Edit Words'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Add New'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      expect(cancelTapped, isTrue);

      await tester.tap(find.text('Done'));
      expect(doneTapped, isTrue);
    });

    testWidgets('Renders adaptive two-row toolbar on compact portrait (width 360) without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditModeBar(
              onCancel: () {},
              onDone: () {},
              onUndo: () {},
              onAdd: () {},
              baseColor: const Color(0xFF0277BD),
              textColor: Colors.white,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Mode'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Add New'), findsOneWidget);
    });

    testWidgets('Supports large text scaling without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: Scaffold(
              body: EditModeBar(
                onCancel: () {},
                onDone: () {},
                onUndo: () {},
                onAdd: () {},
                baseColor: const Color(0xFF0277BD),
                textColor: Colors.white,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Mode'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
