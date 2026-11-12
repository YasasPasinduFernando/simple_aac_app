import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/multilingual_speech_router.dart';

enum SpeechStatus {
  spoken,
  missingLanguageData,
  engineUnavailable,
  synthesisFailed,
  emptyAudio,
  playbackFailed,
}

class LanguageVoiceStatus {
  const LanguageVoiceStatus({
    required this.languageCode,
    required this.localeTag,
    required this.hasOfflineVoice,
    required this.availabilityCode,
    required this.offlineVoiceCount,
    required this.totalVoiceCount,
    this.voices = const [],
  });

  final String languageCode;
  final String localeTag;
  final bool hasOfflineVoice;
  final int availabilityCode;
  final int offlineVoiceCount;
  final int totalVoiceCount;
  final List<Map<String, dynamic>> voices;

  factory LanguageVoiceStatus.fromMap(String code, Map<dynamic, dynamic> raw) {
    final rawVoices = raw['voices'] as List?;
    final parsedVoices = rawVoices == null
        ? const <Map<String, dynamic>>[]
        : rawVoices
            .whereType<Map>()
            .map((v) => Map<String, dynamic>.from(v))
            .toList(growable: false);
    return LanguageVoiceStatus(
      languageCode: code,
      localeTag: raw['localeTag']?.toString() ?? '',
      hasOfflineVoice: raw['hasOfflineVoice'] == true,
      availabilityCode: (raw['availabilityCode'] as num?)?.toInt() ?? -2,
      offlineVoiceCount: (raw['offlineVoiceCount'] as num?)?.toInt() ?? 0,
      totalVoiceCount: (raw['voiceCount'] as num?)?.toInt() ?? 0,
      voices: parsedVoices,
    );
  }
}

class SpeechCapabilityReport {
  const SpeechCapabilityReport({
    required this.initialized,
    required this.defaultEngine,
    required this.languages,
    this.engines = const [],
  });

  final bool initialized;
  final String? defaultEngine;
  final Map<String, LanguageVoiceStatus> languages;
  final List<Map<String, String>> engines;

  bool hasOfflineFor(String langCode) {
    final norm = _normalizeCode(langCode);
    return languages[norm]?.hasOfflineVoice ?? false;
  }

  List<String> get missingLanguages => languages.entries
      .where((e) => !e.value.hasOfflineVoice)
      .map((e) => e.key)
      .toList(growable: false);

  static String _normalizeCode(String code) {
    final lower = code.trim().toLowerCase();
    if (lower.startsWith('si')) return 'si';
    if (lower.startsWith('ta')) return 'ta';
    return 'en';
  }
}

class SpeechResult {
  const SpeechResult({
    required this.status,
    this.missingLanguages = const [],
    this.errorMessage,
    this.durationMs = 0,
  });

  final SpeechStatus status;
  final List<String> missingLanguages;
  final String? errorMessage;
  final int durationMs;

  bool get isSuccess => status == SpeechStatus.spoken;
}

/// Optional neural segment synthesis hook plugged in only if Phase 4/5 proves
/// downloaded packs materially outperform the device's built-in TTS engine.
typedef OptionalNeuralSegmentSynth = Future<String?> Function(
  String text,
  String languageCode,
);

