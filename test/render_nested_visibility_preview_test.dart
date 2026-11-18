import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/widgets/visible_cards_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Render high-resolution preview of Screen 1 and Screen 2 matching UI reference mockup', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build hierarchy matching reference mockup:
    final dog = AACCard(id: 'c_dog', label: 'Dog', colorValue: 0xFFD7ECD9);
    final cat = AACCard(id: 'c_cat', label: 'Cat', colorValue: 0xFFF3D8E2);
    final bird = AACCard(id: 'c_bird', label: 'Bird', colorValue: 0xFFFDF6C7);
    final fish = AACCard(id: 'c_fish', label: 'Fish', colorValue: 0xFFFEDCB7);
    final cow = AACCard(id: 'c_cow', label: 'Cow', colorValue: 0xFFE2D9F3);
    final elephant = AACCard(id: 'c_elephant', label: 'Elephant', colorValue: 0xFFE0DDD5);

    final animals = AACCard(
      id: 'folder_animals',
      label: 'Animals',
      colorValue: 0xFFC8E6C9,
      type: 'folder',
      subCards: [dog, cat, bird, fish, cow, elephant],
    );

    final defaultFolder = AACCard(
      id: 'folder_default',
      label: 'Default',
      colorValue: 0xFFBBDEFB,
      type: 'folder',
      subCards: [animals],
    );

    final moreCard1 = AACCard(id: 'c_more1', label: 'Item 1', colorValue: 0xFFFFF59D);
    final moreCard2 = AACCard(id: 'c_more2', label: 'Item 2', colorValue: 0xFFFFF59D);
    final moreFolder = AACCard(
      id: 'folder_more',
      label: 'More',
      colorValue: 0xFFFFF59D,
      type: 'folder',
      subCards: [moreCard1, moreCard2],
    );

    final sad = AACCard(id: 'c_sad', label: 'Sad', colorValue: 0xFF90CAF9);
    final angry = AACCard(id: 'c_angry', label: 'Angry', colorValue: 0xFFEF9A9A);
    final hello = AACCard(id: 'c_hello', label: 'Hello', colorValue: 0xFFF8BBD0);

    final rootCards = [sad, angry, moreFolder, defaultFolder, hello];

    // ==========================================
    // 1. Render Screen 1: Root Visible Cards
    // ==========================================
    final repaintKey1 = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0284C7)),
        ),
        home: Scaffold(
          backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.6),
          body: Center(
            child: RepaintBoundary(
              key: repaintKey1,
              child: SizedBox(
                width: 440,
                child: VisibleCardsDialog(
                  cards: rootCards,
                  currentLanguage: 'en',
                  initialSelectedIds: rootCards.map((c) => c.id).toSet(),
                  gridColumns: 2,
                  onSubmit: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary1 = repaintKey1.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final img1 = await boundary1.toImage(pixelRatio: 2.0);
      final byteData1 = await img1.toByteData(format: ui.ImageByteFormat.png);
      final bytes1 = byteData1!.buffer.asUint8List();

      const outPath1 = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013/nested_visibility_screen1_root.png';
      File(outPath1).writeAsBytesSync(bytes1);

      final projectArtifactDir = Directory('docs/qa/nested_visibility');
      if (!projectArtifactDir.existsSync()) {
        projectArtifactDir.createSync(recursive: true);
      }
      File('docs/qa/nested_visibility/nested_visibility_screen1_root.png').writeAsBytesSync(bytes1);
    });

    // ==========================================
    // 2. Render Screen 2: Nested Sub-cards (Animals)
    // ==========================================
    final repaintKey2 = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0284C7)),
        ),
        home: Scaffold(
          backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.6),
          body: Center(
            child: RepaintBoundary(
              key: repaintKey2,
              child: SizedBox(
                width: 440,
                child: VisibleCardsDialog(
                  cards: animals.subCards,
                  allCards: rootCards,
                  initialParentStack: [defaultFolder, animals],
                  visibleCardIdsByParent: const {
                    'folder_animals': {'c_dog', 'c_cat', 'c_fish', 'c_cow'}, // Bird & Elephant unchecked
                  },
                  currentLanguage: 'en',
                  initialSelectedIds: const {'c_dog', 'c_cat', 'c_fish', 'c_cow'},
                  gridColumns: 2,
                  onSubmit: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary2 = repaintKey2.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final img2 = await boundary2.toImage(pixelRatio: 2.0);
      final byteData2 = await img2.toByteData(format: ui.ImageByteFormat.png);
      final bytes2 = byteData2!.buffer.asUint8List();

      const outPath2 = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013/nested_visibility_screen2_subcards.png';
      File(outPath2).writeAsBytesSync(bytes2);

      File('docs/qa/nested_visibility/nested_visibility_screen2_subcards.png').writeAsBytesSync(bytes2);
    });
  });
}
