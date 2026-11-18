import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class ImageDimensions {
  final double width;
  final double height;
  const ImageDimensions({required this.width, required this.height});
}

class NormalizedCropParams {
  final Uint8List bytes;
  final double normLeft;
  final double normTop;
  final double normWidth;
  final double normHeight;
  final int targetDimension;
  final int quality;
  final String outputPath;
  final bool isSquare;
  final String sourcePath;

  const NormalizedCropParams({
    required this.bytes,
    required this.normLeft,
    required this.normTop,
    required this.normWidth,
    required this.normHeight,
    required this.targetDimension,
    required this.quality,
    required this.outputPath,
    required this.isSquare,
    required this.sourcePath,
  });
}

class _CropParams {
  final Uint8List bytes;
  final double zoom;
  final double panX;
  final double panY;
  final double viewportSize;
  final int targetDimension;
  final int quality;
  final String outputPath;

  const _CropParams({
    required this.bytes,
    required this.zoom,
    required this.panX,
    required this.panY,
    required this.viewportSize,
    required this.targetDimension,
    required this.quality,
    required this.outputPath,
  });
}

class ImageCropHelper {
  @visibleForTesting
  static Directory Function()? tempDirectoryOverride;

  static Directory _resolveTempDir() {
    if (tempDirectoryOverride != null) {
      return tempDirectoryOverride!();
    }
    return Directory.systemTemp;
  }

  static Future<String> _cropWorker(_CropParams params) async {
    final rawImage = img.decodeImage(params.bytes);
    if (rawImage == null) {
      throw const FormatException('Unable to decode source image');
    }

    // Bake EXIF orientation so rotated mobile camera photos orient right-side up
    final image = img.bakeOrientation(rawImage);
    final srcW = image.width.toDouble();
    final srcH = image.height.toDouble();

    // Base scale required to completely cover the 1:1 viewport
    final baseScale = math.max(params.viewportSize / srcW, params.viewportSize / srcH);
    final effectiveScale = baseScale * math.max(1.0, params.zoom);

    final dispW = srcW * effectiveScale;
    final dispH = srcH * effectiveScale;

    final maxPanX = math.max(0.0, (dispW - params.viewportSize) / 2.0);
    final maxPanY = math.max(0.0, (dispH - params.viewportSize) / 2.0);

    final clampedPanX = params.panX.clamp(-maxPanX, maxPanX);
    final clampedPanY = params.panY.clamp(-maxPanY, maxPanY);

    // Calculate crop rectangle in source image pixel coordinates
    final cropSizeSrc = params.viewportSize / effectiveScale;
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
    if (params.targetDimension > 0 &&
        (cropped.width != params.targetDimension ||
            cropped.height != params.targetDimension)) {
      resized = img.copyResize(
        cropped,
        width: params.targetDimension,
        height: params.targetDimension,
        interpolation: img.Interpolation.linear,
      );
    } else {
      resized = cropped;
    }

    final encoded = img.encodeJpg(resized, quality: params.quality);
    final outFile = File(params.outputPath);
    outFile.writeAsBytesSync(encoded);

    return outFile.path;
  }

  /// Crops an image to a 1:1 square according to viewport pan & zoom parameters.
  /// Handles EXIF orientation baking, maintains aspect ratio, prevents out-of-bound
  /// borders, offloads decoding/encoding to a background isolate via compute(),
  /// and saves a storage-optimized square JPEG in temp directory.
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
    final file = File(sourcePath);
    if (file.existsSync()) {
      bytes = file.readAsBytesSync();
    } else if (sourcePath.startsWith('assets/')) {
      final data = await rootBundle.load(sourcePath);
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } else {
      throw FileSystemException('Source image file not found', sourcePath);
    }

    final tempDir = _resolveTempDir();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final outPath = '${tempDir.path}${Platform.pathSeparator}crop_$timestamp.jpg';

