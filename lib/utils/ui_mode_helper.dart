import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class UiModeHelper {
  static const MethodChannel _orientationChannel =
      MethodChannel('aac_orientation');

  @visibleForTesting
  static bool enableNativeChannelInTests = false;

  static void applyOrientation(String mode) {
    final isLandscape = mode == 'landscape';

    // 1. Cross-platform Flutter system orientation (for non-Android, web, and tests)
    SystemChrome.setPreferredOrientations(isLandscape
        ? [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]
        : [
            DeviceOrientation.portraitUp,
          ]);

    // 2. Android native SENSOR_LANDSCAPE orientation:
    //    Allows physical 180° rotation between Landscape Left and Landscape Right
    //    even when Android system Auto-rotate is locked/OFF.
    if (_shouldUseNativeChannel) {
      _orientationChannel
          .invokeMethod('setOrientation', {'mode': mode})
          .catchError((_) {});
    }
  }

  static bool get _shouldUseNativeChannel {
    try {
      return (!kIsWeb && Platform.isAndroid) || enableNativeChannelInTests;
    } catch (_) {
      return false;
    }
  }

  static void applySystemUi(bool fullScreen) {
    if (fullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}
