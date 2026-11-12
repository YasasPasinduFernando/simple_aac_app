import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/models/aac_card_model.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/utils/app_permissions_helper.dart';
import 'package:simple_aac_app/utils/camera_object_helper.dart';
import 'package:simple_aac_app/widgets/card_editor_dialog.dart';

class _FakeAudioPlayer extends Fake implements AudioPlayer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'online_features_enabled': false});
    await NetworkPolicyService.instance.init();
    AppPermissionsHelper.statusReader = (_) async => PermissionStatus.granted;
  });

  tearDown(() {
    AppPermissionsHelper.resetTestHooks();
    CameraObjectHelper.resetTestHooks();
  });

  group('CameraAnalysisResult.fromMap', () {
    test('parses native ML Kit map cleanly', () {
      final result = CameraAnalysisResult.fromMap({
        'hasObject': true,
        'isTooDarkOrBlank': false,
        'labels': ['Cup', '  ', 'Tableware'],
        'topConfidence': 0.87,
        'objectCount': 2,
      });

      expect(result.hasObject, isTrue);
      expect(result.isTooDarkOrBlank, isFalse);
      expect(result.labels, ['Cup', 'Tableware']);
      expect(result.topConfidence, closeTo(0.87, 0.001));
      expect(result.objectCount, 2);
      expect(result.analyzerAvailable, isTrue);
    });
  });

  group('CameraObjectHelper.captureAndVerify', () {
    testWidgets(
        'shows No Object Detected when blank, deletes rejected capture on Retake, then accepts detected object',
        (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('cam_ml_test_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      final blankShot = File('${tempDir.path}/blank.jpg')
        ..writeAsBytesSync([0, 1, 2]);
      final cupShot = File('${tempDir.path}/cup.jpg')
        ..writeAsBytesSync([3, 4, 5]);
      final persistedShot = File('${tempDir.path}/persisted_cup.jpg');

      var shotIndex = 0;
      CameraObjectHelper.cameraPickerOverride = ({int imageQuality = 85}) async {
        shotIndex++;
        return XFile(shotIndex == 1 ? blankShot.path : cupShot.path);
      };
      CameraObjectHelper.analyzerOverride = (path) async {
        if (path == blankShot.path) {
          return const CameraAnalysisResult(
            hasObject: false,
            isTooDarkOrBlank: true,
            labels: [],
            topConfidence: 0.0,
            objectCount: 0,
            analyzerAvailable: true,
          );
        }
        return const CameraAnalysisResult(
          hasObject: true,
          isTooDarkOrBlank: false,
          labels: ['Cup', 'Drinkware'],
          topConfidence: 0.91,
          objectCount: 1,
          analyzerAvailable: true,
        );
      };
      CameraObjectHelper.persistMediaOverride =
          (sourcePath, {required String cardId}) async {
        persistedShot.writeAsBytesSync(File(sourcePath).readAsBytesSync());
        return persistedShot.path;
      };

      late BuildContext savedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                savedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final outcomeFuture = CameraObjectHelper.captureAndVerify(
        savedContext,
        cardId: 'card_cup',
      );
      await tester.pumpAndSettle();

      expect(find.text('No Object Detected'), findsOneWidget);
      expect(find.text('No object detected'), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);
      expect(find.text('Use Anyway'), findsOneWidget);

      await tester.tap(find.text('Retake'));
      await tester.pumpAndSettle();

      final outcome = await outcomeFuture;
      expect(shotIndex, 2);
      expect(blankShot.existsSync(), isFalse);
      expect(outcome, isNotNull);
      expect(outcome!.imagePath, persistedShot.path);
      expect(outcome.analysis.hasObject, isTrue);
      expect(outcome.analysis.labels, ['Cup', 'Drinkware']);
    });

    testWidgets('allows keeping photo when user taps Use Anyway',
        (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('cam_ml_anyway_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      final darkShot = File('${tempDir.path}/dark.jpg')
        ..writeAsBytesSync([9, 9]);
      final persistedShot = File('${tempDir.path}/persisted_dark.jpg');

      CameraObjectHelper.cameraPickerOverride =
          ({int imageQuality = 85}) async => XFile(darkShot.path);
      CameraObjectHelper.analyzerOverride = (_) async =>
          const CameraAnalysisResult(
            hasObject: false,
            isTooDarkOrBlank: false,
            labels: [],
            topConfidence: 0.0,
            objectCount: 0,
            analyzerAvailable: true,
          );
      CameraObjectHelper.persistMediaOverride =
          (sourcePath, {required String cardId}) async {
        persistedShot.writeAsBytesSync(File(sourcePath).readAsBytesSync());
        return persistedShot.path;
      };

      late BuildContext savedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                savedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final future = CameraObjectHelper.captureAndVerify(
        savedContext,
        cardId: 'card_anyway',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use Anyway'));
      await tester.pumpAndSettle();

      final outcome = await future;
      expect(outcome, isNotNull);
      expect(outcome!.imagePath, persistedShot.path);
      expect(outcome.analysis.hasObject, isFalse);
      expect(outcome.analysis.analyzerAvailable, isTrue);
    });
  });

  testWidgets(
      'CardEditorDialog surfaces one-tap offline ML Kit label suggestion after Camera capture',
      (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('cam_ml_editor_');
    addTearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });
    final shot = File('${tempDir.path}/apple.jpg')..writeAsBytesSync([1, 2, 3]);
    final persisted = File('${tempDir.path}/persisted_apple.jpg');

    CameraObjectHelper.cameraPickerOverride =
        ({int imageQuality = 85}) async => XFile(shot.path);
    CameraObjectHelper.analyzerOverride = (_) async =>
        const CameraAnalysisResult(
          hasObject: true,
          isTooDarkOrBlank: false,
          labels: ['Apple', 'Fruit'],
          topConfidence: 0.94,
          objectCount: 1,
          analyzerAvailable: true,
        );
    CameraObjectHelper.persistMediaOverride =
        (sourcePath, {required String cardId}) async {
      persisted.writeAsBytesSync(File(sourcePath).readAsBytesSync());
      return persisted.path;
    };

    final card = AACCard(
      id: 'new_card',
      label: '',
      colorValue: 0xFFA5D6A7,
      category: 'General',
    );

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardEditorDialog(
            card: card,
            isNew: true,
            categories: const ['General', 'Food'],
            audioPlayer: _FakeAudioPlayer(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Detected (offline)'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Fruit'), findsOneWidget);

    await tester.tap(find.text('Apple'));
    await tester.pumpAndSettle();

    final enField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'English Label'),
    );
    expect(enField.controller?.text, 'Apple');
    expect(tester.takeException(), isNull);
  });
}
