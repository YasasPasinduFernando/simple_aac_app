import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/widgets/add_category_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleCards = [
    AACCard(
      id: 'card_food_1',
      label: 'Water',
      labelSinhala: 'වතුර',
      labelTamil: 'தண்ணீர்',
      category: 'General',
      colorValue: 0xFF90CAF9,
    ),
    AACCard(
      id: 'card_food_2',
      label: 'Rice',
      labelSinhala: 'බත්',
      labelTamil: 'சோறு',
      category: 'Food & Drink',
      colorValue: 0xFFFFF59D,
    ),
    AACCard(
      id: 'card_other_1',
      label: 'Ball',
      labelSinhala: 'බෝලය',
      labelTamil: 'பந்து',
      category: 'General',
      colorValue: 0xFFA5D6A7,
    ),
  ];

  group('AddCategoryDialog Tests', () {
    testWidgets('renders all sections and components properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddCategoryDialog(
              availableCards: sampleCards,
              existingCategories: const {'General', 'Food & Drink'},
              currentLanguage: 'en',
              onAddCategory: (_, __, ___, ____) {},
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('Add New Category'), findsOneWidget);
      expect(find.text('Create, customize & assign cards'), findsOneWidget);

      // Verify Live Preview
      expect(find.text('LIVE CATEGORY PREVIEW'), findsOneWidget);
      expect(find.text('Tap cards below to assign to this category'), findsOneWidget);

      // Verify Section headers
      expect(find.text('QUICK PRESETS'), findsOneWidget);
      expect(find.text('CHOOSE ICON'), findsOneWidget);
      expect(find.text('COLOR ACCENT'), findsOneWidget);
      expect(find.text('ASSIGN CARDS TO CATEGORY'), findsOneWidget);

      // Verify Cards in list
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Rice'), findsOneWidget);
      expect(find.text('Ball'), findsOneWidget);
    });

    testWidgets('preset tap updates name, icon, color and auto-assigns matching cards',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddCategoryDialog(
              availableCards: sampleCards,
              existingCategories: const {'General'},
              currentLanguage: 'en',
              onAddCategory: (_, __, ___, ____) {},
            ),
          ),
        ),
      );

      // Tap 'Food' preset chip
      final foodChip = find.text('Food');
      expect(foodChip, findsOneWidget);
      await tester.tap(foodChip);
      await tester.pumpAndSettle();

      // Category name should be 'Food'
      expect(find.widgetWithText(TextField, 'Food'), findsOneWidget);

      // Card count should reflect auto-matched food cards (Water & Rice)
      expect(find.text('2 cards in this category'), findsOneWidget);
      expect(find.text('Add Category (2)'), findsOneWidget);
    });

    testWidgets('search filters card list and Select All / Clear works',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddCategoryDialog(
              availableCards: sampleCards,
              existingCategories: const {'General'},
              currentLanguage: 'en',
              onAddCategory: (_, __, ___, ____) {},
            ),
          ),
        ),
      );

      // Enter search query 'Rice'
      final searchField = find.widgetWithText(TextField, 'Search cards to assign...');
      await tester.enterText(searchField, 'Rice');
      await tester.pumpAndSettle();

      // Only 'Rice' card tile should be visible in the list
      expect(find.widgetWithText(CheckboxListTile, 'Rice'), findsOneWidget);
      expect(find.widgetWithText(CheckboxListTile, 'Ball'), findsNothing);

      // Tap Select All (1)
      final selectAllBtn = find.text('Select All (1)');
      expect(selectAllBtn, findsOneWidget);
      await tester.ensureVisible(selectAllBtn);
      await tester.tap(selectAllBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('1 cards in this category'), findsOneWidget);

      // Tap Clear Selection
      final clearBtn = find.text('Clear Selection');
      await tester.ensureVisible(clearBtn);
      await tester.tap(clearBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Tap cards below to assign to this category'), findsOneWidget);
    });

    testWidgets('prevents duplicate category creation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddCategoryDialog(
              availableCards: sampleCards,
              existingCategories: const {'General', 'Food'},
              currentLanguage: 'en',
              onAddCategory: (_, __, ___, ____) {},
            ),
          ),
        ),
      );

      // Enter duplicate name 'Food'
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Food');
      await tester.pumpAndSettle();

      // Should show duplicate error
      expect(find.text('Category with this name already exists'), findsOneWidget);

      // Submit button should be disabled
      final submitBtn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(submitBtn.onPressed, isNull);
    });

    testWidgets('submits properly with selected cards, custom icon and color',
        (tester) async {
      String? submittedName;
      Set<String>? submittedCards;
      int? submittedColor;
      IconData? submittedIcon;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddCategoryDialog(
              availableCards: sampleCards,
              existingCategories: const {'General'},
              currentLanguage: 'en',
              onAddCategory: (name, cards, color, icon) {
                submittedName = name;
                submittedCards = cards;
                submittedColor = color;
                submittedIcon = icon;
              },
            ),
          ),
        ),
      );

      // Enter Category Name
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Animals');
      await tester.pumpAndSettle();

      // Select 'Water' card checkbox
      await tester.ensureVisible(find.text('Water'));
      await tester.tap(find.text('Water'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Submit
      final addBtn = find.widgetWithText(FilledButton, 'Add Category (1)');
      expect(addBtn, findsOneWidget);
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(submittedName, equals('Animals'));
      expect(submittedCards, contains('card_food_1'));
      expect(submittedColor, isNotNull);
      expect(submittedIcon, isNotNull);
    });

    testWidgets('reset button resets form state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddCategoryDialog(
              availableCards: sampleCards,
              existingCategories: const {'General'},
              currentLanguage: 'en',
              onAddCategory: (_, __, ___, ____) {},
            ),
          ),
        ),
      );

      // Enter name and select card
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'My Custom');
      await tester.ensureVisible(find.text('Ball'));
      await tester.tap(find.text('Ball'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('1 cards in this category'), findsOneWidget);

      // Tap Reset
      final resetBtn = find.text('Reset');
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Should be back to initial state
      expect(find.text('Tap cards below to assign to this category'), findsOneWidget);
    });
  });
}
