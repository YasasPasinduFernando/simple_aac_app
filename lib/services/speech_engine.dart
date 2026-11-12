import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../utils/multilingual_speech_router.dart';

enum SpeechStatus {
  spoken,
  languageUnavailable,
  engineUnavailable,
  emptyText,
}

class LanguageVoiceStatus {
  const LanguageVoiceStatus({
    required this.languageCode,
    required this.localeTag,
    required this.isLanguageAvailable,
    required this.hasOfflineVoice,
  });

  final String languageCode;
  final String localeTag;
  final bool isLanguageAvailable;
  final bool hasOfflineVoice;
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
  final List<String> engines;

  List<String> get missingLanguages => languages.entries
      .where((e) => !e.value.hasOfflineVoice)
      .map((e) => e.key)
      .toList(growable: false);

  List<String> get unsupportedLanguages => languages.entries
      .where((e) => !e.value.isLanguageAvailable)
      .map((e) => e.key)
      .toList(growable: false);
}

class SpeechResult {
  const SpeechResult({
    required this.status,
    this.missingLanguages = const [],
    this.errorMessage,
  });

  final SpeechStatus status;
  final List<String> missingLanguages;
  final String? errorMessage;

  bool get isSuccess => status == SpeechStatus.spoken;
}

/// Unified multilingual SpeechEngine powered by Android/platform `flutter_tts`.
///
/// Restores the proven lightweight behavior of `release/play-v1.0.2` (`e6fc156`)
/// (`setSpeechRate(0.5)`, `pitch = 1.0`, direct `TextToSpeech.speak`) while adding
/// mixed-script routing (`en`, `si`, `ta`), locale/engine fallback, and non-blocking
/// capability diagnostics without rejecting valid system or online voices.
class SpeechEngine {
  SpeechEngine._({
    FlutterTts? tts,
    MethodChannel? channel,
  })  : _tts = tts ?? FlutterTts(),
        _channel = channel ?? const MethodChannel('aac_backup');

  @visibleForTesting
  factory SpeechEngine.forTest({
    FlutterTts? tts,
    MethodChannel? channel,
  }) {
    return SpeechEngine._(tts: tts, channel: channel);
  }

  static final SpeechEngine instance = SpeechEngine._();

  final FlutterTts _tts;
  final MethodChannel _channel;
  bool _initialized = false;
  String? _activeLanguageTag;
  Future<void>? _initFuture;
  Future<SpeechCapabilityReport?>? _probeFuture;
  SpeechCapabilityReport? _lastReport;
  int _speechEpoch = 0;

  SpeechCapabilityReport? get lastCapabilities => _lastReport;

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  static List<String> _localeCandidatesFor(String langCode) {
    return switch (langCode) {
      'si' => const ['si-LK', 'si'],
      'ta' => const ['ta-IN', 'ta-LK', 'ta'],
      _ => const ['en-US', 'en-GB', 'en-IN', 'en'],
    };
  }

  Future<void> initialize() {
    if (_initialized) return Future.value();
    if (_initFuture != null) return _initFuture!;
    final fut = _doInitialize();
    _initFuture = fut;
    fut.whenComplete(() {
      if (_initFuture == fut) _initFuture = null;
    });
    return fut;
  }

