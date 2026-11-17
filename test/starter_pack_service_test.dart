import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StarterPackService.clearCache();
  });

  group('StarterPackService Hierarchy & Manifest Validation', () {
    test('buildStarterPack constructs exactly 128 nodes (1 root + 13 folders + 114 words)', () {
      final root = StarterPackService.buildStarterPack();

      expect(root.id, equals(StarterPackService.starterPackRootId));
      expect(root.type, equals('folder'));
      expect(root.label, equals('Default'));
      expect(root.labelSinhala, equals('පෙරනිමි'));
      expect(root.labelTamil, equals('இயல்புநிலை'));
      expect(root.colorValue, equals(0xFF228ED3));

      // 13 category folders
      expect(root.subCards.length, equals(13));

      final expectedCategories = [
        'simpleaac.starter.v2.family',
        'simpleaac.starter.v2.colours',
        'simpleaac.starter.v2.shapes',
        'simpleaac.starter.v2.animals',
        'simpleaac.starter.v2.food',
        'simpleaac.starter.v2.snacks',
        'simpleaac.starter.v2.drinks',
        'simpleaac.starter.v2.feelings',
        'simpleaac.starter.v2.needs',
        'simpleaac.starter.v2.basic_words',
        'simpleaac.starter.v2.activities',
        'simpleaac.starter.v2.school_places',
        'simpleaac.starter.v2.personal_care',
      ];

      final actualCategories = root.subCards.map((c) => c.id).toList();
      expect(actualCategories, equals(expectedCategories));

      var totalWordCards = 0;
      for (final folder in root.subCards) {
        expect(folder.type, equals('folder'));
        expect(folder.label.isNotEmpty, isTrue);
        expect(folder.labelSinhala, isNotNull);
        expect(folder.labelTamil, isNotNull);
        expect(folder.colorValue, isNot(equals(0)));

        for (final word in folder.subCards) {
          totalWordCards++;
          expect(word.type, equals('word'));
          expect(word.label.isNotEmpty, isTrue);
          expect(word.labelSinhala, isNotNull);
          expect(word.labelTamil, isNotNull);
          expect(word.imagePath, isNotNull);
          expect(word.imagePath!.startsWith('assets/images/starter_pack_v8/'), isTrue);
          expect(word.colorValue, isNot(equals(0)));
        }
      }

      expect(totalWordCards, equals(114));
      // Total nodes = 1 (root) + 13 (folders) + 114 (words) = 128
    });

    test('All 20 MUST-HAVE Sri Lankan items are present with correct IDs and non-duplicated', () {
      final root = StarterPackService.buildStarterPack();

      final allWordsById = <String, AACCard>{};
      for (final folder in root.subCards) {
        for (final word in folder.subCards) {
          allWordsById[word.id] = word;
        }
      }

      final mustHaveRefs = [
        ('Kottu Roti', 'simpleaac.starter.v2.food.kottu'),
        ('String Hoppers / Idiyappam', 'simpleaac.starter.v2.food.string_hoppers'),
        ('Rice', 'simpleaac.starter.v2.food.rice'),
        ('Milk', 'simpleaac.starter.v2.drinks.milk'),
        ('Biscuit', 'simpleaac.starter.v2.food.biscuit'),
        ('Milk Biscuit', 'simpleaac.starter.v2.snacks.milk_biscuit'),
        ('Tea', 'simpleaac.starter.v2.drinks.tea'),
        ('Coffee', 'simpleaac.starter.v2.drinks.coffee'),
        ('Soft Drink', 'simpleaac.starter.v2.drinks.soft_drink'),
        ('Butter', 'simpleaac.starter.v2.food.butter'),
        ('Bread', 'simpleaac.starter.v2.food.bread'),
        ('Butter Bread', 'simpleaac.starter.v2.food.butter_bread'),
        ('Samosa', 'simpleaac.starter.v2.snacks.samosa'),
        ('Hoppers / Appa', 'simpleaac.starter.v2.food.hoppers'),
        ('Rolls', 'simpleaac.starter.v2.snacks.rolls'),
        ('Patties', 'simpleaac.starter.v2.snacks.patties'),
        ('Cake', 'simpleaac.starter.v2.snacks.cake'),
        ('Toothpaste', 'simpleaac.starter.v2.personal_care.toothpaste'),
        ('Toothbrush', 'simpleaac.starter.v2.personal_care.toothbrush'),
        ('Brush Teeth', 'simpleaac.starter.v2.personal_care.brush_teeth'),
      ];

      for (final (name, expectedId) in mustHaveRefs) {
        expect(allWordsById.containsKey(expectedId), isTrue,
            reason: 'Must-have card "$name" ($expectedId) should exist');
        final card = allWordsById[expectedId]!;
        expect(card.imagePath, isNotNull);
        expect(card.labelSinhala, isNotNull);
        expect(card.labelTamil, isNotNull);
      }
    });

    test('All 114 asset images exist on disk and match SHA256 sums', () async {
      final root = StarterPackService.buildStarterPack();

      // Read IMAGE_SHA256SUMS.txt from extracted zip or check asset files
      final sumsFile = File('/tmp/simple_aac_v8/Simple_AAC_SriLankan_114_Colored_Images_v8/IMAGE_SHA256SUMS.txt');
      final expectedHashes = <String, String>{};
      if (sumsFile.existsSync()) {
        for (final line in sumsFile.readAsLinesSync()) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          final parts = trimmed.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final hash = parts[0];
            final filename = parts[1].replaceFirst('images/', '');
            expectedHashes[filename] = hash;
          }
        }
      }

      var checkedImages = 0;
      for (final folder in root.subCards) {
        for (final word in folder.subCards) {
          final assetPath = word.imagePath!;
          final fileOnDisk = File(assetPath);
          expect(fileOnDisk.existsSync(), isTrue, reason: 'Asset image $assetPath must exist on disk');

          final bytes = await fileOnDisk.readAsBytes();
          expect(bytes.length, greaterThan(0));

          final filename = assetPath.split('/').last;
          if (expectedHashes.containsKey(filename)) {
            final actualHash = sha256.convert(bytes).toString();
            expect(actualHash, equals(expectedHashes[filename]),
                reason: 'SHA256 checksum mismatch for $filename');
          }
          checkedImages++;
        }
      }

      expect(checkedImages, equals(114));
    });
  });

  group('StarterPackService Safe Import & Non-Destructive Behavior', () {
    test('isStarterPackInstalled correctly detects root folder', () {
      final emptyCards = <AACCard>[];
      expect(StarterPackService.isStarterPackInstalled(emptyCards), isFalse);

      final demoCards = [
        AACCard(id: 'seed_hello', label: 'Hello', colorValue: 0xFFFEE685),
        AACCard(id: 'seed_sad', label: 'Sad', colorValue: 0xFFB9DCFE),
      ];
      expect(StarterPackService.isStarterPackInstalled(demoCards), isFalse);

      final packRoot = StarterPackService.getStarterPackRootClone();
      demoCards.add(packRoot);
      expect(StarterPackService.isStarterPackInstalled(demoCards), isTrue);
    });

    test('importStarterPack appends pack on fresh user without removing demo cards', () {
      final userCards = [
        AACCard(id: 'seed_hello', label: 'Hello', colorValue: 0xFFFEE685),
        AACCard(id: 'user_card_1', label: 'My Custom Dog', colorValue: 0xFFFFFFFF),
      ];

      final result = StarterPackService.importStarterPack(userCards);

      expect(result.alreadyInstalled, isFalse);
      expect(result.cardsAdded, equals(128));
      expect(userCards.length, equals(3)); // 2 original + 1 root folder
      expect(userCards[0].id, equals('seed_hello'));
      expect(userCards[1].id, equals('user_card_1'));
      expect(userCards[2].id, equals(StarterPackService.starterPackRootId));
    });

    test('importStarterPack prevents duplicates on repeat import and preserves user edits', () {
      final userCards = [
        AACCard(id: 'seed_hello', label: 'Hello', colorValue: 0xFFFEE685),
      ];

      // First import
      final firstResult = StarterPackService.importStarterPack(userCards);
      expect(firstResult.alreadyInstalled, isFalse);
      expect(firstResult.cardsAdded, equals(128));

      // User customizes one card: edits label, changes color, adds voice path
      final root = userCards.firstWhere((c) => c.id == StarterPackService.starterPackRootId);
      final foodFolder = root.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.food');
      final kottuCard = foodFolder.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.food.kottu');

      kottuCard.label = 'Custom Spicy Kottu';
      kottuCard.colorValue = 0xFF123456;
      kottuCard.voicePath = '/data/user/0/custom_voice.m4a';

      // Second import
      final secondResult = StarterPackService.importStarterPack(userCards);
      expect(secondResult.alreadyInstalled, isTrue);
      expect(secondResult.cardsAdded, equals(0)); // 0 duplicate cards added

      // Verify user's customizations are 100% preserved
      final verifiedKottu = foodFolder.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.food.kottu');
      expect(verifiedKottu.label, equals('Custom Spicy Kottu'));
      expect(verifiedKottu.colorValue, equals(0xFF123456));
      expect(verifiedKottu.voicePath, equals('/data/user/0/custom_voice.m4a'));
    });
  });
}
