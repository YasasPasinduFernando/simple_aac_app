import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/data/default_seed_cards.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';
import 'package:simple_aac_app/widgets/tts_bar.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    AudioplayersPlatformInterface.instance = _FakeAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('global_label_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;
    StarterPackService.clearCache();
  });

  tearDownAll(() async {
    CardStorageService.resetTestHooks();
    StarterPackService.clearCache();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'isFirstRun': false,
      'language': 'en',
      'showCardLabels': true,
      'useImageOverlayLabel': true,
      'pin_mode_active': false,
    });
    HomePage.skipSplashForTesting = true;
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.initialCardsForTesting = createDefaultSeedCards();
    HomePage.hapticPerformer = () async {};
    StarterPackService.clearCache();
  });

  tearDown(() {
    HomePage.skipSplashForTesting = false;
    HomePage.initialCardsForTesting = null;
  });

  group('Global Card Label Visibility & 4 Combinations', () {
    testWidgets('Combination A: Show Card Labels ON + Overlay ON (Existing labels over images)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(home: HomePage(key: UniqueKey())),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(HomePage)) as dynamic;
      state.showCardLabelsForTesting = true;
      state.useImageOverlayLabelForTesting = true;
      await tester.pumpAndSettle();

      // Verify visible card labels are present
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Verify gradient overlays are rendered
      final gradients = tester.widgetList<Container>(
        find.byWidgetPredicate((w) {
          if (w is Container && w.decoration is BoxDecoration) {
            final dec = w.decoration as BoxDecoration;
            if (dec.gradient is LinearGradient) {
              final grad = dec.gradient as LinearGradient;
              return grad.begin == Alignment.topCenter && grad.end == Alignment.bottomCenter;
            }
          }
          return false;
        }),
      );
      expect(gradients.isNotEmpty, isTrue, reason: 'Gradients must exist when Overlay is ON');

      // Capture screenshot
      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();
        const outDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
        await File('$outDir/comb_A_labels_ON_overlay_ON.png').writeAsBytes(bytes);
        await File('docs/qa/card_label_visibility/comb_A_labels_ON_overlay_ON.png').create(recursive: true);
        await File('docs/qa/card_label_visibility/comb_A_labels_ON_overlay_ON.png').writeAsBytes(bytes);
      });
    });

    testWidgets('Combination B: Show Card Labels ON + Overlay OFF (Existing labels in footer below image)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(home: HomePage(key: UniqueKey())),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(HomePage)) as dynamic;
      state.showCardLabelsForTesting = true;
      state.useImageOverlayLabelForTesting = false;
      await tester.pumpAndSettle();

      // Verify visible card labels are present
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Verify flex 24 footer containers exist
      final footers = tester.widgetList<Expanded>(
        find.byWidgetPredicate((w) => w is Expanded && w.flex == 24),
      );
      expect(footers.isNotEmpty, isTrue, reason: 'Footer containers must exist when Overlay is OFF');

      // Capture screenshot
      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();
        const outDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
        await File('$outDir/comb_B_labels_ON_overlay_OFF.png').writeAsBytes(bytes);
        await File('docs/qa/card_label_visibility/comb_B_labels_ON_overlay_OFF.png').create(recursive: true);
        await File('docs/qa/card_label_visibility/comb_B_labels_ON_overlay_OFF.png').writeAsBytes(bytes);
      });
    });

    testWidgets('Combination C: Show Card Labels OFF + Overlay ON (Image-only cards, no visible labels)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(home: HomePage(key: UniqueKey())),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(HomePage)) as dynamic;
      state.showCardLabelsForTesting = false;
      state.useImageOverlayLabelForTesting = true;
      await tester.pumpAndSettle();

      // Verify card labels are HIDDEN from visual widgets
      expect(find.text('Hello'), findsNothing);
      expect(find.text('Happy'), findsNothing);
      expect(find.text('More'), findsNothing);

      // Verify NO gradient overlays exist on cards
      final cardGradients = tester.widgetList<Container>(
        find.byWidgetPredicate((w) {
          if (w is Container && w.decoration is BoxDecoration) {
            final dec = w.decoration as BoxDecoration;
            if (dec.gradient is LinearGradient) {
              final grad = dec.gradient as LinearGradient;
              return grad.begin == Alignment.topCenter && grad.end == Alignment.bottomCenter;
            }
          }
          return false;
        }),
      );
      expect(cardGradients.isEmpty, isTrue, reason: 'No gradients should exist when labels are OFF');

      // Verify NO footer containers exist
      final footers = tester.widgetList<Expanded>(
        find.byWidgetPredicate((w) => w is Expanded && w.flex == 24),
      );
      expect(footers.isEmpty, isTrue, reason: 'No footer should exist when labels are OFF');

      // Verify Semantics still provides label for accessibility
      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Hello',
      );
      expect(semanticsFinder, findsOneWidget, reason: 'Accessibility semantics must remain');

      // Capture screenshot
      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();
        const outDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
        await File('$outDir/comb_C_labels_OFF_overlay_ON.png').writeAsBytes(bytes);
        await File('docs/qa/card_label_visibility/comb_C_labels_OFF_overlay_ON.png').create(recursive: true);
        await File('docs/qa/card_label_visibility/comb_C_labels_OFF_overlay_ON.png').writeAsBytes(bytes);
      });
    });

    testWidgets('Combination D: Show Card Labels OFF + Overlay OFF (Image-only cards, no visible labels)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(home: HomePage(key: UniqueKey())),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(HomePage)) as dynamic;
      state.showCardLabelsForTesting = false;
      state.useImageOverlayLabelForTesting = false;
      await tester.pumpAndSettle();

      // Verify card labels are HIDDEN from visual widgets
      expect(find.text('Hello'), findsNothing);
      expect(find.text('Happy'), findsNothing);
      expect(find.text('More'), findsNothing);

      // Verify NO gradient overlays exist
      final cardGradients = tester.widgetList<Container>(
        find.byWidgetPredicate((w) {
          if (w is Container && w.decoration is BoxDecoration) {
            final dec = w.decoration as BoxDecoration;
            if (dec.gradient is LinearGradient) {
              final grad = dec.gradient as LinearGradient;
              return grad.begin == Alignment.topCenter && grad.end == Alignment.bottomCenter;
            }
          }
          return false;
        }),
      );
      expect(cardGradients.isEmpty, isTrue);

      // Verify NO footer containers exist
      final footers = tester.widgetList<Expanded>(
        find.byWidgetPredicate((w) => w is Expanded && w.flex == 24),
      );
      expect(footers.isEmpty, isTrue);

      // Capture screenshot
      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();
        const outDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';
        await File('$outDir/comb_D_labels_OFF_overlay_OFF.png').writeAsBytes(bytes);
        await File('docs/qa/card_label_visibility/comb_D_labels_OFF_overlay_OFF.png').create(recursive: true);
        await File('docs/qa/card_label_visibility/comb_D_labels_OFF_overlay_OFF.png').writeAsBytes(bytes);
      });
    });

    testWidgets('Restoration: Toggling Show Card Labels OFF then ON restores previous label position', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(MaterialApp(home: HomePage(key: UniqueKey())));
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(HomePage)) as dynamic;

      // 1. Set Overlay = OFF (Footer mode)
      state.showCardLabelsForTesting = true;
      state.useImageOverlayLabelForTesting = false;
      await tester.pumpAndSettle();
      expect(find.byWidgetPredicate((w) => w is Expanded && w.flex == 24), findsWidgets);

      // 2. Turn Show Card Labels = OFF
      state.showCardLabelsForTesting = false;
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsNothing);
      expect(find.byWidgetPredicate((w) => w is Expanded && w.flex == 24), findsNothing);

      // 3. Turn Show Card Labels = ON -> Must restore Footer mode!
      state.showCardLabelsForTesting = true;
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
      expect(state.useImageOverlayLabelForTesting, isFalse);
      expect(find.byWidgetPredicate((w) => w is Expanded && w.flex == 24), findsWidgets);

      // 4. Set Overlay = ON (Overlay mode)
      state.useImageOverlayLabelForTesting = true;
      await tester.pumpAndSettle();
      expect(find.byWidgetPredicate((w) => w is Expanded && w.flex == 24), findsNothing);

      // 5. Turn Show Card Labels = OFF
      state.showCardLabelsForTesting = false;
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsNothing);

      // 6. Turn Show Card Labels = ON -> Must restore Overlay mode!
      state.showCardLabelsForTesting = true;
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
      expect(state.useImageOverlayLabelForTesting, isTrue);
    });

    testWidgets('Folder Navigation & Nested Categories when Labels OFF', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(MaterialApp(home: HomePage(key: UniqueKey())));
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(HomePage)) as dynamic;
      state.showCardLabelsForTesting = false;
      await tester.pumpAndSettle();

      // Find Default folder card via semantics or Key
      final defaultCardFinder = find.byKey(const ValueKey('simpleaac.starter.v2.default'));
      expect(defaultCardFinder, findsOneWidget);

      // Tap Default folder
      await tester.tap(defaultCardFinder);
      await tester.pumpAndSettle();

      // In Default folder, verify category cards exist and no labels are visible
      expect(find.text('Animals'), findsNothing);
      expect(find.text('Feelings'), findsNothing);

      // Animals folder card exists via ValueKey
      final animalsCardFinder = find.byKey(const ValueKey('simpleaac.starter.v2.animals'));
      expect(animalsCardFinder, findsOneWidget);

      // Tap into Animals
      await tester.tap(animalsCardFinder);
      await tester.pumpAndSettle();

      // Inside Animals: Dog and Cat exist, but text is hidden
      expect(find.text('Dog'), findsNothing);
      expect(find.text('Cat'), findsNothing);
      expect(find.byKey(const ValueKey('simpleaac.starter.v2.animals.dog')), findsOneWidget);

      // Tap Dog card to ensure speech / sentence bar building works
      await tester.tap(find.byKey(const ValueKey('simpleaac.starter.v2.animals.dog')));
      await tester.pumpAndSettle();

      // Verify token added to sentence bar with label 'Dog'
      expect(
        find.descendant(of: find.byType(TtsBar), matching: find.text('Dog')),
        findsOneWidget,
        reason: 'Underlying card label must still build sentences in sentence bar',
      );
    });
  });
}
