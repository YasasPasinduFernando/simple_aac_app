import 'package:flutter/material.dart';

class HomeDrawer extends StatelessWidget {
  final String selectedCategory;
  final String currentLanguageLabel;
  final int gridColumns;
  final String visibleCardsLabel;
  final bool isEditMode;
  final bool showTtsInput;
  final VoidCallback onSelectCategory;
  final VoidCallback onAddCategory;
  final VoidCallback onToggleEdit;
  final VoidCallback onToggleTtsInput;
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
    required this.onSelectCategory,
    required this.onAddCategory,
    required this.onToggleEdit,
    required this.onToggleTtsInput,
    required this.onShowLanguage,
    required this.onShowGrid,
    required this.onShowVisibleCount,
    required this.onBackup,
    required this.onRestore,
    required this.onShowAbout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
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
            leading: const Icon(Icons.edit),
            title: Text(isEditMode ? 'Exit Edit' : 'Edit'),
            onTap: onToggleEdit,
          ),
          ListTile(
            leading: const Icon(Icons.record_voice_over),
            title: const Text('Type to Speak'),
            trailing: Switch(
              value: showTtsInput,
              onChanged: (_) => onToggleTtsInput(),
            ),
            onTap: onToggleTtsInput,
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
          const Divider(),
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
