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
  final String voiceProfileLabel;
  final VoidCallback? onShowVoiceProfile;
  final VoidCallback onShowAbout;

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
    this.voiceProfileLabel = 'Woman',
    this.onShowVoiceProfile,
    required this.onShowAbout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drawerWidth = (MediaQuery.of(context).size.width * 0.8).clamp(280.0, 360.0);

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
                  icon: Icons.edit_rounded,
                  title: isEditMode ? 'Exit Edit Mode' : 'Enable Edit Mode',
                  subtitle: isEditMode ? 'Currently editing cards' : 'Tap to customize board',
                  active: isEditMode,
                  activeColor: theme.colorScheme.primaryContainer,
                  onTap: onToggleEdit,
                ),
                _buildSwitchItem(
                  icon: Icons.volume_up_rounded,
                  title: 'Tap to Speak',
                  subtitle: 'Speak card label immediately on tap',
                  value: showTtsInput,
                  onChanged: (_) => onToggleTtsInput(),
                ),
                if (onShowVoiceProfile != null)
                  _buildDrawerItem(
                    icon: Icons.record_voice_over_rounded,
                    title: 'Voice Profile',
                    subtitle: voiceProfileLabel,
                    onTap: onShowVoiceProfile!,
                  ),
                _buildSwitchItem(
                  icon: Icons.text_fields_rounded,
                  title: 'Hide TTS Bar',
                  subtitle: 'Hide the speech composer bar',
                  value: hideTtsText,
                  onChanged: (_) => onToggleTtsText(),
                ),
                _buildSwitchItem(
                  icon: Icons.layers_rounded,
                  title: 'Text on Card Image',
                  subtitle: 'Show label overlaid on image',
                  value: useImageOverlayLabel,
                  onChanged: (_) => onToggleCardImageLabel(),
                ),
                _buildSwitchItem(
                  icon: Icons.format_color_text_rounded,
                  title: 'Custom Card Text Color',
                  subtitle: 'Apply theme text color to all cards',
                  value: applyTextColorToCards,
                  onChanged: (_) => onToggleApplyTextColorToCards(),
                ),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'Layout & Display', Icons.dashboard_customize_rounded),
                _buildDrawerItem(
                  icon: Icons.translate_rounded,
                  title: 'Language',
                  subtitle: currentLanguageLabel,
                  onTap: onShowLanguage,
                ),
                _buildDrawerItem(
                  icon: Icons.grid_view_rounded,
                  title: 'Grid Columns',
                  subtitle: '$gridColumns columns',
                  onTap: onShowGrid,
                ),
                _buildDrawerItem(
                  icon: Icons.visibility_rounded,
                  title: 'Visible Cards Count',
                  subtitle: visibleCardsLabel,
                  onTap: onShowVisibleCount,
                ),
                _buildDrawerItem(
                  icon: Icons.screen_rotation_rounded,
                  title: 'Screen Orientation',
                  subtitle: orientationLabel,
                  onTap: onChangeOrientation,
                ),
                _buildSwitchItem(
                  icon: Icons.fullscreen_rounded,
                  title: 'Full Screen Mode',
                  subtitle: 'Hide Android system bars',
                  value: fullScreen,
                  onChanged: (_) => onToggleFullScreen(),
                ),
                _buildDrawerItem(
                  icon: Icons.text_increase_rounded,
                  title: 'TTS Bar Sizing',
                  subtitle: 'Adjust composer bar height',
                  onTap: onShowTtsBarSize,
                ),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'Appearance & Theme', Icons.palette_rounded),
                _buildSwitchItem(
                  icon: isDarkMode ? Icons.dark_mode_rounded : Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: isDarkMode
                      ? 'Full dark look active'
                      : 'Switch on for full dark theme',
                  value: isDarkMode,
                  onChanged: onToggleDarkMode,
                ),
                _buildColorPickerItem(
                  context,
                  icon: Icons.color_lens_rounded,
                  title: 'Primary App Color',
                  swatchColor: primaryColorSwatch,
                  subtitle: isDarkMode ? 'Saved for Normal Mode' : null,
                  onTap: onPickPrimaryColor,
                ),
                _buildColorPickerItem(
                  context,
                  icon: Icons.format_paint_rounded,
                  title: 'Global Text Color',
                  swatchColor: textColorSwatch,
                  subtitle: isDarkMode ? 'Saved for Normal Mode' : null,
                  onTap: onPickTextColor,
                ),
                _buildColorPickerItem(
                  context,
                  icon: Icons.format_color_fill_rounded,
                  title: 'Board Background Color',
                  swatchColor: backgroundColorSwatch,
                  subtitle: isDarkMode ? 'Saved for Normal Mode' : null,
                  onTap: onPickBackgroundColor,
                ),
                const SizedBox(height: 8),
                _buildColorAccessibilityCard(context),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'Cards & Storage', Icons.folder_rounded),
                _buildDrawerItem(
                  icon: Icons.category_rounded,
                  title: 'Category',
                  subtitle: selectedCategory,
                  onTap: onSelectCategory,
                ),
                _buildDrawerItem(
                  icon: Icons.create_new_folder_rounded,
                  title: 'Add New Category',
                  onTap: onAddCategory,
                ),
                _buildDrawerItem(
                  icon: Icons.backup_rounded,
                  title: 'Export Backup',
                  subtitle: 'Save cards and audio to Downloads',
                  onTap: onBackup,
                ),
                _buildDrawerItem(
                  icon: Icons.restore_page_rounded,
                  title: 'Import Restore',
                  subtitle: 'Restore board from zip backup',
                  onTap: onRestore,
                ),
                _buildDrawerItem(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reset Settings',
                  onTap: onResetSettings,
                ),
                if (onManagePermissions != null)
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'App Permissions',
                    subtitle: 'Check or grant Camera & Mic access',
                    onTap: onManagePermissions!,
                  ),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'About', Icons.info_outline_rounded),
                _buildDrawerItem(
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
    final lighter = Color.lerp(headerColor, Colors.white, 0.08)!;
    final darker = Color.lerp(headerColor, Colors.black, 0.14)!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lighter, darker],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: headerTextColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.forum_rounded, color: headerTextColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simple AAC',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: headerTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Sri Lanka',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: headerTextColor.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: headerTextColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'v1.1.0',
                  style: TextStyle(
                    color: headerTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 12, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: theme.colorScheme.primary,
              ),
            ),
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
        : theme.colorScheme.surfaceContainerHigh;
    final borderColor = isOnlineEnabled
        ? onlineColor.withValues(alpha: 0.5)
        : theme.colorScheme.outlineVariant;
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

  Widget _buildColorPickerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color swatchColor,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: _DrawerIconBadge(icon: icon),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 11))
            : null,
        trailing: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: swatchColor,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outline, width: 1.5),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildColorAccessibilityCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: VisualDensity.compact,
              title: const Text(
                'Normal (Custom Colors)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Keep default & customized colors',
                style: TextStyle(fontSize: 11),
              ),
              value: false,
              groupValue: isColorBlindMode,
              onChanged: (v) {
                if (v != null) onChangeColorBlindMode(v);
              },
            ),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: VisualDensity.compact,
              title: const Text(
                'Color-Blind Safe Mode',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'High-contrast color-safe palette',
                style: TextStyle(fontSize: 11),
              ),
              value: true,
              groupValue: isColorBlindMode,
              onChanged: (v) {
                if (v != null) onChangeColorBlindMode(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool active = false,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: active
                ? (activeColor ?? colorScheme.primaryContainer)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            dense: true,
            leading: _DrawerIconBadge(icon: icon, active: active),
            title: Text(title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: subtitle != null
                ? Text(subtitle, style: const TextStyle(fontSize: 12))
                : null,
            onTap: onTap,
          ),
        );
      },
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: _DrawerIconBadge(icon: icon, active: value),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 12))
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
        onTap: () => onChanged(!value),
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
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: active ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 19, color: tint),
    );
  }
}
