import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/widgets/visible_cards_dialog.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await NetworkPolicyService.instance.init();
  });

  tearDown(() {
    CardStorageService.resetTestHooks();
  });

  group('Nested Sub-card Visibility 15-Point Comprehensive Test Suite', () {
    // Helper to generate a rich folder structure:
    // Root:
    //   - card_sad (regular)
    //   - card_angry (regular)
    //   - folder_more (folder with 2 subcards)
    //   - folder_default (folder with subfolder Animals)
    //       - folder_animals (folder with 6 subcards: dog, cat, bird, fish, cow, elephant)
    //   - card_hello (regular)
    List<AACCard> buildTestCardHierarchy() {
      final dog = AACCard(id: 'c_dog', label: 'Dog', colorValue: 0xFFC8E6C9);
      final cat = AACCard(id: 'c_cat', label: 'Cat', colorValue: 0xFFE1BEE7);
      final bird = AACCard(id: 'c_bird', label: 'Bird', colorValue: 0xFFFFF9C4);
      final fish = AACCard(id: 'c_fish', label: 'Fish', colorValue: 0xFFFFE0B2);
      final cow = AACCard(id: 'c_cow', label: 'Cow', colorValue: 0xFFE8F5E9);
      final elephant = AACCard(id: 'c_elephant', label: 'Elephant', colorValue: 0xFFD7CCC8);

      final animalsFolder = AACCard(
        id: 'folder_animals',
        label: 'Animals',
        colorValue: 0xFFB2DFDB,
        type: 'folder',
        subCards: [dog, cat, bird, fish, cow, elephant],
      );

      final defaultFolder = AACCard(
        id: 'folder_default',
        label: 'Default',
        colorValue: 0xFFBBDEFB,
        type: 'folder',
        subCards: [animalsFolder],
      );

      final moreCard1 = AACCard(id: 'c_more1', label: 'Item 1', colorValue: 0xFFFFF59D);
      final moreCard2 = AACCard(id: 'c_more2', label: 'Item 2', colorValue: 0xFFFFF59D);
      final moreFolder = AACCard(
        id: 'folder_more',
        label: 'More',
        colorValue: 0xFFFFF59D,
        type: 'folder',
        subCards: [moreCard1, moreCard2],
      );

      final sad = AACCard(id: 'c_sad', label: 'Sad', colorValue: 0xFF90CAF9);
      final angry = AACCard(id: 'c_angry', label: 'Angry', colorValue: 0xFFEF9A9A);
      final hello = AACCard(id: 'c_hello', label: 'Hello', colorValue: 0xFFF8BBD0);

      return [sad, angry, moreFolder, defaultFolder, hello];
    }

    testWidgets('1. Hide an individual card updates preview & submitted selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = buildTestCardHierarchy();
      Set<String>? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: cards.map((c) => c.id).toSet(),
              onSubmit: (ids) => submitted = ids,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 of 5 visible'), findsOneWidget);

      // Uncheck "Sad" (c_sad)
      await tester.tap(find.byKey(const ValueKey('visible_card_tile_c_sad')));
      await tester.pumpAndSettle();

      expect(find.text('4 of 5 visible'), findsOneWidget);

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted, isNot(contains('c_sad')));
      expect(submitted, contains('c_angry'));
    });

    testWidgets('2. Show the same card restores visibility in preview & submitted selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = buildTestCardHierarchy();
      Set<String>? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: const {'c_angry', 'folder_more'}, // Sad is initially hidden
              onSubmit: (ids) => submitted = ids,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 of 5 visible'), findsOneWidget);

      // Check "Sad" (c_sad)
      await tester.tap(find.byKey(const ValueKey('visible_card_tile_c_sad')));
      await tester.pumpAndSettle();

      expect(find.text('3 of 5 visible'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(submitted, contains('c_sad'));
      expect(submitted, contains('c_angry'));
      expect(submitted, contains('folder_more'));
    });

    testWidgets('3. Hide a parent folder: Folder checkbox toggles root presence without touching children', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = buildTestCardHierarchy();
      Map<String, Set<String>>? savedMap;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: cards.map((c) => c.id).toSet(),
              visibleCardIdsByParent: {
                '__root__': cards.map((c) => c.id).toSet(),
                'folder_more': const {'c_more1', 'c_more2'},
              },
              onSubmit: (_) {},
              onSaveMap: (map) => savedMap = map,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Uncheck More folder tile (not the manage button)
      await tester.tap(find.byKey(const ValueKey('visible_card_tile_folder_more')));
      await tester.pumpAndSettle();

      expect(find.text('4 of 5 visible'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(savedMap, isNotNull);
      expect(savedMap!['__root__'], isNot(contains('folder_more')));
      // Children of folder_more remain completely untouched!
      expect(savedMap!['folder_more'], contains('c_more1'));
      expect(savedMap!['folder_more'], contains('c_more2'));
    });

    testWidgets('4. Show the parent folder again: Child visibility remains exactly as configured', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = buildTestCardHierarchy();
      Map<String, Set<String>>? savedMap;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: const {'c_sad', 'c_angry'}, // folder_more initially hidden at root
              visibleCardIdsByParent: const {
                '__root__': {'c_sad', 'c_angry'},
                'folder_more': {'c_more1'}, // only more1 visible, more2 hidden
              },
              onSubmit: (_) {},
              onSaveMap: (map) => savedMap = map,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Re-enable More folder at root
      await tester.tap(find.byKey(const ValueKey('visible_card_tile_folder_more')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(savedMap!['__root__'], contains('folder_more'));
      // Child configuration preserved: more1 still visible, more2 still hidden!
      expect(savedMap!['folder_more'], contains('c_more1'));
      expect(savedMap!['folder_more'], isNot(contains('c_more2')));
    });

    testWidgets('5. Phase 3 Critical Test: Animals folder child visibility independence (Dog/Cat visible, Bird hidden)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = buildTestCardHierarchy();
      Map<String, Set<String>>? savedMap;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: cards.map((c) => c.id).toSet(),
              onSubmit: (_) {},
              onSaveMap: (map) => savedMap = map,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Navigate into Default folder
      await tester.tap(find.byKey(const ValueKey('manage_subcards_folder_default')));
      await tester.pumpAndSettle();

      expect(find.text('Manage Sub-cards'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);

      // 2. Navigate into Animals folder
      await tester.tap(find.byKey(const ValueKey('manage_subcards_folder_animals')));
      await tester.pumpAndSettle();

      expect(find.text('Animals'), findsOneWidget);
      expect(find.text('6 of 6 visible'), findsOneWidget);

      // 3. Uncheck Bird and Elephant
      await tester.tap(find.byKey(const ValueKey('visible_card_tile_c_bird')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('visible_card_tile_c_elephant')));
      await tester.pumpAndSettle();

      expect(find.text('4 of 6 visible'), findsOneWidget);

      // 4. Navigate back to Default, then back to Home
      await tester.tap(find.byKey(const ValueKey('manage_subcards_back_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manage_subcards_back_button')));
      await tester.pumpAndSettle();

      expect(find.text('Visible Cards'), findsOneWidget);

      // 5. Hide Default folder at root
      await tester.tap(find.byKey(const ValueKey('visible_card_tile_folder_default')));
      await tester.pumpAndSettle();

      // 6. Save atomically with Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify: Default is hidden at root, but Animals' child settings are 100% preserved!
      expect(savedMap, isNotNull);
      expect(savedMap!['__root__'], isNot(contains('folder_default')));
      expect(savedMap!['folder_animals'], contains('c_dog'));
      expect(savedMap!['folder_animals'], contains('c_cat'));
      expect(savedMap!['folder_animals'], contains('c_fish'));
      expect(savedMap!['folder_animals'], contains('c_cow'));
      expect(savedMap!['folder_animals'], isNot(contains('c_bird')));
      expect(savedMap!['folder_animals'], isNot(contains('c_elephant')));
    });

    testWidgets('6. Manage multiple nested folders: Breadcrumb navigation and stack integrity', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = buildTestCardHierarchy();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: cards.map((c) => c.id).toSet(),
              onSubmit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate Root -> Default -> Animals
      await tester.tap(find.byKey(const ValueKey('manage_subcards_folder_default')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manage_subcards_folder_animals')));
      await tester.pumpAndSettle();

      // Verify breadcrumb bar contains Home, Default, Animals
      expect(find.byKey(const ValueKey('manage_subcards_breadcrumb_bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('manage_breadcrumb_item_0')), findsOneWidget); // Home
      expect(find.byKey(const ValueKey('manage_breadcrumb_item_1')), findsOneWidget); // Default

      // Tap "Home" in breadcrumb to jump directly to root
      await tester.tap(find.byKey(const ValueKey('manage_breadcrumb_item_0')));
      await tester.pumpAndSettle();

      expect(find.text('Visible Cards'), findsOneWidget);
      expect(find.byKey(const ValueKey('manage_subcards_breadcrumb_bar')), findsNothing);
    });

    testWidgets('7. Navigate Back with pending changes preserves draft across levels', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = buildTestCardHierarchy();
      Map<String, Set<String>>? savedMap;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: cards.map((c) => c.id).toSet(),
              onSubmit: (_) {},
              onSaveMap: (map) => savedMap = map,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate into More
      await tester.tap(find.byKey(const ValueKey('manage_subcards_folder_more')));
      await tester.pumpAndSettle();

      // Uncheck Item 2
      await tester.tap(find.byKey(const ValueKey('visible_card_tile_c_more2')));
      await tester.pumpAndSettle();
      expect(find.text('1 of 2 visible'), findsOneWidget);

      // Tap Back button
      await tester.tap(find.byKey(const ValueKey('manage_subcards_back_button')));
      await tester.pumpAndSettle();

      // Uncheck Sad at root
      await tester.tap(find.byKey(const ValueKey('visible_card_tile_c_sad')));
      await tester.pumpAndSettle();

      // Re-enter More
      await tester.tap(find.byKey(const ValueKey('manage_subcards_folder_more')));
      await tester.pumpAndSettle();

      // Item 2 should STILL be unchecked!
      expect(find.text('1 of 2 visible'), findsOneWidget);

      // Save with Done from inside the sub-folder
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(savedMap!['__root__'], isNot(contains('c_sad')));
      expect(savedMap!['folder_more'], contains('c_more1'));
      expect(savedMap!['folder_more'], isNot(contains('c_more2')));
    });

    testWidgets('8. Cancel discards all unsaved changes across all levels', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = buildTestCardHierarchy();
      Map<String, Set<String>>? savedMap;
      Set<String>? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: cards.map((c) => c.id).toSet(),
              onSubmit: (ids) => submitted = ids,
              onSaveMap: (map) => savedMap = map,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Modify root
      await tester.tap(find.byKey(const ValueKey('visible_card_tile_c_sad')));
      await tester.pumpAndSettle();

      // Modify sub-folder
      await tester.tap(find.byKey(const ValueKey('manage_subcards_folder_more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('visible_card_tile_c_more1')));
      await tester.pumpAndSettle();

      // Navigate back to root and tap Cancel
      await tester.tap(find.byKey(const ValueKey('manage_subcards_back_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Nothing submitted or saved!
      expect(submitted, isNull);
      expect(savedMap, isNull);
    });

    testWidgets('9. Save with Done commits changes atomically across root and subfolders', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = buildTestCardHierarchy();
      Map<String, Set<String>>? savedMap;
      Set<String>? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: cards.map((c) => c.id).toSet(),
              onSubmit: (ids) => submitted = ids,
              onSaveMap: (map) => savedMap = map,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(savedMap, isNotNull);
    });

    test('10. Persistence: SharedPreferences saves and loads visibleCardIdsByParent across restarts', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final initialMap = {
        '__root__': ['c_sad', 'folder_animals'],
        'folder_animals': ['c_dog', 'c_cat'],
      };

      await prefs.setString(
        'visibleCardIdsByParent',
        jsonEncode(initialMap),
      );

      final readRaw = prefs.getString('visibleCardIdsByParent');
      expect(readRaw, isNotNull);
      final decoded = jsonDecode(readRaw!) as Map<String, dynamic>;
      final restored = decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List).map((v) => v.toString()).toSet(),
        ),
      );

      expect(restored['__root__'], contains('c_sad'));
      expect(restored['__root__'], contains('folder_animals'));
      expect(restored['folder_animals'], contains('c_dog'));
      expect(restored['folder_animals'], contains('c_cat'));
      expect(restored['folder_animals'], isNot(contains('c_bird')));
    });

    test('11. Backup and Restore: Preserves nested visibleCardIdsByParent in settings payload', () async {
      final card = AACCard(id: 'c_test', label: 'Test Card', colorValue: 0xFF0284C7);
      final settings = {
        'gridColumns': 2,
        'visibleCardIdsByParent': {
          '__root__': ['c_test', 'folder_1'],
          'folder_1': ['sub_1', 'sub_2'],
        },
      };

      final zipBytes = await BackupService.buildBackupZip([card], settings: settings);
      expect(zipBytes, isNotNull);

      final restored = await BackupService.restoreFromZipBytes(zipBytes!);
      expect(restored.settings, isNotNull);
      final restoredVisible = restored.settings['visibleCardIdsByParent'] as Map;
      expect(restoredVisible['__root__'], contains('c_test'));
      expect(restoredVisible['folder_1'], contains('sub_1'));
      expect(restoredVisible['folder_1'], contains('sub_2'));
    });

    testWidgets('12. Large scale test: 100+ and 1,000+ cards initialize cleanly in VisibleCardsDialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final largeCards = List.generate(
        1000,
        (i) => AACCard(id: 'scale_$i', label: 'Scale Card $i', colorValue: 0xFF2196F3),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: largeCards,
              currentLanguage: 'en',
              initialSelectedIds: largeCards.take(500).map((c) => c.id).toSet(),
              onSubmit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('500 of 1000 visible'), findsOneWidget);
      expect(find.byKey(const ValueKey('visible_card_tile_scale_0')), findsOneWidget);
    });

    testWidgets('13. Scrolling reaches final card in a long list without clipping or crashing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = List.generate(
        30,
        (i) => AACCard(id: 'scroll_$i', label: 'Item $i', colorValue: 0xFF4CAF50),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: cards.map((c) => c.id).toSet(),
              onSubmit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listFinder = find.byKey(const PageStorageKey<String>('visible_cards_list_storage_key'));
      final scrollableFinder = find.descendant(of: listFinder, matching: find.byType(Scrollable));

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('visible_card_tile_scroll_29')),
        100,
        scrollable: scrollableFinder,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('visible_card_tile_scroll_29')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('visible_card_tile_scroll_29')),
          matching: find.text('Item 29'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('14. Responsive layout: Portrait and Landscape adapt without overflow', (tester) async {
      final cards = buildTestCardHierarchy();

      // Portrait
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: cards.map((c) => c.id).toSet(),
              onSubmit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Visible Cards'), findsOneWidget);

      // Landscape
      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: cards.map((c) => c.id).toSet(),
              onSubmit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Visible Cards'), findsOneWidget);
    });

    testWidgets('15. Category filtering remains independent of card visibility', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final food1 = AACCard(id: 'f1', label: 'Apple', category: 'Food', colorValue: 0xFFF44336);
      final food2 = AACCard(id: 'f2', label: 'Banana', category: 'Food', colorValue: 0xFFFFEB3B);

      Set<String>? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: [food1, food2],
              categoryName: 'Food',
              currentLanguage: 'en',
              initialSelectedIds: const {'f1'},
              onSubmit: (ids) => submitted = ids,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 visible'), findsOneWidget);
      expect(find.byKey(const ValueKey('visible_card_tile_f1')), findsOneWidget);
      expect(find.byKey(const ValueKey('visible_card_tile_f2')), findsOneWidget);
      expect(find.byKey(const ValueKey('visible_card_tile_t1')), findsNothing);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(submitted, equals({'f1'}));
    });
  });
}
