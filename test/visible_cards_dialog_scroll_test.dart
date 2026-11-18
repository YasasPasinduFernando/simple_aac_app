import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/widgets/visible_cards_dialog.dart';

List<AACCard> generateCards(int count) {
  return List.generate(
    count,
    (i) => AACCard(
      id: 'card_$i',
      label: i == 0 ? 'Default' : (i == count - 1 ? 'Final Card $i' : 'Card $i'),
      category: 'General',
      colorValue: 0xFF2196F3,
      type: i == 0 ? 'folder' : 'card',
    ),
  );
}

void main() {
  group('VisibleCardsDialog Scrolling and Selection Suite', () {
    testWidgets('1 Card: Displays correctly, toggles without scroll issues', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.75, 850 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = generateCards(1);
      Set<String>? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: const {'card_0'},
              onSubmit: (ids) => submitted = ids,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('visible_card_tile_card_0')), findsOneWidget);
      expect(find.text('1 of 1 visible'), findsOneWidget);

      // Uncheck card_0
      await tester.tap(find.byKey(const ValueKey('visible_card_tile_card_0')));
      await tester.pumpAndSettle();
      expect(find.text('0 of 1 visible'), findsOneWidget);

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(submitted, isEmpty);
    });

    testWidgets('5 Cards: Displays correctly and Select All / Clear All works', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.75, 850 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = generateCards(5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: const {'card_0', 'card_1'},
              onSubmit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 of 5 visible'), findsOneWidget);

      // Tap Select All
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();
      expect(find.text('5 of 5 visible'), findsOneWidget);

      // Tap Clear All
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();
      expect(find.text('0 of 5 visible'), findsOneWidget);

      // Tap Reset (clears selection filters so all cards are visible)
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('0 of 5 visible'), findsOneWidget);
    });

    testWidgets('10 Cards: Smooth scrolling to final card, toggle maintains stable scroll offset', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.75, 850 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = generateCards(10);
      final initialIds = cards.take(6).map((c) => c.id).toSet();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: initialIds,
              onSubmit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Default'), findsWidgets);
      expect(find.byKey(const ValueKey('visible_card_tile_card_0')), findsOneWidget);

      final listFinder = find.byKey(const PageStorageKey<String>('visible_cards_list_storage_key'));
      expect(listFinder, findsOneWidget);
      final scrollableFinder = find.descendant(of: listFinder, matching: find.byType(Scrollable));

      // Scroll to the bottom to reach final card (card_9)
      const finalCardKey = ValueKey('visible_card_tile_card_9');
      await tester.scrollUntilVisible(find.byKey(finalCardKey), 100, scrollable: scrollableFinder);
      await tester.pumpAndSettle();

      // Final card is fully visible
      expect(find.byKey(finalCardKey), findsOneWidget);
      expect(find.text('Final Card 9'), findsOneWidget);

      final scrollableState = tester.state<ScrollableState>(scrollableFinder);
      final offsetBeforeToggle = scrollableState.position.pixels;
      expect(offsetBeforeToggle, greaterThan(0));

      // Toggle final card
      await tester.tap(find.byKey(finalCardKey));
      await tester.pumpAndSettle();

      // Verify scroll offset did NOT reset to 0
      final offsetAfterToggle = scrollableState.position.pixels;
      expect(offsetAfterToggle, equals(offsetBeforeToggle));

      // Toggle final card again
      await tester.tap(find.byKey(finalCardKey));
      await tester.pumpAndSettle();
      expect(scrollableState.position.pixels, equals(offsetBeforeToggle));

      // Scroll back upward to card_0
      await tester.scrollUntilVisible(find.byKey(const ValueKey('visible_card_tile_card_0')), -100, scrollable: scrollableFinder);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('visible_card_tile_card_0')), findsOneWidget);

      // Scroll back downward to final card
      await tester.scrollUntilVisible(find.byKey(finalCardKey), 100, scrollable: scrollableFinder);
      await tester.pumpAndSettle();
      expect(find.byKey(finalCardKey), findsOneWidget);
    });

    testWidgets('50 Cards: Virtualized list scrolls smoothly and retains position', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.75, 850 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = generateCards(50);
      final initialIds = cards.take(20).map((c) => c.id).toSet();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: initialIds,
              onSubmit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listFinder = find.byKey(const PageStorageKey<String>('visible_cards_list_storage_key'));
      final scrollableFinder = find.descendant(of: listFinder, matching: find.byType(Scrollable));
      const finalCardKey = ValueKey('visible_card_tile_card_49');

      await tester.scrollUntilVisible(find.byKey(finalCardKey), 300, scrollable: scrollableFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(finalCardKey), findsOneWidget);

      final scrollableState = tester.state<ScrollableState>(scrollableFinder);
      final offsetBefore = scrollableState.position.pixels;

      // Toggle card 49
      await tester.tap(find.byKey(finalCardKey));
      await tester.pumpAndSettle();

      expect(scrollableState.position.pixels, equals(offsetBefore));
    });

    testWidgets('100 Cards: Large card set scrolls to end without jitter', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.75, 850 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = generateCards(100);

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
      const finalCardKey = ValueKey('visible_card_tile_card_99');

      await tester.scrollUntilVisible(find.byKey(finalCardKey), 500, scrollable: scrollableFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(finalCardKey), findsOneWidget);
    });

    testWidgets('500 Cards: High scale stress test virtualizes cleanly', (tester) async {
      tester.view.physicalSize = const Size(392 * 2.75, 850 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = generateCards(500);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: const {'card_0'},
              onSubmit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listFinder = find.byKey(const PageStorageKey<String>('visible_cards_list_storage_key'));
      final scrollableFinder = find.descendant(of: listFinder, matching: find.byType(Scrollable));
      const card50Key = ValueKey('visible_card_tile_card_50');

      // Scroll into the 500-card collection
      await tester.scrollUntilVisible(find.byKey(card50Key), 300, scrollable: scrollableFinder, maxScrolls: 100);
      await tester.pumpAndSettle();

      expect(find.byKey(card50Key), findsOneWidget);

      final scrollableState = tester.state<ScrollableState>(scrollableFinder);
      expect(scrollableState.position.pixels, greaterThan(1000));
    });

    testWidgets('Landscape Orientation: Bounded constraints and smooth scrolling', (tester) async {
      // Landscape viewport: 850 width x 392 height
      tester.view.physicalSize = const Size(850 * 2.75, 392 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = generateCards(15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: cards.take(5).map((c) => c.id).toSet(),
              onSubmit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listFinder = find.byKey(const PageStorageKey<String>('visible_cards_list_storage_key'));
      final scrollableFinder = find.descendant(of: listFinder, matching: find.byType(Scrollable));
      const finalCardKey = ValueKey('visible_card_tile_card_14');

      await tester.scrollUntilVisible(find.byKey(finalCardKey), 150, scrollable: scrollableFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(finalCardKey), findsOneWidget);

      // Verify Cancel and Done buttons are accessible
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('Cancel button dismisses without submitting changes', (tester) async {
      final cards = generateCards(5);
      Set<String>? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: cards,
              currentLanguage: 'en',
              initialSelectedIds: const {'card_0'},
              onSubmit: (ids) => submitted = ids,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Select All
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();
      expect(find.text('5 of 5 visible'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // onSubmit was never triggered
      expect(submitted, isNull);
    });
  });
}
