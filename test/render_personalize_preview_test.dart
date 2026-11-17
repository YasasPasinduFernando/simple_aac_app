import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_aac_app/widgets/personalize_setup_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Render high-resolution preview of Personalize Setup Dialog matching UI mockup',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0284C7)),
        ),
        home: Scaffold(
          backgroundColor: const Color(0xFF0277BD).withValues(alpha: 0.85),
          body: Center(
            child: RepaintBoundary(
              key: repaintKey,
              child: const SizedBox(
                width: 440,
                child: PersonalizeSetupDialog(
                  initialLanguage: 'en',
                  initialAppBarColor: Color(0xFFCE738E), // Soft Rose matching mockup
                  initialBoardColor: Color(0xFFF8F2D8), // Cream matching mockup
                  isFirstLaunch: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final boundary =
        repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final outDir = Directory('docs/qa/personalize_verification');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      File('docs/qa/personalize_verification/personalize_rendered_dialog.png')
          .writeAsBytesSync(bytes);

      const artifactDir =
          '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
      File('$artifactDir/personalize_rendered_dialog.png').writeAsBytesSync(bytes);
    });
  });
}
