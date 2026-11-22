import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application-wide dark mode state and color-vision accessibility helpers.
/// Kept lightweight so user-saved custom colors remain untouched underneath.
class ThemeAccessibility {
  static const String darkModePrefKey = 'darkMode';
  static const String colorBlindPrefKey = 'colorBlindMode';
  static const String colorBlindTypePrefKey = 'colorBlindType';
  static const String colorBlindBorderWidthPrefKey = 'colorBlindBorderWidth';
  static const String colorBlindBorderColorPrefKey = 'colorBlindBorderColor';
  static const String colorBlindBoldTextPrefKey = 'colorBlindBoldText';
  static const String colorBlindFilterImagesPrefKey = 'colorBlindFilterImages';

  static bool colorBlindMode = false;
  static String colorBlindType = 'universal'; // universal, deuteranomaly, protanomaly, tritanomaly, monochrome
  static double colorBlindBorderWidth = 2.5;
  static String colorBlindBorderColor = 'auto'; // auto, black, blue, yellow, white
  static bool colorBlindBoldText = true;
  static bool colorBlindFilterImages = true;

  static final ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(false);

  static Future<bool> initDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(darkModePrefKey) ?? false;
    darkModeNotifier.value = enabled;
    await initColorBlindSettings();
    return enabled;
  }

  static Future<void> initColorBlindSettings() async {
    final prefs = await SharedPreferences.getInstance();
    colorBlindMode = prefs.getBool(colorBlindPrefKey) ?? false;
    colorBlindType = prefs.getString(colorBlindTypePrefKey) ?? 'universal';
    colorBlindBorderWidth = prefs.getDouble(colorBlindBorderWidthPrefKey) ?? 2.5;
    colorBlindBorderColor = prefs.getString(colorBlindBorderColorPrefKey) ?? 'auto';
    colorBlindBoldText = prefs.getBool(colorBlindBoldTextPrefKey) ?? true;
    colorBlindFilterImages = prefs.getBool(colorBlindFilterImagesPrefKey) ?? true;
  }

  static Future<void> saveColorBlindSettings({
    bool? enabled,
    required String type,
    required double borderWidth,
    required String borderColor,
    required bool boldText,
    bool filterImages = true,
  }) async {
    if (enabled != null) colorBlindMode = enabled;
    colorBlindType = type;
    colorBlindBorderWidth = borderWidth;
    colorBlindBorderColor = borderColor;
    colorBlindBoldText = boldText;
    colorBlindFilterImages = filterImages;
    final prefs = await SharedPreferences.getInstance();
    if (enabled != null) {
      await prefs.setBool(colorBlindPrefKey, enabled);
    }
    await prefs.setString(colorBlindTypePrefKey, type);
    await prefs.setDouble(colorBlindBorderWidthPrefKey, borderWidth);
    await prefs.setString(colorBlindBorderColorPrefKey, borderColor);
    await prefs.setBool(colorBlindBoldTextPrefKey, boldText);
    await prefs.setBool(colorBlindFilterImagesPrefKey, filterImages);
  }

  static Future<void> setDarkMode(bool enabled) async {
    darkModeNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(darkModePrefKey, enabled);
  }

  /// Computes WCAG 2.1 relative luminance contrast ratio between two colors (range: 1.0 to 21.0).
  static double contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Resolves the card surface color for display without mutating stored data.
  static Color resolveCardSurface(
    Color base, {
    required bool isDarkMode,
    required bool isColorBlindMode,
    String? type,
  }) {
    if (isColorBlindMode) {
      final effectiveType = type ?? colorBlindType;
      final mapped = _mapColorBlindHue(base, effectiveType);
      return isDarkMode ? Color.lerp(mapped, const Color(0xFF14181F), 0.2)! : mapped;
    }
    if (isDarkMode) {
      return Color.lerp(base, const Color(0xFF181C22), 0.34)!;
    }
    return base;
  }

  /// Resolves card border color.
  static Color resolveCardBorderColor({
    required bool isDarkMode,
    required bool isColorBlindMode,
    String? colorOption,
  }) {
    if (!isColorBlindMode) {
      return isDarkMode ? Colors.white24 : Colors.transparent;
    }
    final option = colorOption ?? colorBlindBorderColor;
    switch (option) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'blue':
        return const Color(0xFF0072B2);
      case 'yellow':
        return const Color(0xFFF0E442);
      case 'auto':
      default:
        return isDarkMode ? Colors.white70 : Colors.black87;
    }
  }

  /// Resolves card border width.
  static double resolveCardBorderWidth({
    required bool isColorBlindMode,
    double? width,
  }) {
    if (!isColorBlindMode) return 1.0;
    return width ?? colorBlindBorderWidth;
  }

  /// Resolves text shadow / outline for high-contrast color blind legibility.
  static List<Shadow>? resolveCardTextShadow({
    required Color cardSurface,
    required bool isColorBlindMode,
    bool? isBold,
  }) {
    final bold = isBold ?? colorBlindBoldText;
    if (!isColorBlindMode || !bold) return null;
    final isLightBg =
        ThemeData.estimateBrightnessForColor(cardSurface) == Brightness.light;
    return [
      Shadow(
        color: isLightBg
            ? Colors.white.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.9),
        blurRadius: 3,
        offset: const Offset(0, 0.5),
      ),
    ];
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

  /// Maps arbitrary card hues according to selected color blindness deficiency type.
  static Color _mapColorBlindHue(Color color, String type) {
    switch (type) {
      case 'deuteranomaly':
        return _mapDeuteranomaly(color);
      case 'protanomaly':
        return _mapProtanomaly(color);
      case 'tritanomaly':
        return _mapTritanomaly(color);
      case 'monochrome':
        return _mapMonochrome(color);
      case 'universal':
      default:
        return _mapToOkabeIto(color);
    }
  }

  /// Deuteranomaly (Red-Green / Green-weak):
  /// Shifts green hues distinctly toward high-luminance teal/cyan and red toward deep vermilion.
  static Color _mapDeuteranomaly(Color color) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.saturation < 0.14) {
      return hsl.lightness > 0.6 ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    }
    final hue = hsl.hue;
    if (hue < 30 || hue >= 330) {
      return const Color(0xFFD55E00); // Warm vermilion
    }
    if (hue < 65) {
      return const Color(0xFFF59E0B); // Amber gold
    }
    if (hue < 170) {
      return const Color(0xFF009E73); // Bluish green / teal
    }
    if (hue < 260) {
      return const Color(0xFF0072B2); // Deep blue
    }
    return const Color(0xFF7C3AED); // Vivid purple
  }

  /// Protanomaly (Red-Green / Red-weak):
  /// Red appears very dark and muddy; shifts red into bright amber and green into cool cyan.
  static Color _mapProtanomaly(Color color) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.saturation < 0.14) {
      return hsl.lightness > 0.6 ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    }
    final hue = hsl.hue;
    if (hue < 35 || hue >= 330) {
      return const Color(0xFFF59E0B); // Bright warm amber (high luminance)
    }
    if (hue < 75) {
      return const Color(0xFFFACC15); // Bright lemon yellow
    }
    if (hue < 175) {
      return const Color(0xFF06B6D4); // Pure cyan (cool contrast)
    }
    if (hue < 260) {
      return const Color(0xFF3B82F6); // Sky-blue
    }
    return const Color(0xFF8B5CF6); // Purple
  }

  /// Tritanomaly (Blue-Yellow / Blue-weak):
  /// Confuses blue with green, and yellow with pink. Maximizes luminance between blue & warm tones.
  static Color _mapTritanomaly(Color color) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.saturation < 0.14) {
      return hsl.lightness > 0.6 ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    }
    final hue = hsl.hue;
    if (hue >= 180 && hue < 270) {
      return const Color(0xFF1E1B4B); // Very deep navy indigo
    }
    if (hue >= 65 && hue < 180) {
      return const Color(0xFF059669); // Emerald green
    }
    if (hue >= 40 && hue < 65) {
      return const Color(0xFFEA580C); // Warm red-orange
    }
    if (hue < 40 || hue >= 330) {
      return const Color(0xFFDC2626); // High-contrast ruby red
    }
    return const Color(0xFFC026D3); // Magenta
  }

  /// Monochromacy (Achromatopsia / Grayscale with High Contrast):
  /// Translates colors into 4 distinct luminance tiers.
  static Color _mapMonochrome(Color color) {
    final lum = color.computeLuminance();
    if (lum > 0.65) {
      return const Color(0xFFF1F5F9); // Light tier
    }
    if (lum > 0.40) {
      return const Color(0xFF94A3B8); // Mid-light tier
    }
    if (lum > 0.20) {
      return const Color(0xFF475569); // Mid-dark tier
    }
    return const Color(0xFF1E293B); // Dark tier
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

  // =========================================================================
  // Color-Blind Deficiency Image Matrices (4x5 Row-Major GPU Matrices)
  // Preserves full alpha and 1.0 white point sum while transforming RGB hues.
  // =========================================================================

  /// Universal High-Contrast matrix: Enhances saturation & channel separation
  /// without skewing neutral whites/grays.
  static const List<double> universalMatrix = <double>[
    1.15, -0.075, -0.075, 0, 0,
   -0.075,  1.15, -0.075, 0, 0,
   -0.075, -0.075,  1.15, 0, 0,
    0,      0,      0,    1, 0,
  ];

  /// Deuteranomaly (Green-weak): Shifts green wavelengths towards cyan and
  /// boosts separation against warm vermilion hues.
  static const List<double> deuteranomalyMatrix = <double>[
    0.800, 0.200, 0.000, 0, 0,
    0.258, 0.742, 0.000, 0, 0,
    0.000, 0.142, 0.858, 0, 0,
    0.000, 0.000, 0.000, 1, 0,
  ];

  /// Protanomaly (Red-weak): Brightens dark muddy red tones into vibrant amber
  /// and enhances contrast with cool tones.
  static const List<double> protanomalyMatrix = <double>[
    0.817, 0.183, 0.000, 0, 0,
    0.333, 0.667, 0.000, 0, 0,
    0.000, 0.125, 0.875, 0, 0,
    0.000, 0.000, 0.000, 1, 0,
  ];

  /// Tritanomaly (Blue-weak): Maximizes distinction between blue and yellow/pink.
  static const List<double> tritanomalyMatrix = <double>[
    0.967, 0.033, 0.000, 0, 0,
    0.000, 0.733, 0.267, 0, 0,
    0.000, 0.183, 0.817, 0, 0,
    0.000, 0.000, 0.000, 1, 0,
  ];

  /// Monochromacy (Grayscale): High-contrast ITU-R BT.709 luminance conversion.
  static const List<double> monochromeMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ];

  /// Resolves the real-time GPU [ColorFilter] for card photos & illustrations.
  /// Returns `null` when Color-Blind Safe Mode is disabled or image filtering
  /// is toggled off (zero overhead, raw asset rendering).
  static ColorFilter? resolveCardImageFilter({
    bool? isColorBlindMode,
    String? type,
    bool? filterImages,
  }) {
    final enabled = isColorBlindMode ?? colorBlindMode;
    final apply = filterImages ?? colorBlindFilterImages;
    if (!enabled || !apply) {
      return null;
    }
    final effectiveType = type ?? colorBlindType;
    switch (effectiveType) {
      case 'deuteranomaly':
        return const ColorFilter.matrix(deuteranomalyMatrix);
      case 'protanomaly':
        return const ColorFilter.matrix(protanomalyMatrix);
      case 'tritanomaly':
        return const ColorFilter.matrix(tritanomalyMatrix);
      case 'monochrome':
        return const ColorFilter.matrix(monochromeMatrix);
      case 'universal':
      default:
        return const ColorFilter.matrix(universalMatrix);
    }
  }
}
