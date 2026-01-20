import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../models/aac_card_model.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const MethodChannel _backupChannel = MethodChannel('aac_backup');
  final FlutterTts _tts = FlutterTts();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _textController = TextEditingController();
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
    _applyOrientation();
    _applySystemUi();
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

  void _appendToTtsInput(String text) {
    if (!showTtsInput) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final existing = _textController.text.trim();
    _textController.text =
        existing.isEmpty ? trimmed : '$existing $trimmed';
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  void _clearTtsInput() {
    _textController.clear();
  }

  void _deleteLastWord() {
    final trimmed = _textController.text.trimRight();
    if (trimmed.isEmpty) {
      _textController.clear();
      return;
    }
    final lastSpace = trimmed.lastIndexOf(' ');
    final updated = lastSpace == -1 ? '' : trimmed.substring(0, lastSpace);
    _textController.text = updated;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  Future<void> _playVoice(String path) async {
    await _audioPlayer.play(DeviceFileSource(path));
  }

  String _safeIdForFile(String raw) {
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
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
    final controllerEn = TextEditingController(text: card.label);
    final controllerSi = TextEditingController(text: card.labelSinhala ?? '');
    final controllerTa = TextEditingController(text: card.labelTamil ?? '');
    String selectedCategory = card.category;
    String selectedType = card.type;
    bool isDialogRecording = false;
    double recordProgress = 0.0;
    Timer? recordTimer;
    DateTime? recordStart;
    StreamSubscription<Duration>? positionSub;
    StreamSubscription<Duration>? durationSub;
    StreamSubscription<void>? completeSub;
    Duration playDuration = Duration.zero;
    Duration playPosition = Duration.zero;
    bool isPlaying = false;
    bool createChildAfterClose = false;
    AACCard? createChildParent;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> stopRecording() async {
            if (!isDialogRecording) return;
            recordTimer?.cancel();
            recordTimer = null;
            final path = await _recorder.stop();
            setDialogState(() {
              isDialogRecording = false;
              recordProgress = 0.0;
            });
            if (path != null) {
              setDialogState(() {
                card.voicePath = path;
              });
              _saveCards();
            }
          }

          Future<void> startRecording() async {
            if (isDialogRecording) return;
            final hasPermission = await _recorder.hasPermission();
            if (!hasPermission) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Microphone permission required')),
              );
              return;
            }

            final dir = await getApplicationDocumentsDirectory();
            final safeId = _safeIdForFile(card.id);
            final path =
                '${dir.path}/voice_${safeId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

            await _recorder.start(const RecordConfig(), path: path);
            recordStart = DateTime.now();
            setDialogState(() {
              isDialogRecording = true;
              recordProgress = 0.0;
            });

            recordTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
              if (recordStart == null) return;
              final elapsedMs =
                  DateTime.now().difference(recordStart!).inMilliseconds;
              final progress = (elapsedMs / 15000).clamp(0.0, 1.0);
              setDialogState(() {
                recordProgress = progress;
              });
              if (elapsedMs >= 15000) {
                stopRecording();
              }
            });
          }

          Future<void> stopRecordingIfNeeded() async {
            if (isDialogRecording) {
              await stopRecording();
            }
          }

          void disposePlayback() {
            positionSub?.cancel();
            durationSub?.cancel();
            completeSub?.cancel();
            positionSub = null;
            durationSub = null;
            completeSub = null;
          }

          Future<void> stopPlayback() async {
            if (!isPlaying) return;
            await _audioPlayer.stop();
            setDialogState(() {
              isPlaying = false;
              playPosition = Duration.zero;
            });
          }

          Future<void> startPlayback() async {
            if (isDialogRecording) {
              await stopRecording();
            }
            if (card.voicePath == null) return;
            if (!await File(card.voicePath!).exists()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recorded file not found')),
              );
              return;
            }
            disposePlayback();

            durationSub = _audioPlayer.onDurationChanged.listen((d) {
              setDialogState(() {
                playDuration = d;
              });
            });
            positionSub = _audioPlayer.onPositionChanged.listen((p) {
              setDialogState(() {
                playPosition = p;
              });
            });
            completeSub = _audioPlayer.onPlayerComplete.listen((_) {
              setDialogState(() {
                isPlaying = false;
                playPosition = Duration.zero;
              });
              disposePlayback();
            });

            try {
              await _audioPlayer.play(DeviceFileSource(card.voicePath!));
              setDialogState(() {
                isPlaying = true;
              });
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unable to play recorded audio')),
              );
            }
          }

          return WillPopScope(
            onWillPop: () async {
              await stopRecordingIfNeeded();
              await stopPlayback();
              disposePlayback();
              return true;
            },
            child: AlertDialog(
              title: Text(isNew ? 'Create Card' : 'Edit Card'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controllerEn,
                      decoration: const InputDecoration(
                        labelText: 'English',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controllerSi,
                      decoration: const InputDecoration(
                        labelText: 'Sinhala (?????)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controllerTa,
                      decoration: const InputDecoration(
                        labelText: 'Tamil (?????)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: allCategories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(
                            () => selectedCategory = value ?? 'General');
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'word', child: Text('Word')),
                        DropdownMenuItem(value: 'folder', child: Text('Folder')),
                      ],
                      onChanged: (value) {
                        setDialogState(() => selectedType = value ?? 'word');
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _pickImage(card);
                            },
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Photo'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (isDialogRecording) {
                                await stopRecording();
                              } else {
                                await startRecording();
                              }
                            },
                            icon: Icon(
                                isDialogRecording ? Icons.stop : Icons.mic),
                            label: Text(isDialogRecording ? 'Stop' : 'Voice'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDialogRecording ? Colors.red : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isDialogRecording)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            LinearProgressIndicator(value: recordProgress),
                            const SizedBox(height: 6),
                            Text(
                              'Recording ${(recordProgress * 15).ceil()}/15s',
                            ),
                          ],
                        ),
                      ),
                    if (card.voicePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(isPlaying
                                      ? Icons.stop
                                      : Icons.play_arrow),
                                  onPressed: () async {
                                    if (isPlaying) {
                                      await stopPlayback();
                                    } else {
                                      await startPlayback();
                                    }
                                  },
                                ),
                                const Text('Play Recorded Voice'),
                              ],
                            ),
                            Slider(
                              value: playDuration.inMilliseconds == 0
                                  ? 0
                                  : playPosition.inMilliseconds
                                      .clamp(0, playDuration.inMilliseconds)
                                      .toDouble(),
                              max: playDuration.inMilliseconds == 0
                                  ? 1
                                  : playDuration.inMilliseconds.toDouble(),
                              onChanged: (value) async {
                                if (playDuration.inMilliseconds == 0) return;
                                final position =
                                    Duration(milliseconds: value.toInt());
                                await _audioPlayer.seek(position);
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: isNew
                          ? null
                          : () {
                              createChildAfterClose = true;
                              createChildParent = card;
                              Navigator.pop(context);
                            },
                      icon: const Icon(Icons.add_box),
                      label: const Text('Add Sub-Card'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await stopRecordingIfNeeded();
                    await stopPlayback();
                    disposePlayback();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await stopRecordingIfNeeded();
                    await stopPlayback();
                    disposePlayback();
                    setState(() {
                      card.label = controllerEn.text;
                      card.labelSinhala =
                          controllerSi.text.isEmpty ? null : controllerSi.text;
                      card.labelTamil =
                          controllerTa.text.isEmpty ? null : controllerTa.text;
                      card.category = selectedCategory;
                      card.type = selectedType;
                      if (card.type == 'word') {
                        card.subCards.clear();
                      }
                    });
                    if (onSave != null) {
                      onSave(card);
                    } else {
                      _updateCategories();
                      _saveCards();
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
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
    if (createChildAfterClose && createChildParent != null) {
      _createCard(parent: createChildParent);
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
      _textController.clear();
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
    final selectedIds = _getVisibleSelection().toSet();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final hasSelection = selectedIds.isNotEmpty;
          return AlertDialog(
            title: Row(
              children: [
                const Expanded(child: Text('Visible Cards')),
                IconButton(
                  icon: Icon(hasSelection ? Icons.clear_all : Icons.select_all),
                  tooltip: hasSelection ? 'Clear All' : 'Select All',
                  onPressed: () {
                    setDialogState(() {
                      if (hasSelection) {
                        selectedIds.clear();
                      } else {
                        selectedIds
                          ..clear()
                          ..addAll(allCards.map((c) => c.id));
                      }
                    });
                  },
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: allCards.map((card) {
                  final label = card.getLabel(currentLanguage);
                  final checked = selectedIds.contains(card.id);
                  final isFolder = card.type == 'folder';
                  return CheckboxListTile(
                    value: checked,
                    title: Row(
                      children: [
                        Text(label),
                        if (isFolder) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.folder, size: 16),
                        ],
                      ],
                    ),
                    secondary: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: card.imagePath != null
                            ? Image.file(
                                File(card.imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.image, size: 18);
                                },
                              )
                            : const Icon(Icons.image, size: 18),
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedIds.add(card.id);
                        } else {
                          selectedIds.remove(card.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    visibleCardIdsByParent[_visibleSelectionKey()] = selectedIds;
                  });
                  _saveCards();
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
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
      return base;
    }
    return base.where((card) => visibleIds.contains(card.id)).toList();
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
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  void _applyOrientation() {
    if (orientationMode == 'landscape') {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _applySystemUi() {
    if (fullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
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
                _applyOrientation();
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
                _applyOrientation();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? path : parts.last;
  }

  Future<void> _backupToDirectory(
    Directory backupDir, {
    bool showSnack = true,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final filesDir = Directory('${backupDir.path}/files');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    if (!await filesDir.exists()) {
      await filesDir.create(recursive: true);
    }

    final Map<String, String> pathMap = {};
    final Map<String, int> nameCounts = {};

    Future<String?> copyMedia(String? path) async {
      if (path == null) return null;
      final file = File(path);
      if (!await file.exists()) return null;
      if (pathMap.containsKey(path)) return pathMap[path];

      final base = _basename(path);
      final dot = base.lastIndexOf('.');
      final name = dot == -1 ? base : base.substring(0, dot);
      final ext = dot == -1 ? '' : base.substring(dot);
      final count = (nameCounts[base] ?? 0) + 1;
      nameCounts[base] = count;
      final fileName = count == 1 ? base : '${name}_$count$ext';
      final destPath = '${filesDir.path}/$fileName';

      await file.copy(destPath);
      final relPath = 'files/$fileName';
      pathMap[path] = relPath;
      return relPath;
    }

    Future<AACCard> cloneCard(AACCard card) async {
      final imagePath = await copyMedia(card.imagePath);
      final voicePath = await copyMedia(card.voicePath);
      final cloned = AACCard(
        id: card.id,
        label: card.label,
        labelSinhala: card.labelSinhala,
        labelTamil: card.labelTamil,
        imagePath: imagePath,
        voicePath: voicePath,
        category: card.category,
        colorValue: card.colorValue,
        type: card.type,
        subCards: [],
      );
      for (final sub in card.subCards) {
        cloned.subCards.add(await cloneCard(sub));
      }
      return cloned;
    }

    final List<AACCard> clonedCards = [];
    for (final card in cards) {
      clonedCards.add(await cloneCard(card));
    }

    final manifestFile = File('${backupDir.path}/cards.json');
    await manifestFile.writeAsString(
      jsonEncode(clonedCards.map((c) => c.toJson()).toList()),
    );

    if (showSnack) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup saved to ${backupDir.path}')),
      );
    }
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

  // Deprecated: replaced by share-based backup.

  Future<void> _restoreFromDirectory(Directory backupDir) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final manifestFile = File('${backupDir.path}/cards.json');
    if (!await manifestFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup not found')),
      );
      return;
    }

    final decoded = jsonDecode(await manifestFile.readAsString()) as List;
    final restored = decoded.map((c) => AACCard.fromJson(c)).toList();

    Future<String?> restoreMedia(String? relPath) async {
      if (relPath == null) return null;
      final sourcePath = '${backupDir.path}/${relPath.replaceAll('\\', '/')}';
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      final base = _basename(sourcePath);
      final destPath = '${docsDir.path}/$base';
      var targetPath = destPath;
      var counter = 1;
      while (await File(targetPath).exists()) {
        final dot = base.lastIndexOf('.');
        final name = dot == -1 ? base : base.substring(0, dot);
        final ext = dot == -1 ? '' : base.substring(dot);
        targetPath = '${docsDir.path}/${name}_$counter$ext';
        counter++;
      }
      await sourceFile.copy(targetPath);
      return targetPath;
    }

    Future<void> fixCard(AACCard card) async {
      card.imagePath = await restoreMedia(card.imagePath);
      card.voicePath = await restoreMedia(card.voicePath);
      for (final sub in card.subCards) {
        await fixCard(sub);
      }
    }

    for (final card in restored) {
      await fixCard(card);
    }

    setState(() {
      cards = restored;
      activeParentCard = null;
      selectedCategory = 'All';
      visibleCardIdsByParent.clear();
    });
    _updateCategories();
    _saveCards();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup restored from ${backupDir.path}')),
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
    final zipBytes = await _buildBackupZip();
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
    final zipBytes = await _buildBackupZip();
    if (zipBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup failed to create zip')),
      );
      return;
    }

    await Permission.storage.request();

    try {
      final savedPath = await _saveZipToDownloads(zipBytes);
      if (savedPath == null) {
        throw Exception('Downloads save failed');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup saved to $savedPath')),
      );
    } catch (_) {
      final fallback = await _saveBackupToAppDocs(zipBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot save to Downloads. Backup saved to $fallback',
          ),
        ),
      );
    }
  }

  Future<String?> _saveZipToDownloads(List<int> zipBytes) async {
    try {
      final result = await _backupChannel.invokeMethod<String>(
        'saveToDownloads',
        {
          'fileName': 'aac_backup.zip',
          'bytes': Uint8List.fromList(zipBytes),
        },
      );
      return result;
    } on PlatformException {
      return null;
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
    final zipPath = picked.path;
    final tempDir = await Directory.systemTemp.createTemp('aac_restore_');
    if (zipBytes != null) {
      await _extractZipBytesToDirectory(zipBytes, tempDir);
    } else if (zipPath != null) {
      await _extractZipToDirectory(zipPath, tempDir);
    } else {
      await tempDir.delete(recursive: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot read selected backup')),
      );
      return;
    }

    final directManifest = File('${tempDir.path}/cards.json');
    final nestedManifest = File('${tempDir.path}/AAC_Backup/cards.json');
    if (await directManifest.exists()) {
      await _restoreFromDirectory(tempDir);
    } else if (await nestedManifest.exists()) {
      await _restoreFromDirectory(Directory('${tempDir.path}/AAC_Backup'));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup not found in selected file')),
      );
    }

    await tempDir.delete(recursive: true);
  }

  Future<void> _backupToAppDocsZip() async {
    final zipBytes = await _buildBackupZip();
    if (zipBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup failed to create zip')),
      );
      return;
    }
    final path = await _saveBackupToAppDocs(zipBytes);
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
    final tempDir = await Directory.systemTemp.createTemp('aac_restore_');
    await _extractZipToDirectory(zipFile.path, tempDir);

    final directManifest = File('${tempDir.path}/cards.json');
    final nestedManifest = File('${tempDir.path}/AAC_Backup/cards.json');
    if (await directManifest.exists()) {
      await _restoreFromDirectory(tempDir);
    } else if (await nestedManifest.exists()) {
      await _restoreFromDirectory(Directory('${tempDir.path}/AAC_Backup'));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup not found in app folder file')),
      );
    }
    await tempDir.delete(recursive: true);
  }

  List<int> _zipDirectory(Directory dir) {
    final archive = Archive();
    final rootPath = dir.path.replaceAll('\\', '/');
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File) {
        final filePath = entity.path.replaceAll('\\', '/');
        final relPath = filePath.startsWith(rootPath)
            ? filePath.substring(rootPath.length + 1)
            : filePath;
        final data = entity.readAsBytesSync();
        archive.addFile(ArchiveFile(relPath, data.length, data));
      }
    }
    final zipEncoder = ZipEncoder();
    return zipEncoder.encode(archive) ?? <int>[];
  }

  Future<List<int>?> _buildBackupZip() async {
    final tempDir = await Directory.systemTemp.createTemp('aac_backup_');
    final backupRoot = Directory('${tempDir.path}/AAC_Backup');
    try {
      await _backupToDirectory(backupRoot, showSnack: false);
      final zipBytes = _zipDirectory(backupRoot);
      return zipBytes;
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  Future<String> _saveBackupToAppDocs(List<int> zipBytes) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = '${docsDir.path}/aac_backup.zip';
    await File(path).writeAsBytes(zipBytes, flush: true);
    return path;
  }

  Future<void> _extractZipToDirectory(String zipPath, Directory target) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final name = file.name.replaceAll('\\', '/');
      final outPath = '${target.path}/$name';
      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>, flush: true);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }
  }

  Future<void> _extractZipBytesToDirectory(
    List<int> bytes,
    Directory target,
  ) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final name = file.name.replaceAll('\\', '/');
      final outPath = '${target.path}/$name';
      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>, flush: true);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }
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
            _textController.clear();
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
        appBar: HomeAppBar(
          title: activeParentCard == null
              ? 'AAC App'
              : activeParentCard!.getLabel(currentLanguage),
          backgroundColor: Colors.blue.shade700,
          showBack: activeParentCard != null && !isPinned,
          onBack: () {
            setState(() {
              _textController.clear();
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
            _applySystemUi();
          },
          isEditMode: isEditMode,
          showMenu: !isPinned,
          onAdd: () {
            if (!isPinned) {
              _createCard(parent: activeParentCard);
            }
          },
          onDone: () {
            setState(() {
              isEditMode = false;
            });
          },
          onCancel: () {
            setState(() {
              isEditMode = false;
            });
          },
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
                  _applySystemUi();
                },
                onShowLanguage: _showLanguageDialog,
                onShowGrid: _showGridOptions,
                onShowVisibleCount: _showVisibleCountDialog,
                onBackup: _backupWithPicker,
                onRestore: _restoreWithPicker,
                onShowAbout: _showAbout,
              ),
        body: Column(
          children: [
            if (showTtsInput)
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                color: Colors.grey.shade200,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(fontSize: isTablet ? 18 : 16),
                      decoration: InputDecoration(
                        hintText: 'Type to speak...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 20 : 16,
                          vertical: isTablet ? 16 : 12,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: _deleteLastWord,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.backspace, size: 18),
                                    SizedBox(height: 2),
                                    Text(
                                      'Delete',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _clearTtsInput,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.clear, size: 18),
                                    SizedBox(height: 2),
                                    Text(
                                      'Clear',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.volume_up, size: isTablet ? 36 : 28),
                        color: Colors.white,
                        onPressed: () {
                          if (_textController.text.isNotEmpty) {
                            _speak(_textController.text);
                          }
                        },
                      ),
                    ),
                  ],
                ),
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
        ),
      ),
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

        _appendToTtsInput(displayLabel);
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
    _recorder.dispose();
    _textController.dispose();
    _gridController.dispose();
    super.dispose();
  }
}
