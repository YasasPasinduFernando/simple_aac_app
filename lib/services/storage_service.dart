import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/aac_card_model.dart';
import 'card_storage_service.dart';

class StorageService {
  static const String _cardsKey = 'aac_cards';
  static const String _gridColumnsKey = 'grid_columns';
  static const String _gridColumnsLegacyKey = 'gridColumns';

  static Future<void> saveCards(List<AACCard> cards) async {
    await CardStorageService.saveCards(cards);
    final prefs = await SharedPreferences.getInstance();
    final jsonList = cards.map((card) => card.toJson()).toList();
    await prefs.setString(_cardsKey, jsonEncode(jsonList));
  }

  static Future<List<AACCard>> loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_cardsKey);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => AACCard.fromJson(json)).toList();
  }

  static Future<void> saveGridColumns(int columns) async {
    final prefs = await SharedPreferences.getInstance();
    final clamped = columns.clamp(1, 30);
    await prefs.setInt(_gridColumnsKey, clamped);
    await prefs.setInt(_gridColumnsLegacyKey, clamped);
  }

  static Future<int> loadGridColumns() async {
    final prefs = await SharedPreferences.getInstance();
    final cols = prefs.getInt(_gridColumnsKey) ?? prefs.getInt(_gridColumnsLegacyKey) ?? 2;
    return cols.clamp(1, 30);
  }
}
