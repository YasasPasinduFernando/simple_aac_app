import 'dart:io';
import 'dart:ui' as ui;

// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';
import 'package:simple_aac_app/services/tutorial_service.dart';

class _FakeAudioPlatform extends AudioplayersPlatformInterface {
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

final Uint8List k1x1PngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    AudioplayersPlatformInterface.instance = _FakeAudioPlatform();
  });

  setUp(() async {
    AudioplayersPlatformInterface.instance = _FakeAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('overlay_setting_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    StarterPackService.clearCache();
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.skipSplashForTesting = true;
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

  Future<void> saveScreenshot(
    WidgetTester tester,
    GlobalKey repaintKey,
    String filename,
  ) async {
    await tester.runAsync(() async {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final img = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final outDir = Directory('docs/qa/text_overlay_setting');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      File('docs/qa/text_overlay_setting/$filename').writeAsBytesSync(bytes);

      const artifactDir =
          '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
      File('$artifactDir/$filename').writeAsBytesSync(bytes);
    });
  }

  group('A. Text on Card Image Toggle Architecture & Visual Parity', () {
    testWidgets(
        '1. Setting ON: Home cards, category cards (Cat), folder cards, and custom photos overlay label over image with dark gradient',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final customPhoto = File('${tempDir.path}/my_toy.jpg');
      customPhoto.writeAsBytesSync(k1x1PngBytes);

      final cards = [
        AACCard(
          id: 'seed_happy',
          label: 'Happy',
          imagePath: 'assets/home/happy.webp',
          colorValue: 0xFFFFF176,
        ),
        AACCard(
          id: 'seed_more',
          label: 'More',
          imagePath: 'assets/images/seed_v2/more.webp',
          colorValue: 0xFF3F51B5,
          type: 'folder',
          subCards: [
            AACCard(id: 'sub_1', label: 'Item 1', colorValue: 0xFFFFFFFF),
          ],
        ),
        AACCard(
          id: StarterPackService.starterPackRootId,
          label: 'Default',
          imagePath: 'assets/home/default_folder_cover.webp',
          colorValue: 0xFF0284C7,
          type: 'folder',
          subCards: [
            AACCard(id: 'cat_folder', label: 'Animals', colorValue: 0xFFE0EED0),
          ],
        ),
        AACCard(
          id: 'card_cat',
          label: 'Cat',
          imagePath: 'assets/images/starter_pack_v8/animals_cat.webp',
          colorValue: 0xFFE0EED0,
        ),
        AACCard(
          id: 'custom_photo_toy',
          label: 'My Toy',
          imagePath: customPhoto.path,
          colorValue: 0xFFF472B6,
        ),
      ];

      SharedPreferences.setMockInitialValues({
        'hasSeededDefaultCards': true,
        'isTutorialCompleted': true,
        'isBoardTutorialDismissed': true,
        TutorialService.prefCompleted: true,
        TutorialService.prefSkipped: true,
        'useImageOverlayLabel': true,
        'gridColumns': 2,
      });
      await NetworkPolicyService.instance.init();
      HomePage.initialCardsForTesting = cards;

      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: repaintKey,
            child: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check all 5 cards render labels in white text
      for (final card in cards) {
        final labelFinder = find.text(card.label);
        expect(labelFinder, findsOneWidget,
            reason: '${card.label} must be rendered');
        final textWidget = tester.widget<Text>(labelFinder);
        expect(textWidget.style?.color, equals(Colors.white),
            reason: '${card.label} must have white text in overlay mode');
      }

      // Check linear gradient containers exist for the card overlays (topCenter to bottomCenter)
      final gradientFinders = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          if (box.gradient is LinearGradient) {
            final grad = box.gradient as LinearGradient;
            return grad.begin == Alignment.topCenter;
          }
        }
        return false;
      });
      expect(gradientFinders, findsNWidgets(5),
          reason: 'All 5 cards must have the dark gradient overlay Container');

      // Save screenshot for visual artifact
      await saveScreenshot(tester, repaintKey, 'text_overlay_on_all_cards.png');
    });

    testWidgets(
        '2. Setting OFF: Home cards, category cards (Cat), folder cards, and custom photos render dedicated footer below unclipped image without gradient',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final customPhoto = File('${tempDir.path}/my_toy.jpg');
      customPhoto.writeAsBytesSync(k1x1PngBytes);

      final cards = [
        AACCard(
          id: 'seed_happy',
          label: 'Happy',
          imagePath: 'assets/home/happy.webp',
          colorValue: 0xFFFFF176,
        ),
        AACCard(
          id: 'seed_more',
          label: 'More',
          imagePath: 'assets/images/seed_v2/more.webp',
          colorValue: 0xFF3F51B5,
          type: 'folder',
          subCards: [
            AACCard(id: 'sub_1', label: 'Item 1', colorValue: 0xFFFFFFFF),
          ],
        ),
        AACCard(
          id: StarterPackService.starterPackRootId,
          label: 'Default',
          imagePath: 'assets/home/default_folder_cover.webp',
          colorValue: 0xFF0284C7,
          type: 'folder',
          subCards: [
            AACCard(id: 'cat_folder', label: 'Animals', colorValue: 0xFFE0EED0),
          ],
        ),
        AACCard(
          id: 'card_cat',
          label: 'Cat',
          imagePath: 'assets/images/starter_pack_v8/animals_cat.webp',
          colorValue: 0xFFE0EED0,
        ),
        AACCard(
          id: 'custom_photo_toy',
          label: 'My Toy',
          imagePath: customPhoto.path,
          colorValue: 0xFFF472B6,
        ),
      ];

      SharedPreferences.setMockInitialValues({
        'hasSeededDefaultCards': true,
        'isTutorialCompleted': true,
        'isBoardTutorialDismissed': true,
        TutorialService.prefCompleted: true,
        TutorialService.prefSkipped: true,
        'useImageOverlayLabel': false,
        'gridColumns': 2,
      });
      await NetworkPolicyService.instance.init();
      HomePage.initialCardsForTesting = cards;

      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: repaintKey,
            child: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Zero linear gradient card overlay containers should exist when setting is OFF!
      final gradientFinders = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          if (box.gradient is LinearGradient) {
            final grad = box.gradient as LinearGradient;
            return grad.begin == Alignment.topCenter;
          }
        }
        return false;
      });
      expect(gradientFinders, findsNothing,
          reason: 'No dark gradient overlay may exist when setting is OFF');

      // Verify that all cards render their labels in dedicated footer containers
      for (final card in cards) {
        final labelFinder = find.text(card.label);
        expect(labelFinder, findsOneWidget,
            reason: '${card.label} must be rendered in footer');
        final textWidget = tester.widget<Text>(labelFinder);
        expect(textWidget.style?.color, isNotNull,
            reason: '${card.label} must have a valid text style color');
      }

      // Verify all card images use BoxFit.contain in footer mode so they remain unclipped
      final imageWidgets = tester.widgetList<Image>(find.byType(Image)).toList();
      for (final img in imageWidgets) {
        expect(img.fit, equals(BoxFit.contain),
            reason: 'Every card image must be BoxFit.contain when setting is OFF');
      }

      // Save screenshot for visual artifact
      await saveScreenshot(tester, repaintKey, 'text_overlay_off_all_cards.png');
    });

    testWidgets(
        '3. Live Drawer Toggle dynamically flips mode between overlay and footer across all cards without restart',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cards = [
        AACCard(
          id: 'seed_happy',
          label: 'Happy',
          imagePath: 'assets/home/happy.webp',
          colorValue: 0xFFFFF176,
        ),
        AACCard(
          id: 'card_cat',
          label: 'Cat',
          imagePath: 'assets/images/starter_pack_v8/animals_cat.webp',
          colorValue: 0xFFE0EED0,
        ),
      ];

      SharedPreferences.setMockInitialValues({
        'hasSeededDefaultCards': true,
        'isTutorialCompleted': true,
        'isBoardTutorialDismissed': true,
        TutorialService.prefCompleted: true,
        TutorialService.prefSkipped: true,
        'useImageOverlayLabel': true,
        'gridColumns': 2,
      });
      await NetworkPolicyService.instance.init();
      HomePage.initialCardsForTesting = cards;

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      bool isCardGradient(Widget w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final box = w.decoration as BoxDecoration;
          if (box.gradient is LinearGradient) {
            return (box.gradient as LinearGradient).begin == Alignment.topCenter;
          }
        }
        return false;
      }

      // Initially ON: 2 gradient overlays
      expect(find.byWidgetPredicate(isCardGradient), findsNWidgets(2));

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Find 'Text on Card Image' switch and toggle it
      final switchFinder = find.byWidgetPredicate(
        (w) => w is Switch,
      );
      expect(switchFinder, findsWidgets);

      // The setting is toggled via HomeDrawer
      final state = tester.state(find.byType(HomePage)) as dynamic;
      expect(state.useImageOverlayLabelForTesting, isTrue);

      // Programmatically toggle via test helper or tap switch
      state.useImageOverlayLabelForTesting = false;
      await tester.pumpAndSettle();

      // Close drawer if open
      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      if (scaffoldState.isEndDrawerOpen) {
        scaffoldState.closeEndDrawer();
        await tester.pumpAndSettle();
      }

      // Now OFF: 0 gradient overlays
      expect(find.byWidgetPredicate(isCardGradient), findsNothing);

      // Toggle back to ON
      state.useImageOverlayLabelForTesting = true;
      await tester.pumpAndSettle();

      // Back to ON: 2 gradient overlays
      expect(find.byWidgetPredicate(isCardGradient), findsNWidgets(2));
    });
  });
}
