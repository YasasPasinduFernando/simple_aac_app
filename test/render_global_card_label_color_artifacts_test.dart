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
import 'package:simple_aac_app/widgets/home_drawer.dart';
import 'package:simple_aac_app/widgets/professional_color_picker_dialog.dart';

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
  const artifactDir =
      '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013';

  setUpAll(() {
    AudioplayersPlatformInterface.instance = _FakeAudioPlatform();
  });

  setUp(() async {
    AudioplayersPlatformInterface.instance = _FakeAudioPlatform();
    tempDir = await Directory.systemTemp.createTemp('render_artifacts_');
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
      final img = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final outDir = Directory('$artifactDir/qa_renders');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      File('$artifactDir/qa_renders/$filename').writeAsBytesSync(bytes);
      File('$artifactDir/$filename').writeAsBytesSync(bytes);
    });
  }

  testWidgets('Render 1: Home in Default Warm Ivory (#F4F1EB)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final customPhoto1 = File('${tempDir.path}/chair.jpg');
    customPhoto1.writeAsBytesSync(k1x1PngBytes);
    final customPhoto2 = File('${tempDir.path}/new_item.jpg');
    customPhoto2.writeAsBytesSync(k1x1PngBytes);

    final cards = [
      AACCard(
        id: 'custom_chair',
        label: 'Chair',
        imagePath: customPhoto1.path,
        colorValue: 0xFFE6EE9C,
      ),
      AACCard(
        id: 'seed_happy',
        label: 'Happy',
        imagePath: 'assets/home/happy.webp',
        colorValue: 0xFFFFF176,
      ),
      AACCard(
        id: 'seed_sad',
        label: 'Sad',
        imagePath: 'assets/home/sad.webp',
        colorValue: 0xFF81D4FA,
      ),
      AACCard(
        id: 'seed_angry',
        label: 'Angry',
        imagePath: 'assets/home/angry.webp',
        colorValue: 0xFFFF8A80,
      ),
      AACCard(
        id: 'seed_more',
        label: 'More',
        imagePath: 'assets/images/seed_v2/more.webp',
        colorValue: 0xFF5C6BC0,
        type: 'folder',
        subCards: List.generate(
            8, (i) => AACCard(id: 'sub_$i', label: 'Item $i', colorValue: 0xFFFFFFFF)),
      ),
      AACCard(
        id: StarterPackService.starterPackRootId,
        label: 'Default',
        imagePath: 'assets/home/default_folder_cover.webp',
        colorValue: 0xFF0288D1,
        type: 'folder',
        subCards: List.generate(
            13, (i) => AACCard(id: 'cat_$i', label: 'Cat $i', colorValue: 0xFFFFFFFF)),
      ),
      AACCard(
        id: 'custom_new1',
        label: 'New',
        imagePath: customPhoto2.path,
        colorValue: 0xFF00B0FF,
      ),
      AACCard(
        id: 'custom_new2',
        label: 'New',
        imagePath: customPhoto2.path,
        colorValue: 0xFF00E5FF,
      ),
    ];

    SharedPreferences.setMockInitialValues({
      'hasSeededDefaultCards': true,
      'isTutorialCompleted': true,
      'isBoardTutorialDismissed': true,
      TutorialService.prefCompleted: true,
      TutorialService.prefSkipped: true,
      'useImageOverlayLabel': false, // Mode B
      'showCardLabels': true,
      'gridColumns': 2,
      'globalCardLabelBackgroundColor': 0xFFF4F1EB,
    });

    await NetworkPolicyService.instance.init();
    HomePage.initialCardsForTesting = cards;

    final repaintKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: repaintKey,
          child: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveScreenshot(tester, repaintKey, '01_ACTUAL_Home_Warm_Ivory.png');
  });

  testWidgets('Render 2: Settings Drawer with Card Label Color (Global)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repaintKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          endDrawer: HomeDrawer(
            selectedCategory: 'All',
            currentLanguageLabel: 'English',
            gridColumns: 2,
            visibleCardsLabel: 'All cards (8/8)',
            isEditMode: false,
            showTtsInput: true,
            orientationLabel: 'Portrait',
            fullScreen: true,
            headerColor: const Color(0xFF0277BD),
            headerTextColor: Colors.white,
            hideTtsText: false,
            useImageOverlayLabel: false,
            applyTextColorToCards: false,
            isDarkMode: false,
            isColorBlindMode: false,
            primaryColorSwatch: const Color(0xFF0277BD),
            textColorSwatch: Colors.white,
            backgroundColorSwatch: Colors.white,
            cardTextColorSwatch: const Color(0xFF111827),
            cardLabelBgColorSwatch: const Color(0xFFF4F1EB),
            isOnlineEnabled: true,
            onToggleOnline: (_) {},
            onToggleDarkMode: (_) {},
            onChangeColorBlindMode: (_) {},
            onSelectCategory: () {},
            onAddCategory: () {},
            onToggleEdit: () {},
            onToggleTtsInput: () {},
            onToggleTtsText: () {},
            onToggleCardImageLabel: () {},
            onToggleApplyTextColorToCards: () {},
            onChangeOrientation: () {},
            onPickPrimaryColor: () {},
            onPickTextColor: () {},
            onPickBackgroundColor: () {},
            onShowTtsBarSize: () {},
            onToggleFullScreen: () {},
            onShowLanguage: () {},
            onShowGrid: () {},
            onShowVisibleCount: () {},
            onBackup: () {},
            onRestore: () {},
            onResetSettings: () {},
            speechStatusLabel: 'Ready',
            onShowAbout: () {},
          ),
          body: RepaintBoundary(
            key: repaintKey,
            child: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Open drawer
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Card Label Color (Global)'), 150);
    await tester.pumpAndSettle();

    await saveScreenshot(
        tester, repaintKey, '02_ACTUAL_Settings_Drawer_Card_Label_Color.png');
  });

  testWidgets('Render 3: Color Picker Dialog with 3-Card Live Preview',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repaintKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.65),
          body: Center(
            child: RepaintBoundary(
              key: repaintKey,
              child: SizedBox(
                width: 380,
                child: ProfessionalColorPickerDialog(
                  title: 'Card Label Color (Global)',
                  subtitle:
                      'Choose one background color for the card labels (applies to all cards)',
                  initialColor: const Color(0xFFF4F1EB),
                  defaultColor: const Color(0xFFF4F1EB),
                  headerColor: const Color(0xFF0277BD),
                  previewType: ColorPickerPreviewType.labelBackgroundPreview,
                  onApply: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await saveScreenshot(
        tester, repaintKey, '03_ACTUAL_Global_Card_Label_Color_Dialog.png');
  });

  testWidgets('Render 4: Home in Soft Blue (#DFEFFA)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final customPhoto1 = File('${tempDir.path}/chair.jpg');
    customPhoto1.writeAsBytesSync(k1x1PngBytes);
    final customPhoto2 = File('${tempDir.path}/new_item.jpg');
    customPhoto2.writeAsBytesSync(k1x1PngBytes);

    final cards = [
      AACCard(
        id: 'custom_chair',
        label: 'Chair',
        imagePath: customPhoto1.path,
        colorValue: 0xFFE6EE9C,
      ),
      AACCard(
        id: 'seed_happy',
        label: 'Happy',
        imagePath: 'assets/home/happy.webp',
        colorValue: 0xFFFFF176,
      ),
      AACCard(
        id: 'seed_sad',
        label: 'Sad',
        imagePath: 'assets/home/sad.webp',
        colorValue: 0xFF81D4FA,
      ),
      AACCard(
        id: 'seed_angry',
        label: 'Angry',
        imagePath: 'assets/home/angry.webp',
        colorValue: 0xFFFF8A80,
      ),
      AACCard(
        id: 'seed_more',
        label: 'More',
        imagePath: 'assets/images/seed_v2/more.webp',
        colorValue: 0xFF5C6BC0,
        type: 'folder',
        subCards: List.generate(
            8, (i) => AACCard(id: 'sub_$i', label: 'Item $i', colorValue: 0xFFFFFFFF)),
      ),
      AACCard(
        id: StarterPackService.starterPackRootId,
        label: 'Default',
        imagePath: 'assets/home/default_folder_cover.webp',
        colorValue: 0xFF0288D1,
        type: 'folder',
        subCards: List.generate(
            13, (i) => AACCard(id: 'cat_$i', label: 'Cat $i', colorValue: 0xFFFFFFFF)),
      ),
      AACCard(
        id: 'custom_new1',
        label: 'New',
        imagePath: customPhoto2.path,
        colorValue: 0xFF00B0FF,
      ),
      AACCard(
        id: 'custom_new2',
        label: 'New',
        imagePath: customPhoto2.path,
        colorValue: 0xFF00E5FF,
      ),
    ];

    SharedPreferences.setMockInitialValues({
      'hasSeededDefaultCards': true,
      'isTutorialCompleted': true,
      'isBoardTutorialDismissed': true,
      TutorialService.prefCompleted: true,
      TutorialService.prefSkipped: true,
      'useImageOverlayLabel': false, // Mode B
      'showCardLabels': true,
      'gridColumns': 2,
      'globalCardLabelBackgroundColor': 0xFFDFEFFA, // Soft Blue
    });

    await NetworkPolicyService.instance.init();
    HomePage.initialCardsForTesting = cards;

    final repaintKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: repaintKey,
          child: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await saveScreenshot(tester, repaintKey, '04_ACTUAL_Home_Soft_Blue.png');
  });
}
