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
  final VoidCallback onSelectCategory;
  final VoidCallback onAddCategory;
  final VoidCallback onToggleEdit;
  final VoidCallback onToggleTtsInput;
  final VoidCallback onChangeOrientation;
  final VoidCallback onToggleFullScreen;
  final VoidCallback onShowLanguage;
  final VoidCallback onShowGrid;
  final VoidCallback onShowVisibleCount;
  final VoidCallback onBackup;
  final VoidCallback onRestore;
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
    required this.onSelectCategory,
    required this.onAddCategory,
    required this.onToggleEdit,
    required this.onToggleTtsInput,
    required this.onChangeOrientation,
    required this.onToggleFullScreen,
    required this.onShowLanguage,
    required this.onShowGrid,
    required this.onShowVisibleCount,
    required this.onBackup,
    required this.onRestore,
    required this.onShowAbout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final drawerWidth =
        (MediaQuery.of(context).size.width * 0.7).clamp(240.0, 320.0);
    return Drawer(
      width: drawerWidth,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.brown.shade700,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.settings, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text(
                  'Settings',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(isEditMode ? 'Exit Edit' : 'Edit'),
            onTap: onToggleEdit,
          ),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Type to Speak'),
            trailing: Switch(
              value: showTtsInput,
              onChanged: (_) => onToggleTtsInput(),
            ),
            onTap: onToggleTtsInput,
          ),
          ListTile(
            leading: const Icon(Icons.screen_rotation),
            title: const Text('Orientation'),
            subtitle: Text(orientationLabel),
            onTap: onChangeOrientation,
          ),
          ListTile(
            leading: const Icon(Icons.fullscreen),
            title: const Text('Full Screen'),
            trailing: Switch(
              value: fullScreen,
              onChanged: (_) => onToggleFullScreen(),
            ),
            onTap: onToggleFullScreen,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(currentLanguageLabel),
            onTap: onShowLanguage,
          ),
          ListTile(
            leading: const Icon(Icons.grid_3x3),
            title: const Text('Grid Layout'),
            subtitle: Text('$gridColumns columns'),
            onTap: onShowGrid,
          ),
          ListTile(
            leading: const Icon(Icons.filter_1),
            title: const Text('Visible Cards'),
            subtitle: Text(visibleCardsLabel),
            onTap: onShowVisibleCount,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Category'),
            subtitle: Text(selectedCategory),
            onTap: onSelectCategory,
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Category'),
            onTap: onAddCategory,
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup'),
            onTap: onBackup,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore'),
            onTap: onRestore,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: onShowAbout,
          ),
        ],
      ),
    );
  }
}
