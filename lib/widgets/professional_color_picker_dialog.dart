import 'dart:math' as math;
import 'package:flutter/material.dart';

enum ColorPickerPreviewType {
  appHeader,
  textColor,
  backgroundColor,
}

class ProfessionalColorPickerDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color initialColor;
  final ColorPickerPreviewType previewType;
  final ValueChanged<Color> onApply;

  const ProfessionalColorPickerDialog({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.initialColor,
    this.previewType = ColorPickerPreviewType.appHeader,
    required this.onApply,
  }) : super(key: key);

  static const List<PresetColorItem> presets = [
    PresetColorItem('Sky Blue', Color(0xFF42A5F5)),
    PresetColorItem('Royal Blue', Color(0xFF0288D1)),
    PresetColorItem('Teal', Color(0xFF00B4D8)),
    PresetColorItem('Green', Color(0xFF4CAF50)),
    PresetColorItem('Orange', Color(0xFFFB8C00)),
    PresetColorItem('Coral', Color(0xFFE53935)),
    PresetColorItem('Purple', Color(0xFF8E24AA)),
    PresetColorItem('Warm Brown', Color(0xFF8B5A46)),
  ];

  @override
  State<ProfessionalColorPickerDialog> createState() =>
      _ProfessionalColorPickerDialogState();
}

class PresetColorItem {
  final String name;
  final Color color;
  const PresetColorItem(this.name, this.color);
}