/// Unified multilingual SpeechEngine for Simple AAC.
///
/// Replaces multi-profile experimental voice synthesis with one automatic,
/// reliable speech pipeline featuring explicit offline capability checks,
/// Unicode-script routing, non-silent audio verification, and actionable errors.
class SpeechEngine {
  SpeechEngine._({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('aac_speech');

  @visibleForTesting
  factory SpeechEngine.forTest({required MethodChannel channel}) {
    return SpeechEngine._(channel: channel);
  }

  static final SpeechEngine instance = SpeechEngine._();
  static const int _maxCachedWavs = 100;

  final MethodChannel _channel;
  AudioPlayer? _player;
  FlutterTts? _fallbackTts;
  String? _cacheDirPath;
  Future<SpeechCapabilityReport?>? _probeFuture;
  SpeechCapabilityReport? _lastReport;
  int _speechEpoch = 0;

  OptionalNeuralSegmentSynth? optionalPackSynth;

  SpeechCapabilityReport? get lastCapabilities => _lastReport;

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  /// Probes installed Android TTS engines & offline language packs lazily.
  Future<SpeechCapabilityReport?> probeCapabilities({
    bool forceRefresh = false,
  }) {
    if (!forceRefresh && _lastReport != null) {
      return Future.value(_lastReport);
    }
    if (!forceRefresh && _probeFuture != null) {
      return _probeFuture!;
    }
    final fut = _runProbe();
    _probeFuture = fut;
    fut.whenComplete(() {
      if (_probeFuture == fut) _probeFuture = null;
    });
    return fut;
  }

  Future<SpeechCapabilityReport?> _runProbe() async {
    if (!_isAndroid) return null;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'probeCapabilities',
      );
      if (raw == null) return null;

      final rawLangs = (raw['languages'] as Map?) ?? const {};
      final langs = <String, LanguageVoiceStatus>{};
      for (final entry in rawLangs.entries) {
        final code = entry.key.toString();
        if (entry.value is Map) {
          langs[code] = LanguageVoiceStatus.fromMap(
            code,
            entry.value as Map,
          );
        }
      }

      final rawEngines = (raw['engines'] as List?) ?? const [];
      final engines = rawEngines
          .whereType<Map>()
          .map(
            (e) => {
              'name': e['name']?.toString() ?? '',
              'label': e['label']?.toString() ?? '',
            },
          )
          .toList(growable: false);

      final report = SpeechCapabilityReport(
        initialized: raw['initialized'] == true,
        defaultEngine: raw['defaultEngine']?.toString(),
        languages: langs,
        engines: engines,
      );
      _lastReport = report;
      return report;
    } catch (e) {
      debugPrint('[SpeechEngine] probeCapabilities error: $e');
      return null;
    }
  }

  /// Opens Android's built-in TTS voice data installer / settings activity.
  Future<bool> openSystemTtsInstaller() async {
    if (!_isAndroid) return false;
    try {
      return (await _channel.invokeMethod<bool>('openTtsInstaller')) ?? false;
    } catch (e) {
      debugPrint('[SpeechEngine] openSystemTtsInstaller error: $e');
      return false;
    }
  }

  Future<void> stop() async {
    _speechEpoch++;
    try {
      await _player?.stop();
    } catch (_) {}
    try {
      await _fallbackTts?.stop();
    } catch (_) {}
  }

  /// Speaks [rawText] with automatic multilingual routing and non-silent checks.
  Future<SpeechResult> speak(
    String rawText, {
    required String preferredLanguage,
    String? cardLanguageHint,
    bool waitForCompletion = false,
    double speechRate = 0.96,
  }) async {
    final segments = MultilingualSpeechRouter.route(
      rawText,
      preferredLanguage: preferredLanguage,
      cardLanguageHint: cardLanguageHint,
    );
    if (segments.isEmpty) {
      return const SpeechResult(status: SpeechStatus.emptyAudio);
    }

    final epoch = ++_speechEpoch;
    try {
      await _player?.stop();
      await _fallbackTts?.stop();
    } catch (_) {}

    if (epoch != _speechEpoch) {
      return const SpeechResult(status: SpeechStatus.spoken);
    }

    if (_isAndroid) {
      final wavRes = await _synthesizeAndPlayAndroid(
        segments,
        speechRate: speechRate,
        epoch: epoch,
        waitForCompletion: waitForCompletion,
      );
      if (wavRes != null) {
        return wavRes;
      }
    }

    // Non-Android / fallback test VM path via FlutterTts.
    try {
      final tts = _fallbackTts ??= FlutterTts();
      for (final seg in segments) {
        if (epoch != _speechEpoch) break;
        await tts.setLanguage(_localeTag(seg.languageCode));
        await tts.setPitch(1.0);
        await tts.setSpeechRate(0.48);
        await tts.setVolume(1.0);
        await tts.awaitSpeakCompletion(waitForCompletion || segments.length > 1);
        await tts.speak(seg.text);
      }
      return const SpeechResult(status: SpeechStatus.spoken);
    } catch (e) {
      debugPrint('[SpeechEngine] FlutterTts fallback failed: $e');
      return SpeechResult(
        status: SpeechStatus.engineUnavailable,
        errorMessage: e.toString(),
      );
    }
  }

