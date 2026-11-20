import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_aac_app/data/default_seed_cards.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('starter_pack_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;
    SharedPreferences.setMockInitialValues({});
    StarterPackService.clearCache();
  });

  tearDown(() async {
    CardStorageService.resetTestHooks();
    HomePage.initialCardsForTesting = null;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Starter Pack Seeding & Opt-in Integration', () {
    test('Fresh install seeds demo cards + starter pack folder', () async {
      final seeded = createDefaultSeedCards();

      // Top level: 5 original demo cards + 1 Default folder
      expect(seeded.length, equals(6));
      expect(seeded.map((c) => c.id).toList(), containsAll([
        'seed_hello',
        'seed_happy',
        'seed_sad',
        'seed_angry',
        'seed_more',
        StarterPackService.starterPackRootId,
      ]));

      // Verify Default folder has 13 categories
      final defaultFolder = seeded.firstWhere((c) => c.id == StarterPackService.starterPackRootId);
      expect(defaultFolder.subCards.length, equals(13));
      expect(defaultFolder.label, equals('Default'));
      expect(defaultFolder.labelSinhala, equals('පෙරනිමි'));
      expect(defaultFolder.labelTamil, equals('இயல்புநிலை'));

      // Total cards counted: 5 demo cards (with 8 More subcards) + 128 starter pack nodes = 141 total
      expect(CardStorageService.countCards(seeded), equals(141));
    });

    test('Existing user cards are loaded without unrequested injection', () async {
      final userCustomCards = [
        AACCard(id: 'user_card_1', label: 'My Custom Card', colorValue: 0xFFFFFFFF),
      ];

      // Simulate existing saved file
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeededDefaultCards', true);
      await prefs.setInt('seededDefaultCardsVersion', CardStorageService.defaultCatalogVersion);

      await CardStorageService.saveCards(userCustomCards);

      // Now load
      final loaded = await CardStorageService.loadCards(
        defaultCardsBuilder: createDefaultSeedCards,
      );

      // Should ONLY contain user's custom card, NOT automatically inject starter pack
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('user_card_1'));
      expect(StarterPackService.isStarterPackInstalled(loaded), isFalse);

      // Now simulate explicit opt-in import
      final importResult = StarterPackService.importStarterPack(loaded);
      expect(importResult.alreadyInstalled, isFalse);
      expect(importResult.cardsAdded, equals(128));
      expect(loaded.length, equals(2)); // user card + Default folder
      expect(StarterPackService.isStarterPackInstalled(loaded), isTrue);

      // Save and reload to verify persistence
      await CardStorageService.saveCards(loaded);
      final reloaded = await CardStorageService.loadCards();
      expect(reloaded.length, equals(2));
      expect(reloaded[0].id, equals('user_card_1'));
      expect(reloaded[1].id, equals(StarterPackService.starterPackRootId));
    });

    test('Repeat import is safe and non-destructive', () async {
      final cards = <AACCard>[
        AACCard(id: 'c1', label: 'Card 1', colorValue: 0xFF123456),
      ];

      // First import
      StarterPackService.importStarterPack(cards);
      expect(cards.length, equals(2));

      // Modify one word card inside Food folder
      final root = StarterPackService.findStarterPackRoot(cards)!;
      final foodFolder = root.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.food');
      final riceCard = foodFolder.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.food.rice');
      riceCard.label = 'Basmati Rice';
      riceCard.colorValue = 0xFF555555;

      // Second import
      final secondResult = StarterPackService.importStarterPack(cards);
      expect(secondResult.alreadyInstalled, isTrue);
      expect(secondResult.cardsAdded, equals(0));
      expect(cards.length, equals(2));

      // Verify customized card was not overwritten
      final verifiedRice = foodFolder.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.food.rice');
      expect(verifiedRice.label, equals('Basmati Rice'));
      expect(verifiedRice.colorValue, equals(0xFF555555));
    });
  });

  group('Backup and Restore Round-trip with Starter Pack', () {
    test('Starter pack cards remain image-complete and user media is restored', () async {
      // Create user photo and audio files in tempDir
      final customPhoto = File('${tempDir.path}/user_photo.jpg');
      await customPhoto.writeAsString('fake_image_bytes');
      final customAudio = File('${tempDir.path}/user_audio.m4a');
      await customAudio.writeAsString('fake_audio_bytes');

      final board = [
        AACCard(
          id: 'user_card',
          label: 'Custom Photo Card',
          colorValue: 0xFFFFFFFF,
          imagePath: customPhoto.path,
          voicePath: customAudio.path,
        ),
        StarterPackService.getStarterPackRootClone(),
      ];

      // 1. Build backup ZIP bytes
      final zipBytes = await BackupService.buildBackupZip(board);
      expect(zipBytes, isNotNull);
      expect(zipBytes!.length, greaterThan(0));

      // 2. Restore from ZIP bytes into a fresh environment
      final freshTempDir = await Directory.systemTemp.createTemp('starter_pack_restore_');
      CardStorageService.docsDirectoryOverride = () async => freshTempDir;

      try {
        final payload = await BackupService.restoreFromZipBytes(zipBytes);
        final restoredCards = payload.cards;

        expect(restoredCards.length, equals(2));

        // Verify user card
        final restoredUserCard = restoredCards.firstWhere((c) => c.id == 'user_card');
        expect(restoredUserCard.imagePath, isNotNull);
        expect(File(restoredUserCard.imagePath!).existsSync(), isTrue);
        expect(restoredUserCard.voicePath, isNotNull);
        expect(File(restoredUserCard.voicePath!).existsSync(), isTrue);

        // Verify starter pack root folder
        final restoredRoot = restoredCards.firstWhere((c) => c.id == StarterPackService.starterPackRootId);
        expect(restoredRoot.subCards.length, equals(13));

        // Verify word cards retain their bundled asset paths
        final foodFolder = restoredRoot.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.food');
        final kottu = foodFolder.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.food.kottu');
        expect(kottu.imagePath, equals('assets/images/starter_pack_v8/food_kottu.webp'));
        expect(kottu.labelSinhala, equals('කොත්තු රොටි'));
        expect(kottu.labelTamil, equals('கொத்து ரொட்டி'));
      } finally {
        if (await freshTempDir.exists()) {
          await freshTempDir.delete(recursive: true);
        }
      }
    });
  });

  group('Multi-language Labels & Color Palette Verification', () {
    test('Key cards display exact expected labels in EN, SI, TA and colors', () {
      final root = StarterPackService.buildStarterPack();

      final allWordsById = <String, AACCard>{};
      for (final cat in root.subCards) {
        for (final word in cat.subCards) {
          allWordsById[word.id] = word;
        }
      }

      // Check key requested cards:
      // Hello, Sad, Yes, Stop, Kottu, Drinks/Milk, Personal Care/Toothpaste
      final testCases = [
        (
          id: 'simpleaac.starter.v2.basic_words.hello',
          en: 'Hello',
          si: 'ආයුබෝවන්',
          ta: 'வணக்கம்',
          color: 0xFFFFE063,
        ),
        (
          id: 'simpleaac.starter.v2.feelings.sad',
          en: 'Sad',
          si: 'දුකයි',
          ta: 'சோகம்',
          color: 0xFFA4C9F2,
        ),
        (
          id: 'simpleaac.starter.v2.basic_words.yes',
          en: 'Yes',
          si: 'ඔව්',
          ta: 'ஆம்',
          color: 0xFF9EDA91,
        ),
        (
          id: 'simpleaac.starter.v2.basic_words.stop',
          en: 'Stop',
          si: 'නවත්වන්න',
          ta: 'நிறுத்து',
          color: 0xFFEE9A93,
        ),
        (
          id: 'simpleaac.starter.v2.food.kottu',
          en: 'Kottu Roti',
          si: 'කොත්තු රොටි',
          ta: 'கொத்து ரொட்டி',
          color: 0xFFFFDE9B,
        ),
        (
          id: 'simpleaac.starter.v2.drinks.milk',
          en: 'Milk',
          si: 'කිරි',
          ta: 'பால்',
          color: 0xFFB4DEF6,
        ),
        (
          id: 'simpleaac.starter.v2.personal_care.toothpaste',
          en: 'Toothpaste',
          si: 'දත් බෙහෙත්',
          ta: 'பற்பசை',
          color: 0xFFC8E5F8,
        ),
      ];

      for (final tc in testCases) {
        final card = allWordsById[tc.id];
        expect(card, isNotNull, reason: 'Card ${tc.id} must exist');
        expect(card!.getLabel('en'), equals(tc.en));
        expect(card.getLabel('si'), equals(tc.si));
        expect(card.getLabel('ta'), equals(tc.ta));
        expect(card.colorValue, equals(tc.color));
      }
    });
  });

  group('HomePage UI & Drawer Starter Pack Integration', () {
    testWidgets('Drawer displays Starter Card Pack item and tapping opens dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      HomePage.initialCardsForTesting = [
        AACCard(id: 'c1', label: 'Hello', colorValue: 0xFFFEE685),
      ];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Scroll drawer to find Starter Card Pack
      final drawerScrollable = find.descendant(
        of: find.byType(HomeDrawer),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Starter Card Pack'),
        200,
        scrollable: drawerScrollable,
      );

      expect(find.text('Starter Card Pack'), findsOneWidget);
      expect(find.text('128 cards in 13 categories (Sri Lanka)'), findsOneWidget);

      // Tap Starter Card Pack
      await tester.tap(find.text('Starter Card Pack'));
      await tester.pumpAndSettle();

      // Dialog should open
      expect(find.text('Import Starter Pack?'), findsOneWidget);
      expect(find.byKey(const ValueKey('confirm_import_starter_pack_btn')), findsOneWidget);

      // Tap Confirm Import
      await tester.tap(find.byKey(const ValueKey('confirm_import_starter_pack_btn')));
      await tester.pumpAndSettle();

      // Board should now display the Default folder
      expect(find.text('Default'), findsOneWidget);

      // Reopen drawer to verify "Starter Pack Installed" state
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Starter Card Pack'),
        200,
        scrollable: drawerScrollable,
      );
      await tester.tap(find.text('Starter Card Pack'));
      await tester.pumpAndSettle();

      expect(find.text('Starter Pack Installed'), findsOneWidget);
    });

    testWidgets('Folder navigation into Default and Category folders works smoothly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Seed with starter pack
      HomePage.initialCardsForTesting = [
        StarterPackService.getStarterPackRootClone(),
      ];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // On home: see Default folder
      expect(find.text('Default'), findsOneWidget);

      // Tap Default folder to navigate inside
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();

      // Should now see category folders: Family, Colours, Food, etc.
      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Colours'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);

      // Tap Food category folder
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Should now see food word cards (e.g. Rice, Bread, Banana)
      expect(find.text('Rice'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });
  });
}
