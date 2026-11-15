import 'package:flutter/material.dart';

import '../utils/theme_accessibility.dart';
import 'preview/live_preview_panel.dart';
import 'styled_dialog_header.dart';

/// Modal dialog with instant Live Preview for configuring Color Vision Support,
/// real color-blindness palettes (Deuteranomaly, Protanomaly, Tritanomaly, Monochrome),
/// card border ring thickness/colors, and bold high-contrast text.
class ColorVisionDialog extends StatefulWidget {
  final bool initialColorBlind;
  final String initialType;
  final double initialBorderWidth;
  final String initialBorderColor;
  final bool initialBoldText;
  final bool initialFilterImages;
  final bool isDarkMode;
  final void Function(
    bool enabled,
    String type,
    double borderWidth,
    String borderColor,
    bool boldText,
    bool filterImages,
  ) onApply;

  const ColorVisionDialog({
    super.key,
    required this.initialColorBlind,
    required this.initialType,
    required this.initialBorderWidth,
    required this.initialBorderColor,
    required this.initialBoldText,
    this.initialFilterImages = true,
    required this.isDarkMode,
    required this.onApply,
  });

  @override
  State<ColorVisionDialog> createState() => _ColorVisionDialogState();
}

class _ColorVisionDialogState extends State<ColorVisionDialog> {
  late bool _enabled;
  late String _type;
  late double _borderWidth;
  late String _borderColor;
  late bool _boldText;
  late bool _filterImages;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialColorBlind;
    _type = widget.initialType;
    _borderWidth = widget.initialBorderWidth.clamp(1.0, 5.0);
    _borderColor = widget.initialBorderColor;
    _boldText = widget.initialBoldText;
    _filterImages = widget.initialFilterImages;
  }

  static const List<_ColorBlindPreset> _presets = [
    _ColorBlindPreset(
      id: 'universal',
      title: 'Universal High-Contrast',
      subtitle: 'Okabe-Ito universal barrier-free palette',
      description: 'Works for all types of color blindness',
    ),
    _ColorBlindPreset(
      id: 'deuteranomaly',
      title: 'Deuteranomaly (Red-Green)',
      subtitle: 'Green-weak adaptation (most common)',
      description: 'Shifts greens to teal/cyan, separates from warm reds',
    ),
    _ColorBlindPreset(
      id: 'protanomaly',
      title: 'Protanomaly (Red-Green)',
      subtitle: 'Red-weak adaptation',
      description: 'Boosts red luminance to gold/amber, prevents dark brown blur',
    ),
    _ColorBlindPreset(
      id: 'tritanomaly',
      title: 'Tritanomaly (Blue-Yellow)',
      subtitle: 'Blue-weak adaptation',
      description: 'High luminance contrast between blues and warm tones',
    ),
    _ColorBlindPreset(
      id: 'monochrome',
      title: 'Monochromacy (Grayscale)',
      subtitle: 'High-contrast achromatic tiers',
      description: '4 distinct brightness levels with thick card borders',
    ),
  ];

  static const List<_BorderColorOption> _borderColors = [
    _BorderColorOption(id: 'auto', label: 'Auto Contrast', color: Color(0xFF1E293B)),
    _BorderColorOption(id: 'black', label: 'Black', color: Colors.black),
    _BorderColorOption(id: 'blue', label: 'Deep Blue', color: Color(0xFF0072B2)),
    _BorderColorOption(id: 'yellow', label: 'Amber Yellow', color: Color(0xFFE69F00)),
    _BorderColorOption(id: 'white', label: 'White', color: Colors.white),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      title: const StyledDialogHeader(
        icon: Icons.visibility_rounded,
        title: 'Color Vision Support',
        subtitle: 'Accessibility palettes & high-contrast card borders',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Live Preview Panel showing 3 sample AAC cards
              LivePreviewPanel(
                title: 'LIVE CARD PREVIEW',
                icon: Icons.remove_red_eye_rounded,
                minHeight: 110,
                maxHeight: 145,
                child: _buildLiveCardsPreview(context),
              ),
              const SizedBox(height: 14),

              // 2. Enable/Disable Master Switch
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Color-Blind Safe Mode',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  _enabled
                      ? 'Custom color-safe palette & borders active'
                      : 'Disabled (Cards show standard default colors)',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                value: _enabled,
                onChanged: (val) => setState(() => _enabled = val),
              ),
              const Divider(height: 18),

              // 3. Color Deficiency Adaptation Mode
              Text(
                'Color Vision Deficiency Mode',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              ..._presets.map((preset) {
                final isSelected = _type == preset.id && _enabled;
                return DialogOptionTile(
                  icon: isSelected ? Icons.check_circle_rounded : Icons.palette_outlined,
                  title: preset.title,
                  subtitle: preset.subtitle,
                  selected: isSelected,
                  badgeText: preset.id == 'universal'
                      ? 'ALL'
                      : preset.id.substring(0, 3).toUpperCase(),
                  onTap: () {
                    setState(() {
                      _enabled = true;
                      _type = preset.id;
                    });
                  },
                );
              }),
              const SizedBox(height: 14),

              // 4. Card Border Thickness Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Card Border Ring Thickness',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_borderWidth.toStringAsFixed(1)} px',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _borderWidth,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                label: '${_borderWidth.toStringAsFixed(1)} px',
                onChanged: _enabled
                    ? (val) => setState(() => _borderWidth = val)
                    : null,
              ),
              const SizedBox(height: 10),

              // 5. Border Ring Color
              Text(
                'Border Ring Color',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _borderColors.map((opt) {
                  final selected = _borderColor == opt.id;
                  return ChoiceChip(
                    label: Text(opt.label, style: const TextStyle(fontSize: 11.5)),
                    selected: selected,
                    onSelected: _enabled
                        ? (_) => setState(() => _borderColor = opt.id)
                        : null,
                    avatar: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: opt.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // 6. High-Legibility Bold Text with Ring
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  Icons.format_bold_rounded,
                  color: _enabled && _boldText ? colorScheme.primary : colorScheme.outline,
                ),
                title: const Text(
                  'Extra-Bold Text with Contrast Ring',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Adds bold letter strokes and shadow ring for maximum reading contrast',
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
                value: _boldText,
                onChanged: _enabled
                    ? (val) => setState(() => _boldText = val)
                    : null,
              ),
              const SizedBox(height: 10),

              // 7. Adapt Card Pictures (Images) to Vision Deficiency
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  Icons.photo_filter_rounded,
                  color: _enabled && _filterImages ? colorScheme.primary : colorScheme.outline,
                ),
                title: const Text(
                  'Adapt Card Pictures to Vision Mode',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Applies color deficiency matrix to card photos and illustrations so picture details remain clear',
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
                value: _filterImages,
                onChanged: _enabled
                    ? (val) => setState(() => _filterImages = val)
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _enabled = false;
              _type = 'universal';
              _borderWidth = 2.5;
              _borderColor = 'auto';
              _boldText = true;
              _filterImages = true;
            });
          },
          child: const Text('Reset'),
        ),
        FilledButton(
          onPressed: () {
            widget.onApply(
              _enabled,
              _type,
              _borderWidth,
              _borderColor,
              _boldText,
              _filterImages,
            );
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildLiveCardsPreview(BuildContext context) {
    // 3 representative cards with distinct hues: Yellow (45°), Blue (210°), Pink/Red (350°)
    final cards = [
      const _SampleCardData(
        label: 'Hello',
        baseColor: Color(0xFFFFF59D), // Yellow
        icon: Icons.accessibility_new_rounded,
        imagePath: 'assets/images/seed/hello.png',
      ),
      const _SampleCardData(
        label: 'Play',
        baseColor: Color(0xFFBBDEFB), // Blue
        icon: Icons.sports_esports_rounded,
        imagePath: 'assets/images/seed/play.png',
      ),
      const _SampleCardData(
        label: 'Happy',
        baseColor: Color(0xFFFFCDD2), // Pink / Red
        icon: Icons.sentiment_very_satisfied_rounded,
        imagePath: 'assets/images/seed/happy.png',
      ),
    ];

    final imageFilter = ThemeAccessibility.resolveCardImageFilter(
      isColorBlindMode: _enabled,
      type: _type,
      filterImages: _filterImages,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: cards.map((data) {
        final surfaceColor = ThemeAccessibility.resolveCardSurface(
          data.baseColor,
          isDarkMode: widget.isDarkMode,
          isColorBlindMode: _enabled,
          type: _type,
        );
        final textColor = ThemeAccessibility.resolveCardTextColor(
          surfaceColor,
          isDarkMode: widget.isDarkMode,
          isColorBlindMode: _enabled,
          applyCustomTextColor: false,
          customTextColor: Colors.white,
        );
        final borderColor = ThemeAccessibility.resolveCardBorderColor(
          isDarkMode: widget.isDarkMode,
          isColorBlindMode: _enabled,
          colorOption: _borderColor,
        );
        final borderWidth = ThemeAccessibility.resolveCardBorderWidth(
          isColorBlindMode: _enabled,
          width: _borderWidth,
        );
        final shadows = ThemeAccessibility.resolveCardTextShadow(
          cardSurface: surfaceColor,
          isColorBlindMode: _enabled,
          isBold: _boldText,
        );

        Widget cardMedia = data.imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  data.imagePath!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    data.icon,
                    size: 26,
                    color: textColor,
                  ),
                ),
              )
            : Icon(
                data.icon,
                size: 26,
                color: textColor,
              );

        if (imageFilter != null && _filterImages) {
          cardMedia = ColorFiltered(
            colorFilter: imageFilter,
            child: cardMedia,
          );
        }

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.35 : 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                cardMedia,
                const SizedBox(height: 4),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: _enabled && _boldText ? FontWeight.w800 : FontWeight.w600,
                    color: textColor,
                    shadows: shadows,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorBlindPreset {
  final String id;
  final String title;
  final String subtitle;
  final String description;

  const _ColorBlindPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}

class _BorderColorOption {
  final String id;
  final String label;
  final Color color;

  const _BorderColorOption({
    required this.id,
    required this.label,
    required this.color,
  });
}

class _SampleCardData {
  final String label;
  final Color baseColor;
  final IconData icon;
  final String? imagePath;

  const _SampleCardData({
    required this.label,
    required this.baseColor,
    required this.icon,
    this.imagePath,
  });
}
