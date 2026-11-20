import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_aac_app/data/default_seed_cards.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StarterPackService.clearCache();
  });

  const expectedPersonalCareActionIds = [
    'simpleaac.starter.v2.personal_care.wash_face',
    'simpleaac.starter.v2.personal_care.take_bath',
    'simpleaac.starter.v2.personal_care.wash_hands',
    'simpleaac.starter.v2.personal_care.dry_hands',
    'simpleaac.starter.v2.personal_care.comb_hair',
    'simpleaac.starter.v2.personal_care.get_dressed',
    'simpleaac.starter.v2.personal_care.put_on_shoes',
  ];

  const expectedActivitiesActionIds = [
    'simpleaac.starter.v2.activities.sleep',
    'simpleaac.starter.v2.activities.watch_tv',
    'simpleaac.starter.v2.activities.play_games',
    'simpleaac.starter.v2.activities.read_book',
    'simpleaac.starter.v2.activities.draw',
    'simpleaac.starter.v2.activities.listen_music',
    'simpleaac.starter.v2.activities.play_outside',
  ];

  group('Daily Actions Manifest & Hierarchy Integration', () {
    test('1. Manifest builds 142 total nodes (1 root + 13 folders + 128 words)', () {
      final root = StarterPackService.buildStarterPack();

      expect(root.id, equals(StarterPackService.starterPackRootId));
      expect(root.subCards.length, equals(13));

      // Personal Care has 3 original + 7 new = 10 cards
      final personalCare = root.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.personal_care');
      expect(personalCare.subCards.length, equals(10));
      final pcIds = personalCare.subCards.map((c) => c.id).toList();
      expect(pcIds.sublist(0, 3), equals([
        'simpleaac.starter.v2.personal_care.toothpaste',
        'simpleaac.starter.v2.personal_care.toothbrush',
        'simpleaac.starter.v2.personal_care.brush_teeth',
      ]));
      expect(pcIds.sublist(3), equals(expectedPersonalCareActionIds));

      // Activities has 5 original + 7 new = 12 cards
      final activities = root.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.activities');
      expect(activities.subCards.length, equals(12));
      final actIds = activities.subCards.map((c) => c.id).toList();
      expect(actIds.sublist(0, 5), equals([
        'simpleaac.starter.v2.activities.eat',
        'simpleaac.starter.v2.activities.drink',
        'simpleaac.starter.v2.activities.play',
        'simpleaac.starter.v2.activities.read',
        'simpleaac.starter.v2.activities.walk',
      ]));
      expect(actIds.sublist(5), equals(expectedActivitiesActionIds));
    });

    test('2. All 14 WebP assets exist on disk and have valid non-empty byte streams', () {
      final root = StarterPackService.buildStarterPack();
      final allWordsById = <String, AACCard>{};
      for (final folder in root.subCards) {
        for (final word in folder.subCards) {
          allWordsById[word.id] = word;
        }
      }

      for (final id in [...expectedPersonalCareActionIds, ...expectedActivitiesActionIds]) {
        final card = allWordsById[id];
        expect(card, isNotNull, reason: 'Card $id must exist in manifest');
        expect(card!.imagePath, isNotNull);
        final file = File(card.imagePath!);
        expect(file.existsSync(), isTrue, reason: 'File ${card.imagePath} must exist on disk');
        expect(file.lengthSync(), greaterThan(1000), reason: 'File ${card.imagePath} must be a valid WebP');
      }
    });

    test('3. Trilingual labels and speech strings resolve accurately for all 14 cards', () {
      final root = StarterPackService.buildStarterPack();
      final allWordsById = <String, AACCard>{};
      for (final folder in root.subCards) {
        for (final word in folder.subCards) {
          allWordsById[word.id] = word;
        }
      }

      final expectedLabels = <String, Map<String, String>>{
        'simpleaac.starter.v2.personal_care.wash_face': {'en': 'Wash Face', 'si': 'මුහුණ හෝදන්න', 'ta': 'முகம் கழுவு'},
        'simpleaac.starter.v2.personal_care.take_bath': {'en': 'Take Bath', 'si': 'නාන්න', 'ta': 'குளி'},
        'simpleaac.starter.v2.personal_care.wash_hands': {'en': 'Wash Hands', 'si': 'අත් හෝදන්න', 'ta': 'கை கழுவு'},
        'simpleaac.starter.v2.personal_care.dry_hands': {'en': 'Dry Hands', 'si': 'අත් පිසදමන්න', 'ta': 'கைகளை துடை'},
        'simpleaac.starter.v2.personal_care.comb_hair': {'en': 'Comb Hair', 'si': 'කොණ්ඩය පීරන්න', 'ta': 'தலை சீவு'},
        'simpleaac.starter.v2.personal_care.get_dressed': {'en': 'Get Dressed', 'si': 'ඇඳුම් අඳින්න', 'ta': 'ஆடை அணி'},
        'simpleaac.starter.v2.personal_care.put_on_shoes': {'en': 'Put On Shoes', 'si': 'සපත්තු දාන්න', 'ta': 'காலணி அணி'},
        'simpleaac.starter.v2.activities.sleep': {'en': 'Sleep', 'si': 'නිදාගන්න', 'ta': 'தூங்கு'},
        'simpleaac.starter.v2.activities.watch_tv': {'en': 'Watch TV', 'si': 'ටීවී බලන්න', 'ta': 'டிவி பார்'},
        'simpleaac.starter.v2.activities.play_games': {'en': 'Play Games', 'si': 'ගේම් ගහන්න', 'ta': 'கேம் விளையாடு'},
        'simpleaac.starter.v2.activities.read_book': {'en': 'Read Book', 'si': 'පොත් කියවන්න', 'ta': 'புத்தகம் வாசி'},
        'simpleaac.starter.v2.activities.draw': {'en': 'Draw', 'si': 'චිත්‍ර අඳින්න', 'ta': 'படம் வரை'},
        'simpleaac.starter.v2.activities.listen_music': {'en': 'Listen to Music', 'si': 'සින්දු අහන්න', 'ta': 'பாட்டு கேள்'},
        'simpleaac.starter.v2.activities.play_outside': {'en': 'Play Outside', 'si': 'එළියේ සෙල්ලම් කරන්න', 'ta': 'வெளியே விளையாடு'},
      };

      for (final entry in expectedLabels.entries) {
        final card = allWordsById[entry.key]!;
        expect(card.getLabel('en'), equals(entry.value['en']));
        expect(card.getLabel('si'), equals(entry.value['si']));
        expect(card.getLabel('ta'), equals(entry.value['ta']));
      }
    });
  }, skip: 'Pending post-1.1.5 daily actions manifest expansion');

  group('Safe Additive Upgrade Migration & Zero Existing Data Loss', () {
    test('4. Fresh installation seeds demo cards + complete starter pack with all 14 daily actions', () {
      final seedCards = createDefaultSeedCards();
      expect(seedCards.length, equals(6));
      expect(CardStorageService.countCards(seedCards), equals(155)); // 13 demo cards (5 root + 8 More sub-cards) + 142 pack cards
    });

    test('5. Existing user board retains all custom cards, photos, audio and modified ordering', () {
      // Simulate an existing user's board with custom cards and modified Personal Care cards
      final userCards = [
        AACCard(
          id: 'seed_hello',
          label: 'Hello!',
          colorValue: 0xFFFEE685,
        ),
        AACCard(
          id: 'user_grandma_card',
          label: 'My Grandma',
          imagePath: '/data/user/0/grandma.jpg',
          voicePath: '/data/user/0/grandma.m4a',
          colorValue: 0xFFE2F0D9,
        ),
      ];

      // Add a starter pack that only had the original 3 Personal Care cards
      final oldStarterPack = AACCard(
        id: StarterPackService.starterPackRootId,
        label: 'Default',
        type: 'folder',
        colorValue: 0xFF228ED3,
        subCards: [
          AACCard(
            id: 'simpleaac.starter.v2.personal_care',
            label: 'Personal Care',
            type: 'folder',
            colorValue: 0xFFFDE5A9,
            subCards: [
              AACCard(
                id: 'simpleaac.starter.v2.personal_care.toothpaste',
                label: 'Custom Toothpaste Label',
                colorValue: 0xFF112233,
                voicePath: '/data/user/0/custom_brush.m4a',
              ),
              AACCard(
                id: 'simpleaac.starter.v2.personal_care.toothbrush',
                label: 'Toothbrush',
                colorValue: 0xFFC5E8D5,
              ),
              AACCard(
                id: 'simpleaac.starter.v2.personal_care.brush_teeth',
                label: 'Brush Teeth',
                colorValue: 0xFFFCE5AC,
              ),
            ],
          ),
          AACCard(
            id: 'simpleaac.starter.v2.activities',
            label: 'Activities',
            type: 'folder',
            colorValue: 0xFFCBE5FA,
            subCards: [
              AACCard(id: 'simpleaac.starter.v2.activities.eat', label: 'Eat', colorValue: 0xFFCDE4F7),
              AACCard(id: 'simpleaac.starter.v2.activities.drink', label: 'Drink', colorValue: 0xFFCDE4F7),
              AACCard(id: 'simpleaac.starter.v2.activities.play', label: 'Play', colorValue: 0xFFCDE4F7),
              AACCard(id: 'simpleaac.starter.v2.activities.read', label: 'Read', colorValue: 0xFFCDE4F7),
              AACCard(id: 'simpleaac.starter.v2.activities.walk', label: 'Walk', colorValue: 0xFFCDE4F7),
            ],
          ),
        ],
      );
      userCards.add(oldStarterPack);

      // Perform safe additive import
      final result = StarterPackService.importStarterPack(userCards);

      expect(result.alreadyInstalled, isTrue);
      // 14 new cards added (7 in Personal Care, 7 in Activities) + 11 other missing categories from full pack
      expect(result.cardsAdded, greaterThanOrEqualTo(14));

      // 1. Verify user custom card is 100% preserved
      final grandmaCard = userCards.firstWhere((c) => c.id == 'user_grandma_card');
      expect(grandmaCard.label, equals('My Grandma'));
      expect(grandmaCard.imagePath, equals('/data/user/0/grandma.jpg'));
      expect(grandmaCard.voicePath, equals('/data/user/0/grandma.m4a'));

      // 2. Verify modified toothpaste card is 100% preserved
      final root = userCards.firstWhere((c) => c.id == StarterPackService.starterPackRootId);
      final pc = root.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.personal_care');
      final toothpaste = pc.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.personal_care.toothpaste');
      expect(toothpaste.label, equals('Custom Toothpaste Label'));
      expect(toothpaste.colorValue, equals(0xFF112233));
      expect(toothpaste.voicePath, equals('/data/user/0/custom_brush.m4a'));

      // 3. Verify original 3 Personal Care cards remain in first 3 positions
      expect(pc.subCards[0].id, equals('simpleaac.starter.v2.personal_care.toothpaste'));
      expect(pc.subCards[1].id, equals('simpleaac.starter.v2.personal_care.toothbrush'));
      expect(pc.subCards[2].id, equals('simpleaac.starter.v2.personal_care.brush_teeth'));

      // 4. Verify 7 new Personal Care cards were appended
      for (final id in expectedPersonalCareActionIds) {
        expect(pc.subCards.any((c) => c.id == id), isTrue, reason: 'Personal Care must contain $id');
      }

      // 5. Verify 7 new Activities cards were appended
      final act = root.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.activities');
      for (final id in expectedActivitiesActionIds) {
        expect(act.subCards.any((c) => c.id == id), isTrue, reason: 'Activities must contain $id');
      }

      // 6. Test Idempotency: run import again
      final secondResult = StarterPackService.importStarterPack(userCards);
      expect(secondResult.alreadyInstalled, isTrue);
      expect(secondResult.cardsAdded, equals(0)); // EXACTLY ZERO duplicates added

      // Run third time
      final thirdResult = StarterPackService.importStarterPack(userCards);
      expect(thirdResult.cardsAdded, equals(0));
    });

    test('6. Reversible rollback capability cleanly removes only newly added cards', () {
      final packRoot = StarterPackService.getStarterPackRootClone();
      final userCards = [packRoot];

      final all14NewIds = {
        ...expectedPersonalCareActionIds,
        ...expectedActivitiesActionIds,
      };

      // Rollback function
      void rollbackDailyActions(List<AACCard> cards) {
        for (final card in cards) {
          card.subCards.removeWhere((child) => all14NewIds.contains(child.id));
          if (card.subCards.isNotEmpty) {
            rollbackDailyActions(card.subCards);
          }
        }
      }

      final pc = packRoot.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.personal_care');
      final act = packRoot.subCards.firstWhere((c) => c.id == 'simpleaac.starter.v2.activities');
      expect(pc.subCards.length, equals(10));
      expect(act.subCards.length, equals(12));

      rollbackDailyActions(userCards);

      // Personal Care returns to original 3 cards
      expect(pc.subCards.length, equals(3));
      expect(pc.subCards.map((c) => c.id).toList(), equals([
        'simpleaac.starter.v2.personal_care.toothpaste',
        'simpleaac.starter.v2.personal_care.toothbrush',
        'simpleaac.starter.v2.personal_care.brush_teeth',
      ]));

      // Activities returns to original 5 cards
      expect(act.subCards.length, equals(5));
      expect(act.subCards.map((c) => c.id).toList(), equals([
        'simpleaac.starter.v2.activities.eat',
        'simpleaac.starter.v2.activities.drink',
        'simpleaac.starter.v2.activities.play',
        'simpleaac.starter.v2.activities.read',
        'simpleaac.starter.v2.activities.walk',
      ]));
    });
  }, skip: 'Pending post-1.1.5 daily actions manifest expansion');
}
