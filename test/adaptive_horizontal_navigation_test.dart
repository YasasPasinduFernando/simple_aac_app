import 'dart:io';
import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';
import 'package:simple_aac_app/widgets/landscape_menu.dart';

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
    tempDir = await Directory.systemTemp.createTemp('adaptive_nav_test_');
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

  final testCards = List.generate(
    20,
    (i) => AACCard(
      id: 'card_$i',
      label: 'Card $i',
      labelSinhala: 'කාඩ්පත $i',
      labelTamil: 'அட்டை $i',
      colorValue: 0xFFFEE685,
    ),
  );

  group('A. Landscape Mode — Conditional Left/Right Arrows & Directional Cluster', () {
    testWidgets('Normal landscape grid (no overflow) shows original sidebar without Left/Right arrows',
        (tester) async {
      // Galaxy A34 Landscape: 2340 x 1080 @ 2.625
      tester.view.physicalSize = const Size(2340, 1080);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'gridColumns': 4, // 4 columns easily fits in 891dp available width
      });
      HomePage.initialCardsForTesting = testCards;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      expect(find.byType(LandscapeMenu), findsOneWidget);

      // Verify original Up & Down buttons exist
      expect(find.byKey(const ValueKey('landscape_nav_up')), findsOneWidget);
      expect(find.byKey(const ValueKey('landscape_nav_down')), findsOneWidget);

      // Verify NO Left or Right arrow buttons
      expect(find.byKey(const ValueKey('landscape_nav_left')), findsNothing);
      expect(find.byKey(const ValueKey('landscape_nav_right')), findsNothing);

      // Verify other navigation buttons exist
      expect(find.byKey(const ValueKey('landscape_nav_pin')), findsOneWidget);
      expect(find.byKey(const ValueKey('landscape_nav_menu')), findsOneWidget);
      expect(find.byKey(const ValueKey('landscape_nav_home')), findsOneWidget);
      expect(find.byKey(const ValueKey('landscape_nav_search')), findsOneWidget);
    });

    testWidgets('Overflow landscape grid shows 2x2 cluster with Left/Right arrows and boundary disables',
        (tester) async {
      tester.view.physicalSize = const Size(2340, 1080);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'gridColumns': 15, // 15 columns requires > 1300dp, will overflow 891dp
      });
      HomePage.initialCardsForTesting = testCards;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      expect(find.byType(LandscapeMenu), findsOneWidget);

      // Verify 2x2 directional cluster buttons are present
      final upFinder = find.byKey(const ValueKey('landscape_nav_up'));
      final downFinder = find.byKey(const ValueKey('landscape_nav_down'));
      final leftFinder = find.byKey(const ValueKey('landscape_nav_left'));
      final rightFinder = find.byKey(const ValueKey('landscape_nav_right'));

      expect(upFinder, findsOneWidget);
      expect(downFinder, findsOneWidget);
      expect(leftFinder, findsOneWidget);
      expect(rightFinder, findsOneWidget);

      // At start (offset 0): Left should be disabled, Right should be enabled
      final leftBtnAtStart = tester.widget<ElevatedButton>(find.descendant(
        of: leftFinder,
        matching: find.byType(ElevatedButton),
      ));
      final rightBtnAtStart = tester.widget<ElevatedButton>(find.descendant(
        of: rightFinder,
        matching: find.byType(ElevatedButton),
      ));

      expect(leftBtnAtStart.onPressed, isNull, reason: 'Left must be disabled at start');
      expect(rightBtnAtStart.onPressed, isNotNull, reason: 'Right must be enabled at start');

      // Tap Right button to scroll forward
      await tester.tap(rightFinder);
      await tester.pumpAndSettle();

      // Now Left should become enabled
      final leftBtnAfterScroll = tester.widget<ElevatedButton>(find.descendant(
        of: leftFinder,
        matching: find.byType(ElevatedButton),
      ));
      expect(leftBtnAfterScroll.onPressed, isNotNull, reason: 'Left should be enabled after scrolling right');

      // Scroll all the way to the end
      final hScroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first);
      final controller = hScroll.controller!;
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();

      // At end: Right should be disabled, Left should be enabled
      final rightBtnAtEnd = tester.widget<ElevatedButton>(find.descendant(
        of: rightFinder,
        matching: find.byType(ElevatedButton),
      ));
      final leftBtnAtEnd = tester.widget<ElevatedButton>(find.descendant(
        of: leftFinder,
        matching: find.byType(ElevatedButton),
      ));
      expect(rightBtnAtEnd.onPressed, isNull, reason: 'Right must be disabled at maxScrollExtent');
      expect(leftBtnAtEnd.onPressed, isNotNull, reason: 'Left must be enabled at maxScrollExtent');

      // Tap Left to scroll back
      await tester.tap(leftFinder);
      await tester.pumpAndSettle();

      expect(controller.offset, lessThan(controller.position.maxScrollExtent));
    });
  });

  group('B. Portrait Mode — Absolute Prohibition of Left/Right Arrows & Real Scrollbar', () {
    testWidgets('Portrait mode NEVER contains Left/Right arrow buttons at ANY grid size (1..30)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);

      for (final cols in [1, 2, 5, 10, 15, 20, 30]) {
        SharedPreferences.setMockInitialValues({'gridColumns': cols});
        HomePage.initialCardsForTesting = testCards;

        await tester.pumpWidget(const MaterialApp(home: HomePage()));
        await tester.pumpAndSettle();

        // Check NO LandscapeMenu exists in portrait
        expect(find.byType(LandscapeMenu), findsNothing,
            reason: 'Portrait must not have LandscapeMenu at $cols columns');

        // Check NO Left or Right arrow buttons anywhere in the widget tree
        expect(find.byKey(const ValueKey('landscape_nav_left')), findsNothing,
            reason: 'Portrait must never have Left arrow at $cols columns');
        expect(find.byKey(const ValueKey('landscape_nav_right')), findsNothing,
            reason: 'Portrait must never have Right arrow at $cols columns');
      }
    });

    testWidgets('Portrait overflow renders horizontal scrollbar with swipe support and no scrollbar when fitted',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);

      // Fitted mode: 2 columns in portrait -> no horizontal overflow
      SharedPreferences.setMockInitialValues({'gridColumns': 2});
      HomePage.initialCardsForTesting = testCards;

      await tester.pumpWidget(const MaterialApp(home: HomePage(key: ValueKey('home_fitted'))));
      await tester.pumpAndSettle();

      expect(find.byType(Scrollbar), findsNothing,
          reason: 'No scrollbar should be rendered when content fits without overflow');

      // Overflow mode: 10 columns in portrait -> requires horizontal scroll
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      SharedPreferences.setMockInitialValues({'gridColumns': 10});
      HomePage.initialCardsForTesting = testCards;

      await tester.pumpWidget(const MaterialApp(home: HomePage(key: ValueKey('home_overflow'))));
      await tester.pumpAndSettle();

      expect(find.byType(Scrollbar), findsOneWidget,
          reason: 'Scrollbar must be displayed when horizontal overflow exists');

      // Swipe horizontally to verify finger gesture works
      final scrollFinder = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(scrollFinder, findsOneWidget);

      await tester.drag(scrollFinder, const Offset(-200, 0));
      await tester.pumpAndSettle();

      final scrollWidget = tester.widget<SingleChildScrollView>(scrollFinder);
      expect(scrollWidget.controller!.offset, greaterThan(0),
          reason: 'Swipe gesture must scroll horizontally');
    });
  });

  group('C. Multi-Form Factor & Grid Density (1, 2, 5, 10, 15, 20, 30 columns)', () {
    final formFactors = [
      ('Phone Portrait', const Size(1080, 2400), 2.625),
      ('Phone Landscape', const Size(2400, 1080), 2.625),
      ('Tablet Portrait', const Size(1600, 2560), 2.0),
      ('Tablet Landscape', const Size(2560, 1600), 2.0),
    ];

    for (final (name, size, dpr) in formFactors) {
      testWidgets('$name renders grid densities 1, 2, 5, 10, 15, 20, 30 cleanly',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = dpr;
        addTearDown(tester.view.resetPhysicalSize);

        for (final cols in [1, 2, 5, 10, 15, 20, 30]) {
          SharedPreferences.setMockInitialValues({'gridColumns': cols});
          HomePage.initialCardsForTesting = testCards;

          await tester.pumpWidget(const MaterialApp(home: HomePage()));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull,
              reason: '$name at $cols columns should not throw exception');
        }
      });
    }
  });

  group('D. Edit Mode & Folder Navigation Compatibility', () {
    testWidgets('Edit Mode preserves docked action trays and allows landscape horizontal scrolling',
        (tester) async {
      tester.view.physicalSize = const Size(2340, 1080);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'gridColumns': 12});
      HomePage.initialCardsForTesting = testCards;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Open menu and enable Edit Mode
      await tester.tap(find.byKey(const ValueKey('landscape_nav_menu')));
      await tester.pumpAndSettle();

      final drawerScrollable = find.descendant(
        of: find.byType(HomeDrawer),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Enable Edit Mode'),
        100,
        scrollable: drawerScrollable,
      );
      await tester.tap(find.text('Enable Edit Mode'));
      await tester.pumpAndSettle();

      // Verify card action tray buttons exist
      expect(find.byKey(ValueKey('card_edit_pencil_${testCards[0].id}')), findsOneWidget);
      expect(find.byKey(ValueKey('card_delete_btn_${testCards[0].id}')), findsOneWidget);
      expect(find.byKey(ValueKey('card_drag_handle_${testCards[0].id}')), findsOneWidget);

      // Verify landscape Right arrow still works in Edit Mode
      expect(find.byKey(const ValueKey('landscape_nav_right')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('landscape_nav_right')));
      await tester.pumpAndSettle();

      final hScrollFinder = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      final hScroll = tester.widget<SingleChildScrollView>(hScrollFinder);
      expect(hScroll.controller!.offset, greaterThan(0));
    });
  });
}