    final params = _CropParams(
      bytes: bytes,
      zoom: zoom,
      panX: panX,
      panY: panY,
      viewportSize: viewportSize,
      targetDimension: targetDimension,
      quality: quality,
      outputPath: outPath,
    );

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      await _cropWorker(params);
    } else {
      try {
        await compute(_cropWorker, params);
      } catch (_) {
        await _cropWorker(params);
      }
    }

    return File(outPath);
  }

  static Future<String> _cropNormalizedWorker(NormalizedCropParams params) async {
    final rawImage = img.decodeImage(params.bytes);
    if (rawImage == null) {
      throw const FormatException('Unable to decode source image');
    }

    // Bake EXIF orientation so rotated mobile camera photos orient right-side up
    final image = img.bakeOrientation(rawImage);
    final srcW = image.width.toDouble();
    final srcH = image.height.toDouble();

    // Clamp normalized coordinates
    final nL = params.normLeft.clamp(0.0, 1.0);
    final nT = params.normTop.clamp(0.0, 1.0);
    final nW = params.normWidth.clamp(0.001, 1.0 - nL);
    final nH = params.normHeight.clamp(0.001, 1.0 - nT);

    // Map to pixel coordinates
    final cropX = (nL * srcW).round().clamp(0, srcW.toInt() - 1);
    final cropY = (nT * srcH).round().clamp(0, srcH.toInt() - 1);
    final cropW = (nW * srcW).round().clamp(1, srcW.toInt() - cropX);
    final cropH = (nH * srcH).round().clamp(1, srcH.toInt() - cropY);

    final cropped = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    final img.Image resized;
    if (params.isSquare) {
      if (params.targetDimension > 0 &&
          (cropped.width != params.targetDimension ||
              cropped.height != params.targetDimension)) {
        resized = img.copyResize(
          cropped,
          width: params.targetDimension,
          height: params.targetDimension,
          interpolation: img.Interpolation.linear,
        );
      } else {
        resized = cropped;
      }
    } else {
      if (params.targetDimension > 0 &&
          (cropped.width > params.targetDimension ||
              cropped.height > params.targetDimension)) {
        final double scale = params.targetDimension / math.max(cropped.width, cropped.height);
        final newW = (cropped.width * scale).round().clamp(1, 4096);
        final newH = (cropped.height * scale).round().clamp(1, 4096);
        resized = img.copyResize(
          cropped,
          width: newW,
          height: newH,
          interpolation: img.Interpolation.linear,
        );
      } else {
        resized = cropped;
      }
    }

    // Handle transparent PNGs by compositing onto a crisp white background
    img.Image finalImage = resized;
    if (params.sourcePath.toLowerCase().endsWith('.png') && finalImage.hasAlpha) {
      final solidBg = img.Image(
        width: finalImage.width,
        height: finalImage.height,
        numChannels: 3,
      );
      img.fill(solidBg, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(solidBg, finalImage);
      finalImage = solidBg;
    }

    final encoded = img.encodeJpg(finalImage, quality: params.quality);
    final outFile = File(params.outputPath);
    outFile.writeAsBytesSync(encoded);

    return outFile.path;
  }

  /// Crops an image to user-defined normalized coordinates (0.0 to 1.0)
  /// supporting 1:1 Card square crop and Free Crop with arbitrary aspect ratios.
  static Future<File> cropNormalized({
    required String sourcePath,
    required double normLeft,
    required double normTop,
    required double normWidth,
    required double normHeight,
    required bool isSquare,
    int targetDimension = 640,
    int quality = 85,
  }) async {
    final Uint8List bytes;
    final file = File(sourcePath);
    if (file.existsSync()) {
      bytes = file.readAsBytesSync();
    } else if (sourcePath.startsWith('assets/')) {
      final data = await rootBundle.load(sourcePath);
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } else {
      throw FileSystemException('Source image file not found', sourcePath);
    }

    final tempDir = _resolveTempDir();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final outPath = '${tempDir.path}${Platform.pathSeparator}crop_$timestamp.jpg';

    final params = NormalizedCropParams(
      bytes: bytes,
      normLeft: normLeft,
      normTop: normTop,
      normWidth: normWidth,
      normHeight: normHeight,
      targetDimension: targetDimension,
      quality: quality,
      outputPath: outPath,
      isSquare: isSquare,
      sourcePath: sourcePath,
    );

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      await _cropNormalizedWorker(params);
    } else {
      try {
        await compute(_cropNormalizedWorker, params);
      } catch (_) {
        await _cropNormalizedWorker(params);
      }
    }

    final outFile = File(outPath);
    if (!outFile.existsSync()) {
      throw FileSystemException('Cropped output file not generated', outPath);
    }
    return outFile;
  }

  /// Efficiently decodes image dimensions off the UI thread via compute.
  static Future<ImageDimensions> decodeDimensions(String sourcePath) async {
    final Uint8List bytes;
    final file = File(sourcePath);
    if (file.existsSync()) {
      bytes = file.readAsBytesSync();
    } else if (sourcePath.startsWith('assets/')) {
      final data = await rootBundle.load(sourcePath);
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } else {
      throw FileSystemException('Source image file not found', sourcePath);
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return _decodeDimensionsWorker(bytes);
    }

    try {
      return await compute(_decodeDimensionsWorker, bytes);
    } catch (_) {
      return _decodeDimensionsWorker(bytes);
    }
  }

  static ImageDimensions _decodeDimensionsWorker(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Unable to decode source image');
    }
    final baked = img.bakeOrientation(decoded);
    return ImageDimensions(
      width: baked.width.toDouble(),
      height: baked.height.toDouble(),
    );
  }
}
