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
import '../widgets/card_editor_dialog.dart';
import '../widgets/edit_mode_bar.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_drawer.dart';
import '../widgets/landscape_menu.dart';
import '../widgets/tts_bar.dart';
import '../widgets/visible_cards_dialog.dart';
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
  Timer? _highlightTimer;
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

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadCards();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('cards');

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

    _updateCategories();
    _migrateVisibleCountIfNeeded(prefs);
    UiModeHelper.applyOrientation(orientationMode);
    UiModeHelper.applySystemUi(fullScreen);
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

  void _appendToTtsInput(String text, {String? imagePath}) {
    if (!showTtsInput) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _ttsTokens.add(TtsToken(trimmed, imagePath));
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

  Future<void> _playVoice(String path) async {
    await _audioPlayer.play(DeviceFileSource(path));
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
        setState(() {
          card.imagePath = image.path;
        });
        _saveCards();
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Grid Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            labels.length,
            (index) => _buildGridOption(
              index + 1,
              labels[index],
            ),
          ),
        ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Search cards',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
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
                  const SnackBar(content: Text('Invalid regex pattern')),
                );
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildGridOption(int columns, String label) {
    return RadioListTile<int>(
      title: Text(label),
      value: columns,
      groupValue: gridColumns,
      onChanged: (value) {
        setState(() => gridColumns = value!);
        _saveCards();
        Navigator.pop(context);
      },
    );
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
    setState(() {
      cards = _cloneCards(_editSnapshotCards!);
      visibleCardIdsByParent =
          _cloneVisibleMap(_editSnapshotVisible ?? {});
      allCategories =
          Set<String>.from(_editSnapshotCategories ?? {'All'});
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

  Map<String, Set<String>> _cloneVisibleMap(
      Map<String, Set<String>> source) {
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
    final zipBytes = await BackupService.buildBackupZip(cards);
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
    final zipBytes = await BackupService.buildBackupZip(cards);
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
    final restored = await BackupService.restoreFromZipBytes(zipBytes);
    if (restored.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup not found in selected file')),
      );
      return;
    }
    _applyRestoredCards(restored);
  }

  void _applyRestoredCards(List<AACCard> restored) {
    setState(() {
      cards = restored;
      activeParentCard = null;
      selectedCategory = 'All';
      visibleCardIdsByParent.clear();
      _resetTtsInput();
    });
    _updateCategories();
    _saveCards();
  }

  Future<void> _backupToAppDocsZip() async {
    final zipBytes = await BackupService.buildBackupZip(cards);
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
    final restored = await BackupService.restoreFromZipBytes(
      await zipFile.readAsBytes(),
    );
    if (restored.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup not found in app folder file')),
      );
      return;
    }
    _applyRestoredCards(restored);
  }

  void _showAbout() {
    Navigator.pop(context);
    showAboutDialog(
      context: context,
      applicationName: 'AAC App',
      applicationVersion: '1.0.0',
      children: [
        const Text('Augmentative and Alternative Communication App'),
        const SizedBox(height: 8),
        const Text('Supports English, Sinhala, and Tamil'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
        appBar: isLandscape
            ? null
            : HomeAppBar(
                title: activeParentCard == null
                    ? 'AAC App'
                    : activeParentCard!.getLabel(currentLanguage),
                backgroundColor: Colors.brown.shade700,
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
                orientationLabel: orientationMode == 'landscape'
                    ? 'Landscape'
                    : 'Portrait',
                fullScreen: fullScreen,
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
                onChangeOrientation: _showOrientationDialog,
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
                onShowAbout: _showAbout,
              ),
        body: SafeArea(
          child: isLandscape
              ? Row(
                  children: [
                    Expanded(child: _buildMainContent(isTablet)),
                    LandscapeMenu(
                      isPinned: isPinned,
                      canGoBack: activeParentCard != null,
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
              : _buildMainContent(isTablet),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isTablet) {
    return Column(
      children: [
        if (isEditMode)
          EditModeBar(
            onDone: _exitEditMode,
            onUndo: _undoEditChanges,
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
            onSpeak: () {
              if (_ttsTokens.isNotEmpty) {
                final text = _ttsTokens.map((t) => t.label).join(' ');
                _speak(text);
              }
            },
          ),
        Expanded(
          child: _getDisplayedCards().isEmpty
              ? Center(
                  child: Text(
                    'No cards in this category. Tap + to add a card!',
                    style:
                        TextStyle(fontSize: isTablet ? 18 : 16, color: Colors.grey),
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

        _appendToTtsInput(displayLabel, imagePath: card.imagePath);
        if (card.voicePath != null && await File(card.voicePath!).exists()) {
          await _playVoice(card.voicePath!);
        } else {
          await _speak(displayLabel);
        }
      },
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
            Column(
              children: [
                Expanded(
                  flex: 3,
                  child: card.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(isTablet ? 20 : 16)),
                          child: Image.file(
                            File(card.imagePath!),
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
                              size: isTablet ? 80 : 60, color: Colors.white70),
                        ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    child: Text(
                      displayLabel,
                      style: TextStyle(
                        color: Colors.white,
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
    );
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _tts.stop();
    _audioPlayer.dispose();
    _gridController.dispose();
    super.dispose();
  }
}
