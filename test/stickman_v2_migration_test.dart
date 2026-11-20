import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_aac_app/data/default_seed_cards.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('stickman_v2_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;
    SharedPreferences.setMockInitialValues({});
    StarterPackService.clearCache();
  });

  tearDown(() async {
    CardStorageService.resetTestHooks();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Stickman Pack v2 — Fresh Install Verification', () {
    test('Fresh install creates 6 root cards and exactly 8 More sub-cards', () async {
      final loaded = await CardStorageService.loadCards(
        defaultCardsBuilder: createDefaultSeedCards,
      );

      expect(loaded.length, equals(6));
      final hello = loaded.firstWhere((c) => c.id == 'seed_hello');
      final happy = loaded.firstWhere((c) => c.id == 'seed_happy');
      final sad = loaded.firstWhere((c) => c.id == 'seed_sad');
      final angry = loaded.firstWhere((c) => c.id == 'seed_angry');
      final more = loaded.firstWhere((c) => c.id == 'seed_more');
      final defaultFolder = loaded.firstWhere((c) => c.id == StarterPackService.starterPackRootId);

      expect(hello.imagePath, equals('assets/home/hello.webp'));
      expect(happy.imagePath, equals('assets/home/happy.webp'));
      expect(sad.imagePath, equals('assets/home/sad.webp'));
      expect(angry.imagePath, equals('assets/home/angry.webp'));
      expect(more.imagePath, equals('assets/images/seed_v2/more.webp'));
      expect(defaultFolder.imagePath, equals('assets/images/starter_pack_v8/starter_default.webp'));

      expect(more.subCards.length, equals(8));
      final subIds = more.subCards.map((c) => c.id).toList();
      expect(subIds, equals([
        'seed_good',
        'seed_play',
        'seed_yes',
        'seed_no',
        'seed_please',
        'seed_thank_you',
        'seed_help',
        'seed_stop',
      ]));

      // Check trilingual labels for each of the 6 new cards
      final yes = more.subCards.firstWhere((c) => c.id == 'seed_yes');
      expect(yes.label, equals('Yes'));
      expect(yes.labelSinhala, equals('ඔව්'));
      expect(yes.labelTamil, equals('ஆம்'));
      expect(yes.imagePath, equals('assets/images/seed_v2/yes.webp'));
      expect(yes.colorValue, equals(0xFF9ADEA7));

      final no = more.subCards.firstWhere((c) => c.id == 'seed_no');
      expect(no.label, equals('No'));
      expect(no.labelSinhala, equals('නැහැ'));
      expect(no.labelTamil, equals('இல்லை'));
      expect(no.imagePath, equals('assets/images/seed_v2/no.webp'));
      expect(no.colorValue, equals(0xFFEB9698));

      final please = more.subCards.firstWhere((c) => c.id == 'seed_please');
      expect(please.label, equals('Please'));
      expect(please.labelSinhala, equals('කරුණාකර'));
      expect(please.labelTamil, equals('தயவுசெய்து'));
      expect(please.imagePath, equals('assets/images/seed_v2/please.webp'));
      expect(please.colorValue, equals(0xFFCF99DB));

      final thankYou = more.subCards.firstWhere((c) => c.id == 'seed_thank_you');
      expect(thankYou.label, equals('Thank You'));
      expect(thankYou.labelSinhala, equals('ස්තුතියි'));
      expect(thankYou.labelTamil, equals('நன்றி'));
      expect(thankYou.imagePath, equals('assets/images/seed_v2/thank_you.webp'));
      expect(thankYou.colorValue, equals(0xFFFDE473));

      final help = more.subCards.firstWhere((c) => c.id == 'seed_help');
      expect(help.label, equals('Help'));
      expect(help.labelSinhala, equals('උදව්'));
      expect(help.labelTamil, equals('உதவி'));
      expect(help.imagePath, equals('assets/images/seed_v2/help.webp'));
      expect(help.colorValue, equals(0xFF70E3EC));

      final stop = more.subCards.firstWhere((c) => c.id == 'seed_stop');
      expect(stop.label, equals('Stop'));
      expect(stop.labelSinhala, equals('නවත්වන්න'));
      expect(stop.labelTamil, equals('நிறுத்து'));
      expect(stop.imagePath, equals('assets/images/seed_v2/stop.webp'));
      expect(stop.colorValue, equals(0xFFFC877C));
    });
  });

  group('Stickman Pack v2 — Upgrade & Migration Safety', () {
    test('Existing user on version 8 with 2 More sub-cards migrates to 8 sub-cards without loss', () async {
      final userPhoto = '${tempDir.path}/child_custom_photo.jpg';
      await File(userPhoto).writeAsBytes([10, 20, 30]);

      final initialUserCards = [
        AACCard(
          id: 'seed_hello',
          label: 'Hello',
          imagePath: 'assets/images/seed/hello.png', // legacy PNG
          colorValue: Colors.yellow.shade300.value,
        ),
        AACCard(
          id: 'seed_happy',
          label: 'My Custom Happy',
          imagePath: userPhoto, // custom user photo
          colorValue: Colors.lightBlue.shade200.value,
        ),
        AACCard(
          id: 'seed_more',
          label: 'More',
          imagePath: 'assets/images/seed/blocks.png', // legacy PNG
          colorValue: Colors.indigo.shade500.value,
          type: 'folder',
          subCards: [
            AACCard(
              id: 'seed_good',
              label: 'Good',
              imagePath: 'assets/images/seed/good.png',
              colorValue: Colors.green.shade300.value,
            ),
            AACCard(
              id: 'seed_play',
              label: 'Play',
              imagePath: 'assets/images/seed/play.png',
              colorValue: Colors.orange.shade300.value,
            ),
            AACCard(
              id: 'custom_user_more_card',
              label: 'Favorite Toy',
              colorValue: 0xFFFF0000,
            ),
          ],
        ),
      ];

      await CardStorageService.saveCards(initialUserCards);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeededDefaultCards', true);
      await prefs.setInt('seededDefaultCardsVersion', 8);

      final loaded = await CardStorageService.loadCards(
        defaultCardsBuilder: createDefaultSeedCards,
      );

      final hello = loaded.firstWhere((c) => c.id == 'seed_hello');
      expect(hello.imagePath, equals('assets/home/hello.webp'),
          reason: 'Legacy PNG seed image should upgrade to child WebP');

      final happy = loaded.firstWhere((c) => c.id == 'seed_happy');
      expect(happy.imagePath, equals(userPhoto),
          reason: 'User custom photo must never be overwritten');
      expect(happy.label, equals('My Custom Happy'),
          reason: 'User custom label must never be overwritten');

      final more = loaded.firstWhere((c) => c.id == 'seed_more');
      expect(more.imagePath, equals('assets/images/seed_v2/more.webp'));
      
      // Sub-cards should have 2 existing + 1 custom + 6 new = 9 total sub-cards
      expect(more.subCards.length, equals(9));
      expect(more.subCards.any((c) => c.id == 'custom_user_more_card'), isTrue,
          reason: 'User custom card in More must be preserved');
      expect(more.subCards.any((c) => c.id == 'seed_yes'), isTrue);
      expect(more.subCards.any((c) => c.id == 'seed_no'), isTrue);
      expect(more.subCards.any((c) => c.id == 'seed_please'), isTrue);
      expect(more.subCards.any((c) => c.id == 'seed_thank_you'), isTrue);
      expect(more.subCards.any((c) => c.id == 'seed_help'), isTrue);
      expect(more.subCards.any((c) => c.id == 'seed_stop'), isTrue);

      // Verify idempotency on second load
      final reloaded = await CardStorageService.loadCards(
        defaultCardsBuilder: createDefaultSeedCards,
      );
      expect(reloaded.firstWhere((c) => c.id == 'seed_more').subCards.length, equals(9));
    });

    test('Deleted seed_angry is NOT restored for existing users', () async {
      final initialCards = [
        AACCard(
          id: 'seed_hello',
          label: 'Hello',
          imagePath: 'assets/images/seed/hello.png',
          colorValue: Colors.yellow.shade300.value,
        ),
      ];

      await CardStorageService.saveCards(initialCards);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeededDefaultCards', true);
      await prefs.setInt('seededDefaultCardsVersion', 8);

      final loaded = await CardStorageService.loadCards(
        defaultCardsBuilder: createDefaultSeedCards,
      );

      expect(loaded.any((c) => c.id == 'seed_angry'), isFalse,
          reason: 'Previously deleted seed card must not be resurrected on version bump');
    });
  });

  group('Stickman Pack v2 — Backup & Restore Round-trip', () {
    test('Full backup and restore round-trip preserves all 8 More cards', () async {
      final defaultCards = createDefaultSeedCards();
      await CardStorageService.saveCards(defaultCards);

      final zipBytes = await BackupService.buildBackupZip(defaultCards);
      expect(zipBytes, isNotNull);

      final payload = await BackupService.restoreFromZipBytes(zipBytes!);
      expect(payload.cards.length, equals(6));

      final restoredMore = payload.cards.firstWhere((c) => c.id == 'seed_more');
      expect(restoredMore.subCards.length, equals(8));
      expect(restoredMore.subCards.map((c) => c.id).toList(), equals([
        'seed_good',
        'seed_play',
        'seed_yes',
        'seed_no',
        'seed_please',
        'seed_thank_you',
        'seed_help',
        'seed_stop',
      ]));
    });
  });
}
