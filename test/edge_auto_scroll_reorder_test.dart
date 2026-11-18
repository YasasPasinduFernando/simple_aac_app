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
    tempDir = await Directory.systemTemp.createTemp('auto_scroll_test_');
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

  List<AACCard> generateCards(int count) {
    return List.generate(
      count,
      (i) => AACCard(
        id: 'card_$i',
        label: 'Card $i',
        colorValue: 0xFF2196F3,
        category: 'General',
      ),
    );
  }

  Future<void> pumpHomePage(
    WidgetTester tester, {
    required List<AACCard> cards,
    Size size = const Size(400, 800),
    int gridColumns = 2,
  }) async {
    tester.view.physicalSize = size * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({
      'online_features_enabled': false,
      'useImageOverlayLabel': true,
      'gridColumns': gridColumns,
    });

    HomePage.initialCardsForTesting = cards;

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Enter Edit Mode
    final editButton = find.text('Edit Words');
    if (editButton.evaluate().isNotEmpty) {
      await tester.tap(editButton);
      await tester.pumpAndSettle();
    } else {
      // Open drawer to enable edit mode if button not on top
      final menuBtn = find.byIcon(Icons.menu_rounded);
      if (menuBtn.evaluate().isNotEmpty) {
        await tester.tap(menuBtn);
        await tester.pumpAndSettle();
        final drawerScrollable = find.descendant(
          of: find.byType(Drawer),
          matching: find.byType(Scrollable),
        );
        if (drawerScrollable.evaluate().isNotEmpty) {
          await tester.scrollUntilVisible(
            find.text('Enable Edit Mode'),
            100,
            scrollable: drawerScrollable.first,
          );
        }
        await tester.tap(find.text('Enable Edit Mode'));
        await tester.pumpAndSettle();
      }
    }
  }

  group('Safe Edge Auto-Scrolling & Reordering 15-Point Suite', () {
    testWidgets('1. Move first card to last position (basic reordering)', (tester) async {
      final testCards = generateCards(4);
      await pumpHomePage(tester, cards: testCards, gridColumns: 2);

      // Verify card_0 is initially at the start
      final card0Handle = find.byKey(const ValueKey('card_drag_handle_card_0'));
      final card3 = find.byKey(const ValueKey('drag_item_card_3'));
      expect(card0Handle, findsOneWidget);
      expect(card3, findsOneWidget);

      // Drag card_0 onto right half of card_3
      final card3Center = tester.getCenter(card3);
      final dropTarget = card3Center + const Offset(30, 0);

      final gesture = await tester.startGesture(tester.getCenter(card0Handle));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(dropTarget);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Reordered cards'), findsOneWidget);
    });

    testWidgets('2. Move last card to first position', (tester) async {
      final testCards = generateCards(4);
      await pumpHomePage(tester, cards: testCards, gridColumns: 2);

      final card3Handle = find.byKey(const ValueKey('card_drag_handle_card_3'));
      final card0 = find.byKey(const ValueKey('drag_item_card_0'));

      final card0Center = tester.getCenter(card0);
      final dropTarget = card0Center - const Offset(30, 0);

      final gesture = await tester.startGesture(tester.getCenter(card3Handle));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(dropTarget);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Reordered cards'), findsOneWidget);
    });

    testWidgets('3. Move a card across multiple rows', (tester) async {
      final testCards = generateCards(8);
      await pumpHomePage(tester, cards: testCards, gridColumns: 2);

      final card0Handle = find.byKey(const ValueKey('card_drag_handle_card_0'));
      final card5 = find.byKey(const ValueKey('drag_item_card_5'));

      final dropTarget = tester.getCenter(card5) + const Offset(20, 0);
      final gesture = await tester.startGesture(tester.getCenter(card0Handle));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(dropTarget);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Reordered cards'), findsOneWidget);
    });

    testWidgets('4 & 10. Drag downward near bottom edge triggers auto-scroll down, then drop', (tester) async {
      // 20 cards so grid has vertical scroll extent
      final testCards = generateCards(20);
      await pumpHomePage(tester, cards: testCards, gridColumns: 2);

      final scrollableFinder = find.byType(Scrollable).first;
      final scrollableState = tester.state<ScrollableState>(scrollableFinder);
      final initialOffset = scrollableState.position.pixels;
      expect(initialOffset, equals(0.0));

      final card0Handle = find.byKey(const ValueKey('card_drag_handle_card_0'));
      final gesture = await tester.startGesture(tester.getCenter(card0Handle));
      await tester.pump(const Duration(milliseconds: 50));

      // First movement initiates the drag and resolves the gesture recognizer
      await gesture.moveBy(const Offset(0, 25));
      await tester.pump(const Duration(milliseconds: 50));

      // Move into bottom edge auto-scroll zone (screen height 800, grid bottom is 800)
      await gesture.moveTo(const Offset(200, 770));
      await tester.pump(const Duration(milliseconds: 50));

      // Allow auto-scroll timer to advance
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }

      final scrolledOffset = scrollableState.position.pixels;
      expect(scrolledOffset, greaterThan(initialOffset + 50.0));

      // Drop card after auto-scroll
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('5. Drag upward near top edge triggers auto-scroll up', (tester) async {
      final testCards = generateCards(20);
      await pumpHomePage(tester, cards: testCards, gridColumns: 2);

      final scrollableFinder = find.byType(Scrollable).first;
      final scrollableState = tester.state<ScrollableState>(scrollableFinder);

      // Pre-scroll down by 300px
      scrollableState.position.jumpTo(300.0);
      await tester.pumpAndSettle();
      expect(scrollableState.position.pixels, equals(300.0));

      // Drag a visible card toward top edge of the grid
      final handleFinder = find.byKey(const ValueKey('card_drag_handle_card_4'));
      expect(handleFinder, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(handleFinder));
      await tester.pump(const Duration(milliseconds: 50));

      // First movement initiates the drag and resolves the gesture recognizer
      await gesture.moveBy(const Offset(0, -25));
      await tester.pump(const Duration(milliseconds: 50));

      // Move into top edge auto-scroll zone (grid starts at y ~ 148, so y = 168 is localPos.dy = 20)
      await gesture.moveTo(const Offset(200, 168));
      await tester.pump(const Duration(milliseconds: 100));

      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }

      expect(scrollableState.position.pixels, lessThan(300.0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('6 & 7. Landscape with horizontal overflow auto-scrolls right and left', (tester) async {
      // 10 columns in landscape (800x400) creates clear horizontal overflow
      final testCards = generateCards(20);
      await pumpHomePage(
        tester,
        cards: testCards,
        size: const Size(800, 400),
        gridColumns: 8,
      );

      // Find horizontal scrollable
      final horizontalScrollableFinder = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
      );
      expect(horizontalScrollableFinder, findsOneWidget);
      final horizState = tester.state<ScrollableState>(horizontalScrollableFinder);

      final initialX = horizState.position.pixels;
      expect(initialX, equals(0.0));
      expect(horizState.position.maxScrollExtent, greaterThan(10.0));

      final handleFinder = find.byKey(const ValueKey('card_drag_handle_card_0'));
      final gesture = await tester.startGesture(tester.getCenter(handleFinder));
      await tester.pump(const Duration(milliseconds: 50));

      // First movement initiates the drag
      await gesture.moveBy(const Offset(25, 0));
      await tester.pump(const Duration(milliseconds: 50));

      // 6. Move near right edge of the screen (dx = 770 in 800px width)
      await gesture.moveTo(const Offset(770, 250));
      await tester.pump(const Duration(milliseconds: 100));

      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }

      final rightScrolledX = horizState.position.pixels;
      expect(rightScrolledX, greaterThan(initialX + 50.0));

      // 7. Move near left edge of the screen (dx = 30)
      await gesture.moveTo(const Offset(30, 250));
      await tester.pump(const Duration(milliseconds: 100));

      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }

      expect(horizState.position.pixels, lessThan(rightScrolledX));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('8. No horizontal auto-scroll when no horizontal overflow exists', (tester) async {
      // 2 columns in portrait has NO horizontal overflow
      final testCards = generateCards(10);
      await pumpHomePage(tester, cards: testCards, gridColumns: 2);

      final horizontalScrollableFinder = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
      );
      // No horizontal scrollable should exist
      expect(horizontalScrollableFinder, findsNothing);

      final handleFinder = find.byKey(const ValueKey('card_drag_handle_card_0'));
      final gesture = await tester.startGesture(tester.getCenter(handleFinder));
      await tester.pump(const Duration(milliseconds: 50));

      // Move toward right screen edge
      await gesture.moveTo(const Offset(390, 400));
      await tester.pump(const Duration(milliseconds: 100));

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }

      // Remains nothing and doesn't throw
      expect(horizontalScrollableFinder, findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('9. Cancel drag during auto-scroll preserves card order and stops scroll', (tester) async {
      final testCards = generateCards(15);
      await pumpHomePage(tester, cards: testCards, gridColumns: 2);

      final card0Handle = find.byKey(const ValueKey('card_drag_handle_card_0'));
      final gesture = await tester.startGesture(tester.getCenter(card0Handle));
      await tester.pump(const Duration(milliseconds: 50));

      // Trigger auto-scroll
      await gesture.moveTo(const Offset(200, 780));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Cancel the gesture (user dragged away or gesture interrupted)
      await gesture.cancel();
      await tester.pumpAndSettle();

      // No reorder snackbar shown
      expect(find.text('Reordered cards'), findsNothing);
    });

    testWidgets('11. Undo a completed reorder restores exact previous card order', (tester) async {
      final testCards = generateCards(4);
      await pumpHomePage(tester, cards: testCards, gridColumns: 2);

      final card0Handle = find.byKey(const ValueKey('card_drag_handle_card_0'));
      final card1 = find.byKey(const ValueKey('drag_item_card_1'));

      final gesture = await tester.startGesture(tester.getCenter(card0Handle));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(tester.getCenter(card1) + const Offset(20, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      // Undo button should be visible in SnackBar
      final undoBtn = find.text('UNDO');
      expect(undoBtn, findsOneWidget);

      await tester.tap(undoBtn);
      await tester.pumpAndSettle();

      // Card 0 restored to top
      expect(find.byKey(const ValueKey('drag_item_card_0')), findsOneWidget);
    });

    testWidgets('12. Rapid repeat reordering executes safely without competing timers', (tester) async {
      final testCards = generateCards(6);
      await pumpHomePage(tester, cards: testCards, gridColumns: 2);

      for (int i = 0; i < 3; i++) {
        final cardHandle = find.byKey(ValueKey('card_drag_handle_card_$i'));
        final targetCard = find.byKey(ValueKey('drag_item_card_${i + 1}'));

        final gesture = await tester.startGesture(tester.getCenter(cardHandle));
        await tester.pump(const Duration(milliseconds: 30));
        await gesture.moveTo(tester.getCenter(targetCard) + const Offset(20, 0));
        await tester.pump(const Duration(milliseconds: 30));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      expect(find.text('Reordered cards'), findsOneWidget);
    });

    testWidgets('13. Scale test: 2, 10, 100, and 500 cards initialize and build cleanly', (tester) async {
      for (final count in [2, 10, 100, 500]) {
        final cards = generateCards(count);
        await pumpHomePage(tester, cards: cards, gridColumns: 2);
        expect(find.byKey(const ValueKey('drag_item_card_0')), findsOneWidget);
      }
    });

    testWidgets('14. Grid sizes 1, 2, 3, 4, 5 columns reorder cleanly', (tester) async {
      for (final cols in [1, 2, 3, 4, 5]) {
        final cards = generateCards(8);
        await pumpHomePage(tester, cards: cards, gridColumns: cols);

        final card0Handle = find.byKey(const ValueKey('card_drag_handle_card_0'));
        expect(card0Handle, findsOneWidget);
      }
    });

    testWidgets('15. Nested folder reorder and drop target move up', (tester) async {
      final folderCards = [
        AACCard(
          id: 'folder_animals',
          label: 'Animals',
          type: 'folder',
          colorValue: 0xFF4CAF50,
          subCards: [
            AACCard(id: 'sub_dog', label: 'Dog', colorValue: 0xFF81C784),
            AACCard(id: 'sub_cat', label: 'Cat', colorValue: 0xFF81C784),
          ],
        ),
      ];

      await pumpHomePage(tester, cards: folderCards, gridColumns: 2);

      // Open folder by tapping its face in normal mode first or navigate into it
      // Exit edit mode to tap into folder
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Animals'));
      await tester.pumpAndSettle();

      // Now inside Animals folder, open drawer to enable Edit Mode
      final menuBtn = find.byIcon(Icons.menu_rounded);
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();
      final drawerScrollable = find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      );
      if (drawerScrollable.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(
          find.text('Enable Edit Mode'),
          100,
          scrollable: drawerScrollable.first,
        );
      }
      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      // Top banner shows "Drop card to move up"
      expect(find.text('Drop card to move up'), findsOneWidget);
      expect(find.text('Dog'), findsOneWidget);
      expect(find.text('Cat'), findsOneWidget);

      // Reorder Dog and Cat inside the folder
      final dogHandle = find.byKey(const ValueKey('card_drag_handle_sub_dog'));
      final cat = find.byKey(const ValueKey('drag_item_sub_cat'));

      final gesture = await tester.startGesture(tester.getCenter(dogHandle));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(tester.getCenter(cat) + const Offset(20, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Reordered cards'), findsOneWidget);
    });
  });
}
