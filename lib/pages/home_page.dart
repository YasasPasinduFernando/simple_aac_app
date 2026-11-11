import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../data/default_seed_cards.dart';
import '../models/aac_card_model.dart';
import '../models/tts_token.dart';
import '../services/backup_service.dart';
import '../services/card_storage_service.dart';
import '../services/network_policy_service.dart';
import '../widgets/card_editor_dialog.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../widgets/edit_mode_bar.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_drawer.dart';
import '../widgets/landscape_menu.dart';
import '../widgets/styled_dialog_header.dart';
import '../widgets/tts_bar.dart';
import '../widgets/visible_cards_dialog.dart';
import '../utils/app_permissions_helper.dart';
import '../utils/card_image.dart';
import '../utils/theme_accessibility.dart';
import '../utils/ui_mode_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterTts _tts = FlutterTts();
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _gridController = ScrollController();

  List<AACCard> cards = [];
  int gridColumns = 2;
  Map<String, Set<String>> visibleCardIdsByParent = {};
  String currentLanguage = 'en';
  bool showTtsInput = true;
  String selectedCategory = 'All';
  Set<String> allCategories = {'General'};
  AACCard? activeParentCard;
  bool isEditMode = false;
  bool isCardEditorOpen = false;
  String? highlightedCardId;
  String? _tapAnimatedCardId;
  Timer? _highlightTimer;
  Timer? _tapAnimTimer;
  String orientationMode = 'portrait';
  bool fullScreen = false;
  bool isPinned = false;
  DateTime? _lastBackPress;
  final List<TtsToken> _ttsTokens = [];
  String searchQuery = '';
  List<AACCard>? _editSnapshotCards;
  Map<String, Set<String>>? _editSnapshotVisible;
  Set<String>? _editSnapshotCategories;
  String? _editSnapshotSelectedCategory;
  String? _editSnapshotActiveParentId;
  static const int _defaultPrimaryColorValue = 0xFF0277BD;
  int _themePrimaryColor = _defaultPrimaryColorValue;
  int _themeTextColor = Colors.white.value;
  int _themeBackgroundColor = Colors.white.value;
  double _ttsBarSize = 1.0;
  bool _showTtsActions = true;
  bool _hideTtsText = false;
  bool _useImageOverlayLabel = false;
  bool _applyTextColorToCards = false;
  bool _isDarkMode = ThemeAccessibility.darkModeNotifier.value;
  bool _isColorBlindMode = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadCards();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _loadCards() async {
    debugPrint('[HomePage] app startup storage initialization started');
    final prefs = await SharedPreferences.getInstance();
    final loadedCards = await CardStorageService.loadCards(
      defaultCards: _createSeedImageCards(),
    );
    if (!mounted) return;
    final String saved = _encodeCardsForLoad(loadedCards);

    final List decoded = jsonDecode(saved);
    setState(() {
      cards = decoded.map((c) => AACCard.fromJson(c)).toList();
    });

    gridColumns = prefs.getInt('gridColumns') ?? 2;
    _loadVisibleSelections(prefs);
    showTtsInput = prefs.getBool('showTtsInput') ?? true;
    orientationMode = prefs.getString('orientationMode') ?? 'portrait';
    fullScreen = prefs.getBool('fullScreen') ?? true;
    currentLanguage = prefs.getString('language') ?? 'en';
    _themePrimaryColor =
        prefs.getInt('themePrimaryColor') ?? _defaultPrimaryColorValue;
    _themeTextColor = prefs.getInt('themeTextColor') ?? Colors.white.value;
    _themeBackgroundColor =
        prefs.getInt('themeBackgroundColor') ?? Colors.white.value;
    _ttsBarSize = prefs.getDouble('ttsBarSize') ?? 1.0;
    _showTtsActions = prefs.getBool('showTtsActions') ?? true;
    _hideTtsText = prefs.getBool('hideTtsText') ?? false;
    _useImageOverlayLabel = prefs.getBool('useImageOverlayLabel') ?? false;
    _applyTextColorToCards = prefs.getBool('applyTextColorToCards') ?? false;
    _isDarkMode =
        prefs.getBool(ThemeAccessibility.darkModePrefKey) ?? _isDarkMode;
    _isColorBlindMode =
        prefs.getBool(ThemeAccessibility.colorBlindPrefKey) ?? false;
    ThemeAccessibility.darkModeNotifier.value = _isDarkMode;

    _updateCategories();
    _migrateVisibleCountIfNeeded(prefs);
    _logCardMediaPaths('load', cards);
    debugPrint(
      '[HomePage] card load complete: ${cards.length} top-level cards, '
      '${CardStorageService.countCards(cards)} total cards',
    );
    UiModeHelper.applyOrientation(orientationMode);
    UiModeHelper.applySystemUi(fullScreen);
  }

  String _encodeCardsForLoad(List<AACCard> loadedCards) {
    return jsonEncode(loadedCards.map((c) => c.toJson()).toList());
  }

  List<AACCard> _createSeedImageCards() {
    return createDefaultSeedCards();
  }

  // ignore: unused_element
  List<AACCard> _createDefaultCards() {
    return _createSeedImageCards();
  }

  void _loadVisibleSelections(SharedPreferences prefs) {
    final savedMap = prefs.getString('visibleCardIdsByParent');
    if (savedMap != null) {
      final decoded = jsonDecode(savedMap) as Map<String, dynamic>;
      visibleCardIdsByParent = decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List).map((v) => v.toString()).toSet(),
        ),
      );
      return;
    }

    final savedVisibleIds = prefs.getStringList('visibleCardIds') ?? [];
    if (savedVisibleIds.isNotEmpty) {
      visibleCardIdsByParent['__root__'] = savedVisibleIds.toSet();
    }
  }

  void _migrateVisibleCountIfNeeded(SharedPreferences prefs) {
    if (visibleCardIdsByParent.isNotEmpty) return;
    final legacyCount = prefs.getInt('visibleCardCount') ?? 0;
    if (legacyCount <= 0) return;
    final base = _getBaseDisplayedCards();
    visibleCardIdsByParent['__root__'] =
        base.take(legacyCount).map((c) => c.id).toSet();
  }

  void _updateCategories() {
    allCategories.clear();
    allCategories.add('All');
    for (var card in cards) {
      allCategories.add(card.category);
      for (var subCard in card.subCards) {
        allCategories.add(subCard.category);
      }
    }
  }

  Future<void> _saveCards() async {
    debugPrint(
      '[HomePage] card saving requested: ${cards.length} top-level cards, '
      '${CardStorageService.countCards(cards)} total cards',
    );
    _logCardMediaPaths('save', cards);
    await CardStorageService.saveCards(cards);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'cards', jsonEncode(cards.map((c) => c.toJson()).toList()));
    await prefs.setInt('gridColumns', gridColumns);
    final encoded = jsonEncode(
      visibleCardIdsByParent.map(
        (key, value) => MapEntry(key, value.toList()),
      ),
    );
    await prefs.setString('visibleCardIdsByParent', encoded);
    await prefs.setBool('showTtsInput', showTtsInput);
    await prefs.setString('orientationMode', orientationMode);
    await prefs.setBool('fullScreen', fullScreen);
    await prefs.setString('language', currentLanguage);
    await prefs.setInt('themePrimaryColor', _themePrimaryColor);
    await prefs.setInt('themeTextColor', _themeTextColor);
    await prefs.setInt('themeBackgroundColor', _themeBackgroundColor);
    await prefs.setDouble('ttsBarSize', _ttsBarSize);
    await prefs.setBool('showTtsActions', _showTtsActions);
    await prefs.setBool('hideTtsText', _hideTtsText);
    await prefs.setBool('useImageOverlayLabel', _useImageOverlayLabel);
    await prefs.setBool('applyTextColorToCards', _applyTextColorToCards);
    await prefs.setBool(ThemeAccessibility.darkModePrefKey, _isDarkMode);
    await prefs.setBool(
        ThemeAccessibility.colorBlindPrefKey, _isColorBlindMode);
    debugPrint('[HomePage] settings and cards saved');
  }

  void _logCardMediaPaths(String phase, List<AACCard> cardsList) {
    void visit(AACCard card) {
      final imagePath = card.imagePath;
      if (imagePath != null && imagePath.isNotEmpty) {
        final exists =
            isAssetImagePath(imagePath) || File(imagePath).existsSync();
        debugPrint(
          '[HomePage] card media $phase: id=${card.id}, '
          'imagePath=$imagePath, exists=$exists',
        );
      }

      final voicePath = card.voicePath;
      if (voicePath != null && voicePath.isNotEmpty) {
        debugPrint(
          '[HomePage] card media $phase: id=${card.id}, '
          'voicePath=$voicePath, exists=${File(voicePath).existsSync()}',
        );
      }

      for (final subCard in card.subCards) {
        visit(subCard);
      }
    }

    for (final card in cardsList) {
      visit(card);
    }
  }

  Future<void> _speak(String text) async {
    switch (currentLanguage) {
      case 'si':
        await _tts.setLanguage("si-LK");
        break;
      case 'ta':
        await _tts.setLanguage("ta-IN");
        break;
      default:
        await _tts.setLanguage("en-US");
    }
    await _tts.speak(text);
  }

  void _appendToTtsInput(
    String text, {
    String? imagePath,
    String? voicePath,
  }) {
    if (!showTtsInput) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _ttsTokens.add(TtsToken(trimmed, imagePath, voicePath: voicePath));
    });
  }

  void _clearTtsInput() {
    setState(() {
      _ttsTokens.clear();
    });
  }

  void _deleteLastWord() {
    if (_ttsTokens.isNotEmpty) {
      setState(() {
        _ttsTokens.removeLast();
      });
      return;
    }
  }

  void _resetTtsInput() {
    _ttsTokens.clear();
  }

  void _triggerWordTapAnimation(String cardId) {
    _tapAnimTimer?.cancel();
    setState(() {
      highlightedCardId = null;
      _tapAnimatedCardId = cardId;
    });
    _tapAnimTimer = Timer(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      setState(() {
        _tapAnimatedCardId = null;
      });
    });
  }

  Future<void> _playVoice(String path) async {
    await _audioPlayer.play(DeviceFileSource(path));
  }

  Future<void> _playTtsTokens() async {
    for (final token in _ttsTokens) {
      final voicePath = token.voicePath;
      if (voicePath != null && await File(voicePath).exists()) {
        await _audioPlayer.play(DeviceFileSource(voicePath));
        await _audioPlayer.onPlayerComplete.first;
        continue;
      }
      await _speak(token.label);
    }
  }

  Future<void> _pickImage(AACCard card) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: const StyledDialogHeader(
          icon: Icons.add_a_photo_rounded,
          title: 'Choose Image Source',
          subtitle: 'Add a picture to this card',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogOptionTile(
                icon: Icons.camera_alt_rounded,
                title: 'Camera',
                subtitle: 'Take a new photo now',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              DialogOptionTile(
                icon: Icons.photo_library_rounded,
                title: 'Gallery',
                subtitle: 'Choose a photo from your device',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final allowed = source == ImageSource.camera
          ? await AppPermissionsHelper.ensureCameraPermission(context)
          : await AppPermissionsHelper.ensureLegacyStorageIfNeeded(context);
      if (!allowed || !mounted) return;

      try {
        final image = await _picker.pickImage(source: source, imageQuality: 80);
        if (image != null) {
          final permanentPath = await CardStorageService.persistMediaFile(
            image.path,
            cardId: card.id,
            mediaType: 'images',
          );
          debugPrint(
            '[HomePage] image selected for card ${card.id}: '
            'pickerPath=${image.path}, savedPath=$permanentPath',
          );
          setState(() {
            card.imagePath = permanentPath;
          });
          _saveCards();
        }
      } catch (error, stackTrace) {
        debugPrint('[HomePage] image save failed: $error');
        debugPrint(stackTrace.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image could not be selected. Check permissions if needed.'),
            ),
          );
        }
      }
    }
  }

  void _setHighlight(String cardId) {
    _highlightTimer?.cancel();
    setState(() {
      highlightedCardId = cardId;
    });
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        highlightedCardId = null;
      });
    });
  }

  Future<void> _editCard(
    AACCard card, {
    bool isNew = false,
    void Function(AACCard card)? onSave,
  }) async {
    if (isCardEditorOpen) return;
    isCardEditorOpen = true;
    final action = await showDialog<CardEditorAction>(
      context: context,
      builder: (context) => CardEditorDialog(
        card: card,
        isNew: isNew,
        categories: allCategories.toList(),
        audioPlayer: _audioPlayer,
        onPickImage: () {
          Navigator.pop(context);
          _pickImage(card);
        },
      ),
    );
    if (mounted) {
      setState(() {
        isCardEditorOpen = false;
      });
    } else {
      isCardEditorOpen = false;
    }
    if (action == CardEditorAction.addSubCard) {
      _createCard(parent: card);
    } else if (action == CardEditorAction.saved) {
      debugPrint(
        '[HomePage] card editor saved: id=${card.id}, label=${card.label}, '
        'imagePath=${card.imagePath}, voicePath=${card.voicePath}',
      );
      if (onSave != null) {
        onSave(card);
      } else {
        _updateCategories();
        _saveCards();
      }
    }
  }

  void _createCard({AACCard? parent}) {
    if (isCardEditorOpen) return;
    final newCard = AACCard(
      id: DateTime.now().toString(),
      label: 'New',
      colorValue: parent != null
          ? Color.lerp(Color(parent.colorValue), Colors.white, 0.25)!.toARGB32()
          : Colors.primaries[cards.length % Colors.primaries.length].toARGB32(),
      category: parent != null
          ? parent.category
          : (selectedCategory == 'All' ? 'General' : selectedCategory),
    );
    debugPrint(
      '[HomePage] opening create card editor: id=${newCard.id}, '
      'parentId=${parent?.id}',
    );

    _editCard(
      newCard,
      isNew: true,
      onSave: (savedCard) {
        setState(() {
          if (parent != null) {
            parent.type = 'folder';
            parent.subCards.add(savedCard);
            activeParentCard = parent;
            _includeInVisibleSelection(parent.id, savedCard.id);
          } else {
            cards.add(savedCard);
            _includeInVisibleSelection('__root__', savedCard.id);
          }
        });
        _updateCategories();
        _saveCards();
        debugPrint(
          '[HomePage] new card saved: id=${savedCard.id}, '
          'parentId=${parent?.id}, imagePath=${savedCard.imagePath}',
        );
        _setHighlight(savedCard.id);
        _scrollToEnd();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New card created')),
        );
      },
    );
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_gridController.hasClients) return;
      _gridController.animateTo(
        _gridController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSubCards(AACCard card) {
    if (card.type != 'folder') return;
    setState(() {
      _resetTtsInput();
      activeParentCard = card;
    });
  }

  void _confirmDelete(AACCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: const StyledDialogHeader(
          icon: Icons.delete_forever_rounded,
          title: 'Delete Card',
          accentColor: Colors.red,
        ),
        content: Text(
          'Remove "${card.getLabel(currentLanguage)}" from your communication board?',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete'),
            onPressed: () {
              debugPrint(
                '[HomePage] deleting card: id=${card.id}, '
                'label=${card.label}, activeParentId=${activeParentCard?.id}',
              );
              setState(() {
                if (activeParentCard != null) {
                  activeParentCard!.subCards.remove(card);
                } else {
                  cards.remove(card);
                }
              });
              _updateCategories();
              _saveCards();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'si':
        return '\u0dc3\u0dd2\u0d82\u0dc4\u0dbd (Sinhala)';
      case 'ta':
        return '\u0ba4\u0bae\u0bbf\u0bb4\u0bcd (Tamil)';
      default:
        return 'English';
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        void selectLang(String code) {
          setState(() => currentLanguage = code);
          _saveCards();
          Navigator.pop(context);
          Navigator.pop(context);
        }

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          title: const StyledDialogHeader(
            icon: Icons.translate_rounded,
            title: 'Select Language',
            subtitle: 'Board & voice output language',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DialogOptionTile(
                  icon: Icons.language_rounded,
                  badgeText: 'EN',
                  title: 'English',
                  subtitle: 'English labels & speech',
                  selected: currentLanguage == 'en',
                  onTap: () => selectLang('en'),
                ),
                DialogOptionTile(
                  icon: Icons.translate_rounded,
                  badgeText: 'සි',
                  title: '\u0dc3\u0dd2\u0d82\u0dc4\u0dbd (Sinhala)',
                  subtitle: 'සිංහල පුවරු සහ කථනය',
                  selected: currentLanguage == 'si',
                  onTap: () => selectLang('si'),
                ),
                DialogOptionTile(
                  icon: Icons.g_translate_rounded,
                  badgeText: 'த',
                  title: '\u0ba4\u0bae\u0bbf\u0bb4\u0bcd (Tamil)',
                  subtitle: 'தமிழ் பலகை மற்றும் பேச்சு',
                  selected: currentLanguage == 'ta',
                  onTap: () => selectLang('ta'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showCategoryDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: const StyledDialogHeader(
          icon: Icons.category_rounded,
          title: 'Select Category',
          subtitle: 'Filter cards shown on board',
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (MediaQuery.of(context).size.height * 0.55).clamp(180.0, 460.0),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: allCategories
                  .map(
                    (cat) => DialogOptionTile(
                      icon: cat == 'All'
                          ? Icons.apps_rounded
                          : Icons.folder_outlined,
                      title: cat,
                      selected: selectedCategory == cat,
                      onTap: () {
                        setState(() {
                          selectedCategory = cat;
                          activeParentCard = null;
                          _resetTtsInput();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    Navigator.pop(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: const StyledDialogHeader(
          icon: Icons.create_new_folder_rounded,
          title: 'Add New Category',
          subtitle: 'Group related AAC cards together',
        ),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g., Food, School, Emotions',
              prefixIcon: const Icon(Icons.label_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
            onPressed: () {
              final clean = controller.text.trim();
              if (clean.isNotEmpty) {
                setState(() {
                  allCategories.add(clean);
                });
                _saveCards();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "$clean" added!')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showGridOptions() {
    Navigator.pop(context);
    final labels = ['Extra Large', 'Large', 'Medium', 'Small', 'Extra Small'];
    int tempColumns = gridColumns.clamp(1, 5);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            title: const StyledDialogHeader(
              icon: Icons.grid_view_rounded,
              title: 'Select Grid Size',
              subtitle: 'Choose card size & column density',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$tempColumns ${tempColumns == 1 ? 'Column' : 'Columns'} • ${labels[tempColumns - 1]}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Slider(
                    value: (6 - tempColumns).toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: labels[tempColumns - 1],
                    onChanged: (value) {
                      setLocalState(() => tempColumns = 6 - value.round());
                    },
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(
                    labels.length,
                    (index) {
                      final cols = index + 1;
                      return DialogOptionTile(
                        icon: Icons.view_module_rounded,
                        badgeText: '${cols}x',
                        title: labels[index],
                        subtitle: '$cols ${cols == 1 ? 'card' : 'cards'} per row',
                        selected: tempColumns == cols,
                        onTap: () => setLocalState(() => tempColumns = cols),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() => gridColumns = tempColumns);
                  _saveCards();
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmResetSettings() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: StyledDialogHeader(
          icon: Icons.restart_alt_rounded,
          title: 'Reset Settings',
          subtitle: 'Restore default look & layout',
          accentColor: Colors.orange.shade700,
        ),
        content: Text(
          'Reset theme, layout, and display preferences to defaults?\n\nYour AAC cards, images, and voice recordings will stay safe.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Reset'),
            onPressed: () {
              debugPrint(
                '[HomePage] resetting settings only; card data is preserved',
              );
              setState(() {
                gridColumns = 2;
                showTtsInput = true;
                orientationMode = 'portrait';
                fullScreen = true;
                currentLanguage = 'en';
                _themePrimaryColor = _defaultPrimaryColorValue;
                _themeTextColor = Colors.white.value;
                _themeBackgroundColor = Colors.white.value;
                _ttsBarSize = 1.0;
                _showTtsActions = true;
                _hideTtsText = false;
                _useImageOverlayLabel = false;
                _applyTextColorToCards = false;
                _isDarkMode = false;
                _isColorBlindMode = false;
                ThemeAccessibility.darkModeNotifier.value = false;
                selectedCategory = 'All';
                visibleCardIdsByParent.clear();
                _resetTtsInput();
              });
              UiModeHelper.applyOrientation(orientationMode);
              UiModeHelper.applySystemUi(fullScreen);
              _saveCards();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showVisibleCountDialog() {
    Navigator.pop(context);
    final total = _getBaseDisplayedCards().length;
    if (total == 0) return;
    final allCards = _getBaseDisplayedCards();
    showDialog(
      context: context,
      builder: (context) => VisibleCardsDialog(
        cards: allCards,
        currentLanguage: currentLanguage,
        initialSelectedIds: _getVisibleSelection().toSet(),
        onSubmit: (selectedIds) {
          setState(() {
            visibleCardIdsByParent[_visibleSelectionKey()] = selectedIds;
          });
          _saveCards();
        },
      ),
    );
  }

  void _showSearchDialog() {
    final controller = TextEditingController(text: searchQuery);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        final colorScheme = Theme.of(context).colorScheme;
        return AnimatedPadding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: viewInsets.bottom + 24,
            top: 16,
          ),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Material(
            borderRadius: BorderRadius.circular(24),
            color: colorScheme.surface,
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const StyledDialogHeader(
                      icon: Icons.search_rounded,
                      title: 'Search Cards',
                      subtitle: 'Find a word across the current board',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Search cards',
                        hintText: 'Type keyword...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              searchQuery = '';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final pattern = controller.text.trim();
                            if (pattern.isEmpty) {
                              setState(() {
                                searchQuery = '';
                              });
                              Navigator.pop(context);
                              return;
                            }
                            try {
                              RegExp(pattern);
                              setState(() {
                                searchQuery = pattern;
                              });
                              Navigator.pop(context);
                            } catch (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Invalid regex pattern')),
                              );
                            }
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _buildBackupSettings() {
    return {
      'gridColumns': gridColumns,
      'visibleCardIdsByParent': visibleCardIdsByParent.map(
        (key, value) => MapEntry(key, value.toList()),
      ),
      'showTtsInput': showTtsInput,
      'orientationMode': orientationMode,
      'fullScreen': fullScreen,
      'language': currentLanguage,
      'themePrimaryColor': _themePrimaryColor,
      'themeTextColor': _themeTextColor,
      'themeBackgroundColor': _themeBackgroundColor,
      'ttsBarSize': _ttsBarSize,
      'showTtsActions': _showTtsActions,
      'hideTtsText': _hideTtsText,
      'useImageOverlayLabel': _useImageOverlayLabel,
      'applyTextColorToCards': _applyTextColorToCards,
      'darkMode': _isDarkMode,
      'colorBlindMode': _isColorBlindMode,
      'selectedCategory': selectedCategory,
    };
  }

  List<AACCard> _getFilteredCards() {
    if (selectedCategory == 'All') {
      return cards;
    }
    return cards.where((card) => card.category == selectedCategory).toList();
  }

  List<AACCard> _getBaseDisplayedCards() {
    if (activeParentCard != null) {
      return activeParentCard!.subCards;
    }
    return _getFilteredCards();
  }

  List<AACCard> _getDisplayedCards() {
    final base = _getBaseDisplayedCards();
    final visibleIds = _getVisibleSelection();
    if (visibleIds.isEmpty) {
      return _filterBySearch(base);
    }
    return _filterBySearch(
        base.where((card) => visibleIds.contains(card.id)).toList());
  }

  List<AACCard> _filterBySearch(List<AACCard> cardsList) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return cardsList;
    try {
      final regex = RegExp(searchQuery, caseSensitive: false);
      return cardsList
          .where((card) => regex.hasMatch(card.getLabel(currentLanguage)))
          .toList();
    } catch (_) {
      return cardsList;
    }
  }

  String _visibleSelectionKey() {
    return activeParentCard?.id ?? '__root__';
  }

  Set<String> _getVisibleSelection() {
    return visibleCardIdsByParent[_visibleSelectionKey()] ?? {};
  }

  String _getVisibleCardsLabel() {
    final selected = _getVisibleSelection();
    if (selected.isEmpty) {
      return 'All cards';
    }
    return '${selected.length} selected';
  }

  void _includeInVisibleSelection(String parentKey, String cardId) {
    final current = visibleCardIdsByParent[parentKey];
    if (current == null || current.isEmpty) return;
    current.add(cardId);
  }

  void _toggleEditMode() {
    Navigator.pop(context);
    if (isEditMode) {
      _exitEditMode();
    } else {
      _enterEditMode();
    }
  }

  void _enterEditMode() {
    if (isEditMode) return;
    setState(() {
      isEditMode = true;
      _editSnapshotCards = _cloneCards(cards);
      _editSnapshotVisible = _cloneVisibleMap(visibleCardIdsByParent);
      _editSnapshotCategories = Set<String>.from(allCategories);
      _editSnapshotSelectedCategory = selectedCategory;
      _editSnapshotActiveParentId = activeParentCard?.id;
    });
  }

  void _exitEditMode() {
    setState(() {
      isEditMode = false;
      _clearEditSnapshot();
    });
    _saveCards();
  }

  void _clearEditSnapshot() {
    _editSnapshotCards = null;
    _editSnapshotVisible = null;
    _editSnapshotCategories = null;
    _editSnapshotSelectedCategory = null;
    _editSnapshotActiveParentId = null;
  }

  void _undoEditChanges() {
    if (_editSnapshotCards == null) return;
    debugPrint('[HomePage] undoing edit-mode changes from snapshot');
    setState(() {
      cards = _cloneCards(_editSnapshotCards!);
      visibleCardIdsByParent = _cloneVisibleMap(_editSnapshotVisible ?? {});
      allCategories = Set<String>.from(_editSnapshotCategories ?? {'All'});
      selectedCategory = _editSnapshotSelectedCategory ?? 'All';
      activeParentCard = _editSnapshotActiveParentId == null
          ? null
          : _findCardById(_editSnapshotActiveParentId!);
    });
    _saveCards();
  }

  List<AACCard> _cloneCards(List<AACCard> source) {
    return source.map((card) => AACCard.fromJson(card.toJson())).toList();
  }

  Map<String, Set<String>> _cloneVisibleMap(Map<String, Set<String>> source) {
    return source.map(
      (key, value) => MapEntry(key, Set<String>.from(value)),
    );
  }

  AACCard? _findCardById(String id, [List<AACCard>? list]) {
    final cardsList = list ?? cards;
    for (final card in cardsList) {
      if (card.id == id) return card;
      final found = _findCardById(id, card.subCards);
      if (found != null) return found;
    }
    return null;
  }

  void _showOrientationDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) {
        void selectOrientation(String mode) {
          setState(() => orientationMode = mode);
          _saveCards();
          UiModeHelper.applyOrientation(orientationMode);
          Navigator.pop(context);
        }

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          title: const StyledDialogHeader(
            icon: Icons.screen_rotation_rounded,
            title: 'Screen Orientation',
            subtitle: 'Choose preferred layout direction',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DialogOptionTile(
                  icon: Icons.stay_current_portrait_rounded,
                  title: 'Portrait',
                  subtitle: 'Tall card grid with top toolbar',
                  selected: orientationMode != 'landscape',
                  onTap: () => selectOrientation('portrait'),
                ),
                DialogOptionTile(
                  icon: Icons.stay_current_landscape_rounded,
                  title: 'Landscape',
                  subtitle: 'Wide card grid with side rail',
                  selected: orientationMode == 'landscape',
                  onTap: () => selectOrientation('landscape'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showThemeColorDialog({
    required String title,
    required Color initialColor,
    required ValueChanged<Color> onSelected,
  }) {
    Color tempColor = initialColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: StyledDialogHeader(
          icon: Icons.palette_rounded,
          title: title,
          subtitle: 'Pick a color for Normal Mode',
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tempColor,
            onColorChanged: (color) {
              tempColor = color;
            },
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onSelected(tempColor);
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showTtsBarSizeDialog() {
    Navigator.pop(context);
    double tempSize = _ttsBarSize;
    bool tempShowActions = _showTtsActions;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            title: const StyledDialogHeader(
              icon: Icons.format_size_rounded,
              title: 'TTS Bar Sizing',
              subtitle: 'Adjust speech composer bar height',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Size: ${(tempSize * 100).round()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Slider(
                    value: tempSize,
                    min: 0.5,
                    max: 2.5,
                    divisions: 20,
                    label: '${(tempSize * 100).round()}%',
                    onChanged: (value) {
                      setLocalState(() => tempSize = value);
                    },
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: SwitchListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      secondary: const Icon(Icons.backspace_outlined, size: 20),
                      title: const Text(
                        'Show Delete / Clear',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      value: tempShowActions,
                      onChanged: (value) {
                        setLocalState(() => tempShowActions = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _ttsBarSize = 1.0;
                    _showTtsActions = true;
                  });
                  _saveCards();
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _ttsBarSize = tempSize;
                    _showTtsActions = tempShowActions;
                  });
                  _saveCards();
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _backupWithPicker() async {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: const StyledDialogHeader(
          icon: Icons.backup_rounded,
          title: 'Export Backup',
          subtitle: 'Save cards, photos & voices cleanly',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogOptionTile(
                icon: Icons.folder_rounded,
                title: 'App Folder',
                subtitle: 'Save locally inside app storage',
                onTap: () async {
                  Navigator.pop(context);
                  await _backupToAppDocsZip();
                },
              ),
              DialogOptionTile(
                icon: Icons.download_rounded,
                title: 'Downloads',
                subtitle: 'Save aac_backup.zip to Downloads',
                onTap: () async {
                  Navigator.pop(context);
                  await _backupToDownloads();
                },
              ),
              DialogOptionTile(
                icon: Icons.share_rounded,
                title: 'Share Backup',
                subtitle: 'Send zip via messaging or Drive',
                onTap: () async {
                  Navigator.pop(context);
                  await _backupAndShare();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreWithPicker() async {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: const StyledDialogHeader(
          icon: Icons.restore_page_rounded,
          title: 'Import Restore',
          subtitle: 'Restore board & media from zip',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogOptionTile(
                icon: Icons.folder_rounded,
                title: 'App Folder',
                subtitle: 'Restore from saved local zip',
                onTap: () async {
                  Navigator.pop(context);
                  await _restoreFromAppDocsZip();
                },
              ),
              DialogOptionTile(
                icon: Icons.file_open_rounded,
                title: 'Pick Backup File',
                subtitle: 'Browse zip file from device',
                onTap: () async {
                  Navigator.pop(context);
                  await _restoreFromPickedFile();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _backupAndShare() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup started...')),
    );
    final zipBytes = await BackupService.buildBackupZip(
      cards,
      settings: _buildBackupSettings(),
    );
    if (zipBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup failed to create zip')),
      );
      return;
    }
    final docsDir = await getApplicationDocumentsDirectory();
    final path = '${docsDir.path}/aac_backup.zip';
    await File(path).writeAsBytes(zipBytes, flush: true);
    await Share.shareXFiles(
      [XFile(path)],
      text: 'AAC App backup',
    );
  }

  Future<void> _backupToDownloads() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup started...')),
    );
    final zipBytes = await BackupService.buildBackupZip(
      cards,
      settings: _buildBackupSettings(),
    );
    if (zipBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup failed to create zip')),
      );
      return;
    }

    if (Platform.isAndroid && mounted) {
      await AppPermissionsHelper.ensureLegacyStorageIfNeeded(context);
    }

    try {
      final savedPath = await BackupService.saveZipToDownloads(zipBytes);
      if (savedPath == null) {
        throw Exception('Downloads save failed');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup saved to $savedPath')),
      );
    } catch (_) {
      final fallback = await BackupService.saveZipToAppDocs(zipBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot save to Downloads. Backup saved to $fallback',
          ),
        ),
      );
    }
  }

  Future<void> _restoreFromPickedFile() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restore started...')),
    );
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    if (result == null) return;

    final picked = result.files.single;
    final zipBytes = picked.bytes;
    if (zipBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot read selected backup')),
      );
      return;
    }
    final payload = await BackupService.restoreFromZipBytes(zipBytes);
    if (payload.cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup not found in selected file')),
      );
      return;
    }
    _applyRestoredBackup(payload);
  }

  void _applyRestoredBackup(BackupPayload payload) {
    final settings = payload.settings;
    final restoredCards = payload.cards;
    debugPrint(
      '[HomePage] applying restored backup: ${restoredCards.length} '
      'top-level cards, ${CardStorageService.countCards(restoredCards)} '
      'total cards',
    );
    setState(() {
      cards = restoredCards;
      activeParentCard = null;
      selectedCategory = settings['selectedCategory']?.toString() ?? 'All';

      final visibleRaw = settings['visibleCardIdsByParent'];
      if (visibleRaw is Map) {
        visibleCardIdsByParent = visibleRaw.map(
          (key, value) => MapEntry(
            key.toString(),
            (value as List).map((v) => v.toString()).toSet(),
          ),
        );
      } else {
        visibleCardIdsByParent.clear();
      }

      gridColumns = (settings['gridColumns'] as num?)?.toInt() ?? gridColumns;
      showTtsInput = settings['showTtsInput'] as bool? ?? showTtsInput;
      orientationMode =
          settings['orientationMode']?.toString() ?? orientationMode;
      fullScreen = settings['fullScreen'] as bool? ?? fullScreen;
      currentLanguage = settings['language']?.toString() ?? currentLanguage;
      _themePrimaryColor = (settings['themePrimaryColor'] as num?)?.toInt() ??
          _themePrimaryColor;
      _themeTextColor =
          (settings['themeTextColor'] as num?)?.toInt() ?? _themeTextColor;
      _themeBackgroundColor =
          (settings['themeBackgroundColor'] as num?)?.toInt() ??
              _themeBackgroundColor;
      _ttsBarSize = (settings['ttsBarSize'] as num?)?.toDouble() ?? _ttsBarSize;
      _showTtsActions = settings['showTtsActions'] as bool? ?? _showTtsActions;
      _hideTtsText = settings['hideTtsText'] as bool? ?? _hideTtsText;
      _useImageOverlayLabel =
          settings['useImageOverlayLabel'] as bool? ?? _useImageOverlayLabel;
      _applyTextColorToCards =
          settings['applyTextColorToCards'] as bool? ?? _applyTextColorToCards;
      _isDarkMode = settings['darkMode'] as bool? ?? _isDarkMode;
      _isColorBlindMode =
          settings['colorBlindMode'] as bool? ?? _isColorBlindMode;
      ThemeAccessibility.darkModeNotifier.value = _isDarkMode;

      _resetTtsInput();
    });
    _updateCategories();
    if (!allCategories.contains(selectedCategory)) {
      setState(() {
        selectedCategory = 'All';
      });
    }
    UiModeHelper.applyOrientation(orientationMode);
    UiModeHelper.applySystemUi(fullScreen);
    _saveCards();
  }

  Future<void> _backupToAppDocsZip() async {
    final zipBytes = await BackupService.buildBackupZip(
      cards,
      settings: _buildBackupSettings(),
    );
    if (zipBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup failed to create zip')),
      );
      return;
    }
    final path = await BackupService.saveZipToAppDocs(zipBytes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup saved to $path')),
    );
  }

  Future<void> _restoreFromAppDocsZip() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final zipFile = File('${docsDir.path}/aac_backup.zip');
    if (!await zipFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No backup found in app folder')),
      );
      return;
    }
    final payload = await BackupService.restoreFromZipBytes(
      await zipFile.readAsBytes(),
    );
    if (payload.cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup not found in app folder file')),
      );
      return;
    }
    _applyRestoredBackup(payload);
  }

  void _showAbout() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          title: const StyledDialogHeader(
            icon: Icons.forum_rounded,
            title: 'About Simple AAC',
            subtitle: 'Simple AAC Sri Lanka • v1.1.0',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Created to support Sri Lankan children with speech and communication difficulties using an accessible, offline-ready communication board.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_rounded, color: colorScheme.primary),
                  title: const Text('Yasas Pasindu Fernando'),
                  subtitle: const Text('Creator & Developer'),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.email_rounded, color: colorScheme.primary),
                  title: const Text('yasaspasindufernando@gmail.com'),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.phone_rounded, color: colorScheme.primary),
                  title: const Text('+94 77 690 5654'),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final customPrimary = Color(_themePrimaryColor);
    final customText = Color(_themeTextColor);
    final customBackground = Color(_themeBackgroundColor);
    final themePrimary = _isDarkMode ? const Color(0xFF1B263B) : customPrimary;
    final themeText = _isDarkMode ? const Color(0xFFF1F5F9) : customText;
    final themeBackground =
        _isDarkMode ? const Color(0xFF111418) : customBackground;

    return WillPopScope(
      onWillPop: () async {
        if (isPinned) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Screen is locked')),
          );
          return false;
        }
        if (activeParentCard != null) {
          setState(() {
            _resetTtsInput();
            activeParentCard = null;
          });
          return false;
        }
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Press back again to exit')),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: themeBackground,
        appBar: isLandscape
            ? null
            : HomeAppBar(
                title: activeParentCard == null
                    ? 'AAC App'
                    : activeParentCard!.getLabel(currentLanguage),
                titleWidget: activeParentCard == null
                    ? Text(
                        'SL AAC',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          letterSpacing: 0.6,
                          color: themeText,
                        ),
                      )
                    : null,
                backgroundColor: themePrimary,
                showBack: activeParentCard != null && !isPinned,
                onBack: () {
                  setState(() {
                    _resetTtsInput();
                    activeParentCard = null;
                  });
                },
                showPin: true,
                isPinned: isPinned,
                onTogglePin: () {
                  setState(() {
                    isPinned = !isPinned;
                    if (isPinned) {
                      fullScreen = true;
                    }
                  });
                  UiModeHelper.applySystemUi(fullScreen);
                },
                isEditMode: isEditMode,
                showMenu: !isPinned,
                onOpenMenu: () => _scaffoldKey.currentState?.openEndDrawer(),
                titleTextColor: themeText,
              ),
        endDrawer: isPinned
            ? null
            : HomeDrawer(
                selectedCategory: selectedCategory,
                currentLanguageLabel: _getLanguageName(currentLanguage),
                gridColumns: gridColumns,
                visibleCardsLabel: _getVisibleCardsLabel(),
                isEditMode: isEditMode,
                showTtsInput: showTtsInput,
                orientationLabel:
                    orientationMode == 'landscape' ? 'Landscape' : 'Portrait',
                fullScreen: fullScreen,
                headerColor: themePrimary,
                headerTextColor: themeText,
                hideTtsText: _hideTtsText,
                useImageOverlayLabel: _useImageOverlayLabel,
                applyTextColorToCards: _applyTextColorToCards,
                isDarkMode: _isDarkMode,
                isColorBlindMode: _isColorBlindMode,
                primaryColorSwatch: customPrimary,
                textColorSwatch: customText,
                backgroundColorSwatch: customBackground,
                isOnlineEnabled: NetworkPolicyService.instance.isOnlineEnabled,
                onToggleOnline: (enabled) async {
                  await NetworkPolicyService.instance.setOnlineEnabled(enabled);
                  if (mounted) setState(() {});
                },
                onToggleDarkMode: (enabled) async {
                  setState(() {
                    _isDarkMode = enabled;
                  });
                  await ThemeAccessibility.setDarkMode(enabled);
                  await _saveCards();
                },
                onChangeColorBlindMode: (enabled) {
                  setState(() {
                    _isColorBlindMode = enabled;
                  });
                  _saveCards();
                },
                onSelectCategory: _showCategoryDialog,
                onAddCategory: _showAddCategoryDialog,
                onToggleEdit: _toggleEditMode,
                onToggleTtsInput: () {
                  Navigator.pop(context);
                  setState(() {
                    showTtsInput = !showTtsInput;
                  });
                  _saveCards();
                },
                onToggleTtsText: () {
                  Navigator.pop(context);
                  setState(() {
                    _hideTtsText = !_hideTtsText;
                  });
                  _saveCards();
                },
                onToggleCardImageLabel: () {
                  Navigator.pop(context);
                  setState(() {
                    _useImageOverlayLabel = !_useImageOverlayLabel;
                  });
                  _saveCards();
                },
                onToggleApplyTextColorToCards: () {
                  Navigator.pop(context);
                  setState(() {
                    _applyTextColorToCards = !_applyTextColorToCards;
                  });
                  _saveCards();
                },
                onChangeOrientation: _showOrientationDialog,
                onPickPrimaryColor: () {
                  Navigator.pop(context);
                  _showThemeColorDialog(
                    title: 'App color',
                    initialColor: customPrimary,
                    onSelected: (color) {
                      setState(() {
                        _themePrimaryColor = color.value;
                      });
                      _saveCards();
                    },
                  );
                },
                onPickTextColor: () {
                  Navigator.pop(context);
                  _showThemeColorDialog(
                    title: 'Text color',
                    initialColor: customText,
                    onSelected: (color) {
                      setState(() {
                        _themeTextColor = color.value;
                      });
                      _saveCards();
                    },
                  );
                },
                onPickBackgroundColor: () {
                  Navigator.pop(context);
                  _showThemeColorDialog(
                    title: 'Background color',
                    initialColor: customBackground,
                    onSelected: (color) {
                      setState(() {
                        _themeBackgroundColor = color.value;
                      });
                      _saveCards();
                    },
                  );
                },
                onShowTtsBarSize: _showTtsBarSizeDialog,
                onToggleFullScreen: () {
                  Navigator.pop(context);
                  setState(() {
                    fullScreen = !fullScreen;
                  });
                  _saveCards();
                  UiModeHelper.applySystemUi(fullScreen);
                },
                onShowLanguage: _showLanguageDialog,
                onShowGrid: _showGridOptions,
                onShowVisibleCount: _showVisibleCountDialog,
                onBackup: _backupWithPicker,
                onRestore: _restoreWithPicker,
                onResetSettings: _confirmResetSettings,
                onManagePermissions: () async {
                  Navigator.pop(context);
                  await AppPermissionsHelper.requestAllAndShowStatus(context);
                },
                onShowAbout: _showAbout,
              ),
        body: SafeArea(
          child: isLandscape
              ? Row(
                  children: [
                    Expanded(
                      child: Container(
                        color: themeBackground,
                        child: _buildMainContent(
                          isTablet,
                          themePrimary,
                          themeText,
                        ),
                      ),
                    ),
                    LandscapeMenu(
                      isPinned: isPinned,
                      canGoBack: activeParentCard != null,
                      baseColor: themePrimary,
                      textColor: themeText,
                      onTogglePin: () {
                        setState(() {
                          isPinned = !isPinned;
                          if (isPinned) {
                            fullScreen = true;
                          }
                        });
                        UiModeHelper.applySystemUi(fullScreen);
                      },
                      onOpenMenu: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      onGoBack: () {
                        setState(() {
                          _resetTtsInput();
                          activeParentCard = null;
                        });
                      },
                      onHome: () {
                        setState(() {
                          selectedCategory = 'All';
                          activeParentCard = null;
                          searchQuery = '';
                          _resetTtsInput();
                        });
                      },
                      onUp: () {
                        if (!_gridController.hasClients) return;
                        final next = _gridController.offset - 300;
                        _gridController.animateTo(
                          next < 0 ? 0 : next,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      },
                      onDown: () {
                        if (!_gridController.hasClients) return;
                        final max = _gridController.position.maxScrollExtent;
                        final next = _gridController.offset + 300;
                        _gridController.animateTo(
                          next > max ? max : next,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      },
                      onSearch: _showSearchDialog,
                    ),
                  ],
                )
              : Container(
                  color: themeBackground,
                  child: _buildMainContent(isTablet, themePrimary, themeText),
                ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
    bool isTablet,
    Color themePrimary,
    Color themeText,
  ) {
    return Column(
      children: [
        if (isEditMode)
          EditModeBar(
            onDone: _exitEditMode,
            onUndo: _undoEditChanges,
            baseColor: themePrimary,
            textColor: themeText,
            onAdd: () {
              if (!isPinned) {
                _createCard(parent: activeParentCard);
              }
            },
          ),
        if (!isEditMode && showTtsInput)
          TtsBar(
            tokens: _ttsTokens,
            isTablet: isTablet,
            onDelete: _deleteLastWord,
            onClear: _clearTtsInput,
            onSpeak: () async {
              if (_ttsTokens.isNotEmpty) {
                await _playTtsTokens();
              }
            },
            speakerColor: _isDarkMode
                ? Theme.of(context).colorScheme.primary
                : themePrimary,
            sizeFactor: _ttsBarSize,
            showActions: _showTtsActions,
            showText: !_hideTtsText,
          ),
        Expanded(
          child: _getDisplayedCards().isEmpty
              ? Center(
                  child: Text(
                    'No cards in this category. Tap + to add a card!',
                    style: TextStyle(
                        fontSize: isTablet ? 18 : 16, color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  controller: _gridController,
                  padding: EdgeInsets.all(isTablet ? 20 : 12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet
                        ? (gridColumns == 1 ? 2 : gridColumns + 1)
                        : gridColumns,
                    crossAxisSpacing: isTablet ? 16 : 12,
                    mainAxisSpacing: isTablet ? 16 : 12,
                    childAspectRatio: isTablet ? 1.1 : 1.0,
                  ),
                  itemCount: _getDisplayedCards().length,
                  itemBuilder: (context, i) {
                    final card = _getDisplayedCards()[i];
                    return _buildCardWidget(card, isTablet);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCardWidget(AACCard card, bool isTablet) {
    final displayLabel = card.getLabel(currentLanguage);
    final isTapAnimated = _tapAnimatedCardId == card.id;
    final useImageOverlay = _useImageOverlayLabel && card.imagePath != null;
    final cardSurfaceColor = ThemeAccessibility.resolveCardSurface(
      Color(card.colorValue),
      isDarkMode: _isDarkMode,
      isColorBlindMode: _isColorBlindMode,
    );
    final cardTextColor = useImageOverlay
        ? (_applyTextColorToCards ? Color(_themeTextColor) : Colors.white)
        : ThemeAccessibility.resolveCardTextColor(
            cardSurfaceColor,
            isDarkMode: _isDarkMode,
            isColorBlindMode: _isColorBlindMode,
            applyCustomTextColor: _applyTextColorToCards,
            customTextColor: Color(_themeTextColor),
          );
    final useLightShadow = cardTextColor.computeLuminance() > 0.5;
    final cardBorder = highlightedCardId == card.id
        ? Border.all(
            color: _isColorBlindMode
                ? const Color(0xFF0072B2)
                : Colors.yellow.shade200,
            width: 3,
          )
        : _isColorBlindMode
            ? Border.all(
                color: _isDarkMode ? Colors.white54 : Colors.black87,
                width: 2,
              )
            : _isDarkMode
                ? Border.all(color: Colors.white24, width: 1)
                : null;

    return GestureDetector(
      onTap: () async {
        if (isEditMode) {
          _editCard(card);
          return;
        }
        if (card.type == 'folder') {
          if (card.voicePath != null && await File(card.voicePath!).exists()) {
            await _playVoice(card.voicePath!);
          } else {
            await _speak(displayLabel);
          }
          _showSubCards(card);
          return;
        }

        _triggerWordTapAnimation(card.id);
        _appendToTtsInput(
          displayLabel,
          imagePath: card.imagePath,
          voicePath: card.voicePath,
        );
        if (card.voicePath != null && await File(card.voicePath!).exists()) {
          await _playVoice(card.voicePath!);
        } else {
          await _speak(displayLabel);
        }
      },
      child: AnimatedScale(
        scale: isTapAnimated ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: cardSurfaceColor,
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            border: cardBorder,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (!useImageOverlay)
                Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: card.imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(isTablet ? 20 : 16)),
                              child: buildCardImage(
                                card.imagePath!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.broken_image,
                                        size: 60, color: Colors.white70),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Icon(Icons.image,
                                  size: isTablet ? 80 : 60,
                                  color: Colors.white70),
                            ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        child: Text(
                          displayLabel,
                          style: TextStyle(
                            color: cardTextColor,
                            fontSize: isTablet ? 20 : 16,
                            fontWeight: FontWeight.bold,
                            shadows: useLightShadow
                                ? const [
                                    Shadow(
                                      blurRadius: 3,
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              if (useImageOverlay)
                ClipRRect(
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  child: buildCardImage(
                    card.imagePath!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image,
                            size: 60, color: Colors.white70),
                      );
                    },
                  ),
                ),
              if (useImageOverlay)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Text(
                    displayLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cardTextColor,
                      fontSize: isTablet ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.black54,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              if (card.voicePath != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 16),
                  ),
                ),
              if (card.type == 'folder')
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 16),
                  ),
                ),
              if (isEditMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(card),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _tapAnimTimer?.cancel();
    _tts.stop();
    _audioPlayer.dispose();
    _gridController.dispose();
    super.dispose();
  }
}
