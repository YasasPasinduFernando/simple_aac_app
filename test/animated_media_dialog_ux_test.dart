import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';
import 'package:simple_aac_app/utils/animated_media_helper.dart';
import 'package:simple_aac_app/utils/app_permissions_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDir;
  late File sampleVideo;
  late File sampleGif;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'online_features_enabled': false});
    await NetworkPolicyService.instance.init();
    AppPermissionsHelper.statusReader = (_) async => PermissionStatus.granted;
    AppPermissionsHelper.sdkVersionReader = () async => 34;

    testDir = Directory.systemTemp.createTempSync('gif_dialog_ux_test_');
    sampleVideo = File('${testDir.path}/test_video.mp4')
      ..writeAsBytesSync(<int>[0, 0, 0, 32, 102, 116, 121, 112]);
    sampleGif = File('${testDir.path}/sample.gif')
      ..writeAsBytesSync('GIF89a\x01\x00\x01\x00\x80\x00\x00\xFF\xFF\xFF\x00\x00\x00!\xF9\x04\x00\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;'.codeUnits);

    AnimatedMediaHelper.resetTestHooks();
    CardStorageService.resetTestHooks();
  });

  tearDown(() {
    AppPermissionsHelper.resetTestHooks();
    AnimatedMediaHelper.resetTestHooks();
    CardStorageService.resetTestHooks();
    try {
      testDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets(
      'GIF processing dialog displays title, subtitle, LinearProgressIndicator, close X, and Cancel processing button',
      (WidgetTester tester) async {
    final completer = Completer<GifConversionResult>();

    AnimatedMediaHelper.videoPickerOverride = (source, {maxDuration}) async =>
        XFile(sampleVideo.path);
    AnimatedMediaHelper.durationProbeOverride = (_) async => 45000; // >30s triggers trim flow
    AnimatedMediaHelper.converterOverride = ({
      required inputPath,
      required outputPath,
      bool trimToLimit = false,
      sessionId,
    }) {
      return completer.future;
    };
    AnimatedMediaHelper.persistMediaOverride = (sourcePath, {required cardId}) async {
      return '${testDir.path}/persisted.gif';
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

    final future = AnimatedMediaHelper.pickOrCreateAnimatedGif(
      savedContext,
      cardId: 'card_dialog_test',
    );
    await tester.pumpAndSettle();

    // Select "Choose Video"
    await tester.tap(find.text('Choose Video (Max 30s)'));
    await tester.pumpAndSettle();

    // Long video confirmation dialog appears
    expect(find.text('Video Longer Than 30s'), findsOneWidget);
    await tester.tap(find.text('Use First 30s'));
    await tester.pump(); // Advance to display the processing dialog

    final processingDialogFinder = find.byType(AlertDialog).last;
    expect(find.descendant(of: processingDialogFinder, matching: find.text('Trimming first 30s into GIF...')), findsOneWidget);
    expect(find.descendant(of: processingDialogFinder, matching: find.text('Offline • Compact quality')), findsOneWidget);
    expect(find.descendant(of: processingDialogFinder, matching: find.text('Processing video...')), findsOneWidget);
    expect(find.descendant(of: processingDialogFinder, matching: find.byType(LinearProgressIndicator)), findsOneWidget);
    expect(find.descendant(of: processingDialogFinder, matching: find.text('Cancel processing')), findsOneWidget);
    expect(find.descendant(of: processingDialogFinder, matching: find.byIcon(Icons.close_rounded)), findsNWidgets(2)); // Close icon in title and button

    // Complete the conversion successfully
    completer.complete(
      GifConversionResult(
        outputPath: sampleGif.path,
        durationMs: 45000,
        encodedDurationMs: 30000,
        trimmed: true,
        frameCount: 60,
        sizeBytes: sampleGif.lengthSync(),
      ),
    );

    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    final result = await future;
    expect(result, isNotNull);
    expect(result, contains('persisted.gif'));
  });

  testWidgets(
      'User can cancel GIF processing via Cancel processing button safely and cleanly',
      (WidgetTester tester) async {
    final completer = Completer<GifConversionResult>();
    String? capturedCancelledSessionId;

    AnimatedMediaHelper.videoPickerOverride = (source, {maxDuration}) async =>
        XFile(sampleVideo.path);
    AnimatedMediaHelper.durationProbeOverride = (_) async => 20000;
    AnimatedMediaHelper.converterOverride = ({
      required inputPath,
      required outputPath,
      bool trimToLimit = false,
      sessionId,
    }) {
      return completer.future;
    };
    AnimatedMediaHelper.cancelOverride = (sessionId) async {
      capturedCancelledSessionId = sessionId;
      // Simulate native delay while worker is terminating
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!completer.isCompleted) {
          completer.completeError(
            PlatformException(code: 'CANCELLED', message: 'Conversion cancelled'),
          );
        }
      });
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

    final future = AnimatedMediaHelper.pickOrCreateAnimatedGif(
      savedContext,
      cardId: 'card_cancel_button_test',
    );
    await tester.pumpAndSettle();

    // Select "Choose Video"
    await tester.tap(find.text('Choose Video (Max 30s)'));
    await tester.pump(); // Show progress dialog

    expect(find.text('Cancel processing'), findsOneWidget);

    // Tap "Cancel processing"
    await tester.tap(find.text('Cancel processing'));
    await tester.pump(); // Rebuild with stopping state

    // Button should now indicate stopping
    expect(find.text('Stopping processing…'), findsAtLeastNWidgets(1));
    expect(capturedCancelledSessionId, isNotNull);

    await tester.pumpAndSettle();

    final result = await future;
    expect(result, isNull); // Safely returned null without corrupting card
    expect(sampleVideo.existsSync(), isTrue); // Original video preserved
  });

  testWidgets(
      'User can cancel GIF processing via top-right close X button',
      (WidgetTester tester) async {
    final completer = Completer<GifConversionResult>();
    var cancelCalled = false;

    AnimatedMediaHelper.videoPickerOverride = (source, {maxDuration}) async =>
        XFile(sampleVideo.path);
    AnimatedMediaHelper.durationProbeOverride = (_) async => 20000;
    AnimatedMediaHelper.converterOverride = ({
      required inputPath,
      required outputPath,
      bool trimToLimit = false,
      sessionId,
    }) {
      return completer.future;
    };
    AnimatedMediaHelper.cancelOverride = (sessionId) async {
      cancelCalled = true;
      completer.completeError(
        PlatformException(code: 'CANCELLED', message: 'Conversion cancelled'),
      );
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

    final future = AnimatedMediaHelper.pickOrCreateAnimatedGif(
      savedContext,
      cardId: 'card_cancel_x_test',
    );
    await tester.pumpAndSettle();

    // Select "Choose Video"
    await tester.tap(find.text('Choose Video (Max 30s)'));
    await tester.pump();

    // Find the top-right close button (IconButton)
    final closeButtonFinder = find.widgetWithIcon(IconButton, Icons.close_rounded);
    expect(closeButtonFinder, findsOneWidget);

    await tester.tap(closeButtonFinder);
    await tester.pump();

    expect(cancelCalled, isTrue);
    await tester.pumpAndSettle();

    final result = await future;
    expect(result, isNull);
    expect(sampleVideo.existsSync(), isTrue);
  });

  testWidgets(
      'Cancelled session does not prevent subsequent conversion session from succeeding',
      (WidgetTester tester) async {
    int sessionCount = 0;
    AnimatedMediaHelper.videoPickerOverride = (source, {maxDuration}) async =>
        XFile(sampleVideo.path);
    AnimatedMediaHelper.durationProbeOverride = (_) async => 20000;
    AnimatedMediaHelper.persistMediaOverride = (sourcePath, {required cardId}) async =>
        '${testDir.path}/persisted_retry.gif';

    AnimatedMediaHelper.converterOverride = ({
      required inputPath,
      required outputPath,
      bool trimToLimit = false,
      sessionId,
    }) async {
      sessionCount++;
      if (sessionCount == 1) {
        throw PlatformException(code: 'CANCELLED', message: 'First session cancelled');
      }
      return GifConversionResult(
        outputPath: sampleGif.path,
        durationMs: 20000,
        encodedDurationMs: 20000,
        trimmed: false,
        frameCount: 30,
        sizeBytes: sampleGif.lengthSync(),
      );
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

    // Session 1: Cancelled
    final future1 = AnimatedMediaHelper.pickOrCreateAnimatedGif(
      savedContext,
      cardId: 'card_retry_test',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose Video (Max 30s)'));
    await tester.pumpAndSettle();

    final result1 = await future1;
    expect(result1, isNull);

    // Session 2: Immediate retry succeeding
    final future2 = AnimatedMediaHelper.pickOrCreateAnimatedGif(
      savedContext,
      cardId: 'card_retry_test',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose Video (Max 30s)'));
    await tester.pumpAndSettle();

    final result2 = await future2;
    expect(result2, isNotNull);
    expect(result2, contains('persisted_retry.gif'));
    expect(sessionCount, 2);
  });
}
