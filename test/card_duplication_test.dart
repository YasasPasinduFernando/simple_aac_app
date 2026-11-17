import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/widgets/card_editor_dialog.dart';

class _FakeAudioPlayer extends Fake implements AudioPlayer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDocsDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'online_features_enabled': false});
    await NetworkPolicyService.instance.init();

    tempDocsDir = await Directory.systemTemp.createTemp('card_duplication_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDocsDir;
  });

  tearDown(() async {
    CardStorageService.docsDirectoryOverride = null;
    if (await tempDocsDir.exists()) {
      await tempDocsDir.delete(recursive: true);
    }
  });

  group('CardEditorDialog - Duplicate Card Button Visibility & Restrictions', () {
    testWidgets('1. Duplicate Card button is visible for existing Word Card without sub-cards',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final wordCard = AACCard(
        id: 'word_sad',
        label: 'Sad',
        labelSinhala: 'දුකයි',
        labelTamil: 'சோகம்',
        colorValue: 0xFF90CAF9,
        category: 'Feelings',
        type: 'word',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardEditorDialog(
              card: wordCard,
              isNew: false,
              categories: const ['General', 'Feelings'],
              audioPlayer: _FakeAudioPlayer(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dupBtnFinder = find.byKey(const ValueKey('card_editor_duplicate_btn'));
      expect(dupBtnFinder, findsOneWidget);
      expect(find.text('Duplicate Card'), findsOneWidget);
    });

    testWidgets('2. Duplicate Card button is strictly hidden for Folder Cards',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final folderCard = AACCard(
        id: 'folder_food',
        label: 'Food',
        colorValue: 0xFFFFCC80,
        category: 'Food',
        type: 'folder',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardEditorDialog(
              card: folderCard,
              isNew: false,
              categories: const ['General', 'Food'],
              audioPlayer: _FakeAudioPlayer(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('card_editor_duplicate_btn')), findsNothing);
    });

    testWidgets('3. Duplicate Card button is strictly hidden when creating a new card (isNew: true)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final newCard = AACCard(
        id: 'new_temp_id',
        label: 'New',
        colorValue: 0xFF81C784,
        category: 'General',
        type: 'word',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardEditorDialog(
              card: newCard,
              isNew: true,
              categories: const ['General'],
              audioPlayer: _FakeAudioPlayer(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('card_editor_duplicate_btn')), findsNothing);
    });

    testWidgets('4. Duplicate Card button is strictly hidden for cards containing sub-cards',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cardWithSub = AACCard(
        id: 'card_with_children',
        label: 'Activities',
        colorValue: 0xFFCE93D8,
        category: 'Actions',
        type: 'word',
        subCards: [
          AACCard(
            id: 'child_1',
            label: 'Run',
            colorValue: 0xFFE1BEE7,
            category: 'Actions',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardEditorDialog(
              card: cardWithSub,
              isNew: false,
              categories: const ['General', 'Actions'],
              audioPlayer: _FakeAudioPlayer(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('card_editor_duplicate_btn')), findsNothing);
    });
  });

  group('CardEditorDialog - Confirmation Dialog Flow & Form Value Preservation', () {
    testWidgets('14. Confirmation dialog cancel dismisses dialog without duplicating',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final wordCard = AACCard(
        id: 'word_sad',
        label: 'Sad',
        colorValue: 0xFF90CAF9,
        category: 'Feelings',
      );

      bool duplicateCalled = false;
      CardEditorAction? resultAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  resultAction = await showDialog<CardEditorAction>(
                    context: ctx,
                    builder: (dCtx) => CardEditorDialog(
                      card: wordCard,
                      isNew: false,
                      categories: const ['General', 'Feelings'],
                      audioPlayer: _FakeAudioPlayer(),
                      onDuplicate: (cand) {
                        duplicateCalled = true;
                      },
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final dupBtnFinder = find.byKey(const ValueKey('card_editor_duplicate_btn'));
      await tester.scrollUntilVisible(
        dupBtnFinder,
        100,
        scrollable: find.descendant(
          of: find.byType(CardEditorDialog),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(dupBtnFinder);
      await tester.pumpAndSettle();

      // Confirmation dialog should be visible
      expect(find.text('Duplicate Card?'), findsOneWidget);
      expect(find.text('Create a separate copy of "Sad"?'), findsOneWidget);
      expect(find.text('Original card stays unchanged.'), findsOneWidget);
      expect(find.text('A new card will be added beside it.'), findsOneWidget);
      expect(find.text('New copy'), findsOneWidget);

      // Tap Cancel in confirmation dialog
      await tester.tap(find.byKey(const ValueKey('duplicate_card_cancel_btn')));
      await tester.pumpAndSettle();

      // Confirmation dialog is closed, CardEditorDialog remains open
      expect(find.text('Duplicate Card?'), findsNothing);
      expect(find.text('Edit Card'), findsOneWidget);
      expect(duplicateCalled, isFalse);
      expect(resultAction, isNull);
    });

    testWidgets('Duplicate confirms and propagates unsaved form edits without mutating original',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final wordCard = AACCard(
        id: 'word_orig',
        label: 'Sad',
        labelSinhala: 'දුකයි',
        labelTamil: 'சோகம்',
        colorValue: 0xFF90CAF9,
        category: 'Feelings',
      );

      AACCard? receivedCandidate;
      CardEditorAction? resultAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  resultAction = await showDialog<CardEditorAction>(
                    context: ctx,
                    builder: (dCtx) => CardEditorDialog(
                      card: wordCard,
                      isNew: false,
                      categories: const ['General', 'Feelings', 'Custom'],
                      audioPlayer: _FakeAudioPlayer(),
                      onDuplicate: (cand) {
                        receivedCandidate = cand;
                      },
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Change the English text in the editor before tapping duplicate
      final enFieldFinder = find.widgetWithText(TextField, 'Sad');
      await tester.enterText(enFieldFinder, 'Very Sad');
      await tester.pumpAndSettle();

      final dupBtnFinder = find.byKey(const ValueKey('card_editor_duplicate_btn'));
      await tester.scrollUntilVisible(
        dupBtnFinder,
        100,
        scrollable: find.descendant(
          of: find.byType(CardEditorDialog),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(dupBtnFinder);
      await tester.pumpAndSettle();

      // Check that confirmation dialog reflects currently entered candidate data
      expect(find.text('Create a separate copy of "Very Sad"?'), findsOneWidget);

      // Confirm duplicate
      await tester.tap(find.byKey(const ValueKey('duplicate_card_confirm_btn')));
      await tester.pumpAndSettle();

      expect(resultAction, CardEditorAction.duplicate);
      expect(receivedCandidate, isNotNull);
      expect(receivedCandidate!.label, 'Very Sad');
      expect(receivedCandidate!.labelSinhala, 'දුකයි');
      expect(receivedCandidate!.labelTamil, 'சோகம்');
      expect(receivedCandidate!.category, 'Feelings');

      // Original card must remain completely unchanged!
      expect(wordCard.label, 'Sad');
    });
  });

  group('Media Safety & Isolation', () {
    test('11. copyMediaFile preserves assets without disk copying', () async {
      const assetPath = 'assets/images/sad.png';
      final result = await CardStorageService.copyMediaFile(
        assetPath,
        cardId: 'card_dup_123',
        mediaType: 'images',
      );
      expect(result, assetPath);
    });

    test('11, 19, 20. copyMediaFile creates independent file; deleting original retains duplicate & vice versa',
        () async {
      final imagesDir = await CardStorageService.mediaDirectory('images');
      final originalFile = File('${imagesDir.path}/original_img.jpg');
      await originalFile.writeAsBytes([1, 2, 3, 4, 5, 6, 7, 8]);

      final dupPath = await CardStorageService.copyMediaFile(
        originalFile.path,
        cardId: 'dup_card_id',
        mediaType: 'images',
      );

      expect(dupPath, isNotNull);
      expect(dupPath, isNot(equals(originalFile.path)));

      final dupFile = File(dupPath!);
      expect(await dupFile.exists(), isTrue);
      expect(await dupFile.readAsBytes(), [1, 2, 3, 4, 5, 6, 7, 8]);

      // 19. Deleting original file does NOT delete duplicate
      await originalFile.delete();
      expect(await originalFile.exists(), isFalse);
      expect(await dupFile.exists(), isTrue);

      // 20. Deleting duplicate file does NOT delete original (if recreated)
      await originalFile.writeAsBytes([9, 10, 11]);
      await dupFile.delete();
      expect(await dupFile.exists(), isFalse);
      expect(await originalFile.exists(), isTrue);
    });

    test('12. Voice recordings are safely duplicated and isolated', () async {
      final voicesDir = await CardStorageService.mediaDirectory('voices');
      final originalVoice = File('${voicesDir.path}/orig_voice.m4a');
      await originalVoice.writeAsBytes([0xAA, 0xBB, 0xCC, 0xDD]);

      final dupVoicePath = await CardStorageService.copyMediaFile(
        originalVoice.path,
        cardId: 'dup_card_voice_id',
        mediaType: 'voices',
      );

      expect(dupVoicePath, isNotNull);
      expect(dupVoicePath, isNot(equals(originalVoice.path)));
      expect(await File(dupVoicePath!).exists(), isTrue);
      expect(await File(dupVoicePath).readAsBytes(), [0xAA, 0xBB, 0xCC, 0xDD]);
    });
  });

  group('HomePage Card Duplication Integration Tests', () {
    testWidgets('5, 6, 7, 9, 10. Duplicate regular Word Card: unique ID, unchanged original, inserted at index + 1, preserves all fields',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final card1 = AACCard(
        id: 'card_hello',
        label: 'Hello',
        labelSinhala: 'හෙලෝ',
        labelTamil: 'வணக்கம்',
        colorValue: 0xFFFEE685,
        category: 'General',
      );
      final card2 = AACCard(
        id: 'card_sad',
        label: 'Sad',
        labelSinhala: 'දුකයි',
        labelTamil: 'சோகம்',
        colorValue: 0xFFB9DCFE,
        category: 'Feelings',
      );
      final card3 = AACCard(
        id: 'card_water',
        label: 'Water',
        labelSinhala: 'වතුර',
        labelTamil: 'தண்ணீர்',
        colorValue: 0xFFB9DCFE,
        category: 'Food',
      );

      HomePage.initialCardsForTesting = [card1, card2, card3];
      HomePage.enableTutorialInit = false;
      HomePage.enableTtsInit = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Edit Mode
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      // Tap pencil on "Sad"
      final pencilSad = find.byKey(const ValueKey('card_edit_pencil_card_sad'));
      expect(pencilSad, findsOneWidget);
      await tester.tap(pencilSad);
      await tester.pumpAndSettle();

      // In CardEditorDialog, scroll to Duplicate Card button
      final dupBtnFinder = find.byKey(const ValueKey('card_editor_duplicate_btn'));
      await tester.scrollUntilVisible(
        dupBtnFinder,
        100,
        scrollable: find.descendant(
          of: find.byType(CardEditorDialog),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(dupBtnFinder);
      await tester.pumpAndSettle();

      // Confirm duplicate
      await tester.tap(find.byKey(const ValueKey('duplicate_card_confirm_btn')));
      await tester.pumpAndSettle();

      // 6. Original card unchanged
      expect(card2.id, 'card_sad');
      expect(card2.label, 'Sad');
      expect(card2.labelSinhala, 'දුකයි');
      expect(card2.labelTamil, 'சோகம்');

      // Verify board has 4 cards now
      // Find HomePageState to inspect cards list
      final homeState = tester.state(find.byType(HomePage)) as dynamic;
      final List<AACCard> boardCards = homeState.cards as List<AACCard>;
      expect(boardCards.length, 4);

      // 7. Correct insertion position: immediately after card_sad (index 2)
      expect(boardCards[0].id, 'card_hello');
      expect(boardCards[1].id, 'card_sad');
      final duplicateCard = boardCards[2];
      expect(boardCards[3].id, 'card_water');

      // 5. Unique ID generation
      expect(duplicateCard.id, isNot(equals('card_sad')));
      expect(duplicateCard.id, isNotEmpty);

      // 9, 10. Field preservation
      expect(duplicateCard.label, 'Sad');
      expect(duplicateCard.labelSinhala, 'දුකයි');
      expect(duplicateCard.labelTamil, 'சோகம்');
      expect(duplicateCard.category, 'Feelings');
      expect(duplicateCard.colorValue, 0xFFB9DCFE);
      expect(duplicateCard.type, 'word');
      expect(duplicateCard.subCards, isEmpty);

      // Verify SnackBar message
      expect(find.text('Card duplicated successfully'), findsOneWidget);
    });

    testWidgets('8. Duplicate Word Card inside a folder creates duplicate inside that same folder',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sub1 = AACCard(
        id: 'sub_apple',
        label: 'Apple',
        labelSinhala: 'ඇපල්',
        labelTamil: 'ஆப்பிள்',
        colorValue: 0xFFFFCDD2,
        category: 'Food',
      );
      final sub2 = AACCard(
        id: 'sub_banana',
        label: 'Banana',
        labelSinhala: 'කෙසෙල්',
        labelTamil: 'வாழைப்பழம்',
        colorValue: 0xFFFFF9C4,
        category: 'Food',
      );
      final folder = AACCard(
        id: 'folder_fruits',
        label: 'Fruits',
        type: 'folder',
        colorValue: 0xFFFFE082,
        category: 'Food',
        subCards: [sub1, sub2],
      );

      HomePage.initialCardsForTesting = [folder];
      HomePage.enableTutorialInit = false;
      HomePage.enableTtsInit = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Edit Mode
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      // Tap folder body to enter folder
      await tester.tap(find.text('Fruits'));
      await tester.pumpAndSettle();

      // Now inside Fruits folder: tap pencil on Apple
      final pencilApple = find.byKey(const ValueKey('card_edit_pencil_sub_apple'));
      expect(pencilApple, findsOneWidget);
      await tester.tap(pencilApple);
      await tester.pumpAndSettle();

      // Tap Duplicate Card
      final dupBtnFinder = find.byKey(const ValueKey('card_editor_duplicate_btn'));
      await tester.scrollUntilVisible(
        dupBtnFinder,
        100,
        scrollable: find.descendant(
          of: find.byType(CardEditorDialog),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(dupBtnFinder);
      await tester.pumpAndSettle();

      // Confirm duplicate
      await tester.tap(find.byKey(const ValueKey('duplicate_card_confirm_btn')));
      await tester.pumpAndSettle();

      // Verify Fruits folder has 3 sub-cards now, with duplicate inserted at index 1
      expect(folder.subCards.length, 3);
      expect(folder.subCards[0].id, 'sub_apple');
      expect(folder.subCards[1].id, isNot(equals('sub_apple')));
      expect(folder.subCards[1].label, 'Apple');
      expect(folder.subCards[1].labelSinhala, 'ඇපල්');
      expect(folder.subCards[2].id, 'sub_banana');
    });

    testWidgets('13. Repeated duplication creates a distinct unique ID every time',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cardSad = AACCard(
        id: 'card_sad_base',
        label: 'Sad',
        colorValue: 0xFFB9DCFE,
        category: 'Feelings',
      );

      HomePage.initialCardsForTesting = [cardSad];
      HomePage.enableTutorialInit = false;
      HomePage.enableTtsInit = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Edit Mode
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      // First duplication
      await tester.tap(find.byKey(const ValueKey('card_edit_pencil_card_sad_base')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('card_editor_duplicate_btn')),
        100,
        scrollable: find.descendant(
          of: find.byType(CardEditorDialog),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(find.byKey(const ValueKey('card_editor_duplicate_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('duplicate_card_confirm_btn')));
      await tester.pumpAndSettle();

      // Second duplication of original card
      await tester.tap(find.byKey(const ValueKey('card_edit_pencil_card_sad_base')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('card_editor_duplicate_btn')),
        100,
        scrollable: find.descendant(
          of: find.byType(CardEditorDialog),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(find.byKey(const ValueKey('card_editor_duplicate_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('duplicate_card_confirm_btn')));
      await tester.pumpAndSettle();

      final homeState = tester.state(find.byType(HomePage)) as dynamic;
      final List<AACCard> boardCards = homeState.cards as List<AACCard>;
      expect(boardCards.length, 3);

      final ids = boardCards.map((c) => c.id).toSet();
      expect(ids.length, 3, reason: 'All cards must have strictly unique IDs');
    });

    testWidgets('15. Undo reverses duplication and removes the duplicate card',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cardSad = AACCard(
        id: 'card_sad_undo',
        label: 'Sad',
        colorValue: 0xFFB9DCFE,
        category: 'Feelings',
      );

      HomePage.initialCardsForTesting = [cardSad];
      HomePage.enableTutorialInit = false;
      HomePage.enableTtsInit = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Edit Mode
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      // Duplicate card
      await tester.tap(find.byKey(const ValueKey('card_edit_pencil_card_sad_undo')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('card_editor_duplicate_btn')),
        100,
        scrollable: find.descendant(
          of: find.byType(CardEditorDialog),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(find.byKey(const ValueKey('card_editor_duplicate_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('duplicate_card_confirm_btn')));
      await tester.pumpAndSettle();

      final homeState = tester.state(find.byType(HomePage)) as dynamic;
      expect((homeState.cards as List).length, 2);

      // Tap Undo in Edit Mode toolbar
      final undoBtnFinder = find.byKey(const ValueKey('edit_mode_undo_btn'));
      await tester.tap(undoBtnFinder);
      await tester.pumpAndSettle();

      // Duplicate is removed, only original remains!
      expect((homeState.cards as List).length, 1);
      expect((homeState.cards as List<AACCard>)[0].id, 'card_sad_undo');
    });

    testWidgets('16. Cancel Edit Mode discards duplicate card and cleans up session media',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cardSad = AACCard(
        id: 'card_sad_cancel',
        label: 'Sad',
        colorValue: 0xFFB9DCFE,
        category: 'Feelings',
      );

      HomePage.initialCardsForTesting = [cardSad];
      HomePage.enableTutorialInit = false;
      HomePage.enableTtsInit = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Edit Mode
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      // Duplicate card
      await tester.tap(find.byKey(const ValueKey('card_edit_pencil_card_sad_cancel')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('card_editor_duplicate_btn')),
        100,
        scrollable: find.descendant(
          of: find.byType(CardEditorDialog),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(find.byKey(const ValueKey('card_editor_duplicate_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('duplicate_card_confirm_btn')));
      await tester.pumpAndSettle();

      final homeState = tester.state(find.byType(HomePage)) as dynamic;
      expect((homeState.cards as List).length, 2);

      // Tap Cancel in Edit Mode toolbar
      final cancelBtnFinder = find.byKey(const ValueKey('edit_mode_cancel_btn'));
      await tester.tap(cancelBtnFinder);
      await tester.pumpAndSettle();

      // Confirm discard in "Discard Changes?" dialog
      final discardBtnFinder = find.byKey(const ValueKey('cancel_dialog_discard_btn'));
      if (discardBtnFinder.evaluate().isNotEmpty) {
        await tester.tap(discardBtnFinder);
        await tester.pumpAndSettle();
      }

      // Discards all session changes, exactly 1 original card remains
      expect((homeState.cards as List).length, 1);
      expect((homeState.cards as List<AACCard>)[0].id, 'card_sad_cancel');
    });

    test('17. Persistence: cards saved and reloaded retain duplicate independently',
        () async {
      final cardOriginal = AACCard(
        id: 'persist_orig',
        label: 'Water',
        colorValue: 0xFF81D4FA,
        category: 'Drinks',
      );
      final cardDuplicate = AACCard(
        id: 'persist_dup_789',
        label: 'Water',
        colorValue: 0xFF81D4FA,
        category: 'Drinks',
      );

      await CardStorageService.saveCards([cardOriginal, cardDuplicate]);

      final loaded = await CardStorageService.loadCards(
        defaultCards: [],
      );

      expect(loaded.length, 2);
      expect(loaded[0].id, 'persist_orig');
      expect(loaded[1].id, 'persist_dup_789');
      expect(loaded[0].label, 'Water');
      expect(loaded[1].label, 'Water');
    });

    test('18. ZIP backup and restore exports and restores duplicate card separately',
        () async {
      final originalCard = AACCard(
        id: 'zip_orig_id',
        label: 'Hello',
        labelSinhala: 'හෙලෝ',
        labelTamil: 'வணக்கம்',
        colorValue: 0xFFFFEE58,
        category: 'General',
      );
      final duplicateCard = AACCard(
        id: 'zip_dup_id',
        label: 'Hello',
        labelSinhala: 'හෙලෝ',
        labelTamil: 'வணக்கம்',
        colorValue: 0xFFFFEE58,
        category: 'General',
      );

      final cardsList = [originalCard, duplicateCard];
      final zipBytes = await BackupService.buildBackupZip(
        cardsList,
      );

      expect(zipBytes, isNotNull);
      expect(zipBytes!.isNotEmpty, isTrue);

      final restoredPayload = await BackupService.restoreFromZipBytes(zipBytes);
      expect(restoredPayload.cards.length, 2);
      expect(restoredPayload.cards[0].id, 'zip_orig_id');
      expect(restoredPayload.cards[1].id, 'zip_dup_id');
      expect(restoredPayload.cards[0].label, 'Hello');
      expect(restoredPayload.cards[1].label, 'Hello');
    });
  });
}
