import 'dart:math' as math;
import 'package:flutter/material.dart';

enum ColorPickerPreviewType {
  appHeader,
  textPreview,
  backgroundPreview;

  // Backwards-compatible aliases
  static const textColor = textPreview;
  static const backgroundColor = backgroundPreview;
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

  static const List<PresetColorItem> textPresets = [
    PresetColorItem('White', Color(0xFFFFFFFF)),
    PresetColorItem('Black', Color(0xFF000000)),
    PresetColorItem('Purple', Color(0xFF7E57C2)),
    PresetColorItem('Green', Color(0xFF00C853)),
    PresetColorItem('Orange', Color(0xFFFF6D00)),
    PresetColorItem('Red', Color(0xFFD50000)),
    PresetColorItem('Magenta', Color(0xFFD500F9)),
    PresetColorItem('Royal Blue', Color(0xFF0288D1)),
  ];

  static const List<PresetColorItem> backgroundPresets = [
    PresetColorItem('White', Color(0xFFFFFFFF)),
    PresetColorItem('Sky Blue', Color(0xFF42A5F5)),
    PresetColorItem('Royal Blue', Color(0xFF0288D1)),
    PresetColorItem('Teal', Color(0xFF00B4D8)),
    PresetColorItem('Mint Green', Color(0xFF81C784)),
    PresetColorItem('Soft Yellow', Color(0xFFFFF176)),
    PresetColorItem('Soft Pink', Color(0xFFF48FB1)),
    PresetColorItem('Lavender', Color(0xFFCE93D8)),
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

  List<PresetColorItem> get _activePresets {
    switch (widget.previewType) {
      case ColorPickerPreviewType.textPreview:
        return ProfessionalColorPickerDialog.textPresets;
      case ColorPickerPreviewType.backgroundPreview:
        return ProfessionalColorPickerDialog.backgroundPresets;
      case ColorPickerPreviewType.appHeader:
        return ProfessionalColorPickerDialog.presets;
    }
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
        return _buildAppHeaderPreview();
      case ColorPickerPreviewType.textPreview:
        return _buildTextPreview(colorScheme, isDark);
      case ColorPickerPreviewType.backgroundPreview:
        return _buildBackgroundPreview(colorScheme, isDark);
    }
  }

  Widget _buildAppHeaderPreview() {
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
  }

