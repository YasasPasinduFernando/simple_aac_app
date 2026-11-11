import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_aac_app/utils/tts_voice_helper.dart';

void main() {
  group('TtsVoiceHelper.fromStorage', () {
    test('defaults to woman for null or unknown values', () {
      expect(TtsVoiceHelper.fromStorage(null), TtsVoiceProfile.woman);
      expect(TtsVoiceHelper.fromStorage(''), TtsVoiceProfile.woman);
      expect(TtsVoiceHelper.fromStorage('robot'), TtsVoiceProfile.woman);
    });

    test('round-trips all stored enum names', () {
      for (final profile in TtsVoiceProfile.values) {
        expect(TtsVoiceHelper.fromStorage(profile.name), profile);
      }
    });
  });

  group('TtsVoiceHelper metadata', () {
    test('provides distinct labels, icons, subtitles, and greetings', () {
      final labels = <String>{};
      for (final profile in TtsVoiceProfile.values) {
        final label = TtsVoiceHelper.labelFor(profile);
        expect(label, isNotEmpty);
        labels.add(label);
        expect(TtsVoiceHelper.subtitleFor(profile), isNotEmpty);
        expect(TtsVoiceHelper.iconFor(profile), isA<IconData>());
        expect(TtsVoiceHelper.sampleGreeting('en', profile), isNotEmpty);
        expect(TtsVoiceHelper.sampleGreeting('si', profile), isNotEmpty);
        expect(TtsVoiceHelper.sampleGreeting('ta', profile), isNotEmpty);
      }
      expect(labels.length, TtsVoiceProfile.values.length);
    });
  });

  group('TtsVoiceHelper.resolveConfig', () {
    const enVoices = <Map<String, String>>[
      {'name': 'en-us-x-sfg-network', 'locale': 'en-US'},
      {'name': 'en-us-x-sfg-local', 'locale': 'en-US'},
      {'name': 'en-us-x-tpd-network', 'locale': 'en-US'},
      {'name': 'en-us-x-tpd-local', 'locale': 'en-US'},
    ];

    test('prioritizes offline -local voices over -network voices', () {
      final woman = TtsVoiceHelper.resolveConfig(
        profile: TtsVoiceProfile.woman,
        languageCode: 'en',
        availableVoices: enVoices,
      );
      final man = TtsVoiceHelper.resolveConfig(
        profile: TtsVoiceProfile.man,
        languageCode: 'en',
        availableVoices: enVoices,
      );

      expect(woman.voiceMap?['name'], 'en-us-x-sfg-local');
      expect(woman.matchedMaleVoice, isFalse);
      expect(man.voiceMap?['name'], 'en-us-x-tpd-local');
      expect(man.matchedMaleVoice, isTrue);
    });

    test('matches male voice for boy and female voice for girl', () {
      final boy = TtsVoiceHelper.resolveConfig(
        profile: TtsVoiceProfile.boy,
        languageCode: 'en',
        availableVoices: enVoices,
      );
      final girl = TtsVoiceHelper.resolveConfig(
        profile: TtsVoiceProfile.girl,
        languageCode: 'en',
        availableVoices: enVoices,
      );
      final man = TtsVoiceHelper.resolveConfig(
        profile: TtsVoiceProfile.man,
        languageCode: 'en',
        availableVoices: enVoices,
      );
      final woman = TtsVoiceHelper.resolveConfig(
        profile: TtsVoiceProfile.woman,
        languageCode: 'en',
        availableVoices: enVoices,
      );

      expect(boy.voiceMap?['name'], 'en-us-x-tpd-local');
      expect(boy.matchedMaleVoice, isTrue);
      expect(girl.voiceMap?['name'], 'en-us-x-sfg-local');
      expect(girl.matchedMaleVoice, isFalse);

      expect(boy.pitch, greaterThan(man.pitch));
      expect(girl.pitch, greaterThan(woman.pitch));
    });

    test('keeps pitch & rate natural on single-voice si-LK fallback', () {
      const siVoices = <Map<String, String>>[
        {'name': 'si-lk-x-sin-local', 'locale': 'si-LK'},
      ];

      final woman = TtsVoiceHelper.resolveConfig(
        profile: TtsVoiceProfile.woman,
        languageCode: 'si',
        availableVoices: siVoices,
      );
      final man = TtsVoiceHelper.resolveConfig(
        profile: TtsVoiceProfile.man,
        languageCode: 'si',
        availableVoices: siVoices,
      );
      final boy = TtsVoiceHelper.resolveConfig(
        profile: TtsVoiceProfile.boy,
        languageCode: 'si',
        availableVoices: siVoices,
      );
      final girl = TtsVoiceHelper.resolveConfig(
        profile: TtsVoiceProfile.girl,
        languageCode: 'si',
        availableVoices: siVoices,
      );

      for (final cfg in [woman, man, boy, girl]) {
        expect(cfg.voiceMap?['name'], 'si-lk-x-sin-local');
        expect(cfg.pitch, inInclusiveRange(0.78, 1.32));
        expect(cfg.speechRate, inInclusiveRange(0.42, 0.50));
      }

      expect(man.pitch, lessThan(woman.pitch));
      expect(boy.pitch, greaterThan(woman.pitch));
      expect(girl.pitch, greaterThan(woman.pitch));
    });
  });
}
