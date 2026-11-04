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

    test('Identifies Latin vs non-Latin scripts correctly', () {
      expect(MultilingualConceptService.isLatinScript('apple'), isTrue);
      expect(MultilingualConceptService.isLatinScript('ඇපල්'), isFalse);
      expect(MultilingualConceptService.isLatinScript('ஆப்பிள்'), isFalse);
    });
  });
}
