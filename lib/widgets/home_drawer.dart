import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tutorial_service.dart';
import '../utils/theme_accessibility.dart';
import 'tutorial/mini_guides_dialog.dart';

class HomeDrawer extends StatelessWidget {
  final String selectedCategory;
  final String currentLanguageLabel;
  final int gridColumns;
  final String visibleCardsLabel;
  final bool isEditMode;
  final bool showCardLabels;
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
  final Color cardTextColorSwatch;
  final Color cardLabelBgColorSwatch;
  final bool isOnlineEnabled;
  final ValueChanged<bool> onToggleOnline;
  final ValueChanged<bool> onToggleDarkMode;
  final ValueChanged<bool> onChangeColorBlindMode;
  final VoidCallback? onOpenColorBlindSettings;
  final VoidCallback onSelectCategory;
  final VoidCallback onAddCategory;
  final VoidCallback onToggleEdit;
  final VoidCallback? onToggleShowCardLabels;
  final VoidCallback onToggleTtsInput;
  final VoidCallback onToggleTtsText;
  final VoidCallback onToggleCardImageLabel;
  final VoidCallback onToggleApplyTextColorToCards;
  final VoidCallback onChangeOrientation;
  final VoidCallback onPickPrimaryColor;
  final VoidCallback onPickTextColor;
  final VoidCallback onPickBackgroundColor;
  final VoidCallback? onOpenPersonalizeSetup;
  final VoidCallback? onPickCardTextColor;
  final VoidCallback? onPickCardLabelBgColor;
  final VoidCallback onShowTtsBarSize;
  final VoidCallback onToggleFullScreen;
  final VoidCallback onShowLanguage;
  final VoidCallback onShowGrid;
  final VoidCallback onShowVisibleCount;
  final String cardTextScaleLabel;
  final VoidCallback? onShowCardTextSize;
  final VoidCallback onBackup;
  final VoidCallback onRestore;
  final VoidCallback? onShowStarterPack;
  final VoidCallback? onOpenRecycleBin;
  final VoidCallback onResetSettings;
  final VoidCallback? onManagePermissions;
  final String speechStatusLabel;
  final VoidCallback? onShowOfflineSpeech;
  final VoidCallback onShowAbout;
  final VoidCallback? onReplayTutorial;
  final VoidCallback? onShowMiniGuides;
  final Key? resizeButtonKey;
  final Key? editModeKey;
  final bool enableHaptics;
  final ValueChanged<bool>? onToggleHaptics;
  final bool isExpanded;
  final ValueChanged<bool>? onToggleExpanded;
  final VoidCallback? onClose;
  final bool? showGestureHint;
  final bool isCaregiverLockEnabled;
  final ValueChanged<bool>? onToggleCaregiverLock;
  final bool openSettingsFullScreen;
  final ValueChanged<bool>? onToggleOpenSettingsFullScreen;
  final bool disableBackCardInPinMode;
  final ValueChanged<bool>? onToggleDisableBackCardInPinMode;

  const HomeDrawer({
    Key? key,
    required this.selectedCategory,
    required this.currentLanguageLabel,
    required this.gridColumns,
    required this.visibleCardsLabel,
    required this.isEditMode,
    this.showCardLabels = true,
    this.onToggleShowCardLabels,
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
    this.cardTextColorSwatch = const Color(0xFF111827),
    this.cardLabelBgColorSwatch = const Color(0xFFF4F1EB),
    required this.isOnlineEnabled,
    required this.onToggleOnline,
    required this.onToggleDarkMode,
    required this.onChangeColorBlindMode,
    this.onOpenColorBlindSettings,
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
    this.onOpenPersonalizeSetup,
    this.onPickCardTextColor,
    this.onPickCardLabelBgColor,
    required this.onShowTtsBarSize,
    required this.onToggleFullScreen,
    required this.onShowLanguage,
    required this.onShowGrid,
    required this.onShowVisibleCount,
    this.cardTextScaleLabel = 'Medium (100%)',
    this.onShowCardTextSize,
    required this.onBackup,
    required this.onRestore,
    this.onShowStarterPack,
    this.onOpenRecycleBin,
    required this.onResetSettings,
    this.onManagePermissions,
    this.speechStatusLabel = 'Automatic offline voice',
    this.onShowOfflineSpeech,
    required this.onShowAbout,
    this.onReplayTutorial,
    this.onShowMiniGuides,
    this.resizeButtonKey,
    this.editModeKey,
    this.enableHaptics = true,
    this.onToggleHaptics,
    this.isExpanded = false,
    this.onToggleExpanded,
    this.onClose,
    this.showGestureHint,
    this.isCaregiverLockEnabled = false,
    this.onToggleCaregiverLock,
    this.openSettingsFullScreen = false,
    this.onToggleOpenSettingsFullScreen,
    this.disableBackCardInPinMode = false,
    this.onToggleDisableBackCardInPinMode,
  }) : super(key: key);

