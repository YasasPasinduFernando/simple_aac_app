import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/card_storage_service.dart';
import '../widgets/styled_dialog_header.dart';
import 'app_permissions_helper.dart';

enum AnimatedMediaSource { recordVideo, galleryVideo, existingGif }

class GifConversionResult {
  final String outputPath;
  final int durationMs;
  final int frameCount;
  final int sizeBytes;

  const GifConversionResult({
    required this.outputPath,
    required this.durationMs,
    required this.frameCount,
    required this.sizeBytes,
  });

  factory GifConversionResult.fromMap(Map<dynamic, dynamic> raw) {
    return GifConversionResult(
      outputPath: raw['outputPath']?.toString() ?? '',
      durationMs: (raw['durationMs'] as num?)?.toInt() ?? 0,
      frameCount: (raw['frameCount'] as num?)?.toInt() ?? 0,
      sizeBytes: (raw['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Shared offline helper to attach existing GIFs or <=30s video clips converted
/// into compact fair-quality animated GIFs for AAC cards and ZIP backups.
class AnimatedMediaHelper {
  static const MethodChannel _visionChannel = MethodChannel('aac_vision');
  static const Duration maxVideoDuration = Duration(seconds: 30);
  static const int maxGifFileBytes = 15 * 1024 * 1024;
  static final ImagePicker _defaultPicker = ImagePicker();

  @visibleForTesting
  static Future<XFile?> Function(ImageSource source, {Duration? maxDuration})?
      videoPickerOverride;

  @visibleForTesting
  static Future<String?> Function()? gifFilePickerOverride;

  @visibleForTesting
  static Future<GifConversionResult> Function({
    required String inputPath,
    required String outputPath,
  })? converterOverride;

  @visibleForTesting
  static Future<String> Function(String sourcePath, {required String cardId})?
      persistMediaOverride;

  @visibleForTesting
  static void resetTestHooks() {
    videoPickerOverride = null;
    gifFilePickerOverride = null;
    converterOverride = null;
    persistMediaOverride = null;
  }

  /// Checks whether bytes start with the standard GIF87a or GIF89a header.
  static bool isValidGifHeader(List<int> bytes) {
    if (bytes.length < 14) return false;
    final sig = String.fromCharCodes(bytes.sublist(0, 6));
    return sig == 'GIF89a' || sig == 'GIF87a';
  }

  static bool isValidGifFileSync(File file) {
    if (!file.existsSync()) return false;
    final len = file.lengthSync();
    if (len < 14 || len > maxGifFileBytes) return false;
    final raf = file.openSync();
    try {
      final header = raf.readSync(6);
      if (header.length < 6) return false;
      final sig = String.fromCharCodes(header);
      return sig == 'GIF89a' || sig == 'GIF87a';
    } finally {
      raf.closeSync();
    }
  }

  /// Lets the user choose Record Video (<=30s), Gallery Video (<=30s), or Existing GIF,
  /// converts videos offline into compact GIFs, validates integrity, and returns saved card media path.
  static Future<String?> pickOrCreateAnimatedGif(
    BuildContext context, {
    required String cardId,
  }) async {
    final source = await showDialog<AnimatedMediaSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: StyledDialogHeader(
          icon: Icons.gif_box_rounded,
          title: 'Add GIF or Short Video',
          subtitle: 'Max 30s video converts offline into a card GIF',
          accentColor: Theme.of(ctx).colorScheme.secondary,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogOptionTile(
                icon: Icons.videocam_rounded,
                title: 'Record Video (Max 30s)',
                subtitle: 'Shoot a quick clip and auto-convert to GIF',
                onTap: () => Navigator.pop(ctx, AnimatedMediaSource.recordVideo),
              ),
              DialogOptionTile(
                icon: Icons.video_library_rounded,
                title: 'Choose Video (Max 30s)',
                subtitle: 'Convert a short phone video to card GIF',
                onTap: () => Navigator.pop(ctx, AnimatedMediaSource.galleryVideo),
              ),
              DialogOptionTile(
                icon: Icons.gif_rounded,
                title: 'Choose Existing GIF',
                subtitle: 'Select a .gif file from your device',
                onTap: () => Navigator.pop(ctx, AnimatedMediaSource.existingGif),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source == null || !context.mounted) return null;

    if (source == AnimatedMediaSource.existingGif) {
      return _pickExistingGif(context, cardId: cardId);
    }

    final cameraSource = source == AnimatedMediaSource.recordVideo
        ? ImageSource.camera
        : ImageSource.gallery;
    return _pickAndConvertVideo(
      context,
      source: cameraSource,
      cardId: cardId,
    );
  }

  static Future<String?> _pickExistingGif(
    BuildContext context, {
    required String cardId,
  }) async {
    final allowed = await AppPermissionsHelper.ensureLegacyStorageIfNeeded(context);
    if (!allowed || !context.mounted) return null;

    Directory? tempDir;
    try {
      String? pickedPath = gifFilePickerOverride != null
          ? await gifFilePickerOverride!()
          : null;

      if (gifFilePickerOverride == null) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['gif'],
          withData: true,
        );
        if (result == null || result.files.isEmpty) return null;
        final pickedFile = result.files.first;
        pickedPath = pickedFile.path;
        if ((pickedPath == null || !File(pickedPath).existsSync()) &&
            pickedFile.bytes != null) {
          tempDir = Directory.systemTemp.createTempSync('aac_gif_pick_');
          final tmp = File('${tempDir.path}/picked.gif');
          tmp.writeAsBytesSync(pickedFile.bytes!, flush: true);
          pickedPath = tmp.path;
        }
      }

      if (pickedPath == null || !context.mounted) return null;
      final file = File(pickedPath);
      if (!file.existsSync()) {
        _showSnack(context, 'Selected GIF file could not be read.');
        return null;
      }

      final len = file.lengthSync();
      if (len > maxGifFileBytes) {
        if (context.mounted) {
          _showSnack(
            context,
            'GIF is too large (max 15 MB) for smooth card playback & backup.',
          );
        }
        return null;
      }

      if (!isValidGifFileSync(file)) {
        if (context.mounted) {
          _showSnack(context, 'Please select a valid animated .gif image file.');
        }
        return null;
      }

      final savedPath = await _persistGif(file.path, cardId: cardId);
      return savedPath;
    } catch (e) {
      debugPrint('[AnimatedMediaHelper] GIF pick failed: $e');
      if (context.mounted) {
        _showSnack(context, 'Could not load GIF file. Try another clip.');
      }
      return null;
    } finally {
      if (tempDir != null) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
  }

  static Future<String?> _pickAndConvertVideo(
    BuildContext context, {
    required ImageSource source,
    required String cardId,
  }) async {
    final allowed = source == ImageSource.camera
        ? await AppPermissionsHelper.ensureCameraPermission(context)
        : await AppPermissionsHelper.ensureLegacyStorageIfNeeded(context);
    if (!allowed || !context.mounted) return null;

    Directory? workDir;
    NavigatorState? rootNavigator;
    var progressOpen = false;

    try {
      final picked = videoPickerOverride != null
          ? await videoPickerOverride!(source, maxDuration: maxVideoDuration)
          : await _defaultPicker.pickVideo(
              source: source,
              maxDuration: maxVideoDuration,
            );
      if (picked == null || !context.mounted) return null;

      workDir = Directory.systemTemp.createTempSync('aac_video_gif_');
      final outGifPath = '${workDir.path}/clip.gif';

      rootNavigator = Navigator.of(context, rootNavigator: true);
      progressOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          content: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Creating offline GIF clip...\n(Max 30s • compact quality)',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      final result = await _convertVideoToGif(
        inputPath: picked.path,
        outputPath: outGifPath,
      );

      if (progressOpen && rootNavigator.mounted) {
        rootNavigator.pop();
        progressOpen = false;
      }

      final outFile = File(result.outputPath);
      if (!isValidGifFileSync(outFile)) {
        if (context.mounted) {
          _showSnack(context, 'Converted GIF is invalid or exceeds 15 MB.');
        }
        return null;
      }

      final savedPath = await _persistGif(outFile.path, cardId: cardId);
      return savedPath;
    } on PlatformException catch (e) {
      if (progressOpen && rootNavigator != null && rootNavigator.mounted) {
        rootNavigator.pop();
        progressOpen = false;
      }
      if (!context.mounted) return null;
      if (e.code == 'VIDEO_TOO_LONG') {
        _showSnack(
          context,
          e.message ?? 'Video is longer than 30 seconds. Please pick a <=30s clip.',
        );
      } else {
        _showSnack(
          context,
          e.message ?? 'Could not convert video to GIF on this device.',
        );
      }
      return null;
    } catch (e) {
      if (progressOpen && rootNavigator != null && rootNavigator.mounted) {
        rootNavigator.pop();
        progressOpen = false;
      }
      debugPrint('[AnimatedMediaHelper] Video to GIF failed: $e');
      if (context.mounted) {
        _showSnack(context, 'Could not convert video to GIF. Try a shorter clip.');
      }
      return null;
    } finally {
      if (workDir != null) {
        try {
          workDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
  }

  static Future<GifConversionResult> _convertVideoToGif({
    required String inputPath,
    required String outputPath,
  }) async {
    final custom = converterOverride;
    if (custom != null) {
      return custom(inputPath: inputPath, outputPath: outputPath);
    }
    if (!Platform.isAndroid) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'Video-to-GIF conversion runs offline on Android devices.',
      );
    }
    final raw = await _visionChannel.invokeMapMethod<dynamic, dynamic>(
      'convertVideoToGif',
      {
        'inputPath': inputPath,
        'outputPath': outputPath,
      },
    );
    if (raw == null) {
      throw PlatformException(
        code: 'GIF_ENCODE_FAILED',
        message: 'GIF converter returned empty result.',
      );
    }
    return GifConversionResult.fromMap(raw);
  }

  static Future<String> _persistGif(
    String sourcePath, {
    required String cardId,
  }) {
    final custom = persistMediaOverride;
    if (custom != null) {
      return custom(sourcePath, cardId: cardId);
    }
    return CardStorageService.persistMediaFile(
      sourcePath,
      cardId: cardId,
      mediaType: 'images',
    );
  }

  static void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
