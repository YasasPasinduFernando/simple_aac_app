import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/aac_card_model.dart';
import 'card_storage_service.dart';

class BackupPayload {
  final List<AACCard> cards;
  final Map<String, dynamic> settings;

  const BackupPayload({
    required this.cards,
    required this.settings,
  });
}

class BackupService {
  static const MethodChannel _channel = MethodChannel('aac_backup');

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? path : parts.last;
  }

  static Future<void> _writeBackupToDirectory(
    List<AACCard> cards,
    Directory backupDir,
    Map<String, dynamic>? settings,
  ) async {
    final filesDir = Directory('${backupDir.path}/files');
    debugPrint(
      '[BackupService] writing backup to ${backupDir.path}: '
      '${cards.length} top-level cards, '
      '${CardStorageService.countCards(cards)} total cards',
    );

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    if (!await filesDir.exists()) {
      await filesDir.create(recursive: true);
    }

    final Map<String, String> pathMap = {};
    final Map<String, int> nameCounts = {};

    Future<String?> copyMedia(String? path) async {
      if (path == null) return null;
      if (_isAssetPath(path)) return path;
      final file = File(path);
      if (!await file.exists() || await file.length() <= 0) return null;
      if (pathMap.containsKey(path)) return pathMap[path];

      final base = _basename(path);
      final dot = base.lastIndexOf('.');
      final name = dot == -1 ? base : base.substring(0, dot);
      final ext = dot == -1 ? '' : base.substring(dot);
      final count = (nameCounts[base] ?? 0) + 1;
      nameCounts[base] = count;
      final fileName = count == 1 ? base : '${name}_$count$ext';
      final destPath = '${filesDir.path}/$fileName';

      await file.copy(destPath);
      final relPath = 'files/$fileName';
      pathMap[path] = relPath;
      debugPrint(
        '[BackupService] copied media into backup: source=$path, '
        'backupPath=$relPath',
      );
      return relPath;
    }

    Future<AACCard> cloneCard(AACCard card) async {
      final imagePath = await copyMedia(card.imagePath);
      final voicePath = await copyMedia(card.voicePath);
      final cloned = AACCard(
        id: card.id,
        label: card.label,
        labelSinhala: card.labelSinhala,
        labelTamil: card.labelTamil,
        imagePath: imagePath,
        voicePath: voicePath,
        category: card.category,
        colorValue: card.colorValue,
        type: card.type,
        subCards: [],
      );
      for (final sub in card.subCards) {
        cloned.subCards.add(await cloneCard(sub));
      }
      return cloned;
    }

    final List<AACCard> clonedCards = [];
    for (final card in cards) {
      clonedCards.add(await cloneCard(card));
    }

    final manifestFile = File('${backupDir.path}/cards.json');
    await manifestFile.writeAsString(
      jsonEncode(clonedCards.map((c) => c.toJson()).toList()),
    );

    if (settings != null && settings.isNotEmpty) {
      final settingsFile = File('${backupDir.path}/settings.json');
      await settingsFile.writeAsString(jsonEncode(settings));
    }
  }

  static Future<List<int>?> buildBackupZip(
    List<AACCard> cards, {
    Map<String, dynamic>? settings,
  }) async {
    final tempDir = await Directory.systemTemp.createTemp('aac_backup_');
    final backupRoot = Directory('${tempDir.path}/AAC_Backup');
    try {
      debugPrint('[BackupService] building backup zip in ${backupRoot.path}');
      await _writeBackupToDirectory(cards, backupRoot, settings);
      return await compute(_encodeZipDirectoryWorker, backupRoot.path);
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  static Future<String> saveZipToAppDocs(List<int> zipBytes) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = '${docsDir.path}/aac_backup.zip';
    await File(path).writeAsBytes(zipBytes, flush: true);
    debugPrint('[BackupService] saved backup zip to app documents: $path');
    return path;
  }

  static Future<int> getSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    try {
      final sdk = await _channel.invokeMethod<int>('getSdkVersion');
      return sdk ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<String?> saveZipToDownloads(List<int> zipBytes) async {
    try {
      return await _channel.invokeMethod<String>(
        'saveToDownloads',
        {
          'fileName': 'aac_backup.zip',
          'bytes': Uint8List.fromList(zipBytes),
        },
      );
    } on PlatformException {
      return null;
    }
  }

  static Future<List<AACCard>> restoreFromBackupDir(
    Directory backupDir,
  ) async {
    final manifestFile = File('${backupDir.path}/cards.json');
    if (!await manifestFile.exists()) {
      debugPrint('[BackupService] cards.json not found in ${backupDir.path}');
      return const <AACCard>[];
    }

    final raw = await manifestFile.readAsString();
    if (raw.trim().isEmpty) {
      debugPrint('[BackupService] cards.json is empty in ${backupDir.path}');
      return const <AACCard>[];
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      debugPrint('[BackupService] failed to parse cards.json: $e');
      return const <AACCard>[];
    }

    final List<dynamic> cardList;
    if (decoded is List) {
      cardList = decoded;
    } else if (decoded is Map && decoded['cards'] is List) {
      cardList = decoded['cards'] as List<dynamic>;
    } else {
      debugPrint(
        '[BackupService] unexpected cards.json structure: ${decoded.runtimeType}',
      );
      return const <AACCard>[];
    }

    final restored = <AACCard>[];
    for (final item in cardList) {
      if (item is Map<String, dynamic>) {
        try {
          restored.add(AACCard.fromJson(item));
        } catch (e) {
          debugPrint('[BackupService] skipping invalid card entry: $e');
        }
      } else if (item is Map) {
        try {
          restored.add(AACCard.fromJson(Map<String, dynamic>.from(item)));
        } catch (e) {
          debugPrint('[BackupService] skipping invalid card entry: $e');
        }
      }
    }

    debugPrint(
      '[BackupService] restoring backup from ${backupDir.path}: '
      '${restored.length} top-level cards, '
      '${CardStorageService.countCards(restored)} total cards',
    );

    final backupRoot = backupDir.absolute.path.replaceAll('\\', '/');

    Future<String?> restoreMedia(String? relPath, String mediaType) async {
      if (relPath == null || relPath.isEmpty) return null;
      if (_isAssetPath(relPath)) return relPath;

      final normalizedRel = relPath.replaceAll('\\', '/');
      String? relativeLookup;
      if (normalizedRel.startsWith('/')) {
        // Absolute path from another device or prior installation.
        // Check if the file is present in the archive's files/ folder or root folder by its basename.
        final base = _basename(normalizedRel);
        if (await File('${backupDir.path}/files/$base').exists()) {
          relativeLookup = 'files/$base';
        } else if (await File('${backupDir.path}/$base').exists()) {
          relativeLookup = base;
        } else {
          debugPrint(
            '[BackupService] absolute path not found in backup archive: $relPath',
          );
          return null;
        }
      } else {
        relativeLookup = normalizedRel;
      }

      if (relativeLookup.startsWith('/') ||
          relativeLookup.split('/').any((seg) => seg == '..')) {
        debugPrint(
          '[BackupService] blocked path traversal in media path: $relativeLookup',
        );
        return null;
      }

      var sourceFile = File('${backupDir.path}/$relativeLookup');
      if (!await sourceFile.exists()) {
        final base = _basename(relativeLookup);
        final inFiles = File('${backupDir.path}/files/$base');
        if (await inFiles.exists()) {
          sourceFile = inFiles;
        }
      }

      final resolvedSource = sourceFile.absolute.path.replaceAll('\\', '/');
      if (resolvedSource != backupRoot &&
          !resolvedSource.startsWith('$backupRoot/')) {
        debugPrint(
          '[BackupService] blocked out-of-bounds media path: $resolvedSource',
        );
        return null;
      }

      if (!await sourceFile.exists() || await sourceFile.length() <= 0) {
        return null;
      }

      final base = _basename(sourceFile.path);
      final mediaDir = await CardStorageService.mediaDirectory(mediaType);
      final destPath = '${mediaDir.path}/$base';
      var targetPath = destPath;
      var counter = 1;
      while (await File(targetPath).exists()) {
        final existingFile = File(targetPath);
        if (await existingFile.length() == await sourceFile.length()) {
          targetPath = existingFile.path;
          break;
        }
        final dot = base.lastIndexOf('.');
        final name = dot == -1 ? base : base.substring(0, dot);
        final ext = dot == -1 ? '' : base.substring(dot);
        targetPath = '${mediaDir.path}/${name}_$counter$ext';
        counter++;
      }
      if (!await File(targetPath).exists()) {
        await sourceFile.copy(targetPath);
      }
      debugPrint(
        '[BackupService] restored $mediaType file: source=${sourceFile.path}, '
        'target=$targetPath',
      );
      return targetPath;
    }

    Future<void> fixCard(AACCard card) async {
      card.imagePath = await restoreMedia(card.imagePath, 'images');
      card.voicePath = await restoreMedia(card.voicePath, 'voices');
      for (final sub in card.subCards) {
        await fixCard(sub);
      }
    }

    for (final card in restored) {
      await fixCard(card);
    }

    return restored;
  }

  static Future<Map<String, dynamic>> _readSettings(
    Directory backupDir,
  ) async {
    final file = File('${backupDir.path}/settings.json');
    if (!await file.exists()) return {};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
    } catch (_) {}
    return {};
  }

  static Future<void> _extractZipBytesToDirectory(
    List<int> bytes,
    Directory target,
  ) =>
      compute(
        _extractZipBytesWorker,
        _ExtractZipArgs(bytes: bytes, targetPath: target.path),
      );

  static Future<BackupPayload> restoreFromZipBytes(List<int> bytes) async {
    if (bytes.isEmpty) return const BackupPayload(cards: [], settings: {});
    final tempDir = await Directory.systemTemp.createTemp('aac_restore_');
    try {
      try {
        await _extractZipBytesToDirectory(bytes, tempDir);
      } catch (e) {
        debugPrint('[BackupService] failed to unpack zip bytes: $e');
        return const BackupPayload(cards: [], settings: {});
      }
      final directManifest = File('${tempDir.path}/cards.json');
      final nestedManifest = File('${tempDir.path}/AAC_Backup/cards.json');
      if (await directManifest.exists()) {
        final restored = await restoreFromBackupDir(tempDir);
        final settings = await _readSettings(tempDir);
        return BackupPayload(cards: restored, settings: settings);
      }
      if (await nestedManifest.exists()) {
        final dir = Directory('${tempDir.path}/AAC_Backup');
        final restored = await restoreFromBackupDir(dir);
        final settings = await _readSettings(dir);
        return BackupPayload(cards: restored, settings: settings);
      }
      return const BackupPayload(cards: [], settings: {});
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  static bool _isAssetPath(String path) {
    return path.startsWith('assets/');
  }
}

class _ExtractZipArgs {
  final List<int> bytes;
  final String targetPath;

  const _ExtractZipArgs({required this.bytes, required this.targetPath});
}

List<int> _encodeZipDirectoryWorker(String dirPath) {
  final dir = Directory(dirPath);
  final archive = Archive();
  final rootPath = dir.path.replaceAll('\\', '/');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File) {
      final filePath = entity.path.replaceAll('\\', '/');
      final relPath = filePath.startsWith(rootPath)
          ? filePath.substring(rootPath.length + 1)
          : filePath;
      final data = entity.readAsBytesSync();
      archive.addFile(ArchiveFile(relPath, data.length, data));
    }
  }
  return ZipEncoder().encode(archive) ?? <int>[];
}

void _extractZipBytesWorker(_ExtractZipArgs args) {
  final target = Directory(args.targetPath);
  final targetRoot = target.absolute.path.replaceAll('\\', '/');
  final archive = ZipDecoder().decodeBytes(args.bytes);
  for (final file in archive) {
    final rawName = file.name.replaceAll('\\', '/');
    if (rawName.startsWith('/') ||
        rawName.split('/').any((seg) => seg == '..')) {
      continue;
    }
    final outPath = '${target.path}/$rawName';
    final resolvedOut = File(outPath).absolute.path.replaceAll('\\', '/');
    if (resolvedOut != targetRoot &&
        !resolvedOut.startsWith('$targetRoot/')) {
      continue;
    }
    if (file.isFile) {
      final outFile = File(outPath);
      outFile.parent.createSync(recursive: true);
      outFile.writeAsBytesSync(file.content as List<int>, flush: true);
    } else {
      Directory(outPath).createSync(recursive: true);
    }
  }
}
