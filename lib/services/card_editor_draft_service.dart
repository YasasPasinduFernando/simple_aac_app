import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/aac_card_model.dart';

/// Staged card editor draft information preserved across Android process recreation.
class CardEditorDraft {
  final String cardId;
  final bool isNew;
  final String label;
  final String? labelSinhala;
  final String? labelTamil;
  final String category;
  final String? imagePath;
  final String? voicePath;
  final int colorValue;
  final String type;
  final List<String> parentStackIds;

  const CardEditorDraft({
    required this.cardId,
    required this.isNew,
    required this.label,
    this.labelSinhala,
    this.labelTamil,
    required this.category,
    this.imagePath,
    this.voicePath,
    required this.colorValue,
    required this.type,
    required this.parentStackIds,
  });

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'isNew': isNew,
        'label': label,
        'labelSinhala': labelSinhala,
        'labelTamil': labelTamil,
        'category': category,
        'imagePath': imagePath,
        'voicePath': voicePath,
        'colorValue': colorValue,
        'type': type,
        'parentStackIds': parentStackIds,
      };

  factory CardEditorDraft.fromJson(Map<String, dynamic> json) => CardEditorDraft(
        cardId: json['cardId'] as String,
        isNew: json['isNew'] as bool? ?? false,
        label: json['label'] as String? ?? '',
        labelSinhala: json['labelSinhala'] as String?,
        labelTamil: json['labelTamil'] as String?,
        category: json['category'] as String? ?? 'General',
        imagePath: json['imagePath'] as String?,
        voicePath: json['voicePath'] as String?,
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFFFFFFFF,
        type: json['type'] as String? ?? 'word',
        parentStackIds: (json['parentStackIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  AACCard toCard({List<AACCard>? subCards}) {
    return AACCard(
      id: cardId,
      label: label,
      labelSinhala: labelSinhala,
      labelTamil: labelTamil,
      imagePath: imagePath,
      voicePath: voicePath,
      colorValue: colorValue,
      type: type,
      category: category,
      subCards: subCards ?? [],
    );
  }
}

/// Service to stage CardEditorDialog draft state in SharedPreferences before
/// camera/gallery external intents so Android process death does not lose
/// draft labels, folder context, or captured camera images.
class CardEditorDraftService {
  static const String _draftActiveKey = 'card_editor_staged_draft_active';
  static const String _draftDataKey = 'card_editor_staged_draft_data';

  static final ImagePicker _picker = ImagePicker();

  @visibleForTesting
  static ImagePicker Function()? pickerOverride;

  @visibleForTesting
  static Future<String?> Function()? lostDataOverride;

  static ImagePicker get _effectivePicker =>
      pickerOverride != null ? pickerOverride!() : _picker;

  /// Stages the current card editor draft into SharedPreferences before
  /// launching an external camera or media intent.
  static Future<void> saveDraft({
    required AACCard card,
    required bool isNew,
    required List<String> parentStackIds,
    required String label,
    String? labelSinhala,
    String? labelTamil,
    String? category,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = CardEditorDraft(
        cardId: card.id,
        isNew: isNew,
        label: label,
        labelSinhala: labelSinhala,
        labelTamil: labelTamil,
        category: category ?? card.category,
        imagePath: card.imagePath,
        voicePath: card.voicePath,
        colorValue: card.colorValue,
        type: card.type,
        parentStackIds: parentStackIds,
      );
      await prefs.setString(_draftDataKey, jsonEncode(draft.toJson()));
      await prefs.setBool(_draftActiveKey, true);
    } catch (e) {
      debugPrint('[CardEditorDraftService] Failed to save draft: $e');
    }
  }

  /// Checks if an uncommitted card editor draft exists from a previous session.
  static Future<bool> hasDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_draftActiveKey) == true &&
          prefs.containsKey(_draftDataKey);
    } catch (_) {
      return false;
    }
  }

  /// Retrieves the uncommitted draft data.
  static Future<CardEditorDraft?> getDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftDataKey);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CardEditorDraft.fromJson(map);
    } catch (e) {
      debugPrint('[CardEditorDraftService] Failed to read draft: $e');
      return null;
    }
  }

  /// Clears the staged draft after normal camera return or explicit save/cancel.
  static Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftActiveKey);
      await prefs.remove(_draftDataKey);
    } catch (_) {}
  }

  /// Calls ImagePicker.retrieveLostData() to recover any image captured before
  /// Android process recreation. Returns the recovered file path or null.
  static Future<String?> recoverCameraPhoto() async {
    if (lostDataOverride != null) {
      return lostDataOverride!();
    }
    try {
      final LostDataResponse response = await _effectivePicker.retrieveLostData();
      if (response.isEmpty) return null;
      final file = response.file;
      if (file != null && file.path.isNotEmpty) {
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('[CardEditorDraftService] retrieveLostData failed: $e');
      return null;
    }
  }
}
