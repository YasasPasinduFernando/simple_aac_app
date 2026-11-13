import 'package:flutter_test/flutter_test.dart';
import 'package:simple_aac_app/services/multilingual_concept_service.dart';

void main() {
  group('MultilingualConceptService Tests', () {
    test('Resolves Sinhala AAC words correctly', () {
      expect(MultilingualConceptService.normalizeConcept('පූසා'), 'cute cat');
      expect(MultilingualConceptService.normalizeConcept('වතුර'), 'glass of water');
      expect(MultilingualConceptService.normalizeConcept('බෝලය'), 'colorful ball');
      expect(MultilingualConceptService.normalizeConcept('අම්මා'), 'mother');
      expect(MultilingualConceptService.normalizeConcept('කනවා'), 'eating food');
      expect(MultilingualConceptService.normalizeConcept('සතුටුයි'), 'happy smiling child');
    });

    test('Resolves Tamil AAC words correctly', () {
      expect(MultilingualConceptService.normalizeConcept('பூனை'), 'cute cat');
      expect(MultilingualConceptService.normalizeConcept('தண்ணீர்'), 'glass of water');
      expect(MultilingualConceptService.normalizeConcept('பந்து'), 'colorful ball');
      expect(MultilingualConceptService.normalizeConcept('அம்மா'), 'mother');
      expect(MultilingualConceptService.normalizeConcept('சாப்பிடு'), 'eating food');
      expect(MultilingualConceptService.normalizeConcept('மகிழ்ச்சி'), 'happy smiling child');
    });

    test('Resolves English AAC words correctly', () {
      expect(MultilingualConceptService.normalizeConcept('cat'), 'cute cat');
      expect(MultilingualConceptService.normalizeConcept('water'), 'water');
      expect(MultilingualConceptService.normalizeConcept('ball'), 'colorful ball');
      expect(MultilingualConceptService.normalizeConcept('mother'), 'mother');
    });

    test('Handles case and whitespace trimming', () {
      expect(MultilingualConceptService.normalizeConcept('  DOG  '), 'friendly dog');
      expect(MultilingualConceptService.normalizeConcept('  පාසල  '), 'school building');
    });

    test('Does not trigger partial English substring collisions', () {
      expect(MultilingualConceptService.normalizeConcept('good'), 'thumbs up good');
      expect(MultilingualConceptService.normalizeConcept('mango'), 'mango');
      expect(MultilingualConceptService.normalizeConcept('teacher'), 'teacher');
      expect(MultilingualConceptService.normalizeConcept('carrot'), 'carrot');
      expect(MultilingualConceptService.normalizeConcept('hello'), 'happy waving child');
    });

    test('Identifies Latin vs non-Latin scripts correctly', () {
      expect(MultilingualConceptService.isLatinScript('apple'), isTrue);
      expect(MultilingualConceptService.isLatinScript('ඇපල්'), isFalse);
      expect(MultilingualConceptService.isLatinScript('ஆப்பிள்'), isFalse);
    });

    test('Distills verbose concept strings to core search keywords without breaking custom phrases', () {
      expect(MultilingualConceptService.toSearchCore('සතුටුයි'), 'happy');
      expect(MultilingualConceptService.toSearchCore('නානවා'), 'bathtub');
      expect(MultilingualConceptService.toSearchCore('අඹ'), 'mango');
      expect(MultilingualConceptService.toSearchCore('සපත්තු'), 'shoe');
      expect(MultilingualConceptService.toSearchCore('red apple'), 'red apple');
    });

    test('Trilingual AAC vocabulary lookup resolves core categories correctly', () {
      // Food & Drink
      final water = MultilingualConceptService.lookupTranslations('water');
      expect(water, isNotNull);
      expect(water!.sinhala, 'වතුර');
      expect(water.tamil, 'தண்ணீர்');
      expect(water.category, 'Food & Drink');

      // Animals
      final cat = MultilingualConceptService.lookupTranslations('cat');
      expect(cat, isNotNull);
      expect(cat!.sinhala, 'පූසා');
      expect(cat.tamil, 'பூனை');
      expect(cat.category, 'Animals');

      // Toys & Learning
      final book = MultilingualConceptService.lookupTranslations('book');
      expect(book, isNotNull);
      expect(book!.sinhala, 'පොත');
      expect(book.tamil, 'புத்தகம்');
      expect(book.category, 'Toys & Learning');

      // Clothing
      final shoes = MultilingualConceptService.lookupTranslations('shoes');
      expect(shoes, isNotNull);
      expect(shoes!.sinhala, 'සපත්තු');
      expect(shoes.tamil, 'காலணிகள்');

      // Actions
      final eat = MultilingualConceptService.lookupTranslations('eat');
      expect(eat, isNotNull);
      expect(eat!.sinhala, 'කනවා');
      expect(eat.tamil, 'சாப்பிடு');

      // Feelings
      final happy = MultilingualConceptService.lookupTranslations('happy');
      expect(happy, isNotNull);
      expect(happy!.sinhala, 'සතුටුයි');
      expect(happy.tamil, 'மகிழ்ச்சி');

      // People
      final mother = MultilingualConceptService.lookupTranslations('mother');
      expect(mother, isNotNull);
      expect(mother!.sinhala, 'අම්මා');
      expect(mother.tamil, 'அம்மா');

      // Vehicles
      final bus = MultilingualConceptService.lookupTranslations('bus');
      expect(bus, isNotNull);
      expect(bus!.sinhala, 'බස් එක');
      expect(bus.tamil, 'பேருந்து');
    });

    test('Trilingual vocabulary strictly preserves entity nuance (e.g. puppy vs dog, kitten vs cat)', () {
      final dog = MultilingualConceptService.lookupTranslations('dog');
      final puppy = MultilingualConceptService.lookupTranslations('puppy');
      expect(dog, isNotNull);
      expect(puppy, isNotNull);
      expect(dog!.sinhala, isNot(equals(puppy!.sinhala)));
      expect(dog.tamil, isNot(equals(puppy.tamil)));
      expect(dog.sinhala, 'බල්ලා');
      expect(puppy.sinhala, 'බලු පැටියා');
      expect(dog.tamil, 'நாய்');
      expect(puppy.tamil, 'நாய்க்குட்டி');

      final cat = MultilingualConceptService.lookupTranslations('cat');
      final kitten = MultilingualConceptService.lookupTranslations('kitten');
      expect(cat, isNotNull);
      expect(kitten, isNotNull);
      expect(cat!.sinhala, isNot(equals(kitten!.sinhala)));
      expect(cat.tamil, isNot(equals(kitten.tamil)));
      expect(cat.sinhala, 'පූසා');
      expect(kitten.sinhala, 'පූස් පැටියා');
      expect(cat.tamil, 'பூனை');
      expect(kitten.tamil, 'பூனைக்குட்டி');
    });

    test('Trilingual lookup normalizes case, whitespace, leading articles, punctuation, and plurals', () {
      expect(MultilingualConceptService.lookupTranslations('  DOG  ')?.sinhala, 'බල්ලා');
      expect(MultilingualConceptService.lookupTranslations('a dog')?.sinhala, 'බල්ලා');
      expect(MultilingualConceptService.lookupTranslations('an apple')?.sinhala, 'ඇපල්');
      expect(MultilingualConceptService.lookupTranslations('the ball!')?.sinhala, 'බෝලය');
      expect(MultilingualConceptService.lookupTranslations('cups')?.sinhala, 'කෝප්පය');
      expect(MultilingualConceptService.lookupTranslations('dogs')?.tamil, 'நாய்');
    });

    test('Trilingual lookup returns null for unverified words without guessing or inventing text', () {
      expect(MultilingualConceptService.lookupTranslations('unobtainium'), isNull);
      expect(MultilingualConceptService.lookupTranslations('xyz123'), isNull);
      expect(MultilingualConceptService.lookupTranslations(''), isNull);
      expect(MultilingualConceptService.lookupTranslations('   '), isNull);
    });

    test('Every entry in trilingual vocabulary has valid Unicode, non-empty labels, and valid categories', () {
      final vocab = MultilingualConceptService.trilingualVocabulary;
      expect(vocab.length, greaterThanOrEqualTo(150));

      // Allow Sinhala and Tamil Unicode ranges, standard punctuation, and ZWJ/ZWNJ (\u200C, \u200D) essential for Indic ligatures
      final sinhalaRegex = RegExp(r'^[\u0D80-\u0DFF\u200C\u200D\s\.,\-/\(\)]+$');
      final tamilRegex = RegExp(r'^[\u0B80-\u0BFF\u200C\u200D\s\.,\-/\(\)]+$');

      for (final entry in vocab.entries) {
        final key = entry.key;
        final item = entry.value;

        expect(key.isNotEmpty, isTrue, reason: 'Key should not be empty');
        expect(item.english.isNotEmpty, isTrue, reason: 'English label for $key is empty');
        expect(item.sinhala.isNotEmpty, isTrue, reason: 'Sinhala label for $key is empty');
        expect(item.tamil.isNotEmpty, isTrue, reason: 'Tamil label for $key is empty');
        expect(item.category.isNotEmpty, isTrue, reason: 'Category for $key is empty');

        expect(
          sinhalaRegex.hasMatch(item.sinhala),
          isTrue,
          reason: 'Sinhala label "${item.sinhala}" for "$key" contains invalid characters outside Sinhala Unicode block',
        );

        expect(
          tamilRegex.hasMatch(item.tamil),
          isTrue,
          reason: 'Tamil label "${item.tamil}" for "$key" contains invalid characters outside Tamil Unicode block',
        );
      }
    });
  });
}
