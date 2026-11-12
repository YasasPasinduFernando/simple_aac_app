import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/main.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/utils/card_image.dart';
import 'package:simple_aac_app/widgets/home_app_bar.dart';

void main() {
  test('AACApp is available', () {
    expect(const AACApp(), isA<StatelessWidget>());
  });

  test('ImagePickerAndroid photo picker configuration works', () {
    final androidPicker = ImagePickerAndroid();
    ImagePickerPlatform.instance = androidPicker;
    androidPicker.useAndroidPhotoPicker = true;
    expect(androidPicker.useAndroidPhotoPicker, isTrue);
  });

  testWidgets('HomeAppBar renders approved redesign with PIN, Simple AAC, and Menu',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool pinToggled = false;
    bool menuOpened = false;

    for (final showBack in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: HomeAppBar(
              title: 'Simple AAC',
              showBack: showBack,
              onBack: () {},
              showPin: true,
              isPinned: false,
              onTogglePin: () => pinToggled = true,
              isEditMode: false,
              showMenu: true,
              onOpenMenu: () => menuOpened = true,
              backgroundColor: const Color(0xFF0277BD),
              titleTextColor: Colors.white,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Simple AAC'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      if (showBack) {
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      }
    }

    // Verify interaction
    await tester.tap(find.byIcon(Icons.push_pin_outlined));
    expect(pinToggled, isTrue);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    expect(menuOpened, isTrue);
  });

  testWidgets(
      'HomeAppBar is responsive across narrow, standard (Galaxy A34), and wide screens with font scaling',
      (tester) async {
    // Test across small phone (320), Galaxy A34 width (384), large phone (480)
    for (final width in [320.0, 384.0, 480.0]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 700),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                appBar: HomeAppBar(
                  title: 'Simple AAC',
                  showBack: false,
                  onBack: () {},
                  showPin: true,
                  isPinned: false,
                  onTogglePin: () {},
                  isEditMode: false,
                  showMenu: true,
                  onOpenMenu: () {},
                  backgroundColor: const Color(0xFF0277BD),
                  titleTextColor: Colors.white,
                ),
                body: const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'Failed at width $width with text scale $scale');
        expect(find.text('Simple AAC'), findsOneWidget);
      }
    }
  });

  test('buildCardImage decodes assets and files with bounded cacheWidth and gaplessPlayback', () {
    final assetWidget = buildCardImage('assets/cards/hello.png', cacheWidth: 320);
    expect(assetWidget, isA<Image>());
    final img = assetWidget as Image;
    expect(img.gaplessPlayback, isTrue);
    expect(img.image, isA<ResizeImage>());

    final fileWidget = buildCardImage('/tmp/nonexistent.jpg');
    expect(fileWidget, isA<Image>());
    expect((fileWidget as Image).image, isA<ResizeImage>());
  });

  test('Switch theme provides distinct thumbColor from trackColor when selected in light and dark modes', () {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final theme = AACApp.buildTheme(brightness);
      final thumbColor = theme.switchTheme.thumbColor?.resolve({WidgetState.selected});
      final primary = theme.colorScheme.primary;
      final onPrimary = theme.colorScheme.onPrimary;

      expect(thumbColor, equals(onPrimary),
          reason: 'Selected thumbColor must be onPrimary for $brightness');
      expect(thumbColor, isNot(equals(primary)),
          reason: 'Selected thumbColor must not match primary track color for $brightness');
    }
  });

  testWidgets(
      'HomePage defaults useImageOverlayLabel to true on first install and restores it on settings reset',
      (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('aac_default_test_');
    addTearDown(() {
      CardStorageService.resetTestHooks();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });
    CardStorageService.docsDirectoryOverride = () async => tempDir;
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    final homeState = tester.state(find.byType(HomePage)) as dynamic;
    expect(homeState.useImageOverlayLabelForTesting, isTrue,
        reason: 'Clean install must default useImageOverlayLabel to true');

    // Manually toggle off and verify
    homeState.useImageOverlayLabelForTesting = false;
    expect(homeState.useImageOverlayLabelForTesting, isFalse);

    // Call reset settings and verify it is restored to true
    homeState.resetSettingsForTesting();
    await tester.pumpAndSettle();
    expect(homeState.useImageOverlayLabelForTesting, isTrue,
        reason: 'Reset settings must restore useImageOverlayLabel to true');
  });

  testWidgets('Render header snapshot for visual comparison', (tester) async {
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: 384,
              child: HomeAppBar(
                title: 'Simple AAC',
                showBack: false,
                onBack: () {},
                showPin: true,
                isPinned: false,
                onTogglePin: () {},
                isEditMode: false,
                showMenu: true,
                onOpenMenu: () {},
                backgroundColor: const Color(0xFF0277BD),
                titleTextColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary =
        boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      File('/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013/scratch/header_rendered_preview.png')
          .writeAsBytesSync(byteData!.buffer.asUint8List());
    });
  });
}
