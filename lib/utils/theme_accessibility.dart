import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application-wide dark mode state and color-vision accessibility helpers.
/// Kept lightweight so user-saved custom colors remain untouched underneath.
class ThemeAccessibility {
  static const String darkModePrefKey = 'darkMode';
  static const String colorBlindPrefKey = 'colorBlindMode';

  static final ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(false);

  static Future<bool> initDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(darkModePrefKey) ?? false;
    darkModeNotifier.value = enabled;
    return enabled;
  }

  static Future<void> setDarkMode(bool enabled) async {
    darkModeNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(darkModePrefKey, enabled);
  }

  /// Resolves the card surface color for display without mutating stored data.
  static Color resolveCardSurface(
    Color base, {
    required bool isDarkMode,
    required bool isColorBlindMode,
  }) {
    if (isColorBlindMode) {
      final mapped = _mapToOkabeIto(base);
      return isDarkMode ? Color.lerp(mapped, const Color(0xFF14181F), 0.2)! : mapped;
    }
    if (isDarkMode) {
      return Color.lerp(base, const Color(0xFF181C22), 0.34)!;
    }
    return base;
  }

  /// Resolves legible text color on top of [cardSurface].
  static Color resolveCardTextColor(
    Color cardSurface, {
    required bool isDarkMode,
    required bool isColorBlindMode,
    required bool applyCustomTextColor,
    required Color customTextColor,
  }) {
    if (isColorBlindMode || isDarkMode) {
      return ThemeData.estimateBrightnessForColor(cardSurface) == Brightness.light
          ? const Color(0xFF111827)
          : Colors.white;
    }
    return applyCustomTextColor ? customTextColor : Colors.white;
  }

  /// Maps arbitrary card hues onto the Okabe-Ito color-blind-safe palette
  /// so red/green/blue/yellow remain distinguishable for protanopia,
  /// deuteranopia, and tritanopia users.
  static Color _mapToOkabeIto(Color color) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.saturation < 0.14) {
      return hsl.lightness > 0.6
          ? const Color(0xFF94A3B8)
          : const Color(0xFF334155);
    }

    final hue = hsl.hue;
    if (hue < 22 || hue >= 335) {
      return const Color(0xFFD55E00); // Vermilion (replaces red)
    }
    if (hue < 48) {
      return const Color(0xFFE69F00); // Orange
    }
    if (hue < 75) {
      return const Color(0xFFF0E442); // Yellow
    }
    if (hue < 165) {
      return const Color(0xFF009E73); // Bluish-green (replaces green)
    }
    if (hue < 208) {
      return const Color(0xFF56B4E9); // Sky blue
    }
    if (hue < 272) {
      return const Color(0xFF0072B2); // Deep blue
    }
    return const Color(0xFFCC79A7); // Reddish purple
  }
}
