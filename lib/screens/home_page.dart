import 'package:flutter/material.dart';
import '../models/aac_card.dart';
import '../services/tts_service.dart';
import '../services/storage_service.dart';
import '../widgets/aac_card_widget.dart';
import '../widgets/card_editor_dialog.dart';
import 'sub_card_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TTSService _ttsService = TTSService();
  final TextEditingController _textController = TextEditingController();

  List<AACCard> cards = [];
  int gridColumns = 2;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _ttsService.initialize();
    await _loadData();
  }

  Future<void> _loadData() async {
    final loadedCards = await StorageService.loadCards();
    final loadedColumns = await StorageService.loadGridColumns();

    setState(() {
      cards = loadedCards.isEmpty ? _createDefaultCards() : loadedCards;
      gridColumns = loadedColumns;
    });
  }

  List<AACCard> _createDefaultCards() {
    return [
      AACCard(
        id: '1',
        label: 'Hello',
        colorValue: Colors.pink.shade300.value,
      ),
      AACCard(
        id: '2',
        label: 'Food',
        colorValue: Colors.orange.shade300.value,
        subCards: [
          AACCard(
            id: '2-1',
            label: 'Rice',
            colorValue: Colors.orange.shade200.value,
          ),
          AACCard(
            id: '2-2',
            label: 'Bread',
            colorValue: Colors.orange.shade200.value,
          ),
        ],
      ),
      AACCard(
        id: '3',
        label: 'Water',
        colorValue: Colors.blue.shade300.value,
      ),
      AACCard(
        id: '4',
        label: 'Help',
        colorValue: Colors.red.shade300.value,
      ),
    ];
  }

  Future<void> _saveData() async {
    await StorageService.saveCards(cards);
    await StorageService.saveGridColumns(gridColumns);
  }

  Future<void> _speak(String text) async {
    await _ttsService.speak(text);
  }

  void _showCardEditor(AACCard card) {
    showDialog(
      context: context,
      builder: (context) => CardEditorDialog(
        card: card,
        onSave: (updatedCard) {
          setState(() {});
          _saveData();
        },
        onAddSubCard: () => _addSubCard(card),
      ),
    );
  }

  void _addSubCard(AACCard parentCard) {
    setState(() {
      parentCard.subCards.add(
        AACCard(
          id: '${parentCard.id}-${parentCard.subCards.length + 1}',
          label: 'New Card',
          colorValue: Color(parentCard.colorValue).withOpacity(0.7).value,
        ),
      );
    });
    _saveData();
  }

  void _showGridOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Grid Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGridOption(1, '1 Card (Full Width)'),
            _buildGridOption(2, '2 Cards (2 Columns)'),
            _buildGridOption(3, '3 Cards (3 Columns)'),
            _buildGridOption(4, '4 Cards (2x2 Grid)'),
          ],
        ),
      ),
    );
  }

  Widget _buildGridOption(int columns, String label) {
    return ListTile(
      title: Text(label),
      leading: Radio<int>(
        value: columns,
        groupValue: gridColumns,
        onChanged: (value) {
          setState(() {
            gridColumns = value!;
          });
          _saveData();
          Navigator.pop(context);
        },
      ),
      onTap: () {
        setState(() {
          gridColumns = columns;
        });
        _saveData();
        Navigator.pop(context);
      },
    );
  }

  void _showSubCards(AACCard card) {
    if (card.subCards.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubCardPage(
          parentCard: card,
          onSpeak: _speak,
          onEdit: _showCardEditor,
        ),
      ),
    );
  }

  void _addNewCard() {
    setState(() {
      cards.add(
        AACCard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          label: 'New Card',
          colorValue:
              Colors.primaries[cards.length % Colors.primaries.length].value,
        ),
      );
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AAC App'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_3x3),
            onPressed: _showGridOptions,
            tooltip: 'Change Grid Size',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewCard,
            tooltip: 'Add New Card',
          ),
        ],
      ),
      body: Column(
        children: [
          // Text-to-Speech Input
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type to speak...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      _speak(_textController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: const CircleBorder(),
                    backgroundColor: Colors.blue.shade700,
                  ),
                  child: const Icon(
                    Icons.volume_up,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Grid of Cards
          Expanded(
            child: cards.isEmpty
                ? const Center(
                    child: Text(
                      'No cards yet. Tap + to add a card!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridColumns == 4 ? 2 : gridColumns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return AACCardWidget(
                          card: card,
                          onTap: () {
                            _speak(card.label);
                            if (card.subCards.isNotEmpty) {
                              _showSubCards(card);
                            }
                          },
                          onLongPress: () => _showCardEditor(card),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    _textController.dispose();
    super.dispose();
  }
}
