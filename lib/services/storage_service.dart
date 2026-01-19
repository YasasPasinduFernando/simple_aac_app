import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/aac_card.dart';

class StorageService {
  static const String _cardsKey = 'aac_cards';
  static const String _gridColumnsKey = 'grid_columns';

  static Future<void> saveCards(List<AACCard> cards) async {
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
    await prefs.setInt(_gridColumnsKey, columns);
  }

  static Future<int> loadGridColumns() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_gridColumnsKey) ?? 2;
  }
}
