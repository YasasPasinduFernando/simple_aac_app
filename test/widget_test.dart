import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:simple_aac_app/main.dart';
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
}
