import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/utils/theme_accessibility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('dark_mode_contrast_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;
    SharedPreferences.setMockInitialValues({});
    HomePage.initialCardsForTesting = [
      AACCard(
        id: 'test_card_1',
        label: 'Test Card',
        colorValue: 0xFFFFEB3B,
      ),
    ];
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.speakPerformer = (_) async {};
    await ThemeAccessibility.setDarkMode(false);
  });

  tearDown(() {
    CardStorageService.resetTestHooks();
    HomePage.initialCardsForTesting = null;
    HomePage.enableTtsInit = true;
    HomePage.enableTutorialInit = true;
    HomePage.speakPerformer = null;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('WCAG Contrast Ratio Calculation', () {
    test('computes correct contrast ratio for black and white', () {
      final ratio = ThemeAccessibility.contrastRatio(Colors.black, Colors.white);
      expect(ratio, closeTo(21.0, 0.5));
    });

    test('detects low contrast between bright orange and Warm Ivory', () {
      const orange = Color(0xFFFF6D00);
      const warmIvory = Color(0xFFF4F1EB);
      final ratio = ThemeAccessibility.contrastRatio(orange, warmIvory);
      expect(ratio, lessThan(3.0));
    });

    test('detects high contrast between dark charcoal and Warm Ivory', () {
      const charcoal = Color(0xFF252B32);
      const warmIvory = Color(0xFFF4F1EB);
      final ratio = ThemeAccessibility.contrastRatio(charcoal, warmIvory);
      expect(ratio, greaterThan(10.0));
    });

    test('detects high contrast between white and dark slate surface', () {
      const darkSlate = Color(0xFF1E293B);
      final ratio = ThemeAccessibility.contrastRatio(Colors.white, darkSlate);
      expect(ratio, greaterThan(10.0));
    });
  });

  group('Dark Mode Card Footer & Label Background Color', () {
    testWidgets('Overlay OFF in Dark Mode uses globalLabelBg without 60% slate-grey lerp',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'darkMode': true,
        'showCardLabels': true,
        'useImageOverlayLabel': false,
        'globalCardLabelBackgroundColor': const Color(0xFFF4F1EB).value,
      });

      await ThemeAccessibility.initDarkMode();
      expect(ThemeAccessibility.darkModeNotifier.value, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasWarmIvoryFooter = containers.any((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          return dec.color == const Color(0xFFF4F1EB);
        }
        return false;
      });

      expect(hasWarmIvoryFooter, isTrue,
          reason: 'Card footer in Dark Mode with Overlay OFF must preserve Warm Ivory #F4F1EB');

      // Ensure NO footer is forced to the old muddy slate-grey #717487 / #737981
      final hasOldMutilatedGreyFooter = containers.any((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration && dec.color != null) {
          final cVal = dec.color!;
          return (cVal.red >= 110 && cVal.red <= 120) &&
              (cVal.green >= 116 && cVal.green <= 126) &&
              (cVal.blue >= 124 && cVal.blue <= 134);
        }
        return false;
      });

      expect(hasOldMutilatedGreyFooter, isFalse,
          reason: 'No footer should be converted to the old forced slate-grey lerp');
    });

    testWidgets('Custom global label background color is respected in Dark Mode',
        (tester) async {
      const customYellowBg = Color(0xFFFFF9C4); // Pale yellow
      SharedPreferences.setMockInitialValues({
        'darkMode': true,
        'showCardLabels': true,
        'useImageOverlayLabel': false,
        'globalCardLabelBackgroundColor': customYellowBg.value,
      });

      await ThemeAccessibility.initDarkMode();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasCustomYellowFooter = containers.any((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          return dec.color == customYellowBg;
        }
        return false;
      });

      expect(hasCustomYellowFooter, isTrue,
          reason: 'Custom global label background color must be respected in Dark Mode');
    });

    testWidgets('Inaccessible custom text color safely falls back to readable text',
        (tester) async {
      const lowContrastOrange = Color(0xFFFF6D00);
      const warmIvory = Color(0xFFF4F1EB);
      SharedPreferences.setMockInitialValues({
        'darkMode': true,
        'showCardLabels': true,
        'useImageOverlayLabel': false,
        'globalCardLabelBackgroundColor': warmIvory.value,
        'applyTextColorToCards': true,
        'cardTextColor': lowContrastOrange.value,
      });

      await ThemeAccessibility.initDarkMode();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final hasReadableDarkCardLabel = textWidgets.any((t) {
        return t.style?.color == const Color(0xFF252B32);
      });

      expect(hasReadableDarkCardLabel, isTrue,
          reason: 'Card text should fall back to readable #252B32 when chosen color has < 3:1 contrast');
    });

    testWidgets('High-contrast custom text color is preserved when contrast >= 3:1',
        (tester) async {
      const highContrastNavy = Color(0xFF0D47A1); // Deep Navy
      const warmIvory = Color(0xFFF4F1EB);
      SharedPreferences.setMockInitialValues({
        'darkMode': true,
        'showCardLabels': true,
        'useImageOverlayLabel': false,
        'globalCardLabelBackgroundColor': warmIvory.value,
        'applyTextColorToCards': true,
        'cardTextColor': highContrastNavy.value,
      });

      await ThemeAccessibility.initDarkMode();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final hasNavyText = textWidgets.any((t) {
        return t.style?.color == highContrastNavy;
      });

      expect(hasNavyText, isTrue,
          reason: 'High-contrast custom text color should be preserved when contrast >= 3:1');
    });
  });
}
