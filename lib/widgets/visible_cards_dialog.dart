import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';
import '../utils/card_image.dart';
import 'styled_dialog_header.dart';

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
    final media = MediaQuery.of(context).size;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: StyledDialogHeader(
        icon: Icons.visibility_rounded,
        title: 'Visible Cards',
        subtitle: '${selectedIds.length} selected',
        trailing: IconButton(
          icon: Icon(hasSelection
              ? Icons.clear_all_rounded
              : Icons.select_all_rounded),
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
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (media.width - 32).clamp(280.0, 480.0),
          maxHeight: (media.height * 0.6).clamp(200.0, 480.0),
        ),
        child: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: widget.cards.map((card) {
              final label = card.getLabel(widget.currentLanguage);
              final checked = selectedIds.contains(card.id);
              final isFolder = card.type == 'folder';
              return CheckboxListTile(
                value: checked,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFolder) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.folder_outlined, size: 16),
                    ],
                  ],
                ),
                secondary: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 36,
                    height: 36,
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
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
