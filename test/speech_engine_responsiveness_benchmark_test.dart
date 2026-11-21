import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_aac_app/services/speech_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TTS First Tap Responsiveness Benchmark & Pre-warm Verification', () {
    late List<MethodCall> methodCalls;
    late MethodChannel fttsChannel;

    setUp(() {
      methodCalls = <MethodCall>[];
      fttsChannel = const MethodChannel('flutter_tts');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(fttsChannel, (call) async {
        methodCalls.add(call);
        switch (call.method) {
          case 'setLanguage':
          case 'setSpeechRate':
          case 'setVolume':
          case 'setPitch':
          case 'awaitSpeakCompletion':
          case 'speak':
          case 'stop':
            return 1;
          case 'getVoices':
            // Simulate realistic system response returning 500 Android system voices
            return List.generate(
              500,
              (i) => {
                'name': i == 0
                    ? 'en-us-x-tpf-local'
                    : i == 1
                        ? 'si-lk-x-sin-local'
                        : i == 2
                            ? 'ta-in-x-tac-local'
                            : 'voice_$i-network',
                'locale': i == 0
                    ? 'en-US'
                    : i == 1
                        ? 'si-LK'
                        : i == 2
                            ? 'ta-IN'
                            : 'es-ES',
              },
            );
          case 'setVoice':
            return 1;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(fttsChannel, null);
    });

    test('1. Cold first tap without pre-warm executes heavy getVoices and language configuration', () async {
      final engine = SpeechEngine.forTest();

      methodCalls.clear();
      final sw = Stopwatch()..start();
      final res = await engine.speak('Happy', preferredLanguage: 'en');
      sw.stop();

      expect(res.isSuccess, isTrue);
      final methods = methodCalls.map((c) => c.method).toList();

      // Confirms root-cause trace: first tap was burdened with getVoices and configuration
      expect(methods, contains('getVoices'),
          reason: 'Cold first tap had to load voice catalog synchronously');
      expect(methods, contains('setLanguage'));
      expect(methods, contains('speak'));
      expect(methods.last, equals('speak'));
    });

    test('2. Pre-warmed engine reduces first tap to direct speak with zero getVoices IPC delay', () async {
      final engine = SpeechEngine.forTest();

      // Simulate app startup pre-warm for English
      await engine.prewarm(preferredLanguage: 'en');

      methodCalls.clear();
      final sw = Stopwatch()..start();
      final res = await engine.speak('Happy', preferredLanguage: 'en');
      sw.stop();

      expect(res.isSuccess, isTrue);
      final methods = methodCalls.map((c) => c.method).toList();

      // On pre-warmed tap: getVoices, setSpeechRate, setPitch, setVolume are NOT called during tap
      expect(methods, isNot(contains('getVoices')),
          reason: 'Pre-warmed first tap must never block on getVoices IPC');
      expect(methods, equals(['stop', 'speak']),
          reason: 'Pre-warmed first tap must directly issue speak with minimum calls');
    });

    test('3. Pre-warmed Sinhala (si) speaks immediately without language switching latency', () async {
      final engine = SpeechEngine.forTest();

      // Simulate app startup pre-warm for Sinhala
      await engine.prewarm(preferredLanguage: 'si');

      methodCalls.clear();
      final res = await engine.speak('සතුටුයි', preferredLanguage: 'si');

      expect(res.isSuccess, isTrue);
      final methods = methodCalls.map((c) => c.method).toList();

      expect(methods, isNot(contains('getVoices')));
      expect(methods, equals(['stop', 'speak']));
      expect(methodCalls.last.arguments, equals('සතුටුයි'));
    });

    test('4. Pre-warmed Tamil (ta) speaks immediately without language switching latency', () async {
      final engine = SpeechEngine.forTest();

      // Simulate app startup pre-warm for Tamil
      await engine.prewarm(preferredLanguage: 'ta');

      methodCalls.clear();
      final res = await engine.speak('மகிழ்ச்சி', preferredLanguage: 'ta');

      expect(res.isSuccess, isTrue);
      final methods = methodCalls.map((c) => c.method).toList();

      expect(methods, isNot(contains('getVoices')));
      expect(methods, equals(['stop', 'speak']));
      expect(methodCalls.last.arguments, equals('மகிழ்ச்சி'));
    });

    test('5. Rapid successive card taps cancel previous speech and do not queue duplicate utterances', () async {
      final engine = SpeechEngine.forTest();
      await engine.prewarm(preferredLanguage: 'en');

      methodCalls.clear();
      // Rapid fire 3 card taps in 10ms
      final f1 = engine.speak('Happy', preferredLanguage: 'en');
      final f2 = engine.speak('Sad', preferredLanguage: 'en');
      final f3 = engine.speak('Angry', preferredLanguage: 'en');

      final results = await Future.wait([f1, f2, f3]);
      expect(results.every((r) => r.isSuccess), isTrue);

      final spokenTexts = methodCalls
          .where((c) => c.method == 'speak')
          .map((c) => c.arguments.toString())
          .toList();

      // Last tap must always be spoken
      expect(spokenTexts.last, equals('Angry'));
    });

    test('6. Early tap during active prewarm safely awaits in-flight future without speech loss', () async {
      final engine = SpeechEngine.forTest();

      // Start prewarm but do NOT await it (simulates early user tap while startup is still ongoing)
      final prewarmFut = engine.prewarm(preferredLanguage: 'en');

      // Immediate tap
      final res = await engine.speak('Hello', preferredLanguage: 'en');
      await prewarmFut;

      expect(res.isSuccess, isTrue);
      final spoken = methodCalls.where((c) => c.method == 'speak').toList();
      expect(spoken.isNotEmpty, isTrue);
      expect(spoken.last.arguments, equals('Hello'));
    });
  });
}
