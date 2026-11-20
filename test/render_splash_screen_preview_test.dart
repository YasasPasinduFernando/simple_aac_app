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

  testWidgets('Render high-resolution preview of Child-Friendly Animated Splash Screen matching visual reference', (tester) async {
    // Load system font for readable typography
    try {
      final fontLoader = FontLoader('Roboto');
      final fontFile = File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
      if (fontFile.existsSync()) {
        fontLoader.addFont(Future.value(ByteData.sublistView(fontFile.readAsBytesSync())));
        await fontLoader.load();
      }
    } catch (_) {}

    try {
      final iconLoader = FontLoader('MaterialIcons');
      final iconFile = File('/home/yasas/.pub-cache/hosted/pub.dev/shared_preferences-2.5.4/extension/devtools/build/assets/fonts/MaterialIcons-Regular.otf');
      if (iconFile.existsSync()) {
        iconLoader.addFont(Future.value(ByteData.sublistView(iconFile.readAsBytesSync())));
        await iconLoader.load();
      }
    } catch (_) {}

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _FileAssetBundle(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0284C7)),
          ),
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: repaintKey,
                child: const SizedBox(
                  width: 440,
                  height: 880,
                  child: ChildFriendlySplash(
                    language: 'en',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Precache assets to ensure decoded bitmaps are rendered
    await tester.runAsync(() async {
      await precacheImage(const AssetImage('assets/images/simple_aac_logo_transparent.png'), repaintKey.currentContext!);
      await precacheImage(const AssetImage('assets/images/starter_pack_v8/feelings_happy.webp'), repaintKey.currentContext!);
      await precacheImage(const AssetImage('assets/images/starter_pack_v8/feelings_love.webp'), repaintKey.currentContext!);
      await precacheImage(const AssetImage('assets/images/starter_pack_v8/food_apple.webp'), repaintKey.currentContext!);
    });

    // Pump frames to advance animation and paint
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));

    final boundary = repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      const outPath = '/home/yasas/.gemini/antigravity/brain/45b3362b-7002-4cdb-9492-575f18061013/child_friendly_splash_rendered.png';
      File(outPath).writeAsBytesSync(bytes);

      final projectArtifactDir = Directory('docs/qa/splash_screen');
      if (!projectArtifactDir.existsSync()) {
        projectArtifactDir.createSync(recursive: true);
      }
      File('docs/qa/splash_screen/child_friendly_splash_rendered.png').writeAsBytesSync(bytes);
    });
  });
}
