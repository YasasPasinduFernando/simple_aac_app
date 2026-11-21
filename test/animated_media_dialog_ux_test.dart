import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
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

  testWidgets('GIF processing dialog displays title, subtitle, LinearProgressIndicator and Cancel button',
      (WidgetTester tester) async {
    final completer = Completer<GifConversionResult>();

    AnimatedMediaHelper.videoPickerOverride = (source, {maxDuration}) async =>
        XFile(sampleVideo.path);
    AnimatedMediaHelper.durationProbeOverride = (_) async => 45000; // >30s triggers trim flow
    AnimatedMediaHelper.converterOverride = ({
      required inputPath,
      required outputPath,
      bool trimToLimit = false,
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
    expect(find.descendant(of: processingDialogFinder, matching: find.byType(LinearProgressIndicator)), findsOneWidget);
    expect(find.descendant(of: processingDialogFinder, matching: find.text('Cancel')), findsOneWidget);

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

  testWidgets('Tapping Cancel in GIF processing dialog dismisses dialog and discards result safely',
      (WidgetTester tester) async {
    final completer = Completer<GifConversionResult>();
    var persistCalled = false;

    AnimatedMediaHelper.videoPickerOverride = (source, {maxDuration}) async =>
        XFile(sampleVideo.path);
    AnimatedMediaHelper.durationProbeOverride = (_) async => 20000; // <=30s, no trim warning
    AnimatedMediaHelper.converterOverride = ({
      required inputPath,
      required outputPath,
      bool trimToLimit = false,
    }) {
      return completer.future;
    };
    AnimatedMediaHelper.persistMediaOverride = (sourcePath, {required cardId}) async {
      persistCalled = true;
      return sourcePath;
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
      cardId: 'card_cancel_test',
    );
    await tester.pumpAndSettle();

    // Select "Choose Video"
    await tester.tap(find.text('Choose Video (Max 30s)'));
    await tester.pump(); // Advance to display processing dialog

    final processingDialogFinder = find.byType(AlertDialog).last;
    expect(find.descendant(of: processingDialogFinder, matching: find.text('Creating offline GIF clip...')), findsOneWidget);
    expect(find.descendant(of: processingDialogFinder, matching: find.text('Max 30s • Compact quality')), findsOneWidget);
    expect(find.descendant(of: processingDialogFinder, matching: find.byType(LinearProgressIndicator)), findsOneWidget);

    final cancelButtonFinder = find.descendant(of: processingDialogFinder, matching: find.text('Cancel'));
    expect(cancelButtonFinder, findsOneWidget);

    // User cancels the in-flight conversion
    await tester.tap(cancelButtonFinder);
    await tester.pumpAndSettle();

    // Dialog is immediately gone
    expect(find.text('Creating offline GIF clip...'), findsNothing);

    // Even if native worker later completes, result must be safely discarded
    completer.complete(
      GifConversionResult(
        outputPath: sampleGif.path,
        durationMs: 20000,
        encodedDurationMs: 20000,
        trimmed: false,
        frameCount: 40,
        sizeBytes: sampleGif.lengthSync(),
      ),
    );

    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    final result = await future;

    // Must return null, never persist, and never save card
    expect(result, isNull);
    expect(persistCalled, isFalse);
    expect(sampleVideo.existsSync(), isTrue); // Original input preserved
  });
}
