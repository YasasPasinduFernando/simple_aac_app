import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:audioplayers/audioplayers.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import '../utils/tts_phonemizer.dart';
import '../utils/tts_voice_helper.dart';

typedef _ProcessPcmNative = Int32 Function(
  Pointer<Float> samples,
  Int32 numSamples,
  Int32 sampleRate,
  Pointer<Utf8> outWavPath,
  Float targetF0Hz,
  Float formantSemitones,
);
typedef _ProcessPcmDart = int Function(
  Pointer<Float> samples,
  int numSamples,
  int sampleRate,
  Pointer<Utf8> outWavPath,
  double targetF0Hz,
  double formantSemitones,
);

/// Offline neural VITS + Signalsmith formant-DSP voice engine.
///
/// Synthesizes clean, zero-whisper speech on a background isolate using bundled
/// INT8 Piper VITS models (`en`, `si`, `ta`), reshapes vocal-tract formants and
/// pitch cleanly via C++ Signalsmith Stretch, caches WAV files for instant replay,
/// and seamlessly falls back to neutral Android TTS + C++ DSP if needed.
class NeuralTtsService {
  NeuralTtsService._();
  static final NeuralTtsService instance = NeuralTtsService._();

  static const MethodChannel _voiceChannel = MethodChannel('aac_voice');
  static const int _maxCachedWavs = 80;

  AudioPlayer? _player;
  final Map<String, Future<String?>> _extractFutures = {};

  SendPort? _workerSendPort;
  ReceivePort? _workerReceivePort;
  Future<SendPort?>? _workerBootFuture;
  int _nextReqId = 1;
  final Map<int, Completer<bool>> _pendingWorkerReqs = {};

  int _speechEpoch = 0;
  FlutterTts? _emergencyTts;
  String? _cacheDirPath;

  static bool get _supportsNativeNeural =>
      !kIsWeb && (Platform.isAndroid || Platform.isLinux);

  /// Extracts and warms up the active language model asynchronously after first paint.
  Future<void> warmUp(String languageCode) async {
    if (!_supportsNativeNeural) return;
    final lang = _normalizeLang(languageCode);
    try {
      final modelDir = await _ensureLanguageExtracted(lang);
      if (modelDir == null) return;
      final port = await _ensureWorker();
      if (port == null) return;
      await _sendWorkerRequest(port, {
        'cmd': 'warmup',
        'lang': lang,
        'modelDir': modelDir,
      });
    } catch (e) {
      debugPrint('[NeuralTts] warmUp($lang) skipped: $e');
    }
  }

  Future<void> stop() async {
    _speechEpoch++;
    try {
      await _player?.stop();
    } catch (_) {}
    try {
      await _emergencyTts?.stop();
    } catch (_) {}
  }

  /// Speaks [rawText] with unmistakable [profile] differentiation and zero whisper artifacts.
  ///
  /// When [waitForCompletion] is `false` (default for card taps), any previous
  /// speech is immediately interrupted and playback starts asynchronously. When
  /// [waitForCompletion] is `true` (for sentence bar word sequences), this awaits
  /// natural audio completion unless interrupted by another tap or [stop].
  Future<void> speak(
    String rawText, {
    required String languageCode,
    required TtsVoiceProfile profile,
    bool waitForCompletion = false,
  }) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

    final epoch = ++_speechEpoch;
    try {
      await _player?.stop();
      await _emergencyTts?.stop();
    } catch (_) {}

    if (epoch != _speechEpoch) return;

    final preferred = _normalizeLang(languageCode);
    final segments = TtsPhonemizer.splitByScript(
      text,
      preferredLanguage: preferred,
    );
    if (segments.isEmpty) return;

