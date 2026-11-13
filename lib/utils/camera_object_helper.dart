import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/card_storage_service.dart';
import '../widgets/styled_dialog_header.dart';
import 'app_permissions_helper.dart';

class CameraAnalysisResult {
  final bool hasObject;
  final bool isTooDarkOrBlank;
  final List<String> labels;
  final double topConfidence;
  final int objectCount;
  final bool analyzerAvailable;

  const CameraAnalysisResult({
    required this.hasObject,
    required this.isTooDarkOrBlank,
    required this.labels,
    required this.topConfidence,
    required this.objectCount,
    required this.analyzerAvailable,
  });

  static const CameraAnalysisResult unavailable = CameraAnalysisResult(
    hasObject: true,
    isTooDarkOrBlank: false,
    labels: <String>[],
    topConfidence: 0.0,
    objectCount: 0,
    analyzerAvailable: false,
  );

  factory CameraAnalysisResult.fromMap(Map<dynamic, dynamic> raw) {
    final labelsRaw = raw['labels'];
    final labels = <String>[];
    if (labelsRaw is List) {
      for (final item in labelsRaw) {
        final s = item?.toString().trim() ?? '';
        if (s.isNotEmpty) labels.add(s);
      }
    }
    return CameraAnalysisResult(
      hasObject: raw['hasObject'] == true,
      isTooDarkOrBlank: raw['isTooDarkOrBlank'] == true,
      labels: List.unmodifiable(labels),
      topConfidence: (raw['topConfidence'] as num?)?.toDouble() ?? 0.0,
      objectCount: (raw['objectCount'] as num?)?.toInt() ?? 0,
      analyzerAvailable: true,
    );
  }
}

class CameraCaptureOutcome {
  final String imagePath;
  final CameraAnalysisResult analysis;

  const CameraCaptureOutcome({
    required this.imagePath,
    required this.analysis,
  });
}

enum _NoObjectAction { retake, useAnyway }

/// Runs bundled offline Google ML Kit object detection & image labeling on camera captures.
class CameraObjectHelper {
  static const MethodChannel _visionChannel = MethodChannel('aac_vision');
  static final ImagePicker _defaultPicker = ImagePicker();

  @visibleForTesting
  static Future<XFile?> Function({int imageQuality})? cameraPickerOverride;

  @visibleForTesting
  static Future<CameraAnalysisResult> Function(String path)? analyzerOverride;

  @visibleForTesting
  static Future<String> Function(String sourcePath, {required String cardId})?
      persistMediaOverride;

  @visibleForTesting
  static void resetTestHooks() {
    cameraPickerOverride = null;
    analyzerOverride = null;
    persistMediaOverride = null;
  }

  /// Analyzes [imagePath] completely offline using Android's bundled ML Kit models.
  static Future<CameraAnalysisResult> analyzeImage(String imagePath) async {
    final custom = analyzerOverride;
    if (custom != null) {
      return custom(imagePath);
    }
    if (!Platform.isAndroid) {
      return CameraAnalysisResult.unavailable;
    }
    try {
      final raw = await _visionChannel.invokeMapMethod<dynamic, dynamic>(
        'analyzeImage',
        {'path': imagePath},
      );
      if (raw == null) return CameraAnalysisResult.unavailable;
      return CameraAnalysisResult.fromMap(raw);
    } on MissingPluginException {
      return CameraAnalysisResult.unavailable;
    } catch (e) {
      debugPrint('[CameraObjectHelper] Offline analysis failed: $e');
      return CameraAnalysisResult.unavailable;
    }
  }

  /// Captures a camera photo, verifies offline whether a clear object is present,
  /// lets the user Retake or Use Anyway if "No object detected", and persists accepted photos.
  static Future<CameraCaptureOutcome?> captureAndVerify(
    BuildContext context, {
    required String cardId,
    int imageQuality = 85,
  }) async {
    final allowed = await AppPermissionsHelper.ensureCameraPermission(context);
    if (!allowed || !context.mounted) return null;

    while (context.mounted) {
      final XFile? picked;
      try {
        picked = await _pickCameraPhoto(imageQuality: imageQuality);
      } catch (e) {
        debugPrint('[CameraObjectHelper] Camera pick failed: $e');
        if (context.mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              title: StyledDialogHeader(
                icon: Icons.camera_alt_rounded,
                title: 'Camera Launch Failed',
                subtitle: 'Unable to open device camera',
                accentColor: Theme.of(ctx).colorScheme.error,
              ),
              content: const Text(
                'Could not launch the camera app. Please ensure camera permissions are allowed in App Settings.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text('Open Settings'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    AppPermissionsHelper.openSettings();
                  },
                ),
              ],
            ),
          );
        }
        return null;
      }
      if (picked == null || !context.mounted) return null;

      final analysis = await analyzeImage(picked.path);
      if (!context.mounted) {
        _deleteTempFileSilently(picked.path);
        return null;
      }

      if (analysis.analyzerAvailable && !analysis.hasObject) {
        final choice = await _showNoObjectDialog(
          context,
          imagePath: picked.path,
          analysis: analysis,
        );
        if (choice == _NoObjectAction.retake) {
          _deleteTempFileSilently(picked.path);
          continue;
        }
        if (choice == null) {
          _deleteTempFileSilently(picked.path);
          return null;
        }
      }

      final permanentPath = await _persistPhoto(picked.path, cardId: cardId);
      return CameraCaptureOutcome(imagePath: permanentPath, analysis: analysis);
    }
    return null;
  }

  static Future<XFile?> _pickCameraPhoto({required int imageQuality}) {
    final override = cameraPickerOverride;
    if (override != null) {
      return override(imageQuality: imageQuality);
    }
    return _defaultPicker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
    );
  }

  static Future<String> _persistPhoto(
    String sourcePath, {
    required String cardId,
  }) {
    final override = persistMediaOverride;
    if (override != null) {
      return override(sourcePath, cardId: cardId);
    }
    return CardStorageService.persistMediaFile(
      sourcePath,
      cardId: cardId,
      mediaType: 'images',
    );
  }

  static void _deleteTempFileSilently(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }

  static Future<_NoObjectAction?> _showNoObjectDialog(
    BuildContext context, {
    required String imagePath,
    required CameraAnalysisResult analysis,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = analysis.isTooDarkOrBlank
        ? 'Photo appears blank or too dark'
        : 'No clear subject found in photo';
    final detail = analysis.isTooDarkOrBlank
        ? 'The photo looks nearly blank or covered. Point the camera clearly at an object in good lighting.'
        : 'No recognizable object was detected offline. Move closer in better lighting, or keep this photo anyway.';

    return showDialog<_NoObjectAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: StyledDialogHeader(
          icon: Icons.center_focus_weak_rounded,
          title: 'No Object Detected',
          subtitle: subtitle,
          accentColor: colorScheme.error,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 150,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildPreviewThumb(imagePath, colorScheme),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: Color(0xFFFFD54F),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'No object detected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _NoObjectAction.useAnyway),
            child: const Text('Use Anyway'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, _NoObjectAction.retake),
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: const Text('Retake'),
          ),
        ],
      ),
    );
  }

  static Widget _buildPreviewThumb(String imagePath, ColorScheme colorScheme) {
    final file = File(imagePath);
    if (!file.existsSync()) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.center_focus_weak_rounded,
          size: 42,
          color: colorScheme.outline,
        ),
      );
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      cacheWidth: 480,
      errorBuilder: (_, __, ___) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: colorScheme.outline,
        ),
      ),
    );
  }
}
