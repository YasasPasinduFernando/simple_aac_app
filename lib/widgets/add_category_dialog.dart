import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';
import '../utils/card_image.dart';
import 'preview/live_preview_panel.dart';
import 'styled_dialog_header.dart';

/// Pre-configured suggestion preset for quick category creation.
class _CategoryPreset {
  final String name;
  final IconData icon;
  final int colorValue;
  final String emoji;
  final List<String> searchKeywords;

  const _CategoryPreset({
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.emoji,
    required this.searchKeywords,
  });
}

const List<_CategoryPreset> _kCategoryPresets = [
  _CategoryPreset(
    name: 'Food',
    icon: Icons.restaurant_rounded,
    colorValue: 0xFFFFA726, // Orange
    emoji: '🍽️',
    searchKeywords: [
      'food',
      'drink',
      'water',
      'rice',
      'milk',
      'apple',
      'bread',
      'eat',
      'කෑම',
      'වතුර',
      'බත්',
      'உணவு'
    ],
  ),
  _CategoryPreset(
    name: 'School',
    icon: Icons.school_rounded,
    colorValue: 0xFF42A5F5, // Blue
    emoji: '🏫',
    searchKeywords: [
      'school',
      'teacher',
      'book',
      'pen',
      'pencil',
      'study',
      'class',
      'පාසල',
      'පොත',
      'பள்ளி'
    ],
  ),
  _CategoryPreset(
    name: 'Feelings',
    icon: Icons.emoji_emotions_rounded,
    colorValue: 0xFFFFCA28, // Amber / Warm Yellow
    emoji: '😊',
    searchKeywords: [
      'happy',
      'sad',
      'angry',
      'feelings',
      'tired',
      'hungry',
      'sick',
      'සතුටුයි',
      'දුකයි',
      'மகிழ்ச்சி'
    ],
  ),
  _CategoryPreset(
    name: 'Play',
    icon: Icons.sports_soccer_rounded,
    colorValue: 0xFF66BB6A, // Green
    emoji: '⚽',
    searchKeywords: [
      'play',
      'game',
      'ball',
      'toy',
      'run',
      'jump',
      'video',
      'සෙල්ලම්',
      'விளையாட்டு'
    ],
  ),
  _CategoryPreset(
    name: 'Home',
    icon: Icons.home_rounded,
    colorValue: 0xFF26A69A, // Teal
    emoji: '🏠',
    searchKeywords: [
      'home',
      'house',
      'room',
      'bed',
      'sleep',
      'bath',
      'kitchen',
      'ගෙදර',
      'නිවස',
      'வீடு'
    ],
  ),
  _CategoryPreset(
    name: 'Health',
    icon: Icons.favorite_rounded,
    colorValue: 0xFFEF5350, // Coral / Red
    emoji: '🩺',
    searchKeywords: [
      'health',
      'doctor',
      'hospital',
      'medicine',
      'pain',
      'hurt',
      'sick',
      'රෝහල',
      'අසනීපයි',
      'மருத்துவமனை'
    ],
  ),
  _CategoryPreset(
    name: 'Travel',
    icon: Icons.directions_car_rounded,
    colorValue: 0xFFAB47BC, // Purple
    emoji: '🚗',
    searchKeywords: [
      'car',
      'bus',
      'vehicle',
      'van',
      'train',
      'go',
      'trip',
      'කාර්',
      'බස්',
      'வாகனம்'
    ],
  ),
  _CategoryPreset(
    name: 'Animals',
    icon: Icons.pets_rounded,
    colorValue: 0xFF8D6E63, // Warm Brown
    emoji: '🐶',
    searchKeywords: [
      'cat',
      'dog',
      'pet',
      'animal',
      'bird',
      'fish',
      'සතා',
      'බල්ලා',
      'விலங்கு'
    ],
  ),
  _CategoryPreset(
    name: 'People',
    icon: Icons.people_rounded,
    colorValue: 0xFF5C6BC0, // Indigo
    emoji: '👥',
    searchKeywords: [
      'mom',
      'dad',
      'friend',
      'brother',
      'sister',
      'family',
      'අම්මා',
      'තාත්තා',
      'குடும்பம்'
    ],
  ),
];

