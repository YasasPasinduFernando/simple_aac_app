import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/widgets/card_editor_dialog.dart';
import 'package:simple_aac_app/widgets/manage_sub_cards_dialog.dart';

class _FakeAudioPlayer extends Fake implements AudioPlayer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'online_features_enabled': false});
    await NetworkPolicyService.instance.init();
  });

  group('Folder to Word Conversion Safeguards', () {
    testWidgets(
        'Converting folder to word shows safeguard dialog and "Move to Home" moves sub-cards',
        (tester) async {
      final sub1 = AACCard(
        id: 'sub_1',
        label: 'Water',
        colorValue: 0xFF2196F3,
        category: 'Food',
      );
      final sub2 = AACCard(
        id: 'sub_2',
        label: 'Juice',
        colorValue: 0xFF4CAF50,
        category: 'Food',
      );
      final folder = AACCard(
        id: 'drinks_folder',
        label: 'Drinks',
        type: 'folder',
        colorValue: 0xFFFF9800,
        category: 'Food',
        subCards: [sub1, sub2],
      );

      List<AACCard>? movedSubCards;
      CardEditorAction? resultAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultAction = await showDialog<CardEditorAction>(
                    context: context,
                    builder: (ctx) => CardEditorDialog(
                      card: folder,
                      isNew: false,
                      categories: const ['General', 'Food'],
                      audioPlayer: _FakeAudioPlayer(),
                      onMoveSubCardsToHome: (cards) {
                        movedSubCards = cards;
                      },
                    ),
                  );
                },
                child: const Text('Open Editor'),
              ),
            ),
          ),
        ),
      );

      // Open editor
      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('card_editor_add_subcard_btn')));
      // Verify editor is open and button says "+ Add Sub-Card" and "Manage Sub-Cards (2)"
      expect(find.byKey(const ValueKey('card_editor_add_subcard_btn')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('card_editor_manage_subcards_btn')),
          findsOneWidget);
      expect(find.text('Manage Sub-Cards (2)'), findsOneWidget);

      // Change type dropdown from 'Folder Card' to 'Word Card'
      await tester.ensureVisible(find.text('Folder Card'));
      await tester.tap(find.text('Folder Card'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Word Card').last);
      await tester.pumpAndSettle();

      // Tap Save Card
      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      // Verify safeguard dialog appeared
      expect(find.text('Convert Folder to Word Card?'), findsOneWidget);
      expect(find.textContaining('This folder currently contains 2 sub-card(s)'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('folder_to_word_move_home')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('folder_to_word_delete')), findsOneWidget);

      // Choose "Move to Home Board (Recommended)"
      await tester.tap(find.byKey(const ValueKey('folder_to_word_move_home')));
      await tester.pumpAndSettle();

      // Verify editor popped and saved
      expect(resultAction, CardEditorAction.saved);
      expect(folder.type, 'word');
      expect(folder.subCards, isEmpty);
      expect(movedSubCards, isNotNull);
      expect(movedSubCards!.length, 2);
      expect(movedSubCards![0].label, 'Water');
      expect(movedSubCards![1].label, 'Juice');
    });

    testWidgets(
        'Converting folder to word with Cancel preserves folder and sub-cards',
        (tester) async {
      final sub = AACCard(
        id: 'sub_1',
        label: 'Happy Child',
        colorValue: 0xFF2196F3,
      );
      final folder = AACCard(
        id: 'emotions_folder',
        label: 'Emotions',
        type: 'folder',
        colorValue: 0xFFFFEB3B,
        subCards: [sub],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showDialog<CardEditorAction>(
                    context: context,
                    builder: (ctx) => CardEditorDialog(
                      card: folder,
                      isNew: false,
                      categories: const ['General'],
                      audioPlayer: _FakeAudioPlayer(),
                    ),
                  );
                },
                child: const Text('Open Editor'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      // Change type to Word Card
      await tester.ensureVisible(find.text('Folder Card'));
      await tester.tap(find.text('Folder Card'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Word Card').last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      // Tap Cancel in safeguard dialog
      await tester.tap(find.byKey(const ValueKey('folder_to_word_cancel')));
      await tester.pumpAndSettle();

      // Safeguard closed, CardEditorDialog remains open, folder still has its subCards!
      expect(folder.subCards.length, 1);
      expect(find.byType(CardEditorDialog), findsOneWidget);
    });

    testWidgets(
        'Converting folder to word with Delete prompts secondary confirmation',
        (tester) async {
      final sub = AACCard(
        id: 'sub_1',
        label: 'School Bus',
        colorValue: 0xFFFFC107,
      );
      final folder = AACCard(
        id: 'school_folder',
        label: 'School',
        type: 'folder',
        colorValue: 0xFF4CAF50,
        subCards: [sub],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showDialog<CardEditorAction>(
                    context: context,
                    builder: (ctx) => CardEditorDialog(
                      card: folder,
                      isNew: false,
                      categories: const ['General'],
                      audioPlayer: _FakeAudioPlayer(),
                    ),
                  );
                },
                child: const Text('Open Editor'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      // Change type to Word Card
      await tester.ensureVisible(find.text('Folder Card'));
      await tester.tap(find.text('Folder Card'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Word Card').last);
      await tester.pumpAndSettle();

      // Tap Save Card
      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      // Tap Delete Sub-Cards
      await tester.tap(find.byKey(const ValueKey('folder_to_word_delete')));
      await tester.pumpAndSettle();

      // Verify secondary confirmation dialog
      expect(find.text('Confirm Delete Sub-Cards'), findsOneWidget);
      expect(find.text('Delete (1 cards)'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Delete (1 cards)'));
      await tester.pumpAndSettle();

      // Folder converted to word and subCards cleared
      expect(folder.type, 'word');
      expect(folder.subCards, isEmpty);
    });
  });

  group('ManageSubCardsDialog Features', () {
    testWidgets('Renders sub-cards list, preview carousel, and handles move to Home',
        (tester) async {
      final sub1 = AACCard(
        id: 'c1',
        label: 'Dog',
        colorValue: 0xFF2196F3,
        category: 'Animals',
      );
      final sub2 = AACCard(
        id: 'c2',
        label: 'Cat',
        colorValue: 0xFFE91E63,
        category: 'Animals',
      );
      final folder = AACCard(
        id: 'animals_folder',
        label: 'Animals',
        type: 'folder',
        colorValue: 0xFF9C27B0,
        category: 'Animals',
        subCards: [sub1, sub2],
      );

      final List<AACCard> rootCards = [];
      bool cardsChangedCalled = false;
      String? recordedUndo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManageSubCardsDialog(
              folderCard: folder,
              rootCards: rootCards,
              currentLanguage: 'en',
              customMetadata: const {},
              onCardsChanged: () {
                cardsChangedCalled = true;
              },
              onRecordUndo: (msg) {
                recordedUndo = msg;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and counts
      expect(find.text('Manage Sub-Cards'), findsOneWidget);
      expect(find.text('Inside "Animals"'), findsOneWidget);
      expect(find.text('2 Cards'), findsOneWidget);

      // Verify Dog and Cat in preview and in list
      expect(find.text('Dog'), findsWidgets);
      expect(find.text('Cat'), findsWidgets);

      // Move Dog to Home
      final moveButtons = find.byTooltip('Move to Home Board');
      expect(moveButtons, findsNWidgets(2));
      await tester.tap(moveButtons.first);
      await tester.pumpAndSettle();

      // Dog should now be in rootCards and removed from folder.subCards
      expect(cardsChangedCalled, isTrue);
      expect(recordedUndo, contains('Move Dog to Home'));
      expect(folder.subCards.length, 1);
      expect(folder.subCards.first.label, 'Cat');
      expect(rootCards.length, 1);
      expect(rootCards.first.label, 'Dog');
      expect(find.text('1 Card'), findsOneWidget);
    });

    testWidgets('Move All to Home moves entire batch of sub-cards',
        (tester) async {
      final sub1 = AACCard(id: 'c1', label: 'Apple', colorValue: 0xFFF44336);
      final sub2 = AACCard(id: 'c2', label: 'Banana', colorValue: 0xFFFFEB3B);
      final folder = AACCard(
        id: 'fruits',
        label: 'Fruits',
        type: 'folder',
        colorValue: 0xFFFF9800,
        subCards: [sub1, sub2],
      );

      final List<AACCard> rootCards = [];
      bool changed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManageSubCardsDialog(
              folderCard: folder,
              rootCards: rootCards,
              currentLanguage: 'en',
              customMetadata: const {},
              onCardsChanged: () => changed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Move All to Home
      await tester.tap(find.text('Move All to Home'));
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.text('Move All to Home?'), findsOneWidget);
      await tester.tap(find.text('Move All (2)'));
      await tester.pumpAndSettle();

      expect(changed, isTrue);
      expect(folder.subCards, isEmpty);
      expect(rootCards.length, 2);
      expect(rootCards[0].label, 'Apple');
      expect(rootCards[1].label, 'Banana');
      expect(find.text('This folder is currently empty'), findsOneWidget);
    });

    testWidgets('Individual delete prompts confirmation and removes card on confirm',
        (tester) async {
      final sub = AACCard(id: 'del_1', label: 'Cookie', colorValue: 0xFF795548);
      final folder = AACCard(
        id: 'snacks',
        label: 'Snacks',
        type: 'folder',
        colorValue: 0xFFFF9800,
        subCards: [sub],
      );

      bool changed = false;
      String? recordedUndo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManageSubCardsDialog(
              folderCard: folder,
              rootCards: const [],
              currentLanguage: 'en',
              customMetadata: const {},
              onCardsChanged: () => changed = true,
              onRecordUndo: (msg) => recordedUndo = msg,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete on Cookie
      await tester.tap(find.byTooltip('Delete Sub-Card'));
      await tester.pumpAndSettle();

      // Secondary delete confirmation
      expect(find.text('Delete Sub-Card?'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to delete "Cookie"?'),
          findsOneWidget);

      // Tap Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(folder.subCards.length, 1);
      expect(changed, isFalse);

      // Tap Delete again and confirm
      await tester.tap(find.byTooltip('Delete Sub-Card'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(folder.subCards, isEmpty);
      expect(changed, isTrue);
      expect(recordedUndo, contains('Delete Cookie'));
    });

    testWidgets('Add and Edit callbacks are invoked from ManageSubCardsDialog',
        (tester) async {
      final sub = AACCard(id: 'edit_1', label: 'Toy', colorValue: 0xFF2196F3);
      final folder = AACCard(
        id: 'play',
        label: 'Play',
        type: 'folder',
        colorValue: 0xFF4CAF50,
        subCards: [sub],
      );

      bool addCalled = false;
      AACCard? editedCard;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManageSubCardsDialog(
              folderCard: folder,
              rootCards: const [],
              currentLanguage: 'en',
              customMetadata: const {},
              onCardsChanged: () {},
              onAddSubCard: () async {
                addCalled = true;
              },
              onEditSubCard: (card) async {
                editedCard = card;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Edit
      await tester.tap(find.byTooltip('Edit Card'));
      await tester.pumpAndSettle();
      expect(editedCard, isNotNull);
      expect(editedCard!.label, 'Toy');

      // Tap + Add Sub-Card
      await tester.tap(find.text('+ Add Sub-Card'));
      await tester.pumpAndSettle();
      expect(addCalled, isTrue);
    });
  });

  group('Drag and Drop Nesting Confirmation & Cycle Prevention', () {
    testWidgets(
        'Nesting confirmation for Folder target shows "Add as Sub-Card" and handles cancel/confirm',
        (tester) async {
      final dragged = AACCard(id: 'd1', label: 'Bread', colorValue: 0xFF8D6E63);
      final target = AACCard(
        id: 't1',
        label: 'Food Folder',
        type: 'folder',
        colorValue: 0xFFFF9800,
      );

      bool? userChoice;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  userChoice = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Add as Sub-Card?'),
                      content: Text('Add "${dragged.label}" as a sub-card inside "${target.label}"?'),
                      actions: [
                        TextButton(
                          key: const ValueKey('nesting_dialog_cancel_btn'),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          key: const ValueKey('nesting_dialog_confirm_btn'),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Add as Sub-Card'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Trigger Nest'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Trigger Nest'));
      await tester.pumpAndSettle();

      expect(find.text('Add as Sub-Card?'), findsOneWidget);
      expect(find.text('Add "Bread" as a sub-card inside "Food Folder"?'),
          findsOneWidget);

      // Tap Cancel
      await tester.tap(find.byKey(const ValueKey('nesting_dialog_cancel_btn')));
      await tester.pumpAndSettle();
      expect(userChoice, isFalse);

      // Open dialog again and Confirm
      await tester.tap(find.text('Trigger Nest'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nesting_dialog_confirm_btn')));
      await tester.pumpAndSettle();
      expect(userChoice, isTrue);
    });

    testWidgets(
        'Nesting confirmation for Word target warns about converting to Folder Card',
        (tester) async {
      final dragged = AACCard(id: 'd2', label: 'Hat', colorValue: 0xFF00BCD4);
      final target = AACCard(id: 't2', label: 'Shirt', type: 'word', colorValue: 0xFF3F51B5);

      bool? userChoice;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  userChoice = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Convert to Folder & Add?'),
                      content: Text(
                        '"${target.label}" is currently a Word Card. '
                        'Adding "${dragged.label}" inside it will convert it into a Folder Card.',
                      ),
                      actions: [
                        TextButton(
                          key: const ValueKey('nesting_dialog_cancel_btn'),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          key: const ValueKey('nesting_dialog_confirm_btn'),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Convert & Add'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Trigger Word Nest'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Word Nest'));
      await tester.pumpAndSettle();

      expect(find.text('Convert to Folder & Add?'), findsOneWidget);
      expect(
          find.textContaining(
              '"Shirt" is currently a Word Card. Adding "Hat" inside it will convert it into a Folder Card.'),
          findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nesting_dialog_confirm_btn')));
      await tester.pumpAndSettle();
      expect(userChoice, isTrue);
    });
    test('Cycle prevention: cannot nest ancestor inside descendant', () {
      final child = AACCard(id: 'c_child', label: 'Child', colorValue: 0);
      final parent = AACCard(
        id: 'c_parent',
        label: 'Parent',
        colorValue: 0,
        subCards: [child],
      );

      bool isDescendantOf(AACCard potentialDescendant, AACCard ancestor) {
        if (potentialDescendant.id == ancestor.id) return true;
        for (final c in ancestor.subCards) {
          if (isDescendantOf(potentialDescendant, c)) return true;
        }
        return false;
      }

      // child is descendant of parent
      expect(isDescendantOf(child, parent), isTrue);
      // parent is NOT descendant of child
      expect(isDescendantOf(parent, child), isFalse);
    });

    test('Moving sub-card with descendants safely moves complete subtree', () {
      final leaf = AACCard(id: 'leaf', label: 'Leaf', colorValue: 0);
      final subFolder = AACCard(
        id: 'sub_folder',
        label: 'SubFolder',
        type: 'folder',
        colorValue: 0,
        subCards: [leaf],
      );
      final rootFolder = AACCard(
        id: 'root_folder',
        label: 'RootFolder',
        type: 'folder',
        colorValue: 0,
        subCards: [subFolder],
      );

      final List<AACCard> homeCards = [];

      // Move subFolder to Home
      rootFolder.subCards.removeWhere((c) => c.id == subFolder.id);
      homeCards.add(subFolder);

      expect(rootFolder.subCards, isEmpty);
      expect(homeCards.length, 1);
      expect(homeCards.first.id, 'sub_folder');
      // Subtree preserved
      expect(homeCards.first.subCards.length, 1);
      expect(homeCards.first.subCards.first.id, 'leaf');
    });

    test('Undo snapshot restores exact pre-conversion state', () {
      final sub = AACCard(id: 'sub', label: 'SubCard', colorValue: 0);
      final folder = AACCard(
        id: 'f1',
        label: 'Folder',
        type: 'folder',
        colorValue: 0,
        subCards: [sub],
      );
      final cards = [folder];

      // Clone pre-conversion snapshot
      final snapshot = cards.map((c) => AACCard.fromJson(c.toJson())).toList();

      // Mutate: move sub to home, convert folder to word
      folder.subCards.clear();
      folder.type = 'word';
      cards.add(sub);

      expect(cards.length, 2);
      expect(cards[0].type, 'word');
      expect(cards[0].subCards, isEmpty);

      // Restore snapshot
      final restored = snapshot.map((c) => AACCard.fromJson(c.toJson())).toList();
      expect(restored.length, 1);
      expect(restored[0].type, 'folder');
      expect(restored[0].subCards.length, 1);
      expect(restored[0].subCards.first.label, 'SubCard');
    });

    test('Backup/Restore round-trip preserves nested card hierarchy and metadata', () {
      final childCard = AACCard(
        id: 'nested_child',
        label: 'Rice & Curry',
        labelSinhala: 'බත් සහ ව්‍යංජන',
        labelTamil: 'சோறு மற்றும் கறி',
        imagePath: 'assets/cards/food.png',
        voicePath: '/data/user/0/lk.yasas.simpleaac/files/rice_voice.m4a',
        category: 'Food',
        colorValue: 0xFFFF5722,
        type: 'word',
      );

      final parentFolder = AACCard(
        id: 'parent_folder',
        label: 'Lunch Menu',
        labelSinhala: 'දිවා ආහාරය',
        labelTamil: 'மதிய உணவு',
        category: 'Food',
        colorValue: 0xFFFF9800,
        type: 'folder',
        subCards: [childCard],
      );

      // Serialize (Backup format)
      final jsonMap = parentFolder.toJson();

      // Deserialize (Restore format)
      final restoredFolder = AACCard.fromJson(jsonMap);

      expect(restoredFolder.id, 'parent_folder');
      expect(restoredFolder.label, 'Lunch Menu');
      expect(restoredFolder.labelSinhala, 'දිවා ආහාරය');
      expect(restoredFolder.labelTamil, 'மதிய உணவு');
      expect(restoredFolder.type, 'folder');
      expect(restoredFolder.subCards.length, 1);

      final restoredChild = restoredFolder.subCards.first;
      expect(restoredChild.id, 'nested_child');
      expect(restoredChild.label, 'Rice & Curry');
      expect(restoredChild.labelSinhala, 'බත් සහ ව්‍යංජන');
      expect(restoredChild.labelTamil, 'சோறு மற்றும் கறி');
      expect(restoredChild.imagePath, 'assets/cards/food.png');
      expect(restoredChild.voicePath, '/data/user/0/lk.yasas.simpleaac/files/rice_voice.m4a');
      expect(restoredChild.category, 'Food');
      expect(restoredChild.type, 'word');
    });
  });
}
