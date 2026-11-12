import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsVoiceProfile {
  woman,
  man,
  boy,
  girl,
}

class TtsVoiceConfig {
  final Map<String, String>? voiceMap;
  final bool matchedMaleVoice;
  final double pitch;
  final double speechRate;

  const TtsVoiceConfig({
    this.voiceMap,
    required this.matchedMaleVoice,
    required this.pitch,
    required this.speechRate,
  });
}

/// Manages R&D-tuned natural TTS voice selection across Woman, Man, Boy Child,
/// and Girl Child while keeping speech offline-safe and free of robotic artifacts.
class TtsVoiceHelper {
  static const String prefKey = 'ttsVoiceProfile';

  static const Set<String> _maleTags = {
    '-tpd-',
    '-iom-',
    '-iob-',
    '-gbd-',
    '-gbb-',
    '-rjm-',
    '-tag-',
    '_m',
    'smtm',
    '#male',
    '-male',
    'male',
    'david',
    'daniel',
    'arthur',
    'george',
    'james',
    'rishi',
    'aaron',
  };

  static const Set<String> _femaleTags = {
    '-sfg-',
    '-tpf-',
    '-tpc-',
    '-iol-',
    '-iof-',
    '-gba-',
    '-gbc-',
    '-taf-',
    '-sin-',
    '_f',
    'smtf',
    '#female',
    '-female',
    'female',
    'samantha',
    'karen',
    'serena',
    'victoria',
    'lekha',
    'veena',
  };

  static TtsVoiceProfile fromStorage(String? raw) {
    for (final profile in TtsVoiceProfile.values) {
      if (profile.name == raw) return profile;
    }
    return TtsVoiceProfile.woman;
  }

  static String labelFor(TtsVoiceProfile profile) {
    switch (profile) {
      case TtsVoiceProfile.woman:
        return 'Woman';
      case TtsVoiceProfile.man:
        return 'Man';
      case TtsVoiceProfile.boy:
        return 'Child (Boy)';
      case TtsVoiceProfile.girl:
        return 'Child (Girl)';
    }
  }

  static String subtitleFor(TtsVoiceProfile profile) {
    switch (profile) {
      case TtsVoiceProfile.woman:
        return 'Warm natural adult female voice';
      case TtsVoiceProfile.man:
        return 'Calm natural adult male voice';
      case TtsVoiceProfile.boy:
        return 'Bright cheerful boy child voice';
      case TtsVoiceProfile.girl:
        return 'Sweet gentle girl child voice';
    }
  }

  static IconData iconFor(TtsVoiceProfile profile) {
    switch (profile) {
      case TtsVoiceProfile.woman:
        return Icons.woman_rounded;
      case TtsVoiceProfile.man:
        return Icons.man_rounded;
      case TtsVoiceProfile.boy:
        return Icons.boy_rounded;
      case TtsVoiceProfile.girl:
        return Icons.girl_rounded;
    }
  }

  static String localeTagFor(String languageCode) {
    switch (languageCode) {
      case 'si':
        return 'si-LK';
      case 'ta':
        return 'ta-IN';
      default:
        return 'en-US';
    }
  }

  static String sampleGreeting(String languageCode, TtsVoiceProfile profile) {
    switch (languageCode) {
      case 'si':
        return 'ආයුබෝවන්';
      case 'ta':
        return 'வணக்கம்';
      default:
        return 'Hello, ${labelFor(profile)} voice ready';
    }
  }

