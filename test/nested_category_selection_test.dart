import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';
import 'package:simple_aac_app/utils/category_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const defaultColor = 0xFF42A5F5;

  group('Nested Category Selection & Accurate Card Counts Specification Tests', () {
    late AACCard starterPack;
    late List<AACCard> fullHierarchy;

    setUp(() {
      starterPack = StarterPackService.buildStarterPack();
      fullHierarchy = [
        AACCard(
          id: 'seed_hello',
          label: 'Hello',
          labelSinhala: 'හෙලෝ',
          labelTamil: 'வணக்கம்',
          category: 'General',
          colorValue: defaultColor,
        ),
        AACCard(
          id: 'seed_happy',
          label: 'Happy',
          labelSinhala: 'සතුටුයි',
          labelTamil: 'மகிழ்ச்சி',
          category: 'General',
          colorValue: defaultColor,
        ),
        starterPack,
      ];
    });

    // 1. Nested category discovery
    test('1. Nested category discovery traverses multi-level folders and detects cycles', () {
      final categories = CategoryHelper.discoverCategories(fullHierarchy);
      expect(categories, contains('Food'));
      expect(categories, contains('Feelings'));
      expect(categories, contains('Family'));
      expect(categories, contains('Colours'));
      expect(categories, contains('Shapes'));
      expect(categories, contains('Animals'));
      expect(categories, contains('Snacks'));
      expect(categories, contains('Drinks'));
      expect(categories, contains('Needs'));
      expect(categories, contains('Activities'));
      expect(categories, contains('Basic Words'));
      expect(categories, contains('School & Places'));
      expect(categories, contains('Personal Care'));
      expect(categories, contains('General'));

      // Cycle detection
      final cyclicCardA = AACCard(
        id: 'cycle_a',
        label: 'A',
        category: 'CycleCat',
        colorValue: defaultColor,
      );
      final cyclicCardB = AACCard(
        id: 'cycle_b',
        label: 'B',
        category: 'CycleCat',
        colorValue: defaultColor,
      );
      cyclicCardA.subCards.add(cyclicCardB);
      cyclicCardB.subCards.add(cyclicCardA);

      final cycleDiscovered = CategoryHelper.discoverCategories([cyclicCardA]);
      expect(cycleDiscovered, contains('CycleCat'));
    });

    // 2. Correct category counts
    test('2. Correct category counts reflect actual word cards, not container folders', () {
      // Starter pack has 114 word cards + 2 seed word cards = 116 total word cards
      final totalWordCards = CategoryHelper.countWordCardsForCategory(fullHierarchy, 'All');
      expect(totalWordCards, equals(116));

      // Container folders must not be counted
      final foodCount = CategoryHelper.countWordCardsForCategory(fullHierarchy, 'Food');
      expect(foodCount, equals(17));

      final feelingsCount = CategoryHelper.countWordCardsForCategory(fullHierarchy, 'Feelings');
      expect(feelingsCount, equals(10));

      final snacksCount = CategoryHelper.countWordCardsForCategory(fullHierarchy, 'Snacks');
      expect(snacksCount, equals(11));

      final drinksCount = CategoryHelper.countWordCardsForCategory(fullHierarchy, 'Drinks');
      expect(drinksCount, equals(10));

      final generalCount = CategoryHelper.countWordCardsForCategory(fullHierarchy, 'General');
      expect(generalCount, equals(2));
    });

    // 3. Starter pack Default container handling
    test('3. Starter pack Default container folder is never surfaced as a category', () {
      final discovered = CategoryHelper.discoverCategories([starterPack]);
      expect(starterPack.id, equals(StarterPackService.starterPackRootId));
      expect(discovered.contains('Default'), isFalse);
    });

    // 4. User-created categories
    test('4. User-created categories are preserved, even if named "Default"', () {
      final userCardWithDefaultCategory = AACCard(
        id: 'user_card_custom',
        label: 'My Card',
        category: 'Default',
        colorValue: defaultColor,
      );
      final discovered = CategoryHelper.discoverCategories([userCardWithDefaultCategory]);
      expect(discovered, contains('Default'));

      final userCustomCategory = AACCard(
        id: 'user_custom_1',
        label: 'Guitar',
        category: 'Hobbies',
        colorValue: defaultColor,
      );
      final discoveredCustom = CategoryHelper.discoverCategories([userCustomCategory]);
      expect(discoveredCustom, contains('Hobbies'));
    });

    // 5. Categories with duplicate / cased names
    test('5. Categories with duplicate or case variations are unified canonically', () {
      final List<AACCard> mixedCards = [
        AACCard(id: 'm1', label: 'Apple', category: 'food', colorValue: defaultColor),
        AACCard(id: 'm2', label: 'Pizza', category: 'Food', colorValue: defaultColor),
        AACCard(id: 'm3', label: 'Burger', category: 'FOOD', colorValue: defaultColor),
        AACCard(id: 'm4', label: 'Bread', category: ' food ', colorValue: defaultColor),
        AACCard(id: 'm5', label: 'Yes', category: 'basic_words', colorValue: defaultColor),
        AACCard(id: 'm6', label: 'No', category: 'Basic Words', colorValue: defaultColor),
      ];

      final discovered = CategoryHelper.discoverCategories(mixedCards);
      expect(discovered.contains('Food'), isTrue);
      expect(discovered.contains('food'), isFalse);
      expect(discovered.contains('Basic Words'), isTrue);
      expect(discovered.contains('basic_words'), isFalse);

      final foodCount = CategoryHelper.countWordCardsForCategory(mixedCards, 'Food');
      expect(foodCount, equals(4));

      final basicCount = CategoryHelper.countWordCardsForCategory(mixedCards, 'Basic Words');
      expect(basicCount, equals(2));
    });

    // 6. Multiple levels of nested folders
    test('6. Multiple levels of nested folders discover deeply nested word cards', () {
      final level3Word = AACCard(
        id: 'lvl3',
        label: 'Deep Star',
        category: 'Cosmos',
        colorValue: defaultColor,
      );
      final level2Folder = AACCard(
        id: 'lvl2',
        label: 'Level 2',
        type: 'folder',
        colorValue: defaultColor,
        subCards: [level3Word],
      );
      final level1Folder = AACCard(
        id: 'lvl1',
        label: 'Level 1',
        type: 'folder',
        colorValue: defaultColor,
        subCards: [level2Folder],
      );
      final rootFolder = AACCard(
        id: 'lvl0',
        label: 'Root Folder',
        type: 'folder',
        colorValue: defaultColor,
        subCards: [level1Folder],
      );

      final discovered = CategoryHelper.discoverCategories([rootFolder]);
      expect(discovered, contains('Cosmos'));

      final cosmosCards = CategoryHelper.getWordCardsForCategories(
        [rootFolder],
        selectedCategories: {'Cosmos'},
      );
      expect(cosmosCards.length, equals(1));
      expect(cosmosCards.first.id, equals('lvl3'));
      expect(cosmosCards.first.label, equals('Deep Star'));
    });

    // 7. Empty categories
    test('7. Empty categories return 0 count without errors', () {
      final emptyFolder = AACCard(
        id: 'empty_f',
        label: 'Empty Folder',
        type: 'folder',
        category: 'EmptyCategory',
        colorValue: defaultColor,
        subCards: [],
      );

      final count = CategoryHelper.countWordCardsForCategory([emptyFolder], 'EmptyCategory');
      expect(count, equals(0));

      final cards = CategoryHelper.getWordCardsForCategories(
        [emptyFolder],
        selectedCategories: {'EmptyCategory'},
      );
      expect(cards, isEmpty);
    });

    // 8. Deleted and restored cards
    test('8. Deleted and restored cards correctly update counts and discovery', () {
      final List<AACCard> customCards = [
        AACCard(id: 'del_1', label: 'Carrot', category: 'Veggies', colorValue: defaultColor),
        AACCard(id: 'del_2', label: 'Broccoli', category: 'Veggies', colorValue: defaultColor),
      ];

      expect(CategoryHelper.countWordCardsForCategory(customCards, 'Veggies'), equals(2));
      expect(CategoryHelper.discoverCategories(customCards), contains('Veggies'));

      // Delete Broccoli
      final deleted = customCards.removeAt(1);
      expect(CategoryHelper.countWordCardsForCategory(customCards, 'Veggies'), equals(1));

      // Delete Carrot
      customCards.removeAt(0);
      expect(CategoryHelper.countWordCardsForCategory(customCards, 'Veggies'), equals(0));
      expect(CategoryHelper.discoverCategories(customCards).contains('Veggies'), isFalse);

      // Restore Broccoli
      customCards.add(deleted);
      expect(CategoryHelper.countWordCardsForCategory(customCards, 'Veggies'), equals(1));
      expect(CategoryHelper.discoverCategories(customCards), contains('Veggies'));
    });

    // 9. Food category filtering
    test('9. Food category filtering returns all 17 Food word cards directly', () {
      final foodCards = CategoryHelper.getWordCardsForCategories(
        fullHierarchy,
        selectedCategories: {'Food'},
      );

      expect(foodCards.length, equals(17));
      expect(foodCards.every((c) => !c.isFolder), isTrue);
      final labels = foodCards.map((c) => c.label).toSet();
      expect(labels, contains('Rice'));
      expect(labels, contains('Bread'));
      expect(labels, contains('Egg'));
      expect(labels, contains('Fish'));
    });

    // 10. Feelings category filtering
    test('10. Feelings category filtering returns all 10 Feelings word cards', () {
      final feelingsCards = CategoryHelper.getWordCardsForCategories(
        fullHierarchy,
        selectedCategories: {'Feelings'},
      );

      expect(feelingsCards.length, equals(10));
      expect(feelingsCards.every((c) => !c.isFolder), isTrue);
      final labels = feelingsCards.map((c) => c.label).toSet();
      expect(labels, contains('Happy'));
      expect(labels, contains('Sad'));
      expect(labels, contains('Angry'));
      expect(labels, contains('Scared'));
      expect(labels, contains('Tired'));
    });

    // 11. Multiple selected categories
    test('11. Multiple selected categories returns union of unique cards with zero duplicates', () {
      final unionCards = CategoryHelper.getWordCardsForCategories(
        fullHierarchy,
        selectedCategories: {'Food', 'Drinks'},
      );

      expect(unionCards.length, equals(27)); // 17 food + 10 drinks
      final uniqueIds = unionCards.map((c) => c.id).toSet();
      expect(uniqueIds.length, equals(27));
    });

    // 12. Returning to All Cards
    test('12. All Cards returns all word cards', () {
      final allCards = CategoryHelper.getWordCardsForCategories(
        fullHierarchy,
        selectedCategories: {'All Cards'},
      );
      expect(allCards.length, equals(116));

      final allCardsDefault = CategoryHelper.getWordCardsForCategories(
        fullHierarchy,
        selectedCategories: {'All'},
      );
      expect(allCardsDefault.length, equals(116));
    });

    // 13. No changes to original parent relationships
    test('13. Category filtering does not mutate parent relationships or hierarchy', () {
      final originalJson = jsonEncode(fullHierarchy.map((c) => c.toJson()).toList());

      // Perform multiple category queries
      CategoryHelper.getWordCardsForCategories(fullHierarchy, selectedCategories: {'Food'});
      CategoryHelper.getWordCardsForCategories(fullHierarchy, selectedCategories: {'Feelings'});
      CategoryHelper.getWordCardsForCategories(fullHierarchy, selectedCategories: {'Animals'});
      CategoryHelper.getWordCardsForCategories(fullHierarchy, selectedCategories: {'All'});

      final afterJson = jsonEncode(fullHierarchy.map((c) => c.toJson()).toList());
      expect(afterJson, equals(originalJson), reason: 'Hierarchy must remain strictly unchanged');
    });

    // 14. No duplicate persisted cards
    test('14. Traversal ensures card IDs in the returned views are unique', () {
      final wordCards = CategoryHelper.getWordCardsForCategories(fullHierarchy);
      final idSet = <String>{};
      for (final card in wordCards) {
        expect(idSet.add(card.id), isTrue, reason: 'Duplicate card ID detected: ${card.id}');
      }
    });

    // 15. Editing filtered cards targets original persisted card instance
    test('15. Modifying a card in the filtered result modifies the card in the original tree', () {
      final foodCards = CategoryHelper.getWordCardsForCategories(
        fullHierarchy,
        selectedCategories: {'Food'},
      );

      final riceCard = foodCards.firstWhere((c) => c.label == 'Rice');
      final originalLabel = riceCard.label;
      riceCard.label = 'Fragrant Rice';

      // Verify that starterPack inside fullHierarchy has updated in place
      final foodFolder = starterPack.subCards.firstWhere((c) => c.label == 'Food');
      final riceInTree = foodFolder.subCards.firstWhere((c) => c.id == riceCard.id);
      expect(riceInTree.label, equals('Fragrant Rice'));

      // Revert edit
      riceCard.label = originalLabel;
    });

    // 16. Existing backup/restore compatibility
    test('16. Starter pack tree serializes and deserializes accurately with full hierarchy', () {
      final jsonTree = fullHierarchy.map((c) => c.toJson()).toList();
      final serialized = jsonEncode(jsonTree);

      final decoded = (jsonDecode(serialized) as List)
          .map((e) => AACCard.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(decoded.length, equals(fullHierarchy.length));
      final decodedWordCount = CategoryHelper.countWordCardsForCategory(decoded, 'All');
      expect(decodedWordCount, equals(116));

      final decodedFoodCount = CategoryHelper.countWordCardsForCategory(decoded, 'Food');
      expect(decodedFoodCount, equals(17));
    });

    // 17. English, Sinhala and Tamil labels
    test('17. Filtered cards preserve English, Sinhala, and Tamil labels', () {
      final foodCards = CategoryHelper.getWordCardsForCategories(
        fullHierarchy,
        selectedCategories: {'Food'},
      );

      final riceCard = foodCards.firstWhere((c) => c.label == 'Rice');
      expect(riceCard.getLabel('en'), equals('Rice'));
      expect(riceCard.getLabel('si'), isNotEmpty);
      expect(riceCard.getLabel('ta'), isNotEmpty);

      final breadCard = foodCards.firstWhere((c) => c.label == 'Bread');
      expect(breadCard.getLabel('en'), equals('Bread'));
      expect(breadCard.getLabel('si'), equals('පාන්'));
      expect(breadCard.getLabel('ta'), equals('ரொட்டி'));
    });
  });
}
