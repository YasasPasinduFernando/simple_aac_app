import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/aac_card_model.dart';
import '../models/recycle_bin_entry.dart';

/// Service responsible for managing deleted cards in the 30-day Recycle Bin.
/// Ensures atomic persistence, isolated storage, reference-safe media cleanup,
/// and automatic 30-day expiration.
class RecycleBinService {
  RecycleBinService._internal();
  static final RecycleBinService _instance = RecycleBinService._internal();
  static RecycleBinService get instance => _instance;

  static const String fileName = 'aac_recycle_bin.json';

  @visibleForTesting
  static Future<Directory> Function()? docsDirectoryOverride;

  @visibleForTesting
  static DateTime Function()? clockOverride;

  /// Returns current UTC time or injectable test clock time.
  static DateTime get now =>
      clockOverride != null ? clockOverride!() : DateTime.now().toUtc();

  @visibleForTesting
  static void resetTestHooks() {
    docsDirectoryOverride = null;
    clockOverride = null;
  }

  static Future<Directory> _getDocsDirectory() {
    final override = docsDirectoryOverride;
    if (override != null) return override();
    return getApplicationDocumentsDirectory();
  }

  static Future<File> _getFile() async {
    final docsDir = await _getDocsDirectory();
    return File('${docsDir.path}${Platform.pathSeparator}$fileName');
  }

