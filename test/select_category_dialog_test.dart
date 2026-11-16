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
    AACCard(
      id: 'c4',
      label: 'Dog',
      labelSinhala: 'බල්ලා',
      labelTamil: 'நாய்',
      category: 'Animals',
      colorValue: 0xFF4CAF50,
    ),
  ];

  final customMetadata = {
    'CustomHobbies': const CategoryMetadata(
      name: 'CustomHobbies',
      icon: Icons.palette_rounded,
      colorValue: 0xFFAB47BC,
    ),
  };

  void configureScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('ChooseCategoriesDialog (Multi-Category Selection) Tests', () {
    testWidgets('renders Choose Categories title, checkboxes and All Cards',
        (tester) async {
      configureScreen(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectCategoryDialog(
              categories: const ['All', 'General', 'Food', 'School', 'Animals'],
              selectedCategories: const {'All'},
              availableCards: sampleCards,
              customMetadata: customMetadata,
              currentLanguage: 'en',
              onApply: (_) {},
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('Choose Categories'), findsOneWidget);
      expect(
        find.text('Select the categories to show on your board'),
        findsOneWidget,
      );

      // Verify Board Preview Panel
      expect(find.text('BOARD PREVIEW'), findsOneWidget);
      expect(find.text('4 cards from All Categories'), findsOneWidget);

      // Verify Checkboxes present
      expect(find.byType(Checkbox), findsNWidgets(5)); // All + 4 categories

      // All Cards option exists
      expect(find.text('All Cards'), findsOneWidget);
      expect(find.text('Apply (All)'), findsOneWidget);
    });

    testWidgets('selecting multiple categories updates live preview and chips',
        (tester) async {
      configureScreen(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectCategoryDialog(
              categories: const ['All', 'General', 'Food', 'School', 'Animals'],
              selectedCategories: const {'Food'},
              availableCards: sampleCards,
              customMetadata: customMetadata,
              currentLanguage: 'en',
              onApply: (_) {},
            ),
          ),
        ),
      );

      // Initially 1 card from 1 category
      expect(find.text('1 cards from 1 category'), findsOneWidget);
      expect(find.text('Apply (1)'), findsOneWidget);

      // Select Animals
      await tester.ensureVisible(find.text('Animals'));
      await tester.tap(find.text('Animals'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Now 2 cards from 2 categories
      expect(find.text('2 cards from 2 categories'), findsOneWidget);
      expect(find.text('Apply (2)'), findsOneWidget);

      // Both chips should be visible
      expect(find.byIcon(Icons.close_rounded), findsWidgets);
    });

    testWidgets('All Cards is mutually exclusive with individual categories',
        (tester) async {
      configureScreen(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectCategoryDialog(
              categories: const ['All', 'General', 'Food', 'School'],
              selectedCategories: const {'Food', 'School'},
              availableCards: sampleCards,
              customMetadata: customMetadata,
              currentLanguage: 'en',
              onApply: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('2 cards from 2 categories'), findsOneWidget);

      // Tap 'All Cards' -> should deselect Food & School and select All
      await tester.ensureVisible(find.text('All Cards'));
      await tester.tap(find.text('All Cards'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('4 cards from All Categories'), findsOneWidget);
      expect(find.text('Apply (All)'), findsOneWidget);

      // Tap 'General' -> should deselect All Cards and select General
      await tester.ensureVisible(find.text('General'));
      await tester.tap(find.text('General'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('1 cards from 1 category'), findsOneWidget);
      expect(find.text('Apply (1)'), findsOneWidget);
    });

    testWidgets('tapping cross on preview chip removes category',
        (tester) async {
      configureScreen(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectCategoryDialog(
              categories: const ['All', 'General', 'Food', 'School'],
              selectedCategories: const {'Food', 'School'},
              availableCards: sampleCards,
              customMetadata: customMetadata,
              currentLanguage: 'en',
              onApply: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('2 cards from 2 categories'), findsOneWidget);

      // Find close icons in preview chips
      final closeIcons = find.byIcon(Icons.close_rounded);
      expect(closeIcons, findsNWidgets(2)); // 2 chips

      // Tap the first chip close icon
      await tester.tap(closeIcons.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Now only 1 category remains
      expect(find.text('1 cards from 1 category'), findsOneWidget);
      expect(find.text('Apply (1)'), findsOneWidget);
    });

    testWidgets('empty category shows friendly guidance in live preview',
        (tester) async {
      configureScreen(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectCategoryDialog(
              categories: const ['General', 'EmptyTest'],
              selectedCategories: const {'EmptyTest'},
              availableCards: sampleCards,
              customMetadata: customMetadata,
              currentLanguage: 'en',
              onApply: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.text(
          'No cards in the selected categories yet.\nCreate cards in Edit Mode to get started.',
        ),
        findsOneWidget,
      );
      expect(find.text('0 cards from 1 category'), findsOneWidget);
    });

    testWidgets('Apply button triggers onApply with selected categories set',
        (tester) async {
      configureScreen(tester);

      Set<String>? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectCategoryDialog(
              categories: const ['General', 'Food', 'School'],
              selectedCategories: const {'Food'},
              availableCards: sampleCards,
              customMetadata: customMetadata,
              currentLanguage: 'en',
              onApply: (cats) => applied = cats,
            ),
          ),
        ),
      );

      // Select School
      await tester.ensureVisible(find.text('School'));
      await tester.tap(find.text('School'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap Apply (2)
      await tester.ensureVisible(find.text('Apply (2)'));
      await tester.tap(find.text('Apply (2)'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(applied, equals({'Food', 'School'}));
    });

    testWidgets('Cancel button dismisses without calling onApply',
        (tester) async {
      configureScreen(tester);

      Set<String>? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => SelectCategoryDialog(
                    categories: const ['General', 'Food', 'School'],
                    selectedCategories: const {'General'},
                    availableCards: sampleCards,
                    customMetadata: customMetadata,
                    currentLanguage: 'en',
                    onApply: (cats) => applied = cats,
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
      await tester.ensureVisible(find.text('Food'));
      await tester.tap(find.text('Food'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(applied, isNull);
      expect(find.text('Choose Categories'), findsNothing);
    });

    testWidgets('duplicate card prevention across selected categories',
        (tester) async {
      configureScreen(tester);

      // Create cards where c1 has category 'Food' and c1_dup also has 'Food' or duplicate ids
      final duplicateCards = [
        AACCard(
          id: 'card_apple_1',
          label: 'Apple',
          category: 'Food',
          colorValue: 0xFFFFA726,
        ),
        AACCard(
          id: 'card_apple_1', // Duplicate ID
          label: 'Apple',
          category: 'Food',
          colorValue: 0xFFFFA726,
        ),
        AACCard(
          id: 'card_dog',
          label: 'Dog',
          category: 'Animals',
          colorValue: 0xFF4CAF50,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectCategoryDialog(
              categories: const ['Food', 'Animals'],
              selectedCategories: const {'Food', 'Animals'},
              availableCards: duplicateCards,
              customMetadata: customMetadata,
              currentLanguage: 'en',
              onApply: (_) {},
            ),
          ),
        ),
      );

      // Should count 2 unique cards (card_apple_1 and card_dog) instead of 3
      expect(find.text('2 cards from 2 categories'), findsOneWidget);
    });
  });
}
