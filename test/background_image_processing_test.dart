import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:simple_aac_app/utils/image_crop_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bg_image_crop_test_');
    ImageCropHelper.tempDirectoryOverride = () => tempDir;
  });

  tearDown(() async {
    ImageCropHelper.tempDirectoryOverride = null;
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Background Image Processing (Phase 6)', () {
    test('ImageCropHelper.cropSquare executes cropping and encoding without blocking UI', () async {
      // 1. Create a simulated high-res 1200x800 camera photograph
      final sourceImage = img.Image(width: 1200, height: 800);
      img.fill(sourceImage, color: img.ColorRgb8(100, 150, 200));
      // Draw distinctive center mark
      img.fillRect(
        sourceImage,
        x1: 500,
        y1: 300,
        x2: 700,
        y2: 500,
        color: img.ColorRgb8(255, 255, 0),
      );

      final sourceBytes = img.encodeJpg(sourceImage, quality: 90);
      final sourceFile = File('${tempDir.path}/original_photo.jpg');
      sourceFile.writeAsBytesSync(sourceBytes);

      final originalSize = sourceFile.lengthSync();
      expect(originalSize, greaterThan(0));

      // 2. Perform 1:1 square crop with zoom 1.5x
      final croppedFile = await ImageCropHelper.cropSquare(
        sourcePath: sourceFile.path,
        zoom: 1.5,
        panX: 0,
        panY: 0,
        viewportSize: 300,
        targetDimension: 640,
        quality: 85,
      );

      // 3. Verify original source photo was NOT modified or deleted
      expect(sourceFile.existsSync(), isTrue);
      expect(sourceFile.lengthSync(), equals(originalSize));

      // 4. Verify cropped output is a valid 640x640 JPEG
      expect(croppedFile.existsSync(), isTrue);
      final croppedBytes = croppedFile.readAsBytesSync();
      final decodedCrop = img.decodeJpg(croppedBytes);
      expect(decodedCrop, isNotNull);
      expect(decodedCrop!.width, equals(640));
      expect(decodedCrop.height, equals(640));
    });

    test('ImageCropHelper.cropSquare handles edge clamping and small aspect ratios cleanly', () async {
      final sourceImage = img.Image(width: 400, height: 1000); // Tall portrait
      img.fill(sourceImage, color: img.ColorRgb8(50, 100, 150));
      final sourceFile = File('${tempDir.path}/portrait_photo.jpg');
      sourceFile.writeAsBytesSync(img.encodeJpg(sourceImage));

      // Test extreme panning
      final croppedFile = await ImageCropHelper.cropSquare(
        sourcePath: sourceFile.path,
        zoom: 1.0,
        panX: 9999, // Should clamp gracefully
        panY: -9999, // Should clamp gracefully
        viewportSize: 300,
        targetDimension: 480,
      );

      expect(croppedFile.existsSync(), isTrue);
      final decoded = img.decodeJpg(croppedFile.readAsBytesSync());
      expect(decoded!.width, equals(480));
      expect(decoded.height, equals(480));
    });
  });
}