  /// Prefers Google's offline neural Speech Services engine on Android when available
  /// instead of legacy/Samsung robotic engines.
  static Future<void> preferBestEngine(FlutterTts tts) async {
    if (!Platform.isAndroid) return;
    try {
      const googleEngine = 'com.google.android.tts';
      final defaultEngine = await tts.getDefaultEngine;
      if (defaultEngine?.toString() == googleEngine) return;
      final engines = await tts.getEngines;
      if (engines is List && engines.any((e) => e.toString() == googleEngine)) {
        await tts.setEngine(googleEngine);
        // FlutterTtsPlugin.setEngine initializes TextToSpeech asynchronously.
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    } catch (e) {
      debugPrint('[TtsVoiceHelper] Engine preference check skipped: $e');
    }
  }

  static bool _hasAnyTag(String lowerName, Set<String> tags) {
    for (final tag in tags) {
      if (lowerName.contains(tag)) return true;
    }
    return false;
  }

  static bool _isNetworkVoice(String lowerName) =>
      lowerName.contains('-network') || lowerName.endsWith('network');

  static int _localePriority(String lowerLocale, String lang) {
    if (lang == 'en') {
      if (lowerLocale == 'en-us') return 3;
      if (lowerLocale == 'en-gb') return 2;
    } else if (lang == 'si' && lowerLocale == 'si-lk') {
      return 3;
    } else if (lang == 'ta' && (lowerLocale == 'ta-in' || lowerLocale == 'ta-lk')) {
      return 3;
    }
    return 1;
  }

  /// Selects an installed offline voice and formant-safe pitch/rate tuned to
  /// avoid buzzy Android pitch-shifter distortion.
  static TtsVoiceConfig resolveConfig({
    required TtsVoiceProfile profile,
    required String languageCode,
    List<dynamic>? availableVoices,
  }) {
    final lang = languageCode.trim().toLowerCase().split('-').first;
    final wantsMale =
        profile == TtsVoiceProfile.man || profile == TtsVoiceProfile.boy;

    final candidates = <Map<String, String>>[];
    if (availableVoices != null) {
      for (final raw in availableVoices) {
        if (raw is! Map) continue;
        final name = raw['name']?.toString() ?? '';
        final locale = raw['locale']?.toString() ?? '';
        if (name.isEmpty || locale.isEmpty) continue;
        if (locale.toLowerCase().startsWith(lang)) {
          candidates.add({'name': name, 'locale': locale});
        }
      }
    }

    // Never pick cloud-only -network voices when local offline voices are present.
    final localOnly = candidates
        .where((v) => !_isNetworkVoice(v['name']!.toLowerCase()))
        .toList();
    final pool = localOnly.isNotEmpty ? localOnly : candidates;

    Map<String, String>? chosen;
    var bestScore = -1000;
    for (final voice in pool) {
      final lowerName = voice['name']!.toLowerCase();
      final lowerLocale = voice['locale']!.toLowerCase();
      final isMale = _hasAnyTag(lowerName, _maleTags) &&
          !_hasAnyTag(lowerName, {'female', '-female'});
      final isFemale = _hasAnyTag(lowerName, _femaleTags);

      var score = _localePriority(lowerLocale, lang) * 10;
      if (lowerName.contains('-local')) score += 6;
      if (wantsMale) {
        if (isMale) score += 50;
        if (isFemale) score -= 15;
      } else {
        if (isFemale) score += 40;
        if (isMale) score -= 25;
      }

      if (score > bestScore) {
        bestScore = score;
        chosen = voice;
      }
    }

    final matchedMale = chosen != null &&
        _hasAnyTag(chosen['name']!.toLowerCase(), _maleTags) &&
        !_hasAnyTag(chosen['name']!.toLowerCase(), {'female', '-female'});

    // Mild formant-safe pitches (0.80..1.28) sound human; extreme pitches (<0.75 or >1.4) create metallic robot buzz.
    final double pitch;
    final double rate;
    switch (profile) {
      case TtsVoiceProfile.woman:
        pitch = matchedMale ? 1.18 : 1.02;
        rate = 0.46;
        break;
      case TtsVoiceProfile.man:
        pitch = matchedMale ? 0.96 : 0.80;
        rate = 0.45;
        break;
      case TtsVoiceProfile.boy:
        pitch = matchedMale ? 1.20 : 1.15;
        rate = 0.48;
        break;
      case TtsVoiceProfile.girl:
        pitch = matchedMale ? 1.28 : 1.24;
        rate = 0.48;
        break;
    }

    return TtsVoiceConfig(
      voiceMap: chosen,
      matchedMaleVoice: matchedMale,
      pitch: pitch,
      speechRate: rate,
    );
  }

  /// Applies language, matching installed voice, pitch, and natural cadence.
  /// Always calls setLanguage BEFORE setVoice because Android resets voice on setLanguage.
  static Future<List<dynamic>?> applyProfile(
    FlutterTts tts, {
    required String languageCode,
    required TtsVoiceProfile profile,
    List<dynamic>? cachedVoices,
  }) async {
    final targetLocale = localeTagFor(languageCode);
    await tts.setLanguage(targetLocale);

    var voices = cachedVoices;
    if (voices == null || voices.isEmpty) {
      try {
        final raw = await tts.getVoices;
        if (raw is List) voices = raw;
      } catch (_) {}
    }

    final config = resolveConfig(
      profile: profile,
      languageCode: languageCode,
      availableVoices: voices,
    );

    if (config.voiceMap != null) {
      try {
        await tts.setVoice(config.voiceMap!);
      } catch (e) {
        debugPrint('[TtsVoiceHelper] setVoice skipped: $e');
      }
    }
    await tts.setPitch(config.pitch);
    await tts.setSpeechRate(config.speechRate);
    await tts.setVolume(1.0);
    return voices;
  }
}

class TtsAcousticSpec {
  const TtsAcousticSpec({
    required this.languageCode,
    required this.modelKey,
    required this.localeTag,
    required this.speakerId,
    required this.targetF0Hz,
    required this.formantSemitones,
    required this.fallbackTargetF0Hz,
    required this.fallbackFormantSemitones,
    required this.speed,
  });

