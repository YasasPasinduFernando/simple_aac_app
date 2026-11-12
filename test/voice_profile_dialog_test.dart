import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_aac_app/services/neural_tts_service.dart';
import 'package:simple_aac_app/utils/tts_voice_helper.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HomeDrawer surfaces active Voice Profile and opens voice picker',
      (tester) async {
    var voiceOpened = false;

    for (final profile in TtsVoiceProfile.values) {
      voiceOpened = false;
      final label = TtsVoiceHelper.labelFor(profile);
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
              voiceProfileLabel: label,
              onShowVoiceProfile: () => voiceOpened = true,
              onShowAbout: () {},
            ),
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Voice Profile'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Voice Profile'), findsOneWidget);
      expect(find.text(label), findsOneWidget);

      await tester.tap(find.text('Voice Profile'));
      await tester.pump();
      expect(voiceOpened, isTrue);
    }
  });

  test('NeuralTtsService warmUp and stop degrade cleanly under test VM', () async {
    await NeuralTtsService.instance.warmUp('en');
    await NeuralTtsService.instance.warmUp('si');
    await NeuralTtsService.instance.warmUp('ta');
    await NeuralTtsService.instance.stop();
  });
}
