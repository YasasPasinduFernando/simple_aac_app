import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../models/aac_card_model.dart';
import '../models/tts_token.dart';
import '../services/backup_service.dart';
import '../services/card_storage_service.dart';
import '../widgets/card_editor_dialog.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/edit_mode_bar.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_drawer.dart';
import '../widgets/landscape_menu.dart';
import '../widgets/tts_bar.dart';
import '../widgets/visible_cards_dialog.dart';
import '../utils/card_image.dart';
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
  int _themePrimaryColor = Colors.brown.value;
  int _themeTextColor = Colors.white.value;
  int _themeBackgroundColor = Colors.white.value;
  double _ttsBarSize = 1.0;
  bool _showTtsActions = true;
  bool _hideTtsText = false;
  bool _useImageOverlayLabel = false;
  bool _applyTextColorToCards = false;

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
    final String? saved = _encodeCardsForLoad(loadedCards);

    if (saved != null) {
      final List decoded = jsonDecode(saved);
      setState(() {
        cards = decoded.map((c) => AACCard.fromJson(c)).toList();
      });
    } else {
      setState(() {
        cards = [
          AACCard(
            id: '1',
            label: 'Hello',
            labelSinhala: 'ආයුබෝවන්',
            labelTamil: 'வணக்கம்',
            colorValue: Colors.pink.shade300.value,
          ),
          AACCard(
            id: '2',
            label: 'Food',
            labelSinhala: 'ආහාර',
            labelTamil: 'உணவு',
            colorValue: Colors.orange.shade300.value,
            subCards: [
              AACCard(
                id: '2-1',
                label: 'Rice',
                labelSinhala: 'බත්',
                labelTamil: 'சோறு',
                colorValue: Colors.orange.shade200.value,
              ),
              AACCard(
                id: '2-2',
                label: 'Bread',
                labelSinhala: 'පාන්',
                labelTamil: 'ரொட்டி',
                colorValue: Colors.orange.shade200.value,
              ),
            ],
          ),
          AACCard(
            id: '3',
            label: 'Water',
            labelSinhala: 'වතුර',
            labelTamil: 'தண்ணீர்',
            colorValue: Colors.blue.shade300.value,
          ),
          AACCard(
            id: '4',
            label: 'Help',
            labelSinhala: 'උදව්',
            labelTamil: 'உதவி',
            colorValue: Colors.red.shade300.value,
          ),
        ];
      });
    }

    gridColumns = prefs.getInt('gridColumns') ?? 2;
    _loadVisibleSelections(prefs);
    showTtsInput = prefs.getBool('showTtsInput') ?? true;
    orientationMode = prefs.getString('orientationMode') ?? 'portrait';
    fullScreen = prefs.getBool('fullScreen') ?? true;
    currentLanguage = prefs.getString('language') ?? 'en';
    _themePrimaryColor =
        prefs.getInt('themePrimaryColor') ?? Colors.brown.value;
    _themeTextColor = prefs.getInt('themeTextColor') ?? Colors.white.value;
    _themeBackgroundColor =
        prefs.getInt('themeBackgroundColor') ?? Colors.white.value;
    _ttsBarSize = prefs.getDouble('ttsBarSize') ?? 1.0;
    _showTtsActions = prefs.getBool('showTtsActions') ?? true;
    _hideTtsText = prefs.getBool('hideTtsText') ?? false;
    _useImageOverlayLabel = prefs.getBool('useImageOverlayLabel') ?? false;
    _applyTextColorToCards = prefs.getBool('applyTextColorToCards') ?? false;

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

  String? _encodeCardsForLoad(List<AACCard> loadedCards) {
    return jsonEncode(loadedCards.map((c) => c.toJson()).toList());
  }

  List<AACCard> _createSeedImageCards() {
    return [
      AACCard(
        id: 'seed_hello',
        label: 'Hello',
        imagePath: 'assets/images/seed/hello.png',
        colorValue: Colors.yellow.shade300.value,
      ),
      AACCard(
        id: 'seed_happy',
        label: 'Happy',
        imagePath: 'assets/images/seed/happy.png',
        colorValue: Colors.lightBlue.shade200.value,
      ),
      AACCard(
        id: 'seed_sad',
        label: 'Sad',
        imagePath: 'assets/images/seed/sad.png',
        colorValue: Colors.lightBlue.shade300.value,
      ),
      AACCard(
        id: 'seed_angry',
        label: 'Angry',
        imagePath: 'assets/images/seed/angry.png',
        colorValue: Colors.red.shade300.value,
      ),
      AACCard(
        id: 'seed_more',
        label: 'More',
        colorValue: Colors.indigo.shade500.value,
      ),
      AACCard(
        id: 'seed_rotation_turn_change',
        label: 'Rotation/Turn/Change',
        imagePath: 'assets/images/seed/turn.png',
        colorValue: Colors.teal.shade300.value,
      ),
      AACCard(
        id: 'seed_blocks_toys_play',
        label: 'Blocks/Toys/Play',
        imagePath: 'assets/images/seed/blocks.png',
        colorValue: Colors.deepPurple.shade300.value,
      ),
    ];
  }

  // ignore: unused_element
  List<AACCard> _createDefaultCards() {
    return _createSeedImageCards();
    /*
    final defaultCards = <AACCard>[
      AACCard(
        id: '1',
        label: 'Hello',
        labelSinhala: 'à¶†à¶ºà·”à¶¶à·à·€à¶±à·Š',
        labelTamil: 'à®µà®£à®•à¯à®•à®®à¯',
        colorValue: Colors.pink.shade300.value,
      ),
      AACCard(
        id: '2',
        label: 'Food',
        labelSinhala: 'à¶†à·„à·à¶»',
        labelTamil: 'à®‰à®£à®µà¯',
        colorValue: Colors.orange.shade300.value,
        subCards: [
          AACCard(
            id: '2-1',
            label: 'Rice',
            labelSinhala: 'à¶¶à¶­à·Š',
            labelTamil: 'à®šà¯‹à®±à¯',
            colorValue: Colors.orange.shade200.value,
          ),
          AACCard(
            id: '2-2',
            label: 'Bread',
            labelSinhala: 'à¶´à·à¶±à·Š',
            labelTamil: 'à®°à¯Šà®Ÿà¯à®Ÿà®¿',
            colorValue: Colors.orange.shade200.value,
          ),
        ],
      ),
      AACCard(
        id: '3',
        label: 'Water',
        labelSinhala: 'à·€à¶­à·”à¶»',
        labelTamil: 'à®¤à®£à¯à®£à¯€à®°à¯',
        colorValue: Colors.blue.shade300.value,
      ),
      AACCard(
        id: '4',
        label: 'Help',
        labelSinhala: 'à¶‹à¶¯à·€à·Š',
        labelTamil: 'à®‰à®¤à®µà®¿',
        colorValue: Colors.red.shade300.value,
      ),
    ];
    defaultCards[0].labelSinhala =
        '\u0d86\u0dba\u0dd4\u0db6\u0ddd\u0dc0\u0db1\u0dca';
    defaultCards[0].labelTamil = '\u0bb5\u0ba3\u0b95\u0bcd\u0b95\u0bae\u0bcd';
    defaultCards[1].labelSinhala = '\u0d86\u0dc4\u0dcf\u0dbb';
    defaultCards[1].labelTamil = '\u0b89\u0ba3\u0bb5\u0bc1';
    defaultCards[1].subCards[0].labelSinhala = '\u0db6\u0dad\u0dca';
    defaultCards[1].subCards[0].labelTamil = '\u0b9a\u0bcb\u0bb1\u0bc1';
    defaultCards[1].subCards[1].labelSinhala = '\u0db4\u0dcf\u0db1\u0dca';
    defaultCards[1].subCards[1].labelTamil =
        '\u0bb0\u0bca\u0b9f\u0bcd\u0b9f\u0bbf';
    defaultCards[2].labelSinhala = '\u0dc0\u0dad\u0dd4\u0dbb';
    defaultCards[2].labelTamil = '\u0ba4\u0ba3\u0bcd\u0ba3\u0bc0\u0bb0\u0bcd';
    defaultCards[3].labelSinhala = '\u0d8b\u0daf\u0dc0\u0dca';
    defaultCards[3].labelTamil = '\u0b89\u0ba4\u0bb5\u0bbf';
    return defaultCards;
    */
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
        title: const Text('Choose source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        try {
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
        } catch (error, stackTrace) {
          debugPrint('[HomePage] image save failed: $error');
          debugPrint(stackTrace.toString());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image could not be saved')),
            );
          }
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
          ? Color(parent.colorValue).withOpacity(0.7).value
          : Colors.primaries[cards.length % Colors.primaries.length].value,
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
        title: const Text('Delete Card'),
        content: Text('Delete "${card.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
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
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'si':
        return 'සිංහල (Sinhala)';
      case 'ta':
        return 'தமிழ் (Tamil)';
      default:
        return 'English';
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLanguage,
              onChanged: (value) {
                setState(() => currentLanguage = value!);
                _saveCards();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('සිංහල (Sinhala)'),
              value: 'si',
              groupValue: currentLanguage,
              onChanged: (value) {
                setState(() => currentLanguage = value!);
                _saveCards();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('தமிழ் (Tamil)'),
              value: 'ta',
              groupValue: currentLanguage,
              onChanged: (value) {
                setState(() => currentLanguage = value!);
                _saveCards();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...allCategories.map((cat) => RadioListTile<String>(
                  title: Text(cat),
                  value: cat,
                  groupValue: selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                      activeParentCard = null;
                      _resetTtsInput();
                    });
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    Navigator.pop(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
            hintText: 'Enter category name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  allCategories.add(controller.text);
                });
                _saveCards();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Category "${controller.text}" added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showGridOptions() {
    Navigator.pop(context);
    final labels = ['Extra Large', 'Large', 'Medium', 'Small', 'Extra Small'];
    int tempColumns = gridColumns;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Grid Size'),
        content: StatefulBuilder(
          builder: (context, setLocalState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                Text(labels[tempColumns - 1]),
                const SizedBox(height: 8),
                ...List.generate(
                  labels.length,
                  (index) => RadioListTile<int>(
                    title: Text(labels[index]),
                    value: index + 1,
                    groupValue: tempColumns,
                    onChanged: (value) {
                      setLocalState(() => tempColumns = value ?? tempColumns);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => gridColumns = tempColumns);
              _saveCards();
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _confirmResetSettings() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Reset all settings to defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
                _themePrimaryColor = Colors.brown.value;
                _themeTextColor = Colors.white.value;
                _themeBackgroundColor = Colors.white.value;
                _ttsBarSize = 1.0;
                _showTtsActions = true;
                _hideTtsText = false;
                _useImageOverlayLabel = false;
                _applyTextColorToCards = false;
                selectedCategory = 'All';
                visibleCardIdsByParent.clear();
                _resetTtsInput();
              });
              UiModeHelper.applyOrientation(orientationMode);
              UiModeHelper.applySystemUi(fullScreen);
              _saveCards();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
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
        return AnimatedPadding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: viewInsets.bottom + 32,
            top: 16,
          ),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Material(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).dialogBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Search cards',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
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
                        ElevatedButton(
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
      builder: (context) => AlertDialog(
        title: const Text('Orientation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Portrait'),
              value: 'portrait',
              groupValue: orientationMode,
              onChanged: (value) {
                setState(() => orientationMode = value ?? 'portrait');
                _saveCards();
                UiModeHelper.applyOrientation(orientationMode);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Landscape'),
              value: 'landscape',
              groupValue: orientationMode,
              onChanged: (value) {
                setState(() => orientationMode = value ?? 'landscape');
                _saveCards();
                UiModeHelper.applyOrientation(orientationMode);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
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
        title: Text(title),
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
          ElevatedButton(
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
      builder: (context) => AlertDialog(
        title: const Text('TTS Bar Size'),
        content: StatefulBuilder(
          builder: (context, setLocalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Text('Size: ${(tempSize * 100).round()}%'),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Delete/Clear'),
                value: tempShowActions,
                onChanged: (value) {
                  setLocalState(() => tempShowActions = value);
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
          ElevatedButton(
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
      ),
    );
  }

  Future<void> _backupWithPicker() async {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup'),
        content: const Text('Choose how to save the backup file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _backupToAppDocsZip();
            },
            child: const Text('App Folder'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _backupToDownloads();
            },
            child: const Text('Download'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _backupAndShare();
            },
            child: const Text('Share'),
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
        title: const Text('Restore'),
        content: const Text('Choose a backup file to restore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _restoreFromAppDocsZip();
            },
            child: const Text('App Folder'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _restoreFromPickedFile();
            },
            child: const Text('Pick File'),
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

    await Permission.storage.request();

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
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: const Text(
          'Created by Yasas Pasindu Fernando\n'
          'Email: yasaspasindufernando@gmail.com\n'
          'Tel: +94776905654\n\n'
          'Created to help Sri Lankan autism children by giving them '
          'a good application for their development.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final themePrimary = Color(_themePrimaryColor);
    final themeText = Color(_themeTextColor);
    final themeBackground = Color(_themeBackgroundColor);

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
                        style: GoogleFonts.playfairDisplay(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          letterSpacing: 1.0,
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
                    initialColor: themePrimary,
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
                    initialColor: themeText,
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
                    initialColor: themeBackground,
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
            speakerColor: themePrimary,
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
    final cardTextColor =
        _applyTextColorToCards ? Color(_themeTextColor) : Colors.white;

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
        scale: isTapAnimated ? 1.5 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Color(card.colorValue),
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            border: highlightedCardId == card.id
                ? Border.all(color: Colors.yellow.shade200, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
