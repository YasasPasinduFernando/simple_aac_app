import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final homeCards = [
    AACCard(
      id: 'seed_hello',
      label: 'Hello',
      labelSinhala: 'හෙලෝ',
      labelTamil: 'வணக்கம்',
      imagePath: 'assets/images/seed_v2/hello.webp',
      colorValue: 0xFFFFF176,
    ),
    AACCard(
      id: 'seed_happy',
      label: 'Happy',
      labelSinhala: 'සතුටුයි',
      labelTamil: 'மகிழ்ச்சி',
      imagePath: 'assets/images/seed_v2/happy.webp',
      colorValue: 0xFF4FC3F7,
    ),
    AACCard(
      id: 'seed_sad',
      label: 'Sad',
      labelSinhala: 'දුකයි',
      labelTamil: 'சோகம்',
      imagePath: 'assets/images/seed_v2/sad.webp',
      colorValue: 0xFF4FC3F7,
    ),
    AACCard(
      id: 'seed_angry',
      label: 'Angry',
      labelSinhala: 'තරහයි',
      labelTamil: 'கோபம்',
      imagePath: 'assets/images/seed_v2/angry.webp',
      colorValue: 0xFFE57373,
    ),
    AACCard(
      id: 'seed_more',
      label: 'More',
      labelSinhala: 'තවත්',
      labelTamil: 'மேலும்',
      imagePath: 'assets/images/seed_v2/more.webp',
      colorValue: 0xFF3F51B5,
      type: 'folder',
      subCards: [
        AACCard(id: 'dummy1', label: '1', colorValue: 0),
        AACCard(id: 'dummy2', label: '2', colorValue: 0),
        AACCard(id: 'dummy3', label: '3', colorValue: 0),
        AACCard(id: 'dummy4', label: '4', colorValue: 0),
        AACCard(id: 'dummy5', label: '5', colorValue: 0),
        AACCard(id: 'dummy6', label: '6', colorValue: 0),
        AACCard(id: 'dummy7', label: '7', colorValue: 0),
        AACCard(id: 'dummy8', label: '8', colorValue: 0),
      ],
    ),
    AACCard(
      id: 'simpleaac.starter.v2.default',
      label: 'Default',
      labelSinhala: 'පෙරනිමි',
      labelTamil: 'இயல்பு',
      imagePath: 'assets/images/simple_aac_logo_transparent.png',
      colorValue: 0xFF2196F3,
      type: 'folder',
      subCards: List.generate(
        13,
        (i) => AACCard(id: 'cat_$i', label: 'Cat $i', colorValue: 0),
      ),
    ),
  ];

  final moreCards = [
    AACCard(
      id: 'seed_good',
      label: 'Good',
      labelSinhala: 'හොඳයි',
      labelTamil: 'நல்லது',
      imagePath: 'assets/images/seed_v2/good.webp',
      colorValue: 0xFF81C784,
    ),
    AACCard(
      id: 'seed_play',
      label: 'Play',
      labelSinhala: 'සෙල්ලම්',
      labelTamil: 'விளையாடு',
      imagePath: 'assets/images/seed_v2/play.webp',
      colorValue: 0xFFFFB74D,
    ),
    AACCard(
      id: 'seed_yes',
      label: 'Yes',
      labelSinhala: 'ඔව්',
      labelTamil: 'ஆம்',
      imagePath: 'assets/images/seed_v2/yes.webp',
      colorValue: 0xFFA5D6A7,
    ),
    AACCard(
      id: 'seed_no',
      label: 'No',
      labelSinhala: 'නැහැ',
      labelTamil: 'இல்லை',
      imagePath: 'assets/images/seed_v2/no.webp',
      colorValue: 0xFFEF9A9A,
    ),
    AACCard(
      id: 'seed_please',
      label: 'Please',
      labelSinhala: 'කරුණාකර',
      labelTamil: 'தயவுசெய்து',
      imagePath: 'assets/images/seed_v2/please.webp',
      colorValue: 0xFFCE93D8,
    ),
    AACCard(
      id: 'seed_thank_you',
      label: 'Thank You',
      labelSinhala: 'ස්තුතියි',
      labelTamil: 'நன்றி',
      imagePath: 'assets/images/seed_v2/thank_you.webp',
      colorValue: 0xFFFFE082,
    ),
    AACCard(
      id: 'seed_help',
      label: 'Help',
      labelSinhala: 'උදව්',
      labelTamil: 'உதவி',
      imagePath: 'assets/images/seed_v2/help.webp',
      colorValue: 0xFF80DEEA,
    ),
    AACCard(
      id: 'seed_stop',
      label: 'Stop',
      labelSinhala: 'නවත්වන්න',
      labelTamil: 'நிறுத்து',
      imagePath: 'assets/images/seed_v2/stop.webp',
      colorValue: 0xFFFF8A80,
    ),
  ];

  Future<void> saveRepaintBoundary(
      WidgetTester tester, GlobalKey key, String fileName) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final dir = Directory('docs/qa/stickman_v2');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      final artifactDir = Directory(
          '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013');
      if (artifactDir.existsSync()) {
        await File('${artifactDir.path}/$fileName').writeAsBytes(bytes);
      }
    });
  }

  Widget buildActualCard({
    required AACCard card,
    double textScale = 1.0,
  }) {
    final cardSurfaceColor = Color(card.colorValue);
    return Container(
      decoration: BoxDecoration(
        color: cardSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 76,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Center(
                  child: card.imagePath != null
                      ? Image.file(
                          File(card.imagePath!),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image,
                                  size: 48, color: Colors.white70),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            card.isFolder
                                ? Icons.folder_rounded
                                : Icons.image,
                            size: 48,
                            color: Colors.white70,
                          ),
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 24,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (card.subCards.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${card.subCards.length} ${card.subCards.length == 1 ? "sub-card" : "sub-cards"}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5 * textScale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            card.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16 * textScale,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black54,
                                  offset: Offset(0, 1.5),
                                ),
                              ],
                            ),
                          ),
                          if (card.isFolder || card.subCards.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 18 * textScale,
                              height: 18 * textScale,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 11 * textScale,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPreviewGrid({
    required List<AACCard> cards,
    required int columns,
    required String title,
    required GlobalKey key,
    double textScale = 1.0,
  }) {
    return RepaintBoundary(
      key: key,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFFF1F5F9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  return buildActualCard(
                    card: cards[index],
                    textScale: textScale,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('Preview 1: Home 6 cards in Portrait 2-column layout',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildPreviewGrid(
            cards: homeCards,
            columns: 2,
            title: 'Simple AAC — Home Board (Portrait 2-Column Grid)',
            key: key,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveRepaintBoundary(
        tester, key, 'stickman_v2_01_home_portrait_2col.png');
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Happy'), findsOneWidget);
    expect(find.text('Sad'), findsOneWidget);
    expect(find.text('Angry'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('8 sub-cards'), findsOneWidget);
    expect(find.text('13 sub-cards'), findsOneWidget);
  });

  testWidgets('Preview 2: Home 6 cards in Landscape 4-column layout',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildPreviewGrid(
            cards: homeCards,
            columns: 4,
            title: 'Simple AAC — Home Board (Landscape 4-Column Grid)',
            key: key,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveRepaintBoundary(
        tester, key, 'stickman_v2_02_home_landscape_4col.png');
    expect(homeCards.length, equals(6));
  });

  testWidgets('Preview 3: More 8 cards in Portrait 2-column layout',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildPreviewGrid(
            cards: moreCards,
            columns: 2,
            title: 'Simple AAC — More Folder Expanded (Portrait 2-Column Grid)',
            key: key,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveRepaintBoundary(
        tester, key, 'stickman_v2_03_more_portrait_2col.png');
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    expect(find.text('Please'), findsOneWidget);
    expect(find.text('Thank You'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
  });

  testWidgets('Preview 4: More 8 cards in Landscape 4-column layout',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildPreviewGrid(
            cards: moreCards,
            columns: 4,
            title: 'Simple AAC — More Folder Expanded (Landscape 4-Column Grid)',
            key: key,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveRepaintBoundary(
        tester, key, 'stickman_v2_04_more_landscape_4col.png');
    expect(moreCards.length, equals(8));
  });

  testWidgets('Preview 5: More 8 cards in Dense 6-column layout',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 700);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildPreviewGrid(
            cards: moreCards,
            columns: 6,
            title: 'Simple AAC — More Folder Expanded (Dense 6-Column Grid)',
            key: key,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveRepaintBoundary(
        tester, key, 'stickman_v2_05_more_dense_6col.png');
    expect(moreCards.length, equals(8));
  });

  testWidgets('Preview 6: Home & More at Large Text Scale (1.4x)',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildPreviewGrid(
            cards: [...homeCards.take(4), ...moreCards.take(4)],
            columns: 4,
            textScale: 1.4,
            title: 'Simple AAC — High Accessibility Scale (1.4x Text Scale)',
            key: key,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveRepaintBoundary(
        tester, key, 'stickman_v2_06_large_text_scale.png');
    expect(find.text('Hello'), findsOneWidget);
  });
}
