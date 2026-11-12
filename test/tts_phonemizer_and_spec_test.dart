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
      expect(TtsPhonemizer.phonemizeSinhala('වතුර'), contains('w'));
      expect(TtsPhonemizer.phonemizeSinhala('හොඳයි'), contains('nd̪'));
    });

    test('romanizes Sinhala seed words cleanly for Roshan male model', () {
      for (final word in const [
        sinhalaHello,
        sinhalaHappy,
        sinhalaSad,
        sinhalaAngry,
        sinhalaMore,
        sinhalaGood,
        sinhalaPlay,
        'ආයුබෝවන්, මට වතුර ඕනේ.',
        'ශ්‍රී ලංකා',
      ]) {
        final rom = TtsPhonemizer.phonemizeSinhalaRoman(word);
        final cps = TtsPhonemizer.phonemizeSinhalaRomanCodepoints(word);
        expect(rom, isNotEmpty, reason: 'Empty romanization for $word');
        expect(cps, isNotEmpty);
      }
      expect(TtsPhonemizer.phonemizeSinhalaRoman('සතුටුයි'), 'satuṭuyi');
      expect(TtsPhonemizer.phonemizeSinhalaRoman('හොඳයි'), 'hoṉdayi');
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
      expect(TtsPhonemizer.phonemizeTamil('மகிழ்ச்சி'), contains('ɻ'));
      expect(TtsPhonemizer.phonemizeTamil('கோபம்'), contains('b'));
    });
  });

  group('TtsVoiceProfileAcoustic separation guarantees', () {
    test('routes Man/Boy to native Male models and separates Child Girl vs Woman cleanly', () {
      for (final lang in ['en', 'si', 'ta']) {
        final man = TtsVoiceProfile.man.acousticSpecFor(lang);
        final woman = TtsVoiceProfile.woman.acousticSpecFor(lang);
        final boy = TtsVoiceProfile.boy.acousticSpecFor(lang);
        final girl = TtsVoiceProfile.girl.acousticSpecFor(lang);

        expect(man.languageCode, lang);
        expect(woman.languageCode, lang);
        expect(boy.languageCode, lang);
        expect(girl.languageCode, lang);

        // Female models feed Woman & Girl; native Male models feed Man & Boy.
        if (lang == 'en') {
          expect(man.modelKey, 'en');
          expect(man.speakerId, isNot(equals(woman.speakerId)));
          expect(boy.speakerId, equals(man.speakerId));
          expect(girl.speakerId, equals(woman.speakerId));
        } else {
          expect(man.modelKey, '${lang}_m');
          expect(boy.modelKey, '${lang}_m');
          expect(woman.modelKey, lang);
          expect(girl.modelKey, lang);
        }
        expect(man.useRomanPhonemizer, lang == 'si');
        expect(boy.useRomanPhonemizer, lang == 'si');
        expect(woman.useRomanPhonemizer, isFalse);
        expect(girl.useRomanPhonemizer, isFalse);

        // Man plays native un-pitched male voice (targetF0Hz == 0) to prevent pitch-down artifacts.
        expect(man.targetF0Hz, 0.0);
        expect(man.formantSemitones, 0.0);
        expect(man.fallbackTargetF0Hz, lessThan(woman.fallbackTargetF0Hz - 70));

        // Boy (from Male) & Girl (from Female) use WORLD shorter child vocal tract + higher F0.
        expect(boy.targetF0Hz, greaterThan(woman.targetF0Hz + 20));
        expect(girl.targetF0Hz, greaterThan(boy.targetF0Hz + 70));
        expect(boy.formantSemitones, greaterThan(woman.formantSemitones + 3.0));
        expect(girl.formantSemitones, greaterThan(boy.formantSemitones));
      }
    });
  });
}