  Future<void> _doInitialize() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      _activeLanguageTag = 'en-US';
      _initialized = true;
    } catch (e) {
      debugPrint('[SpeechEngine] initialize failed: $e');
    }
  }

  /// Queries platform TTS capabilities for the UI status dialog without ever
  /// blocking playback of working voices.
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
      await initialize();
      final defaultEng = (await _tts.getDefaultEngine)?.toString();
      final rawEngines = await _tts.getEngines as List?;
      final engines = rawEngines == null
          ? const <String>[]
          : rawEngines.map((e) => e.toString()).toList(growable: false);

      final langs = <String, LanguageVoiceStatus>{};
      for (final entry in const {
        'en': 'en-US',
        'si': 'si-LK',
        'ta': 'ta-IN',
      }.entries) {
        final code = entry.key;
        final primaryTag = entry.value;
        var available = false;
        var offlineInstalled = false;

        for (final tag in _localeCandidatesFor(code)) {
          try {
            final avail = await _tts.isLanguageAvailable(tag);
            if (avail == true || avail == 1) {
              available = true;
              final inst = await _tts.isLanguageInstalled(tag);
              if (inst == true || inst == 1) {
                offlineInstalled = true;
              }
              break;
            }
          } catch (_) {}
        }

        langs[code] = LanguageVoiceStatus(
          languageCode: code,
          localeTag: primaryTag,
          isLanguageAvailable: available,
          hasOfflineVoice: offlineInstalled,
        );
      }

      final report = SpeechCapabilityReport(
        initialized: _initialized,
        defaultEngine: defaultEng,
        languages: langs,
        engines: engines,
      );
      _lastReport = report;
      return report;
    } catch (e) {
      debugPrint('[SpeechEngine] probeCapabilities skipped: $e');
      return null;
    }
  }

  /// Opens Android's built-in TTS voice data installer / TTS settings screen.
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
      await _tts.stop();
    } catch (_) {}
  }

  /// Speaks [rawText] via Android/platform TTS with automatic Unicode-script
  /// routing and locale/engine fallback.
  Future<SpeechResult> speak(
    String rawText, {
    required String preferredLanguage,
    String? cardLanguageHint,
    bool waitForCompletion = false,
  }) async {
    final segments = MultilingualSpeechRouter.route(
      rawText,
      preferredLanguage: preferredLanguage,
      cardLanguageHint: cardLanguageHint,
    );
    if (segments.isEmpty) {
      return const SpeechResult(status: SpeechStatus.emptyText);
    }

    final epoch = ++_speechEpoch;
    try {
      await _tts.stop();
    } catch (_) {}
    if (epoch != _speechEpoch) {
      return const SpeechResult(status: SpeechStatus.spoken);
    }

    await initialize();
    if (epoch != _speechEpoch) {
      return const SpeechResult(status: SpeechStatus.spoken);
    }

    final isMixed = segments.length > 1;
    try {
      await _tts.awaitSpeakCompletion(waitForCompletion || isMixed);
    } catch (_) {}

    final unsupported = <String>[];
    for (final seg in segments) {
      if (epoch != _speechEpoch) {
        return const SpeechResult(status: SpeechStatus.spoken);
      }
      final configured = await _configureLanguage(seg.languageCode);
      if (!configured) {
        unsupported.add(seg.languageCode);
      }
      if (epoch != _speechEpoch) {
        return const SpeechResult(status: SpeechStatus.spoken);
      }
      try {
        final speakRes = await _tts.speak(seg.text);
        // On Android `speak` returns 1 on queued/started success, 0 on error.
        if (speakRes == 0 && unsupported.contains(seg.languageCode)) {
          return SpeechResult(
            status: SpeechStatus.languageUnavailable,
            missingLanguages: unsupported,
          );
        }
      } catch (e) {
        debugPrint('[SpeechEngine] speak error (${seg.languageCode}): $e');
        return SpeechResult(
          status: SpeechStatus.engineUnavailable,
          missingLanguages: unsupported,
          errorMessage: e.toString(),
        );
      }
    }

    return const SpeechResult(status: SpeechStatus.spoken);
  }

  Future<bool> _configureLanguage(String langCode) async {
    final candidates = _localeCandidatesFor(langCode);
    if (_activeLanguageTag != null && candidates.contains(_activeLanguageTag)) {
      return true;
    }

    for (final tag in candidates) {
      try {
        final res = await _tts.setLanguage(tag);
        if (res == 1 || res == true) {
          _activeLanguageTag = tag;
          return true;
        }
      } catch (_) {}
    }

    // Fallback across any other installed Android TTS engines if current engine
    // does not carry a compatible locale.
    if (_isAndroid) {
      try {
        final rawEngines = await _tts.getEngines as List?;
        final current = (await _tts.getDefaultEngine)?.toString();
        if (rawEngines != null) {
          for (final eng in rawEngines) {
            final engName = eng.toString();
            if (engName.isEmpty || engName == current) continue;
            await _tts.setEngine(engName);
            await _tts.setSpeechRate(0.5);
            await _tts.setPitch(1.0);
            for (final tag in candidates) {
              final res = await _tts.setLanguage(tag);
              if (res == 1 || res == true) {
                _activeLanguageTag = tag;
                return true;
              }
            }
          }
        }
      } catch (_) {}
    }

    return false;
  }

  Future<void> dispose() async {
    await stop();
  }
}
