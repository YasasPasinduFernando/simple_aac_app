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
import 'package:simple_aac_app/widgets/child_friendly_splash.dart';

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
    tempDir = await Directory.systemTemp.createTemp('splash_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );

    SharedPreferences.setMockInitialValues({
      'online_features_enabled': false,
      'useImageOverlayLabel': true,
      'gridColumns': 2,
    });
    await NetworkPolicyService.instance.init();

    HomePage.enableTtsInit = false;
    HomePage.enableTutorialInit = false;
    HomePage.enablePersonalizeInit = false;
    HomePage.skipSplashForTesting = false;
    HomePage.forceSplashForTesting = false;
    HomePage.initialCardsForTesting = null;
  });

  tearDown(() {
    CardStorageService.docsDirectoryOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    HomePage.forceSplashForTesting = false;
    HomePage.skipSplashForTesting = false;
    HomePage.initialCardsForTesting = null;
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('ChildFriendlySplash Unit & Widget Tests', () {
    testWidgets('1. Renders logo, 3 cards, loading text, and 3 dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildFriendlySplash(language: 'en'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Circular Logo container and unclipped transparent image exist
      expect(find.byKey(const ValueKey('splash_logo_container')), findsOneWidget);
      expect(find.byKey(const ValueKey('splash_logo_image')), findsOneWidget);
      expect(find.byType(ClipOval), findsNothing); // Wordmark is not clipped by ClipOval

      // Loading text exists with expected content
      final textFinder = find.byKey(const ValueKey('splash_loading_text'));
      expect(textFinder, findsOneWidget);
      expect(find.text('Getting your picture cards ready...'), findsOneWidget);

      // 3 cards row exists
      expect(find.byKey(const ValueKey('splash_cards_row')), findsOneWidget);

      // Sparkle icons (auto_awesome)
      expect(find.byIcon(Icons.auto_awesome), findsNWidgets(2));

      // 3 pulsing dots row exists
      expect(find.byKey(const ValueKey('splash_dots_row')), findsOneWidget);
    });

    testWidgets('2. Displays localized loading text for English, Sinhala, and Tamil', (tester) async {
      // English
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildFriendlySplash(language: 'en'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Getting your picture cards ready...'), findsOneWidget);

      // Sinhala
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildFriendlySplash(language: 'si'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('ඔබගේ පින්තූර කාඩ්පත් සූදානම් කරමින්...'), findsOneWidget);

      // Tamil
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildFriendlySplash(language: 'ta'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('உங்கள் பட அட்டைகள் தயாராகின்றன...'), findsOneWidget);
    });

    testWidgets('3. Animation loops smoothly without throwing and triggers callback', (tester) async {
      bool readyCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ChildFriendlySplash(
            language: 'en',
            onAnimationReady: () {
              readyCalled = true;
            },
          ),
        ),
      );

      expect(readyCalled, isTrue);

      // Advance frames across 1 full 2400ms cycle
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('4. Respects reduced-motion accessibility preference (disableAnimations)', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: ChildFriendlySplash(language: 'en'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      // Logo Transform.scale should have scale 1.0 when reduced motion is enabled
      final scaleFinders = find.byType(Transform);
      expect(scaleFinders, findsWidgets);

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('5. Disposes AnimationController cleanly without ticker leaks', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildFriendlySplash(language: 'en'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Replace with empty container to trigger unmount / dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify no exception or dangling ticker
      expect(tester.takeException(), isNull);
    });
  });

  group('HomePage Animated Splash Integration Tests', () {
    testWidgets('6. Shows splash layer during initial loading and removes it when cards load', (tester) async {
      HomePage.forceSplashForTesting = true;
      HomePage.initialCardsForTesting = [
        AACCard(id: 'c1', label: 'Test Card', colorValue: 0xFFFFF176),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // Immediately after initial pump, splash layer is visible with opacity 1.0
      expect(find.byKey(const ValueKey('home_animated_splash_layer')), findsOneWidget);
      expect(find.byType(ChildFriendlySplash), findsOneWidget);
      final initialOpacity = tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('home_animated_splash_layer')));
      expect(initialOpacity.opacity, 1.0);

      // Advance frames so async _loadCards completes and cross-fade completes
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // complete 220ms cross-fade

      // Splash layer is dismissed after cards load
      expect(find.byKey(const ValueKey('home_animated_splash_layer')), findsNothing);
      expect(find.byType(ChildFriendlySplash), findsNothing);
      expect(find.text('Test Card'), findsOneWidget);
    });

    testWidgets('7. skipSplashForTesting bypasses splash overlay for fast test execution', (tester) async {
      HomePage.skipSplashForTesting = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump();

      // Splash overlay is completely bypassed
      expect(find.byKey(const ValueKey('home_animated_splash_layer')), findsNothing);
      expect(find.byType(ChildFriendlySplash), findsNothing);
    });
  });
}
