import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_aac_app/widgets/child_friendly_splash.dart';

class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final candidatePaths = [
      key,
      'simple_aac_play_release/$key',
      'build/unit_test_assets/$key',
      'simple_aac_play_release/build/unit_test_assets/$key',
    ];

    for (final path in candidatePaths) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        return ByteData.sublistView(bytes);
      }
    }
    throw FlutterError('Asset not found: $key');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Seamless Splash Handoff Verification Suite', () {
    testWidgets('1. At t=0 (handoff frame), Logo is positioned at exact screen vertical center', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FileAssetBundle(),
          child: const MaterialApp(
            home: ChildFriendlySplash(language: 'en'),
          ),
        ),
      );

      // Frame 0: Pump with 0 duration so entrance animation is at 0.0
      await tester.pump(Duration.zero);

      final logoFinder = find.byKey(const ValueKey('splash_logo_container'));
      expect(logoFinder, findsOneWidget);

      final logoCenter = tester.getCenter(logoFinder);
      const expectedScreenCenterY = 800.0 / 2.0; // 400.0

      // The logo must be centered at exact screen vertical center at t=0
      expect(logoCenter.dy, closeTo(expectedScreenCenterY, 1.0));
      expect(logoCenter.dx, closeTo(200.0, 1.0)); // Horizontally centered

      // Subcontent should have opacity 0 on frame 0
      final opacityWidget = tester.widget<Opacity>(find.byKey(const ValueKey('splash_subcontent_opacity')));
      expect(opacityWidget.opacity, equals(0.0));
    });

    testWidgets('2. Over entrance duration (380ms), Logo smoothly floats up and cards fade in', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FileAssetBundle(),
          child: const MaterialApp(
            home: ChildFriendlySplash(language: 'en'),
          ),
        ),
      );

      // Frame 0
      await tester.pump(Duration.zero);
      final logoFinder = find.byKey(const ValueKey('splash_logo_container'));
      final startCenterY = tester.getCenter(logoFinder).dy;

      // Halfway (190ms)
      await tester.pump(const Duration(milliseconds: 190));
      final midCenterY = tester.getCenter(logoFinder).dy;
      expect(midCenterY, lessThan(startCenterY)); // Gliding upward

      final midOpacity = tester.widget<Opacity>(find.byKey(const ValueKey('splash_subcontent_opacity'))).opacity;
      expect(midOpacity, greaterThan(0.0));
      expect(midOpacity, lessThan(1.0));

      // End of entrance (400ms)
      await tester.pump(const Duration(milliseconds: 210));
      final endCenterY = tester.getCenter(logoFinder).dy;
      expect(endCenterY, lessThan(midCenterY));

      final endOpacity = tester.widget<Opacity>(find.byKey(const ValueKey('splash_subcontent_opacity'))).opacity;
      expect(endOpacity, equals(1.0));
    });

    testWidgets('3. Landscape handoff: Logo starts at vertical center and glides smoothly', (tester) async {
      tester.view.physicalSize = const Size(800 * 2.0, 400 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FileAssetBundle(),
          child: const MaterialApp(
            home: ChildFriendlySplash(language: 'en'),
          ),
        ),
      );

      // Frame 0 in landscape
      await tester.pump(Duration.zero);
      final logoFinder = find.byKey(const ValueKey('splash_logo_container'));
      final logoCenter = tester.getCenter(logoFinder);
      const expectedLandscapeCenterY = 400.0 / 2.0; // 200.0

      expect(logoCenter.dy, closeTo(expectedLandscapeCenterY, 1.0));
      expect(logoCenter.dx, closeTo(400.0, 1.0));

      // Advance entrance
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. Reduced motion (disableAnimations) shows completed resting state immediately', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FileAssetBundle(),
          child: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: ChildFriendlySplash(language: 'en'),
            ),
          ),
        ),
      );

      await tester.pump(Duration.zero);

      // Subcontent opacity should be 1.0 immediately
      final opacityWidget = tester.widget<Opacity>(find.byKey(const ValueKey('splash_subcontent_opacity')));
      expect(opacityWidget.opacity, equals(1.0));
    });

    testWidgets('5. Render visual screenshots for before/after comparison', (tester) async {
      final repaintKey = GlobalKey();

      tester.view.physicalSize = const Size(400 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _FileAssetBundle(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: RepaintBoundary(
                key: repaintKey,
                child: const ChildFriendlySplash(language: 'en'),
              ),
            ),
          ),
        ),
      );

      // 1. Frame 0 (Handoff frame - Logo dead center, identical to native splash)
      await tester.pump(Duration.zero);

      final boundary = repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final img0 = await boundary.toImage(pixelRatio: 2.0);
        final bytes0 = (await img0.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
        File('/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013/splash_handoff_frame_0ms.png').writeAsBytesSync(bytes0);
        Directory('docs/qa/splash_screen').createSync(recursive: true);
        File('docs/qa/splash_screen/splash_handoff_frame_0ms.png').writeAsBytesSync(bytes0);
      });

      // 2. Fully revealed animated splash (400ms)
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() async {
        final img1 = await boundary.toImage(pixelRatio: 2.0);
        final bytes1 = (await img1.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
        File('/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013/splash_revealed_cards_frame.png').writeAsBytesSync(bytes1);
        File('docs/qa/splash_screen/splash_revealed_cards_frame.png').writeAsBytesSync(bytes1);
      });
    });
  });
}
