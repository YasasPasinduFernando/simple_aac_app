import 'package:flutter/material.dart';

class HomeDrawer extends StatelessWidget {
  final String selectedCategory;
  final String currentLanguageLabel;
  final int gridColumns;
  final String visibleCardsLabel;
  final bool isEditMode;
  final bool showTtsInput;
  final String orientationLabel;
  final bool fullScreen;
  final Color headerColor;
  final Color headerTextColor;
  final bool hideTtsText;
  final bool useImageOverlayLabel;
  final bool applyTextColorToCards;
  final bool isDarkMode;
  final bool isColorBlindMode;
  final Color primaryColorSwatch;
  final Color textColorSwatch;
  final Color backgroundColorSwatch;
  final bool isOnlineEnabled;
  final ValueChanged<bool> onToggleOnline;
  final ValueChanged<bool> onToggleDarkMode;
  final ValueChanged<bool> onChangeColorBlindMode;
  final VoidCallback onSelectCategory;
  final VoidCallback onAddCategory;
  final VoidCallback onToggleEdit;
  final VoidCallback onToggleTtsInput;
  final VoidCallback onToggleTtsText;
  final VoidCallback onToggleCardImageLabel;
  final VoidCallback onToggleApplyTextColorToCards;
  final VoidCallback onChangeOrientation;
  final VoidCallback onPickPrimaryColor;
  final VoidCallback onPickTextColor;
  final VoidCallback onPickBackgroundColor;
  final VoidCallback onShowTtsBarSize;
  final VoidCallback onToggleFullScreen;
  final VoidCallback onShowLanguage;
  final VoidCallback onShowGrid;
  final VoidCallback onShowVisibleCount;
  final VoidCallback onBackup;
  final VoidCallback onRestore;
  final VoidCallback onResetSettings;
  final VoidCallback? onManagePermissions;
  final String speechStatusLabel;
  final VoidCallback? onShowOfflineSpeech;
  final VoidCallback onShowAbout;
  final bool enableHaptics;
  final ValueChanged<bool>? onToggleHaptics;