  void _handleClose(BuildContext context) {
    if (onClose != null) {
      onClose!();
      return;
    }
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isEndDrawerOpen) {
      scaffold.closeEndDrawer();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final standardWidth = (screenWidth * 0.82).clamp(280.0, 360.0);
    final drawerWidth = isExpanded ? screenWidth : standardWidth;

    return _SettingsDrawerDiscoveryHost(
      isExpanded: isExpanded,
      onToggleExpanded: onToggleExpanded,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: drawerWidth,
        child: Drawer(
          width: drawerWidth,
          child: Stack(
            children: [
              Column(
                children: [
                  _DrawerGestureHandler(
                    isExpanded: isExpanded,
                    onToggleExpanded: onToggleExpanded,
                    onClose: () => _handleClose(context),
                    child: _buildHeader(context),
                  ),
                  _DrawerGestureHandler(
                    isExpanded: isExpanded,
                    onToggleExpanded: onToggleExpanded,
                    onClose: () => _handleClose(context),
                    child: _DrawerGestureHintBar(
                      isExpanded: isExpanded,
                      forceShow: showGestureHint,
                      onExpand: () {
                        DrawerGestureHintHelper.markExpansionDiscovered();
                        onToggleExpanded?.call(true);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      key: const PageStorageKey('settings_drawer_list_view'),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                _buildSectionHeader(context, 'Connectivity & Privacy', Icons.wifi_protected_setup_rounded),
                _buildOnlineSwitch(context),
                const SizedBox(height: 12),

                _buildSectionHeader(context, 'Communication & Speech', Icons.record_voice_over_rounded),
                _buildDrawerItem(
                  context,
                  itemKey: editModeKey,
                  icon: Icons.edit_rounded,
                  title: isEditMode ? 'Exit Edit Mode' : 'Enable Edit Mode',
                  subtitle: isEditMode ? 'Currently editing cards' : 'Tap to customize board',
                  active: isEditMode,
                  activeColor: theme.colorScheme.primaryContainer,
                  onTap: () {
                    TutorialService.instance.notifyEditModeEnabled();
                    onToggleEdit();
                  },
                ),
                _buildSwitchItem(
                  context,
                  icon: Icons.fingerprint_rounded,
                  title: 'Caregiver Lock',
                  subtitle: isCaregiverLockEnabled
                      ? 'Lock active: Phone biometrics or PIN required'
                      : 'Protect board & settings with phone fingerprint, face, pattern or PIN',
                  value: isCaregiverLockEnabled,
                  onChanged: (val) => onToggleCaregiverLock?.call(val),
                ),
                _buildSwitchItem(
                  context,
                  itemKey: const ValueKey('open_settings_full_screen_switch'),
                  icon: Icons.open_in_full_rounded,
                  title: 'Open Settings Full Screen',
                  subtitle: 'Automatically expand Settings when opened',
                  value: openSettingsFullScreen,
                  onChanged: (val) => onToggleOpenSettingsFullScreen?.call(val),
                ),
                _buildSwitchItem(
                  context,
                  itemKey: const ValueKey('disable_back_card_in_pin_mode_switch'),
                  icon: Icons.arrow_back_rounded,
                  title: 'Disable Back Card in Pin Mode',
                  subtitle: 'Hide folder Back cards while Pin Mode is active.',
                  value: disableBackCardInPinMode,
                  onChanged: (val) =>
                      onToggleDisableBackCardInPinMode?.call(val),
                ),
                if (onShowOfflineSpeech != null)
                  _buildDrawerItem(
                    context,
                    icon: Icons.record_voice_over_rounded,
                    title: 'Offline Speech Test',
                    subtitle: speechStatusLabel,
                    onTap: onShowOfflineSpeech!,
                  ),
                _buildSwitchItem(
                  context,
                  icon: Icons.label_rounded,
                  title: 'Show Card Labels',
                  subtitle: 'Show or hide text labels on all cards',
                  value: showCardLabels,
                  onChanged: (_) => onToggleShowCardLabels?.call(),
                ),
                _buildSwitchItem(
                  context,
                  icon: Icons.view_headline_rounded,
                  title: 'Show Sentence Bar',
                  subtitle: 'Show the top bar for building and speaking sentences',
                  value: showTtsInput,
                  onChanged: (_) => onToggleTtsInput(),
                ),
                if (showTtsInput)
                  _buildSwitchItem(
                    context,
                    icon: Icons.text_fields_rounded,
                    title: 'Hide Text in Sentence Bar',
                    subtitle: 'Show only card pictures in the sentence bar',
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
                  title: 'Overlay Card Labels on Images',
                  subtitle:
                      'Show card labels over images instead of below them',
                  value: useImageOverlayLabel,
                  onChanged: (_) => onToggleCardImageLabel(),
                ),
                _buildSwitchItem(
                  context,
                  icon: Icons.format_color_text_rounded,
                  title: 'Custom Card Text Color',
                  subtitle: 'Apply custom color to all card labels',
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
                  subtitle:
                      '$gridColumns ${gridColumns == 1 ? "column" : "columns"}',
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
                  icon: Icons.format_size_rounded,
                  title: 'Card Text Size',
                  subtitle: cardTextScaleLabel,
                  onTap: onShowCardTextSize ?? () {},
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.text_increase_rounded,
                  title: 'TTS Bar Settings',
                  subtitle: 'Bar size, Delete & Clear buttons',
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
                  title: 'Choose Categories',
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
                if (onShowStarterPack != null)
                  _buildDrawerItem(
                    context,
                    itemKey: const ValueKey('drawer_starter_pack_item'),
                    icon: Icons.auto_awesome_rounded,
                    title: 'Starter Card Pack',
                    subtitle: '128 cards in 13 categories (Sri Lanka)',
                    onTap: onShowStarterPack!,
                  ),
                if (onOpenRecycleBin != null)
                  _buildDrawerItem(
                    context,
                    itemKey: const ValueKey('drawer_recycle_bin_item'),
                    icon: Icons.restore_from_trash_outlined,
                    title: 'Recycle Bin',
                    subtitle: 'Recover deleted cards for up to 30 days',
                    onTap: onOpenRecycleBin!,
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

                _buildSectionHeader(context, 'Help & Guides', Icons.help_outline_rounded),
                _buildDrawerItem(
                  context,
                  icon: Icons.school_rounded,
                  title: 'Interactive App Guide',
                  subtitle: 'Replay step-by-step walkthrough anytime',
                  onTap: () {
                    _handleClose(context);
                    if (onReplayTutorial != null) {
                      onReplayTutorial!();
                    } else {
                      TutorialService.instance.resetAndReplayTour();
                    }
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.menu_book_rounded,
                  title: 'Feature Guides',
                  subtitle: 'PIN, Backup, Permissions & Privacy',
                  onTap: () {
                    if (onShowMiniGuides != null) {
                      onShowMiniGuides!();
                    } else {
                      MiniGuidesDialog.show(context, language: 'en');
                    }
                  },
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
      // Left edge swipe gesture handle strip (24dp) for compact mode below header
      if (!isExpanded)
        Positioned(
          left: 0,
          top: 130,
          bottom: 0,
          width: 24,
          child: _DrawerGestureHandler(
            isExpanded: isExpanded,
            onToggleExpanded: onToggleExpanded,
            onClose: () => _handleClose(context),
            child: const SizedBox.expand(),
          ),
        ),
    ],
  ),
),
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
              top: MediaQuery.of(context).padding.top + 14,
              bottom: 16,
              left: 14,
              right: 14,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Expand / Shrink Chevron Button
                        Semantics(
                          button: true,
                          label: isExpanded ? 'Shrink Settings' : 'Expand Settings',
                          child: Tooltip(
                            message: isExpanded ? 'Shrink Settings' : 'Expand Settings',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  TutorialService.instance.notifyDrawerResized();
                                  final next = !isExpanded;
                                  onToggleExpanded?.call(next);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  key: resizeButtonKey,
                                  width: isVeryCompact ? 36 : 40,
                                  height: isVeryCompact ? 36 : 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Icon(
                                    isExpanded
                                        ? Icons.chevron_right_rounded
                                        : Icons.chevron_left_rounded,
                                    color: Colors.white,
                                    size: isVeryCompact ? 20 : 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Center / Left-aligned Title, Subtitle, and Version Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Settings',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isVeryCompact ? 18 : 21,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 1.5),
                              Text(
                                'Simple AAC Sri Lanka',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: isVeryCompact ? 11.5 : 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3.5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.32),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'v1.1.6',
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
                        const SizedBox(width: 8),
                        // Right: Dedicated Close (×) Button (matching squircle, top-aligned)
                        Semantics(
                          button: true,
                          label: 'Close Settings',
                          child: Tooltip(
                            message: 'Close Settings',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _handleClose(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: isVeryCompact ? 36 : 40,
                                  height: isVeryCompact ? 36 : 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: isVeryCompact ? 18 : 22,
                                  ),
                                ),
                              ),
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

          // Row 2: Personalize App (Language & Theme Wizard)
          if (onOpenPersonalizeSetup != null)
            _buildColorPickerRow(
              context,
              icon: Icons.tune_rounded,
              title: 'Personalize App',
              subtitle: isDarkMode
                  ? 'Language & theme setup'
                  : 'Language, App Bar & Board colors',
              previewChip: _PersonalizePreviewChip(
                appBarColor: primaryColorSwatch,
                boardColor: backgroundColorSwatch,
                isDarkMode: isDark,
              ),
              onTap: onOpenPersonalizeSetup!,
            ),

          // Row 3: Primary App Color with Mini UI Header Preview
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

          // Row 4: Card Text Color with Mini AAC Cards Preview
          _buildColorPickerRow(
            context,
            icon: Icons.format_color_text_rounded,
            title: 'Card Text Color',
            subtitle: isDarkMode ? 'Saved for Normal Mode' : 'Color of text on AAC cards',
            previewChip: _CardTextColorPreviewChip(
              color: cardTextColorSwatch,
              isDarkMode: isDark,
            ),
            onTap: onPickCardTextColor ?? () {},
          ),

          // Row 5: Card Label Background Color with Sample Label Preview
          _buildColorPickerRow(
            context,
            icon: Icons.label_outline_rounded,
            title: 'Card Label Color (Global)',
            subtitle: isDarkMode ? 'Saved for Normal Mode' : 'Background color of the text label on cards',
            previewChip: _CardLabelColorPreviewChip(
              color: cardLabelBgColorSwatch,
              isDarkMode: isDark,
            ),
            onTap: onPickCardLabelBgColor ?? () {},
          ),

          // Row 5: Board Background Color with 3 AAC Cards Canvas Preview
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

  String _getColorBlindSubtitle() {
    final type = ThemeAccessibility.colorBlindType;
    final widthStr = '${ThemeAccessibility.colorBlindBorderWidth.toStringAsFixed(1)}px';
    switch (type) {
      case 'deuteranomaly':
        return 'Deuteranomaly (Red-Green) • $widthStr';
      case 'protanomaly':
        return 'Protanomaly (Red-Green) • $widthStr';
      case 'tritanomaly':
        return 'Tritanomaly (Blue-Yellow) • $widthStr';
      case 'monochrome':
        return 'Monochromacy (Grayscale) • $widthStr';
      case 'universal':
      default:
        return 'Universal High-Contrast • $widthStr';
    }
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
            preview: ColorVisionPreviewChip(
              isColorBlind: false,
              isDarkMode: isDark,
            ),
          ),
          const SizedBox(height: 2),
          _ColorBlindRadioOption(
            title: 'Color-Blind Safe Mode',
            subtitle: isColorBlindMode
                ? _getColorBlindSubtitle()
                : 'High-contrast color-safe palette',
            selected: isColorBlindMode,
            onTap: () {
              if (!isColorBlindMode) {
                onChangeColorBlindMode(true);
              } else {
                onOpenColorBlindSettings?.call();
              }
            },
            onSettingsTap: onOpenColorBlindSettings,
            preview: ColorVisionPreviewChip(
              isColorBlind: true,
              isDarkMode: isDark,
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
    Key? itemKey,
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
      key: itemKey,
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
    Key? itemKey,
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
      key: itemKey,
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

/// Mini UI preview chip for Personalize App (reflects selected App Bar and Board colors)
class _PersonalizePreviewChip extends StatelessWidget {
  final Color appBarColor;
  final Color boardColor;
  final bool isDarkMode;

  const _PersonalizePreviewChip({
    required this.appBarColor,
    required this.boardColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Personalize preview: App bar and board colors',
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
            // Mini Header Bar in selected App Bar color
            Container(
              height: 14,
              color: appBarColor,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const Row(
                children: [
                  Icon(
                    Icons.chat_bubble_rounded,
                    size: 7,
                    color: Colors.white,
                  ),
                  Spacer(),
                  Icon(
                    Icons.menu_rounded,
                    size: 7,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            // Mini Board in selected Board color
            Expanded(
              child: Container(
                color: boardColor,
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE68A),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.08),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBAE6FD),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.08),
                            width: 0.5,
                          ),
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

/// Card text color preview chip displaying sample miniature AAC cards with the text color applied
class _CardTextColorPreviewChip extends StatelessWidget {
  final Color color;
  final bool isDarkMode;

  const _CardTextColorPreviewChip({
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Card text color preview: #${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
      child: Container(
        width: 96,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
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
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MiniCardWithText(
                cardBg: const Color(0xFFFFF59D),
                textColor: color,
                label: 'Hello',
                icon: Icons.waving_hand_rounded,
              ),
              _MiniCardWithText(
                cardBg: const Color(0xFFBBDEFB),
                textColor: color,
                label: 'Eat',
                icon: Icons.restaurant_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCardWithText extends StatelessWidget {
  final Color cardBg;
  final Color textColor;
  final String label;
  final IconData icon;

  const _MiniCardWithText({
    required this.cardBg,
    required this.textColor,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 30,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: Colors.black87),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: textColor,
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card label background color preview chip displaying a compact sample label
class _CardLabelColorPreviewChip extends StatelessWidget {
  final Color color;
  final bool isDarkMode;

  const _CardLabelColorPreviewChip({
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeData.estimateBrightnessForColor(color) == Brightness.light
        ? const Color(0xFF252B32)
        : Colors.white;

    return Semantics(
      label: 'Card label background color preview: #${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
      child: Container(
        width: 68,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.18),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Text(
            'Hello',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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
      ..strokeWidth = 1.2
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

/// Miniature 3-card palette preview chip for Color Vision Support options.
class ColorVisionPreviewChip extends StatelessWidget {
  final bool isColorBlind;
  final bool isDarkMode;

  const ColorVisionPreviewChip({
    super.key,
    required this.isColorBlind,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Resolves palette using the single source of truth in ThemeAccessibility
    final card1Bg = ThemeAccessibility.resolveCardSurface(
      const Color(0xFFFFF59D), // Yellow
      isDarkMode: isDarkMode,
      isColorBlindMode: isColorBlind,
    );
    final card2Bg = ThemeAccessibility.resolveCardSurface(
      const Color(0xFFBBDEFB), // Blue
      isDarkMode: isDarkMode,
      isColorBlindMode: isColorBlind,
    );
    final card3Bg = ThemeAccessibility.resolveCardSurface(
      const Color(0xFFFFCDD2), // Pink / Red
      isDarkMode: isDarkMode,
      isColorBlindMode: isColorBlind,
    );

    final borderColor = isColorBlind
        ? ThemeAccessibility.resolveCardBorderColor(
            isDarkMode: isDarkMode,
            isColorBlindMode: true,
          )
        : Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.22);
    final borderWidth = isColorBlind
        ? (ThemeAccessibility.colorBlindBorderWidth * 0.6).clamp(0.8, 2.8)
        : 0.8;

    final Color textColor1;
    final Color textColor2;
    final Color textColor3;

    if (isColorBlind) {
      textColor1 = ThemeAccessibility.resolveCardTextColor(
        card1Bg,
        isDarkMode: isDarkMode,
        isColorBlindMode: true,
        applyCustomTextColor: false,
        customTextColor: Colors.white,
      );
      textColor2 = ThemeAccessibility.resolveCardTextColor(
        card2Bg,
        isDarkMode: isDarkMode,
        isColorBlindMode: true,
        applyCustomTextColor: false,
        customTextColor: Colors.white,
      );
      textColor3 = ThemeAccessibility.resolveCardTextColor(
        card3Bg,
        isDarkMode: isDarkMode,
        isColorBlindMode: true,
        applyCustomTextColor: false,
        customTextColor: Colors.white,
      );
    } else {
      // Normal AAC mode: authentic high-contrast icon colors on pastel cards (no washed-out fade)
      textColor1 = isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
      textColor2 = isDarkMode ? const Color(0xFF90CAF9) : const Color(0xFF0D47A1);
      textColor3 = isDarkMode ? const Color(0xFFFF8A80) : const Color(0xFFB71C1C);
    }

    return Semantics(
      label: isColorBlind
          ? 'Color-blind safe preview palette'
          : 'Normal colors preview palette',
      child: Container(
        width: 74,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        // Shield internal preview elements from external system font/text scaling
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tiny AAC Card 1: Yellow with Stick Figure
              _buildMiniTile(
                bg: card1Bg,
                borderColor: borderColor,
                borderWidth: borderWidth,
                filter: isColorBlind
                    ? ThemeAccessibility.resolveCardImageFilter(isColorBlindMode: true)
                    : null,
                child: CustomPaint(
                  size: const Size(9, 12),
                  painter: _MiniStickFigurePainter(
                    color: textColor1,
                  ),
                ),
              ),
              // Tiny AAC Card 2: Blue with Cup
              _buildMiniTile(
                bg: card2Bg,
                borderColor: borderColor,
                borderWidth: borderWidth,
                filter: isColorBlind
                    ? ThemeAccessibility.resolveCardImageFilter(isColorBlindMode: true)
                    : null,
                child: Icon(
                  Icons.local_cafe_rounded,
                  size: 9.5,
                  color: textColor2,
                ),
              ),
              // Tiny AAC Card 3: Pink / Vermilion with Apple
              _buildMiniTile(
                bg: card3Bg,
                borderColor: borderColor,
                borderWidth: borderWidth,
                filter: isColorBlind
                    ? ThemeAccessibility.resolveCardImageFilter(isColorBlindMode: true)
                    : null,
                child: Icon(
                  Icons.apple_rounded,
                  size: 9.5,
                  color: textColor3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTile({
    required Color bg,
    required Color borderColor,
    required double borderWidth,
    required Widget child,
    ColorFilter? filter,
  }) {
    final effectiveChild = filter != null
        ? ColorFiltered(colorFilter: filter, child: child)
        : child;
    return Container(
      width: 18,
      height: 23,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3.5),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: effectiveChild,
    );
  }
}

class _ColorBlindRadioOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onSettingsTap;
  final Widget? preview;

  const _ColorBlindRadioOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.onSettingsTap,
    this.preview,
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
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 10),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (preview != null) ...[
                  const SizedBox(width: 6),
                  preview!,
                ],
                if (onSettingsTap != null) ...[
                  const SizedBox(width: 2),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: selected ? primary : colorScheme.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    splashRadius: 16,
                    tooltip: 'Customize color vision & border options',
                    onPressed: onSettingsTap,
                  ),
                ] else ...[
                  const SizedBox(width: 30),
                ],
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

/// Helper service for managing the Settings Drawer swipe hint.
/// Shows in compact mode for up to 2 distinct eligible app sessions,
/// can be dismissed per-session via the 'x' button, and is permanently
/// silenced once the swipe gesture or banner tap is performed.
class DrawerGestureHintHelper {
  static const String prefKeyLegacyDiscoveredExpansion =
      'has_discovered_drawer_expansion';
  static const String prefKeyGestureDiscovered =
      'has_discovered_drawer_gesture_v2';
  static const String prefKeySessionCount =
      'drawer_gesture_discovery_session_count_v2';
  static const int maxEligibleSessions = 2;

  static bool _sessionDismissed = false;
  static bool _hasDiscoveredGesture = false;
  static int _sessionCount = 0;
  static bool _hasLoadedFromPrefs = false;
  static bool _hasRecordedCurrentSession = false;

  /// Loads persisted expansion discovery state and session count from SharedPreferences.
  static Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasDiscoveredGesture =
          prefs.getBool(prefKeyGestureDiscovered) ?? false;
      _sessionCount = prefs.getInt(prefKeySessionCount) ?? 0;
      _hasLoadedFromPrefs = true;
    } catch (_) {}
  }

  /// Synchronous check for session dismissal.
  static bool get isSessionDismissed => _sessionDismissed;

  /// Synchronous check for discovery state.
  static bool get hasDiscoveredExpansion => _hasDiscoveredGesture;

  /// Whether automatic discovery is exhausted (after maxEligibleSessions).
  static bool get isDiscoveryExhausted => _sessionCount >= maxEligibleSessions;

  /// Current recorded eligible session count.
  static int get sessionCount => _sessionCount;

  /// Synchronous check for whether this app session has already been counted.
  static bool get hasRecordedCurrentSession => _hasRecordedCurrentSession;

  /// Returns true if the user dismissed the swipe gesture guidance during this session
  /// OR has already discovered drawer expansion
  /// OR has completed the maximum allowed discovery sessions (2).
  static Future<bool> isDismissed() async {
    if (_sessionDismissed) return true;
    if (!_hasLoadedFromPrefs) {
      await loadPreferences();
    }
    if (_hasDiscoveredGesture) return true;
    if (_sessionCount >= maxEligibleSessions) return true;
    return false;
  }

  /// Records that the hint was genuinely eligible and displayed during this app session.
  /// Only increments once per app session (in-memory process lifecycle).
  static Future<void> recordEligibleSessionDisplayed() async {
    if (_hasRecordedCurrentSession) return;
    if (!_hasLoadedFromPrefs) {
      await loadPreferences();
    }
    if (_hasDiscoveredGesture) return;
    if (_sessionCount >= maxEligibleSessions) return;

    _hasRecordedCurrentSession = true;
    _sessionCount++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(prefKeySessionCount, _sessionCount);
    } catch (_) {}
  }

  /// Marks the gesture hint as dismissed for this session when the user taps 'x'.
  static void setDismissed() {
    _sessionDismissed = true;
  }

  /// Marks expansion as successfully discovered and persists to SharedPreferences.
  static Future<void> markExpansionDiscovered() async {
    _hasDiscoveredGesture = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeyGestureDiscovered, true);
      await prefs.setBool(prefKeyLegacyDiscoveredExpansion, true);
    } catch (_) {}
  }

  /// Resets session-specific in-memory flags to simulate closing and relaunching the app.
  @visibleForTesting
  static void resetSessionForTesting() {
    _sessionDismissed = false;
    _hasRecordedCurrentSession = false;
    _hasLoadedFromPrefs = false;
  }

  /// Resets the session dismissal, discovery flags, and session counts.
  static Future<void> reset() async {
    _sessionDismissed = false;
    _hasDiscoveredGesture = false;
    _hasRecordedCurrentSession = false;
    _sessionCount = 0;
    _hasLoadedFromPrefs = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefKeyGestureDiscovered);
      await prefs.remove(prefKeyLegacyDiscoveredExpansion);
      await prefs.remove(prefKeySessionCount);
    } catch (_) {}
  }
}

/// InheritedWidget providing discovery animation state and actions to child widgets.
class _SettingsDrawerDiscoveryScope extends InheritedWidget {
  final Animation<double> nudgeAnimation;
  final VoidCallback triggerNudge;
  final VoidCallback expandDrawer;

  const _SettingsDrawerDiscoveryScope({
    Key? key,
    required this.nudgeAnimation,
    required this.triggerNudge,
    required this.expandDrawer,
    required Widget child,
  }) : super(key: key, child: child);

  static _SettingsDrawerDiscoveryScope? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SettingsDrawerDiscoveryScope>();
  }

  @override
  bool updateShouldNotify(_SettingsDrawerDiscoveryScope oldWidget) => false;
}

/// Host widget that detects sustained active scrolling (~3 seconds) and plays a gentle,
/// 400ms spring-back nudge animation moving the drawer 12 logical pixels to the left.
class _SettingsDrawerDiscoveryHost extends StatefulWidget {
  final bool isExpanded;
  final ValueChanged<bool>? onToggleExpanded;
  final Widget child;

  @visibleForTesting
  static Duration activeScrollThreshold = const Duration(milliseconds: 2800);

  const _SettingsDrawerDiscoveryHost({
    Key? key,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.child,
  }) : super(key: key);

  @override
  State<_SettingsDrawerDiscoveryHost> createState() =>
      _SettingsDrawerDiscoveryHostState();
}

class _SettingsDrawerDiscoveryHostState
    extends State<_SettingsDrawerDiscoveryHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _nudgeController;
  late final Animation<double> _nudgeAnimation;

  bool _hasNudgedThisSession = false;
  bool _isUserScrolling = false;
  bool _sustainedScrollReached = false;
  Timer? _activeScrollTimer;
  Timer? _idleResetTimer;
  DateTime? _activeScrollStartTime;

  @override
  void initState() {
    super.initState();
    DrawerGestureHintHelper.loadPreferences();

    _nudgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _nudgeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -12.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -12.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60.0,
      ),
    ]).animate(_nudgeController);
  }

  @override
  void dispose() {
    _activeScrollTimer?.cancel();
    _idleResetTimer?.cancel();
    _nudgeController.dispose();
    super.dispose();
  }

  bool get _isNudgeEligible {
    if (widget.isExpanded) return false;
    if (_hasNudgedThisSession) return false;
    if (DrawerGestureHintHelper.hasDiscoveredExpansion) return false;
    if (DrawerGestureHintHelper.isSessionDismissed) return false;
    if (DrawerGestureHintHelper.isDiscoveryExhausted) return false;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    return true;
  }

  void _triggerNudge() {
    if (!mounted || !_isNudgeEligible) return;
    _hasNudgedThisSession = true;
    _nudgeController.forward(from: 0.0);
  }

  void _onScrollStart() {
    _idleResetTimer?.cancel();
    _isUserScrolling = true;

    if (!_isNudgeEligible) return;

    if (_activeScrollStartTime == null) {
      _activeScrollStartTime = DateTime.now();
      _activeScrollTimer?.cancel();
      _activeScrollTimer =
          Timer(_SettingsDrawerDiscoveryHost.activeScrollThreshold, () {
        if (!mounted) return;
        _sustainedScrollReached = true;
        // If the user already stopped touching/scrolling when threshold was reached
        if (!_isUserScrolling && _isNudgeEligible) {
          _triggerNudge();
        }
      });
    }
  }

  void _onScrollUpdate() {
    _idleResetTimer?.cancel();
    _isUserScrolling = true;
  }

  void _onScrollEnd() {
    _isUserScrolling = false;

    if (_sustainedScrollReached) {
      if (_isNudgeEligible) {
        _triggerNudge();
      }
      _sustainedScrollReached = false;
      _activeScrollStartTime = null;
      _activeScrollTimer?.cancel();
      return;
    }

    // Reset after 1.2s of inactivity if sustained duration was not met
    _idleResetTimer?.cancel();
    _idleResetTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (!_isUserScrolling) {
        _activeScrollStartTime = null;
        _activeScrollTimer?.cancel();
        _sustainedScrollReached = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsDrawerDiscoveryScope(
      nudgeAnimation: _nudgeAnimation,
      triggerNudge: _triggerNudge,
      expandDrawer: () {
        DrawerGestureHintHelper.markExpansionDiscovered();
        widget.onToggleExpanded?.call(true);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            if (notification.dragDetails != null) {
              _onScrollStart();
            }
          } else if (notification is ScrollUpdateNotification) {
            if (notification.dragDetails != null) {
              _onScrollUpdate();
            }
          } else if (notification is ScrollEndNotification) {
            _onScrollEnd();
          } else if (notification is UserScrollNotification) {
            if (notification.direction == ScrollDirection.idle) {
              _onScrollEnd();
            } else {
              _onScrollUpdate();
            }
          }
          return false;
        },
        child: AnimatedBuilder(
          animation: _nudgeAnimation,
          builder: (context, child) {
            final disableAnimations =
                MediaQuery.maybeOf(context)?.disableAnimations ?? false;
            final offset = disableAnimations
                ? Offset.zero
                : Offset(_nudgeAnimation.value, 0);
            return Transform.translate(
              offset: offset,
              child: child,
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,
              if (!widget.isExpanded)
                Positioned(
                  left: 0,
                  top: MediaQuery.of(context).padding.top + 76,
                  child: AnimatedBuilder(
                    animation: _nudgeAnimation,
                    builder: (context, _) {
                      final disableAnimations =
                          MediaQuery.maybeOf(context)?.disableAnimations ??
                              false;
                      final progress =
                          (_nudgeAnimation.value.abs() / 12.0).clamp(0.0, 1.0);
                      if (progress <= 0.05 || disableAnimations) {
                        return const SizedBox.shrink();
                      }
                      return Opacity(
                        opacity: progress,
                        child: Transform.translate(
                          offset: Offset(-8 * progress, 0),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0267C1),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0267C1)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dismissible onboarding hint showing "Swipe left to expand".
class _DrawerGestureHintBar extends StatefulWidget {
  final bool isExpanded;
  final bool? forceShow;
  final VoidCallback? onExpand;

  const _DrawerGestureHintBar({
    Key? key,
    required this.isExpanded,
    this.forceShow,
    this.onExpand,
  }) : super(key: key);

  @override
  State<_DrawerGestureHintBar> createState() => _DrawerGestureHintBarState();
}

class _DrawerGestureHintBarState extends State<_DrawerGestureHintBar> {
  bool _dismissed = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _checkPref();
  }

  @override
  void didUpdateWidget(covariant _DrawerGestureHintBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceShow != oldWidget.forceShow ||
        widget.isExpanded != oldWidget.isExpanded) {
      _checkPref();
    }
  }

  Future<void> _checkPref() async {
    if (widget.forceShow != null) {
      if (mounted) {
        setState(() {
          _dismissed = !widget.forceShow!;
          _loaded = true;
        });
      }
      return;
    }
    final dismissed = await DrawerGestureHintHelper.isDismissed();
    if (!dismissed && !widget.isExpanded) {
      await DrawerGestureHintHelper.recordEligibleSessionDisplayed();
    }
    if (mounted) {
      setState(() {
        _dismissed = dismissed;
        _loaded = true;
      });
    }
  }

  void _dismiss() {
    setState(() {
      _dismissed = true;
    });
    DrawerGestureHintHelper.setDismissed();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isExpanded) {
      return const SizedBox.shrink();
    }
    if (!_loaded || _dismissed) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scope = _SettingsDrawerDiscoveryScope.of(context);

    Widget buildBarContent(double nudgeProgress) {
      final isNudging = nudgeProgress > 0.05;
      final borderColor = isNudging
          ? Color.lerp(
              isDark ? const Color(0xFF334155) : const Color(0xFFD0E2F9),
              isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              nudgeProgress,
            )!
          : (isDark ? const Color(0xFF334155) : const Color(0xFFD0E2F9));

      final backgroundColor = isNudging
          ? Color.lerp(
              isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F1FC),
              isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
              nudgeProgress,
            )!
          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F1FC));

      return Semantics(
        container: true,
        button: true,
        label: 'Gesture hint: Swipe left or tap to expand Settings to full screen',
        hint: 'Expands settings drawer to full screen',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isNudging ? 1.5 : 1.0,
            ),
            boxShadow: isNudging
                ? [
                    BoxShadow(
                      color: (isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF2563EB))
                          .withValues(alpha: 0.25 * nudgeProgress),
                      blurRadius: 8 * nudgeProgress,
                      spreadRadius: 1 * nudgeProgress,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('drawer_gesture_hint_bar_tap'),
              onTap: () {
                if (widget.onExpand != null) {
                  widget.onExpand!();
                } else {
                  scope?.expandDrawer();
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  children: [
                    Icon(
                      Icons.swipe_left_rounded,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF155799),
                      size: 24,
                    ),
                    Container(
                      height: 22,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFB0CBEA),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Swipe left to expand',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F3B7A),
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_back_rounded,
                            size: 13,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F3B7A),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Dismiss gesture hint',
                      child: Tooltip(
                        message: 'Dismiss hint',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: const ValueKey(
                                'drawer_gesture_hint_dismiss_button'),
                            onTap: _dismiss,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF5A7CA5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (scope?.nudgeAnimation != null) {
      return AnimatedBuilder(
        animation: scope!.nudgeAnimation,
        builder: (context, _) {
          final progress =
              (scope.nudgeAnimation.value.abs() / 12.0).clamp(0.0, 1.0);
          return buildBarContent(progress);
        },
      );
    }

    return buildBarContent(0.0);
  }
}

/// Gesture detector specifically tuned for horizontal drawer resize and close actions.
class _DrawerGestureHandler extends StatefulWidget {
  final Widget child;
  final bool isExpanded;
  final ValueChanged<bool>? onToggleExpanded;
  final VoidCallback onClose;

  const _DrawerGestureHandler({
    Key? key,
    required this.child,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onClose,
  }) : super(key: key);

  @override
  State<_DrawerGestureHandler> createState() => _DrawerGestureHandlerState();
}

class _DrawerGestureHandlerState extends State<_DrawerGestureHandler> {
  double _accumulatedDelta = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) {
        _accumulatedDelta = 0.0;
      },
      onHorizontalDragUpdate: (details) {
        _accumulatedDelta += details.primaryDelta ?? 0.0;
        if (_accumulatedDelta <= -40 && !widget.isExpanded) {
          _accumulatedDelta = 0.0;
          TutorialService.instance.notifyDrawerResized();
          DrawerGestureHintHelper.markExpansionDiscovered();
          widget.onToggleExpanded?.call(true);
        } else if (_accumulatedDelta >= 40 && widget.isExpanded) {
          _accumulatedDelta = 0.0;
          TutorialService.instance.notifyDrawerResized();
          widget.onToggleExpanded?.call(false);
        }
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0.0;
        if ((velocity < -200 || _accumulatedDelta <= -30) &&
            !widget.isExpanded) {
          TutorialService.instance.notifyDrawerResized();
          DrawerGestureHintHelper.markExpansionDiscovered();
          widget.onToggleExpanded?.call(true);
        } else if (velocity > 200 || _accumulatedDelta >= 30) {
          if (widget.isExpanded) {
            TutorialService.instance.notifyDrawerResized();
            widget.onToggleExpanded?.call(false);
          } else {
            widget.onClose();
          }
        }
        _accumulatedDelta = 0.0;
      },
      child: widget.child,
    );
  }
}
