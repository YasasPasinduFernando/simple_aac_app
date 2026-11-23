import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/tts_token.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';
import 'package:simple_aac_app/widgets/professional_color_picker_dialog.dart';
import 'package:simple_aac_app/widgets/tts_bar.dart';

void main() {
  group('TtsBar Color & Contrast Tests', () {
    testWidgets('TtsBar defaults to 0xFFF5F5F5 in Light Mode when backgroundColor is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: TtsBar(
              tokens: const [],
              isTablet: false,
              onDelete: () {},
              onClear: () {},
              onSpeak: () {},
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.grey.shade100));
    });

    testWidgets('TtsBar defaults to 0xFF1B2027 in Dark Mode when backgroundColor is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: TtsBar(
              tokens: const [],
              isTablet: false,
              onDelete: () {},
              onClear: () {},
              onSpeak: () {},
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF1B2027)));
    });

    testWidgets('TtsBar adapts contrast when custom dark color is used in Light Mode', (tester) async {
      const customDarkColor = Color(0xFF1E1E2E);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: TtsBar(
              tokens: const [
                TtsToken('Elephant', null),
              ],
              isTablet: false,
              backgroundColor: customDarkColor,
              onDelete: () {},
              onClear: () {},
              onSpeak: () {},
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(customDarkColor));

      // Token text should adapt to light/white color for contrast
      final textWidget = tester.widget<Text>(find.text('Elephant'));
      expect(textWidget.style?.color, equals(Colors.white));
    });

    testWidgets('TtsBar adapts contrast when custom light color is used in Dark Mode', (tester) async {
      const customLightColor = Color(0xFFFFF9C4); // Light yellow
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: TtsBar(
              tokens: const [
                TtsToken('Fish', null),
              ],
              isTablet: false,
              backgroundColor: customLightColor,
              onDelete: () {},
              onClear: () {},
              onSpeak: () {},
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(customLightColor));

      // Token text should adapt to dark color for contrast
      final textWidget = tester.widget<Text>(find.text('Fish'));
      expect(textWidget.style?.color, equals(ThemeData.dark().colorScheme.onSurface));
    });
  });

  group('ProfessionalColorPickerDialog TTS Bar Preview Tests', () {
    testWidgets('Renders sentence bar preview and applies selected color', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Color? appliedColor;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfessionalColorPickerDialog(
              title: 'Text-to-Speech Bar Colour',
              subtitle: 'Pick a colour for the sentence bar',
              initialColor: const Color(0xFFF5F5F5),
              defaultColor: const Color(0xFFF5F5F5),
              previewType: ColorPickerPreviewType.ttsBarPreview,
              onApply: (c) => appliedColor = c,
            ),
          ),
        ),
      );

      // Verify header and preview exist
      expect(find.text('Text-to-Speech Bar Colour'), findsOneWidget);
      expect(find.text('Pick a colour for the sentence bar'), findsOneWidget);
      expect(find.byKey(const ValueKey('tts_bar_preview_container')), findsOneWidget);
      expect(find.text('Elephant'), findsOneWidget);
      expect(find.text('Fish'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      // Tap Sky Blue preset
      final skyBlueFinder = find.bySemanticsLabel('Preset colour Sky Blue');
      expect(skyBlueFinder, findsOneWidget);
      await tester.tap(skyBlueFinder);
      await tester.pump();

      // Tap Apply
      final applyFinder = find.text('Apply');
      await tester.ensureVisible(applyFinder);
      await tester.tap(applyFinder);
      await tester.pump();

      expect(appliedColor, equals(const Color(0xFF42A5F5)));
    });

    testWidgets('Reset button reverts to default color', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Color? appliedColor;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfessionalColorPickerDialog(
              title: 'Text-to-Speech Bar Colour',
              subtitle: 'Pick a colour for the sentence bar',
              initialColor: const Color(0xFF42A5F5), // initially blue
              defaultColor: const Color(0xFFF5F5F5), // default light
              previewType: ColorPickerPreviewType.ttsBarPreview,
              onApply: (c) => appliedColor = c,
            ),
          ),
        ),
      );

      // Tap Reset
      final resetFinder = find.text('Reset');
      expect(resetFinder, findsOneWidget);
      await tester.ensureVisible(resetFinder);
      await tester.tap(resetFinder);
      await tester.pump();

      // Tap Apply
      final applyFinder = find.text('Apply');
      await tester.ensureVisible(applyFinder);
      await tester.tap(applyFinder);
      await tester.pump();

      expect(appliedColor, equals(const Color(0xFFF5F5F5)));
    });
  });

  group('HomeDrawer Settings UI Row Tests', () {
    testWidgets('Displays Text-to-Speech Bar Colour row below Board Background Color', (tester) async {
      bool pickTtsBarColorCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: HomeDrawer(
              selectedCategory: 'All',
              currentLanguageLabel: 'English',
              gridColumns: 2,
              visibleCardsLabel: 'All cards',
              isEditMode: false,
              showTtsInput: true,
              orientationLabel: 'Portrait',
              fullScreen: true,
              headerColor: Colors.blue,
              headerTextColor: Colors.white,
              hideTtsText: false,
              useImageOverlayLabel: true,
              applyTextColorToCards: false,
              isDarkMode: false,
              isColorBlindMode: false,
              primaryColorSwatch: Colors.blue,
              textColorSwatch: Colors.white,
              backgroundColorSwatch: Colors.white,
              ttsBarColorSwatch: const Color(0xFFEDE5F8),
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
              onPickTtsBarColor: () {
                pickTtsBarColorCalled = true;
              },
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
            body: const SizedBox.shrink(),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Scroll to Appearance & Theme section
      final ttsBarRow = find.text('Text-to-Speech Bar Colour');
      await tester.scrollUntilVisible(
        ttsBarRow,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(ttsBarRow, findsOneWidget);
      expect(find.text('Customise the sentence bar background'), findsOneWidget);

      // Tap row to verify callback
      await tester.tap(ttsBarRow);
      await tester.pump();
      expect(pickTtsBarColorCalled, isTrue);
    });
  });

  group('TTS Bar Colour Persistence & Backup Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Independent Normal and Dark mode SharedPreferences persistence', () async {
      final prefs = await SharedPreferences.getInstance();

      // Normal mode custom color
      const customLight = 0xFFDFEFFA;
      // Dark mode custom color
      const customDark = 0xFF2A2D34;

      await prefs.setInt('ttsBarColorLight', customLight);
      await prefs.setInt('ttsBarColorDark', customDark);

      // Verify each mode is stored independently
      expect(prefs.getInt('ttsBarColorLight'), equals(customLight));
      expect(prefs.getInt('ttsBarColorDark'), equals(customDark));

      // Updating light mode does not overwrite dark mode
      const updatedLight = 0xFFDFF2E4;
      await prefs.setInt('ttsBarColorLight', updatedLight);
      expect(prefs.getInt('ttsBarColorLight'), equals(updatedLight));
      expect(prefs.getInt('ttsBarColorDark'), equals(customDark));

      // Removing/resetting dark mode does not affect light mode
      await prefs.remove('ttsBarColorDark');
      expect(prefs.getInt('ttsBarColorLight'), equals(updatedLight));
      expect(prefs.getInt('ttsBarColorDark'), isNull);
    });

    test('Backup settings map serialization and deserialization', () {
      const customLight = 0xFFEDE5F8;
      const customDark = 0xFF1E222A;

      // Simulated serialization
      final settings = <String, dynamic>{
        'ttsBarColorLight': customLight,
        'ttsBarColorDark': customDark,
        'ttsBarColor': customLight,
      };

      // Simulated deserialization
      int? restoredLight;
      int? restoredDark;

      final rawLight = settings['ttsBarColorLight'] ?? settings['ttsBarColor'];
      if (rawLight is num) restoredLight = rawLight.toInt();

      final rawDark = settings['ttsBarColorDark'];
      if (rawDark is num) restoredDark = rawDark.toInt();

      expect(restoredLight, equals(customLight));
      expect(restoredDark, equals(customDark));
    });

    test('Legacy backup without TTS bar keys deserializes cleanly without errors', () {
      final legacySettings = <String, dynamic>{
        'gridColumns': 2,
        'themePrimaryColor': 0xFF0277BD,
        'themeBackgroundColor': 0xFFFFFFFF,
      };

      int? restoredLight;
      int? restoredDark;

      final rawLight = legacySettings['ttsBarColorLight'] ?? legacySettings['ttsBarColor'];
      if (rawLight is num) restoredLight = rawLight.toInt();

      final rawDark = legacySettings['ttsBarColorDark'];
      if (rawDark is num) restoredDark = rawDark.toInt();

      expect(restoredLight, isNull);
      expect(restoredDark, isNull);
    });
  });
}
