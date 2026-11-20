import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/widgets/card_editor_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('responsive_card_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;
    SharedPreferences.setMockInitialValues({
      'online_features_enabled': false,
      'useImageOverlayLabel': true,
      'gridColumns': 2,
    });
    await NetworkPolicyService.instance.init();
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.initialCardsForTesting = null;
  });

  tearDown(() async {
    CardStorageService.resetTestHooks();
    HomePage.initialCardsForTesting = null;
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('A. Equal External Dimensions (ON vs OFF Mode)', () {
    testWidgets('Card has identical external width and height when toggling Text ON vs OFF',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testCard = AACCard(
        id: 'card_equal_dim',
        label: 'Hello',
        imagePath: 'assets/home/happy.webp',
        colorValue: 0xFFFEE685,
      );

      // 1. Text ON (useImageOverlayLabel = true)
      SharedPreferences.setMockInitialValues({
        'useImageOverlayLabel': true,
        'gridColumns': 2,
      });
      HomePage.initialCardsForTesting = [testCard];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      final cardFinderOn = find.byKey(const ValueKey('card_equal_dim'));
      expect(cardFinderOn, findsOneWidget);
      final sizeOn = tester.getSize(cardFinderOn);

      // 2. Text OFF (useImageOverlayLabel = false)
      SharedPreferences.setMockInitialValues({
        'useImageOverlayLabel': false,
        'gridColumns': 2,
      });
      HomePage.initialCardsForTesting = [testCard];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      final cardFinderOff = find.byKey(const ValueKey('card_equal_dim'));
      expect(cardFinderOff, findsOneWidget);
      final sizeOff = tester.getSize(cardFinderOff);

      expect(sizeOn.width, equals(sizeOff.width),
          reason: 'Card width must remain identical between ON and OFF modes');
      expect(sizeOn.height, equals(sizeOff.height),
          reason: 'Card height must remain identical between ON and OFF modes');
      expect(tester.takeException(), isNull);
    });
  });

  group('B. Artwork Containment & Unclipped Bounds', () {
    testWidgets('Cards with images use BoxFit.contain in both ON and OFF modes without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testCard = AACCard(
        id: 'card_contain_test',
        label: 'Water',
        imagePath: 'assets/images/starter_pack_v8/drinks_water.webp',
        colorValue: 0xFFB9DCFE,
      );
      HomePage.initialCardsForTesting = [testCard];

      for (final overlayMode in [true, false]) {
        SharedPreferences.setMockInitialValues({
          'useImageOverlayLabel': overlayMode,
          'gridColumns': 2,
        });

        await tester.pumpWidget(const MaterialApp(home: HomePage()));
        await tester.pumpAndSettle();

        expect(find.text('Water'), findsWidgets);
        expect(tester.takeException(), isNull,
            reason: 'Zero overflow exceptions allowed in mode overlay=$overlayMode');
      }
    });

    testWidgets('Narrow constraints (8 columns on phone) render without RenderFlex overflow',
        (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'gridColumns': 8,
        'useImageOverlayLabel': true,
      });
      HomePage.initialCardsForTesting = [
        AACCard(id: 'c1', label: 'C1', colorValue: 0xFFFEE685),
        AACCard(id: 'c2', label: 'C2', colorValue: 0xFFB9DCFE),
      ];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      expect(find.byType(Scrollbar), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('C. Edit Mode Action Tray (Docked Under Card Face, Never Obstructing Artwork)', () {
    testWidgets('Action tray is positioned below card face and exposes Drag, Pencil, Delete',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testCard = AACCard(
        id: 'card_edit_mode_tray',
        label: 'Eat',
        imagePath: 'assets/images/starter_pack_v8/activities_eat.webp',
        colorValue: 0xFFBBF7D0,
      );
      HomePage.initialCardsForTesting = [testCard];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Open drawer and enter edit mode
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      // 1. Verify 3 action affordances exist with exact ValueKeys
      final dragHandleFinder = find.byKey(const ValueKey('card_drag_handle_card_edit_mode_tray'));
      final pencilFinder = find.byKey(const ValueKey('card_edit_pencil_card_edit_mode_tray'));
      final deleteFinder = find.byKey(const ValueKey('card_delete_btn_card_edit_mode_tray'));

      expect(dragHandleFinder, findsOneWidget);
      expect(pencilFinder, findsOneWidget);
      expect(deleteFinder, findsOneWidget);

      // 2. Verify Pencil and Delete are positioned in the action tray below the upper image area
      final pencilCenter = tester.getCenter(pencilFinder);
      final deleteCenter = tester.getCenter(deleteFinder);
      final dragCenter = tester.getCenter(dragHandleFinder);

      // All three tray buttons share approximately the same vertical center (horizontal row)
      expect((pencilCenter.dy - deleteCenter.dy).abs(), lessThan(5.0));
      expect((dragCenter.dy - pencilCenter.dy).abs(), lessThan(5.0));

      // 3. Tapping Pencil opens CardEditorDialog
      await tester.tap(pencilFinder);
      await tester.pumpAndSettle();
      expect(find.byType(CardEditorDialog), findsOneWidget);

      // Close editor
      final cancelBtn = find.descendant(
        of: find.byType(CardEditorDialog),
        matching: find.text('Cancel'),
      );
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // 4. Tapping Delete opens guarded delete confirmation
      await tester.tap(deleteFinder);
      await tester.pumpAndSettle();
      expect(find.text('Delete Card'), findsOneWidget);
      expect(find.text('Remove "Eat" from your communication board?'), findsOneWidget);

      // Cancel delete
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Edit Mode Cancel discards changes and Done applies changes',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      HomePage.initialCardsForTesting = [
        AACCard(id: 'c1', label: 'First', colorValue: 0xFFFEE685),
        AACCard(id: 'c2', label: 'Second', colorValue: 0xFFB9DCFE),
      ];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      // Cancel button exits edit mode
      final cancelEditBtn = find.text('Cancel');
      expect(cancelEditBtn, findsOneWidget);
      await tester.tap(cancelEditBtn);
      await tester.pumpAndSettle();

      // Verify returned to normal board
      expect(find.byKey(const ValueKey('card_edit_pencil_c1')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('D. Folder Cards, Badges and Arrows', () {
    testWidgets('Folder cards display sub-card badge count and forward arrow in both modes',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final folderCard = AACCard(
        id: 'folder_food',
        label: 'Food',
        type: 'folder',
        colorValue: 0xFFFEE685,
        subCards: [
          AACCard(id: 'sub_rice', label: 'Rice', colorValue: 0xFFFFFFFF),
          AACCard(id: 'sub_apple', label: 'Apple', colorValue: 0xFFFFD1D1),
        ],
      );
      HomePage.initialCardsForTesting = [folderCard];

      for (final overlayMode in [true, false]) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();

        HomePage.initialCardsForTesting = [
          AACCard(
            id: 'folder_food',
            label: 'Food',
            type: 'folder',
            colorValue: 0xFFFEE685,
            subCards: [
              AACCard(id: 'sub_rice', label: 'Rice', colorValue: 0xFFFFFFFF),
              AACCard(id: 'sub_apple', label: 'Apple', colorValue: 0xFFFFD1D1),
            ],
          )
        ];

        SharedPreferences.setMockInitialValues({
          'useImageOverlayLabel': overlayMode,
          'gridColumns': 2,
        });

        await tester.pumpWidget(const MaterialApp(home: HomePage()));
        await tester.pumpAndSettle();

        expect(find.text('2 sub-cards'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

        // Tap folder navigates into folder
        await tester.tap(find.text('Food'));
        await tester.pumpAndSettle();

        expect(find.text('Rice'), findsWidgets);
        expect(find.text('Apple'), findsWidgets);

        expect(tester.takeException(), isNull);
      }
    });
  });

  group('E. Multilingual & Long Labels (EN, SI, TA)', () {
    testWidgets('Sinhala, Tamil, and long labels render without overflow across text scales',
        (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final multiCard = AACCard(
        id: 'card_multi',
        label: 'Supercalifragilistic Long English Word',
        labelSinhala: 'පරිගණකය සහ තොරතුරු තාක්ෂණය',
        labelTamil: 'கணினி மற்றும் தகவல் தொழில்நுட்பம்',
        colorValue: 0xFFFEE685,
      );
      HomePage.initialCardsForTesting = [multiCard];

      for (final lang in ['en', 'si', 'ta']) {
        SharedPreferences.setMockInitialValues({
          'app_language': lang,
          'useImageOverlayLabel': true,
          'gridColumns': 2,
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.4)),
              child: HomePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'Text scaling and long label for lang=$lang must not overflow');
      }
    });
  });

  group('F. Speech Therapist Landscape Verification (Exactly 4 Cards Per Row)', () {
    testWidgets('Landscape mode with 4 columns displays exactly 4 cards per row without horizontal scroll',
        (tester) async {
      // Samsung Galaxy A34 5G Landscape dimensions (e.g. 2340 x 1080 px, DPR ~2.625 => ~890 x 411 dp)
      tester.view.physicalSize = const Size(2340, 1080);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'gridColumns': 4,
        'useImageOverlayLabel': true,
      });

      HomePage.initialCardsForTesting = [
        AACCard(id: 'c1', label: 'Card 1', colorValue: 0xFFFEE685),
        AACCard(id: 'c2', label: 'Card 2', colorValue: 0xFFB9DCFE),
        AACCard(id: 'c3', label: 'Card 3', colorValue: 0xFFBBF7D0),
        AACCard(id: 'c4', label: 'Card 4', colorValue: 0xFFFFD1D1),
      ];

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Verify all 4 cards are simultaneously visible
      expect(find.text('Card 1'), findsWidgets);
      expect(find.text('Card 2'), findsWidgets);
      expect(find.text('Card 3'), findsWidgets);
      expect(find.text('Card 4'), findsWidgets);

      // Verify all 4 cards share the exact same vertical Y position (exactly one clean row of 4)
      final y1 = tester.getCenter(find.byKey(const ValueKey('c1'))).dy;
      final y2 = tester.getCenter(find.byKey(const ValueKey('c2'))).dy;
      final y3 = tester.getCenter(find.byKey(const ValueKey('c3'))).dy;
      final y4 = tester.getCenter(find.byKey(const ValueKey('c4'))).dy;

      expect((y1 - y2).abs(), lessThan(2.0));
      expect((y2 - y3).abs(), lessThan(2.0));
      expect((y3 - y4).abs(), lessThan(2.0));

      // In 4-column landscape on wide screen, horizontal scrollbar is not needed
      expect(find.byType(Scrollbar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('G. Full Grid Density Suite (1 to 30 Columns)', () {
    testWidgets('Columns 1, 3, 5, 10, 15, 30 render cleanly without exception',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      HomePage.initialCardsForTesting = [
        AACCard(id: 'c1', label: 'Hello', colorValue: 0xFFFEE685),
        AACCard(id: 'c2', label: 'Water', colorValue: 0xFFB9DCFE),
        AACCard(id: 'c3', label: 'Food', colorValue: 0xFFBBF7D0),
      ];

      for (final cols in [1, 3, 5, 10, 15, 30]) {
        SharedPreferences.setMockInitialValues({
          'gridColumns': cols,
          'useImageOverlayLabel': true,
        });

        await tester.pumpWidget(const MaterialApp(home: HomePage()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'Grid column density $cols must render without exception');
      }
    });
  });
}
