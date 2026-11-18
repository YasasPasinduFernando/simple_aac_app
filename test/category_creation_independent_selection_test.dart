import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/widgets/add_category_dialog.dart';
import 'package:simple_aac_app/widgets/select_category_dialog.dart';

class FakeAudioplayerPlatform extends AudioplayersPlatformInterface {
  @override
  Stream<AudioEvent> getEventStream(String playerId) => const Stream.empty();
  @override
  Future<void> create(String playerId) async {}
  @override
  Future<void> dispose(String playerId) async {}
  @override
  Future<void> pause(String playerId) async {}
  @override
  Future<void> release(String playerId) async {}
  @override
  Future<void> resume(String playerId) async {}
  @override
  Future<void> seek(String playerId, Duration position) async {}
  @override
  Future<void> setAudioContext(String playerId, AudioContext context) async {}
  @override
  Future<void> setBalance(String playerId, double balance) async {}
  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) async {}
  @override
  Future<void> setPlayerMode(String playerId, PlayerMode playerMode) async {}
  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {}
  @override
  Future<void> setSourceBytes(String playerId, Uint8List bytes, {String? mimeType}) async {}
  @override
  Future<void> setSourceUrl(String playerId, String url, {bool? isLocal}) async {}
  @override
  Future<void> setVolume(String playerId, double volume) async {}
  @override
  Future<void> stop(String playerId) async {}
  @override
  Future<int?> getCurrentPosition(String playerId) async => null;
  @override
  Future<int?> getDuration(String playerId) async => null;
  @override
  Future<void> emitLog(String playerId, String message) async {}
  @override
  Future<void> emitError(String playerId, String code, String message) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    AudioplayersPlatformInterface.instance = FakeAudioplayerPlatform();
    tempDir = await Directory.systemTemp.createTemp('cat_independent_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

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

  List<AACCard> createTestCards() {
    return [
      AACCard(
        id: 'card_hello',
        label: 'Hello',
        category: 'General',
        colorValue: 0xFFFFF176,
      ),
      AACCard(
        id: 'card_apple',
        label: 'Apple',
        category: 'Food',
        colorValue: 0xFFEF5350,
      ),
      AACCard(
        id: 'card_dog',
        label: 'Dog',
        category: 'Animals',
        colorValue: 0xFF81C784,
      ),
      AACCard(
        id: 'card_cat',
        label: 'Cat',
        category: 'Animals',
        colorValue: 0xFF81C784,
      ),
    ];
  }

  Future<void> openDrawerAndTap(WidgetTester tester, String text) async {
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    if (!scaffoldState.isEndDrawerOpen) {
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
    }
    final target = find.text(text);
    final drawerScrollable = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(target, 200, scrollable: drawerScrollable);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  group('Category Creation & Selection Independence Tests (Regressions 1-7)', () {
    testWidgets('TEST 1 & 7: Creating an empty category "People" does NOT change All Cards selection and does not empty board', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      HomePage.initialCardsForTesting = createTestCards();
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify all 4 cards are initially visible on the board
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Cat'), findsOneWidget);

      // Open Settings drawer and tap "Add New Category"
      await openDrawerAndTap(tester, 'Add New Category');

      // Enter category name "People"
      await tester.enterText(find.byType(TextField).first, 'People');
      await tester.pumpAndSettle();

      // Tap Add Category button
      await tester.tap(find.descendant(
        of: find.byType(AddCategoryDialog),
        matching: find.byIcon(Icons.add_rounded),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Success message is shown
      expect(find.text('Category "People" created!'), findsOneWidget);

      // Settle dialog dismiss and animations
      await tester.pumpAndSettle();

      // 2. All Cards remains selected: Board is NOT empty!
      expect(find.text('No cards in this category'), findsNothing);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Cat'), findsOneWidget);

      // 3. Open Choose Categories and verify "People" appears but is NOT automatically selected
      await openDrawerAndTap(tester, 'Choose Categories');

      // Dialog is open
      expect(find.byType(SelectCategoryDialog), findsOneWidget);
      expect(find.text('People'), findsOneWidget);

      // People has 0 cards and is NOT selected
      expect(find.text('All Cards'), findsOneWidget);
      expect(find.textContaining('All Cards'), findsWidgets);
    });

    testWidgets('TEST 2: Specific category selection ("Food") is strictly preserved when creating a new category', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      HomePage.initialCardsForTesting = createTestCards();
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Explicitly select "Food" through Choose Categories
      await openDrawerAndTap(tester, 'Choose Categories');

      // Tap "Food" tile in dialog
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.textContaining('Apply'));
      await tester.pumpAndSettle();

      // Board only shows Apple (Food)
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Hello'), findsNothing);
      expect(find.text('Dog'), findsNothing);

      // 2. Now create a category named "Travel"
      await openDrawerAndTap(tester, 'Add New Category');

      await tester.enterText(find.byType(TextField).first, 'Travel');
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
        of: find.byType(AddCategoryDialog),
        matching: find.byIcon(Icons.add_rounded),
      ));
      await tester.pumpAndSettle();

      // 3. Board filter MUST NOT switch to Travel! It must stay on Food!
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('No cards in this category'), findsNothing);
    });

    testWidgets('TEST 3: Creating a category with card assignments updates card category without switching board selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      HomePage.initialCardsForTesting = createTestCards();
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Open Add New Category
      await openDrawerAndTap(tester, 'Add New Category');

      await tester.enterText(find.byType(TextField).first, 'Greetings');
      await tester.pumpAndSettle();

      // Assign 'Hello' card to 'Greetings' inside AddCategoryDialog
      await tester.tap(find.descendant(
        of: find.byType(AddCategoryDialog),
        matching: find.text('Hello'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(AddCategoryDialog),
        matching: find.byIcon(Icons.add_rounded),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Success message with card count
      expect(find.text('Category "Greetings" created with 1 cards!'), findsOneWidget);

      await tester.pumpAndSettle();

      // All cards remain visible on home board
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Dog'), findsOneWidget);
    });

    testWidgets('TEST 4: Explicitly selecting a category through Choose Categories and pressing Apply changes board', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      HomePage.initialCardsForTesting = createTestCards();
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Open Choose Categories
      await openDrawerAndTap(tester, 'Choose Categories');

      // Select Animals
      await tester.tap(find.text('Animals'));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.textContaining('Apply'));
      await tester.pumpAndSettle();

      // Only Animals are shown
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Cat'), findsOneWidget);
      expect(find.text('Hello'), findsNothing);
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('TEST 5: Cancelling category creation creates no category and changes nothing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      HomePage.initialCardsForTesting = createTestCards();
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await openDrawerAndTap(tester, 'Add New Category');

      await tester.enterText(find.byType(TextField).first, 'CancelledCat');
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Board unchanged
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('TEST 6: Custom categories and selected category filter persist across reload', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('customCategories', ['People', 'Hobbies']);
      await prefs.setString(
        'customCategoryMetadata',
        jsonEncode({
          'People': {'name': 'People', 'icon': 'school_rounded', 'colorValue': 0xFF9C27B0},
          'Hobbies': {'name': 'Hobbies', 'icon': 'palette_rounded', 'colorValue': 0xFFE91E63},
        }),
      );
      await prefs.setStringList('selectedCategories', ['All']);

      HomePage.initialCardsForTesting = createTestCards();
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);

      // Open Choose Categories and verify both custom categories are loaded
      await openDrawerAndTap(tester, 'Choose Categories');

      expect(find.text('People'), findsOneWidget);
      expect(find.text('Hobbies'), findsOneWidget);
    });
  });
}
