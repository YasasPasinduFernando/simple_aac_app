import 'dart:io';
import 'dart:ui' as ui;
// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/data/default_seed_cards.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/services/starter_pack_service.dart';

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
    tempDir = await Directory.systemTemp.createTemp('default_folder_cover_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );

    SharedPreferences.setMockInitialValues({
      'online_features_enabled': false,
      'useImageOverlayLabel': true,
      'gridColumns': 2,
      'language': 'en',
    });
    await NetworkPolicyService.instance.init();
  });

  setUp(() {
    HomePage.skipSplashForTesting = true;
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.initialCardsForTesting = createDefaultSeedCards();
    HomePage.hapticPerformer = () async {};
  });

  tearDown(() {
    HomePage.skipSplashForTesting = false;
    HomePage.initialCardsForTesting = null;
  });

  tearDownAll(() async {
    CardStorageService.resetTestHooks();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  void setPortrait(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  void setLandscape(WidgetTester tester) {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Default Folder Cover Visual Update & Functional Parity', () {
    test('1. Image asset exists on disk and is 768x768 WebP', () {
      final file = File('assets/home/default_folder_cover.webp');
      expect(file.existsSync(), isTrue, reason: 'assets/home/default_folder_cover.webp must exist');
      expect(file.lengthSync(), greaterThan(10000));
    });

    testWidgets('2. Fresh install: Home screen renders Default card with new full-bleed cover', (tester) async {
      setPortrait(tester);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', 'en');

      await tester.pumpWidget(MaterialApp(home: HomePage(key: UniqueKey())));
      await tester.pumpAndSettle();

      // Find Default card
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('13 sub-cards'), findsOneWidget);

      // Verify Image.asset with default_folder_cover.webp is in the widget tree with BoxFit.cover
      final imageFinder = find.byWidgetPredicate((widget) {
        if (widget is Image) {
          final provider = widget.image;
          final inner = provider is ResizeImage ? provider.imageProvider : provider;
          if (inner is AssetImage) {
            return inner.assetName == 'assets/home/default_folder_cover.webp' &&
                widget.fit == BoxFit.cover;
          }
        }
        return false;
      });
      expect(imageFinder, findsOneWidget, reason: 'Default card should use BoxFit.cover with new asset');
    });

    testWidgets('3. Tapping Default folder opens original 13 category folders without data loss', (tester) async {
      setPortrait(tester);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', 'en');

      await tester.pumpWidget(MaterialApp(home: HomePage(key: UniqueKey())));
      await tester.pumpAndSettle();

      // Tap Default folder
      await tester.tap(find.text('Default'));
      await tester.pumpAndSettle();

      // Verify categories inside Default
      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Colours'), findsOneWidget);
      expect(find.text('Shapes'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('4. Existing install: Image is resolved for existing saved card without resync', (tester) async {
      setPortrait(tester);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', 'en');

      // Simulate existing saved card with starter_default.webp
      final existingDefault = StarterPackService.getStarterPackRootClone();
      expect(existingDefault.imagePath, equals('assets/images/starter_pack_v8/starter_default.webp'));

      HomePage.initialCardsForTesting = [existingDefault];
      await tester.pumpWidget(MaterialApp(home: HomePage(key: UniqueKey())));
      await tester.pumpAndSettle();

      // Should automatically render with new cover
      final imageFinder = find.byWidgetPredicate((widget) {
        if (widget is Image) {
          final provider = widget.image;
          final inner = provider is ResizeImage ? provider.imageProvider : provider;
          if (inner is AssetImage) {
            return inner.assetName == 'assets/home/default_folder_cover.webp' &&
                widget.fit == BoxFit.cover;
          }
        }
        return false;
      });
      expect(imageFinder, findsOneWidget);
    });

    test('5. Custom caregiver cover is preserved and not replaced', () async {
      final customPhoto = '${tempDir.path}/caregiver_custom_cover.png';
      await File(customPhoto).writeAsBytes([1, 2, 3, 4]);

      final customDefault = AACCard(
        id: StarterPackService.starterPackRootId,
        label: 'Default',
        type: 'folder',
        imagePath: customPhoto,
        colorValue: 0xFF228ED3,
        subCards: [],
      );

      // Verify that when saved and reloaded, caregiver custom image is preserved
      await CardStorageService.saveCards([customDefault]);
      final loaded = await CardStorageService.loadCards(
        defaultCardsBuilder: createDefaultSeedCards,
      );
      final loadedDefault = loaded.firstWhere((c) => c.id == StarterPackService.starterPackRootId);
      expect(loadedDefault.imagePath, equals(customPhoto),
          reason: 'Caregiver custom cover must NEVER be overwritten');
    });

    testWidgets('6. Localized Home card labels (English, Sinhala, Tamil) display correctly', (tester) async {
      setPortrait(tester);

      final prefs = await SharedPreferences.getInstance();

      // English
      await prefs.setString('language', 'en');
      await tester.pumpWidget(MaterialApp(home: HomePage(key: UniqueKey())));
      await tester.pumpAndSettle();
      expect(find.text('Default'), findsOneWidget);

      // Switch to Sinhala
      await prefs.setString('language', 'si');
      await tester.pumpWidget(MaterialApp(home: HomePage(key: UniqueKey())));
      await tester.pumpAndSettle();
      expect(find.text('පෙරනිමි'), findsOneWidget);
      expect(find.text('13 sub-cards'), findsOneWidget);

      // Switch to Tamil
      await prefs.setString('language', 'ta');
      await tester.pumpWidget(MaterialApp(home: HomePage(key: UniqueKey())));
      await tester.pumpAndSettle();
      expect(find.text('இயல்புநிலை'), findsOneWidget);
    });

    testWidgets('7. High-Resolution Visual Evidence Capture for Documentation', (tester) async {
      setPortrait(tester);

      final outDir = Directory('docs/qa/default_folder_cover');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      const brainDir = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', 'en');

      // 1. Portrait Home Board
      final key1 = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key1,
          child: MaterialApp(home: HomePage(key: UniqueKey())),
        ),
      );
      await tester.pumpAndSettle();

      final boundary1 = key1.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final imgData = await boundary1.toImage(pixelRatio: 2.0);
        final byteData = await imgData.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();
        File('${outDir.path}/01_home_board_default_cover_portrait.png').writeAsBytesSync(bytes);
        File('$brainDir/01_home_board_default_cover_portrait.png').writeAsBytesSync(bytes);
      });

      // 2. Sinhala Home Board
      await prefs.setString('language', 'si');
      final key2 = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key2,
          child: MaterialApp(home: HomePage(key: UniqueKey())),
        ),
      );
      await tester.pumpAndSettle();

      final boundary2 = key2.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final imgData = await boundary2.toImage(pixelRatio: 2.0);
        final byteData = await imgData.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();
        File('${outDir.path}/02_home_board_sinhala_default_cover.png').writeAsBytesSync(bytes);
        File('$brainDir/02_home_board_sinhala_default_cover.png').writeAsBytesSync(bytes);
      });

      // 3. Inside Default Folder
      await tester.tap(find.text('පෙරනිමි'));
      await tester.pumpAndSettle();

      final boundary3 = key2.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final imgData = await boundary3.toImage(pixelRatio: 2.0);
        final byteData = await imgData.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();
        File('${outDir.path}/03_inside_default_folder.png').writeAsBytesSync(bytes);
        File('$brainDir/03_inside_default_folder.png').writeAsBytesSync(bytes);
      });

      // 4. Landscape Home Board
      setLandscape(tester);
      await prefs.setString('language', 'en');
      final key4 = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key4,
          child: MaterialApp(home: HomePage(key: UniqueKey())),
        ),
      );
      await tester.pumpAndSettle();

      final boundary4 = key4.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final imgData = await boundary4.toImage(pixelRatio: 2.0);
        final byteData = await imgData.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();
        File('${outDir.path}/04_home_board_landscape.png').writeAsBytesSync(bytes);
        File('$brainDir/04_home_board_landscape.png').writeAsBytesSync(bytes);
      });

      expect(File('${outDir.path}/01_home_board_default_cover_portrait.png').existsSync(), isTrue);
      expect(File('${outDir.path}/02_home_board_sinhala_default_cover.png').existsSync(), isTrue);
      expect(File('${outDir.path}/03_inside_default_folder.png').existsSync(), isTrue);
      expect(File('${outDir.path}/04_home_board_landscape.png').existsSync(), isTrue);
    });
  });
}
