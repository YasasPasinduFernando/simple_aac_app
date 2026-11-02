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
      if (!await file.exists()) return null;
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

  static List<int> _zipDirectory(Directory dir) {
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
    final zipEncoder = ZipEncoder();
    return zipEncoder.encode(archive) ?? <int>[];
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
      return _zipDirectory(backupRoot);
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
    final decoded = jsonDecode(await manifestFile.readAsString()) as List;
    final restored = decoded.map((c) => AACCard.fromJson(c)).toList();
    debugPrint(
      '[BackupService] restoring backup from ${backupDir.path}: '
      '${restored.length} top-level cards, '
      '${CardStorageService.countCards(restored)} total cards',
    );

    Future<String?> restoreMedia(String? relPath, String mediaType) async {
      if (relPath == null) return null;
      if (_isAssetPath(relPath)) return relPath;
      final sourcePath = '${backupDir.path}/${relPath.replaceAll('\\', '/')}';
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      final base = _basename(sourcePath);
      final mediaDir = await CardStorageService.mediaDirectory(mediaType);
      final destPath = '${mediaDir.path}/$base';
      var targetPath = destPath;
      var counter = 1;
      while (await File(targetPath).exists()) {
        final dot = base.lastIndexOf('.');
        final name = dot == -1 ? base : base.substring(0, dot);
        final ext = dot == -1 ? '' : base.substring(dot);
        targetPath = '${mediaDir.path}/${name}_$counter$ext';
        counter++;
      }
      await sourceFile.copy(targetPath);
      debugPrint(
        '[BackupService] restored $mediaType file: source=$sourcePath, '
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
  ) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final name = file.name.replaceAll('\\', '/');
      final outPath = '${target.path}/$name';
      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>, flush: true);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }
  }

  static Future<BackupPayload> restoreFromZipBytes(List<int> bytes) async {
    final tempDir = await Directory.systemTemp.createTemp('aac_restore_');
    try {
      await _extractZipBytesToDirectory(bytes, tempDir);
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
      await tempDir.delete(recursive: true);
    }
  }

  static bool _isAssetPath(String path) {
    return path.startsWith('assets/');
  }
}
