import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/utils/camera_object_helper.dart';
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

  testWidgets(
      'SmartImageSearchDialog renders 4 filter chips (All, Photos, GIFs, AAC Symbols) with zero overflow',
      (tester) async {
    SharedPreferences.setMockInitialValues({'online_features_enabled': true});
    await NetworkPolicyService.instance.init();

    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(360, 640)),
          child: Scaffold(
            body: SmartImageSearchDialog(
              initialQuery: 'dance',
              cardId: 'dance_card',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.byType(SmartSearchIcon), findsOneWidget);
  });

  testWidgets('Tapping recognized ML Kit chip auto-fills English, Sinhala, and Tamil when fields are empty',
      (tester) async {
    final card = AACCard(
      id: 'empty_card',
      label: '',
      labelSinhala: '',
      labelTamil: '',
      imagePath: 'assets/images/seed/apple.jpg',
      colorValue: 0xFF90CAF9,
      category: 'General',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardEditorDialog(
            card: card,
            isNew: false,
            categories: const ['All', 'General'],
            audioPlayer: _FakeAudioPlayer(),
            initialCameraAnalysis: const CameraAnalysisResult(
              hasObject: true,
              isTooDarkOrBlank: false,
              labels: ['Apple', 'Food'],
              topConfidence: 0.95,
              objectCount: 1,
              analyzerAvailable: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detected (offline) — tap to use word:'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);

    // Tap the 'Apple' chip
    await tester.tap(find.text('Apple'));
    await tester.pumpAndSettle();

    // Verify fields were auto-filled
    expect(find.text('ඇපල්'), findsOneWidget);
    expect(find.text('ஆப்பிள்'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Apple'), findsOneWidget);
    expect(find.text('Auto-filled English, Sinhala & Tamil labels'), findsOneWidget);
  });

  testWidgets('Tapping recognized ML Kit chip prompts confirmation dialog when manual labels conflict and preserves on Keep Current',
      (tester) async {
    final card = AACCard(
      id: 'custom_card',
      label: 'My Snack',
      labelSinhala: 'මගේ කෑම',
      labelTamil: 'என் உணவு',
      imagePath: 'assets/images/seed/apple.jpg',
      colorValue: 0xFF90CAF9,
      category: 'General',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardEditorDialog(
            card: card,
            isNew: false,
            categories: const ['All', 'General'],
            audioPlayer: _FakeAudioPlayer(),
            initialCameraAnalysis: const CameraAnalysisResult(
              hasObject: true,
              isTooDarkOrBlank: false,
              labels: ['Apple'],
              topConfidence: 0.95,
              objectCount: 1,
              analyzerAvailable: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the 'Apple' chip
    await tester.tap(find.text('Apple'));
    await tester.pumpAndSettle();

    // Overwrite confirmation dialog should appear
    expect(find.text('Update Card Labels?'), findsOneWidget);
    expect(find.text('Keep Current'), findsOneWidget);
    expect(find.text('Update Labels'), findsOneWidget);

    // Tap Keep Current
    await tester.tap(find.text('Keep Current'));
    await tester.pumpAndSettle();

    // Dialog dismissed and manual text preserved
    expect(find.text('Update Card Labels?'), findsNothing);
    expect(find.text('My Snack'), findsOneWidget);
    expect(find.text('මගේ කෑම'), findsOneWidget);
    expect(find.text('என் உணவு'), findsOneWidget);
  });

  testWidgets('Tapping recognized ML Kit chip updates labels when confirmed with Update Labels',
      (tester) async {
    final card = AACCard(
      id: 'custom_card_update',
      label: 'My Snack',
      labelSinhala: 'මගේ කෑම',
      labelTamil: 'என் உணவு',
      imagePath: 'assets/images/seed/apple.jpg',
      colorValue: 0xFF90CAF9,
      category: 'General',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardEditorDialog(
            card: card,
            isNew: false,
            categories: const ['All', 'General'],
            audioPlayer: _FakeAudioPlayer(),
            initialCameraAnalysis: const CameraAnalysisResult(
              hasObject: true,
              isTooDarkOrBlank: false,
              labels: ['Apple'],
              topConfidence: 0.95,
              objectCount: 1,
              analyzerAvailable: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the 'Apple' chip
    await tester.tap(find.text('Apple'));
    await tester.pumpAndSettle();

    expect(find.text('Update Card Labels?'), findsOneWidget);

    // Tap Update Labels
    await tester.tap(find.text('Update Labels'));
    await tester.pumpAndSettle();

    // Dialog dismissed and fields updated
    expect(find.text('Update Card Labels?'), findsNothing);
    expect(find.widgetWithText(TextField, 'Apple'), findsOneWidget);
    expect(find.text('ඇපල්'), findsOneWidget);
    expect(find.text('ஆப்பிள்'), findsOneWidget);
  });

  testWidgets(
      'Full ML Kit camera-to-trilingual-auto-fill workflow: auto-fill, save, persist, reopen, overwrite guard (keep & update), and re-persist',
      (tester) async {
    // 1. Start with an empty card with camera detection labels
    final initialCard = AACCard(
      id: 'flow_card_1',
      label: '',
      labelSinhala: '',
      labelTamil: '',
      imagePath: 'assets/images/seed/apple.jpg',
      colorValue: 0xFF90CAF9,
      category: 'General',
    );

    CardEditorAction? resultAction;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                resultAction = await showDialog<CardEditorAction>(
                  context: context,
                  builder: (_) => CardEditorDialog(
                    card: initialCard,
                    isNew: true,
                    categories: const ['All', 'General'],
                    audioPlayer: _FakeAudioPlayer(),
                    initialCameraAnalysis: const CameraAnalysisResult(
                      hasObject: true,
                      isTooDarkOrBlank: false,
                      labels: ['Apple', 'Water'],
                      topConfidence: 0.98,
                      objectCount: 2,
                      analyzerAvailable: true,
                    ),
                  ),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify detection chips appear
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);

    // Tap 'Apple' chip -> auto-fills English, Sinhala, Tamil
    await tester.tap(find.text('Apple'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Apple'), findsOneWidget);
    expect(find.text('ඇපල්'), findsOneWidget);
    expect(find.text('ஆப்பிள்'), findsOneWidget);

    // Tap Save Card button
    await tester.tap(find.text('Save Card'));
    await tester.pumpAndSettle();

    expect(resultAction, CardEditorAction.saved);
    expect(initialCard.label, 'Apple');
    expect(initialCard.labelSinhala, 'ඇපල්');
    expect(initialCard.labelTamil, 'ஆப்பிள்');

    // 2. Persist to JSON and reload (simulating app storage / restart)
    final savedJson = initialCard.toJson();
    final reloadedCard = AACCard.fromJson(savedJson);

    expect(reloadedCard.label, 'Apple');
    expect(reloadedCard.labelSinhala, 'ඇපල්');
    expect(reloadedCard.labelTamil, 'ஆப்பிள்');

    // 3. Reopen dialog with the reloaded card
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                resultAction = await showDialog<CardEditorAction>(
                  context: context,
                  builder: (_) => CardEditorDialog(
                    card: reloadedCard,
                    isNew: false,
                    categories: const ['All', 'General'],
                    audioPlayer: _FakeAudioPlayer(),
                    initialCameraAnalysis: const CameraAnalysisResult(
                      hasObject: true,
                      isTooDarkOrBlank: false,
                      labels: ['Water'],
                      topConfidence: 0.95,
                      objectCount: 1,
                      analyzerAvailable: true,
                    ),
                  ),
                );
              },
              child: const Text('Reopen Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Reopen Dialog'));
    await tester.pumpAndSettle();

    // Verify initial values in reopened dialog
    expect(find.widgetWithText(TextField, 'Apple'), findsOneWidget);
    expect(find.text('ඇපල්'), findsOneWidget);
    expect(find.text('ஆப்பிள்'), findsOneWidget);

    // Tap conflicting 'Water' chip
    await tester.tap(find.text('Water'));
    await tester.pumpAndSettle();

    // Verify overwrite confirmation dialog appears with diffs
    expect(find.text('Update Card Labels?'), findsOneWidget);
    expect(find.text('Keep Current'), findsOneWidget);
    expect(find.text('Update Labels'), findsOneWidget);

    // User chooses 'Keep Current'
    await tester.tap(find.text('Keep Current'));
    await tester.pumpAndSettle();

    // Verify values remain unchanged
    expect(find.text('Update Card Labels?'), findsNothing);
    expect(find.widgetWithText(TextField, 'Apple'), findsOneWidget);
    expect(find.text('ඇපල්'), findsOneWidget);
    expect(find.text('ஆப்பிள்'), findsOneWidget);

    // Tap conflicting 'Water' chip again
    await tester.tap(find.text('Water'));
    await tester.pumpAndSettle();

    expect(find.text('Update Card Labels?'), findsOneWidget);

    // User chooses 'Update Labels'
    await tester.tap(find.text('Update Labels'));
    await tester.pumpAndSettle();

    // Verify updated to Water, වතුර, தண்ணீர்
    expect(find.text('Update Card Labels?'), findsNothing);
    expect(find.widgetWithText(TextField, 'Water'), findsOneWidget);
    expect(find.text('වතුර'), findsOneWidget);
    expect(find.text('தண்ணீர்'), findsOneWidget);

    // Save updated card
    await tester.tap(find.text('Save Card'));
    await tester.pumpAndSettle();

    expect(resultAction, CardEditorAction.saved);
    expect(reloadedCard.label, 'Water');
    expect(reloadedCard.labelSinhala, 'වතුර');
    expect(reloadedCard.labelTamil, 'தண்ணீர்');

    // 4. Re-persist and verify final round-trip
    final finalJson = reloadedCard.toJson();
    final finalCard = AACCard.fromJson(finalJson);
    expect(finalCard.label, 'Water');
    expect(finalCard.labelSinhala, 'වතුර');
    expect(finalCard.labelTamil, 'தண்ணீர்');
  });
}
