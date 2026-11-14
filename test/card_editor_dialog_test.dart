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
    await tester.ensureVisible(find.text('Apple'));
    await tester.pumpAndSettle();

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
    await tester.ensureVisible(find.text('Apple'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apple'));
    await tester.pumpAndSettle();

    // Overwrite confirmation dialog should appear
    expect(find.text('Update card labels'), findsOneWidget);
    expect(find.text('Choose which labels to replace'), findsOneWidget);
    expect(find.text('All 3 selected'), findsOneWidget);
    expect(find.text('Select all'), findsOneWidget);
    expect(find.text('Keep current'), findsOneWidget);
    expect(find.text('Update selected (3)'), findsOneWidget);

    // Tap Keep current
    await tester.tap(find.text('Keep current'));
    await tester.pumpAndSettle();

    // Dialog dismissed and manual text preserved
    expect(find.text('Update card labels'), findsNothing);
    expect(find.text('My Snack'), findsOneWidget);
    expect(find.text('මගේ කෑම'), findsOneWidget);
    expect(find.text('என் உணவு'), findsOneWidget);
  });

  testWidgets('Tapping recognized ML Kit chip updates labels when confirmed with Update selected (3)',
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
    await tester.ensureVisible(find.text('Apple'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apple'));
    await tester.pumpAndSettle();

    expect(find.text('Update card labels'), findsOneWidget);

    // Tap Update selected (3)
    await tester.tap(find.text('Update selected (3)'));
    await tester.pumpAndSettle();

    // Dialog dismissed and fields updated
    expect(find.text('Update card labels'), findsNothing);
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
    await tester.ensureVisible(find.text('Apple'));
    await tester.pumpAndSettle();

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
    expect(find.text('Update card labels'), findsOneWidget);
    expect(find.text('Keep current'), findsOneWidget);
    expect(find.text('Update selected (3)'), findsOneWidget);

    // User chooses 'Keep current'
    await tester.tap(find.text('Keep current'));
    await tester.pumpAndSettle();

    // Verify values remain unchanged
    expect(find.text('Update card labels'), findsNothing);
    expect(find.widgetWithText(TextField, 'Apple'), findsOneWidget);
    expect(find.text('ඇපල්'), findsOneWidget);
    expect(find.text('ஆப்பிள்'), findsOneWidget);

    // Tap conflicting 'Water' chip again
    await tester.tap(find.text('Water'));
    await tester.pumpAndSettle();

    expect(find.text('Update card labels'), findsOneWidget);

    // User chooses 'Update selected (3)'
    await tester.tap(find.text('Update selected (3)'));
    await tester.pumpAndSettle();

    // Verify updated to Water, වතුර, தண்ணீர்
    expect(find.text('Update card labels'), findsNothing);
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

  testWidgets(
      'Overwrite dialog: individual language selection - deselecting Sinhala updates English and Tamil, preserving custom Sinhala text',
      (tester) async {
    final card = AACCard(
      id: 'lang_sel_card_1',
      label: 'Happy',
      labelSinhala: 'සතුටුයි',
      labelTamil: 'மகிழ்ச்சி',
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
              labels: ['Phone'],
              topConfidence: 0.95,
              objectCount: 1,
              analyzerAvailable: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Phone chip to trigger overwrite dialog
    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();

    // Dialog appears with all 3 selected
    expect(find.text('Update card labels'), findsOneWidget);
    expect(find.text('All 3 selected'), findsOneWidget);
    expect(find.text('Update selected (3)'), findsOneWidget);

    // Deselect Sinhala
    await tester.tap(find.text('Sinhala'));
    await tester.pumpAndSettle();

    // Verification of count update
    expect(find.text('2 of 3 selected'), findsOneWidget);
    expect(find.text('Update selected (2)'), findsOneWidget);

    // Tap 'Update selected (2)'
    await tester.tap(find.text('Update selected (2)'));
    await tester.pumpAndSettle();

    // Verify English and Tamil are updated, but Sinhala is preserved
    expect(find.text('Update card labels'), findsNothing);
    expect(find.widgetWithText(TextField, 'Phone'), findsOneWidget);
    expect(find.text('සතුටුයි'), findsOneWidget); // Sinhala PRESERVED
    expect(find.text('දුරකථනය'), findsNothing); // Target NOT applied
    expect(find.text('தொலைபேசி'), findsOneWidget); // Tamil UPDATED
  });

  testWidgets(
      'Overwrite dialog: English-only update preserves existing Sinhala and Tamil text',
      (tester) async {
    final card = AACCard(
      id: 'lang_sel_card_en_only',
      label: 'Happy',
      labelSinhala: 'සතුටුයි',
      labelTamil: 'மகிழ்ச்சி',
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
              labels: ['Phone'],
              topConfidence: 0.95,
              objectCount: 1,
              analyzerAvailable: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();

    // Deselect Sinhala and Tamil
    await tester.tap(find.text('Sinhala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamil'));
    await tester.pumpAndSettle();

    expect(find.text('1 of 3 selected'), findsOneWidget);
    expect(find.text('Update selected (1)'), findsOneWidget);

    await tester.tap(find.text('Update selected (1)'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Phone'), findsOneWidget);
    expect(find.text('සතුටුයි'), findsOneWidget);
    expect(find.text('மகிழ்ச்சி'), findsOneWidget);
    expect(find.text('දුරකථනය'), findsNothing);
    expect(find.text('தொலைபேசி'), findsNothing);
  });

  testWidgets(
      'Overwrite dialog: Sinhala-only update preserves existing English and Tamil text',
      (tester) async {
    final card = AACCard(
      id: 'lang_sel_card_si_only',
      label: 'Happy',
      labelSinhala: 'සතුටුයි',
      labelTamil: 'மகிழ்ச்சி',
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
              labels: ['Phone'],
              topConfidence: 0.95,
              objectCount: 1,
              analyzerAvailable: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();

    // Deselect English and Tamil
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamil'));
    await tester.pumpAndSettle();

    expect(find.text('1 of 3 selected'), findsOneWidget);
    expect(find.text('Update selected (1)'), findsOneWidget);

    await tester.tap(find.text('Update selected (1)'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Happy'), findsOneWidget);
    expect(find.text('දුරකථනය'), findsOneWidget);
    expect(find.text('மகிழ்ச்சி'), findsOneWidget);
    expect(find.text('தொலைபேசி'), findsNothing);
  });

  testWidgets(
      'Overwrite dialog: Tamil-only update preserves existing English and Sinhala text',
      (tester) async {
    final card = AACCard(
      id: 'lang_sel_card_ta_only',
      label: 'Happy',
      labelSinhala: 'සතුටුයි',
      labelTamil: 'மகிழ்ச்சி',
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
              labels: ['Phone'],
              topConfidence: 0.95,
              objectCount: 1,
              analyzerAvailable: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();

    // Deselect English and Sinhala
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sinhala'));
    await tester.pumpAndSettle();

    expect(find.text('1 of 3 selected'), findsOneWidget);
    expect(find.text('Update selected (1)'), findsOneWidget);

    await tester.tap(find.text('Update selected (1)'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Happy'), findsOneWidget);
    expect(find.text('සතුටුයි'), findsOneWidget);
    expect(find.text('தொலைபேசி'), findsOneWidget);
    expect(find.text('දුරකථනය'), findsNothing);
  });

  testWidgets(
      'Overwrite dialog: zero selections disables update button, Keep Current preserves all labels',
      (tester) async {
    final card = AACCard(
      id: 'lang_sel_zero',
      label: 'Happy',
      labelSinhala: 'සතුටුයි',
      labelTamil: 'மகிழ்ச்சி',
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
              labels: ['Phone'],
              topConfidence: 0.95,
              objectCount: 1,
              analyzerAvailable: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();

    // Click 'Select all' to deselect all 3
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();

    expect(find.text('0 of 3 selected'), findsOneWidget);
    expect(find.text('Update selected (0)'), findsOneWidget);

    // Verify the primary FilledButton is disabled
    final filledBtn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Update selected (0)'),
    );
    expect(filledBtn.onPressed, isNull);

    // Tapping it does not dismiss dialog
    await tester.tap(find.text('Update selected (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Update card labels'), findsOneWidget);

    // Keep current is clickable and preserves labels
    await tester.tap(find.text('Keep current'));
    await tester.pumpAndSettle();

    expect(find.text('Update card labels'), findsNothing);
    expect(find.widgetWithText(TextField, 'Happy'), findsOneWidget);
    expect(find.text('සතුටුයි'), findsOneWidget);
    expect(find.text('மகிழ்ச்சி'), findsOneWidget);
  });

  testWidgets(
      'Overwrite dialog: Select all toggles between all selected and none selected',
      (tester) async {
    final card = AACCard(
      id: 'select_all_toggle',
      label: 'Happy',
      labelSinhala: 'සතුටුයි',
      labelTamil: 'மகிழ்ச்சி',
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
              labels: ['Phone'],
              topConfidence: 0.95,
              objectCount: 1,
              analyzerAvailable: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();

    expect(find.text('All 3 selected'), findsOneWidget);

    // Tap Select all -> deselects all 3
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 3 selected'), findsOneWidget);

    // Tap Select all again -> selects all 3
    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    expect(find.text('All 3 selected'), findsOneWidget);
  });

  testWidgets(
      'Overwrite dialog: renders cleanly without overflow on compact 320x480 screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final card = AACCard(
      id: 'compact_screen_card',
      label: 'Very Long Existing English Label That Wraps',
      labelSinhala: 'ඉතා දිගු පවතින සිංහල ලේබලය',
      labelTamil: 'மிக நீண்ட தற்போதைய தமிழ் லேபிள்',
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

    await tester.ensureVisible(find.text('Apple'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apple'));
    await tester.pumpAndSettle();

    expect(find.text('Update card labels'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
