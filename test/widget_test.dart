import 'dart:io';

import 'package:flutter/material.dart';
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

  testWidgets('HomeAppBar renders pin and back buttons cleanly without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final showBack in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: HomeAppBar(
              title: 'SL AAC',
              showBack: showBack,
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
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
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
}