  Future<SpeechResult?> _synthesizeAndPlayAndroid(
    List<SpeechRouteSegment> segments, {
    required double speechRate,
    required int epoch,
    required bool waitForCompletion,
  }) async {
    try {
      final cacheDir = await _getCacheDir();
      if (cacheDir == null) return null;

      final key = _cacheKey(segments, speechRate);
      final outPath = '$cacheDir/$key.wav';
      final outFile = File(outPath);
      var durationMs = 0;

      if (!await outFile.exists() || await outFile.length() <= 44) {
        final rawRes = await _channel.invokeMapMethod<String, dynamic>(
          'synthesizeSegments',
          {
            'segments': segments.map((s) => s.toMap()).toList(growable: false),
            'outputPath': outPath,
            'speechRate': speechRate,
            'allowNetworkVoice': false,
          },
        );
        if (rawRes == null) {
          return const SpeechResult(status: SpeechStatus.synthesisFailed);
        }
        final ok = rawRes['ok'] == true;
        if (!ok) {
          final st = rawRes['status']?.toString() ?? 'synthesis_failed';
          final missing = (rawRes['missingLanguages'] as List?)
                  ?.map((e) => e.toString())
                  .toList(growable: false) ??
              const <String>[];
          return SpeechResult(
            status: _parseStatus(st),
            missingLanguages: missing,
            errorMessage: rawRes['failedSegmentLang']?.toString(),
          );
        }
        durationMs = (rawRes['durationMs'] as num?)?.toInt() ?? 0;
        unawaited(_pruneCacheDir(cacheDir));
      }

      if (epoch != _speechEpoch) {
        return const SpeechResult(status: SpeechStatus.spoken);
      }

      if (!await outFile.exists() || await outFile.length() <= 44) {
        return const SpeechResult(status: SpeechStatus.emptyAudio);
      }

      final player = _player ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      final doneFuture = waitForCompletion
          ? player.onPlayerComplete.first.timeout(const Duration(seconds: 25))
          : null;
      await player.play(DeviceFileSource(outPath));
      if (doneFuture != null) {
        await doneFuture.catchError((_) {});
      }
      return SpeechResult(
        status: SpeechStatus.spoken,
        durationMs: durationMs,
      );
    } on MissingPluginException {
      return null;
    } catch (e) {
      debugPrint('[SpeechEngine] Android synthesis/play error: $e');
      return SpeechResult(
        status: SpeechStatus.playbackFailed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Synthesizes test phrases silently into `cache/aac_speech_probe/` for
  /// real-device offline verification without disturbing playback UX.
  Future<Map<String, dynamic>> runDeviceDiagnosticProbe() async {
    if (!_isAndroid) return const {'supported': false};
    final report = await probeCapabilities(forceRefresh: true);
    final tmp = await getTemporaryDirectory();
    final probeDir = Directory('${tmp.path}/aac_speech_probe');
    await probeDir.create(recursive: true);

    const probes = <Map<String, String>>[
      {'slug': 'en_hello', 'lang': 'en', 'text': 'Hello'},
      {'slug': 'si_water', 'lang': 'si', 'text': 'මට වතුර ඕනේ'},
      {'slug': 'si_mix_water', 'lang': 'si', 'text': 'මට water එකක් දෙන්න'},
      {'slug': 'si_mix_school', 'lang': 'si', 'text': 'අද school යන්න ඕනේ'},
      {'slug': 'ta_vanakkam', 'lang': 'ta', 'text': 'வணக்கம்'},
      {'slug': 'ta_mix_water', 'lang': 'ta', 'text': 'எனக்கு water வேண்டும்'},
      {'slug': 'en_si_mix', 'lang': 'si', 'text': 'Good morning, ආයුබෝවන්'},
      {'slug': 'si_sellam', 'lang': 'si', 'text': 'සෙල්ලම්'},
      {'slug': 'si_twath', 'lang': 'si', 'text': 'තවත්'},
      {'slug': 'si_hondai', 'lang': 'si', 'text': 'හොඳයි'},
    ];

    final results = <String, dynamic>{};
    for (final p in probes) {
      final segs = MultilingualSpeechRouter.route(
        p['text']!,
        preferredLanguage: p['lang']!,
      );
      final outPath = '${probeDir.path}/${p['slug']}.wav';
      try {
        final res = await _channel.invokeMapMethod<String, dynamic>(
          'synthesizeSegments',
          {
            'segments': segs.map((s) => s.toMap()).toList(growable: false),
            'outputPath': outPath,
            'speechRate': 0.96,
            'allowNetworkVoice': false,
          },
        );
        results[p['slug']!] = res;
      } catch (e) {
        results[p['slug']!] = {'ok': false, 'error': e.toString()};
      }
    }

    return {
      'defaultEngine': report?.defaultEngine,
      'engines': report?.engines,
      'missingLanguages': report?.missingLanguages,
      'languages': report?.languages.map(
        (k, v) => MapEntry(k, {
          'availabilityCode': v.availabilityCode,
          'hasOfflineVoice': v.hasOfflineVoice,
          'offlineVoiceCount': v.offlineVoiceCount,
          'totalVoiceCount': v.totalVoiceCount,
          'voices': v.voices.take(8).toList(),
        }),
      ),
      'probes': results,
    };
  }

  static SpeechStatus _parseStatus(String raw) {
    return switch (raw) {
      'missing_language_data' => SpeechStatus.missingLanguageData,
      'engine_unavailable' => SpeechStatus.engineUnavailable,
      'empty_audio' => SpeechStatus.emptyAudio,
      'playback_failed' => SpeechStatus.playbackFailed,
      _ => SpeechStatus.synthesisFailed,
    };
  }

  static String _localeTag(String lang) {
    return switch (lang) {
      'si' => 'si-LK',
      'ta' => 'ta-IN',
      _ => 'en-US',
    };
  }

  Future<String?> _getCacheDir() async {
    if (_cacheDirPath != null) return _cacheDirPath;
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}/aac_speech_cache_v1');
      await dir.create(recursive: true);
      _cacheDirPath = dir.path;
      return _cacheDirPath;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pruneCacheDir(String cachePath) async {
    try {
      final dir = Directory(cachePath);
      if (!await dir.exists()) return;
      final files = await dir
          .list()
          .where((e) => e is File && e.path.endsWith('.wav'))
          .cast<File>()
          .toList();
      if (files.length <= _maxCachedWavs) return;
      final stats = <MapEntry<File, DateTime>>[];
      for (final f in files) {
        stats.add(MapEntry(f, (await f.stat()).modified));
      }
      stats.sort((a, b) => a.value.compareTo(b.value));
      final excess = stats.length - _maxCachedWavs;
      for (var i = 0; i < excess; i++) {
        await stats[i].key.delete().catchError((_) => stats[i].key);
      }
    } catch (_) {}
  }

  static String _cacheKey(List<SpeechRouteSegment> segs, double rate) {
    final joined = segs.map((s) => '${s.languageCode}:${s.text}').join('|');
    final raw = 'sp1|${rate.toStringAsFixed(2)}|$joined';
    var h1 = 0x811c9dc5;
    var h2 = 0x01000193;
    for (final u in raw.codeUnits) {
      h1 = ((h1 ^ u) * 0x01000193) & 0x7fffffff;
      h2 = ((h2 + u) * 0x45d9f3b) & 0x7fffffff;
    }
    return '${h1.toRadixString(16).padLeft(8, '0')}${h2.toRadixString(16).padLeft(8, '0')}';
  }

  Future<void> dispose() async {
    await stop();
    await _player?.dispose();
    _player = null;
  }
}
