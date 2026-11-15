import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/utils/theme_accessibility.dart';
import 'package:simple_aac_app/widgets/color_vision_dialog.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';
import 'package:simple_aac_app/widgets/professional_color_picker_dialog.dart';
import 'package:simple_aac_app/widgets/visible_cards_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeAccessibility Color Vision Deficiency Models', () {
    test('init and persist color blind settings', () async {
      await ThemeAccessibility.saveColorBlindSettings(
        type: 'deuteranomaly',
        borderWidth: 3.5,
        borderColor: 'blue',
        boldText: true,
      );

      expect(ThemeAccessibility.colorBlindType, 'deuteranomaly');
      expect(ThemeAccessibility.colorBlindBorderWidth, 3.5);
      expect(ThemeAccessibility.colorBlindBorderColor, 'blue');
      expect(ThemeAccessibility.colorBlindBoldText, true);

      // Reset and reload from prefs
      ThemeAccessibility.colorBlindType = 'universal';
      ThemeAccessibility.colorBlindBorderWidth = 2.0;
      await ThemeAccessibility.initColorBlindSettings();

      expect(ThemeAccessibility.colorBlindType, 'deuteranomaly');
      expect(ThemeAccessibility.colorBlindBorderWidth, 3.5);
      expect(ThemeAccessibility.colorBlindBorderColor, 'blue');
    });

    test('resolveCardSurface maps distinct colors per deficiency type', () {
      const red = Color(0xFFFF0000);
      const green = Color(0xFF00FF00);
      const blue = Color(0xFF0000FF);

      // Normal mode leaves color untouched
      expect(
        ThemeAccessibility.resolveCardSurface(red, isDarkMode: false, isColorBlindMode: false),
        red,
      );

      // Deuteranomaly shifts green to teal/cyan
      final deutGreen = ThemeAccessibility.resolveCardSurface(
        green,
        isDarkMode: false,
        isColorBlindMode: true,
        type: 'deuteranomaly',
      );
      expect(deutGreen, const Color(0xFF009E73));

      // Protanomaly shifts red to bright warm amber
      final protRed = ThemeAccessibility.resolveCardSurface(
        red,
        isDarkMode: false,
        isColorBlindMode: true,
        type: 'protanomaly',
      );
      expect(protRed, const Color(0xFFF59E0B));

      // Tritanomaly maps blue to very deep navy
      final tritBlue = ThemeAccessibility.resolveCardSurface(
        blue,
        isDarkMode: false,
        isColorBlindMode: true,
        type: 'tritanomaly',
      );
      expect(tritBlue, const Color(0xFF1E1B4B));

      // Monochrome maps to luminance tiers
      final monoRed = ThemeAccessibility.resolveCardSurface(
        red,
        isDarkMode: false,
        isColorBlindMode: true,
        type: 'monochrome',
      );
      expect(monoRed, isA<Color>());
    });

    test('resolveCardBorderColor and resolveCardBorderWidth respect settings', () {
      expect(
        ThemeAccessibility.resolveCardBorderWidth(isColorBlindMode: false),
        1.0,
      );
      expect(
        ThemeAccessibility.resolveCardBorderWidth(isColorBlindMode: true, width: 4.0),
        4.0,
      );

      expect(
        ThemeAccessibility.resolveCardBorderColor(
          isDarkMode: false,
          isColorBlindMode: true,
          colorOption: 'blue',
        ),
        const Color(0xFF0072B2),
      );

      expect(
        ThemeAccessibility.resolveCardBorderColor(
          isDarkMode: false,
          isColorBlindMode: true,
          colorOption: 'yellow',
        ),
        const Color(0xFFF0E442),
      );

      expect(
        ThemeAccessibility.resolveCardBorderColor(
          isDarkMode: false,
          isColorBlindMode: true,
          colorOption: 'black',
        ),
        Colors.black,
      );
    });

    test('resolveCardTextShadow adds high contrast shadow when bold enabled', () {
      final shadows = ThemeAccessibility.resolveCardTextShadow(
        cardSurface: const Color(0xFFFFF59D),
        isColorBlindMode: true,
        isBold: true,
      );
      expect(shadows, isNotNull);
      expect(shadows!.isNotEmpty, isTrue);

      final noShadows = ThemeAccessibility.resolveCardTextShadow(
        cardSurface: const Color(0xFFFFF59D),
        isColorBlindMode: false,
        isBold: true,
      );
      expect(noShadows, isNull);
    });
  });

  group('ColorVisionDialog Widget Tests', () {
    testWidgets('renders preview panel, deficiency presets, slider and applies', (tester) async {
      bool? appliedEnabled;
      String? appliedType;
      double? appliedWidth;
      String? appliedColor;
      bool? appliedBold;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorVisionDialog(
              initialColorBlind: true,
              initialType: 'universal',
              initialBorderWidth: 2.5,
              initialBorderColor: 'auto',
              initialBoldText: true,
              isDarkMode: false,
              onApply: (enabled, type, width, color, bold) {
                appliedEnabled = enabled;
                appliedType = type;
                appliedWidth = width;
                appliedColor = color;
                appliedBold = bold;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & Live preview
      expect(find.text('Color Vision Support'), findsOneWidget);
      expect(find.text('LIVE CARD PREVIEW'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);

      // Verify presets are displayed
      expect(find.text('Deuteranomaly (Red-Green)'), findsOneWidget);
      expect(find.text('Protanomaly (Red-Green)'), findsOneWidget);
      expect(find.text('Tritanomaly (Blue-Yellow)'), findsOneWidget);

      // Scroll into view and select Deuteranomaly
      await tester.ensureVisible(find.text('Deuteranomaly (Red-Green)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deuteranomaly (Red-Green)'));
      await tester.pumpAndSettle();

      // Scroll into view and tap Apply
      await tester.ensureVisible(find.text('Apply'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(appliedEnabled, true);
      expect(appliedType, 'deuteranomaly');
      expect(appliedWidth, 2.5);
      expect(appliedColor, 'auto');
      expect(appliedBold, true);
    });

    testWidgets('Reset button restores default settings in ColorVisionDialog', (tester) async {
      bool? appliedEnabled;
      String? appliedType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorVisionDialog(
              initialColorBlind: true,
              initialType: 'deuteranomaly',
              initialBorderWidth: 4.5,
              initialBorderColor: 'yellow',
              initialBoldText: false,
              isDarkMode: false,
              onApply: (enabled, type, width, color, bold) {
                appliedEnabled = enabled;
                appliedType = type;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Reset
      await tester.ensureVisible(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.ensureVisible(find.text('Apply'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Should be restored to defaults
      expect(appliedEnabled, false);
      expect(appliedType, 'universal');
    });
  });

  group('ColorVisionPreviewChip Widget Tests', () {
    testWidgets('renders 3 preview tiles in normal and color-blind modes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ColorVisionPreviewChip(isColorBlind: false, isDarkMode: false),
                ColorVisionPreviewChip(isColorBlind: true, isDarkMode: false),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ColorVisionPreviewChip), findsNWidgets(2));
    });
  });

  group('Dialog Reset Buttons Verification', () {
    testWidgets('ProfessionalColorPickerDialog Reset restores defaultColor', (tester) async {
      Color? appliedColor;
      const defaultCol = Color(0xFF0267C1);
      const customCol = Color(0xFFFF0000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfessionalColorPickerDialog(
              title: 'App color',
              subtitle: 'Pick a color',
              initialColor: customCol,
              defaultColor: defaultCol,
              onApply: (c) => appliedColor = c,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Reset
      await tester.ensureVisible(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.ensureVisible(find.text('Apply'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(appliedColor, defaultCol);
    });

    testWidgets('VisibleCardsDialog Reset clears selection to show all', (tester) async {
      Set<String>? submitted;
      final sampleCards = [
        AACCard(id: 'c1', label: 'One', colorValue: 0xFFFFFFFF),
        AACCard(id: 'c2', label: 'Two', colorValue: 0xFFFFFFFF),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: sampleCards,
              currentLanguage: 'en',
              initialSelectedIds: const {'c1'},
              onSubmit: (ids) => submitted = ids,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Reset
      await tester.ensureVisible(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Tap Done
      await tester.ensureVisible(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Cleared set means show all cards
      expect(submitted, isEmpty);
    });
  });
}
