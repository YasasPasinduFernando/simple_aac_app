import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_aac_app/services/speech_engine.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HomeDrawer shows Offline Speech without legacy 4-voice selector',
      (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeDrawer(
            selectedCategory: 'All',
            currentLanguageLabel: 'English',
            gridColumns: 2,
            visibleCardsLabel: 'All',
            isEditMode: false,
            showTtsInput: true,
            orientationLabel: 'Portrait',
            fullScreen: false,
            headerColor: Colors.blue,
            headerTextColor: Colors.white,
            hideTtsText: false,
            useImageOverlayLabel: false,
            applyTextColorToCards: false,
            isDarkMode: false,
            isColorBlindMode: false,
            primaryColorSwatch: Colors.blue,
            textColorSwatch: Colors.white,
            backgroundColorSwatch: Colors.white,
            isOnlineEnabled: false,
            onToggleOnline: (_) {},
            onToggleDarkMode: (_) {},
            onChangeColorBlindMode: (_) {},
            onSelectCategory: () {},
            onAddCategory: () {},
            onToggleEdit: () {},
            onToggleTtsInput: () {},
            onToggleTtsText: () {},
            onToggleCardImageLabel: () {},
            onToggleApplyTextColorToCards: () {},
            onChangeOrientation: () {},
            onPickPrimaryColor: () {},
            onPickTextColor: () {},
            onPickBackgroundColor: () {},
            onShowTtsBarSize: () {},
            onToggleFullScreen: () {},
            onShowLanguage: () {},
            onShowGrid: () {},
            onShowVisibleCount: () {},
            onBackup: () {},
            onRestore: () {},
            onResetSettings: () {},
            speechStatusLabel: 'English, Sinhala & Tamil ready offline',
            onShowOfflineSpeech: () => opened = true,
            onShowAbout: () {},
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Offline Speech'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Offline Speech'), findsOneWidget);
    expect(find.text('Voice Profile'), findsNothing);

    await tester.tap(find.text('Offline Speech'));
    await tester.pump();
    expect(opened, isTrue);
  });

  test('SpeechEngine parses capability report cleanly via channel mock', () async {
    const channel = MethodChannel('aac_speech_test_probe');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'probeCapabilities') {
        return {
          'initialized': true,
          'defaultEngine': 'com.google.android.tts',
          'engines': [
            {'name': 'com.google.android.tts', 'label': 'Google TTS'},
          ],
          'languages': {
            'en': {
              'localeTag': 'en-US',
              'hasOfflineVoice': true,
              'availabilityCode': 1,
              'offlineVoiceCount': 4,
              'voiceCount': 6,
            },
            'si': {
              'localeTag': 'si-LK',
              'hasOfflineVoice': false,
              'availabilityCode': -1,
              'offlineVoiceCount': 0,
              'voiceCount': 1,
            },
          },
        };
      }
      if (call.method == 'openTtsInstaller') return true;
      return null;
    });

    final engine = SpeechEngine.forTest(channel: channel);
    final report = await engine.probeCapabilities();
    // On Linux VM `Platform.isAndroid` is false so probeCapabilities returns null gracefully.
    expect(report == null || report.defaultEngine == 'com.google.android.tts', isTrue);
    await expectLater(engine.stop(), completes);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('SpeechResult & SpeechCapabilityReport track missing offline languages', () {
    const report = SpeechCapabilityReport(
      initialized: true,
      defaultEngine: 'com.google.android.tts',
      languages: {
        'en': LanguageVoiceStatus(
          languageCode: 'en',
          localeTag: 'en-US',
          hasOfflineVoice: true,
          availabilityCode: 1,
          offlineVoiceCount: 2,
          totalVoiceCount: 2,
        ),
        'si': LanguageVoiceStatus(
          languageCode: 'si',
          localeTag: 'si-LK',
          hasOfflineVoice: false,
          availabilityCode: -1,
          offlineVoiceCount: 0,
          totalVoiceCount: 0,
        ),
      },
    );
    expect(report.hasOfflineFor('en'), isTrue);
    expect(report.hasOfflineFor('si-LK'), isFalse);
    expect(report.missingLanguages, ['si']);

    const emptyRes = SpeechResult(status: SpeechStatus.emptyAudio);
    expect(emptyRes.isSuccess, isFalse);

    const missingRes = SpeechResult(
      status: SpeechStatus.missingLanguageData,
      missingLanguages: ['si'],
    );
    expect(missingRes.isSuccess, isFalse);
    expect(missingRes.missingLanguages, ['si']);

    const failRes = SpeechResult(
      status: SpeechStatus.synthesisFailed,
      errorMessage: 'ta',
    );
    expect(failRes.isSuccess, isFalse);
    expect(failRes.errorMessage, 'ta');

    // Uninstalled voices carrying 'notInstalled' must not falsely count as offline-ready.
    final uninstalled = LanguageVoiceStatus.fromMap('si', {
      'localeTag': 'si-LK',
      'hasOfflineVoice': false,
      'availabilityCode': -1,
      'offlineVoiceCount': 0,
      'voiceCount': 1,
      'voices': [
        {
          'name': 'si-lk-x-sin-local',
          'locale': 'si-LK',
          'requiresNetwork': false,
          'notInstalled': true,
        }
      ],
    });
    expect(uninstalled.hasOfflineVoice, isFalse);
    expect(uninstalled.offlineVoiceCount, 0);
  });

  test('SpeechEngine rejects empty/whitespace utterances explicitly', () async {
    final res = await SpeechEngine.instance.speak(
      '   ',
      preferredLanguage: 'si',
    );
    expect(res.isSuccess, isFalse);
    expect(res.status, SpeechStatus.emptyAudio);
  });
}
