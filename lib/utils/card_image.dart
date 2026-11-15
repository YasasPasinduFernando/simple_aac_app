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

Widget buildCardImage(
  String imagePath, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  int? cacheWidth = 480,
  ImageErrorWidgetBuilder? errorBuilder,
  ColorFilter? colorFilter,
  bool autoApplyColorBlindFilter = true,
}) {
  // ResizeImage flattens animated GIFs to frame 0, so preserve native codec for .gif files.
  final effectiveCacheWidth = isGifImagePath(imagePath) ? null : cacheWidth;

  final Widget image = isAssetImagePath(imagePath)
      ? Image.asset(
          imagePath,
          fit: fit,
          width: width,
          height: height,
          cacheWidth: effectiveCacheWidth,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: errorBuilder,
        )
      : Image.file(
          File(imagePath),
          fit: fit,
          width: width,
          height: height,
          cacheWidth: effectiveCacheWidth,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
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
