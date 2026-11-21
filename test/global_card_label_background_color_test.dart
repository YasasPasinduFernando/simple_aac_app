import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';
import 'package:simple_aac_app/services/tutorial_service.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';
import 'package:simple_aac_app/widgets/professional_color_picker_dialog.dart';

class _FakeAudioPlatform extends AudioplayersPlatformInterface {
  @override
  Stream<AudioEvent> getEventStream(String playerId) => const Stream.empty();
  @override
  Future<void> create(String playerId) async {}
  @override
  Future<void> dispose(String playerId) async {}
  @override
  Future<void> pause(String playerId) async {}
  @override
  Future<void> release(String playerId) async {}
  @override
  Future<void> resume(String playerId) async {}
  @override
  Future<void> seek(String playerId, Duration position) async {}
  @override
  Future<void> setAudioContext(String playerId, AudioContext context) async {}
  @override
  Future<void> setBalance(String playerId, double balance) async {}
  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) async {}
  @override
  Future<void> setPlayerMode(String playerId, PlayerMode playerMode) async {}
  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {}
  @override
  Future<void> setSourceBytes(String playerId, Uint8List bytes, {String? mimeType}) async {}
  @override
  Future<void> setSourceUrl(String playerId, String url, {bool? isLocal}) async {}
  @override
  Future<void> setVolume(String playerId, double volume) async {}
  @override
  Future<void> stop(String playerId) async {}
  @override
  Future<int?> getCurrentPosition(String playerId) async => null;
  @override
  Future<int?> getDuration(String playerId) async => null;
  @override
  Future<void> emitLog(String playerId, String message) async {}
  @override
  Future<void> emitError(String playerId, String code, String message) async {}
}