const List<IconData> _kAvailableIcons = [
  Icons.category_rounded,
  Icons.restaurant_rounded,
  Icons.school_rounded,
  Icons.emoji_emotions_rounded,
  Icons.sports_soccer_rounded,
  Icons.home_rounded,
  Icons.favorite_rounded,
  Icons.directions_car_rounded,
  Icons.pets_rounded,
  Icons.people_rounded,
  Icons.star_rounded,
  Icons.toys_rounded,
  Icons.music_note_rounded,
  Icons.local_hospital_rounded,
];

const List<int> _kAvailableColors = [
  0xFF42A5F5, // Sky Blue (Default)
  0xFF66BB6A, // Vibrant Green
  0xFFFFA726, // Sunny Orange
  0xFFEF5350, // Coral Red
  0xFFAB47BC, // Creative Purple
  0xFF26A69A, // Calm Teal
  0xFFFFCA28, // Warm Yellow
  0xFFEC407A, // Pink
  0xFF5C6BC0, // Indigo
  0xFF8D6E63, // Warm Brown
];

/// Rich, interactive modal dialog to create a new category, customize its
/// icon, color accent, and assign existing AAC cards to it with live preview.
class AddCategoryDialog extends StatefulWidget {
  final List<AACCard> availableCards;
  final Set<String> existingCategories;
  final String currentLanguage;
  final void Function(
    String categoryName,
    Set<String> selectedCardIds,
    int colorValue,
    IconData icon,
  ) onAddCategory;

  const AddCategoryDialog({
    Key? key,
    required this.availableCards,
    required this.existingCategories,
    required this.currentLanguage,
    required this.onAddCategory,
  }) : super(key: key);

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _searchController;
  String _searchQuery = '';
  final Set<String> _selectedCardIds = {};
  IconData _selectedIcon = Icons.category_rounded;
  int _selectedColorValue = 0xFF42A5F5;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _searchController = TextEditingController();
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isDuplicateName {
    final clean = _nameController.text.trim().toLowerCase();
    if (clean.isEmpty) return false;
    return widget.existingCategories.any(
      (cat) => cat.trim().toLowerCase() == clean,
    );
  }

  bool get _canSubmit {
    final clean = _nameController.text.trim();
    return clean.isNotEmpty && !_isDuplicateName;
  }

  List<AACCard> get _filteredCards {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return widget.availableCards;

    return widget.availableCards.where((card) {
      final labelEn = card.label.toLowerCase();
      final labelSi = (card.labelSinhala ?? '').toLowerCase();
      final labelTa = (card.labelTamil ?? '').toLowerCase();
      final currentLabel = card.getLabel(widget.currentLanguage).toLowerCase();
      final category = card.category.toLowerCase();

      return labelEn.contains(query) ||
          labelSi.contains(query) ||
          labelTa.contains(query) ||
          currentLabel.contains(query) ||
          category.contains(query);
    }).toList();
  }

