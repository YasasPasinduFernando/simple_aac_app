import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Result returned from the PersonalizeSetupDialog.
class PersonalizeSetupResult {
  final String language;
  final Color appBarColor;
  final Color boardColor;

  const PersonalizeSetupResult({
    required this.language,
    required this.appBarColor,
    required this.boardColor,
  });
}

/// Color option descriptor for board background options.
class BoardColorOption {
  final String id;
  final String label;
  final Color color;

  const BoardColorOption(this.id, this.label, this.color);
}

/// Modal bottom sheet dialog for first-launch and settings-based language and theme customization.
///
/// Provides:
/// 1. AAC Language selection: English ('en'), Sinhala ('si'), Tamil ('ta').
/// 2. App Bar & Menu theme color selection (4 curated accessible colors).
/// 3. Board background color selection (6 soft contrast-safe backgrounds).
/// 4. Live interactive preview reflecting all 3 choices in real-time.
/// 5. "Use Defaults" and "Continue" actions.
/// 6. Safe persistence and re-configurability anytime from Settings.
class PersonalizeSetupDialog extends StatefulWidget {
  final String initialLanguage;
  final Color initialAppBarColor;
  final Color initialBoardColor;
  final bool isFirstLaunch;

  const PersonalizeSetupDialog({
    Key? key,
    this.initialLanguage = 'en',
    this.initialAppBarColor = const Color(0xFF0277BD),
    this.initialBoardColor = const Color(0xFFFFFFFF),
    this.isFirstLaunch = true,
  }) : super(key: key);

  /// 4 Curated accessible App Bar & Menu colors
  static const List<Color> appBarColors = [
    Color(0xFF0277BD), // Classic Simple AAC Ocean Blue (Default)
    Color(0xFFCE738E), // Soft Rose / Pink (#D87D9A / #CE738E)
    Color(0xFF8DA885), // Sage Green (#8DA885 / #94AB8E)
    Color(0xFFAF7A62), // Terracotta / Warm Clay (#AF7A62 / #AE7B68)
  ];

  /// 6 Curated soft board background color options
  static const List<BoardColorOption> boardBackgroundOptions = [
    BoardColorOption('white', 'White', Color(0xFFFFFFFF)),
    BoardColorOption('blush', 'Blush', Color(0xFFFAE3E9)),
    BoardColorOption('light_blue', 'Light Blue', Color(0xFFCDE1F9)),
    BoardColorOption('cream', 'Cream', Color(0xFFF8F2D8)),
    BoardColorOption('mint', 'Mint', Color(0xFFD3E8D5)),
    BoardColorOption('charcoal', 'Charcoal', Color(0xFF545D6E)),
  ];

  /// Displays the PersonalizeSetupDialog as a modal bottom sheet.
  static Future<PersonalizeSetupResult?> show(
    BuildContext context, {
    String initialLanguage = 'en',
    Color initialAppBarColor = const Color(0xFF0277BD),
    Color initialBoardColor = const Color(0xFFFFFFFF),
    bool isFirstLaunch = true,
  }) {
    return showModalBottomSheet<PersonalizeSetupResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !isFirstLaunch,
      enableDrag: !isFirstLaunch,
      builder: (ctx) => PersonalizeSetupDialog(
        initialLanguage: initialLanguage,
        initialAppBarColor: initialAppBarColor,
        initialBoardColor: initialBoardColor,
        isFirstLaunch: isFirstLaunch,
      ),
    );
  }

  @override
  State<PersonalizeSetupDialog> createState() => _PersonalizeSetupDialogState();
}

class _PersonalizeSetupDialogState extends State<PersonalizeSetupDialog> {
  late String _selectedLanguage;
  late Color _selectedAppBarColor;
  late Color _selectedBoardColor;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = ['en', 'si', 'ta'].contains(widget.initialLanguage)
        ? widget.initialLanguage
        : 'en';

    // Find closest matching app bar color or fallback to default
    _selectedAppBarColor = PersonalizeSetupDialog.appBarColors.firstWhere(
      (c) => c.value == widget.initialAppBarColor.value,
      orElse: () => PersonalizeSetupDialog.appBarColors.first,
    );

