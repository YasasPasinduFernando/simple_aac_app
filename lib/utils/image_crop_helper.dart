import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class ImageCropHelper {
  @visibleForTesting
  static Directory Function()? tempDirectoryOverride;

  static Directory _resolveTempDir() {
    if (tempDirectoryOverride != null) {
      return tempDirectoryOverride!();
    }
    return Directory.systemTemp;
  }
  /// Crops an image to a 1:1 square according to viewport pan & zoom parameters.
  /// Handles EXIF orientation baking, maintains aspect ratio, prevents out-of-bound
  /// borders, and saves a high-quality, storage-optimized square JPEG in temp directory.
  static Future<File> cropSquare({
    required String sourcePath,
    required double zoom,
    required double panX,
    required double panY,
    required double viewportSize,
    int targetDimension = 640,
    int quality = 85,
  }) async {
    final Uint8List bytes;
    if (sourcePath.startsWith('assets/')) {
      final data = await rootBundle.load(sourcePath);
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } else {
      final file = File(sourcePath);
      if (!file.existsSync()) {
        throw FileSystemException('Source image file not found', sourcePath);
      }
      bytes = file.readAsBytesSync();
    }

    final rawImage = img.decodeImage(bytes);
    if (rawImage == null) {
      throw const FormatException('Unable to decode source image');
    }

    // Bake EXIF orientation so rotated mobile camera photos orient right-side up
    final image = img.bakeOrientation(rawImage);
    final srcW = image.width.toDouble();
    final srcH = image.height.toDouble();

    // Base scale required to completely cover the 1:1 viewport
    final baseScale = math.max(viewportSize / srcW, viewportSize / srcH);
    final effectiveScale = baseScale * math.max(1.0, zoom);

    final dispW = srcW * effectiveScale;
    final dispH = srcH * effectiveScale;

    final maxPanX = math.max(0.0, (dispW - viewportSize) / 2.0);
    final maxPanY = math.max(0.0, (dispH - viewportSize) / 2.0);

    final clampedPanX = panX.clamp(-maxPanX, maxPanX);
    final clampedPanY = panY.clamp(-maxPanY, maxPanY);

    // Calculate crop rectangle in source image pixel coordinates
    final cropSizeSrc = viewportSize / effectiveScale;
    final maxCropSize = math.min(srcW, srcH);
    final effectiveCropSize = cropSizeSrc.clamp(1.0, maxCropSize);

    final cropXSrc = (srcW / 2.0) - (clampedPanX / effectiveScale) - (effectiveCropSize / 2.0);
    final cropYSrc = (srcH / 2.0) - (clampedPanY / effectiveScale) - (effectiveCropSize / 2.0);

    final finalX = cropXSrc.clamp(0.0, srcW - effectiveCropSize).round();
    final finalY = cropYSrc.clamp(0.0, srcH - effectiveCropSize).round();
    final maxAllowedSize = math.min(srcW.round(), srcH.round());
    final finalSize = effectiveCropSize.round().clamp(1, maxAllowedSize).toInt();

    final cropped = img.copyCrop(
      image,
      x: finalX,
      y: finalY,
      width: finalSize,
      height: finalSize,
    );

    final img.Image resized;
    if (targetDimension > 0 && (cropped.width != targetDimension || cropped.height != targetDimension)) {
      resized = img.copyResize(
        cropped,
        width: targetDimension,
        height: targetDimension,
        interpolation: img.Interpolation.linear,
      );
    } else {
      resized = cropped;
    }

    final encoded = img.encodeJpg(resized, quality: quality);

    final tempDir = _resolveTempDir();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final outFile = File('${tempDir.path}${Platform.pathSeparator}crop_$timestamp.jpg');
    outFile.writeAsBytesSync(encoded);

    return outFile;
  }
}
