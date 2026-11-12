import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/widgets/card_editor_dialog.dart';
import 'package:simple_aac_app/widgets/smart_image_search_dialog.dart';
import 'package:simple_aac_app/widgets/styled_dialog_header.dart';

class _FakeAudioPlayer extends Fake implements AudioPlayer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'online_features_enabled': false});
    await NetworkPolicyService.instance.init();
  });

  testWidgets('CardEditorDialog renders without overflow on compact portrait screen with large text',
      (tester) async {
    final card = AACCard(
      id: 'happy_test',
      label: 'Happy',
      labelSinhala: 'සතුටුයි',
      labelTamil: 'மகிழ்ச்சி',
      colorValue: 0xFF90CAF9,
      category: 'General',
    );

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.25),
          ),
          child: Scaffold(
            body: CardEditorDialog(
              card: card,
              isNew: false,
              categories: const ['All', 'General', 'Food & Drink'],
              audioPlayer: _FakeAudioPlayer(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SmartSearchIcon), findsNWidgets(2));
    expect(find.textContaining('happy smiling child'), findsOneWidget);
    expect(find.text('Voice Recording (Optional)'), findsOneWidget);
  });

  testWidgets('CardEditorDialog and SmartImageSearchDialog render without overflow in compact landscape',
      (tester) async {
    final card = AACCard(
      id: 'cat_test',
      label: 'Cat',
      labelSinhala: 'පූසා',
      labelTamil: 'பூனை',
      colorValue: 0xFFFFD54F,
      category: 'Animals',
    );

    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(640, 320)),
          child: Scaffold(
            body: CardEditorDialog(
              card: card,
              isNew: false,
              categories: const ['All', 'General'],
              audioPlayer: _FakeAudioPlayer(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(640, 320)),
          child: Scaffold(
            body: SmartImageSearchDialog(
              initialQuery: 'cute cat',
              cardId: 'cat_test',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SmartSearchIcon), findsOneWidget);
    expect(find.text('Offline Mode Is Active'), findsOneWidget);
  });

  testWidgets(
      'CardEditorDialog top-right close button and image delete bin button operate correctly',
      (tester) async {
    final card = AACCard(
      id: 'wave_test',
      label: 'Wave',
      labelSinhala: 'අත වනන්න',
      labelTamil: 'அசை',
      imagePath: 'assets/images/seed/wave.jpg',
      colorValue: 0xFF90CAF9,
      category: 'General',
    );

    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => CardEditorDialog(
                    card: card,
                    isNew: false,
                    categories: const ['All', 'General'],
                    audioPlayer: _FakeAudioPlayer(),
                  ),
                );
                closed = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify dialog header has close button and image has delete bin button
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(find.byTooltip('Remove Image'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    // Tap Remove Image bin icon
    await tester.tap(find.byTooltip('Remove Image'));
    await tester.pumpAndSettle();
    expect(card.imagePath, isNull);
    expect(find.text('No Image Selected'), findsOneWidget);

    // Tap header Close button
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  });
}
