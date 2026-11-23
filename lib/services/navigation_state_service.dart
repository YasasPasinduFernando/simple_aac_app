import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/aac_card_model.dart';

/// Navigation restore information retrieved from native lifecycle and storage.
class NavigationRestoreInfo {
  final bool isSystemProcessRecreation;
  final List<String> folderStackIds;

  const NavigationRestoreInfo({
    required this.isSystemProcessRecreation,
    required this.folderStackIds,
  });
}

/// Service managing AAC navigation folder state persistence across Android
/// background process recreation and normal application lifecycle.
class NavigationStateService {
  static const MethodChannel _channel = MethodChannel('aac_lifecycle');
  static const String prefFolderStackKey = 'nav_active_folder_stack_ids';

  @visibleForTesting
  static NavigationRestoreInfo? testRestoreInfoOverride;

  @visibleForTesting
  static bool enableNativeChannelInTests = false;

  static bool get _isAndroid =>
      (!kIsWeb && Platform.isAndroid) || enableNativeChannelInTests;

  /// Retrieves lifecycle restoration information.
  /// Distinguishes between system process recreation (returns saved folder stack)
  /// and fresh app launches (returns isSystemProcessRecreation = false).
  static Future<NavigationRestoreInfo> getRestoreInfo() async {
    if (testRestoreInfoOverride != null) {
      return testRestoreInfoOverride!;
    }

    if (!_isAndroid) {
      return const NavigationRestoreInfo(
        isSystemProcessRecreation: false,
        folderStackIds: [],
      );
    }

    bool isRecreation = false;
    List<String> stack = [];

    try {
      final res =
          await _channel.invokeMapMethod<String, dynamic>('getNavigationRestoreInfo');
      if (res != null) {
        isRecreation = res['isSystemProcessRecreation'] as bool? ?? false;
        final rawList = res['folderStackIds'] as List<dynamic>?;
        if (rawList != null) {
          stack = rawList.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {
      // Platform channel not available (e.g. non-Android or unit test)
    }

    // Fallback: If native reported recreation but had an empty stack, inspect SharedPreferences
    if (isRecreation && stack.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        stack = prefs.getStringList(prefFolderStackKey) ?? [];
      } catch (_) {}
    }

    return NavigationRestoreInfo(
      isSystemProcessRecreation: isRecreation,
      folderStackIds: stack,
    );
  }

  /// Synchronizes the current active folder stack to native lifecycle and SharedPreferences.
  static Future<void> syncFolderStack(List<String> folderStackIds) async {
    if (_isAndroid) {
      try {
        await _channel.invokeMethod(
          'syncFolderStack',
          {'folderStackIds': folderStackIds},
        );
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (folderStackIds.isEmpty) {
        await prefs.remove(prefFolderStackKey);
      } else {
        await prefs.setStringList(prefFolderStackKey, folderStackIds);
      }
    } catch (_) {}
  }

  /// Validates a list of card IDs in hierarchical order against loaded cards.
  /// Returns the resolved AACCard stack if all exist and are folders, or null if broken/deleted.
  static List<AACCard>? validateFolderChain(List<String> ids, List<AACCard> rootCards) {
    if (ids.isEmpty) return null;

    final result = <AACCard>[];
    List<AACCard> currentScope = rootCards;

    for (final id in ids) {
      final found = _findCardInScope(id, currentScope);
      if (found == null) return null; // Chain broken or deleted
      if (found.type != 'folder' && found.subCards.isEmpty) return null; // Not a valid folder
      result.add(found);
      currentScope = found.subCards;
    }

    return result;
  }

  static AACCard? _findCardInScope(String id, List<AACCard> cards) {
    for (final c in cards) {
      if (c.id == id) return c;
      final sub = _findCardInScope(id, c.subCards);
      if (sub != null) return sub;
    }
    return null;
  }
}
