import 'dart:io';

import 'package:flutter/widgets.dart';

bool isAssetImagePath(String? path) {
  return path != null && path.startsWith('assets/');
}

Widget buildCardImage(
  String imagePath, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  if (isAssetImagePath(imagePath)) {
    return Image.asset(
      imagePath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }

  return Image.file(
    File(imagePath),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}
