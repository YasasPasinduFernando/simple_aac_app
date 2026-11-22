import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/main.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_editor_draft_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('camera_recovery_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;
    SharedPreferences.setMockInitialValues({});
    HomePage.initialCardsForTesting = [
      AACCard(
        id: 'cat_card_id',
        label: 'Cat',
        colorValue: 0xFFFFEB3B,
      ),
    ];
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.speakPerformer = (_) async {};
    CardEditorDraftService.pickerOverride = null;
    CardEditorDraftService.lostDataOverride = () async => null;
  });

  tearDown(() {
    CardStorageService.resetTestHooks();
    HomePage.initialCardsForTesting = null;
    HomePage.enableTtsInit = true;
    HomePage.enableTutorialInit = true;
    HomePage.speakPerformer = null;
    CardEditorDraftService.pickerOverride = null;
    CardEditorDraftService.lostDataOverride = null;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CardEditorDraftService', () {
    test('saveDraft, getDraft, and clearDraft work as expected', () async {
      final card = AACCard(
        id: 'cat_card_id',
        label: 'Cat',
        labelSinhala: 'පූසා',
        labelTamil: 'பூனை',
        category: 'Animals',
        colorValue: 0xFFFFEB3B,
      );

      expect(await CardEditorDraftService.hasDraft(), isFalse);

      await CardEditorDraftService.saveDraft(
        card: card,
        isNew: false,
        parentStackIds: ['default_folder', 'animals_folder'],
        label: 'Cat',
        labelSinhala: 'පූසා',
        labelTamil: 'பூனை',
        category: 'Animals',
      );

      expect(await CardEditorDraftService.hasDraft(), isTrue);

      final draft = await CardEditorDraftService.getDraft();
      expect(draft, isNotNull);
      expect(draft!.cardId, equals('cat_card_id'));
      expect(draft.label, equals('Cat'));
      expect(draft.labelSinhala, equals('පූසා'));
      expect(draft.labelTamil, equals('பூனை'));
      expect(draft.parentStackIds, equals(['default_folder', 'animals_folder']));

      await CardEditorDraftService.clearDraft();
      expect(await CardEditorDraftService.hasDraft(), isFalse);
      expect(await CardEditorDraftService.getDraft(), isNull);
    });
  });

  group('AACApp NavigatorKey stability across theme changes', () {
    testWidgets('MaterialApp uses stable navigatorKey across build cycles',
        (tester) async {
      await tester.pumpWidget(const AACApp());
      await tester.pumpAndSettle();

      final navState1 = AACApp.navigatorKey.currentState;
      expect(navState1, isNotNull);

      // Rebuild widget
      await tester.pumpWidget(const AACApp());
      await tester.pumpAndSettle();

      final navState2 = AACApp.navigatorKey.currentState;
      expect(navState2, same(navState1),
          reason: 'NavigatorState must be preserved across rebuilds so dialogs are not destroyed');
    });
  });

  group('Camera Recovery Lifecycle', () {
    testWidgets('Recovers draft and re-opens editor with intact labels on simulated process death',
        (tester) async {
      // 1. Stage an active draft simulating an in-progress Cat edit in Animals folder
      final testCard = AACCard(
        id: 'cat_card_id',
        label: 'Cat',
        labelSinhala: 'පූසා',
        labelTamil: 'பூனை',
        category: 'Animals',
        colorValue: 0xFFFFEB3B,
      );

      await CardEditorDraftService.saveDraft(
        card: testCard,
        isNew: false,
        parentStackIds: [],
        label: 'Cat (Unsaved Draft)',
        labelSinhala: 'පූසා (අලුත්)',
        labelTamil: 'பூனை (புதிய)',
        category: 'Animals',
      );

      // 2. Launch HomePage fresh (simulating process restart)
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that the draft marker is cleared so it only runs once
      expect(await CardEditorDraftService.hasDraft(), isFalse);

      // Verify CardEditorDialog was safely re-opened with the draft labels
      expect(find.text('Edit Card'), findsOneWidget);
      expect(find.text('Cat (Unsaved Draft)'), findsWidgets);
      expect(find.text('පූසා (අලුත්)'), findsWidgets);
      expect(find.text('பூனை (புதிய)'), findsWidgets);

      // Close the dialog safely
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
    });
  });
}