  const HomeDrawer({
    Key? key,
    required this.selectedCategory,
    required this.currentLanguageLabel,
    required this.gridColumns,
    required this.visibleCardsLabel,
    required this.isEditMode,
    required this.showTtsInput,
    required this.orientationLabel,
    required this.fullScreen,
    required this.headerColor,
    required this.headerTextColor,
    required this.hideTtsText,
    required this.useImageOverlayLabel,
    required this.applyTextColorToCards,
    required this.isDarkMode,
    required this.isColorBlindMode,
    required this.primaryColorSwatch,
    required this.textColorSwatch,
    required this.backgroundColorSwatch,
    required this.isOnlineEnabled,
    required this.onToggleOnline,
    required this.onToggleDarkMode,
    required this.onChangeColorBlindMode,
    required this.onSelectCategory,
    required this.onAddCategory,
    required this.onToggleEdit,
    required this.onToggleTtsInput,
    required this.onToggleTtsText,
    required this.onToggleCardImageLabel,
    required this.onToggleApplyTextColorToCards,
    required this.onChangeOrientation,
    required this.onPickPrimaryColor,
    required this.onPickTextColor,
    required this.onPickBackgroundColor,
    required this.onShowTtsBarSize,
    required this.onToggleFullScreen,
    required this.onShowLanguage,
    required this.onShowGrid,
    required this.onShowVisibleCount,
    required this.onBackup,
    required this.onRestore,
    required this.onResetSettings,
    this.onManagePermissions,
    this.speechStatusLabel = 'Automatic offline voice',
    this.onShowOfflineSpeech,
    required this.onShowAbout,
    this.enableHaptics = true,
    this.onToggleHaptics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drawerWidth = (MediaQuery.of(context).size.width * 0.82).clamp(280.0, 360.0);

    return Drawer(
      width: drawerWidth,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildSectionHeader(context, 'Connectivity & Privacy', Icons.wifi_protected_setup_rounded),
                _buildOnlineSwitch(context),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'Communication & Speech', Icons.record_voice_over_rounded),
                _buildDrawerItem(
                  context,
                  icon: Icons.edit_rounded,
                  title: isEditMode ? 'Exit Edit Mode' : 'Enable Edit Mode',
                  subtitle: isEditMode ? 'Currently editing cards' : 'Tap to customize board',
                  active: isEditMode,
                  activeColor: theme.colorScheme.primaryContainer,
                  onTap: onToggleEdit,
                ),
                _buildSwitchItem(
                  context,
                  icon: Icons.volume_up_rounded,
                  title: 'Tap to Speak',
                  subtitle: 'Speak card label immediately on tap',
                  value: showTtsInput,
                  onChanged: (_) => onToggleTtsInput(),
                ),
                if (onShowOfflineSpeech != null)
                  _buildDrawerItem(
                    context,
                    icon: Icons.record_voice_over_rounded,
                    title: 'Offline Speech',
                    subtitle: speechStatusLabel,
                    onTap: onShowOfflineSpeech!,
                  ),
                _buildSwitchItem(
                  context,
                  icon: Icons.text_fields_rounded,
                  title: 'Hide TTS Bar',
                  subtitle: 'Hide the speech composer bar',
                  value: hideTtsText,
                  onChanged: (_) => onToggleTtsText(),
                ),
                if (onToggleHaptics != null)
                  _buildSwitchItem(
                    context,
                    icon: Icons.vibration_rounded,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibration and pop feel when tapping cards',
                    value: enableHaptics,
                    onChanged: onToggleHaptics!,
                  ),
                _buildSwitchItem(
                  context,
                  icon: Icons.layers_rounded,
                  title: 'Text on Card Image',
                  subtitle: 'Show label overlaid on image',
                  value: useImageOverlayLabel,
                  onChanged: (_) => onToggleCardImageLabel(),
                ),
                _buildSwitchItem(
                  context,
                  icon: Icons.format_color_text_rounded,
                  title: 'Custom Card Text Color',
                  subtitle: 'Apply theme text color to all cards',
                  value: applyTextColorToCards,
                  onChanged: (_) => onToggleApplyTextColorToCards(),
                ),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'Layout & Display', Icons.dashboard_customize_rounded),
                _buildDrawerItem(
                  context,
                  icon: Icons.translate_rounded,
                  title: 'Language',
                  subtitle: currentLanguageLabel,
                  onTap: onShowLanguage,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.grid_view_rounded,
                  title: 'Grid Columns',
                  subtitle: '$gridColumns columns',
                  onTap: onShowGrid,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.visibility_rounded,
                  title: 'Visible Cards Count',
                  subtitle: visibleCardsLabel,
                  onTap: onShowVisibleCount,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.screen_rotation_rounded,
                  title: 'Screen Orientation',
                  subtitle: orientationLabel,
                  onTap: onChangeOrientation,
                ),
                _buildSwitchItem(
                  context,
                  icon: Icons.fullscreen_rounded,
                  title: 'Full Screen Mode',
                  subtitle: 'Hide Android system bars',
                  value: fullScreen,
                  onChanged: (_) => onToggleFullScreen(),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.text_increase_rounded,
                  title: 'TTS Bar Sizing',
                  subtitle: 'Adjust composer bar height',
                  onTap: onShowTtsBarSize,
                ),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'Appearance & Theme', Icons.palette_rounded),
                _buildAppearanceThemeSection(context),
                const SizedBox(height: 8),
                _buildColorAccessibilityCard(context),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'Cards & Storage', Icons.folder_rounded),
                _buildDrawerItem(
                  context,
                  icon: Icons.category_rounded,
                  title: 'Category',
                  subtitle: selectedCategory,
                  onTap: onSelectCategory,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.create_new_folder_rounded,
                  title: 'Add New Category',
                  onTap: onAddCategory,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.backup_rounded,
                  title: 'Export Backup',
                  subtitle: 'Save cards and audio to Downloads',
                  onTap: onBackup,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.restore_page_rounded,
                  title: 'Import Restore',
                  subtitle: 'Restore board from zip backup',
                  onTap: onRestore,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.restart_alt_rounded,
                  title: 'Reset Settings',
                  onTap: onResetSettings,
                ),
                if (onManagePermissions != null)
                  _buildDrawerItem(
                    context,
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'App Permissions',
                    subtitle: 'Check or grant Camera & Mic access',
                    onTap: onManagePermissions!,
                  ),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'About', Icons.info_outline_rounded),
                _buildDrawerItem(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'About Simple AAC',
                  subtitle: 'Version 1.1.0',
                  onTap: onShowAbout,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final lighter = Color.lerp(headerColor, Colors.white, 0.12)!;
    final darker = Color.lerp(headerColor, Colors.black, 0.18)!;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lighter, darker],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _DrawerHeaderWavePainter(waveColor: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 18,
              left: 16,
              right: 16,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isVeryCompact = constraints.maxWidth < 240;
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                      maxWidth: constraints.maxWidth < 280 ? 280 : constraints.maxWidth,
                    ),
                    child: Row(
                      children: [
                        // Branded squircle communication icon
                        Container(
                          width: isVeryCompact ? 38 : 42,
                          height: isVeryCompact ? 38 : 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.32),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            Icons.chat_bubble_rounded,
                            color: Colors.white,
                            size: isVeryCompact ? 20 : 22,
                          ),
                        ),
                        // Subtle vertical divider line
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: isVeryCompact ? 8 : 12),
                          width: 1.5,
                          height: isVeryCompact ? 22 : 26,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        // Title and subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Simple AAC',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isVeryCompact ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Sri Lanka',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: isVeryCompact ? 11.5 : 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Version badge pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'v1.1.0',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 14, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceThemeSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2230) : const Color(0xFFF1F6FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2E384D) : const Color(0xFFD6E4F5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Row 1: Dark Mode Switch
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B26) : Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isDark ? const Color(0xFF2A3447) : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => onToggleDarkMode(!isDarkMode),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      _DrawerIconBadge(
                        icon: isDarkMode ? Icons.dark_mode_rounded : Icons.dark_mode_outlined,
                        active: isDarkMode,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Dark Mode',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              isDarkMode
                                  ? 'Full dark look active'
                                  : 'Switch on for full dark theme',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isDarkMode,
                        onChanged: onToggleDarkMode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Row 2: Primary App Color with Mini UI Header Preview
          _buildColorPickerRow(
            context,
            icon: Icons.palette_rounded,
            title: 'Primary App Color',
            subtitle: isDarkMode ? 'Saved for Normal Mode' : 'App bars, headers & key UI',
            previewChip: _PrimaryColorPreviewChip(
              color: primaryColorSwatch,
              isDarkMode: isDark,
            ),
            onTap: onPickPrimaryColor,
          ),

          // Row 3: Global Text Color with Aa Sample Text Preview
          _buildColorPickerRow(
            context,
            icon: Icons.format_size_rounded,
            title: 'Global Text Color',
            subtitle: isDarkMode ? 'Saved for Normal Mode' : 'Text across the entire app',
            previewChip: _TextColorPreviewChip(
              color: textColorSwatch,
              isDarkMode: isDark,
            ),
            onTap: onPickTextColor,
          ),

          // Row 4: Board Background Color with 3 AAC Cards Canvas Preview
          _buildColorPickerRow(
            context,
            icon: Icons.layers_rounded,
            title: 'Board Background Color',
            subtitle: isDarkMode ? 'Saved for Normal Mode' : 'Background of communication boards',
            previewChip: _BackgroundColorPreviewChip(
              color: backgroundColorSwatch,
              isDarkMode: isDark,
            ),
            isLast: true,
            onTap: onPickBackgroundColor,
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickerRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget previewChip,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF161B26) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2A3447) : const Color(0xFFE2E8F0);

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _DrawerIconBadge(icon: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                previewChip,
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorAccessibilityCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2230) : const Color(0xFFF1F6FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E384D) : const Color(0xFFD6E4F5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Color Vision Support',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _ColorBlindRadioOption(
            title: 'Normal (Custom Colors)',
            subtitle: 'Keep default & customized colors',
            selected: !isColorBlindMode,
            onTap: () => onChangeColorBlindMode(false),
          ),
          const SizedBox(height: 2),
          _ColorBlindRadioOption(
            title: 'Color-Blind Safe Mode',
            subtitle: 'High-contrast color-safe palette',
            selected: isColorBlindMode,
            onTap: () => onChangeColorBlindMode(true),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineSwitch(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onlineColor = isColorBlindMode ? const Color(0xFF0072B2) : Colors.green;
    final cardBg = isOnlineEnabled
        ? (isDark
            ? onlineColor.withValues(alpha: 0.18)
            : (isColorBlindMode ? Colors.blue.shade50 : Colors.green.shade50))
        : (isDark ? const Color(0xFF161B26) : Colors.white);
    final borderColor = isOnlineEnabled
        ? onlineColor.withValues(alpha: 0.5)
        : (isDark ? const Color(0xFF2A3447) : const Color(0xFFE2E8F0));
    final accentText = isOnlineEnabled
        ? (isDark
            ? (isColorBlindMode ? Colors.lightBlue.shade200 : Colors.green.shade300)
            : (isColorBlindMode ? const Color(0xFF005A8D) : Colors.green.shade800))
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOnlineEnabled ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: accentText,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Online Features',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        isOnlineEnabled
                            ? 'Active (Smart Image Search Enabled)'
                            : 'OFF (100% Strict Offline Privacy)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: accentText,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isOnlineEnabled,
                  activeThumbColor: isColorBlindMode
                      ? const Color(0xFF0072B2)
                      : Colors.green.shade600,
                  onChanged: onToggleOnline,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Enables free child-safe image search for cards. When disabled, the app is 100% offline and makes zero network calls.',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    bool active = false,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = active
        ? (activeColor ?? colorScheme.primaryContainer)
        : (isDark ? const Color(0xFF161B26) : Colors.white);
    final cardBorder = active
        ? colorScheme.primary.withValues(alpha: 0.5)
        : (isDark ? const Color(0xFF2A3447) : const Color(0xFFE2E8F0));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _DrawerIconBadge(icon: icon, active: active),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1.5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: active
                                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: active
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF161B26) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2A3447) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _DrawerIconBadge(icon: icon, active: value),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1.5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerIconBadge extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _DrawerIconBadge({
    required this.icon,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = active ? colorScheme.onPrimaryContainer : colorScheme.primary;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: active ? 0.22 : 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: tint),
    );
  }
}

