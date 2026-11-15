import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestDrawer({
    Brightness brightness = Brightness.light,
    Color headerColor = const Color(0xFF0267C1),
    Color primaryColorSwatch = const Color(0xFF0267C1),
    Color textColorSwatch = const Color(0xFF111827),
    Color backgroundColorSwatch = const Color(0xFFFFF9E6),
    Color cardTextColorSwatch = const Color(0xFF111827),
    bool isDarkMode = false,
    bool isColorBlindMode = false,
    VoidCallback? onPickPrimaryColor,
    VoidCallback? onPickTextColor,
    VoidCallback? onPickBackgroundColor,
    VoidCallback? onPickCardTextColor,
    String cardTextScaleLabel = 'Standard (100%)',
    VoidCallback? onShowCardTextSize,
    bool isExpanded = false,
    ValueChanged<bool>? onToggleExpanded,
    ValueChanged<bool>? onToggleDarkMode,
    ValueChanged<bool>? onChangeColorBlindMode,
  }) {
    final themeData = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0267C1)),
          );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeData,
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
          headerColor: headerColor,
          headerTextColor: Colors.white,
          hideTtsText: false,
          useImageOverlayLabel: true,
          applyTextColorToCards: false,
          isDarkMode: isDarkMode,
          isColorBlindMode: isColorBlindMode,
          primaryColorSwatch: primaryColorSwatch,
          textColorSwatch: textColorSwatch,
          backgroundColorSwatch: backgroundColorSwatch,
          cardTextColorSwatch: cardTextColorSwatch,
          isOnlineEnabled: true,
          onToggleOnline: (_) {},
          onToggleDarkMode: onToggleDarkMode ?? (_) {},
          onChangeColorBlindMode: onChangeColorBlindMode ?? (_) {},
          onSelectCategory: () {},
          onAddCategory: () {},
          onToggleEdit: () {},
          onToggleTtsInput: () {},
          onToggleTtsText: () {},
          onToggleCardImageLabel: () {},
          onToggleApplyTextColorToCards: () {},
          onChangeOrientation: () {},
          onPickPrimaryColor: onPickPrimaryColor ?? () {},
          onPickTextColor: onPickTextColor ?? () {},
          onPickBackgroundColor: onPickBackgroundColor ?? () {},
          onPickCardTextColor: onPickCardTextColor ?? () {},
          onShowTtsBarSize: () {},
          onToggleFullScreen: () {},
          onShowLanguage: () {},
          onShowGrid: () {},
          onShowVisibleCount: () {},
          cardTextScaleLabel: cardTextScaleLabel,
          onShowCardTextSize: onShowCardTextSize,
          onBackup: () {},
          onRestore: () {},
          onResetSettings: () {},
          onShowAbout: () {},
          isExpanded: isExpanded,
          onToggleExpanded: onToggleExpanded,
        ),
      ),
    );
  }

  testWidgets('HomeDrawer header renders branded icon, title, country and version pill',
      (tester) async {
    tester.view.physicalSize = const Size(384, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestDrawer());
    await tester.pumpAndSettle();

    expect(find.text('Simple AAC'), findsWidgets);
    expect(find.text('Sri Lanka'), findsOneWidget);
    expect(find.text('v1.1.0'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_rounded), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Appearance & Theme section renders live previews and triggers color callbacks',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var tappedPrimary = false;
    var tappedText = false;
    var tappedBackground = false;
    var tappedCardText = false;

    await tester.pumpWidget(
      buildTestDrawer(
        primaryColorSwatch: const Color(0xFF0267C1),
        textColorSwatch: const Color(0xFFE91E63),
        backgroundColorSwatch: const Color(0xFFFFF9E6),
        cardTextColorSwatch: const Color(0xFF111827),
        onPickPrimaryColor: () => tappedPrimary = true,
        onPickTextColor: () => tappedText = true,
        onPickBackgroundColor: () => tappedBackground = true,
        onPickCardTextColor: () => tappedCardText = true,
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down to Appearance & Theme section
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();

    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Switch on for full dark theme'), findsOneWidget);

    // Verify Primary App Color row
    expect(find.text('Primary App Color'), findsOneWidget);
    expect(find.text('App bars, headers & key UI'), findsOneWidget);
    await tester.tap(find.text('Primary App Color'));
    await tester.pump();
    expect(tappedPrimary, isTrue);

    // Verify Global Text Color row
    expect(find.text('Global Text Color'), findsOneWidget);
    expect(find.text('Text across the entire app'), findsOneWidget);
    expect(find.text('Aa'), findsOneWidget);
    expect(find.text('Sample Text'), findsOneWidget);
    await tester.tap(find.text('Global Text Color'));
    await tester.pump();
    expect(tappedText, isTrue);

    // Verify Board Background Color row
    expect(find.text('Board Background Color'), findsOneWidget);
    expect(find.text('Background of communication boards'), findsOneWidget);
    await tester.tap(find.text('Board Background Color'));
    await tester.pump();
    expect(tappedBackground, isTrue);

    // Verify Card Text Color row
    expect(find.text('Card Text Color'), findsOneWidget);
    expect(find.text('Color of text on AAC cards'), findsOneWidget);
    await tester.tap(find.text('Card Text Color'));
    await tester.pump();
    expect(tappedCardText, isTrue);

    // Scroll further down to Color Vision Support
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(find.text('Color Vision Support'), findsOneWidget);
    expect(find.text('Normal (Custom Colors)'), findsOneWidget);
    expect(find.text('Color-Blind Safe Mode'), findsOneWidget);
  });

  testWidgets('Color Vision Support toggles mode cleanly on tap',
      (tester) async {
    tester.view.physicalSize = const Size(384, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool isColorBlind = false;
    bool? selectedMode;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return buildTestDrawer(
            isColorBlindMode: isColorBlind,
            onChangeColorBlindMode: (v) {
              setState(() {
                isColorBlind = v;
              });
              selectedMode = v;
            },
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Color-Blind Safe Mode'), 200);
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Color-Blind Safe Mode'));
    await tester.pumpAndSettle();
    expect(selectedMode, isTrue);

    await tester.tap(find.text('Normal (Custom Colors)'));
    await tester.pumpAndSettle();
    expect(selectedMode, isFalse);
  });

  testWidgets('HomeDrawer renders without overflow on narrow 320px screen across font scalers',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [320.0, 384.0]) {
      for (final scale in [1.0, 1.4, 1.8]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: TextScaler.linear(scale),
            ),
            child: buildTestDrawer(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'RenderFlex overflow occurred on width=$width scale=$scale');

        // Scroll fully down and verify no overflows throughout
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('Render high-res screenshots for light and dark drawer inspection',
      (tester) async {
    tester.view.physicalSize = const Size(384, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final lightKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: lightKey,
        child: buildTestDrawer(
          brightness: Brightness.light,
          primaryColorSwatch: const Color(0xFF0267C1),
          textColorSwatch: const Color(0xFF111827),
          backgroundColorSwatch: const Color(0xFFFFF9E6),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll so Appearance & Theme is right in view
    await tester.scrollUntilVisible(find.text('Dark Mode'), 200);
    await tester.pumpAndSettle();

    final lightBoundary =
        lightKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final img = await lightBoundary.toImage(pixelRatio: 2.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final outDir = Directory('/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013');
      File('${outDir.path}/drawer_rendered_light.png')
          .writeAsBytesSync(byteData!.buffer.asUint8List());
    });

    // Dark Mode Capture
    final darkKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: darkKey,
        child: buildTestDrawer(
          brightness: Brightness.dark,
          headerColor: const Color(0xFF1E293B),
          primaryColorSwatch: const Color(0xFF0277BD),
          textColorSwatch: Colors.white,
          backgroundColorSwatch: const Color(0xFF263238),
          isDarkMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Dark Mode'), 200);
    await tester.pumpAndSettle();

    final darkBoundary =
        darkKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final img = await darkBoundary.toImage(pixelRatio: 2.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final outDir = Directory('/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013');
      File('${outDir.path}/drawer_rendered_dark.png')
          .writeAsBytesSync(byteData!.buffer.asUint8List());
    });
  });

  testWidgets('Toggling switch options in HomePage endDrawer does not close the drawer',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    HomePage.enableTtsInit = false;
    HomePage.speakPerformer = (_) async {};

    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() {
      HomePage.enableTtsInit = true;
      HomePage.speakPerformer = null;
    });

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    // Open endDrawer
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openEndDrawer();
    await tester.pumpAndSettle();

    expect(find.byType(HomeDrawer), findsOneWidget);

    // Tap 'Text on Card Image'
    await tester.scrollUntilVisible(find.text('Text on Card Image'), 100);
    await tester.tap(find.text('Text on Card Image'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Drawer must remain open!
    expect(find.byType(HomeDrawer), findsOneWidget);

    // Tap 'Custom Card Text Color'
    await tester.scrollUntilVisible(find.text('Custom Card Text Color'), 100);
    await tester.tap(find.text('Custom Card Text Color'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Drawer must still remain open!
    expect(find.byType(HomeDrawer), findsOneWidget);
  });

  testWidgets('Layout & Display section renders Card Text Size and triggers callback',
      (tester) async {
    tester.view.physicalSize = const Size(384, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool tappedCardTextSize = false;

    await tester.pumpWidget(
      buildTestDrawer(
        cardTextScaleLabel: 'Standard (100%)',
        onShowCardTextSize: () => tappedCardTextSize = true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Card Text Size'), 100);
    expect(find.text('Card Text Size'), findsOneWidget);
    expect(find.text('Standard (100%)'), findsOneWidget);

    await tester.tap(find.text('Card Text Size'), warnIfMissed: false);
    await tester.pump();
    expect(tappedCardTextSize, isTrue);
  });

  testWidgets('HomeDrawer expand button toggles between collapsed and expanded state',
      (tester) async {
    tester.view.physicalSize = const Size(384, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool expanded = false;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return buildTestDrawer(
            isExpanded: expanded,
            onToggleExpanded: (val) => setState(() => expanded = val),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // In collapsed mode, button tooltip is "Expand to full screen"
    final expandBtn = find.byTooltip('Expand to full screen');
    expect(expandBtn, findsOneWidget);
    await tester.tap(expandBtn);
    await tester.pumpAndSettle();

    expect(expanded, isTrue);
    // In expanded mode, button tooltip is "Collapse drawer"
    expect(find.byTooltip('Collapse drawer'), findsOneWidget);
  });

  testWidgets('HomeDrawer horizontal drag gestures toggle expand and collapse',
      (tester) async {
    tester.view.physicalSize = const Size(384, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool expanded = false;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return buildTestDrawer(
            isExpanded: expanded,
            onToggleExpanded: (val) => setState(() => expanded = val),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // Drag left to expand
    await tester.drag(find.text('Simple AAC'), const Offset(-60, 0));
    await tester.pumpAndSettle();
    expect(expanded, isTrue);

    // Drag right to collapse
    await tester.drag(find.text('Simple AAC'), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(expanded, isFalse);
  });
}
