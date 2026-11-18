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
import 'package:simple_aac_app/utils/ui_mode_helper.dart';

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
  final List<MethodCall> nativeCalls = [];
  final List<MethodCall> systemChromeCalls = [];

  setUp(() async {
    AudioplayersPlatformInterface.instance = FakeAudioplayerPlatform();
    tempDir = await Directory.systemTemp.createTemp('orientation_sensor_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;

    nativeCalls.clear();
    systemChromeCalls.clear();
    UiModeHelper.enableNativeChannelInTests = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('aac_orientation'),
      (call) async {
        nativeCalls.add(call);
        if (call.method == 'setOrientation') {
          return true;
        } else if (call.method == 'getOrientation') {
          return 'landscape';
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        systemChromeCalls.add(call);
        return null;
      },
    );

    SharedPreferences.setMockInitialValues({
      'online_features_enabled': false,
      'useImageOverlayLabel': true,
      'gridColumns': 2,
    });
    await NetworkPolicyService.instance.init();
    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
  });

  tearDown(() async {
    UiModeHelper.enableNativeChannelInTests = false;
    CardStorageService.resetTestHooks();
    HomePage.initialCardsForTesting = null;
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('UiModeHelper Orientation Channel & Method Calls', () {
    test('applyOrientation("landscape") dispatches native SENSOR_LANDSCAPE and both landscape orientations', () {
      UiModeHelper.applyOrientation('landscape');

      // 1. Verify native aac_orientation channel invocation
      expect(nativeCalls, hasLength(1));
      expect(nativeCalls.first.method, 'setOrientation');
      expect(nativeCalls.first.arguments, {'mode': 'landscape'});

      // 2. Verify SystemChrome calls
      final setPreferredCalls = systemChromeCalls
          .where((call) => call.method == 'SystemChrome.setPreferredOrientations')
          .toList();
      expect(setPreferredCalls, isNotEmpty);
      final args = (setPreferredCalls.last.arguments as List).cast<String>();
      expect(args, containsAll([
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]));
      expect(args, isNot(contains('DeviceOrientation.portraitUp')));
      expect(args, isNot(contains('DeviceOrientation.portraitDown')));
    });

    test('applyOrientation("portrait") strictly locks to portraitUp and excludes landscape/upside-down', () {
      UiModeHelper.applyOrientation('portrait');

      // 1. Verify native aac_orientation channel invocation
      expect(nativeCalls, hasLength(1));
      expect(nativeCalls.first.method, 'setOrientation');
      expect(nativeCalls.first.arguments, {'mode': 'portrait'});

      // 2. Verify SystemChrome calls
      final setPreferredCalls = systemChromeCalls
          .where((call) => call.method == 'SystemChrome.setPreferredOrientations')
          .toList();
      expect(setPreferredCalls, isNotEmpty);
      final args = (setPreferredCalls.last.arguments as List).cast<String>();
      expect(args, equals(['DeviceOrientation.portraitUp']));
      expect(args, isNot(contains('DeviceOrientation.portraitDown')));
      expect(args, isNot(contains('DeviceOrientation.landscapeLeft')));
      expect(args, isNot(contains('DeviceOrientation.landscapeRight')));
    });
  });

  group('State Preservation across Orientation and Viewport Changes', () {
    testWidgets('Preserves sentence tokens and active folder when rotating between portrait and landscape',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final childCard = AACCard(
        id: 'card_apple',
        label: 'Apple',
        colorValue: 0xFFFF0000,
      );
      final folderCard = AACCard(
        id: 'folder_food',
        label: 'Food',
        colorValue: 0xFF00FF00,
        subCards: [childCard],
      );

      HomePage.initialCardsForTesting = [folderCard];

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Navigate into folder
      expect(find.text('Food'), findsOneWidget);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Inside folder, Apple should be visible
      expect(find.text('Apple'), findsOneWidget);

      // 2. Tap Apple to add to sentence bar
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      // Verify token in sentence bar
      expect(find.text('Apple'), findsWidgets);

      // 3. Simulate device rotation to Landscape (2400 x 1080)
      tester.view.physicalSize = const Size(2400, 1080);
      await tester.pumpAndSettle();

      // Verify sentence token and folder view are preserved without loss
      expect(find.text('Apple'), findsWidgets);

      // 4. Simulate 180° rotation between Landscape Left & Landscape Right
      // (Screen geometry remains landscape, no Activity recreation / widget tree disposal)
      tester.view.physicalSize = const Size(2400, 1080);
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsWidgets);
    });
  });
}