    for (final segment in segments) {
      if (epoch != _speechEpoch) return;
      final wavPath = await _resolveSegmentWav(
        segment.text,
        languageCode: segment.languageCode,
        profile: profile,
      );
      if (epoch != _speechEpoch) return;

      if (wavPath != null) {
        final ok = await _playWavFile(
          wavPath,
          epoch: epoch,
          waitForCompletion: waitForCompletion || segments.length > 1,
        );
        if (ok) continue;
      }

      if (epoch != _speechEpoch) return;
      await _speakEmergencyFlutterTts(
        segment.text,
        languageCode: segment.languageCode,
      );
    }
  }

  Future<String?> _resolveSegmentWav(
    String text, {
    required String languageCode,
    required TtsVoiceProfile profile,
  }) async {
    final spec = profile.acousticSpecFor(languageCode);
    final normalizedText = spec.languageCode == 'en'
        ? TtsPhonemizer.normalizeEnglishText(text)
        : text.trim();
    if (normalizedText.isEmpty) return null;

    final cacheDir = await _getCacheDir();
    if (cacheDir == null) return null;

    final key = _cacheKey(spec, normalizedText);
    final outPath = '$cacheDir/$key.wav';
    final outFile = File(outPath);
    if (await outFile.exists() && await outFile.length() > 44) {
      return outPath;
    }

    // Tier 1: Bundled offline neural VITS + C++ Signalsmith Stretch DSP.
    if (_supportsNativeNeural) {
      final modelDir = await _ensureLanguageExtracted(spec.languageCode);
      if (modelDir != null) {
        final port = await _ensureWorker();
        if (port != null) {
          List<List<int>>? codepoints;
          if (spec.languageCode != 'en') {
            final cps = TtsPhonemizer.phonemizeToCodepoints(
              normalizedText,
              spec.languageCode,
            );
            if (cps.isNotEmpty) {
              codepoints = [cps];
            }
          }
          if (spec.languageCode == 'en' || codepoints != null) {
            final ok = await _sendWorkerRequest(port, {
              'cmd': 'synth',
              'lang': spec.languageCode,
              'modelDir': modelDir,
              'text': spec.languageCode == 'en' ? normalizedText : '',
              'codepoints': codepoints,
              'sid': spec.speakerId,
              'speed': spec.speed,
              'targetF0': spec.targetF0Hz,
              'formantSt': spec.formantSemitones,
              'outPath': outPath,
            });
            if (ok && await outFile.exists() && await outFile.length() > 44) {
              unawaited(_pruneCacheDir(cacheDir));
              return outPath;
            }
          }
        }
      }
    }

    // Tier 2: Clean neutral Android TextToSpeech.synthesizeToFile + C++ Signalsmith DSP.
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final ok = await _voiceChannel.invokeMethod<bool>(
          'synthesizeFallbackWav',
          {
            'text': normalizedText,
            'localeTag': spec.localeTag,
            'outputPath': outPath,
            'targetF0Hz': spec.fallbackTargetF0Hz,
            'formantSemitones': spec.fallbackFormantSemitones,
            'speechRate': spec.speed,
          },
        );
        if (ok == true && await outFile.exists() && await outFile.length() > 44) {
          unawaited(_pruneCacheDir(cacheDir));
          return outPath;
        }
      } catch (e) {
        debugPrint('[NeuralTts] Android DSP fallback failed: $e');
      }
    }

    return null;
  }

  Future<bool> _playWavFile(
    String path, {
    required int epoch,
    required bool waitForCompletion,
  }) async {
    try {
      if (epoch != _speechEpoch) return true;
      final player = _player ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      final doneFuture = waitForCompletion
          ? player.onPlayerComplete.first.timeout(const Duration(seconds: 25))
          : null;
      await player.play(DeviceFileSource(path));
      if (doneFuture != null) {
        await doneFuture.catchError((_) {});
      }
      return true;
    } catch (e) {
      debugPrint('[NeuralTts] WAV playback error: $e');
      return false;
    }
  }

  Future<void> _speakEmergencyFlutterTts(
    String text, {
    required String languageCode,
  }) async {
    try {
      final tts = _emergencyTts ??= FlutterTts();
      await tts.setLanguage(TtsVoiceHelper.localeTagFor(languageCode));
      await tts.setPitch(1.0);
      await tts.setSpeechRate(0.46);
      await tts.setVolume(1.0);
      await tts.speak(text);
    } catch (e) {
      debugPrint('[NeuralTts] Emergency FlutterTts failed: $e');
    }
  }

  Future<String?> _ensureLanguageExtracted(String lang) {
    final existing = _extractFutures[lang];
    if (existing != null) return existing;
    final fut = _extractLanguageAssets(lang);
    _extractFutures[lang] = fut;
    fut.whenComplete(() {
      if (_extractFutures[lang] == fut) {
        _extractFutures.remove(lang);
      }
    });
    return fut;
  }

  Future<String?> _extractLanguageAssets(String lang) async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final targetDir = Directory('${supportDir.path}/tts_models_v1/$lang');
      await targetDir.create(recursive: true);

      final files = switch (lang) {
        'en' => const ['model.int8.onnx', 'tokens.txt', 'lexicon.txt'],
        'si' || 'ta' => const ['model.int8.onnx', 'tokens.txt'],
        _ => const <String>[],
      };
      if (files.isEmpty) return null;

      for (final name in files) {
        final assetPath = 'assets/tts/$lang/$name';
        final dstFile = File('${targetDir.path}/$name');
        final data = await rootBundle.load(assetPath);
        final expectedLen = data.lengthInBytes;
        if (await dstFile.exists() && await dstFile.length() == expectedLen) {
          continue;
        }
        final tmpFile = File('${dstFile.path}.tmp');
        await tmpFile.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, expectedLen),
          flush: true,
        );
        if (await dstFile.exists()) {
          await dstFile.delete();
        }
        await tmpFile.rename(dstFile.path);
      }
      return targetDir.path;
    } catch (e) {
      debugPrint('[NeuralTts] Asset extract($lang) failed: $e');
      return null;
    }
  }

  Future<SendPort?> _ensureWorker() {
    if (_workerSendPort != null) return Future.value(_workerSendPort);
    final inflight = _workerBootFuture;
    if (inflight != null) return inflight;

    final boot = _spawnWorker();
    _workerBootFuture = boot;
    boot.whenComplete(() {
      if (_workerBootFuture == boot) {
        _workerBootFuture = null;
      }
    });
    return boot;
  }

  Future<SendPort?> _spawnWorker() async {
    try {
      final receivePort = ReceivePort();
      _workerReceivePort = receivePort;
      final portCompleter = Completer<SendPort?>();

      await Isolate.spawn(
        _ttsWorkerMain,
        receivePort.sendPort,
        debugName: 'aac_neural_tts_worker',
      );

      receivePort.listen((msg) {
        if (msg is SendPort) {
          _workerSendPort = msg;
          if (!portCompleter.isCompleted) {
            portCompleter.complete(msg);
          }
          return;
        }
        if (msg is Map) {
          final id = msg['id'] as int?;
          final ok = msg['ok'] as bool? ?? false;
          if (id != null) {
            _pendingWorkerReqs.remove(id)?.complete(ok);
          }
        }
      });

      return await portCompleter.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint('[NeuralTts] Isolate spawn failed: $e');
      return null;
    }
  }

  Future<bool> _sendWorkerRequest(
    SendPort port,
    Map<String, Object?> payload,
  ) async {
    final id = _nextReqId++;
    final completer = Completer<bool>();
    _pendingWorkerReqs[id] = completer;
    port.send({...payload, 'id': id});
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _pendingWorkerReqs.remove(id);
        return false;
      },
    );
  }

  Future<String?> _getCacheDir() async {
    if (_cacheDirPath != null) return _cacheDirPath;
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory('${tmp.path}/aac_tts_cache');
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
      final entities = await dir
          .list()
          .where((e) => e is File && e.path.endsWith('.wav'))
          .cast<File>()
          .toList();
      if (entities.length <= _maxCachedWavs) return;
      final stats = <MapEntry<File, DateTime>>[];
      for (final f in entities) {
        stats.add(MapEntry(f, (await f.stat()).modified));
      }
      stats.sort((a, b) => a.value.compareTo(b.value));
      final toDelete = stats.length - _maxCachedWavs;
      for (var i = 0; i < toDelete; i++) {
        await stats[i].key.delete().catchError((_) => stats[i].key);
      }
    } catch (_) {}
  }

  static String _cacheKey(TtsAcousticSpec spec, String text) {
    final raw =
        '${spec.languageCode}|${spec.speakerId}|${spec.targetF0Hz.toStringAsFixed(1)}|${spec.formantSemitones.toStringAsFixed(2)}|${spec.speed.toStringAsFixed(2)}|$text';
    var h1 = 0x811c9dc5;
    var h2 = 0x01000193;
    for (final unit in raw.codeUnits) {
      h1 = ((h1 ^ unit) * 0x01000193) & 0x7fffffff;
      h2 = ((h2 + unit) * 0x45d9f3b) & 0x7fffffff;
    }
    final p1 = h1.toRadixString(16).padLeft(8, '0');
    final p2 = h2.toRadixString(16).padLeft(8, '0');
    return '$p1$p2';
  }

  static String _normalizeLang(String lang) {
    final lower = lang.toLowerCase();
    if (lower.startsWith('si')) return 'si';
    if (lower.startsWith('ta')) return 'ta';
    return 'en';
  }

  /// Disposes worker resources on app shutdown.
  Future<void> dispose() async {
    await stop();
    _workerSendPort?.send({'cmd': 'shutdown'});
    _workerSendPort = null;
    _workerReceivePort?.close();
    _workerReceivePort = null;
    await _player?.dispose();
    _player = null;
  }
}

