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
  final bool isOnlineEnabled;
  final ValueChanged<bool> onToggleOnline;
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
    required this.isOnlineEnabled,
    required this.onToggleOnline,
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
                _buildSectionHeader(context, 'Connectivity & Privacy', Icons.wifi_protected_setup),
                _buildOnlineSwitch(context),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'Communication & Speech', Icons.record_voice_over),
                _buildDrawerItem(
                  icon: Icons.edit,
                  title: isEditMode ? 'Exit Edit Mode' : 'Enable Edit Mode',
                  subtitle: isEditMode ? 'Currently editing cards' : 'Tap to customize board',
                  active: isEditMode,
                  activeColor: theme.colorScheme.primaryContainer,
                  onTap: onToggleEdit,
                ),
                _buildSwitchItem(
                  icon: Icons.volume_up,
                  title: 'Tap to Speak',
                  subtitle: 'Speak card label immediately on tap',
                  value: showTtsInput,
                  onChanged: (_) => onToggleTtsInput(),
                ),
                _buildSwitchItem(
                  icon: Icons.text_fields,
                  title: 'Hide TTS Bar',
                  subtitle: 'Hide the speech composer bar',
                  value: hideTtsText,
                  onChanged: (_) => onToggleTtsText(),
                ),
                _buildSwitchItem(
                  icon: Icons.layers,
                  title: 'Text on Card Image',
                  subtitle: 'Show label overlaid on image',
                  value: useImageOverlayLabel,
                  onChanged: (_) => onToggleCardImageLabel(),
                ),
                _buildSwitchItem(
                  icon: Icons.format_color_text,
                  title: 'Custom Card Text Color',
                  subtitle: 'Apply theme text color to all cards',
                  value: applyTextColorToCards,
                  onChanged: (_) => onToggleApplyTextColorToCards(),
                ),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'Layout & Display', Icons.dashboard_customize),
                _buildDrawerItem(
                  icon: Icons.translate,
                  title: 'Language',
                  subtitle: currentLanguageLabel,
                  onTap: onShowLanguage,
                ),
                _buildDrawerItem(
                  icon: Icons.grid_view,
                  title: 'Grid Columns',
                  subtitle: '$gridColumns columns',
                  onTap: onShowGrid,
                ),
                _buildDrawerItem(
                  icon: Icons.visibility,
                  title: 'Visible Cards Count',
                  subtitle: visibleCardsLabel,
                  onTap: onShowVisibleCount,
                ),
                _buildDrawerItem(
                  icon: Icons.screen_rotation,
                  title: 'Screen Orientation',
                  subtitle: orientationLabel,
                  onTap: onChangeOrientation,
                ),
                _buildSwitchItem(
                  icon: Icons.fullscreen,
                  title: 'Full Screen Mode',
                  subtitle: 'Hide Android system bars',
                  value: fullScreen,
                  onChanged: (_) => onToggleFullScreen(),
                ),
                _buildDrawerItem(
                  icon: Icons.text_increase,
                  title: 'TTS Bar Sizing',
                  subtitle: 'Adjust composer bar height',
                  onTap: onShowTtsBarSize,
                ),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'Appearance & Theme', Icons.palette),
                _buildDrawerItem(
                  icon: Icons.color_lens,
                  title: 'Primary App Color',
                  onTap: onPickPrimaryColor,
                ),
                _buildDrawerItem(
                  icon: Icons.format_paint,
                  title: 'Global Text Color',
                  onTap: onPickTextColor,
                ),
                _buildDrawerItem(
                  icon: Icons.format_color_fill,
                  title: 'Board Background Color',
                  onTap: onPickBackgroundColor,
                ),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'Cards & Storage', Icons.folder),
                _buildDrawerItem(
                  icon: Icons.category,
                  title: 'Category',
                  subtitle: selectedCategory,
                  onTap: onSelectCategory,
                ),
                _buildDrawerItem(
                  icon: Icons.add_circle_outline,
                  title: 'Add New Category',
                  onTap: onAddCategory,
                ),
                _buildDrawerItem(
                  icon: Icons.upload_file,
                  title: 'Export Backup',
                  subtitle: 'Save cards and audio to Downloads',
                  onTap: onBackup,
                ),
                _buildDrawerItem(
                  icon: Icons.download_for_offline,
                  title: 'Import Restore',
                  subtitle: 'Restore board from zip backup',
                  onTap: onRestore,
                ),
                _buildDrawerItem(
                  icon: Icons.restart_alt,
                  title: 'Reset Settings',
                  onTap: onResetSettings,
                ),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'About', Icons.info),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About Simple AAC',
                  subtitle: 'Version 1.0.2',
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: headerColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
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
                  color: headerTextColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.forum, color: headerTextColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simple AAC',
                      style: TextStyle(
                        color: headerTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Sri Lanka',
                      style: TextStyle(
                        color: headerTextColor.withOpacity(0.85),
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
                  color: headerTextColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'v1.0.2',
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
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineSwitch(BuildContext context) {
    return Card(
      elevation: 0,
      color: isOnlineEnabled ? Colors.green.shade50 : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOnlineEnabled ? Colors.green.shade300 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOnlineEnabled ? Icons.wifi : Icons.wifi_off,
                  color: isOnlineEnabled ? Colors.green.shade700 : Colors.grey.shade700,
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
                          color: isOnlineEnabled ? Colors.green.shade900 : Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        isOnlineEnabled ? 'Active (Smart Image Search Enabled)' : 'OFF (100% Strict Offline Privacy)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOnlineEnabled ? Colors.green.shade700 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isOnlineEnabled,
                  activeColor: Colors.green.shade600,
                  onChanged: onToggleOnline,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Enables free CC0/Public Domain image search for cards. When disabled, the app is 100% offline and makes zero network calls.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: active ? (activeColor ?? Colors.blue.shade50) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: Icon(icon, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 12))
            : null,
        onTap: onTap,
      ),
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
        leading: Icon(icon, size: 22),
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
