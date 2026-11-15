import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/widgets/preview/grid_density_preview.dart';
import 'package:simple_aac_app/widgets/preview/live_preview_panel.dart';
import 'package:simple_aac_app/widgets/preview/tts_composer_preview.dart';
import 'package:simple_aac_app/widgets/preview/visible_cards_preview.dart';
import 'package:simple_aac_app/widgets/visible_cards_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.speakPerformer = (_) async {};
    HomePage.hapticPerformer = () async {};
  });

  group('LivePreviewPanel Widget Tests', () {
    testWidgets('renders title, live badge and child properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LivePreviewPanel(
              title: 'LIVE PREVIEW',
              icon: Icons.record_voice_over_rounded,
              trailing: Text('Trailing Action'),
              child: Text('Sample Preview Child'),
            ),
          ),
        ),
      );

      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.byIcon(Icons.record_voice_over_rounded), findsOneWidget);
      expect(find.text('Trailing Action'), findsOneWidget);
      expect(find.text('Sample Preview Child'), findsOneWidget);
    });
  });

  group('TtsComposerPreview Widget Tests', () {
    testWidgets(
        'renders sample tokens, speaker button and reacts to showActions',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TtsComposerPreview(
              sizeFactor: 1.0,
              showActions: true,
              showText: true,
            ),
          ),
        ),
      );

      expect(find.text('I want'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('hides Delete and Clear pills when showActions is false',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TtsComposerPreview(
              sizeFactor: 1.0,
              showActions: false,
              showText: true,
            ),
          ),
        ),
      );

      expect(find.text('I want'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Clear'), findsNothing);
    });

    testWidgets('hides token text when showText is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TtsComposerPreview(
              sizeFactor: 1.0,
              showActions: true,
              showText: false,
            ),
          ),
        ),
      );

      expect(find.text('I want'), findsNothing);
      expect(find.text('Water'), findsNothing);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);
    });

    testWidgets(
        'handles extreme scale factors (0.5 to 2.5) without layout overflow',
        (tester) async {
      for (final factor in [0.5, 1.0, 1.5, 2.0, 2.5]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                child: TtsComposerPreview(
                  sizeFactor: factor,
                  showActions: true,
                  showText: true,
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('GridDensityPreview Widget Tests', () {
    testWidgets('renders 1 through 5 columns cleanly with aspect ratios',
        (tester) async {
      final sampleCards = [
        AACCard(id: 'c1', label: 'Hello', colorValue: 0xFFFEE685),
        AACCard(id: 'c2', label: 'Happy', colorValue: 0xFFB9DCFE),
        AACCard(
            id: 'c3', label: 'More', colorValue: 0xFFFEE685, type: 'folder'),
      ];

      for (int cols = 1; cols <= 5; cols++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 200,
                child: GridDensityPreview(
                  columns: cols,
                  cards: sampleCards,
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Hello'), findsOneWidget);
      }
    });

    testWidgets('uses fallback default sample cards when empty cards passed',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 200,
              child: GridDensityPreview(
                columns: 2,
                cards: [],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Sad'), findsOneWidget);
    });
  });

  group('VisibleCardsPreview & VisibleCardsDialog Tests', () {
    final testCards = [
      AACCard(id: 'c1', label: 'Hello', colorValue: 0xFFFEE685),
      AACCard(id: 'c2', label: 'Water', colorValue: 0xFFB9DCFE),
      AACCard(id: 'c3', label: 'Food', colorValue: 0xFFBAE6FD),
    ];

    testWidgets('VisibleCardsPreview displays only selected cards',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 200,
              child: VisibleCardsPreview(
                cards: testCards,
                selectedIds: const {'c1'},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Water'), findsNothing);
      expect(find.text('Food'), findsNothing);
    });

    testWidgets('VisibleCardsPreview renders empty state when 0 cards visible',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 200,
              child: VisibleCardsPreview(
                cards: testCards,
                selectedIds: const {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('No cards visible'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
    });

    testWidgets('VisibleCardsDialog Select All, Clear All, and Done flow',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Set<String>? submittedSelection;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: testCards,
              currentLanguage: 'en',
              initialSelectedIds: const {'c1'},
              gridColumns: 2,
              onSubmit: (selected) => submittedSelection = selected,
            ),
          ),
        ),
      );

      // Verify initial live badge
      expect(find.text('1 of 3 visible'), findsOneWidget);

      // Tap "Select all"
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();
      expect(find.text('3 of 3 visible'), findsOneWidget);

      // Tap "Clear all"
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();
      expect(find.text('0 of 3 visible'), findsOneWidget);
      expect(find.text('No cards visible'), findsOneWidget);

      // Toggle 'c2' (Water)
      final waterTile = find.widgetWithText(CheckboxListTile, 'Water');
      await tester.tap(waterTile);
      await tester.pumpAndSettle();
      expect(find.text('1 of 3 visible'), findsOneWidget);

      // Tap 'Done'
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(submittedSelection, isNotNull);
      expect(submittedSelection, contains('c2'));
      expect(submittedSelection!.length, equals(1));
    });

    testWidgets('VisibleCardsDialog Cancel does not invoke onSubmit',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Set<String>? submittedSelection;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisibleCardsDialog(
              cards: testCards,
              currentLanguage: 'en',
              initialSelectedIds: const {'c1', 'c2'},
              gridColumns: 2,
              onSubmit: (selected) => submittedSelection = selected,
            ),
          ),
        ),
      );

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(submittedSelection, isNull);
    });
  });

  group('HomePage Dialog Integration Tests', () {
    testWidgets(
        'TTS Bar Sizing dialog live preview, slider, Reset draft, and Apply',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Tap "TTS Bar Sizing" item in drawer
      final ttsTile = find.byIcon(Icons.text_increase_rounded);
      await tester.scrollUntilVisible(ttsTile, 200);
      await tester.tap(ttsTile);
      await tester.pumpAndSettle();

      // Verify Live Preview is present
      expect(find.text('TTS Bar Sizing'), findsOneWidget);
      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.text('I want'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);

      // Toggle "Show Delete / Clear"
      final switchTile =
          find.widgetWithText(SwitchListTile, 'Show Delete / Clear');
      expect(switchTile, findsOneWidget);
      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      // Reset button resets draft state only (dialog remains open)
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('TTS Bar Sizing'), findsOneWidget);
      expect(find.text('Size: 100%'), findsOneWidget);

      // Apply button persists and dismisses dialog
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('TTS Bar Sizing'), findsNothing);
    });

    testWidgets('Select Grid Size dialog live preview reflow, Cancel vs Apply',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Tap "Grid Columns"
      final gridTile = find.text('Grid Columns');
      await tester.scrollUntilVisible(gridTile, 200);
      await tester.tap(gridTile);
      await tester.pumpAndSettle();

      // Verify Live Grid Preview is present
      expect(find.text('Select Grid Size'), findsOneWidget);
      expect(find.text('LIVE GRID PREVIEW'), findsOneWidget);

      // Tap 3x option (Medium)
      final threeColsOption = find.text('Medium');
      await tester.ensureVisible(threeColsOption);
      await tester.tap(threeColsOption);
      await tester.pumpAndSettle();

      // Density indicator updates
      expect(find.text('3 Columns • Medium'), findsOneWidget);

      // Cancel button closes without saving
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Select Grid Size'), findsNothing);
    });

    testWidgets(
        'Narrow viewport (320px) and large text scale (1.8x) render without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 600 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 600),
              textScaler: TextScaler.linear(1.8),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    LivePreviewPanel(
                      title: 'LIVE PREVIEW',
                      child: TtsComposerPreview(
                        sizeFactor: 1.0,
                        showActions: true,
                        showText: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    LivePreviewPanel(
                      title: 'LIVE GRID PREVIEW',
                      child: GridDensityPreview(
                        columns: 2,
                        cards: [],
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
      expect(tester.takeException(), isNull);
    });
  });
}
