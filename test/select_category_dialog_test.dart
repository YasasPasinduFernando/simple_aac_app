import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/models/category_metadata.dart';
import 'package:simple_aac_app/widgets/select_category_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleCards = [
    AACCard(
      id: 'c1',
      label: 'Apple',
      labelSinhala: 'ඇපල්',
      labelTamil: 'ஆப்பிள்',
      category: 'Food',
      colorValue: 0xFFFFA726,
    ),
    AACCard(
      id: 'c2',
      label: 'Book',
      labelSinhala: 'පොත',
      labelTamil: 'புத்தகம்',
      category: 'School',
      colorValue: 0xFF42A5F5,
    ),
    AACCard(
      id: 'c3',
      label: 'Hello',
      labelSinhala: 'හෙලෝ',
      labelTamil: 'வணக்கம்',
      category: 'General',
      colorValue: 0xFF90CAF9,
    ),
  ];

  final customMetadata = {
    'CustomHobbies': const CategoryMetadata(
      name: 'CustomHobbies',
      icon: Icons.palette_rounded,
      colorValue: 0xFFAB47BC,
    ),
  };

  group('SelectCategoryDialog Tests', () {
    testWidgets('renders all categories, "All Cards", and live preview header',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectCategoryDialog(
              categories: const ['All', 'General', 'Food', 'School', 'EmptyTest'],
              selectedCategory: 'Food',
              availableCards: sampleCards,
              customMetadata: customMetadata,
              currentLanguage: 'en',
              onApply: (_) {},
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('Select Category'), findsOneWidget);
      expect(find.text('Choose which cards appear on your board'), findsOneWidget);

      // Verify Live Preview shows selected 'Food'
      expect(find.text('CURRENTLY SHOWING'), findsOneWidget);
      expect(find.text('Food'), findsNWidgets(2)); // in preview and list
      expect(find.text('1 card in this category'), findsOneWidget);

      // Verify "All Cards" option exists
      expect(find.text('All Cards'), findsOneWidget);

      // Verify categories in list
      expect(find.text('General'), findsOneWidget);
      expect(find.text('School'), findsOneWidget);
      expect(find.text('EmptyTest'), findsOneWidget);
    });

    testWidgets('empty category shows friendly guidance in live preview',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectCategoryDialog(
              categories: const ['General', 'EmptyTest'],
              selectedCategory: 'EmptyTest',
              availableCards: sampleCards,
              customMetadata: customMetadata,
              currentLanguage: 'en',
              onApply: (_) {},
            ),
          ),
        ),
      );

      // Preview should show empty state guidance
      expect(
        find.text('No cards in this category yet.\nCreate cards in Edit Mode to get started.'),
        findsOneWidget,
      );
      expect(find.text('0 cards'), findsNWidgets(2));
    });

    testWidgets('selecting a different category updates live preview immediately',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectCategoryDialog(
              categories: const ['General', 'Food', 'School'],
              selectedCategory: 'General',
              availableCards: sampleCards,
              customMetadata: customMetadata,
              currentLanguage: 'en',
              onApply: (_) {},
            ),
          ),
        ),
      );

      // Initially showing General
      expect(find.text('CURRENTLY SHOWING'), findsOneWidget);

      // Tap School row
      await tester.tap(find.text('School'));
      await tester.pumpAndSettle();

      // Now previewing selection
      expect(find.text('PREVIEWING SELECTION'), findsOneWidget);
    });

    testWidgets('Apply button triggers onApply with selected category',
        (tester) async {
      String? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectCategoryDialog(
              categories: const ['General', 'Food', 'School'],
              selectedCategory: 'General',
              availableCards: sampleCards,
              customMetadata: customMetadata,
              currentLanguage: 'en',
              onApply: (cat) => applied = cat,
            ),
          ),
        ),
      );

      // Select Food
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(applied, 'Food');
    });

    testWidgets('Cancel button dismisses without calling onApply',
        (tester) async {
      String? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => SelectCategoryDialog(
                    categories: const ['General', 'Food'],
                    selectedCategory: 'General',
                    availableCards: sampleCards,
                    customMetadata: customMetadata,
                    currentLanguage: 'en',
                    onApply: (cat) => applied = cat,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Select Food
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(applied, isNull);
      expect(find.text('Select Category'), findsNothing);
    });
  });
}
