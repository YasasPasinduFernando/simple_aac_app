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
  String currentLanguage = 'en';
  bool isRecording = false;
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
            labelSinhala: '????????',
            labelTamil: '???????',
            colorValue: Colors.pink.shade300.value,
          ),
          AACCard(
            id: '2',
            label: 'Food',
            labelSinhala: '????',
            labelTamil: '????',
            colorValue: Colors.orange.shade300.value,
            subCards: [
              AACCard(
                id: '2-1',
                label: 'Rice',
                labelSinhala: '???',
                labelTamil: '????',
                colorValue: Colors.orange.shade200.value,
              ),
              AACCard(
                id: '2-2',
                label: 'Bread',
                labelSinhala: '????',
                labelTamil: '??????',
                colorValue: Colors.orange.shade200.value,
              ),
            ],
          ),
          AACCard(
            id: '3',
            label: 'Water',
            labelSinhala: '????',
            labelTamil: '???????',
            colorValue: Colors.blue.shade300.value,
          ),
          AACCard(
            id: '4',
            label: 'Help',
            labelSinhala: '????',
            labelTamil: '????',
            colorValue: Colors.red.shade300.value,
          ),
        ];
      });
    }

    gridColumns = prefs.getInt('gridColumns') ?? 2;
    currentLanguage = prefs.getString('language') ?? 'en';

    _updateCategories();
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

  Future<void> _recordVoice(AACCard card) async {
    if (isRecording) {
      final path = await _recorder.stop();
      setState(() {
        isRecording = false;
        if (path != null) {
          card.voicePath = path;
        }
      });
      _saveCards();
    } else {
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
      setState(() {
        isRecording = true;
      });
    }
  }

  void _editCard(AACCard card) {
    final controllerEn = TextEditingController(text: card.label);
    final controllerSi = TextEditingController(text: card.labelSinhala ?? '');
    final controllerTa = TextEditingController(text: card.labelTamil ?? '');
    String selectedCategory = card.category;
    String selectedType = card.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                    setDialogState(() => selectedCategory = value ?? 'General');
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
                        onPressed: () {
                          Navigator.pop(context);
                          _recordVoice(card);
                        },
                        icon: Icon(isRecording ? Icons.stop : Icons.mic),
                        label: Text(isRecording ? 'Stop' : 'Voice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRecording ? Colors.red : null,
                        ),
                      ),
                    ),
                  ],
                ),
                if (card.voicePath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _playVoice(card.voicePath!),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play Recorded Voice'),
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
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
      ),
    );
  }

  void _addSubCard(AACCard parentCard) {
    if (parentCard.type == 'word') return;
    setState(() {
      parentCard.subCards.add(
        AACCard(
          id: '${parentCard.id}-${parentCard.subCards.length + 1}',
          label: 'New Card',
          colorValue: Color(parentCard.colorValue).withOpacity(0.7).value,
        ),
      );
    });
    _saveCards();
  }

  void _showSubCards(AACCard card) {
    if (card.type != 'folder') return;
    setState(() {
      activeParentCard = card;
    });
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'si':
        return '????? (Sinhala)';
      case 'ta':
        return '????? (Tamil)';
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
              title: const Text('????? (Sinhala)'),
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
              title: const Text('????? (Tamil)'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Grid Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGridOption(1, '1 Column'),
            _buildGridOption(2, '2 Columns'),
            _buildGridOption(3, '3 Columns'),
            _buildGridOption(4, '4 Columns'),
          ],
        ),
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

  List<AACCard> _getDisplayedCards() {
    if (activeParentCard != null) {
      return activeParentCard!.subCards;
    }
    return _getFilteredCards();
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
            } else {
              cards.add(AACCard(
                id: DateTime.now().toString(),
                label: 'New',
                colorValue: Colors
                    .primaries[cards.length % Colors.primaries.length].value,
              ));
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
        isEditMode: isEditMode,
        onSelectCategory: _showCategoryDialog,
        onToggleEdit: _toggleEditMode,
        onShowLanguage: _showLanguageDialog,
        onShowGrid: _showGridOptions,
        onShowAbout: _showAbout,
      ),
      body: Column(
        children: [
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
        if (card.voicePath != null && await File(card.voicePath!).exists()) {
          await _playVoice(card.voicePath!);
        } else {
          await _speak(displayLabel);
        }

        if (card.type == 'folder') {
          _showSubCards(card);
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
