import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';
import '../utils/card_image.dart';

class VisibleCardsDialog extends StatefulWidget {
  final List<AACCard> cards;
  final String currentLanguage;
  final Set<String> initialSelectedIds;
  final ValueChanged<Set<String>> onSubmit;

  const VisibleCardsDialog({
    Key? key,
    required this.cards,
    required this.currentLanguage,
    required this.initialSelectedIds,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<VisibleCardsDialog> createState() => _VisibleCardsDialogState();
}

class _VisibleCardsDialogState extends State<VisibleCardsDialog> {
  late Set<String> selectedIds;

  @override
  void initState() {
    super.initState();
    selectedIds = widget.initialSelectedIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedIds.isNotEmpty;
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Visible Cards')),
          IconButton(
            icon: Icon(hasSelection ? Icons.clear_all : Icons.select_all),
            tooltip: hasSelection ? 'Clear All' : 'Select All',
            onPressed: () {
              setState(() {
                if (hasSelection) {
                  selectedIds.clear();
                } else {
                  selectedIds
                    ..clear()
                    ..addAll(widget.cards.map((c) => c.id));
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
          children: widget.cards.map((card) {
            final label = card.getLabel(widget.currentLanguage);
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
                      ? buildCardImage(
                          card.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image, size: 18);
                          },
                        )
                      : const Icon(Icons.image, size: 18),
                ),
              ),
              onChanged: (value) {
                setState(() {
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
            widget.onSubmit(selectedIds);
            Navigator.pop(context);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}
