import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/storage_service.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';
import 'package:simple_aac_app/widgets/preview/grid_density_preview.dart';
import 'package:simple_aac_app/widgets/select_grid_size_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    HomePage.initialCardsForTesting = null;
  });

  group('SelectGridSizeDialog UI & Controls Tests', () {
    testWidgets('renders all dialog elements and initial state correctly',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? appliedColumns;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectGridSizeDialog(
              currentColumns: 2,
              cards: const [],
              currentLanguage: 'en',
              onApply: (val) => appliedColumns = val,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Select Grid Size'), findsOneWidget);
      expect(find.text('Choose card size & column density.'), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

      // Live Grid Preview
      expect(find.text('LIVE GRID PREVIEW'), findsOneWidget);
      expect(find.byType(GridDensityPreview), findsOneWidget);

      // Stepper
      expect(find.text('Columns per row'), findsOneWidget);
      expect(find.byKey(const ValueKey('grid_stepper_minus')), findsOneWidget);
      expect(find.byKey(const ValueKey('grid_columns_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('grid_stepper_plus')), findsOneWidget);
      expect(find.text('2'), findsWidgets); // stepper & preset button

      // Slider & Ticks
      expect(find.byKey(const ValueKey('grid_columns_slider')), findsOneWidget);
      for (final tick in [1, 5, 10, 15, 20, 25, 30]) {
        expect(find.text('$tick'), findsWidgets);
      }

      // Presets
      for (int i = 1; i <= 5; i++) {
        expect(find.text('$i'), findsWidgets);
      }
      expect(find.text('Custom'), findsOneWidget);

      // Pill
      expect(find.text('2 columns selected'), findsOneWidget);

      // Helper
      expect(
          find.text('On smaller screens, swipe to see more cards.'), findsOneWidget);
      expect(find.text('You can type a number up to 30.'), findsOneWidget);

      // Action buttons
      expect(find.byKey(const ValueKey('grid_dialog_cancel')), findsOneWidget);
      expect(find.byKey(const ValueKey('grid_dialog_reset')), findsOneWidget);
      expect(find.byKey(const ValueKey('grid_dialog_apply')), findsOneWidget);

      // Verify Cancel closes without applying
      await tester.tap(find.byKey(const ValueKey('grid_dialog_cancel')));
      await tester.pumpAndSettle();
      expect(appliedColumns, isNull);
    });

    testWidgets('Preset buttons 1 through 5 update column count and pill',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectGridSizeDialog(
              currentColumns: 2,
              onApply: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Preset 1
      await tester.tap(find.widgetWithText(InkWell, '1'));
      await tester.pumpAndSettle();
      expect(find.text('1 column selected'), findsOneWidget);

      // Tap Preset 4
      await tester.tap(find.widgetWithText(InkWell, '4'));
      await tester.pumpAndSettle();
      expect(find.text('4 columns selected'), findsOneWidget);

      // Tap Preset 5
      await tester.tap(find.widgetWithText(InkWell, '5'));
      await tester.pumpAndSettle();
      expect(find.text('5 columns selected'), findsOneWidget);
    });

    testWidgets('Custom preset sets custom density and highlights Custom',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectGridSizeDialog(
              currentColumns: 2,
              onApply: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Custom
      await tester.tap(find.widgetWithText(InkWell, 'Custom'));
      await tester.pumpAndSettle();

      // Defaults to 12 when transitioning from <=5
      expect(find.text('12 columns selected'), findsOneWidget);
    });

    testWidgets('Stepper plus and minus buttons correctly adjust columns',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectGridSizeDialog(
              currentColumns: 2,
              onApply: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final plusBtn = find.byKey(const ValueKey('grid_stepper_plus'));
      final minusBtn = find.byKey(const ValueKey('grid_stepper_minus'));

      // Increment 2 -> 3
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();
      expect(find.text('3 columns selected'), findsOneWidget);

      // Decrement 3 -> 2 -> 1
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
      expect(find.text('2 columns selected'), findsOneWidget);

      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
      expect(find.text('1 column selected'), findsOneWidget);

      // Decrement at 1 should be disabled/no-op
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
      expect(find.text('1 column selected'), findsOneWidget);
    });

    testWidgets('Typing into columns input updates density', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectGridSizeDialog(
              currentColumns: 2,
              onApply: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final input = find.byKey(const ValueKey('grid_columns_input'));
      await tester.enterText(input, '18');
      await tester.pumpAndSettle();

      expect(find.text('18 columns selected'), findsOneWidget);
    });

    testWidgets('Reset button restores column count to 2', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectGridSizeDialog(
              currentColumns: 2,
              onApply: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Change to 5
      await tester.tap(find.widgetWithText(InkWell, '5'));
      await tester.pumpAndSettle();
      expect(find.text('5 columns selected'), findsOneWidget);

      // Tap Reset
      await tester.tap(find.byKey(const ValueKey('grid_dialog_reset')));
      await tester.pumpAndSettle();
      expect(find.text('2 columns selected'), findsOneWidget);
    });
  });

  group('High Grid Density Safeguard Warning Tests', () {
    testWidgets(
        'Selecting <= 10 columns applies directly without showing warning dialog',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? appliedColumns;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectGridSizeDialog(
              currentColumns: 2,
              onApply: (val) => appliedColumns = val,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Choose 4 columns
      await tester.tap(find.widgetWithText(InkWell, '4'));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.byKey(const ValueKey('grid_dialog_apply')));
      await tester.pumpAndSettle();

      // Applied directly, no warning dialog shown
      expect(find.text('High Grid Density'), findsNothing);
      expect(appliedColumns, equals(4));
    });

    testWidgets(
        'Selecting > 10 columns (e.g. 15) triggers High Grid Density warning dialog',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? appliedColumns;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectGridSizeDialog(
              currentColumns: 2,
              onApply: (val) => appliedColumns = val,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type 15 columns
      final input = find.byKey(const ValueKey('grid_columns_input'));
      await tester.enterText(input, '15');
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.byKey(const ValueKey('grid_dialog_apply')));
      await tester.pumpAndSettle();

      // Warning dialog appears
      expect(find.text('High Grid Density'), findsOneWidget);
      expect(find.textContaining("You've selected 15 columns."), findsOneWidget);
      expect(find.textContaining("recommend 2–5 columns on phones and up to 15 on larger tablets."), findsOneWidget);
      expect(find.byKey(const ValueKey('grid_warning_back')), findsOneWidget);
      expect(find.byKey(const ValueKey('grid_warning_confirm')), findsOneWidget);

      // Tap Go Back: warning dismissed, not applied yet
      await tester.tap(find.byKey(const ValueKey('grid_warning_back')));
      await tester.pumpAndSettle();
      expect(find.text('High Grid Density'), findsNothing);
      expect(appliedColumns, isNull);

      // Tap Apply again
      await tester.tap(find.byKey(const ValueKey('grid_dialog_apply')));
      await tester.pumpAndSettle();

      // Tap Confirm: applies and closes
      await tester.tap(find.byKey(const ValueKey('grid_warning_confirm')));
      await tester.pumpAndSettle();
      expect(appliedColumns, equals(15));
    });

    testWidgets(
        'Leaving already > 10 columns unchanged applies without warning dialog',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? appliedColumns;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectGridSizeDialog(
              currentColumns: 16,
              onApply: (val) => appliedColumns = val,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Directly tap Apply without changing
      await tester.tap(find.byKey(const ValueKey('grid_dialog_apply')));
      await tester.pumpAndSettle();

      expect(find.text('High Grid Density'), findsNothing);
      expect(appliedColumns, equals(16));
    });
  });

  group('GridDensityPreview Multi-Density Support Tests', () {
    testWidgets('renders densities 1 through 5 without errors',
        (tester) async {
      for (int c = 1; c <= 5; c++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 120,
                child: GridDensityPreview(columns: c),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
        'renders high densities (6, 12, 20, 30) with horizontal scroll view without overflow',
        (tester) async {
      for (final c in [6, 12, 20, 30]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 120,
                child: GridDensityPreview(columns: c),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      }
    });
  });

  group('StorageService Grid Columns Persistence Tests', () {
    test('saveGridColumns and loadGridColumns roundtrip within 1..30',
        () async {
      await StorageService.saveGridColumns(8);
      final loaded = await StorageService.loadGridColumns();
      expect(loaded, equals(8));
    });

    test('Clamps out-of-range values to [1, 30]', () async {
      await StorageService.saveGridColumns(0);
      expect(await StorageService.loadGridColumns(), equals(1));

      await StorageService.saveGridColumns(50);
      expect(await StorageService.loadGridColumns(), equals(30));

      await StorageService.saveGridColumns(-5);
      expect(await StorageService.loadGridColumns(), equals(1));
    });
  });

  group('HomePage Responsive Grid Integration Tests', () {
    testWidgets('Opening Grid Columns from drawer and applying updates grid',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      HomePage.initialCardsForTesting = [
        AACCard(id: 'c1', label: 'Hello', colorValue: 0xFFFEE685),
        AACCard(id: 'c2', label: 'Water', colorValue: 0xFFB9DCFE),
      ];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Scroll drawer to see Grid Columns tile
      final drawerScrollable = find.descendant(
        of: find.byType(HomeDrawer),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Grid Columns'),
        200,
        scrollable: drawerScrollable,
      );
      await tester.tap(find.text('Grid Columns'));
      await tester.pumpAndSettle();

      expect(find.text('Select Grid Size'), findsOneWidget);

      // Select preset 3
      await tester.tap(find.widgetWithText(InkWell, '3'));
      await tester.pumpAndSettle();
      expect(find.text('3 columns selected'), findsOneWidget);

      // Apply
      await tester.tap(find.byKey(const ValueKey('grid_dialog_apply')));
      await tester.pumpAndSettle();

      expect(find.text('Select Grid Size'), findsNothing);

      // Verify subtitle updated on open drawer
      expect(find.text('3 columns'), findsOneWidget);
    });

    testWidgets(
        'High column density (20 columns) renders horizontally scrollable canvas with readable cards',
        (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Pre-seed 20 columns in SharedPreferences and set initial cards
      SharedPreferences.setMockInitialValues({'gridColumns': 20});
      HomePage.initialCardsForTesting = [
        AACCard(id: 'c1', label: 'Hello', colorValue: 0xFFFEE685),
        AACCard(id: 'c2', label: 'Water', colorValue: 0xFFB9DCFE),
        AACCard(id: 'c3', label: 'Food', colorValue: 0xFFBBF7D0),
      ];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Expect horizontal scrollbar / SingleChildScrollView to be present
      expect(find.byType(Scrollbar), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
