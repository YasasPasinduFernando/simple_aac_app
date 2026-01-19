import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/aac_card.dart';

class CardEditorDialog extends StatefulWidget {
  final AACCard card;
  final Function(AACCard) onSave;
  final Function() onAddSubCard;

  const CardEditorDialog({
    Key? key,
    required this.card,
    required this.onSave,
    required this.onAddSubCard,
  }) : super(key: key);

  @override
  State<CardEditorDialog> createState() => _CardEditorDialogState();
}

class _CardEditorDialogState extends State<CardEditorDialog> {
  late TextEditingController _labelController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.card.label);
  }

  Future<void> _pickImageSource() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image != null) {
      setState(() {
        widget.card.imagePath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Card'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Card Label',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                widget.card.label = value;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImageSource,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add/Change Photo'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onAddSubCard();
              },
              icon: const Icon(Icons.add_box),
              label: const Text('Add Sub-Card'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
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
        ElevatedButton(
          onPressed: () {
            widget.onSave(widget.card);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }
}
