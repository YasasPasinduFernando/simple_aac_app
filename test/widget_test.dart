import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:simple_aac_app/main.dart';

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
}
