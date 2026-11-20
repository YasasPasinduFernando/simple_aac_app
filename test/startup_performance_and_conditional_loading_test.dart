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

class _FakeAudioplayerPlatform extends AudioplayersPlatformInterface {
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
    AudioplayersPlatformInterface.instance = _FakeAudioplayerPlatform();
    tempDir = await Directory.systemTemp.createTemp('startup_perf_test_');
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
    HomePage.injectedStartupDelayForTesting = null;
    HomePage.forceStartupErrorForTesting = null;
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
    HomePage.injectedStartupDelayForTesting = null;
    HomePage.forceStartupErrorForTesting = null;
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('Startup Performance & Conditional Loading Suite', () {
    testWidgets('1. Fast startup (<380ms): Loader never mounts, direct-to-home without flashing', (tester) async {
      HomePage.initialCardsForTesting = [
        AACCard(id: 'c_fast', label: 'Fast Card', colorValue: 0xFFFFF176),
      ];
      // Fast async completion (50ms < 380ms threshold)
      HomePage.injectedStartupDelayForTesting = const Duration(milliseconds: 50);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // Frame 0: Loader has not mounted yet because 380ms timer has not fired
      expect(find.byType(StartupLoadingView), findsNothing);
      expect(find.byKey(const ValueKey('home_animated_splash_layer')), findsNothing);

      // Fast async completion within 50ms (< 380ms threshold)
      await tester.pump(const Duration(milliseconds: 50));

      // Home grid is immediately visible with the card
      expect(find.text('Fast Card'), findsOneWidget);
      // Loader is NEVER mounted
      expect(find.byType(StartupLoadingView), findsNothing);
      expect(find.byKey(const ValueKey('home_animated_splash_layer')), findsNothing);

      // Advance past 400ms to verify timer cancellation prevents late mounting
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(StartupLoadingView), findsNothing);
    });

    testWidgets('2. Delayed startup (>380ms): Loader mounts at 380ms and fades out when complete', (tester) async {
      HomePage.initialCardsForTesting = [
        AACCard(id: 'c_delayed', label: 'Delayed Card', colorValue: 0xFFFFF176),
      ];
      // Inject a 600ms delay representing heavy cold storage read / DB migrations
      HomePage.injectedStartupDelayForTesting = const Duration(milliseconds: 600);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // At 200ms: still loading, but under 380ms threshold -> loader NOT mounted yet
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(StartupLoadingView), findsNothing);

      // At 400ms (>380ms threshold): loader mounts because work is genuinely pending
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(StartupLoadingView), findsOneWidget);
      expect(find.byKey(const ValueKey('home_animated_splash_layer')), findsOneWidget);
      expect(find.byKey(const ValueKey('splash_cards_row')), findsOneWidget);
      expect(find.byKey(const ValueKey('splash_dots_row')), findsOneWidget);

      // At 650ms: data load finishes, triggering fade out
      await tester.pump(const Duration(milliseconds: 250));
      // Cross-fade completes in 150ms
      await tester.pump(const Duration(milliseconds: 160));

      // Loader is dismissed and Home is cleanly visible
      expect(find.byType(StartupLoadingView), findsNothing);
      expect(find.text('Delayed Card'), findsOneWidget);
    });

    testWidgets('3. Failed startup: Non-destructive error state and Retry button recovers safely', (tester) async {
      HomePage.initialCardsForTesting = [
        AACCard(id: 'c_recovered', label: 'Recovered Card', colorValue: 0xFFFFF176),
      ];
      HomePage.forceStartupErrorForTesting = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));

      // Error UI is displayed
      expect(find.byKey(const ValueKey('splash_error_container')), findsOneWidget);
      expect(find.byKey(const ValueKey('splash_retry_button')), findsOneWidget);

      // Clear the forced error to simulate recovering
      HomePage.forceStartupErrorForTesting = false;

      // Tap Retry button
      await tester.tap(find.byKey(const ValueKey('splash_retry_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200)); // complete reload

      // Error dismisses and app recovers to Home with cards intact
      expect(find.byKey(const ValueKey('splash_error_container')), findsNothing);
      expect(find.text('Recovered Card'), findsOneWidget);
    });

    testWidgets('4. StartupLoadingView displays Hello, Happy, Play cards with specified pastel styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StartupLoadingView(language: 'en'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 3 cards row exists
      expect(find.byKey(const ValueKey('splash_cards_row')), findsOneWidget);

      // Verify the three distinct pastel colors
      // Hello (butter-yellow #FFF1A2), Happy (powder-blue #C6EFFF), Play (pale peach #FFE1CA)
      final containers = tester.widgetList<Container>(find.descendant(
        of: find.byKey(const ValueKey('splash_cards_row')),
        matching: find.byType(Container),
      ));

      final pastelYellowFound = containers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.color == const Color(0xFFFFF1A2);
      });
      final pastelBlueFound = containers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.color == const Color(0xFFC6EFFF);
      });
      final pastelPeachFound = containers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.color == const Color(0xFFFFE1CA);
      });

      expect(pastelYellowFound, isTrue, reason: 'Butter-yellow Hello card present');
      expect(pastelBlueFound, isTrue, reason: 'Powder-blue Happy card present');
      expect(pastelPeachFound, isTrue, reason: 'Pale peach Play card present');
    });

    testWidgets('5. Screen reader semantics announces single loading text and excludes decorative cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StartupLoadingView(language: 'en'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Semantics for loading text exists
      final textSemantics = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'Getting your picture cards ready...',
      );
      expect(textSemantics, findsOneWidget);

      // Mini cards row has ExcludeSemantics so screen reader does not spam 3 decorative cards
      final excludedRow = find.ancestor(
        of: find.byKey(const ValueKey('splash_cards_row')),
        matching: find.byType(ExcludeSemantics),
      );
      expect(excludedRow, findsOneWidget);

      // Pulsing dots row has ExcludeSemantics
      final excludedDots = find.ancestor(
        of: find.byKey(const ValueKey('splash_dots_row')),
        matching: find.byType(ExcludeSemantics),
      );
      expect(excludedDots, findsOneWidget);
    });

    testWidgets('6. Empty-category flash guard: While initial loading is pending, "No cards in this category" is NEVER displayed', (tester) async {
      HomePage.initialCardsForTesting = [
        AACCard(id: 'c_guard', label: 'Guard Card', colorValue: 0xFFFFF176),
      ];
      HomePage.injectedStartupDelayForTesting = const Duration(milliseconds: 200);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // Frame 0: While loading is pending, empty category message must NEVER be present
      expect(find.text('No cards in this category'), findsNothing);
      expect(find.byKey(const ValueKey('grid_initial_loading')), findsOneWidget);

      // Advance halfway (100ms)
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('No cards in this category'), findsNothing);

      // Advance to complete loading
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('Guard Card'), findsOneWidget);
      expect(find.text('No cards in this category'), findsNothing);
    });
  });
}