  /// Text Color Preview:
  /// Shows 3 sample AAC cards with stable yellow card bodies.
  /// The label text demonstrates text readability:
  /// Card 1: Default black text (#111827)
  /// Card 2: Initial/Current text (or sample purple #7E57C2)
  /// Card 3: Live Selected Candidate text (_currentColor)
  Widget _buildTextPreview(ColorScheme colorScheme, bool isDark) {
    final initialAccent = (widget.initialColor != const Color(0xFF000000) &&
            widget.initialColor != const Color(0xFF111827) &&
            widget.initialColor != const Color(0xFF212121))
        ? widget.initialColor
        : const Color(0xFF7E57C2);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildTextSampleCard(
              label: 'Hello',
              textColor: const Color(0xFF111827),
              cardColor: const Color(0xFFFFF59D),
              semanticsLabel: 'Default black text sample',
              onTap: () => _updateColor(const Color(0xFF000000)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTextSampleCard(
              label: 'Hello',
              textColor: initialAccent,
              cardColor: const Color(0xFFFFF59D),
              semanticsLabel: 'Current saved text sample',
              onTap: () => _updateColor(initialAccent),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTextSampleCard(
              label: 'Hello',
              textColor: _currentColor,
              cardColor: const Color(0xFFFFF59D),
              isCandidate: true,
              semanticsLabel: 'Selected candidate text sample',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSampleCard({
    required String label,
    required Color textColor,
    required Color cardColor,
    bool isCandidate = false,
    String? semanticsLabel,
    VoidCallback? onTap,
  }) {
    final cardContent = Container(
      key: isCandidate ? const ValueKey('candidate_text_card') : null,
      constraints: const BoxConstraints(minHeight: 82),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: isCandidate
            ? Border.all(
                color: const Color(0xFF0288D1),
                width: 2.0,
              )
            : Border.all(
                color: Colors.black.withValues(alpha: 0.12),
                width: 1.0,
              ),
        boxShadow: [
          BoxShadow(
            color: isCandidate
                ? const Color(0xFF0288D1).withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isCandidate ? 5 : 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CustomPaint(
              painter: _StickFigurePainter(
                color: Colors.black87,
                isCrying: false,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Semantics(
        label: semanticsLabel,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return Semantics(
      label: semanticsLabel,
      child: cardContent,
    );
  }

  /// Background Color Preview:
  /// Shows a miniature Simple AAC app layout where the candidate color
  /// visibly fills the board/body canvas beneath the header, with
  /// the sentence composer bar and AAC cards resting on top.
  Widget _buildBackgroundPreview(ColorScheme colorScheme, bool isDark) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Container(
        decoration: BoxDecoration(
          color: _currentColor, // Candidate color fills body area!
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.16),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Mini Top App Header Bar
            _buildMiniAppHeader(),

            // 2. Main Content Body Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sentence Composer Bar
                  _buildMiniSentenceBar(),
                  const SizedBox(height: 8),

                  // 3 AAC Cards
                  _buildMiniCardsRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniAppHeader() {
    return Container(
      height: 30,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0288D1), Color(0xFF01579B)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.push_pin,
              size: 10,
              color: Colors.white,
            ),
          ),
          Container(
            height: 12,
            width: 1.0,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const Expanded(
            child: Text(
              'Simple AAC',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.menu_rounded,
              size: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSentenceBar() {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('😋', style: TextStyle(fontSize: 10)),
                  SizedBox(width: 2.5),
                  Flexible(
                    child: Text(
                      'Happy',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniSentenceAction(
                icon: Icons.backspace_outlined,
                label: 'Delete',
              ),
              const SizedBox(width: 2.5),
              _buildMiniSentenceAction(
                icon: Icons.close_rounded,
                label: 'Clear',
              ),
              const SizedBox(width: 3),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF0288D1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSentenceAction({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: Colors.black54),
          const SizedBox(width: 1.5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniAACCard(
            color: const Color(0xFFFDD835),
            label: 'Hello',
            isStickHappy: true,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildMiniAACCard(
            color: const Color(0xFF90CAF9),
            label: 'Sad',
            isStickSad: true,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildMiniAACCard(
            color: const Color(0xFFEF5350),
            label: 'Angry',
            isImagePlaceholder: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAACCard({
    required Color color,
    required String label,
    bool isStickHappy = false,
    bool isStickSad = false,
    bool isImagePlaceholder = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 2.5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isStickHappy)
            const SizedBox(
              width: 26,
              height: 26,
              child: CustomPaint(
                painter: _StickFigurePainter(
                  color: Colors.black87,
                  isCrying: false,
                ),
              ),
            )
          else if (isStickSad)
            const SizedBox(
              width: 26,
              height: 26,
              child: CustomPaint(
                painter: _StickFigurePainter(
                  color: Colors.black87,
                  isCrying: true,
                ),
              ),
            )
          else if (isImagePlaceholder)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Icon(
                Icons.image_outlined,
                size: 15,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 2),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
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
          children: _activePresets.map((item) {
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

class _StickFigurePainter extends CustomPainter {
  final Color color;
  final bool isCrying;
  const _StickFigurePainter({
    this.color = Colors.black87,
    this.isCrying = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final headRadius = size.height * 0.20;
    final headCenter = Offset(cx, headRadius + 2.0);

    // Head circle
    canvas.drawCircle(headCenter, headRadius, strokePaint);

    // Eyes
    final eyeDx = headRadius * 0.38;
    canvas.drawCircle(Offset(cx - eyeDx, headCenter.dy - 1.0), 1.2, fillPaint);
    canvas.drawCircle(Offset(cx + eyeDx, headCenter.dy - 1.0), 1.2, fillPaint);

    if (isCrying) {
      // Frown
      final mouthRect = Rect.fromCircle(
        center: Offset(cx, headCenter.dy + headRadius * 0.6),
        radius: headRadius * 0.35,
      );
      canvas.drawArc(mouthRect, math.pi * 1.15, math.pi * 0.7, false, strokePaint..strokeWidth = 1.3);

      // Tears
      final tearPaint = Paint()
        ..color = const Color(0xFF42A5F5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx - eyeDx, headCenter.dy + 3.0), 1.2, tearPaint);
      canvas.drawCircle(Offset(cx + eyeDx, headCenter.dy + 3.0), 1.2, tearPaint);
    } else {
      // Smile
      final mouthRect = Rect.fromCircle(
        center: Offset(cx, headCenter.dy + headRadius * 0.1),
        radius: headRadius * 0.45,
      );
      canvas.drawArc(mouthRect, 0.25, math.pi - 0.5, false, strokePaint..strokeWidth = 1.3);
    }

    strokePaint.strokeWidth = 1.8;

    // Body
    final neck = Offset(cx, headCenter.dy + headRadius);
    final crotch = Offset(cx, size.height * 0.72);
    canvas.drawLine(neck, crotch, strokePaint);

    // Arms
    if (isCrying) {
      final shoulderY = neck.dy + 3.0;
      canvas.drawLine(Offset(cx, shoulderY), Offset(cx - size.width * 0.3, shoulderY + size.height * 0.2), strokePaint);
      canvas.drawLine(Offset(cx, shoulderY), Offset(cx + size.width * 0.3, shoulderY + size.height * 0.2), strokePaint);
    } else {
      final shoulderY = neck.dy + 3.0;
      final leftHand = Offset(cx - size.width * 0.36, neck.dy - 2.0);
      final rightHand = Offset(cx + size.width * 0.36, neck.dy - 2.0);
      canvas.drawLine(Offset(cx, shoulderY), leftHand, strokePaint);
      canvas.drawLine(Offset(cx, shoulderY), rightHand, strokePaint);

      // Wave ticks / fingers
      canvas.drawLine(leftHand, Offset(leftHand.dx - 2.5, leftHand.dy - 3.5), strokePaint..strokeWidth = 1.2);
      canvas.drawLine(leftHand, Offset(leftHand.dx + 1.5, leftHand.dy - 4.0), strokePaint..strokeWidth = 1.2);
      canvas.drawLine(rightHand, Offset(rightHand.dx + 2.5, rightHand.dy - 3.5), strokePaint..strokeWidth = 1.2);
      canvas.drawLine(rightHand, Offset(rightHand.dx - 1.5, rightHand.dy - 4.0), strokePaint..strokeWidth = 1.2);
    }

    strokePaint.strokeWidth = 1.8;

    // Legs
    canvas.drawLine(crotch, Offset(cx - size.width * 0.24, size.height - 1.5), strokePaint);
    canvas.drawLine(crotch, Offset(cx + size.width * 0.24, size.height - 1.5), strokePaint);
  }

  @override
  bool shouldRepaint(covariant _StickFigurePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isCrying != isCrying;
}
