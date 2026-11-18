import 'dart:io';

import 'package:flutter/widgets.dart';

import 'theme_accessibility.dart';

bool isAssetImagePath(String? path) {
  return path != null && path.startsWith('assets/');
}

bool isGifImagePath(String? path) {
  if (path == null) return false;
  final lower = path.split('?').first.toLowerCase();
  return lower.endsWith('.gif');
}

/// Computes an adaptive decoding cache width based on the rendered card's logical width
/// and the device pixel ratio (DPR).
///
/// Prevents allocating oversized 1200px (4.3MB) bitmaps for small grid thumbnails,
/// reducing heap consumption by 85-95% while keeping cards crisp and unblurred.
int computeAdaptiveCacheWidth({
  required double targetLogicalWidth,
  required double devicePixelRatio,
  int minDimension = 120,
  int maxDimension = 1024,
}) {
  final target = (targetLogicalWidth * devicePixelRatio).round();
  return target.clamp(minDimension, maxDimension);
}

Widget buildCardImage(
  String imagePath, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  int? cacheWidth,
  double? targetLogicalWidth,
  double? devicePixelRatio,
  ImageErrorWidgetBuilder? errorBuilder,
  ColorFilter? colorFilter,
  bool autoApplyColorBlindFilter = true,
  FilterQuality filterQuality = FilterQuality.medium,
}) {
  // ResizeImage flattens animated GIFs to frame 0, so preserve native multi-frame codec for .gif files.
  final int? effectiveCacheWidth;
  if (isGifImagePath(imagePath)) {
    effectiveCacheWidth = null;
  } else if (cacheWidth != null) {
    effectiveCacheWidth = cacheWidth;
  } else if (targetLogicalWidth != null && targetLogicalWidth > 0) {
    final dpr = (devicePixelRatio != null && devicePixelRatio > 0) ? devicePixelRatio : 2.0;
    effectiveCacheWidth = computeAdaptiveCacheWidth(
      targetLogicalWidth: targetLogicalWidth,
      devicePixelRatio: dpr,
      maxDimension: isAssetImagePath(imagePath) ? 1024 : 1200,
    );
  } else {
    // Sensible bounded fallback when no target size is provided
    effectiveCacheWidth = isAssetImagePath(imagePath) ? 512 : 640;
  }

  Widget smoothFrameBuilder(BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
    if (wasSynchronouslyLoaded || frame != null) {
      return child;
    }
    return AnimatedOpacity(
      opacity: frame == null ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: child,
    );
  }

  final Widget image = isAssetImagePath(imagePath)
      ? Image.asset(
          imagePath,
          fit: fit,
          width: width,
          height: height,
          cacheWidth: effectiveCacheWidth,
          filterQuality: filterQuality,
          gaplessPlayback: true,
          frameBuilder: smoothFrameBuilder,
          errorBuilder: errorBuilder,
        )
      : Image.file(
          File(imagePath),
          fit: fit,
          width: width,
          height: height,
          cacheWidth: effectiveCacheWidth,
          filterQuality: filterQuality,
          gaplessPlayback: true,
          frameBuilder: smoothFrameBuilder,
          errorBuilder: errorBuilder,
        );

  final effectiveFilter = colorFilter ??
      (autoApplyColorBlindFilter ? ThemeAccessibility.resolveCardImageFilter() : null);

  if (effectiveFilter != null) {
    return ColorFiltered(
      colorFilter: effectiveFilter,
      child: image,
    );
  }

  return image;
}
