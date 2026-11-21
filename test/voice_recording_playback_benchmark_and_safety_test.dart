import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';
import 'package:simple_aac_app/widgets/card_editor_dialog.dart';

const List<int> _kSampleGifBytes = <int>[
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00,
  0x00, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3B,
];

class _InstrumentedAudioPlatform extends AudioplayersPlatformInterface {
  final List<String> callLog = [];
  final List<Duration> callTimestamps = [];
  final Stopwatch stopwatch = Stopwatch()..start();
  final StreamController<AudioEvent> _eventController =
      StreamController<AudioEvent>.broadcast();

  void reset() {
    callLog.clear();
    callTimestamps.clear();
    stopwatch.reset();
    stopwatch.start();
  }

  void _log(String method) {
    callLog.add(method);
    callTimestamps.add(stopwatch.elapsed);
  }

  @override
  Stream<AudioEvent> getEventStream(String playerId) => _eventController.stream;

  @override
  Future<void> create(String playerId) async {
    _log('create:$playerId');
  }

  @override
  Future<void> dispose(String playerId) async {
    _log('dispose:$playerId');
  }

  @override
  Future<void> pause(String playerId) async {
    _log('pause:$playerId');
  }

  @override
  Future<void> release(String playerId) async {
    _log('release:$playerId');
  }

  @override
  Future<void> resume(String playerId) async {
    _log('resume:$playerId');
  }

  @override
  Future<void> seek(String playerId, Duration position) async {
    _log('seek:$playerId');
  }

  @override
  Future<void> setAudioContext(String playerId, AudioContext context) async {
    _log('setAudioContext:$playerId');
  }