  void _applyPreset(_CategoryPreset preset) {
    setState(() {
      _nameController.text = preset.name;
      _selectedIcon = preset.icon;
      _selectedColorValue = preset.colorValue;

      // Auto-select relevant cards if no cards are selected yet
      if (_selectedCardIds.isEmpty) {
        for (final card in widget.availableCards) {
          final cardCat = card.category.toLowerCase();
          final cardLabel = card.label.toLowerCase();
          final matches = preset.searchKeywords.any((kw) =>
              cardCat.contains(kw) || cardLabel.contains(kw));
          if (matches) {
            _selectedCardIds.add(card.id);
          }
        }
      }
    });
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _searchController.clear();
      _searchQuery = '';
      _selectedCardIds.clear();
      _selectedIcon = Icons.category_rounded;
      _selectedColorValue = 0xFF42A5F5;
    });
  }

  void _selectAllFiltered() {
    setState(() {
      for (final card in _filteredCards) {
        _selectedCardIds.add(card.id);
      }
    });
  }

  void _clearSelected() {
    setState(() {
      _selectedCardIds.clear();
    });
  }

  void _toggleCardSelection(String cardId) {
    setState(() {
      if (_selectedCardIds.contains(cardId)) {
        _selectedCardIds.remove(cardId);
      } else {
        _selectedCardIds.add(cardId);
      }
    });
  }

  void _submit() {
    final clean = _nameController.text.trim();
    if (clean.isEmpty || _isDuplicateName) return;

    widget.onAddCategory(
      clean,
      _selectedCardIds,
      _selectedColorValue,
      _selectedIcon,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context).size;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = keyboardInset > 60;
    final accentColor = Color(_selectedColorValue);

    final categoryNameDisplay = _nameController.text.trim().isEmpty
        ? 'Category Name'
        : _nameController.text.trim();

    final filteredList = _filteredCards;
    final selectedCardsList = widget.availableCards
        .where((c) => _selectedCardIds.contains(c.id))
        .toList();

    // Dynamically scale content height to adapt to open keyboard without awkward shrinking or overflow
    final availableHeight = media.height - keyboardInset;
    final maxContentHeight =
        (availableHeight * (isKeyboardOpen ? 0.62 : 0.72)).clamp(180.0, 640.0);

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isKeyboardOpen ? 8 : 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: StyledDialogHeader(
        icon: Icons.create_new_folder_rounded,
        accentColor: accentColor,
        title: 'Add New Category',
        subtitle: 'Create, customize & assign cards',
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDark ? 0.30 : 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.40),
              width: 0.8,
            ),
          ),
          child: Text(
            '${_selectedCardIds.length} cards',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : accentColor,
            ),
          ),
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (media.width - 32).clamp(280.0, 500.0),
          maxHeight: maxContentHeight,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. LIVE PREVIEW PANEL
              LivePreviewPanel(
                title: 'LIVE CATEGORY PREVIEW',
                icon: Icons.visibility_rounded,
                accentColor: accentColor,
                minHeight: isKeyboardOpen ? 70 : 100,
                maxHeight: isKeyboardOpen ? 110 : 180,
                trailing: Text(
                  '${_selectedCardIds.length} assigned',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Category Card Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: accentColor
                            .withValues(alpha: isDark ? 0.28 : 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.60),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundColor: accentColor,
                            child: Icon(
                              _selectedIcon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  categoryNameDisplay,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedCardIds.isEmpty
                                      ? 'Tap cards below to assign to this category'
                                      : '${_selectedCardIds.length} cards in this category',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor
                                  .withValues(alpha: isDark ? 0.40 : 0.20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.folder_rounded,
                              size: 14,
                              color: isDark ? Colors.white : accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Horizontal assigned cards thumbnail strip
                    if (selectedCardsList.isNotEmpty && !isKeyboardOpen) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int index = 0;
                                index <
                                    (selectedCardsList.length > 8
                                        ? 9
                                        : selectedCardsList.length);
                                index++) ...[
                              if (index > 0) const SizedBox(width: 6),
                              if (index == 8 && selectedCardsList.length > 8)
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+${selectedCardsList.length - 8}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Builder(
                                  builder: (context) {
                                    final card = selectedCardsList[index];
                                    final cardLabel =
                                        card.getLabel(widget.currentLanguage);
                                    return Tooltip(
                                      message: cardLabel,
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Color(card.colorValue),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.black
                                                .withValues(alpha: 0.12),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(9),
                                          child: card.imagePath != null &&
                                                  card.imagePath!.isNotEmpty
                                              ? buildCardImage(
                                                  card.imagePath!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      const Icon(Icons.image,
                                                          size: 18),
                                                )
                                              : const Icon(Icons.image,
                                                  size: 18),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 2. CATEGORY NAME TEXT FIELD
              TextField(
                controller: _nameController,
                autofocus: false,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Food, School, Emotions',
                  prefixIcon: Icon(_selectedIcon, color: accentColor),
                  suffixIcon: _nameController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _nameController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  errorText: _isDuplicateName
                      ? 'Category with this name already exists'
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E2836)
                      : colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. QUICK PRESET CHIPS
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'QUICK PRESETS',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _kCategoryPresets.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Builder(
                        builder: (context) {
                          final preset = _kCategoryPresets[i];
                          final isSelected =
                              _nameController.text.trim().toLowerCase() ==
                                  preset.name.toLowerCase();
                          return ActionChip(
                            avatar: Text(
                              preset.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            label: Text(
                              preset.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : null,
                              ),
                            ),
                            backgroundColor: isSelected
                                ? Color(preset.colorValue)
                                    .withValues(alpha: isDark ? 0.35 : 0.25)
                                : null,
                            side: BorderSide(
                              color: isSelected
                                  ? Color(preset.colorValue)
                                  : colorScheme.outlineVariant
                                      .withValues(alpha: 0.6),
                              width: isSelected ? 1.4 : 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onPressed: () => _applyPreset(preset),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 4. ICON PICKER
              Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'CHOOSE ICON',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _kAvailableIcons.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Builder(
                        builder: (context) {
                          final icon = _kAvailableIcons[i];
                          final isSelected = _selectedIcon == icon;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _selectedIcon = icon;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentColor
                                        .withValues(alpha: isDark ? 0.35 : 0.20)
                                    : (isDark
                                        ? const Color(0xFF1E2836)
                                        : colorScheme.surfaceContainerLowest),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? accentColor
                                      : colorScheme.outlineVariant
                                          .withValues(alpha: 0.5),
                                  width: isSelected ? 1.6 : 0.8,
                                ),
                              ),
                              child: Icon(
                                icon,
                                size: 20,
                                color: isSelected
                                    ? accentColor
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 5. COLOR ACCENT PICKER
              Row(
                children: [
                  Icon(
                    Icons.color_lens_outlined,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'COLOR ACCENT',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _kAvailableColors.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Builder(
                        builder: (context) {
                          final colorVal = _kAvailableColors[i];
                          final isSelected = _selectedColorValue == colorVal;
                          final color = Color(colorVal);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColorValue = colorVal;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black26,
                                  width: isSelected ? 2.2 : 0.8,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 6. CARD ASSIGNMENT SECTION ("cards add krna eka")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.library_add_check_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'ASSIGN CARDS TO CATEGORY',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_selectedCardIds.length} of ${widget.availableCards.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search cards to assign...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E2836)
                      : colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),

              const SizedBox(height: 6),

              // Select all / clear buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      onPressed: _selectAllFiltered,
                      icon: const Icon(Icons.done_all_rounded, size: 15),
                      label: Text(
                        'Select All (${filteredList.length})',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      onPressed: _clearSelected,
                      icon: const Icon(Icons.clear_all_rounded, size: 15),
                      label: const Text(
                        'Clear Selection',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Scrollable list of cards
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (media.height * 0.24).clamp(130.0, 240.0),
                ),
                child: Material(
                  color: isDark
                      ? const Color(0xFF1E2836)
                      : colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: filteredList.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18.0),
                              child: Text(
                                _searchQuery.isEmpty
                                    ? 'No cards available'
                                    : 'No cards match "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (int i = 0;
                                    i < filteredList.length;
                                    i++) ...[
                                  if (i > 0)
                                    Divider(
                                      height: 1,
                                      indent: 52,
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.35),
                                    ),
                                  Builder(
                                    builder: (context) {
                                      final card = filteredList[i];
                                      final label = card
                                          .getLabel(widget.currentLanguage);
                                      final isChecked =
                                          _selectedCardIds.contains(card.id);
                                      final isFolder = card.type == 'folder';

                                      return CheckboxListTile(
                                        value: isChecked,
                                        dense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        title: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                label,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (isFolder) ...[
                                              const SizedBox(width: 5),
                                              Icon(
                                                Icons.folder_outlined,
                                                size: 14,
                                                color: isDark
                                                    ? Colors.amber.shade300
                                                    : const Color(0xFFB45309),
                                              ),
                                            ],
                                          ],
                                        ),
                                        subtitle: Text(
                                          'Category: ${card.category}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        secondary: Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: Color(card.colorValue),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.black
                                                  .withValues(alpha: 0.08),
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: card.imagePath != null &&
                                                    card.imagePath!.isNotEmpty
                                                ? buildCardImage(
                                                    card.imagePath!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Icon(
                                                        isFolder
                                                            ? Icons
                                                                .folder_rounded
                                                            : Icons.image,
                                                        size: 16,
                                                      );
                                                    },
                                                  )
                                                : Icon(
                                                    isFolder
                                                        ? Icons
                                                            .folder_rounded
                                                        : Icons.image,
                                                    size: 16,
                                                  ),
                                          ),
                                        ),
                                        onChanged: (_) =>
                                            _toggleCardSelection(card.id),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: _resetForm,
              child: const Text('Reset'),
            ),
            const Spacer(),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                _selectedCardIds.isEmpty
                    ? 'Add Category'
                    : 'Add Category (${_selectedCardIds.length})',
              ),
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ],
    );
  }
}