  final String languageCode;
  final String modelKey;
  final String localeTag;
  final int speakerId;
  final double targetF0Hz;
  final double formantSemitones;
  final double fallbackTargetF0Hz;
  final double fallbackFormantSemitones;
  final double speed;
}

extension TtsVoiceProfileAcoustic on TtsVoiceProfile {
  /// Resolves clean neural VITS model pack + WORLD vocal-tract parameters so
  /// Woman, Man, Child (Boy), and Child (Girl) each have distinct, natural speech.
  TtsAcousticSpec acousticSpecFor(String rawLanguageCode) {
    final lower = rawLanguageCode.toLowerCase();
    final lang = lower.startsWith('si')
        ? 'si'
        : (lower.startsWith('ta') ? 'ta' : 'en');
    final localeTag = switch (lang) {
      'si' => 'si-LK',
      'ta' => 'ta-IN',
      _ => 'en-US',
    };

    switch (this) {
      case TtsVoiceProfile.woman:
        return TtsAcousticSpec(
          languageCode: lang,
          modelKey: lang,
          localeTag: localeTag,
          speakerId: lang == 'en' ? 60 : 0,
          targetF0Hz: lang == 'en' ? 216.0 : 212.0,
          formantSemitones: -0.53,
          fallbackTargetF0Hz: 214.0,
          fallbackFormantSemitones: -0.53,
          speed: lang == 'en' ? 0.96 : 0.98,
        );
      case TtsVoiceProfile.man:
        // Use native crisp human male voices for en (LibriTTS sid=749) & ta (Valluvar),
        // and clean chan4lk + non-linear WORLD male vocoder for si (accurate Sinhala G2P).
        final hasNativeMale = lang != 'si';
        return TtsAcousticSpec(
          languageCode: lang,
          modelKey: lang == 'ta' ? 'ta_m' : lang,
          localeTag: localeTag,
          speakerId: lang == 'en' ? 749 : 0,
          targetF0Hz: hasNativeMale ? 0.0 : 122.0,
          formantSemitones: hasNativeMale ? 0.0 : -3.30,
          fallbackTargetF0Hz: 122.0,
          fallbackFormantSemitones: -3.40,
          speed: 0.96,
        );
      case TtsVoiceProfile.boy:
        // Child Boy: pre-adolescent F0 (~252-258 Hz) + youth formant shift.
        final fromMale = lang != 'si';
        return TtsAcousticSpec(
          languageCode: lang,
          modelKey: lang == 'ta' ? 'ta_m' : lang,
          localeTag: localeTag,
          speakerId: lang == 'en' ? 749 : 0,
          targetF0Hz: fromMale ? 252.0 : 258.0,
          formantSemitones: fromMale ? 3.65 : 2.15,
          fallbackTargetF0Hz: 252.0,
          fallbackFormantSemitones: 3.65,
          speed: 1.04,
        );
      case TtsVoiceProfile.girl:
        return TtsAcousticSpec(
          languageCode: lang,
          modelKey: lang,
          localeTag: localeTag,
          speakerId: lang == 'en' ? 60 : 0,
          // Pre-adolescent Girl vocal tract from clean Female base.
          targetF0Hz: 340.0,
          formantSemitones: 4.27,
          fallbackTargetF0Hz: 340.0,
          fallbackFormantSemitones: 4.27,
          speed: 1.05,
        );
    }
  }
}
