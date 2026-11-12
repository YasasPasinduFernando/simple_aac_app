import 'package:flutter_test/flutter_test.dart';
import 'package:simple_aac_app/utils/multilingual_speech_router.dart';

void main() {
  group('MultilingualSpeechRouter.route', () {
    test('routes pure English, Sinhala, and Tamil cleanly', () {
      final en = MultilingualSpeechRouter.route('Hello', preferredLanguage: 'en');
      expect(en.length, 1);
      expect(en.first.languageCode, 'en');
      expect(en.first.text, 'Hello');

      final si = MultilingualSpeechRouter.route(
        'මට වතුර ඕනේ',
        preferredLanguage: 'si',
      );
      expect(si.length, 1);
      expect(si.first.languageCode, 'si');
      expect(si.first.text, 'මට වතුර ඕනේ');

      final ta = MultilingualSpeechRouter.route(
        'வணக்கம்',
        preferredLanguage: 'ta',
      );
      expect(ta.length, 1);
      expect(ta.first.languageCode, 'ta');
      expect(ta.first.text, 'வணக்கம்');
    });

    test('segments mixed Sinhala + English and Tamil + English without distorting English words', () {
      final siMix1 = MultilingualSpeechRouter.route(
        'මට water එකක් දෙන්න',
        preferredLanguage: 'si',
      );
      expect(
        siMix1.map((s) => '${s.languageCode}:${s.text}').toList(),
        ['si:මට', 'en:water', 'si:එකක් දෙන්න'],
      );

      final siMix2 = MultilingualSpeechRouter.route(
        'අද school යන්න ඕනේ',
        preferredLanguage: 'si',
      );
      expect(
        siMix2.map((s) => '${s.languageCode}:${s.text}').toList(),
        ['si:අද', 'en:school', 'si:යන්න ඕනේ'],
      );

      final taMix = MultilingualSpeechRouter.route(
        'எனக்கு water வேண்டும்',
        preferredLanguage: 'ta',
      );
      expect(
        taMix.map((s) => '${s.languageCode}:${s.text}').toList(),
        ['ta:எனக்கு', 'en:water', 'ta:வேண்டும்'],
      );

      final enSi = MultilingualSpeechRouter.route(
        'Good morning, ආයුබෝවන්',
        preferredLanguage: 'en',
      );
      expect(
        enSi.map((s) => '${s.languageCode}:${s.text}').toList(),
        ['en:Good morning,', 'si:ආයුබෝවන්'],
      );
    });

    test('handles three-language sentences and unambiguous Romanized terms cleanly', () {
      final tri = MultilingualSpeechRouter.route(
        'Hello අම්මා வணக்கம்',
        preferredLanguage: 'en',
      );
      expect(
        tri.map((s) => '${s.languageCode}:${s.text}').toList(),
        ['en:Hello', 'si:අම්මා', 'ta:வணக்கம்'],
      );

      final romSi = MultilingualSpeechRouter.route(
        'ayubowan, good morning',
        preferredLanguage: 'en',
      );
      expect(
        romSi.map((s) => '${s.languageCode}:${s.text}').toList(),
        ['si:ආයුබෝවන්,', 'en:good morning'],
      );

      final romTa = MultilingualSpeechRouter.route(
        'vanakkam friend',
        preferredLanguage: 'ta',
      );
      expect(
        romTa.map((s) => '${s.languageCode}:${s.text}').toList(),
        ['ta:வணக்கம்', 'en:friend'],
      );
    });

    test('does not invent transliterations for ambiguous Latin words and expands numbers', () {
      final numbers = MultilingualSpeechRouter.route(
        '2 cups & 15% water',
        preferredLanguage: 'si',
      );
      expect(numbers.length, 1);
      expect(numbers.first.languageCode, 'en');
      expect(numbers.first.text, 'two cups and fifteen percent water');

      final hint = MultilingualSpeechRouter.route(
        '...',
        preferredLanguage: 'en',
        cardLanguageHint: 'si',
      );
      expect(hint.first.languageCode, 'si');
    });
  });
}
