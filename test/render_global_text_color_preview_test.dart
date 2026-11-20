import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_aac_app/widgets/professional_color_picker_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Render high-resolution preview of Global Text Color Picker Dialog matching UI mockup',
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
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0288D1)),
        ),
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.65),
          body: Center(
            child: RepaintBoundary(
              key: repaintKey,
              child: SizedBox(
                width: 380,
                child: ProfessionalColorPickerDialog(
                  title: 'Global Text Color',
                  subtitle: 'App-wide text and icons',
                  initialColor: const Color(0xFF00F193), // Exact candidate color from mockup
                  defaultColor: Colors.white,
                  headerColor: const Color(0xFF0288D1),
                  previewType: ColorPickerPreviewType.globalTextPreview,
                  onApply: (_) {},
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

      final outDir = Directory('docs/qa/color_picker_verification');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      File('docs/qa/color_picker_verification/global_text_color_dialog_rendered.png')
          .writeAsBytesSync(bytes);

      const artifactDir =
          '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
      File('$artifactDir/global_text_color_dialog_rendered.png').writeAsBytesSync(bytes);
    });
  });

  testWidgets(
      'Render comparison between Global Text Color and Card Text Color Dialogs',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0288D1)),
        ),
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.65),
          body: Center(
            child: RepaintBoundary(
              key: repaintKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Global Text Color Dialog
                    SizedBox(
                      width: 380,
                      child: ProfessionalColorPickerDialog(
                        title: 'Global Text Color',
                        subtitle: 'App-wide text and icons',
                        initialColor: const Color(0xFF00F193),
                        defaultColor: Colors.white,
                        headerColor: const Color(0xFF0288D1),
                        previewType: ColorPickerPreviewType.globalTextPreview,
                        onApply: (_) {},
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Right: Card Text Color Dialog
                    SizedBox(
                      width: 380,
                      child: ProfessionalColorPickerDialog(
                        title: 'Card text color',
                        subtitle: 'Pick a text color for cards',
                        initialColor: const Color(0xFF111827),
                        defaultColor: const Color(0xFF111827),
                        previewType: ColorPickerPreviewType.textPreview,
                        onApply: (_) {},
                      ),
                    ),
                  ],
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

      final outDir = Directory('docs/qa/color_picker_verification');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      File('docs/qa/color_picker_verification/global_vs_card_text_color_comparison.png')
          .writeAsBytesSync(bytes);

      const artifactDir =
          '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
      File('$artifactDir/global_vs_card_text_color_comparison.png').writeAsBytesSync(bytes);
    });
  });
}
