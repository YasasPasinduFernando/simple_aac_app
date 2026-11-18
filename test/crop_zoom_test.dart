import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/utils/image_crop_helper.dart';
import 'package:simple_aac_app/widgets/card_editor_dialog.dart';
import 'package:simple_aac_app/widgets/crop_zoom_dialog.dart';

class _FakeAudioPlayer extends Fake implements AudioPlayer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File sampleLandscapeFile;
  late File samplePortraitFile;
  late File sampleGifFile;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'online_features_enabled': false});
    await NetworkPolicyService.instance.init();

    tempDir = await Directory.systemTemp.createTemp('crop_zoom_test_');

    // Create 800x600 landscape sample image
    final landscapeImg = img.Image(width: 800, height: 600);
    img.fill(landscapeImg, color: img.ColorRgb8(255, 200, 100));
    sampleLandscapeFile = File('${tempDir.path}/sample_landscape.jpg');
    sampleLandscapeFile.writeAsBytesSync(img.encodeJpg(landscapeImg));

    // Create 600x900 portrait sample image
    final portraitImg = img.Image(width: 600, height: 900);
    img.fill(portraitImg, color: img.ColorRgb8(100, 200, 255));
    samplePortraitFile = File('${tempDir.path}/sample_portrait.jpg');
    samplePortraitFile.writeAsBytesSync(img.encodeJpg(portraitImg));

    // Create a dummy .gif file
    sampleGifFile = File('${tempDir.path}/sample.gif');
    sampleGifFile.writeAsBytesSync([0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00]);
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ImageCropHelper Unit Tests', () {
    test('1. Default 1.0x centered crop on landscape image produces exact square with correct dimensions', () async {
      final cropped = await ImageCropHelper.cropSquare(
        sourcePath: sampleLandscapeFile.path,
        zoom: 1.0,
        panX: 0.0,
        panY: 0.0,
        viewportSize: 280.0,
        targetDimension: 640,
      );

      expect(cropped.existsSync(), isTrue);
      final decoded = img.decodeImage(cropped.readAsBytesSync())!;
      expect(decoded.width, equals(640));
      expect(decoded.height, equals(640));
    });

    test('2. Default 1.0x centered crop on portrait image produces exact square', () async {
      final cropped = await ImageCropHelper.cropSquare(
        sourcePath: samplePortraitFile.path,
        zoom: 1.0,
        panX: 0.0,
        panY: 0.0,
        viewportSize: 280.0,
        targetDimension: 512,
      );

      expect(cropped.existsSync(), isTrue);
      final decoded = img.decodeImage(cropped.readAsBytesSync())!;
      expect(decoded.width, equals(512));
      expect(decoded.height, equals(512));
    });

    test('3. Extreme pan clamps cleanly and prevents empty/negative bounds', () async {
      final cropped = await ImageCropHelper.cropSquare(
        sourcePath: sampleLandscapeFile.path,
        zoom: 1.5,
        panX: 9999.0, // extreme pan right
        panY: -9999.0, // extreme pan up
        viewportSize: 280.0,
        targetDimension: 640,
      );

      expect(cropped.existsSync(), isTrue);
      final decoded = img.decodeImage(cropped.readAsBytesSync())!;
      expect(decoded.width, equals(640));
      expect(decoded.height, equals(640));
    });

    test('4. Zoom scaling at 3.0x crops detailed region without failure', () async {
      final cropped = await ImageCropHelper.cropSquare(
        sourcePath: sampleLandscapeFile.path,
        zoom: 3.0,
        panX: 0.0,
        panY: 0.0,
        viewportSize: 280.0,
        targetDimension: 640,
      );

      expect(cropped.existsSync(), isTrue);
      final decoded = img.decodeImage(cropped.readAsBytesSync())!;
      expect(decoded.width, equals(640));
      expect(decoded.height, equals(640));
    });
  });

  group('CropZoomDialog Widget Tests', () {
    testWidgets('5. Renders complete UI: Title, Subtitle, Info banner, Badge, Zoom controls, Reset & Actions',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CropZoomDialog(
              imagePath: sampleLandscapeFile.path,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Crop & Zoom'), findsOneWidget);
      expect(find.text('Pinch to zoom • Drag image or crop handles'), findsOneWidget);
      expect(find.textContaining('Gallery and Camera photos only'), findsOneWidget);
      expect(find.text('1:1 Card'), findsOneWidget);
      expect(find.text('Free Crop'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.text('1.0×'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Use Photo'), findsOneWidget);
    });

    testWidgets('6. Zoom step buttons increase and decrease zoom level and update indicator', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CropZoomDialog(
              imagePath: sampleLandscapeFile.path,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1.0×'), findsOneWidget);

      // Tap '+' button 4 times -> 1.4x
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();
      }
      expect(find.text('1.4×'), findsOneWidget);

      // Tap Reset button -> back to 1.0x
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('1.0×'), findsOneWidget);
    });

    testWidgets('7. Small screen layout (360x640) renders without layout overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CropZoomDialog(
              imagePath: sampleLandscapeFile.path,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Crop & Zoom'), findsOneWidget);
      expect(find.text('Use Photo'), findsOneWidget);
    });

    testWidgets('8. Cancel button closes dialog with null result', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? result = 'not_null';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await CropZoomDialog.show(ctx, imagePath: sampleLandscapeFile.path);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });

  group('CardEditorDialog Integration Tests', () {
    testWidgets('9. Adjust/Crop icon is visible for static images, but hidden for GIFs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staticCard = AACCard(
        id: 'card_static',
        label: 'Static Photo',
        imagePath: sampleLandscapeFile.path,
        colorValue: 0xFF0284C7,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardEditorDialog(
              card: staticCard,
              isNew: false,
              categories: const ['General'],
              audioPlayer: _FakeAudioPlayer(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tooltip / Icon for Crop & Zoom should be present
      expect(find.byTooltip('Crop & Zoom'), findsOneWidget);
      expect(find.byTooltip('Remove Image'), findsOneWidget);

      // Now test with a GIF card
      final gifCard = AACCard(
        id: 'card_gif',
        label: 'Animated GIF',
        imagePath: sampleGifFile.path,
        colorValue: 0xFF0284C7,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardEditorDialog(
              card: gifCard,
              isNew: false,
              categories: const ['General'],
              audioPlayer: _FakeAudioPlayer(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Adjust/Crop must NOT be present for GIFs
      expect(find.byTooltip('Crop & Zoom'), findsNothing);
      expect(find.byTooltip('Remove Image'), findsOneWidget);
    });

    testWidgets('10. Cancelling CardEditorDialog reverts image and preserves original card image', (tester) async {
      final origCard = AACCard(
        id: 'card_revert',
        label: 'Original',
        imagePath: sampleLandscapeFile.path,
        colorValue: 0xFF0284C7,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardEditorDialog(
              card: origCard,
              isNew: false,
              categories: const ['General'],
              audioPlayer: _FakeAudioPlayer(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Staged image should initially be the landscape file
      expect(origCard.imagePath, equals(sampleLandscapeFile.path));

      // Tap Cancel in CardEditorDialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Original image is fully preserved
      expect(origCard.imagePath, equals(sampleLandscapeFile.path));
    });

    testWidgets('11. Backup and restore correctly preserves cropped image files in media storage', (tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({'online_features_enabled': false});
        await NetworkPolicyService.instance.init();

        final docsDir = await Directory.systemTemp.createTemp('card_crop_backup_test_');
        CardStorageService.docsDirectoryOverride = () async => docsDir;
        try {
          // Crop an image to temp
          final cropped = await ImageCropHelper.cropSquare(
            sourcePath: sampleLandscapeFile.path,
            zoom: 1.0,
            panX: 0.0,
            panY: 0.0,
            viewportSize: 280.0,
            targetDimension: 640,
          );

          // Persist it into app documents
          final persisted = await CardStorageService.persistMediaFile(
            cropped.path,
            cardId: 'card_backup_crop',
            mediaType: 'images',
          );

          final cardWithCroppedImage = AACCard(
            id: 'card_backup_crop',
            label: 'Cropped Item',
            imagePath: persisted,
            colorValue: 0xFF0284C7,
          );

          final zipBytes = await BackupService.buildBackupZip(
            [cardWithCroppedImage],
            settings: {},
          );

          expect(zipBytes, isNotNull);
          expect(zipBytes!.isNotEmpty, isTrue);

          final payload = await BackupService.restoreFromZipBytes(zipBytes);
          expect(payload.cards.length, equals(1));
          expect(payload.cards.first.imagePath, isNotNull);
          expect(File(payload.cards.first.imagePath!).existsSync(), isTrue);
        } finally {
          CardStorageService.docsDirectoryOverride = null;
          if (await docsDir.exists()) {
            await docsDir.delete(recursive: true);
          }
        }
      });
    });
  });
}
