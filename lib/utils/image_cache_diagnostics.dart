import 'package:flutter/painting.dart';

/// Diagnostics utility for inspecting Flutter's ImageCache status and memory metrics.
class ImageCacheDiagnostics {
  /// Returns a snapshot of the current ImageCache state.
  static Map<String, dynamic> getSnapshot() {
    final cache = PaintingBinding.instance.imageCache;
    return {
      'currentSizeBytes': cache.currentSizeBytes,
      'currentSizeMB': (cache.currentSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      'maximumSizeBytes': cache.maximumSizeBytes,
      'currentCount': cache.currentSize,
      'maximumSize': cache.maximumSize,
      'liveImageCount': cache.liveImageCount,
      'pendingImageCount': cache.pendingImageCount,
    };
  }

  /// Estimates the decoded bitmap memory for given dimensions in RGBA_8888 (4 bytes per pixel).
  static int estimateBitmapMemoryBytes(int width, int height) {
    return width * height * 4;
  }
}