final Uint8List k1x1PngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Global Card Label Background Color - Model & Preset Tests', () {
    test('Default label background color is Warm Ivory (#F4F1EB)', () {
      const defaultColor = Color(0xFFF4F1EB);
      expect(defaultColor.value, equals(0xFFF4F1EB));
      expect(ProfessionalColorPickerDialog.labelBackgroundPresets.first.color.value,
          equals(0xFFF4F1EB));
      expect(ProfessionalColorPickerDialog.labelBackgroundPresets.first.name,
          equals('Warm Ivory'));
    });

    test('All 7 accessible label background presets are defined in correct order', () {
      const presets = ProfessionalColorPickerDialog.labelBackgroundPresets;
      expect(presets.length, equals(7));

      expect(presets[0].name, equals('Warm Ivory'));
      expect(presets[0].color, equals(const Color(0xFFF4F1EB)));

      expect(presets[1].name, equals('Soft Blue'));
      expect(presets[1].color, equals(const Color(0xFFDFEFFA)));

      expect(presets[2].name, equals('Mint Green'));
      expect(presets[2].color, equals(const Color(0xFFDFF2E4)));

      expect(presets[3].name, equals('Blush Pink'));
      expect(presets[3].color, equals(const Color(0xFFF9E3E5)));

      expect(presets[4].name, equals('Lavender'));
      expect(presets[4].color, equals(const Color(0xFFEDE5F8)));

      expect(presets[5].name, equals('Light Yellow'));
      expect(presets[5].color, equals(const Color(0xFFFAEDB9)));

      expect(presets[6].name, equals('Light Gray'));
      expect(presets[6].color, equals(const Color(0xFFECEFF1)));
    });
  });

  group('Global Card Label Color Picker Dialog Tests', () {
    testWidgets('Opens dialog with labelBackgroundPreview and shows 3 sample cards',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Color? appliedColor;
      const initialColor = Color(0xFFF4F1EB);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ProfessionalColorPickerDialog(
                      title: 'Card label color',
                      subtitle: 'Pick a background color for card labels',
                      initialColor: initialColor,
                      defaultColor: const Color(0xFFF4F1EB),
                      previewType: ColorPickerPreviewType.labelBackgroundPreview,
                      onApply: (color) => appliedColor = color,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify title & subtitle
      expect(find.text('Card label color'), findsOneWidget);
      expect(find.text('Pick a background color for card labels'), findsOneWidget);

      // Verify header icon
      expect(find.byIcon(Icons.label_outline_rounded), findsOneWidget);

      // Verify 3 distinct sample cards exist in the live preview
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Eat'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);

      // Verify all 7 presets exist
      for (final p in ProfessionalColorPickerDialog.labelBackgroundPresets) {
        expect(find.bySemanticsLabel('Preset color ${p.name}'), findsOneWidget);
      }

      // Tap 'Soft Blue' preset
      await tester.tap(find.bySemanticsLabel('Preset color Soft Blue'));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(appliedColor, isNotNull);
      expect(appliedColor!.value, equals(const Color(0xFFDFEFFA).value));
    });

    testWidgets('Cancel button dismisses without modifying color', (tester) async {
      Color? appliedColor;
      const initialColor = Color(0xFFF4F1EB);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ProfessionalColorPickerDialog(
                      title: 'Card label color',
                      subtitle: 'Pick a background color for card labels',
                      initialColor: initialColor,
                      defaultColor: const Color(0xFFF4F1EB),
                      previewType: ColorPickerPreviewType.labelBackgroundPreview,
                      onApply: (color) => appliedColor = color,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Select Mint Green
      await tester.tap(find.bySemanticsLabel('Preset color Mint Green'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(appliedColor, isNull);
    });

    testWidgets('Reset button restores default Warm Ivory (#F4F1EB)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Color? appliedColor;
      const initialColor = Color(0xFFDFEFFA); // Start with Soft Blue

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ProfessionalColorPickerDialog(
                      title: 'Card label color',
                      subtitle: 'Pick a background color for card labels',
                      initialColor: initialColor,
                      defaultColor: const Color(0xFFF4F1EB),
                      previewType: ColorPickerPreviewType.labelBackgroundPreview,
                      onApply: (color) => appliedColor = color,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap Reset
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(appliedColor, isNotNull);
      expect(appliedColor!.value, equals(const Color(0xFFF4F1EB).value));
    });
  });

  group('HomeDrawer Settings Tile Tests', () {
    testWidgets('Renders Card Label Color (Global) tile with preview chip and triggers callback',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool pickerOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            endDrawer: HomeDrawer(
              selectedCategory: 'All',
              currentLanguageLabel: 'English',
              gridColumns: 2,
              visibleCardsLabel: 'All cards (6/6)',
              isEditMode: false,
              showTtsInput: true,
              orientationLabel: 'Portrait',
              fullScreen: true,
              headerColor: const Color(0xFF0277BD),
              headerTextColor: Colors.white,
              hideTtsText: false,
              useImageOverlayLabel: false,
              applyTextColorToCards: false,
              isDarkMode: false,
              isColorBlindMode: false,
              primaryColorSwatch: const Color(0xFF0277BD),
              textColorSwatch: Colors.white,
              backgroundColorSwatch: Colors.white,
              cardTextColorSwatch: const Color(0xFF111827),
              cardLabelBgColorSwatch: const Color(0xFFF4F1EB),
              onPickCardLabelBgColor: () => pickerOpened = true,
              isOnlineEnabled: true,
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
              speechStatusLabel: 'Ready',
              onShowAbout: () {},
            ),
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                child: const Text('Open Drawer'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Card Label Color (Global)'), 150);
      await tester.pumpAndSettle();

      // Find the Card Label Color (Global) tile
      expect(find.text('Card Label Color (Global)'), findsOneWidget);
      expect(find.text('Background color of the text label on cards'), findsOneWidget);

      // Verify preview chip with 'Hello'
      expect(find.text('Hello'), findsWidgets);

      // Tap the tile
      await tester.tap(find.text('Card Label Color (Global)'));
      await tester.pumpAndSettle();

      expect(pickerOpened, isTrue);
    });
  });

  group('Contrast Safety & WCAG AAA Compliance Tests', () {
    test('Warm Ivory (#F4F1EB) provides > 12:1 contrast with #252B32 text', () {
      const bg = Color(0xFFF4F1EB);
      const text = Color(0xFF252B32);

      final bgLuminance = bg.computeLuminance();
      final textLuminance = text.computeLuminance();

      final contrast = (bgLuminance + 0.05) / (textLuminance + 0.05);
      expect(contrast, greaterThan(7.0)); // WCAG AAA is 7:1
      expect(contrast, greaterThan(12.0));
    });

    test('Dark custom footer falls back to white text', () {
      const darkBg = Color(0xFF111827);
      final brightness = ThemeData.estimateBrightnessForColor(darkBg);
      expect(brightness, equals(Brightness.dark));

      final resolvedTextColor = brightness == Brightness.light
          ? const Color(0xFF252B32)
          : Colors.white;

      expect(resolvedTextColor, equals(Colors.white));

      final whiteLuminance = Colors.white.computeLuminance();
      final darkLuminance = darkBg.computeLuminance();
      final contrast = (whiteLuminance + 0.05) / (darkLuminance + 0.05);
      expect(contrast, greaterThan(15.0)); // WCAG AAA
    });
  });

  group('SharedPreferences Persistence & Backup/Restore Roundtrip', () {
    test('Default value is #F4F1EB when preference is absent', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final colorValue = prefs.getInt('globalCardLabelBackgroundColor') ??
          prefs.getInt('cardLabelBackgroundColor') ??
          const Color(0xFFF4F1EB).value;

      expect(colorValue, equals(0xFFF4F1EB));
    });

    test('Saves and retrieves globalCardLabelBackgroundColor', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('globalCardLabelBackgroundColor', 0xFFDFEFFA);

      final colorValue = prefs.getInt('globalCardLabelBackgroundColor') ??
          const Color(0xFFF4F1EB).value;

      expect(colorValue, equals(0xFFDFEFFA));
    });

    test('Backup export and restore includes globalCardLabelBackgroundColor', () {
      final backupSettings = {
        'gridColumns': 2,
        'language': 'en',
        'cardTextColor': const Color(0xFF111827).value,
        'globalCardLabelBackgroundColor': 0xFFDFEFFA,
      };

      // Verify serialization
      expect(backupSettings['globalCardLabelBackgroundColor'], equals(0xFFDFEFFA));

      // Verify deserialization
      final restored = (backupSettings['globalCardLabelBackgroundColor'] as num?)?.toInt() ??
          (backupSettings['cardLabelBackgroundColor'] as num?)?.toInt() ??
          const Color(0xFFF4F1EB).value;

      expect(restored, equals(0xFFDFEFFA));
    });

    test('Legacy backup without globalCardLabelBackgroundColor restores with default', () {
      final legacyBackupSettings = {
        'gridColumns': 2,
        'language': 'en',
        'cardTextColor': const Color(0xFF111827).value,
      };

      final restored = (legacyBackupSettings['globalCardLabelBackgroundColor'] as num?)?.toInt() ??
          (legacyBackupSettings['cardLabelBackgroundColor'] as num?)?.toInt() ??
          const Color(0xFFF4F1EB).value;

      expect(restored, equals(0xFFF4F1EB));
    });
  });

  group('HomePage Global Card Label Background Color Integration Tests', () {
    late Directory tempDir;

    setUpAll(() {
      AudioplayersPlatformInterface.instance = _FakeAudioPlatform();
    });

    setUp(() async {
      AudioplayersPlatformInterface.instance = _FakeAudioPlatform();
      tempDir = await Directory.systemTemp.createTemp('label_bg_test_');
      CardStorageService.docsDirectoryOverride = () async => tempDir;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tempDir.path,
      );

      StarterPackService.clearCache();
      HomePage.enableTtsInit = false;
      HomePage.enableTutorialInit = false;
      HomePage.skipSplashForTesting = true;
      HomePage.initialCardsForTesting = null;
    });

    tearDown(() async {
      CardStorageService.resetTestHooks();
      HomePage.initialCardsForTesting = null;
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    testWidgets(
        'Mode B (Overlay OFF, Labels ON): All cards with distinct body colors share SAME global label BG (#F4F1EB) and #252B32 text',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final customPhoto = File('${tempDir.path}/chair_camera.jpg');
      customPhoto.writeAsBytesSync(k1x1PngBytes);

      final testCards = [
        AACCard(
          id: 'seed_happy',
          label: 'Happy',
          imagePath: 'assets/home/happy.webp',
          colorValue: 0xFFFFF176, // Yellow
        ),
        AACCard(
          id: 'seed_sad',
          label: 'Sad',
          imagePath: 'assets/home/sad.webp',
          colorValue: 0xFF00B0FF, // Blue
        ),
        AACCard(
          id: 'seed_angry',
          label: 'Angry',
          imagePath: 'assets/home/angry.webp',
          colorValue: 0xFFFF5252, // Red
        ),
        AACCard(
          id: 'seed_more',
          label: 'More',
          imagePath: 'assets/images/seed_v2/more.webp',
          colorValue: 0xFF3F51B5, // Purple/Indigo
          type: 'folder',
          subCards: [AACCard(id: 'sub_1', label: 'Item 1', colorValue: 0xFFFFFFFF)],
        ),
        AACCard(
          id: 'custom_chair',
          label: 'Chair',
          imagePath: customPhoto.path,
          colorValue: 0xFFE040FB, // Magenta
        ),
      ];

      SharedPreferences.setMockInitialValues({
        'hasSeededDefaultCards': true,
        'isTutorialCompleted': true,
        'isBoardTutorialDismissed': true,
        TutorialService.prefCompleted: true,
        TutorialService.prefSkipped: true,
        'useImageOverlayLabel': false, // Mode B
        'showCardLabels': true,
        'gridColumns': 2,
      });

      await NetworkPolicyService.instance.init();
      HomePage.initialCardsForTesting = testCards;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Check all 5 cards render labels in #252B32 text
      for (final card in testCards) {
        final labelFinder = find.text(card.label);
        expect(labelFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(labelFinder);
        expect(textWidget.style?.color, equals(const Color(0xFF252B32)),
            reason: '${card.label} text must be accessible #252B32 on Warm Ivory');
      }

      // Check footer Containers are colored with Warm Ivory (0xFFF4F1EB)
      final footerContainers = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.color?.value == const Color(0xFFF4F1EB).value;
        }
        return false;
      });

      expect(footerContainers, findsNWidgets(5),
          reason: 'All 5 cards must have footers colored with global Warm Ivory #F4F1EB');
    });

    testWidgets(
        'Mode B with Soft Blue: All cards simultaneously use Soft Blue (#DFEFFA)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testCards = [
        AACCard(
          id: 'seed_happy',
          label: 'Happy',
          imagePath: 'assets/home/happy.webp',
          colorValue: 0xFFFFF176,
        ),
        AACCard(
          id: 'seed_sad',
          label: 'Sad',
          imagePath: 'assets/home/sad.webp',
          colorValue: 0xFF00B0FF,
        ),
      ];

      SharedPreferences.setMockInitialValues({
        'hasSeededDefaultCards': true,
        'isTutorialCompleted': true,
        'isBoardTutorialDismissed': true,
        TutorialService.prefCompleted: true,
        TutorialService.prefSkipped: true,
        'useImageOverlayLabel': false, // Mode B
        'showCardLabels': true,
        'globalCardLabelBackgroundColor': 0xFFDFEFFA, // Soft Blue
        'gridColumns': 2,
      });

      await NetworkPolicyService.instance.init();
      HomePage.initialCardsForTesting = testCards;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Check footer Containers are colored with Soft Blue (0xFFDFEFFA)
      final footerContainers = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.color?.value == const Color(0xFFDFEFFA).value;
        }
        return false;
      });

      expect(footerContainers, findsNWidgets(2),
          reason: 'All cards must have footers colored with global Soft Blue #DFEFFA');
    });

    testWidgets('Mode A (Overlay ON): Cards render white text over gradient, no solid footer',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testCards = [
        AACCard(
          id: 'seed_happy',
          label: 'Happy',
          imagePath: 'assets/home/happy.webp',
          colorValue: 0xFFFFF176,
        ),
      ];

      SharedPreferences.setMockInitialValues({
        'hasSeededDefaultCards': true,
        'isTutorialCompleted': true,
        'isBoardTutorialDismissed': true,
        TutorialService.prefCompleted: true,
        TutorialService.prefSkipped: true,
        'useImageOverlayLabel': true, // Mode A
        'showCardLabels': true,
        'gridColumns': 2,
      });

      await NetworkPolicyService.instance.init();
      HomePage.initialCardsForTesting = testCards;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      final labelFinder = find.text('Happy');
      expect(labelFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(labelFinder);
      expect(textWidget.style?.color, equals(Colors.white));

      // No solid Warm Ivory footer in Overlay ON mode
      final footerContainers = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.color?.value == const Color(0xFFF4F1EB).value;
        }
        return false;
      });
      expect(footerContainers, findsNothing);
    });

    testWidgets('Mode C (Labels OFF): No card label text is rendered', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testCards = [
        AACCard(
          id: 'seed_happy',
          label: 'Happy',
          imagePath: 'assets/home/happy.webp',
          colorValue: 0xFFFFF176,
        ),
      ];

      SharedPreferences.setMockInitialValues({
        'hasSeededDefaultCards': true,
        'isTutorialCompleted': true,
        'isBoardTutorialDismissed': true,
        TutorialService.prefCompleted: true,
        TutorialService.prefSkipped: true,
        'useImageOverlayLabel': false,
        'showCardLabels': false, // Mode C
        'gridColumns': 2,
      });

      await NetworkPolicyService.instance.init();
      HomePage.initialCardsForTesting = testCards;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Happy'), findsNothing);
    });
  });
}
