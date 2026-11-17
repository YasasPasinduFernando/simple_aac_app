import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Render and capture high-resolution preview of requested colored cards', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final root = StarterPackService.buildStarterPack();
    final allWordsById = <String, AACCard>{};
    for (final folder in root.subCards) {
      for (final word in folder.subCards) {
        allWordsById[word.id] = word;
      }
    }

    final targetCards = [
      allWordsById['simpleaac.starter.v2.basic_words.hello']!,      // Hello (yellow)
      allWordsById['simpleaac.starter.v2.feelings.sad']!,           // Sad (blue)
      allWordsById['simpleaac.starter.v2.basic_words.yes']!,        // Yes (green)
      allWordsById['simpleaac.starter.v2.basic_words.stop']!,       // Stop (soft red)
      allWordsById['simpleaac.starter.v2.food.kottu']!,             // Kottu Roti (warm yellow)
      allWordsById['simpleaac.starter.v2.drinks.milk']!,            // Milk / Drinks (blue)
      allWordsById['simpleaac.starter.v2.personal_care.toothpaste']!, // Personal Care / Toothpaste (mint)
    ];

    final repaintKey = GlobalKey();

    Widget buildTile(AACCard card) {
      return Container(
        decoration: BoxDecoration(
          color: Color(card.colorValue),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.file(
                  File(card.imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  card.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: RepaintBoundary(
            key: repaintKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFFF8FAFC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simple AAC Sri Lanka — 114 Ready-Colored Starter Cards (v8)',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Baked-in Soft Colors: Hello (yellow), Sad (blue), Yes (green), Stop (soft red), Kottu (warm yellow), Drinks (blue), Personal Care (mint)',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.92,
                      children: targetCards.map(buildTile).toList(),
                    ),
                  ),
                ],
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

      final outDir = Directory('docs/qa/starter_pack_verification');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      File('docs/qa/starter_pack_verification/preview_rendered_tiles.png').writeAsBytesSync(bytes);

      const artifactDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
      File('$artifactDir/preview_rendered_tiles.png').writeAsBytesSync(bytes);
    });
  });
}
