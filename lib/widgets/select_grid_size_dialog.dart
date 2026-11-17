import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';
import 'preview/grid_density_preview.dart';

/// Advanced Responsive Grid Size Dialog supporting 1–30 customizable grid columns.
/// Features a live interactive preview, numeric stepper, slider with ticks,
/// quick presets (1–5, Custom), responsive info box, and a high-density safety warning.
class SelectGridSizeDialog extends StatefulWidget {
  final int currentColumns;
  final List<AACCard> cards;
  final String currentLanguage;
  final double cardTextScale;
  final int cardTextColor;
  final bool isDarkMode;
  final ValueChanged<int> onApply;

  const SelectGridSizeDialog({
    super.key,
    required this.currentColumns,
    this.cards = const [],
    this.currentLanguage = 'en',
    this.cardTextScale = 1.0,
    this.cardTextColor = 0xFF111827,
    this.isDarkMode = false,
    required this.onApply,
  });

  @override
  State<SelectGridSizeDialog> createState() => _SelectGridSizeDialogState();
}

class _SelectGridSizeDialogState extends State<SelectGridSizeDialog> {
  late int _tempColumns;
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _tempColumns = widget.currentColumns.clamp(1, 30);
    _textController = TextEditingController(text: _tempColumns.toString());
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateColumns(int value) {
    final clamped = value.clamp(1, 30);
    setState(() {
      _tempColumns = clamped;
      _textController.text = clamped.toString();
    });
  }

  Future<void> _handleApply() async {
    // If selected > 10 columns and it's a change from currentColumns, show safeguard warning
    if (_tempColumns > 10 && _tempColumns != widget.currentColumns) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber.shade700,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'High Grid Density',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            "You've selected $_tempColumns columns.\n\n"
            "Using many columns may make cards smaller or require horizontal scrolling, especially on phones.\n\n"
            "For easier communication, we recommend 2–5 columns on phones and up to 15 on larger tablets.\n\n"
            "Would you like to continue?",
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
          actions: [
            OutlinedButton(
              key: const ValueKey('grid_warning_back'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Go Back'),
            ),
            FilledButton(
              key: const ValueKey('grid_warning_confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Use $_tempColumns Columns'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }
    }

    widget.onApply(_tempColumns);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final dialogBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    const primaryBlue = Color(0xFF0284C7);

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: primaryBlue,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Select Grid Size',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose card size & column density.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Grid Preview Box
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF4FC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'LIVE GRID PREVIEW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 96,
                        child: GridDensityPreview(
                          columns: _tempColumns,
                          cards: widget.cards,
                          language: widget.currentLanguage,
                          cardTextScale: widget.cardTextScale,
                          cardTextColor: widget.cardTextColor,
                          isDarkMode: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Stepper Row: "Columns per row" + [ - ] [ 12 ] [ + ]
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Columns per row',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: const ValueKey('grid_stepper_minus'),
                            onPressed: _tempColumns > 1
                                ? () => _updateColumns(_tempColumns - 1)
                                : null,
                            icon: const Icon(Icons.remove, size: 18),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            splashRadius: 18,
                            tooltip: 'Decrease columns',
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                          SizedBox(
                            width: 44,
                            child: TextField(
                              key: const ValueKey('grid_columns_input'),
                              controller: _textController,
                              focusNode: _focusNode,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 2,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (val) {
                                final n = int.tryParse(val);
                                if (n != null && n >= 1 && n <= 30) {
                                  setState(() => _tempColumns = n);
                                }
                              },
                              onSubmitted: (val) {
                                final n = int.tryParse(val) ?? _tempColumns;
                                _updateColumns(n.clamp(1, 30));
                              },
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                          IconButton(
                            key: const ValueKey('grid_stepper_plus'),
                            onPressed: _tempColumns < 30
                                ? () => _updateColumns(_tempColumns + 1)
                                : null,
                            icon: const Icon(Icons.add, size: 18),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            splashRadius: 18,
                            tooltip: 'Increase columns',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: primaryBlue,
                    inactiveTrackColor: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFBAE6FD),
                    thumbColor: primaryBlue,
                    overlayColor: primaryBlue.withOpacity(0.12),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                  ),
                  child: Slider(
                    key: const ValueKey('grid_columns_slider'),
                    value: _tempColumns.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    onChanged: (val) => _updateColumns(val.round()),
                  ),
                ),

                // Scale tick marks: 1, 5, 10, 15, 20, 25, 30
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [1, 5, 10, 15, 20, 25, 30].map((tick) {
                      return Text(
                        '$tick',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Presets: [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ] [ Custom ]
                Row(
                  children: [
                    for (int i = 1; i <= 5; i++) ...[
                      Expanded(
                        child: _buildPresetButton(
                          label: '$i',
                          isSelected: _tempColumns == i,
                          onTap: () => _updateColumns(i),
                          isDark: isDark,
                          primaryColor: primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      flex: 2,
                      child: _buildPresetButton(
                        label: 'Custom',
                        isSelected: _tempColumns > 5,
                        onTap: () {
                          if (_tempColumns <= 5) {
                            _updateColumns(12);
                          }
                          _focusNode.requestFocus();
                        },
                        isDark: isDark,
                        primaryColor: primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Selection Status Pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? primaryBlue.withOpacity(0.2)
                          : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_tempColumns ${_tempColumns == 1 ? "column" : "columns"} selected',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Helper Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.swipe_rounded,
                        size: 28,
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'On smaller screens, swipe to see more cards.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'You can type a number up to 30.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Footer Actions: [ Cancel ] [ Reset ] [ Apply ]
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const ValueKey('grid_dialog_cancel'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        key: const ValueKey('grid_dialog_reset'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        onPressed: () => _updateColumns(2),
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('grid_dialog_apply'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _handleApply,
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Material(
      color: isSelected
          ? primaryColor
          : (isDark ? const Color(0xFF1E293B) : Colors.white),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
          ),
        ),
      ),
    );
  }
}
