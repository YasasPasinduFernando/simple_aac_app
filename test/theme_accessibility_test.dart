import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/utils/theme_accessibility.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';
import 'package:simple_aac_app/widgets/styled_dialog_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Dark mode preference initializes and persists cleanly', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await ThemeAccessibility.initDarkMode(), isFalse);

    await ThemeAccessibility.setDarkMode(true);
    expect(ThemeAccessibility.darkModeNotifier.value, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(ThemeAccessibility.darkModePrefKey), isTrue);
  });

  test('Color-blind safe mode maps red and green into distinguishable Okabe-Ito colors with legible text', () {
    final redSafe = ThemeAccessibility.resolveCardSurface(
      Colors.red,
      isDarkMode: false,
      isColorBlindMode: true,
    );
    final greenSafe = ThemeAccessibility.resolveCardSurface(
      Colors.green,
      isDarkMode: false,
      isColorBlindMode: true,
    );
    final yellowSafe = ThemeAccessibility.resolveCardSurface(
      Colors.yellow,
      isDarkMode: false,
      isColorBlindMode: true,
    );

    expect(redSafe, const Color(0xFFD55E00));
    expect(greenSafe, const Color(0xFF009E73));
    expect(yellowSafe, const Color(0xFFF0E442));

    // Yellow background must select dark text for accessible contrast
    final yellowLabel = ThemeAccessibility.resolveCardTextColor(
      yellowSafe,
      isDarkMode: false,
      isColorBlindMode: true,
      applyCustomTextColor: false,
      customTextColor: Colors.white,
    );
    expect(yellowLabel, const Color(0xFF111827));

    // Normal mode preserves user card color unchanged
    expect(
      ThemeAccessibility.resolveCardSurface(
        Colors.brown,
        isDarkMode: false,
        isColorBlindMode: false,
      ),
      Colors.brown,
    );
  });

  testWidgets('HomeDrawer renders Dark Mode toggle and Color Vision radio buttons without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: HomeDrawer(
            selectedCategory: 'All',
            currentLanguageLabel: 'English',
            gridColumns: 2,
            visibleCardsLabel: 'All cards',
            isEditMode: false,
            showTtsInput: true,
            orientationLabel: 'Portrait',
            fullScreen: true,
            headerColor: const Color(0xFF1B263B),
            headerTextColor: Colors.white,
            hideTtsText: false,
            useImageOverlayLabel: false,
            applyTextColorToCards: false,
            isDarkMode: true,
            isColorBlindMode: true,
            primaryColorSwatch: const Color(0xFF0277BD),
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
            onManagePermissions: () {},
            onShowAbout: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.text('Dark Mode'), 200);
    expect(find.text('Dark Mode'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Color-Blind Safe Mode'), 200);
    expect(tester.takeException(), isNull);
    expect(find.text('Normal (Custom Colors)'), findsOneWidget);
    expect(find.text('Color-Blind Safe Mode'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('App Permissions'), 200);
    expect(find.text('App Permissions'), findsOneWidget);
  });

  testWidgets('StyledDialogHeader and DialogOptionTile render cleanly in narrow dialog',
      (tester) async {
    tester.view.physicalSize = const Size(320, 560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: AlertDialog(
            title: const StyledDialogHeader(
              icon: Icons.screen_rotation_rounded,
              title: 'Screen Orientation',
              subtitle: 'Choose preferred layout direction',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DialogOptionTile(
                    icon: Icons.stay_current_portrait_rounded,
                    title: 'Portrait',
                    subtitle: 'Tall card grid with top toolbar',
                    selected: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Screen Orientation'), findsOneWidget);
    expect(find.text('Portrait'), findsOneWidget);
  });
}