  /// Loads all stored RecycleBinEntry items from disk.
  Future<List<RecycleBinEntry>> loadEntries() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return [];
      }
      final decoded = jsonDecode(content);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map>()
          .map((m) => RecycleBinEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint('[RecycleBin] Error loading entries: $e');
      return [];
    }
  }

  /// Persists the list of entries to disk.
  Future<void> saveEntries(List<RecycleBinEntry> entries) async {
    try {
      final file = await _getFile();
      final tmpFile = File('${file.path}.tmp');
      final jsonStr = const JsonEncoder.withIndent('  ').convert(
        entries.map((e) => e.toJson()).toList(),
      );
      await tmpFile.writeAsString(jsonStr, flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await tmpFile.rename(file.path);
    } catch (e) {
      debugPrint('[RecycleBin] Error saving entries: $e');
      // Fallback direct write if atomic rename fails
      try {
        final file = await _getFile();
        final jsonStr = const JsonEncoder.withIndent('  ').convert(
          entries.map((e) => e.toJson()).toList(),
        );
        await file.writeAsString(jsonStr, flush: true);
      } catch (fallbackError) {
        debugPrint('[RecycleBin] Fallback save failed: $fallbackError');
      }
    }
  }

  /// Moves a deleted card or folder to the Recycle Bin.
  /// Preserves full subtree, original parent ID, sibling position, and deletion timestamp.
  Future<RecycleBinEntry> moveToRecycleBin({
    required AACCard card,
    String? parentId,
    int originalIndex = 0,
  }) async {
    final clonedCard = AACCard.fromJson(card.toJson());
    final entry = RecycleBinEntry(
      entryId: 'bin_${DateTime.now().microsecondsSinceEpoch}',
      card: clonedCard,
      parentId: parentId,
      originalIndex: originalIndex >= 0 ? originalIndex : 0,
      deletedAtUtc: now,
    );

    final entries = await loadEntries();
    // Most recently deleted at the top
    entries.insert(0, entry);
    await saveEntries(entries);
    debugPrint(
      '[RecycleBin] moved "${card.label}" to recycle bin (entryId: ${entry.entryId}, parent: $parentId, index: $originalIndex)',
    );
    return entry;
  }

  /// Restores an entry from the Recycle Bin into activeCards.
  /// If original parent exists in activeCards, restores to parent; otherwise restores to root.
  /// Handles ID collisions gracefully.
  Future<AACCard?> restoreEntry({
    required String entryId,
    required List<AACCard> activeCards,
  }) async {
    final entries = await loadEntries();
    final index = entries.indexWhere((e) => e.entryId == entryId);
    if (index == -1) return null;

    final entry = entries.removeAt(index);
    await saveEntries(entries);

    final restoredCard = entry.card;
    _deduplicateCardIds(restoredCard, activeCards);

    AACCard? targetParent;
    if (entry.parentId != null) {
      targetParent = _findCardById(entry.parentId!, activeCards);
    }

    if (targetParent != null) {
      final safeIndex = entry.originalIndex.clamp(0, targetParent.subCards.length);
      targetParent.subCards.insert(safeIndex, restoredCard);
      debugPrint(
        '[RecycleBin] restored "${restoredCard.label}" into parent "${targetParent.label}" at index $safeIndex',
      );
    } else {
      final safeIndex = entry.originalIndex.clamp(0, activeCards.length);
      activeCards.insert(safeIndex, restoredCard);
      debugPrint(
        '[RecycleBin] restored "${restoredCard.label}" into root cards at index $safeIndex',
      );
    }

    return restoredCard;
  }

  /// Permanently removes a single entry and cleans up unreferenced media.
  Future<void> removeEntry(
    String entryId, {
    List<AACCard>? activeCards,
  }) async {
    final entries = await loadEntries();
    final index = entries.indexWhere((e) => e.entryId == entryId);
    if (index == -1) return;

    final entry = entries.removeAt(index);
    await saveEntries(entries);

    // Clean up media referenced by this entry if no other active card or bin entry needs it
    if (activeCards != null) {
      await _cleanupUnreferencedMedia(
        candidatePaths: entry.referencedMediaPaths,
        activeCards: activeCards,
        remainingEntries: entries,
      );
    }
  }

  /// Permanently removes all items from the Recycle Bin and cleans up unreferenced media.
  Future<void> emptyRecycleBin({
    List<AACCard>? activeCards,
  }) async {
    final entries = await loadEntries();
    if (entries.isEmpty) return;

    final allCandidateMedia = <String>{};
    for (final e in entries) {
      allCandidateMedia.addAll(e.referencedMediaPaths);
    }

    await saveEntries([]);

    if (activeCards != null) {
      await _cleanupUnreferencedMedia(
        candidatePaths: allCandidateMedia,
        activeCards: activeCards,
        remainingEntries: const [],
      );
    }
  }

  /// Purges entries older than 30 days and removes their unreferenced media.
  Future<int> purgeExpiredEntries({
    List<AACCard>? activeCards,
  }) async {
    final entries = await loadEntries();
    if (entries.isEmpty) return 0;

    final expired = <RecycleBinEntry>[];
    final surviving = <RecycleBinEntry>[];

    final currentNow = now;
    for (final e in entries) {
      if (e.isExpired(currentNow)) {
        expired.add(e);
      } else {
        surviving.add(e);
      }
    }

    if (expired.isEmpty) return 0;

    await saveEntries(surviving);
    debugPrint(
      '[RecycleBin] automatically purged ${expired.length} expired entries (>= 30 days old)',
    );

    if (activeCards != null) {
      final candidateMedia = <String>{};
      for (final e in expired) {
        candidateMedia.addAll(e.referencedMediaPaths);
      }
      await _cleanupUnreferencedMedia(
        candidatePaths: candidateMedia,
        activeCards: activeCards,
        remainingEntries: surviving,
      );
    }

    return expired.length;
  }

  /// Returns the current number of items in the Recycle Bin.
  Future<int> getEntryCount() async {
    final entries = await loadEntries();
    return entries.length;
  }

  // --- Helper Methods ---

  AACCard? _findCardById(String id, List<AACCard> cardList) {
    for (final card in cardList) {
      if (card.id == id) return card;
      final foundInSub = _findCardById(id, card.subCards);
      if (foundInSub != null) return foundInSub;
    }
    return null;
  }

  void _deduplicateCardIds(AACCard card, List<AACCard> activeCards) {
    final existingIds = <String>{};
    void collectIds(AACCard c) {
      existingIds.add(c.id);
      for (final sub in c.subCards) {
        collectIds(sub);
      }
    }

    for (final root in activeCards) {
      collectIds(root);
    }

    void ensureUnique(AACCard c) {
      if (existingIds.contains(c.id)) {
        c.id = 'card_${DateTime.now().microsecondsSinceEpoch}_restored';
        existingIds.add(c.id);
      }
      for (final sub in c.subCards) {
        ensureUnique(sub);
      }
    }

    ensureUnique(card);
  }

  static bool isAppOwnedMedia(String path, Directory docsDir) {
    if (path.isEmpty) return false;
    final normalized = path.replaceAll('\\', '/');
    if (normalized.startsWith('assets/') || normalized.startsWith('asset:')) {
      return false;
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return false;
    }
    final mediaPrefix =
        '${docsDir.path.replaceAll('\\', '/')}/aac_media/';
    return normalized.startsWith(mediaPrefix);
  }

  Future<void> _cleanupUnreferencedMedia({
    required Iterable<String> candidatePaths,
    required List<AACCard> activeCards,
    required List<RecycleBinEntry> remainingEntries,
  }) async {
    final docsDir = await _getDocsDirectory();

    // 1. Collect all active media paths
    final activePaths = <String>{};
    void walkActive(AACCard c) {
      final img = c.imagePath?.trim();
      if (img != null && img.isNotEmpty) {
        activePaths.add(img.replaceAll('\\', '/'));
      }
      final voice = c.voicePath?.trim();
      if (voice != null && voice.isNotEmpty) {
        activePaths.add(voice.replaceAll('\\', '/'));
      }
      for (final sub in c.subCards) {
        walkActive(sub);
      }
    }

    for (final root in activeCards) {
      walkActive(root);
    }

    // 2. Collect all remaining bin media paths
    final binPaths = <String>{};
    for (final entry in remainingEntries) {
      for (final p in entry.referencedMediaPaths) {
        binPaths.add(p.replaceAll('\\', '/'));
      }
    }

    // 3. For each candidate, if not referenced by active cards or remaining bin, delete from disk
    for (final rawPath in candidatePaths) {
      if (!isAppOwnedMedia(rawPath, docsDir)) continue;
      final normalized = rawPath.replaceAll('\\', '/');
      if (activePaths.contains(normalized) || binPaths.contains(normalized)) {
        continue;
      }
      try {
        final f = File(rawPath);
        if (await f.exists()) {
          await f.delete();
          debugPrint('[RecycleBin] Safely deleted unreferenced media file: $rawPath');
        }
      } catch (e) {
        debugPrint('[RecycleBin] Error deleting media file $rawPath: $e');
      }
    }
  }
}