/// Mini UI preview chip for Primary App Color (reflects header chrome and canvas)
class _PrimaryColorPreviewChip extends StatelessWidget {
  final Color color;
  final bool isDarkMode;

  const _PrimaryColorPreviewChip({
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Primary color preview: #${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
      child: Container(
        width: 86,
        height: 38,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.14),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.06),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // Mini Header Bar in selected primary color
            Container(
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(color, Colors.white, 0.12)!,
                    Color.lerp(color, Colors.black, 0.16)!,
                  ],
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.chat_bubble_rounded,
                    size: 8,
                    color: Colors.white,
                  ),
                  SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      'Simple AAC',
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6.8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Mini Body Area with Placeholder Blocks
            Expanded(
              child: Container(
                color: isDarkMode ? const Color(0xFF232A38) : const Color(0xFFEDF2F7),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white24 : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
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

/// Text preview chip for Global Text Color ("Aa Sample Text")
class _TextColorPreviewChip extends StatelessWidget {
  final Color color;
  final bool isDarkMode;

  const _TextColorPreviewChip({
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Adaptive contrast backing ensures text is always legible
    final lum = color.computeLuminance();
    final bg = lum > 0.65
        ? const Color(0xFF1E293B)
        : (isDarkMode ? const Color(0xFFF8FAFC) : Colors.white);

    return Semantics(
      label: 'Global text color preview: #${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
      child: Container(
        width: 96,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.14),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        // Shield internal preview text from extreme system font scaling
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Aa',
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Sample Text',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    color: color,
                    fontSize: 9.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Board preview chip for Board Background Color (displays board canvas with 3 miniature AAC cards)
class _BackgroundColorPreviewChip extends StatelessWidget {
  final Color color;
  final bool isDarkMode;

  const _BackgroundColorPreviewChip({
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Board background color preview: #${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
      child: Container(
        width: 92,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
        decoration: BoxDecoration(
          color: color, // The candidate board background color
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.16),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.06),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tiny AAC Card 1: Yellow with Stick Figure
            _MiniCard(
              cardBg: Color(0xFFFFF59D),
              child: CustomPaint(
                size: Size(11, 14),
                painter: _MiniStickFigurePainter(color: Color(0xFF111827)),
              ),
            ),
            // Tiny AAC Card 2: Soft Blue with Cup/Drink
            _MiniCard(
              cardBg: Color(0xFFBBDEFB),
              child: Icon(
                Icons.local_cafe_rounded,
                size: 11,
                color: Color(0xFF0D47A1),
              ),
            ),
            // Tiny AAC Card 3: Soft Pink with Apple/Food
            _MiniCard(
              cardBg: Color(0xFFFFCDD2),
              child: Icon(
                Icons.apple_rounded,
                size: 11,
                color: Color(0xFFB71C1C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final Color cardBg;
  final Widget child;

  const _MiniCard({
    required this.cardBg,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 23,
      height: 29,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.18),
          width: 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 1,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _MiniStickFigurePainter extends CustomPainter {
  final Color color;

  const _MiniStickFigurePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    // Head
    canvas.drawCircle(Offset(cx, 3), 2.2, paint);
    // Body spine
    canvas.drawLine(Offset(cx, 5.2), Offset(cx, 10), paint);
    // Waving arms
    canvas.drawLine(Offset(cx, 6.5), const Offset(1, 4), paint);
    canvas.drawLine(Offset(cx, 6.5), Offset(size.width - 1, 4), paint);
    // Legs
    canvas.drawLine(Offset(cx, 10), Offset(2, size.height - 1), paint);
    canvas.drawLine(Offset(cx, 10), Offset(size.width - 2, size.height - 1), paint);
  }

  @override
  bool shouldRepaint(covariant _MiniStickFigurePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ColorBlindRadioOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ColorBlindRadioOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;

    return Semantics(
      checked: selected,
      label: '$title: $subtitle',
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2, right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? primary : colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: selected
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary,
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerHeaderWavePainter extends CustomPainter {
  final Color waveColor;

  const _DrawerHeaderWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Gentle organic bottom-right wave
    final path1 = Path()
      ..moveTo(size.width * 0.30, size.height)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.62,
        size.width * 0.78,
        size.height * 0.74,
      )
      ..quadraticBezierTo(
        size.width * 0.90,
        size.height * 0.78,
        size.width,
        size.height * 0.48,
      )
      ..lineTo(size.width, size.height)
      ..close();

    final paint1 = Paint()
      ..color = waveColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path1, paint1);

    // Accent secondary top-right curve
    final path2 = Path()
      ..moveTo(size.width * 0.60, 0)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.35,
        size.width,
        size.height * 0.20,
      )
      ..lineTo(size.width, 0)
      ..close();

    final paint2 = Paint()
      ..color = waveColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _DrawerHeaderWavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor;
}
