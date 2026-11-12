import 'package:flutter_test/flutter_test.dart';
import 'package:simple_aac_app/data/default_seed_cards.dart';
import 'package:simple_aac_app/utils/tts_phonemizer.dart';
import 'package:simple_aac_app/utils/tts_voice_helper.dart';

void main() {
  group('TtsPhonemizer.splitByScript', () {
    test('keeps single-script utterances intact', () {
      final si = TtsPhonemizer.splitByScript(
        'මට වතුර ඕනේ',
        preferredLanguage: 'si',
      );
      expect(si.length, 1);
      expect(si.first.languageCode, 'si');
      expect(si.first.text, 'මට වතුර ඕනේ');

      final ta = TtsPhonemizer.splitByScript(
        'எனக்கு தண்ணீர் வேண்டும்',
        preferredLanguage: 'ta',
      );
      expect(ta.length, 1);
      expect(ta.first.languageCode, 'ta');
    });

    test('splits mixed English and Sinhala labels into script runs', () {
      final runs = TtsPhonemizer.splitByScript(
        'TV බලන්න 2',
        preferredLanguage: 'si',
      );
      expect(runs.length, 3);
      expect(runs[0].languageCode, 'en');
      expect(runs[0].text, 'TV');
      expect(runs[1].languageCode, 'si');
      expect(runs[1].text, 'බලන්න');
      expect(runs[2].languageCode, 'en');
      expect(runs[2].text, '2');
    });
  });

  group('TtsPhonemizer.normalizeEnglishText', () {
    test('expands numbers, symbols, and hyphenated words cleanly', () {
      expect(
        TtsPhonemizer.normalizeEnglishText('I want 2 cups & 15% sugar'),
        'I want two cups and fifteen percent sugar',
      );
      expect(
        TtsPhonemizer.normalizeEnglishText('Year 2026 hi-five'),
        'Year two thousand twenty six hi five',
      );
      expect(TtsPhonemizer.normalizeEnglishText('0'), 'zero');
    });
  });

  group('TtsPhonemizer Sinhala & Tamil IPA generation', () {
    test('phonemizes all default Sinhala seed words with non-empty valid IPA', () {
      const seedSi = [
        sinhalaHello,
        sinhalaHappy,
        sinhalaSad,
        sinhalaAngry,
        sinhalaMore,
        sinhalaGood,
        sinhalaPlay,
        'ආයුබෝවන්, මට වතුර ඕනේ.',
        'ශ්‍රී ලංකා කර්ම ක්‍රම',
      ];
      for (final word in seedSi) {
        final ipa = TtsPhonemizer.phonemizeSinhala(word);
        final cps = TtsPhonemizer.phonemizeToCodepoints(word, 'si');
        expect(ipa, isNotEmpty, reason: 'Empty IPA for $word');
        expect(cps, isNotEmpty, reason: 'Empty codepoints for $word');
        expect(ipa.contains('\u207f'), isFalse); // Must not emit unsupported superscript
      }
      expect(TtsPhonemizer.phonemizeSinhala('වතුර'), 'wˈɐtuɹə');
      expect(TtsPhonemizer.phonemizeSinhala('තවත්'), 'tˈɐwət');
      expect(TtsPhonemizer.phonemizeSinhala('හොඳයි'), 'hˈondəji');
      expect(TtsPhonemizer.phonemizeSinhala('සෙල්ලම්'), 'sˈelləm');
      expect(TtsPhonemizer.phonemizeSinhala('හෙලෝ'), 'hˈeloː');
    });

    test('phonemizes all default Tamil seed words and intervocalic rules', () {
      const seedTa = [
        tamilHello,
        tamilHappy,
        tamilSad,
        tamilAngry,
        tamilMore,
        tamilGood,
        tamilPlay,
        'வணக்கம், எனக்கு தண்ணீர் வேண்டும்.',
        'பக்கம் நண்பன் கோபம்',
      ];
      for (final word in seedTa) {
        final ipa = TtsPhonemizer.phonemizeTamil(word);
        final cps = TtsPhonemizer.phonemizeToCodepoints(word, 'ta');
        expect(ipa, isNotEmpty, reason: 'Empty IPA for $word');
        expect(cps, isNotEmpty, reason: 'Empty codepoints for $word');
      }
      expect(TtsPhonemizer.phonemizeTamil('மகிழ்ச்சி'), 'mˈʌɡiɻtʃːi');
      expect(TtsPhonemizer.phonemizeTamil('கோபம்'), 'kˈoːbʌm');
      expect(TtsPhonemizer.phonemizeTamil('வணக்கம்'), 'vˈʌɳʌkkʌm');
    });
  });

  group('TtsVoiceProfileAcoustic separation guarantees', () {
    test('routes Woman, Man, Child Boy, and Child Girl to clear separated specs', () {
      for (final lang in ['en', 'si', 'ta']) {
        final man = TtsVoiceProfile.man.acousticSpecFor(lang);
        final woman = TtsVoiceProfile.woman.acousticSpecFor(lang);
        final boy = TtsVoiceProfile.boy.acousticSpecFor(lang);
        final girl = TtsVoiceProfile.girl.acousticSpecFor(lang);

        expect(man.languageCode, lang);
        expect(woman.languageCode, lang);
        expect(boy.languageCode, lang);
        expect(girl.languageCode, lang);

        if (lang == 'en') {
          expect(man.modelKey, 'en');
          expect(man.speakerId, isNot(equals(woman.speakerId)));
          expect(boy.speakerId, equals(man.speakerId));
          expect(girl.speakerId, equals(woman.speakerId));
          expect(man.targetF0Hz, 0.0);
          expect(man.formantSemitones, 0.0);
        } else if (lang == 'ta') {
          expect(man.modelKey, 'ta_m');
          expect(boy.modelKey, 'ta_m');
          expect(woman.modelKey, 'ta');
          expect(girl.modelKey, 'ta');
          expect(man.targetF0Hz, 0.0);
          expect(man.formantSemitones, 0.0);
        } else {
          // Sinhala uses clean high-HNR chan4lk model + non-linear WORLD across all 4 voices.
          expect(man.modelKey, 'si');
          expect(boy.modelKey, 'si');
          expect(woman.modelKey, 'si');
          expect(girl.modelKey, 'si');
          expect(man.targetF0Hz, inInclusiveRange(115.0, 130.0));
          expect(man.formantSemitones, lessThan(-2.5));
        }

        expect(man.fallbackTargetF0Hz, lessThan(woman.fallbackTargetF0Hz - 70));

        // Boy & Girl occupy distinct child pitch/formant bands above Woman and well separated from each other.
        expect(boy.targetF0Hz, greaterThan(woman.targetF0Hz + 30));
        expect(girl.targetF0Hz, greaterThan(boy.targetF0Hz + 70));
        expect(boy.formantSemitones, greaterThan(woman.formantSemitones + 2.0));
        expect(girl.formantSemitones, greaterThan(boy.formantSemitones));
      }
    });
  });
}