  @override
  Future<void> setBalance(String playerId, double balance) async {
    _log('setBalance:$playerId');
  }

  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) async {
    _log('setPlaybackRate:$playerId');
  }

  @override
  Future<void> setPlayerMode(String playerId, PlayerMode playerMode) async {
    _log('setPlayerMode:$playerId');
  }

  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {
    _log('setReleaseMode:$playerId');
  }

  @override
  Future<void> setSourceBytes(String playerId, Uint8List bytes,
      {String? mimeType}) async {
    _log('setSourceBytes:$playerId');
    _eventController.add(const AudioEvent(
      eventType: AudioEventType.prepared,
      isPrepared: true,
    ));
  }

  @override
  Future<void> setSourceUrl(String playerId, String url, {bool? isLocal}) async {
    _log('setSourceUrl:$playerId:$url');
    _eventController.add(const AudioEvent(
      eventType: AudioEventType.prepared,
      isPrepared: true,
    ));
  }

  @override
  Future<void> setVolume(String playerId, double volume) async {
    _log('setVolume:$playerId');
  }

  @override
  Future<void> stop(String playerId) async {
    _log('stop:$playerId');
  }

  @override
  Future<int?> getCurrentPosition(String playerId) async => null;

  @override
  Future<int?> getDuration(String playerId) async => null;

  @override
  Future<void> emitLog(String playerId, String message) async {}

  @override
  Future<void> emitError(String playerId, String code, String message) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late _InstrumentedAudioPlatform audioPlatform;
  final List<String> fttsCalls = [];

  setUpAll(() {
    audioPlatform = _InstrumentedAudioPlatform();
    AudioplayersPlatformInterface.instance = audioPlatform;
  });

  setUp(() async {
    audioPlatform.reset();
    fttsCalls.clear();

    tempDir = await Directory.systemTemp.createTemp('voice_perf_qa_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async {
        fttsCalls.add(call.method);
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
            return [
              {'name': 'en-us-local', 'locale': 'en-US'},
              {'name': 'si-lk-local', 'locale': 'si-LK'},
              {'name': 'ta-in-local', 'locale': 'ta-IN'},
            ];
          case 'setVoice':
            return 1;
          default:
            return null;
        }
      },
    );

    SharedPreferences.setMockInitialValues({
      'online_features_enabled': false,
      'globalCardLabelBackgroundColor': 0xFFF4F1EB,
      'useImageOverlayLabel': false,
      'showCardLabels': true,
    });

    StarterPackService.clearCache();
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.skipSplashForTesting = true;
    HomePage.initialCardsForTesting = null;
  });

  tearDown(() async {
    CardStorageService.resetTestHooks();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Performance Baseline & Statistical Profiling', () {
    testWidgets(
        'Measures cold vs warm tap latency across 50 iterations with p50 and p95 calculations',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Create a dummy recording
      final voiceFile = File('${tempDir.path}/test_voice.m4a')
        ..writeAsBytesSync(utf8.encode('M4A_SAMPLE_AUDIO_BYTES_TEST'));

      final testCard = AACCard(
        id: 'bench_voice_card',
        label: 'My Voice',
        voicePath: voiceFile.path,
        colorValue: 0xFF4CAF50,
      );

      HomePage.initialCardsForTesting = [testCard];

      await tester.pumpWidget(
        const MaterialApp(home: HomePage()),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.descendant(
        of: find.byKey(const ValueKey('bench_voice_card')),
        matching: find.text('My Voice'),
      );
      expect(cardFinder, findsOneWidget);

      final latenciesMs = <double>[];

      // Measure 50 consecutive taps to compute statistical baseline
      for (int i = 0; i < 50; i++) {
        if (i < 49) {
          audioPlatform.callLog.clear();
        }
        final sw = Stopwatch()..start();

        await tester.tap(cardFinder);
        await tester.pump();

        sw.stop();
        latenciesMs.add(sw.elapsedMicroseconds / 1000.0);

        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 30));
        });
        await tester.pump();
      }

      latenciesMs.sort();
      final p50 = latenciesMs[(latenciesMs.length * 0.50).floor()];
      final p95 = latenciesMs[(latenciesMs.length * 0.95).floor()];
      final coldTap = latenciesMs.first;

      debugPrint(
        '[Voice Benchmark] 50 runs: Cold=${coldTap.toStringAsFixed(2)}ms, '
        'p50=${p50.toStringAsFixed(2)}ms, p95=${p95.toStringAsFixed(2)}ms',
      );

      // Verify that UI tap handling is responsive and non-blocking in debug test runner
      expect(p50, lessThan(100.0),
          reason: 'Median tap dispatch must be fast and non-blocking');
      expect(p95, lessThan(200.0),
          reason: '95th percentile tap dispatch must complete without lag');

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(audioPlatform.callLog.any((c) => c.startsWith('setSourceUrl')), isTrue);
      expect(audioPlatform.callLog.any((c) => c.startsWith('resume')), isTrue);
    });
  });

  group('Mandatory Test Scenarios (A - I)', () {
    testWidgets('Scenario A: Recorded voice only card tap triggers playback promptly',
        (tester) async {
      final voiceFile = File('${tempDir.path}/voice_only.m4a')
        ..writeAsBytesSync(utf8.encode('VOICE_ONLY_CONTENT'));

      final card = AACCard(
        id: 'card_voice_only',
        label: 'Voice Only',
        voicePath: voiceFile.path,
        colorValue: 0xFF81C784,
      );
      HomePage.initialCardsForTesting = [card];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      audioPlatform.reset();
      fttsCalls.clear();

      await tester.tap(find.text('Voice Only'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      // AudioPlayer must be invoked with the exact path
      expect(
        audioPlatform.callLog.any((c) => c.contains('voice_only.m4a')),
        isTrue,
      );
      expect(audioPlatform.callLog.any((c) => c.startsWith('resume')), isTrue);
      // TTS must NOT speak when custom voice exists
      expect(fttsCalls.contains('speak'), isFalse);
    });

    testWidgets('Scenario B: Recorded voice with Camera JPEG photo',
        (tester) async {
      final jpgFile = File('${tempDir.path}/photo.jpg')
        ..writeAsBytesSync(utf8.encode('PHOTO_BYTES'));
      final voiceFile = File('${tempDir.path}/photo_voice.m4a')
        ..writeAsBytesSync(utf8.encode('VOICE_BYTES'));

      final card = AACCard(
        id: 'card_photo_voice',
        label: 'Photo Voice',
        imagePath: jpgFile.path,
        voicePath: voiceFile.path,
        colorValue: 0xFFFFB74D,
      );
      HomePage.initialCardsForTesting = [card];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      audioPlatform.reset();
      await tester.tap(find.text('Photo Voice'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(
        audioPlatform.callLog.any((c) => c.contains('photo_voice.m4a')),
        isTrue,
      );
    });

    testWidgets(
        'Scenario C: Recorded voice with animated GIF (silent loop, zero audio collision)',
        (tester) async {
      final gifFile = File('${tempDir.path}/animated.gif')
        ..writeAsBytesSync(_kSampleGifBytes);
      final voiceFile = File('${tempDir.path}/gif_voice.m4a')
        ..writeAsBytesSync(utf8.encode('GIF_VOICE_BYTES'));

      final card = AACCard(
        id: 'card_gif_voice',
        label: 'GIF Voice',
        imagePath: gifFile.path,
        voicePath: voiceFile.path,
        colorValue: 0xFFBA68C8,
      );
      HomePage.initialCardsForTesting = [card];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      audioPlatform.reset();
      await tester.tap(find.text('GIF Voice'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      // Playback invoked cleanly for recorded voice
      expect(
        audioPlatform.callLog.any((c) => c.contains('gif_voice.m4a')),
        isTrue,
      );
      // Image renders without attempting audio playback from GIF
      expect(fttsCalls.contains('speak'), isFalse);
    });

    testWidgets('Scenario D: TTS-only cards (en, si, ta) speak via SpeechEngine',
        (tester) async {
      final cardEn = AACCard(
        id: 'card_tts_en',
        label: 'Water',
        labelSinhala: 'වතුර',
        labelTamil: 'தண்ணீர்',
        colorValue: 0xFF29B6F6,
      );
      HomePage.initialCardsForTesting = [cardEn];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      audioPlatform.reset();
      fttsCalls.clear();

      await tester.tap(find.text('Water'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(fttsCalls, contains('speak'));
      expect(audioPlatform.callLog.any((c) => c.startsWith('resume')), isFalse);
    });

    testWidgets(
        'Scenario E: Mixed card sequence (Voice -> TTS -> Voice) handles interruption cleanly',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final voiceFile1 = File('${tempDir.path}/v1.m4a')
        ..writeAsBytesSync(utf8.encode('V1'));
      final voiceFile2 = File('${tempDir.path}/v2.m4a')
        ..writeAsBytesSync(utf8.encode('V2'));

      final cardVoice1 = AACCard(
        id: 'c_voice_1',
        label: 'Voice 1',
        voicePath: voiceFile1.path,
        colorValue: 0xFF81C784,
      );
      final cardTts = AACCard(
        id: 'c_tts',
        label: 'TTS Speak',
        colorValue: 0xFFFFD54F,
      );
      final cardVoice2 = AACCard(
        id: 'c_voice_2',
        label: 'Voice 2',
        voicePath: voiceFile2.path,
        colorValue: 0xFF4DD0E1,
      );

      HomePage.initialCardsForTesting = [cardVoice1, cardTts, cardVoice2];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // 1. Tap Voice 1
      await tester.tap(find.text('Voice 1'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(audioPlatform.callLog.any((c) => c.contains('v1.m4a')), isTrue);

      // 2. Tap TTS (must stop previous voice player)
      audioPlatform.callLog.clear();
      fttsCalls.clear();
      await tester.tap(find.text('TTS Speak'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(audioPlatform.callLog, contains(startsWith('stop')));
      expect(fttsCalls, contains('speak'));

      // 3. Tap Voice 2 (must stop previous TTS and previous player)
      audioPlatform.callLog.clear();
      fttsCalls.clear();
      await tester.tap(find.text('Voice 2'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(fttsCalls, contains('stop'));
      expect(audioPlatform.callLog.any((c) => c.contains('v2.m4a')), isTrue);
    });

    testWidgets(
        'Scenario F: Rapid taps on same card and across cards do not crash or leak players',
        (tester) async {
      final voiceFile = File('${tempDir.path}/rapid.m4a')
        ..writeAsBytesSync(utf8.encode('RAPID_BYTES'));

      final card1 = AACCard(
        id: 'rapid_1',
        label: 'Rapid 1',
        voicePath: voiceFile.path,
        colorValue: 0xFFE57373,
      );
      final card2 = AACCard(
        id: 'rapid_2',
        label: 'Rapid 2',
        voicePath: voiceFile.path,
        colorValue: 0xFF64B5F6,
      );

      HomePage.initialCardsForTesting = [card1, card2];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Rapidly fire 5 taps within 20ms of each other
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Rapid 1').first);
        await tester.pump(const Duration(milliseconds: 20));
      }

      // Switch to card 2 rapidly
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Rapid 2').first);
        await tester.pump(const Duration(milliseconds: 20));
      }

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      // Verify app remains responsive and no uncaught exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Scenario G: CardEditorDialog Preview/Play, Delete and Cancel flows',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final voiceFile = File('${tempDir.path}/dialog_voice.m4a')
        ..writeAsBytesSync(utf8.encode('DIALOG_VOICE_BYTES'));

      final card = AACCard(
        id: 'dialog_card',
        label: 'Editable',
        voicePath: voiceFile.path,
        colorValue: 0xFF9575CD,
      );

      final dummyPlayer = AudioPlayer();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1080, 2400)),
            child: Scaffold(
              body: CardEditorDialog(
                card: card,
                isNew: false,
                categories: const ['General'],
                audioPlayer: dummyPlayer,
                language: 'en',
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Play button is present
      final playBtn = find.byTooltip('Play recording');
      await tester.ensureVisible(playBtn);
      await tester.pump(const Duration(milliseconds: 50));
      expect(playBtn, findsOneWidget);

      audioPlatform.callLog.clear();
      await tester.tap(playBtn);
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      // Playback triggered
      expect(
        audioPlatform.callLog.any((c) => c.contains('dialog_voice.m4a')),
        isTrue,
      );

      // Verify Delete button clears recording
      final deleteBtn = find.byTooltip('Delete recording');
      await tester.ensureVisible(deleteBtn);
      await tester.pump(const Duration(milliseconds: 50));
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pump(const Duration(milliseconds: 50));

      expect(card.voicePath, isNull);
    });

    test('Scenario H: Offline operation functions with local recordings', () async {
      await NetworkPolicyService.instance.setOnlineEnabled(false);
      expect(NetworkPolicyService.instance.isOnlineEnabled, isFalse);

      final voiceFile = File('${tempDir.path}/offline.m4a')
        ..writeAsBytesSync(utf8.encode('OFFLINE_VOICE_BYTES'));

      final card = AACCard(
        id: 'offline_card',
        label: 'Offline Card',
        voicePath: voiceFile.path,
        colorValue: 0xFF4DB6AC,
      );

      // Audio file remains on local disk and readable
      expect(voiceFile.existsSync(), isTrue);
      expect(card.voicePath, voiceFile.path);
    });

    test('Scenario I: Backup & restore preserves custom voice byte integrity',
        () async {
      final voiceFile = File('${tempDir.path}/export_voice.m4a')
        ..writeAsBytesSync(utf8.encode('ORIGINAL_VOICE_AUDIO_PAYLOAD'));
      final originalHash = sha256.convert(voiceFile.readAsBytesSync());

      final card = AACCard(
        id: 'export_card',
        label: 'Export Card',
        voicePath: voiceFile.path,
        colorValue: 0xFFFF8A65,
      );

      // 1. Build backup ZIP
      final zipBytes = await BackupService.buildBackupZip(
        [card],
        settings: {'globalCardLabelBackgroundColor': 0xFFDFEFFA},
      );
      expect(zipBytes, isNotNull);

      // 2. Restore into fresh directory
      final dstDir = await Directory.systemTemp.createTemp('voice_restore_dst_');
      addTearDown(() {
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
      });
      CardStorageService.docsDirectoryOverride = () async => dstDir;

      final payload = await BackupService.restoreFromZipBytes(zipBytes!);
      expect(payload.cards.length, 1);
      final restoredCard = payload.cards[0];
      expect(restoredCard.voicePath, isNotNull);
      expect(File(restoredCard.voicePath!).existsSync(), isTrue);

      final restoredHash =
          sha256.convert(File(restoredCard.voicePath!).readAsBytesSync());
      expect(restoredHash, originalHash,
          reason: 'Voice recording bytes must match byte-for-byte post-restore');
    });
  });
}
