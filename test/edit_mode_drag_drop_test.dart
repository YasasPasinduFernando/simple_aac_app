import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/widgets/edit_mode_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Drag, Reorder, Move Inside, and Undo Logic Tests', () {
    late List<AACCard> cards;
    late List<EditUndoStep> undoStack;

    AACCard createCard(String id, String label, {List<AACCard>? subCards}) {
      return AACCard(
        id: id,
        label: label,
        labelSinhala: '$label සිංහල',
        labelTamil: '$label தமிழ்',
        type: (subCards != null && subCards.isNotEmpty) ? 'folder' : 'action',
        colorValue: 0xFF2196F3,
        subCards: subCards ?? [],
      );
    }

    List<AACCard> cloneCards(List<AACCard> source) {
      return source.map((c) => AACCard.fromJson(c.toJson())).toList();
    }

    bool isDescendantOf(AACCard potentialDescendant, AACCard ancestor) {
      if (potentialDescendant.id == ancestor.id) return true;
      for (final child in ancestor.subCards) {
        if (isDescendantOf(potentialDescendant, child)) return true;
      }
      return false;
    }

    void recordUndoStep(String desc, List<AACCard> currentCards) {
      undoStack.add(
        EditUndoStep(
          cards: cloneCards(currentCards),
          visibleMap: {},
          activeParentId: null,
          parentStackIds: [],
          description: desc,
        ),
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      undoStack = [];
      cards = [
        createCard('c1', 'Hello'),
        createCard('c2', 'Thank You'),
        createCard('c3', 'Happy'),
        createCard('c4', 'More', subCards: [
          createCard('c4_1', 'Water'),
          createCard('c4_2', 'Food'),
        ]),
      ];
    });

    test('Reordering siblings: moves Happy ahead of Hello and records undo', () {
      recordUndoStep('Reorder cards', cards);

      // Reorder: move 'Happy' (c3 at index 2) to index 0 (ahead of 'Hello')
      final dragged = cards.removeAt(2); // c3 Happy
      cards.insert(0, dragged);

      expect(cards[0].id, 'c3');
      expect(cards[1].id, 'c1');
      expect(cards[2].id, 'c2');
      expect(cards[3].id, 'c4');

      // Verify Undo restores original order
      expect(undoStack.isNotEmpty, isTrue);
      final lastStep = undoStack.removeLast();
      cards = lastStep.cards;

      expect(cards[0].id, 'c1');
      expect(cards[1].id, 'c2');
      expect(cards[2].id, 'c3');
      expect(cards[3].id, 'c4');
    });

    test('Moving card into existing card with sub-cards: Happy into More', () {
      recordUndoStep('Move Happy into More', cards);

      // Move Happy (c3) into More (c4)
      final happyIndex = cards.indexWhere((c) => c.id == 'c3');
      final happyCard = cards.removeAt(happyIndex);

      final moreCard = cards.firstWhere((c) => c.id == 'c4');
      moreCard.subCards.add(happyCard);
      moreCard.type = 'folder';

      // Verify Happy is removed from root and present in More
      expect(cards.any((c) => c.id == 'c3'), isFalse);
      expect(moreCard.subCards.length, 3);
      expect(moreCard.subCards[2].id, 'c3');
      expect(moreCard.subCards[0].id, 'c4_1');
      expect(moreCard.subCards[1].id, 'c4_2');

      // Undo restores Happy to root and More to original sub-cards
      final lastStep = undoStack.removeLast();
      cards = lastStep.cards;

      expect(cards.any((c) => c.id == 'c3'), isTrue);
      final restoredMore = cards.firstWhere((c) => c.id == 'c4');
      expect(restoredMore.subCards.length, 2);
      expect(restoredMore.subCards.any((c) => c.id == 'c3'), isFalse);
    });

    test('Moving card into card with NO existing children: Thank You into Hello', () {
      recordUndoStep('Move Thank You into Hello', cards);

      final helloCard = cards.firstWhere((c) => c.id == 'c1');
      expect(helloCard.subCards.isEmpty, isTrue);

      final tyIndex = cards.indexWhere((c) => c.id == 'c2');
      final tyCard = cards.removeAt(tyIndex);

      helloCard.subCards.add(tyCard);
      helloCard.type = 'folder';

      expect(cards.any((c) => c.id == 'c2'), isFalse);
      expect(helloCard.subCards.length, 1);
      expect(helloCard.subCards.first.id, 'c2');
      expect(helloCard.type, 'folder');

      // Undo restores Thank You
      final lastStep = undoStack.removeLast();
      cards = lastStep.cards;
      expect(cards.any((c) => c.id == 'c2'), isTrue);
      final restoredHello = cards.firstWhere((c) => c.id == 'c1');
      expect(restoredHello.subCards.isEmpty, isTrue);
    });

    test('Cycle prevention: cannot move ancestor into descendant', () {
      final moreCard = cards.firstWhere((c) => c.id == 'c4');
      final waterCard = moreCard.subCards.firstWhere((c) => c.id == 'c4_1');

      // Check isDescendantOf: More is ancestor of Water, so moving More into Water is invalid
      expect(isDescendantOf(waterCard, moreCard), isTrue);

      // Self-check: cannot move card into itself
      expect(isDescendantOf(moreCard, moreCard), isTrue);

      // Unrelated card is not a descendant
      final happyCard = cards.firstWhere((c) => c.id == 'c3');
      expect(isDescendantOf(happyCard, moreCard), isFalse);
    });

    test('Moving sub-card back to root: Water from More up to root', () {
      final moreCard = cards.firstWhere((c) => c.id == 'c4');
      recordUndoStep('Move Water up to Home', cards);

      final waterCard = moreCard.subCards.firstWhere((c) => c.id == 'c4_1');
      moreCard.subCards.removeWhere((c) => c.id == 'c4_1');
      cards.add(waterCard);

      expect(moreCard.subCards.length, 1);
      expect(cards.any((c) => c.id == 'c4_1'), isTrue);

      // Undo
      final lastStep = undoStack.removeLast();
      cards = lastStep.cards;

      final restoredMore = cards.firstWhere((c) => c.id == 'c4');
      expect(restoredMore.subCards.length, 2);
      expect(restoredMore.subCards.any((c) => c.id == 'c4_1'), isTrue);
      expect(cards.any((c) => c.id == 'c4_1'), isFalse);
    });

    test('Consecutive multi-step Undo reverses operations in exact LIFO order', () {
      // Step 1: Reorder c1 and c2
      recordUndoStep('Step 1: Reorder', cards);
      final item = cards.removeAt(0); // c1
      cards.insert(1, item); // [c2, c1, c3, c4]

      // Step 2: Move c3 into c4
      recordUndoStep('Step 2: Move inside', cards);
      final c3 = cards.removeAt(2); // c3
      cards.firstWhere((c) => c.id == 'c4').subCards.add(c3);

      // Verify current state
      expect(cards.map((c) => c.id).toList(), ['c2', 'c1', 'c4']);
      expect(cards.last.subCards.map((c) => c.id).toList(), ['c4_1', 'c4_2', 'c3']);

      // Undo Step 2
      final step2 = undoStack.removeLast();
      cards = step2.cards;
      expect(cards.map((c) => c.id).toList(), ['c2', 'c1', 'c3', 'c4']);
      expect(cards.last.subCards.length, 2);

      // Undo Step 1
      final step1 = undoStack.removeLast();
      cards = step1.cards;
      expect(cards.map((c) => c.id).toList(), ['c1', 'c2', 'c3', 'c4']);
    });
  });

  group('Edit Mode Bar and Hint Widget Tests', () {
    testWidgets('EditModeBar renders with Done and Undo and calls callbacks',
        (tester) async {
      bool doneCalled = false;
      bool undoCalled = false;
      bool addCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditModeBar(
              onDone: () => doneCalled = true,
              onUndo: () => undoCalled = true,
              onAdd: () => addCalled = true,
              baseColor: const Color(0xFF0277BD),
              textColor: Colors.white,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Words'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Add New'), findsOneWidget);

      await tester.tap(find.text('Done'));
      expect(doneCalled, isTrue);

      await tester.tap(find.text('Undo'));
      expect(undoCalled, isTrue);

      await tester.tap(find.text('Add New'));
      expect(addCalled, isTrue);
    });
  });
}