class _ProfessionalColorPickerDialogState
    extends State<ProfessionalColorPickerDialog> {
  late Color _currentColor;
  late HSVColor _currentHsv;
  late TextEditingController _hexController;
  bool _isUpdatingFromHex = false;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _currentHsv = HSVColor.fromColor(_currentColor);
    _hexController = TextEditingController(text: _formatHex(_currentColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  static String _formatHex(Color c) {
    final r = c.red.toRadixString(16).padLeft(2, '0').toUpperCase();
    final g = c.green.toRadixString(16).padLeft(2, '0').toUpperCase();
    final b = c.blue.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '$r$g$b';
  }

  void _updateColor(Color newColor, {bool updateHexField = true}) {
    setState(() {
      _currentColor = newColor;
      _currentHsv = HSVColor.fromColor(newColor);
      if (updateHexField && !_isUpdatingFromHex) {
        final newText = _formatHex(newColor);
        if (_hexController.text.toUpperCase() != newText) {
          _hexController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }
      }
    });
  }

  void _onHexChanged(String input) {
    final clean = input.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final val = int.tryParse(clean, radix: 16);
      if (val != null) {
        _isUpdatingFromHex = true;
        _updateColor(Color(0xFF000000 | val), updateHexField: false);
        _isUpdatingFromHex = false;
      }
    }
  }

  bool _isColorSelected(Color a, Color b) {
    return a.red == b.red && a.green == b.green && a.blue == b.blue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colorScheme.surface,
      elevation: 6,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(colorScheme, isDark),
              const SizedBox(height: 16),

              // Live Preview Card
              _buildPreviewCard(colorScheme, isDark),
              const SizedBox(height: 16),

              // Quick Colors Header & Grid/Row
              _buildQuickColorsSection(colorScheme, isDark),
              const SizedBox(height: 16),

              // Custom Color Section
              _buildCustomColorSection(colorScheme, isDark),
              const SizedBox(height: 20),

              // Actions Footer (Cancel & Apply)
              _buildActionsFooter(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                : const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.palette_rounded,
            size: 24,
            color: isDark ? colorScheme.primary : const Color(0xFF0288D1),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 2,
          height: 28,
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.outlineVariant
                : const Color(0xFFBAE6FD),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? colorScheme.onPrimaryContainer
                        : const Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPreviewContent(colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(ColorScheme colorScheme, bool isDark) {
    switch (widget.previewType) {
      case ColorPickerPreviewType.appHeader:
        final lighter = Color.lerp(_currentColor, Colors.white, 0.10)!;
        final darker = Color.lerp(_currentColor, Colors.black, 0.14)!;
        return Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [lighter, darker],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(
                  painter: _MiniWavePainter(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.push_pin,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      height: 18,
                      width: 1.2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Simple AAC',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case ColorPickerPreviewType.textColor:
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _currentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Aa',
                  style: TextStyle(
                    color: _currentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Simple AAC Labels',
                  style: TextStyle(
                    color: _currentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

      case ColorPickerPreviewType.backgroundColor:
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: _currentColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.15),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(child: _buildMiniCardChip('Hello', const Color(0xFFFDD835))),
              const SizedBox(width: 6),
              Flexible(child: _buildMiniCardChip('Sad', const Color(0xFF90CAF9))),
              const SizedBox(width: 6),
              Flexible(child: _buildMiniCardChip('Play', const Color(0xFFA5D6A7))),
            ],
          ),
        );
    }
  }

  Widget _buildMiniCardChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildQuickColorsSection(ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Quick colors',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ProfessionalColorPickerDialog.presets.map((item) {
            final isSelected = _isColorSelected(_currentColor, item.color);
            return Semantics(
              label: 'Preset color ${item.name}',
              button: true,
              selected: isSelected,
              child: InkWell(
                onTap: () => _updateColor(item.color),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(
                            color: isDark ? Colors.white : Colors.black87,
                            width: 2.5,
                          )
                        : Border.all(
                            color: Colors.black.withValues(alpha: 0.12),
                            width: 1.0,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: item.color.computeLuminance() > 0.5
                                ? Colors.black87
                                : Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomColorSection(ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Custom color',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 280;
              final paletteWidth = isNarrow ? constraints.maxWidth : 145.0;
              final paletteHeight = isNarrow ? 120.0 : 130.0;

              final paletteWidget = _SatValPalette(
                hue: _currentHsv.hue,
                saturation: _currentHsv.saturation,
                value: _currentHsv.value,
                width: paletteWidth,
                height: paletteHeight,
                onChanged: (sat, val) {
                  final newHsv = HSVColor.fromAHSV(
                    1.0,
                    _currentHsv.hue,
                    sat,
                    val,
                  );
                  _updateColor(newHsv.toColor());
                },
              );

              final controlsWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hue Slider
                  _HueSlider(
                    hue: _currentHsv.hue,
                    onChanged: (hue) {
                      final newHsv = HSVColor.fromAHSV(
                        1.0,
                        hue,
                        _currentHsv.saturation,
                        _currentHsv.value,
                      );
                      _updateColor(newHsv.toColor());
                    },
                  ),
                  const SizedBox(height: 14),

                  // Swatch + Hex input
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _currentColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.15),
                            width: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              Text(
                                '# ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _hexController,
                                  onChanged: _onHexChanged,
                                  maxLength: 6,
                                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    paletteWidget,
                    const SizedBox(height: 14),
                    controlsWidget,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  paletteWidget,
                  const SizedBox(width: 14),
                  Expanded(child: controlsWidget),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionsFooter(BuildContext context, ColorScheme colorScheme) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            minimumSize: const Size(64, 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            widget.onApply(_currentColor);
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            minimumSize: const Size(96, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Apply'),
        ),
      ],
    );
  }
}

class _SatValPalette extends StatelessWidget {
  final double hue;
  final double saturation;
  final double value;
  final double width;
  final double height;
  final void Function(double sat, double val) onChanged;

  const _SatValPalette({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.width,
    required this.height,
    required this.onChanged,
  });

  void _handleGesture(Offset localPos) {
    final sat = (localPos.dx / width).clamp(0.0, 1.0);
    final val = (1.0 - (localPos.dy / height)).clamp(0.0, 1.0);
    onChanged(sat, val);
  }

  @override
  Widget build(BuildContext context) {
    final pureHue = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    return GestureDetector(
      onPanDown: (d) => _handleGesture(d.localPosition),
      onPanUpdate: (d) => _handleGesture(d.localPosition),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Base hue color
            Container(color: pureHue),
            // Saturation gradient (white -> transparent)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.white, Colors.transparent],
                ),
              ),
            ),
            // Value gradient (transparent -> black)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
            ),
            // Selector Thumb
            Positioned(
              left: (saturation * width - 9).clamp(0.0, width - 18).toDouble(),
              top: ((1.0 - value) * height - 9).clamp(0.0, height - 18).toDouble(),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HueSlider extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const _HueSlider({
    required this.hue,
    required this.onChanged,
  });

  void _handleGesture(Offset localPos, double width) {
    if (width <= 0) return;
    final frac = (localPos.dx / width).clamp(0.0, 1.0);
    onChanged(frac * 360.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbLeft = ((hue / 360.0) * width - 9)
            .clamp(0.0, math.max(0.0, width - 18))
            .toDouble();

        return GestureDetector(
          onPanDown: (d) => _handleGesture(d.localPosition, width),
          onPanUpdate: (d) => _handleGesture(d.localPosition, width),
          child: Container(
            height: 26,
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // Rainbow track
                Container(
                  height: 14,
                  width: width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                // Circular Thumb
                Positioned(
                  left: thumbLeft,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniWavePainter extends CustomPainter {
  const _MiniWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.1,
        size.width * 0.55,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.85,
        size.width,
        size.height * 0.4,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