// =============================================================================
// BACKGROUND WORKER ISOLATE (sherpa_onnx VITS + Signalsmith Stretch FFI)
// =============================================================================

void _ttsWorkerMain(SendPort mainPort) {
  final rx = ReceivePort();
  mainPort.send(rx.sendPort);

  sherpa_onnx.initBindings();

  _ProcessPcmDart? processPcm;
  try {
    final dspLib = DynamicLibrary.open('libaac_voice_dsp.so');
    processPcm = dspLib.lookupFunction<_ProcessPcmNative, _ProcessPcmDart>(
      'aac_process_float_pcm_to_wav',
    );
  } catch (_) {
    processPcm = null;
  }

  sherpa_onnx.OfflineTts? activeTts;
  String? activeLang;

  sherpa_onnx.OfflineTts? ensureModel(String lang, String modelDir) {
    if (activeTts != null && activeLang == lang) return activeTts;
    activeTts?.free();
    activeTts = null;
    activeLang = null;

    final modelFile = '$modelDir/model.int8.onnx';
    final tokensFile = '$modelDir/tokens.txt';
    final lexiconFile = lang == 'en' ? '$modelDir/lexicon.txt' : '';

    if (!File(modelFile).existsSync() || !File(tokensFile).existsSync()) {
      return null;
    }
    if (lang == 'en' && !File(lexiconFile).existsSync()) {
      return null;
    }

    final config = sherpa_onnx.OfflineTtsConfig(
      model: sherpa_onnx.OfflineTtsModelConfig(
        vits: sherpa_onnx.OfflineTtsVitsModelConfig(
          model: modelFile,
          tokens: tokensFile,
          lexicon: lexiconFile,
        ),
        numThreads: 2,
        debug: false,
      ),
      maxNumSentences: 1,
    );

    activeTts = sherpa_onnx.OfflineTts(config);
    activeLang = lang;
    return activeTts;
  }

  rx.listen((raw) {
    if (raw is! Map) return;
    final cmd = raw['cmd'] as String?;
    final id = raw['id'] as int?;

    if (cmd == 'shutdown') {
      activeTts?.free();
      activeTts = null;
      rx.close();
      return;
    }

    var ok = false;
    try {
      final lang = raw['lang'] as String? ?? 'en';
      final modelDir = raw['modelDir'] as String? ?? '';
      final tts = ensureModel(lang, modelDir);

      if (cmd == 'warmup') {
        ok = tts != null;
      } else if (cmd == 'synth' && tts != null) {
        final text = raw['text'] as String? ?? '';
        final rawCodepoints = raw['codepoints'] as List?;
        final codepoints = rawCodepoints
            ?.map((s) => (s as List).cast<int>())
            .toList(growable: false);
        final sid = raw['sid'] as int? ?? 0;
        final speed = (raw['speed'] as num?)?.toDouble() ?? 1.0;
        final targetF0 = (raw['targetF0'] as num?)?.toDouble() ?? 0.0;
        final formantSt = (raw['formantSt'] as num?)?.toDouble() ?? 0.0;
        final outPath = raw['outPath'] as String? ?? '';

        final genCfg = sherpa_onnx.OfflineTtsGenerationConfig(
          sid: sid,
          speed: speed,
          silenceScale: 0.2,
          phonemeCodepoints: codepoints,
        );
        final audio = tts.generateWithConfig(text: text, config: genCfg);
        if (audio.samples.isNotEmpty && audio.sampleRate > 0) {
          if (processPcm != null) {
            final buf = calloc<Float>(audio.samples.length);
            final outPtr = outPath.toNativeUtf8();
            try {
              buf.asTypedList(audio.samples.length).setAll(0, audio.samples);
              final rc = processPcm(
                buf,
                audio.samples.length,
                audio.sampleRate,
                outPtr,
                targetF0,
                formantSt,
              );
              ok = rc == 0;
            } finally {
              calloc.free(buf);
              calloc.free(outPtr);
            }
          } else {
            ok = sherpa_onnx.writeWave(
              filename: outPath,
              samples: audio.samples,
              sampleRate: audio.sampleRate,
            );
          }
        }
      }
    } catch (_) {
      ok = false;
    }

    if (id != null) {
      mainPort.send({'id': id, 'ok': ok});
    }
  });
}