    // Find closest matching board background color or fallback to white
    _selectedBoardColor = PersonalizeSetupDialog.boardBackgroundOptions
        .firstWhere(
          (opt) => opt.color.value == widget.initialBoardColor.value,
          orElse: () => PersonalizeSetupDialog.boardBackgroundOptions.first,
        )
        .color;
  }

  void _handleUseDefaults() {
    Navigator.of(context).pop(
      const PersonalizeSetupResult(
        language: 'en',
        appBarColor: Color(0xFF0277BD),
        boardColor: Color(0xFFFFFFFF),
      ),
    );
  }

  void _handleContinue() {
    Navigator.of(context).pop(
      PersonalizeSetupResult(
        language: _selectedLanguage,
        appBarColor: _selectedAppBarColor,
        boardColor: _selectedBoardColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.92;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDragHandle(),
                  const SizedBox(height: 10),
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildLanguageSection(),
                  const SizedBox(height: 20),
                  _buildAppBarColorSection(),
                  const SizedBox(height: 20),
                  _buildBoardBackgroundSection(),
                  const SizedBox(height: 20),
                  _buildLivePreviewSection(),
                  const SizedBox(height: 22),
                  _buildFooterActions(),
                  const SizedBox(height: 10),
                  _buildSettingsHint(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 38,
        height: 4.5,
        decoration: BoxDecoration(
          color: const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.translate_rounded,
            color: Color(0xFF0284C7),
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalize Simple AAC',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Choose your language and colours',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0284C7),
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.people_alt_outlined,
          title: 'Select AAC Language',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildLanguageCard('en', 'English')),
            const SizedBox(width: 10),
            Expanded(child: _buildLanguageCard('si', 'සිංහල')),
            const SizedBox(width: 10),
            Expanded(child: _buildLanguageCard('ta', 'தமிழ்')),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageCard(String code, String label) {
    final isSelected = _selectedLanguage == code;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = code;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 52,
                  height: 52,
                  child: CustomPaint(
                    painter: _HappyStickFigurePainter(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: -6,
                right: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0284C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.palette_outlined,
          title: 'App Bar & Menu Colour',
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: PersonalizeSetupDialog.appBarColors.map((color) {
            final isSelected = _selectedAppBarColor.value == color.value;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAppBarColor = color;
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: color.withValues(alpha: 0.5), width: 3.5)
                      : null,
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 24,
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

  Widget _buildBoardBackgroundSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.layers_outlined,
          title: 'Board Background',
        ),
        const SizedBox(height: 12),
        Row(
          children: PersonalizeSetupDialog.boardBackgroundOptions.map((opt) {
            final isSelected = _selectedBoardColor.value == opt.color.value;
            final isWhite = opt.color.value == 0xFFFFFFFF;
            final isDark = opt.color.value == 0xFF545D6E;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedBoardColor = opt.color;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: _selectedAppBarColor.withValues(alpha: 0.6),
                                width: 3.0,
                              )
                            : null,
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: opt.color,
                          shape: BoxShape.circle,
                          border: isWhite
                              ? Border.all(color: const Color(0xFFE2E8F0), width: 1.5)
                              : null,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                color: isDark ? Colors.white : _selectedAppBarColor,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        opt.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLivePreviewSection() {
    final helloLabel = switch (_selectedLanguage) {
      'si' => 'ආයුබෝවන්',
      'ta' => 'வணக்கம்',
      _ => 'Hello',
    };

    final waterLabel = switch (_selectedLanguage) {
      'si' => 'වතුර',
      'ta' => 'தண்ணீர்',
      _ => 'Water',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.visibility_outlined,
          title: 'Live Preview',
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _selectedBoardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mini App Bar
              Container(
                height: 38,
                color: _selectedAppBarColor,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.push_pin_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '|   Simple AAC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Mini Board Area
              Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Card 1: Hello
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE082),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 44,
                              height: 44,
                              child: CustomPaint(
                                painter: _HelloStickFigurePainter(),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              helloLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Card 2: Water
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBAE6FD),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 44,
                              height: 44,
                              child: CustomPaint(
                                painter: _WaterStickFigurePainter(),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              waterLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Mini Drawer Strip
                    Container(
                      width: 54,
                      height: 90,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: _selectedAppBarColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMiniDrawerRow(Icons.home_rounded),
                          _buildMiniDrawerRow(Icons.grid_view_rounded),
                          _buildMiniDrawerRow(Icons.settings_rounded),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniDrawerRow(IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: _selectedAppBarColor.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: _selectedAppBarColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _handleUseDefaults,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Use Defaults',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedAppBarColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsHint() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.settings_outlined, size: 13.5, color: Color(0xFF64748B)),
        SizedBox(width: 5),
        Text(
          'Change anytime in Settings',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

/// Custom painter rendering a happy smiling stick figure with raised hands.
class _HappyStickFigurePainter extends CustomPainter {
  const _HappyStickFigurePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const faceColor = Color(0xFFFDE68A);
    const strokeColor = Color(0xFF1E293B);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Fill background circle
    final bgPaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Head
    final headCenter = Offset(center.dx, center.dy - radius * 0.15);
    final headRadius = radius * 0.42;
    canvas.drawCircle(headCenter, headRadius, strokePaint);

    // Eyes
    final eyePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(headCenter.dx - headRadius * 0.35, headCenter.dy - headRadius * 0.1),
      2.0,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(headCenter.dx + headRadius * 0.35, headCenter.dy - headRadius * 0.1),
      2.0,
      eyePaint,
    );

    // Smile
    final smileRect = Rect.fromCircle(
      center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.05),
      radius: headRadius * 0.5,
    );
    canvas.drawArc(smileRect, 0.2, math.pi - 0.4, false, strokePaint);

    // Body
    final neck = Offset(headCenter.dx, headCenter.dy + headRadius);
    final waist = Offset(headCenter.dx, size.height - 2);
    canvas.drawLine(neck, waist, strokePaint);

    // Raised arms \o/
    final shoulder = Offset(headCenter.dx, neck.dy + 4);
    canvas.drawLine(
      shoulder,
      Offset(center.dx - radius * 0.65, headCenter.dy),
      strokePaint,
    );
    canvas.drawLine(
      shoulder,
      Offset(center.dx + radius * 0.65, headCenter.dy),
      strokePaint,
    );

    // Radiating joy lines
    canvas.drawLine(
      Offset(center.dx - radius * 0.65 - 2, headCenter.dy - 4),
      Offset(center.dx - radius * 0.65 - 5, headCenter.dy - 7),
      strokePaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.65 + 2, headCenter.dy - 4),
      Offset(center.dx + radius * 0.65 + 5, headCenter.dy - 7),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stick figure for Live Preview: "Hello"
class _HelloStickFigurePainter extends CustomPainter {
  const _HelloStickFigurePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const strokeColor = Color(0xFF1E293B);
    final center = Offset(size.width / 2, size.height / 2);
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillHead = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.fill;

    // Head
    final headCenter = Offset(center.dx, center.dy - 7);
    const headRadius = 14.0;
    canvas.drawCircle(headCenter, headRadius, fillHead);
    canvas.drawCircle(headCenter, headRadius, strokePaint);

    // Eyes
    final eyePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(headCenter.dx - 4.5, headCenter.dy - 2), 1.5, eyePaint);
    canvas.drawCircle(Offset(headCenter.dx + 4.5, headCenter.dy - 2), 1.5, eyePaint);

    // Smile
    final smileRect = Rect.fromCircle(
      center: Offset(headCenter.dx, headCenter.dy + 1),
      radius: 6,
    );
    canvas.drawArc(smileRect, 0.2, math.pi - 0.4, false, strokePaint);

    // Body
    canvas.drawLine(
      Offset(headCenter.dx, headCenter.dy + headRadius),
      Offset(headCenter.dx, size.height - 4),
      strokePaint,
    );

    // Arms open up \o/
    canvas.drawLine(
      Offset(headCenter.dx, headCenter.dy + headRadius + 3),
      Offset(headCenter.dx - 13, headCenter.dy - 4),
      strokePaint,
    );
    canvas.drawLine(
      Offset(headCenter.dx, headCenter.dy + headRadius + 3),
      Offset(headCenter.dx + 13, headCenter.dy - 4),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stick figure for Live Preview: "Water"
class _WaterStickFigurePainter extends CustomPainter {
  const _WaterStickFigurePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const strokeColor = Color(0xFF1E293B);
    final center = Offset(size.width / 2, size.height / 2);
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillHead = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.fill;

    // Head
    final headCenter = Offset(center.dx, center.dy - 7);
    const headRadius = 14.0;
    canvas.drawCircle(headCenter, headRadius, fillHead);
    canvas.drawCircle(headCenter, headRadius, strokePaint);

    // Eyes
    final eyePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(headCenter.dx - 4.5, headCenter.dy - 3), 1.5, eyePaint);
    canvas.drawCircle(Offset(headCenter.dx + 4.5, headCenter.dy - 3), 1.5, eyePaint);

    // Gasping oval mouth
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy + 4.5),
        width: 6.5,
        height: 7.5,
      ),
      strokePaint,
    );

    // Teardrops / sweat drops
    final tearPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(headCenter.dx - headRadius - 2.5, headCenter.dy - 2),
      2.2,
      tearPaint,
    );
    canvas.drawCircle(
      Offset(headCenter.dx + headRadius + 2.5, headCenter.dy - 2),
      2.2,
      tearPaint,
    );

    // Body
    canvas.drawLine(
      Offset(headCenter.dx, headCenter.dy + headRadius),
      Offset(headCenter.dx, size.height - 4),
      strokePaint,
    );

    // Hands reaching up to cheeks
    canvas.drawLine(
      Offset(headCenter.dx, headCenter.dy + headRadius + 4),
      Offset(headCenter.dx - 10, headCenter.dy + 3),
      strokePaint,
    );
    canvas.drawLine(
      Offset(headCenter.dx, headCenter.dy + headRadius + 4),
      Offset(headCenter.dx + 10, headCenter.dy + 3),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
