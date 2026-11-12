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

  test('SpeechEngine speaks en, si, ta, and mixed phrases via flutter_tts channel', () async {
    final calls = <MethodCall>[];
    const fttsChannel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(fttsChannel, (call) async {
      calls.add(call);
      if (call.method == 'setLanguage' ||
          call.method == 'setSpeechRate' ||
          call.method == 'setVolume' ||
          call.method == 'setPitch' ||
          call.method == 'awaitSpeakCompletion' ||
          call.method == 'speak' ||
          call.method == 'stop') {
        return 1;
      }
      return null;
    });

    final engine = SpeechEngine.forTest();

    final siRes = await engine.speak('සෙල්ලම්', preferredLanguage: 'si');
    expect(siRes.isSuccess, isTrue);

    final mixRes = await engine.speak(
      'මට water එකක් දෙන්න',
      preferredLanguage: 'si',
    );
    expect(mixRes.isSuccess, isTrue);

    final langs = calls
        .where((c) => c.method == 'setLanguage')
        .map((c) => c.arguments)
        .toList();
    expect(langs, containsAllInOrder(['en-US', 'si-LK', 'en-US', 'si-LK']));

    final spoken = calls
        .where((c) => c.method == 'speak')
        .map((c) => c.arguments)
        .toList();
    expect(spoken, ['සෙල්ලම්', 'මට', 'water', 'එකක් දෙන්න']);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(fttsChannel, null);
  });

  test('SpeechEngine reports languageUnavailable if no locale works and speak returns 0', () async {
    const fttsChannel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(fttsChannel, (call) async {
      if (call.method == 'setLanguage') {
        return call.arguments == 'en-US' ? 1 : 0;
      }
      if (call.method == 'speak') return 0;
      if (call.method == 'setSpeechRate' ||
          call.method == 'setVolume' ||
          call.method == 'setPitch' ||
          call.method == 'awaitSpeakCompletion' ||
          call.method == 'stop') {
        return 1;
      }
      return null;
    });

    final engine = SpeechEngine.forTest();
    final res = await engine.speak('හොඳයි', preferredLanguage: 'si');
    expect(res.isSuccess, isFalse);
    expect(res.status, SpeechStatus.languageUnavailable);
    expect(res.missingLanguages, ['si']);

    final emptyRes = await engine.speak('   ', preferredLanguage: 'si');
    expect(emptyRes.isSuccess, isFalse);
    expect(emptyRes.status, SpeechStatus.emptyText);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(fttsChannel, null);
  });

  test('SpeechCapabilityReport tracks supported vs missing offline packs separately', () {
    const report = SpeechCapabilityReport(
      initialized: true,
      defaultEngine: 'com.google.android.tts',
      languages: {
        'en': LanguageVoiceStatus(
          languageCode: 'en',
          localeTag: 'en-US',
          isLanguageAvailable: true,
          hasOfflineVoice: true,
        ),
        'si': LanguageVoiceStatus(
          languageCode: 'si',
          localeTag: 'si-LK',
          isLanguageAvailable: true,
          hasOfflineVoice: false,
        ),
        'ta': LanguageVoiceStatus(
          languageCode: 'ta',
          localeTag: 'ta-IN',
          isLanguageAvailable: false,
          hasOfflineVoice: false,
        ),
      },
    );
    expect(report.missingLanguages, ['si', 'ta']);
    expect(report.unsupportedLanguages, ['ta']);
  });

  test('SpeechEngine selects best offline local voices and applies tuned rates', () async {
    final calls = <MethodCall>[];
    const fttsChannel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(fttsChannel, (call) async {
      calls.add(call);
      if (call.method == 'getVoices') {
        return [
          {'name': 'en-us-x-sfg-network', 'locale': 'en-US'},
          {'name': 'en-us-x-iog-local', 'locale': 'en-US'},
          {'name': 'en-us-x-tpf-local', 'locale': 'en-US'},
          {'name': 'si-lk-x-sin-local', 'locale': 'si-LK'},
          {'name': 'ta-in-x-tad-local', 'locale': 'ta-IN'},
          {'name': 'ta-in-x-tac-local', 'locale': 'ta-IN'},
        ];
      }
      if (call.method == 'setLanguage' ||
          call.method == 'setVoice' ||
          call.method == 'setSpeechRate' ||
          call.method == 'setVolume' ||
          call.method == 'setPitch' ||
          call.method == 'awaitSpeakCompletion' ||
          call.method == 'speak' ||
          call.method == 'stop') {
        return 1;
      }
      return null;
    });

    final engine = SpeechEngine.forTest();
    expect(
      (await engine.speak('සෙල්ලම්', preferredLanguage: 'si')).isSuccess,
      isTrue,
    );
    expect(
      (await engine.speak('வணக்கம்', preferredLanguage: 'ta')).isSuccess,
      isTrue,
    );
    expect(
      (await engine.speak('Hello', preferredLanguage: 'en')).isSuccess,
      isTrue,
    );

    final setVoices = calls
        .where((c) => c.method == 'setVoice')
        .map((c) => Map<String, dynamic>.from(c.arguments as Map)['name'])
        .toList();
    expect(setVoices, [
      'si-lk-x-sin-local',
      'ta-in-x-tac-local',
      'en-us-x-tpf-local',
    ]);

    final rates = calls
        .where((c) => c.method == 'setSpeechRate')
        .map((c) => c.arguments)
        .toList();
    expect(rates, [0.48, 0.465, 0.475, 0.48]);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(fttsChannel, null);
  });
}
