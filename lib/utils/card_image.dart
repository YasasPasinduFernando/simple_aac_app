import 'dart:io';

import 'package:flutter/widgets.dart';

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
}) {
  // ResizeImage flattens animated GIFs to frame 0, so preserve native codec for .gif files.
  final effectiveCacheWidth = isGifImagePath(imagePath) ? null : cacheWidth;

  if (isAssetImagePath(imagePath)) {
    return Image.asset(
      imagePath,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: effectiveCacheWidth,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: errorBuilder,
    );
  }

  return Image.file(
    File(imagePath),
    fit: fit,
    width: width,
    height: height,
    cacheWidth: effectiveCacheWidth,
    filterQuality: FilterQuality.medium,
    gaplessPlayback: true,
    errorBuilder: errorBuilder,
  );
}
