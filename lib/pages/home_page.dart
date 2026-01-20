import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/aac_card_model.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterTts _tts = FlutterTts();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _textController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<AACCard> cards = [];
  int gridColumns = 2;
  Map<String, Set<String>> visibleCardIdsByParent = {};
  String currentLanguage = 'en';
  bool showTtsInput = true;
  String selectedCategory = 'All';
  Set<String> allCategories = {'General'};
  AACCard? activeParentCard;
  bool isEditMode = false;

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
    currentLanguage = prefs.getString('language') ?? 'en';

    _updateCategories();
    _migrateVisibleCountIfNeeded(prefs);
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

  void _editCard(AACCard card) {
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

    showDialog(
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
              setState(() {
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
            final path =
                '${dir.path}/voice_${card.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';

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
            if (card.voicePath == null) return;
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

            await _audioPlayer.play(DeviceFileSource(card.voicePath!));
            setDialogState(() {
              isPlaying = true;
            });
          }

          return WillPopScope(
            onWillPop: () async {
              await stopRecordingIfNeeded();
              await stopPlayback();
              disposePlayback();
              return true;
            },
            child: AlertDialog(
              title: const Text('Edit Card'),
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
                      onPressed: () {
                        Navigator.pop(context);
                        _addSubCard(card);
                        setState(() {
                          activeParentCard = card;
                        });
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
                    _updateCategories();
                    _saveCards();
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
  }

  void _addSubCard(AACCard parentCard) {
    setState(() {
      parentCard.type = 'folder';
      parentCard.subCards.add(
        AACCard(
          id: '${parentCard.id}-${parentCard.subCards.length + 1}',
          label: 'New Card',
          colorValue: Color(parentCard.colorValue).withOpacity(0.7).value,
        ),
      );
    });
    final newCardId = parentCard.subCards.last.id;
    _includeInVisibleSelection(parentCard.id, newCardId);
    _saveCards();
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

    return Scaffold(
      key: _scaffoldKey,
      appBar: HomeAppBar(
        title: activeParentCard == null
            ? 'AAC App'
            : activeParentCard!.getLabel(currentLanguage),
        backgroundColor: Colors.blue.shade700,
        showBack: activeParentCard != null,
        onBack: () {
          setState(() {
            _textController.clear();
            activeParentCard = null;
          });
        },
        isEditMode: isEditMode,
        onAdd: () {
          setState(() {
            if (activeParentCard != null) {
              activeParentCard!.subCards.add(
                AACCard(
                  id:
                      '${activeParentCard!.id}-${activeParentCard!.subCards.length + 1}',
                  label: 'New',
                  colorValue:
                      Color(activeParentCard!.colorValue).withOpacity(0.7).value,
                ),
              );
              _includeInVisibleSelection(
                activeParentCard!.id,
                activeParentCard!.subCards.last.id,
              );
            } else {
              cards.add(AACCard(
                id: DateTime.now().toString(),
                label: 'New',
                colorValue: Colors
                    .primaries[cards.length % Colors.primaries.length].value,
              ));
              _includeInVisibleSelection('__root__', cards.last.id);
            }
          });
          _updateCategories();
          _saveCards();
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
      endDrawer: HomeDrawer(
        selectedCategory: selectedCategory,
        currentLanguageLabel: _getLanguageName(currentLanguage),
        gridColumns: gridColumns,
        visibleCardsLabel: _getVisibleCardsLabel(),
        isEditMode: isEditMode,
        showTtsInput: showTtsInput,
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
        onShowLanguage: _showLanguageDialog,
        onShowGrid: _showGridOptions,
        onShowVisibleCount: _showVisibleCountDialog,
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
      child: Container(
        decoration: BoxDecoration(
          color: Color(card.colorValue),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
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
    _tts.stop();
    _audioPlayer.dispose();
    _recorder.dispose();
    _textController.dispose();
    super.dispose();
  }
}
