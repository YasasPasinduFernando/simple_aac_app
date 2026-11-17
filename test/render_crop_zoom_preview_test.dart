import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_aac_app/widgets/crop_zoom_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Render high-resolution preview of Crop & Zoom Dialog matching UI reference', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const samplePath = 'assets/images/starter_pack_v8/feelings_sad.webp';
    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0284C7)),
        ),
        home: Scaffold(
          backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.7),
          body: Center(
            child: RepaintBoundary(
              key: repaintKey,
              child: const SizedBox(
                width: 440,
                child: CropZoomDialog(
                  imagePath: samplePath,
                  targetDimension: 640,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final boundary = repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final outDir = Directory('docs/qa/crop_zoom_verification');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      File('docs/qa/crop_zoom_verification/crop_zoom_rendered_dialog.png').writeAsBytesSync(bytes);

      const artifactDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
      File('$artifactDir/crop_zoom_rendered_dialog.png').writeAsBytesSync(bytes);
    });
  });
}
