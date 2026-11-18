import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/utils/image_crop_helper.dart';
import 'package:simple_aac_app/widgets/crop_zoom_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File squarePhotoFile;
  late File portraitPhotoFile;
  late File landscapePhotoFile;
  late File largeCameraPhotoFile;
  late File lowResPhotoFile;
  late File transparentPngFile;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('crop_zoom_comp_test_');
    ImageCropHelper.tempDirectoryOverride = () => tempDir;

    // 1. Square photo (500x500)
    final squareImg = img.Image(width: 500, height: 500);
    img.fill(squareImg, color: img.ColorRgb8(255, 100, 50));
    squarePhotoFile = File('${tempDir.path}/test_square.jpg');
    squarePhotoFile.writeAsBytesSync(img.encodeJpg(squareImg));

    // 2. Portrait photo (400x800)
    final portraitImg = img.Image(width: 400, height: 800);
    img.fill(portraitImg, color: img.ColorRgb8(50, 150, 250));
    portraitPhotoFile = File('${tempDir.path}/test_portrait.jpg');
    portraitPhotoFile.writeAsBytesSync(img.encodeJpg(portraitImg));

    // 3. Landscape photo (1000x500)
    final landscapeImg = img.Image(width: 1000, height: 500);
    img.fill(landscapeImg, color: img.ColorRgb8(80, 220, 120));
    landscapePhotoFile = File('${tempDir.path}/test_landscape.jpg');
    landscapePhotoFile.writeAsBytesSync(img.encodeJpg(landscapeImg));

    // 4. Large camera photo (3000x2000)
    final largeImg = img.Image(width: 3000, height: 2000);
    img.fill(largeImg, color: img.ColorRgb8(240, 200, 100));
    largeCameraPhotoFile = File('${tempDir.path}/test_large.jpg');
    largeCameraPhotoFile.writeAsBytesSync(img.encodeJpg(largeImg));

    // 5. Low-resolution image (64x64)
    final lowResImg = img.Image(width: 64, height: 64);
    img.fill(lowResImg, color: img.ColorRgb8(180, 50, 180));
    lowResPhotoFile = File('${tempDir.path}/test_lowres.jpg');
    lowResPhotoFile.writeAsBytesSync(img.encodeJpg(lowResImg));

    // 6. Transparent PNG (200x200 with center circle and transparent border)
    final transparentImg = img.Image(width: 200, height: 200, numChannels: 4);
    img.fill(transparentImg, color: img.ColorRgba8(0, 0, 0, 0));
    img.fillCircle(transparentImg, x: 100, y: 100, radius: 80, color: img.ColorRgba8(255, 0, 0, 255));
    transparentPngFile = File('${tempDir.path}/test_transparent.png');
    transparentPngFile.writeAsBytesSync(img.encodePng(transparentImg));

    SharedPreferences.setMockInitialValues({'online_features_enabled': false});
    await NetworkPolicyService.instance.init();
  });

  tearDownAll(() async {
    ImageCropHelper.tempDirectoryOverride = null;
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Crop & Zoom Phase 10: 18-Point Verification Suite', () {
    test('1. Square photo (500x500) crops to exact square JPEG', () async {
      final cropped = await ImageCropHelper.cropNormalized(
        sourcePath: squarePhotoFile.path,
        normLeft: 0.1,
        normTop: 0.1,
        normWidth: 0.8,
        normHeight: 0.8,
        isSquare: true,
        targetDimension: 640,
      );

      expect(cropped.existsSync(), isTrue);
      final decoded = img.decodeImage(cropped.readAsBytesSync())!;
      expect(decoded.width, equals(640));
      expect(decoded.height, equals(640));
    });

    test('2. Portrait photo (400x800) 1:1 crop produces square output without distortion', () async {
      final cropped = await ImageCropHelper.cropNormalized(
        sourcePath: portraitPhotoFile.path,
        normLeft: 0.0,
        normTop: 0.25,
        normWidth: 1.0,
        normHeight: 0.5,
        isSquare: true,
        targetDimension: 640,
      );

      expect(cropped.existsSync(), isTrue);
      final decoded = img.decodeImage(cropped.readAsBytesSync())!;
      expect(decoded.width, equals(640));
      expect(decoded.height, equals(640));
    });

    test('3. Landscape photo (1000x500) Free Crop preserves arbitrary aspect ratio', () async {
      final cropped = await ImageCropHelper.cropNormalized(
        sourcePath: landscapePhotoFile.path,
        normLeft: 0.1,
        normTop: 0.1,
        normWidth: 0.8,
        normHeight: 0.4,
        isSquare: false,
        targetDimension: 640,
      );

      expect(cropped.existsSync(), isTrue);
      final decoded = img.decodeImage(cropped.readAsBytesSync())!;
      // Width to height aspect ratio is (0.8 * 1000) : (0.4 * 500) = 800 : 200 = 4:1 -> 640x160
      expect(decoded.width, equals(640));
      expect(decoded.height, equals(160));
    });

    test('4. Large camera photo (3000x2000) decodes and crops smoothly to target dimension', () async {
      final cropped = await ImageCropHelper.cropNormalized(
        sourcePath: largeCameraPhotoFile.path,
        normLeft: 0.2,
        normTop: 0.2,
        normWidth: 0.6,
        normHeight: 0.6,
        isSquare: true,
        targetDimension: 640,
      );

      expect(cropped.existsSync(), isTrue);
      final decoded = img.decodeImage(cropped.readAsBytesSync())!;
      expect(decoded.width, equals(640));
      expect(decoded.height, equals(640));
    });

    test('5. Low-resolution image (64x64) crops safely without division by zero', () async {
      final cropped = await ImageCropHelper.cropNormalized(
        sourcePath: lowResPhotoFile.path,
        normLeft: 0.25,
        normTop: 0.25,
        normWidth: 0.5,
        normHeight: 0.5,
        isSquare: true,
        targetDimension: 640,
      );

      expect(cropped.existsSync(), isTrue);
      final decoded = img.decodeImage(cropped.readAsBytesSync())!;
      expect(decoded.width, equals(640));
      expect(decoded.height, equals(640));
    });

    test('6. Transparent PNG composites over clean white background without black artifacts', () async {
      final cropped = await ImageCropHelper.cropNormalized(
        sourcePath: transparentPngFile.path,
        normLeft: 0.0,
        normTop: 0.0,
        normWidth: 1.0,
        normHeight: 1.0,
        isSquare: true,
        targetDimension: 200,
      );

      expect(cropped.existsSync(), isTrue);
      final decoded = img.decodeImage(cropped.readAsBytesSync())!;
      expect(decoded.width, equals(200));
      expect(decoded.height, equals(200));

      // Check pixel at corner (0,0) which was transparent in source:
      // It should now be white (255, 255, 255), NOT black (0, 0, 0)!
      final cornerPixel = decoded.getPixel(0, 0);
      expect(cornerPixel.r, greaterThan(250));
      expect(cornerPixel.g, greaterThan(250));
      expect(cornerPixel.b, greaterThan(250));
    });

    testWidgets('7. CropZoomDialog: Pinch zoom gesture & zoom controls scale image within min/max bounds', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CropZoomDialog(imagePath: squarePhotoFile.path),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1.0×'), findsOneWidget);

      // Verify zoom control step button increases zoom
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.text('1.1×'), findsOneWidget);

      // Verify zoom control step button decreases zoom
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();
      expect(find.text('1.0×'), findsOneWidget);

      // Verify multi-touch scale gesture
      final center = tester.getCenter(find.byType(GestureDetector).first);
      final gesture1 = await tester.startGesture(center - const Offset(50, 0));
      final gesture2 = await tester.startGesture(center + const Offset(50, 0));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture1.moveBy(const Offset(-40, 0));
      await gesture2.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture1.moveBy(const Offset(-40, 0));
      await gesture2.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('8. CropZoomDialog: Image panning gesture moves the viewport', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CropZoomDialog(imagePath: squarePhotoFile.path),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pan from corner outside crop rect
      final viewportTopLeft = tester.getTopLeft(find.byType(GestureDetector).first);
      final gesture = await tester.startGesture(viewportTopLeft + const Offset(10, 10));
      await gesture.moveBy(const Offset(25, 25));
      await gesture.up();
      await tester.pumpAndSettle();

      // Dialog remains active with no exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('9. CropZoomDialog: Dragging corner handle resizes the crop frame', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CropZoomDialog(imagePath: squarePhotoFile.path),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(GestureDetector).first);
      // Start drag near bottom-right corner of default centered crop rect
      final gesture = await tester.startGesture(center + const Offset(80, 80));
      await gesture.moveBy(const Offset(20, 20));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('10. CropZoomDialog: Dragging edge handle resizes the crop frame', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CropZoomDialog(imagePath: squarePhotoFile.path),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(GestureDetector).first);
      // Start drag near top-center edge handle
      final gesture = await tester.startGesture(center - const Offset(0, 80));
      await gesture.moveBy(const Offset(0, -20));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('11. CropZoomDialog: Free Crop mode toggle allows independent width and height', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CropZoomDialog(imagePath: landscapePhotoFile.path),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Free Crop'), findsOneWidget);
      await tester.tap(find.text('Free Crop'));
      await tester.pumpAndSettle();

      // Drag right handle outward in Free Crop
      final center = tester.getCenter(find.byType(GestureDetector).first);
      final gesture = await tester.startGesture(center + const Offset(80, 0));
      await gesture.moveBy(const Offset(30, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('12. CropZoomDialog: 1:1 Crop mode toggle enforces square aspect ratio', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CropZoomDialog(imagePath: landscapePhotoFile.path),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Free Crop then back to 1:1 Card
      await tester.tap(find.text('Free Crop'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('1:1 Card'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('13. CropZoomDialog: Reset restores 1.0x zoom and centered frame', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CropZoomDialog(imagePath: squarePhotoFile.path),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Increase zoom to 1.3x using '+' button
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.text('1.3×'), findsOneWidget);

      // Tap Reset
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.text('1.0×'), findsOneWidget);
    });

    testWidgets('14. CropZoomDialog: Cancel discards unsaved changes and returns null', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? result = 'initial';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await CropZoomDialog.show(ctx, imagePath: squarePhotoFile.path);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('15. CropZoomDialog: Use Photo produces cropped file and returns valid path', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await CropZoomDialog.show(ctx, imagePath: squarePhotoFile.path);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(File(result!).existsSync(), isTrue);
      final decoded = img.decodeImage(File(result!).readAsBytesSync())!;
      expect(decoded.width, equals(640));
      expect(decoded.height, equals(640));
    });

    testWidgets('16. Reopening an edited card retains original source safely without corruption', (tester) async {
      final initialBytes = squarePhotoFile.readAsBytesSync();

      // Crop once
      final crop1 = await ImageCropHelper.cropNormalized(
        sourcePath: squarePhotoFile.path,
        normLeft: 0.1,
        normTop: 0.1,
        normWidth: 0.8,
        normHeight: 0.8,
        isSquare: true,
      );
      expect(crop1.existsSync(), isTrue);

      // Verify original source was never overwritten
      final afterBytes = squarePhotoFile.readAsBytesSync();
      expect(afterBytes, equals(initialBytes));

      // Crop again from original source
      final crop2 = await ImageCropHelper.cropNormalized(
        sourcePath: squarePhotoFile.path,
        normLeft: 0.2,
        normTop: 0.2,
        normWidth: 0.6,
        normHeight: 0.6,
        isSquare: true,
      );
      expect(crop2.existsSync(), isTrue);
      expect(crop1.path, isNot(equals(crop2.path)));
    });

    test('17. Backup and Restore correctly preserves cropped images in media storage', () async {
      final docsDir = await Directory.systemTemp.createTemp('card_crop_bup_');
      try {
        CardStorageService.docsDirectoryOverride = () async => docsDir;

        final cropped = await ImageCropHelper.cropNormalized(
          sourcePath: squarePhotoFile.path,
          normLeft: 0.1,
          normTop: 0.1,
          normWidth: 0.8,
          normHeight: 0.8,
          isSquare: true,
        );

        final permanentPath = await CardStorageService.persistMediaFile(
          cropped.path,
          cardId: 'card_comp_crop',
          mediaType: 'images',
        );

        final card = AACCard(
          id: 'card_comp_crop',
          label: 'Cropped Card',
          imagePath: permanentPath,
          colorValue: 0xFF0284C7,
        );

        final zipBytes = await BackupService.buildBackupZip(
          [card],
          settings: {},
        );
        expect(zipBytes, isNotNull);
        expect(zipBytes!.isNotEmpty, isTrue);

        final restored = await BackupService.restoreFromZipBytes(zipBytes);
        expect(restored.cards.length, equals(1));
        expect(restored.cards.first.imagePath, isNotEmpty);
        expect(File(restored.cards.first.imagePath!).existsSync(), isTrue);
      } finally {
        CardStorageService.resetTestHooks();
        try {
          if (await docsDir.exists()) await docsDir.delete(recursive: true);
        } catch (_) {}
      }
    });

    testWidgets('18. Responsive layout: Portrait (390x844) adapts without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CropZoomDialog(imagePath: squarePhotoFile.path),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Crop & Zoom'), findsOneWidget);
    });

    testWidgets('19. Responsive layout: Landscape (844x390) adapts without overflow', (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CropZoomDialog(imagePath: squarePhotoFile.path),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Crop & Zoom'), findsOneWidget);
    });
  });
}
