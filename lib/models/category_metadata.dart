import 'package:flutter/material.dart';

/// Pre-configured suggestion preset for quick category creation.
class CategoryPresetItem {
  final String name;
  final IconData icon;
  final int colorValue;
  final String emoji;
  final List<String> searchKeywords;

  const CategoryPresetItem({
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.emoji,
    required this.searchKeywords,
  });
}

/// Pre-defined list of supported Material icons for categories.
/// Statically referenced so Flutter tree-shaking preserves glyphs in release builds.
const List<IconData> kAllCategoryIcons = [
  Icons.category_rounded,
  Icons.restaurant_rounded,
  Icons.school_rounded,
  Icons.emoji_emotions_rounded,
  Icons.sports_soccer_rounded,
  Icons.home_rounded,
  Icons.favorite_rounded,
  Icons.directions_car_rounded,
  Icons.pets_rounded,
  Icons.people_rounded,
  Icons.star_rounded,
  Icons.toys_rounded,
  Icons.music_note_rounded,
  Icons.local_hospital_rounded,
  Icons.folder_rounded,
  Icons.folder_outlined,
  Icons.grid_view_rounded,
  Icons.apps_rounded,
];

/// Metadata describing a category's icon, accent color, and display properties.
class CategoryMetadata {
  final String name;
  final IconData icon;
  final int colorValue;

  const CategoryMetadata({
    required this.name,
    required this.icon,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'name': name,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'iconFontPackage': icon.fontPackage,
        'colorValue': colorValue,
      };

  factory CategoryMetadata.fromJson(Map<String, dynamic> json) {
    final codePoint = json['iconCodePoint'] as int?;
    final colorVal = json['colorValue'] as int? ?? 0xFF0277BD;
    final name = json['name'] as String? ?? '';

    IconData resolvedIcon = Icons.folder_rounded;
    if (codePoint != null) {
      for (final ic in kAllCategoryIcons) {
        if (ic.codePoint == codePoint) {
          resolvedIcon = ic;
          break;
        }
      }
    }

    return CategoryMetadata(
      name: name,
      icon: resolvedIcon,
      colorValue: colorVal,
    );
  }

  /// Resolves the metadata for a given category name, checking custom metadata first,
  /// then built-in presets, and falling back to a safe default icon/color.
  static CategoryMetadata resolve(
    String categoryName, {
    Map<String, CategoryMetadata>? customMetadata,
    int? fallbackColorValue,
  }) {
    final trimmed = categoryName.trim();
    final defaultColor = fallbackColorValue ?? 0xFF0277BD;

    if (trimmed.isEmpty) {
      return CategoryMetadata(
        name: '',
        icon: Icons.category_rounded,
        colorValue: defaultColor,
      );
    }

    // 1. Check custom metadata first (exact match, then case-insensitive)
    if (customMetadata != null) {
      if (customMetadata.containsKey(trimmed)) {
        return customMetadata[trimmed]!;
      }
      for (final entry in customMetadata.entries) {
        if (entry.key.toLowerCase() == trimmed.toLowerCase()) {
          return entry.value;
        }
      }
    }

    // 2. Built-in defaults by known names
    final lower = trimmed.toLowerCase();
    if (lower == 'all' || lower == 'all cards') {
      return const CategoryMetadata(
        name: 'All Cards',
        icon: Icons.grid_view_rounded,
        colorValue: 0xFF0277BD,
      );
    }
    if (lower == 'general') {
      return const CategoryMetadata(
        name: 'General',
        icon: Icons.category_rounded,
        colorValue: 0xFF0277BD,
      );
    }

    // 3. Known preset defaults
    for (final preset in defaultPresets) {
      if (preset.name.toLowerCase() == lower) {
        return CategoryMetadata(
          name: preset.name,
          icon: preset.icon,
          colorValue: preset.colorValue,
        );
      }
    }

    // 4. Safe fallback
    return CategoryMetadata(
      name: trimmed,
      icon: Icons.folder_rounded,
      colorValue: defaultColor,
    );
  }

  static const List<CategoryPresetItem> defaultPresets = [
    CategoryPresetItem(
      name: 'Food',
      icon: Icons.restaurant_rounded,
      colorValue: 0xFFFFA726, // Orange
      emoji: '🍽️',
      searchKeywords: [
        'food',
        'drink',
        'water',
        'rice',
        'milk',
        'apple',
        'bread',
        'eat',
        'කෑම',
        'වතුර',
        'බත්',
        'உணவு'
      ],
    ),
    CategoryPresetItem(
      name: 'School',
      icon: Icons.school_rounded,
      colorValue: 0xFF42A5F5, // Blue
      emoji: '🏫',
      searchKeywords: [
        'school',
        'teacher',
        'book',
        'pen',
        'pencil',
        'study',
        'class',
        'පාසල',
        'පොත',
        'பள்ளி'
      ],
    ),
    CategoryPresetItem(
      name: 'Feelings',
      icon: Icons.emoji_emotions_rounded,
      colorValue: 0xFFFFCA28, // Amber / Warm Yellow
      emoji: '😊',
      searchKeywords: [
        'happy',
        'sad',
        'angry',
        'feelings',
        'tired',
        'hungry',
        'sick',
        'සතුටුයි',
        'දුකයි',
        'மகிழ்ச்சි'
      ],
    ),
    CategoryPresetItem(
      name: 'Play',
      icon: Icons.sports_soccer_rounded,
      colorValue: 0xFF66BB6A, // Green
      emoji: '⚽',
      searchKeywords: [
        'play',
        'game',
        'ball',
        'toy',
        'run',
        'jump',
        'video',
        'සෙල්ලම්',
        'விளையாட்டு'
      ],
    ),
    CategoryPresetItem(
      name: 'Home',
      icon: Icons.home_rounded,
      colorValue: 0xFF26A69A, // Teal
      emoji: '🏠',
      searchKeywords: [
        'home',
        'house',
        'room',
        'bed',
        'sleep',
        'bath',
        'kitchen',
        'ගෙදර',
        'නිවස',
        'வீடு'
      ],
    ),
    CategoryPresetItem(
      name: 'Health',
      icon: Icons.favorite_rounded,
      colorValue: 0xFFEF5350, // Coral / Red
      emoji: '🩺',
      searchKeywords: [
        'health',
        'doctor',
        'hospital',
        'medicine',
        'pain',
        'hurt',
        'sick',
        'රෝහල',
        'අසනීපයි',
        'மருத்துவமனை'
      ],
    ),
    CategoryPresetItem(
      name: 'Travel',
      icon: Icons.directions_car_rounded,
      colorValue: 0xFFAB47BC, // Purple
      emoji: '🚗',
      searchKeywords: [
        'car',
        'bus',
        'vehicle',
        'van',
        'train',
        'go',
        'trip',
        'කාර්',
        'බස්',
        'வாகனம்'
      ],
    ),
    CategoryPresetItem(
      name: 'Animals',
      icon: Icons.pets_rounded,
      colorValue: 0xFF8D6E63, // Warm Brown
      emoji: '🐶',
      searchKeywords: [
        'cat',
        'dog',
        'pet',
        'animal',
        'bird',
        'fish',
        'සතා',
        'බල්ලා',
        'விலங்கு'
      ],
    ),
    CategoryPresetItem(
      name: 'People',
      icon: Icons.people_rounded,
      colorValue: 0xFF5C6BC0, // Indigo
      emoji: '👥',
      searchKeywords: [
        'mom',
        'dad',
        'friend',
        'brother',
        'sister',
        'family',
        'අම්මා',
        'තාත්තා',
        'குடும்பம்'
      ],
    ),
  ];
}
