import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/services/tutorial_service.dart';
import 'package:simple_aac_app/utils/app_permissions_helper.dart';
import 'package:simple_aac_app/utils/camera_object_helper.dart';
import 'package:simple_aac_app/utils/image_crop_helper.dart';
import 'package:simple_aac_app/widgets/card_editor_dialog.dart';

class _FakeAudioPlayer extends Fake implements AudioPlayer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory docsDir;
  late File samplePhoto;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'online_features_enabled': false,
      TutorialService.prefCompleted: true,
      TutorialService.prefSkipped: true,
    });
    await NetworkPolicyService.instance.init();
    await TutorialService.instance.init();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'online_features_enabled': false,
      TutorialService.prefCompleted: true,
      TutorialService.prefSkipped: true,
      'hasSeededDefaultCards': true,
      'seededDefaultCardsVersion': CardStorageService.defaultCatalogVersion,
    });
    tempDir = await Directory.systemTemp.createTemp('card_lifecycle_temp_');
    docsDir = await Directory.systemTemp.createTemp('card_lifecycle_docs_');
    ImageCropHelper.tempDirectoryOverride = () => tempDir;
    CardStorageService.docsDirectoryOverride = () async => docsDir;

    AppPermissionsHelper.statusReader = (p) async => PermissionStatus.granted;
    AppPermissionsHelper.permissionRequester = (p) async => PermissionStatus.granted;

    // Create a 640x480 test image
    final testImg = img.Image(width: 640, height: 480);
    img.fill(testImg, color: img.ColorRgb8(120, 180, 240));
    samplePhoto = File('${tempDir.path}/camera_sample.jpg');
    samplePhoto.writeAsBytesSync(img.encodeJpg(testImg));

    CameraObjectHelper.analyzerOverride = (path) async {
      return const CameraAnalysisResult(
        hasObject: true,
        isTooDarkOrBlank: false,
        labels: ['TestItem'],
        topConfidence: 0.95,
        objectCount: 1,
        analyzerAvailable: true,
      );
    };

    CameraObjectHelper.cameraPickerOverride = ({int imageQuality = 85}) async {
      return XFile(samplePhoto.path);
    };

    CameraObjectHelper.persistMediaOverride =
        (sourcePath, {required String cardId}) async {
      final dest = File('${docsDir.path}/images/persisted_${DateTime.now().microsecondsSinceEpoch}.jpg');
      dest.parent.createSync(recursive: true);
      dest.writeAsBytesSync(File(sourcePath).readAsBytesSync());
      return dest.path;
    };
  });

  tearDown(() async {
    AppPermissionsHelper.resetTestHooks();
    CameraObjectHelper.resetTestHooks();
    ImageCropHelper.tempDirectoryOverride = null;
    CardStorageService.docsDirectoryOverride = null;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    if (await docsDir.exists()) {
      await docsDir.delete(recursive: true);
    }
  });

  Widget buildEditor({
    required AACCard card,
    required bool isNew,
    void Function(String permanentPath)? onMediaCreated,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CardEditorDialog(
          card: card,
          isNew: isNew,
          categories: const ['General', 'Food', 'More'],
          audioPlayer: _FakeAudioPlayer(),
          onMediaCreated: onMediaCreated,
        ),
      ),
    );
  }

  Future<List<AACCard>> loadStoredCards(WidgetTester tester) async {
    final res = await tester.runAsync(() => CardStorageService.loadCards());
    return res ?? <AACCard>[];
  }

  Future<void> saveStoredCards(WidgetTester tester, List<AACCard> cards) async {
    await tester.runAsync(() => CardStorageService.saveCards(cards));
  }

  group('Transactional Card Creation & Camera/Crop Lifecycle Tests', () {
    testWidgets('1 & 2. Open camera and return without saving leaves storage untouched', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final newCard = AACCard(id: 'c1', label: 'New', colorValue: 0xFF0284C7, category: 'General');
      final cardsList = <AACCard>[];

      await tester.pumpWidget(buildEditor(card: newCard, isNew: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      expect(find.text('Crop & Zoom'), findsOneWidget);
      expect(cardsList.isEmpty, isTrue);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      final storedCards = await loadStoredCards(tester);
      expect(storedCards.isEmpty, isTrue);
    });

    testWidgets('3 & 4. Cancel crop discards temporary capture and leaves storage untouched', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final newCard = AACCard(id: 'c2', label: 'New', colorValue: 0xFF0284C7, category: 'General');

      await tester.pumpWidget(buildEditor(card: newCard, isNew: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Cancel crop
      expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Returned to CardEditorDialog
      expect(find.text('Create New Card'), findsOneWidget);
      expect(newCard.imagePath, isNull);

      final storedCards = await loadStoredCards(tester);
      expect(storedCards.isEmpty, isTrue);
    });

    testWidgets('5. Confirm crop updates editor preview without creating or saving card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final newCard = AACCard(id: 'c3', label: 'New', colorValue: 0xFF0284C7, category: 'General');

      await tester.pumpWidget(buildEditor(card: newCard, isNew: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Tap Use Photo in crop dialog
      expect(find.text('Use Photo'), findsOneWidget);
      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      // Back in editor, cropped image path is staged
      expect(find.text('Create New Card'), findsOneWidget);
      expect(newCard.imagePath, isNotNull);
      expect(File(newCard.imagePath!).existsSync(), isTrue);

      // BUT persistent cards list is strictly empty!
      final storedCards = await loadStoredCards(tester);
      expect(storedCards.isEmpty, isTrue);
    });

    testWidgets('6. Save after crop creates exactly one card in persistent storage', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final newCard = AACCard(id: 'c4', label: 'Water', colorValue: 0xFF0284C7, category: 'General');

      await tester.pumpWidget(buildEditor(card: newCard, isNew: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      // Now tap Save Card
      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      await saveStoredCards(tester, [newCard]);

      final loaded = await loadStoredCards(tester);
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('c4'));
      expect(loaded.first.imagePath, isNotNull);
      expect(File(loaded.first.imagePath!).existsSync(), isTrue);
    });

    testWidgets('7. Rapidly tapping Save Card commits exactly once without duplicate saves', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final newCard = AACCard(id: 'c5', label: 'Rapid Tap', colorValue: 0xFF0284C7, category: 'General');

      await tester.pumpWidget(buildEditor(card: newCard, isNew: true));
      await tester.pumpAndSettle();

      // Rapidly tap Save Card multiple times
      await tester.tap(find.text('Save Card'));
      await tester.tap(find.text('Save Card'), warnIfMissed: false);
      await tester.tap(find.text('Save Card'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('8. Cancelling Create New Card leaves zero cards in storage and cleans temp files', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final newCard = AACCard(id: 'c6', label: 'To Cancel', colorValue: 0xFF0284C7, category: 'General');

      await tester.pumpWidget(buildEditor(card: newCard, isNew: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      final tempCroppedPath = newCard.imagePath;
      expect(tempCroppedPath, isNotNull);
      expect(File(tempCroppedPath!).existsSync(), isTrue);

      // Tap Cancel in CardEditorDialog
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Temp cropped file must be purged
      expect(File(tempCroppedPath).existsSync(), isFalse);

      final loaded = await loadStoredCards(tester);
      expect(loaded.isEmpty, isTrue);
    });

    testWidgets('9. Camera launch failure shows guidance dialog with zero unintended cards', (tester) async {
      CameraObjectHelper.cameraPickerOverride = ({int imageQuality = 85}) async {
        throw const FormatException('Simulated camera error');
      };

      final newCard = AACCard(id: 'c7', label: 'Fail Test', colorValue: 0xFF0284C7, category: 'General');

      await tester.pumpWidget(buildEditor(card: newCard, isNew: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Dialog explaining camera launch error is presented
      expect(find.text('Camera Launch Failed'), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog).last, matching: find.text('Cancel')));
      await tester.pumpAndSettle();

      // Editor remains active without unintended card creation
      expect(find.text('Create New Card'), findsOneWidget);
      final loaded = await loadStoredCards(tester);
      expect(loaded.isEmpty, isTrue);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('10. Gallery image crop and save creates exactly one card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final newCard = AACCard(id: 'c8', label: 'Gallery Card', colorValue: 0xFF0284C7, category: 'General');

      await tester.pumpWidget(buildEditor(card: newCard, isNew: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      await saveStoredCards(tester, [newCard]);
      final loaded = await loadStoredCards(tester);
      expect(loaded.length, equals(1));
    });

    testWidgets('11. Background/resume during editor preserves state safely', (tester) async {
      final newCard = AACCard(id: 'c9', label: 'Background Test', colorValue: 0xFF0284C7, category: 'General');

      await tester.pumpWidget(buildEditor(card: newCard, isNew: true));
      await tester.pumpAndSettle();

      // Enter label
      await tester.enterText(find.widgetWithText(TextField, 'English Label'), 'Custom Label');
      await tester.pumpAndSettle();

      // Simulate AppLifecycleState transition
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Custom Label'), findsOneWidget);
    });

    testWidgets('12. Repeated camera operations purge previous temporary crops', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final newCard = AACCard(id: 'c10', label: 'Repeat Test', colorValue: 0xFF0284C7, category: 'General');

      await tester.pumpWidget(buildEditor(card: newCard, isNew: true));
      await tester.pumpAndSettle();

      // First capture & crop
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      final firstCropPath = newCard.imagePath;
      expect(firstCropPath, isNotNull);
      expect(File(firstCropPath!).existsSync(), isTrue);

      // Second capture & crop
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      final secondCropPath = newCard.imagePath;
      expect(secondCropPath, isNotNull);
      expect(secondCropPath, isNot(equals(firstCropPath)));

      // Tap Save Card
      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      // Old temp crops are cleaned up, permanent image is preserved
      expect(File(firstCropPath).existsSync(), isFalse);
      expect(newCard.imagePath, isNotNull);
      expect(newCard.imagePath, isNot(equals(secondCropPath)));
      expect(File(newCard.imagePath!).existsSync(), isTrue);
    });

    testWidgets('13. Existing card image editing modifies card in-place without adding extra cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final existingCard = AACCard(
        id: 'c11_existing',
        label: 'Existing',
        colorValue: 0xFF0284C7,
        category: 'General',
        imagePath: samplePhoto.path,
      );

      final List<AACCard> cards = [existingCard];
      await saveStoredCards(tester, cards);

      await tester.pumpWidget(buildEditor(card: existingCard, isNew: false));
      await tester.pumpAndSettle();

      // Verify Crop & Zoom tool is accessible for existing image
      expect(find.byTooltip('Crop & Zoom'), findsOneWidget);
      await tester.tap(find.byTooltip('Crop & Zoom'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      await saveStoredCards(tester, cards);

      final loaded = await loadStoredCards(tester);
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('c11_existing'));
    });

    testWidgets('14. New card creation inside More folder adds to folder subCards only', (tester) async {
      final moreFolder = AACCard(
        id: 'folder_more',
        label: 'More',
        colorValue: 0xFF0284C7,
        type: 'folder',
        category: 'General',
        subCards: [],
      );

      final subCard = AACCard(
        id: 'c12_sub',
        label: 'More Item',
        colorValue: 0xFF0284C7,
        category: 'General',
      );

      await tester.pumpWidget(buildEditor(card: subCard, isNew: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      moreFolder.subCards.add(subCard);
      expect(moreFolder.subCards.length, equals(1));
      expect(moreFolder.subCards.first.id, equals('c12_sub'));
    });

    testWidgets('15. New card creation inside nested subfolder adds to nested subCards only', (tester) async {
      final subFolder = AACCard(
        id: 'deep_subfolder',
        label: 'Subfolder',
        colorValue: 0xFF0284C7,
        type: 'folder',
        category: 'General',
        subCards: [],
      );

      final parentFolder = AACCard(
        id: 'top_folder',
        label: 'Top',
        colorValue: 0xFF0284C7,
        type: 'folder',
        category: 'General',
        subCards: [subFolder],
      );

      final deepCard = AACCard(
        id: 'c13_deep',
        label: 'Deep Item',
        colorValue: 0xFF0284C7,
        category: 'General',
      );

      await tester.pumpWidget(buildEditor(card: deepCard, isNew: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Card'));
      await tester.pumpAndSettle();

      subFolder.subCards.add(deepCard);
      expect(parentFolder.subCards.first.subCards.length, equals(1));
      expect(parentFolder.subCards.first.subCards.first.id, equals('c13_deep'));
    });

    testWidgets('16. Card persistence survives simulated app restart', (tester) async {
      final card = AACCard(
        id: 'c14_restart',
        label: 'Survives Restart',
        labelSinhala: 'නැවත අරඹයි',
        labelTamil: 'மீண்டும் தொடங்கு',
        colorValue: 0xFF0284C7,
        category: 'Food',
        imagePath: samplePhoto.path,
      );

      await saveStoredCards(tester, [card]);

      final reloaded = await loadStoredCards(tester);
      expect(reloaded.length, equals(1));
      expect(reloaded.first.id, equals('c14_restart'));
      expect(reloaded.first.label, equals('Survives Restart'));
      expect(reloaded.first.labelSinhala, equals('නැවත අරඹයි'));
      expect(reloaded.first.labelTamil, equals('மீண்டும் தொடங்கு'));
    });
  });
}
