import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/widgets/aac_card_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final personalCareCards = [
    AACCard(
      id: 'simpleaac.starter.v2.personal_care.wash_face',
      label: 'Wash Face',
      labelSinhala: 'මුහුණ හෝදන්න',
      labelTamil: 'முகம் கழுவு',
      imagePath: 'assets/images/starter_pack_v8/personal_care_wash_face.webp',
      colorValue: 0xFFBBE6FE,
      category: 'personal_care',
    ),
    AACCard(
      id: 'simpleaac.starter.v2.personal_care.take_bath',
      label: 'Take Bath',
      labelSinhala: 'නාන්න',
      labelTamil: 'குளி',
      imagePath: 'assets/images/starter_pack_v8/personal_care_take_bath.webp',
      colorValue: 0xFFB1F2E5,
      category: 'personal_care',
    ),
    AACCard(
      id: 'simpleaac.starter.v2.personal_care.wash_hands',
      label: 'Wash Hands',
      labelSinhala: 'අත් හෝදන්න',
      labelTamil: 'கை கழுவு',
      imagePath: 'assets/images/starter_pack_v8/personal_care_wash_hands.webp',
      colorValue: 0xFFBDE7FE,
      category: 'personal_care',
    ),
    AACCard(
      id: 'simpleaac.starter.v2.personal_care.dry_hands',
      label: 'Dry Hands',
      labelSinhala: 'අත් පිසදමන්න',
      labelTamil: 'கைகளை துடை',
      imagePath: 'assets/images/starter_pack_v8/personal_care_dry_hands.webp',
      colorValue: 0xFFACF3E4,
      category: 'personal_care',
    ),
    AACCard(
      id: 'simpleaac.starter.v2.personal_care.comb_hair',
      label: 'Comb Hair',
      labelSinhala: 'කොණ්ඩය පීරන්න',
      labelTamil: 'தலை சீவு',
      imagePath: 'assets/images/starter_pack_v8/personal_care_comb_hair.webp',
      colorValue: 0xFFFDE3A0,
      category: 'personal_care',
    ),
    AACCard(
      id: 'simpleaac.starter.v2.personal_care.get_dressed',
      label: 'Get Dressed',
      labelSinhala: 'ඇඳුම් අඳින්න',
      labelTamil: 'ஆடை அணி',
      imagePath: 'assets/images/starter_pack_v8/personal_care_get_dressed.webp',
      colorValue: 0xFFE0CBF4,
      category: 'personal_care',
    ),
    AACCard(
      id: 'simpleaac.starter.v2.personal_care.put_on_shoes',
      label: 'Put On Shoes',
      labelSinhala: 'සපත්තු දාන්න',
      labelTamil: 'காலணி அணி',
      imagePath: 'assets/images/starter_pack_v8/personal_care_put_on_shoes.webp',
      colorValue: 0xFFBAF8CF,
      category: 'personal_care',
    ),
  ];

  final activitiesCards = [
    AACCard(
      id: 'simpleaac.starter.v2.activities.sleep',
      label: 'Sleep',
      labelSinhala: 'නිදාගන්න',
      labelTamil: 'தூங்கு',
      imagePath: 'assets/images/starter_pack_v8/activities_sleep.webp',
      colorValue: 0xFFD7CCF6,
      category: 'activities',
    ),
    AACCard(
      id: 'simpleaac.starter.v2.activities.watch_tv',
      label: 'Watch TV',
      labelSinhala: 'ටීවී බලන්න',
      labelTamil: 'டிவி பார்',
      imagePath: 'assets/images/starter_pack_v8/activities_watch_tv.webp',
      colorValue: 0xFFFED6BF,
      category: 'activities',
    ),
    AACCard(
      id: 'simpleaac.starter.v2.activities.play_games',
      label: 'Play Games',
      labelSinhala: 'ගේම් ගහන්න',
      labelTamil: 'கேம் விளையாடு',
      imagePath: 'assets/images/starter_pack_v8/activities_play_games.webp',
      colorValue: 0xFFCDF1D5,
      category: 'activities',
    ),
    AACCard(
      id: 'simpleaac.starter.v2.activities.read_book',
      label: 'Read Book',
      labelSinhala: 'පොත් කියවන්න',
      labelTamil: 'புத்தகம் வாசி',
      imagePath: 'assets/images/starter_pack_v8/activities_read_book.webp',
      colorValue: 0xFFFDE3A0,
      category: 'activities',
    ),
    AACCard(
      id: 'simpleaac.starter.v2.activities.draw',
      label: 'Draw',
      labelSinhala: 'චිත්‍ර අඳින්න',
      labelTamil: 'படம் வரை',
      imagePath: 'assets/images/starter_pack_v8/activities_draw.webp',
      colorValue: 0xFFC4E5F7,
      category: 'activities',
    ),
    AACCard(
      id: 'simpleaac.starter.v2.activities.listen_music',
      label: 'Listen to Music',
      labelSinhala: 'සින්දු අහන්න',
      labelTamil: 'பாட்டு கேள்',
      imagePath: 'assets/images/starter_pack_v8/activities_listen_music.webp',
      colorValue: 0xFFE1CBF2,
      category: 'activities',
    ),
    AACCard(
      id: 'simpleaac.starter.v2.activities.play_outside',
      label: 'Play Outside',
      labelSinhala: 'එළියේ සෙල්ලම් කරන්න',
      labelTamil: 'வெளியே விளையாடு',
      imagePath: 'assets/images/starter_pack_v8/activities_play_outside.webp',
      colorValue: 0xFFCDF2D1,
      category: 'activities',
    ),
  ];

  Future<void> saveRepaintBoundary(WidgetTester tester, GlobalKey key, String fileName) async {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final dir = Directory('docs/qa/daily_actions');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      final artifactDir = Directory('/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013');
      if (artifactDir.existsSync()) {
        await File('${artifactDir.path}/$fileName').writeAsBytes(bytes);
      }
    });
  }

  Widget buildPreviewGrid({
    required List<AACCard> cards,
    required int columns,
    required String title,
    required GlobalKey key,
  }) {
    return RepaintBoundary(
      key: key,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFFF0F4F8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
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
                  final card = cards[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Color(card.colorValue),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 76,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.file(
                              File(card.imagePath!),
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 24,
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                card.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('Render and capture Personal Care 7 cards preview', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildPreviewGrid(
            cards: personalCareCards,
            columns: 3,
            title: 'Simple AAC — Personal Care (7 Daily Action Cards)',
            key: key,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveRepaintBoundary(tester, key, 'daily_actions_personal_care_grid.png');
    expect(find.text('Wash Face'), findsOneWidget);
    expect(find.text('Take Bath'), findsOneWidget);
    expect(find.text('Wash Hands'), findsOneWidget);
    expect(find.text('Dry Hands'), findsOneWidget);
    expect(find.text('Comb Hair'), findsOneWidget);
    expect(find.text('Get Dressed'), findsOneWidget);
    expect(find.text('Put On Shoes'), findsOneWidget);
  });

  testWidgets('Render and capture Activities 7 cards preview', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildPreviewGrid(
            cards: activitiesCards,
            columns: 3,
            title: 'Simple AAC — Activities (7 Daily Action Cards)',
            key: key,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveRepaintBoundary(tester, key, 'daily_actions_activities_grid.png');
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Watch TV'), findsOneWidget);
    expect(find.text('Play Games'), findsOneWidget);
    expect(find.text('Read Book'), findsOneWidget);
    expect(find.text('Draw'), findsOneWidget);
    expect(find.text('Listen to Music'), findsOneWidget);
    expect(find.text('Play Outside'), findsOneWidget);
  });

  testWidgets('Render all 14 cards in 4-column Landscape layout', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final all14Cards = [...personalCareCards, ...activitiesCards];
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildPreviewGrid(
            cards: all14Cards,
            columns: 4,
            title: 'Simple AAC — All 14 Daily Action Cards (Landscape 4-Column Grid)',
            key: key,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveRepaintBoundary(tester, key, 'daily_actions_14cards_landscape.png');
    expect(all14Cards.length, equals(14));
  });

  testWidgets('Verify card gestures and touch-target responses', (tester) async {
    var tapCount = 0;
    var longPressCount = 0;

    final testCard = personalCareCards.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 150,
              height: 180,
              child: AACCardWidget(
                card: testCard,
                onTap: () => tapCount++,
                onLongPress: () => longPressCount++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AACCardWidget));
    await tester.pumpAndSettle();
    expect(tapCount, equals(1));

    await tester.longPress(find.byType(AACCardWidget));
    await tester.pumpAndSettle();
    expect(longPressCount, equals(1));
  });
}
