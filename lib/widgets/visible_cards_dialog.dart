import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';
import '../utils/card_image.dart';
import 'preview/live_preview_panel.dart';
import 'preview/visible_cards_preview.dart';
import 'styled_dialog_header.dart';

/// Interactive Visible Cards selection dialog featuring a reactive Live Board Preview.
/// Selecting or deselecting cards updates the preview and count badge immediately before saving.
class VisibleCardsDialog extends StatefulWidget {
  final List<AACCard> cards;
  final String currentLanguage;
  final Set<String> initialSelectedIds;
  final int gridColumns;
  final ValueChanged<Set<String>> onSubmit;

  const VisibleCardsDialog({
    Key? key,
    required this.cards,
    required this.currentLanguage,
    required this.initialSelectedIds,
    this.gridColumns = 2,
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

  void _selectAll() {
    setState(() {
      selectedIds = widget.cards.map((c) => c.id).toSet();
    });
  }

  void _clearAll() {
    setState(() {
      selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context).size;

    final infoBg = isDark ? const Color(0xFF1E2838) : const Color(0xFFE8F1FC);
    final infoBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFD0E2F9);
    final infoTextColor =
        isDark ? const Color(0xFFBFDBFE) : const Color(0xFF0F3B7A);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: StyledDialogHeader(
        icon: Icons.remove_red_eye_rounded,
        title: 'Visible Cards',
        subtitle: 'Choose cards shown on your board',
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer
                .withValues(alpha: isDark ? 0.40 : 0.60),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Text(
            '${selectedIds.length} of ${widget.cards.length} visible',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color:
                  isDark ? colorScheme.onPrimaryContainer : colorScheme.primary,
            ),
          ),
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (media.width - 32).clamp(280.0, 480.0),
          maxHeight: (media.height * 0.72).clamp(320.0, 600.0),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live Board Preview Panel
              LivePreviewPanel(
                title: 'LIVE BOARD PREVIEW',
                icon: Icons.grid_view_rounded,
                minHeight: 110,
                maxHeight: 180,
                child: VisibleCardsPreview(
                  cards: widget.cards,
                  selectedIds: selectedIds,
                  language: widget.currentLanguage,
                  columns: widget.gridColumns,
                  isDarkMode: isDark,
                ),
              ),
              const SizedBox(height: 10),

              // Informational Safety Notice
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: infoBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: infoBorder, width: 0.8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF0267C1),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only the selected cards are shown on your board. Unchecking a card hides it (it\'s not deleted).',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: infoTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Quick Action Buttons: Select All & Clear All
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      onPressed: _selectAll,
                      icon: const Icon(Icons.check_box_outlined, size: 16),
                      label: const Text(
                        'Select all',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      onPressed: _clearAll,
                      icon: const Icon(Icons.disabled_by_default_rounded,
                          size: 16),
                      label: const Text(
                        'Clear all',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Scrollable list of cards with checkboxes
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (media.height * 0.32).clamp(150.0, 320.0),
                ),
                child: Material(
                  color: isDark
                      ? const Color(0xFF1E2836)
                      : colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.5)),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int index = 0;
                              index < widget.cards.length;
                              index++) ...[
                            if (index > 0)
                              Divider(
                                height: 1,
                                indent: 52,
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.35),
                              ),
                            Builder(
                              builder: (context) {
                                final card = widget.cards[index];
                                final label =
                                    card.getLabel(widget.currentLanguage);
                                final checked = selectedIds.contains(card.id);
                                final isFolder = card.type == 'folder';

                                return CheckboxListTile(
                                  value: checked,
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 2),
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
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (isFolder) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.folder_outlined,
                                          size: 15,
                                          color: isDark
                                              ? Colors.amber.shade300
                                              : const Color(0xFFB45309),
                                        ),
                                      ],
                                    ],
                                  ),
                                  secondary: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: Color(card.colorValue),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: card.imagePath != null &&
                                              card.imagePath!.isNotEmpty
                                          ? buildCardImage(
                                              card.imagePath!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  isFolder
                                                      ? Icons.folder_rounded
                                                      : Icons.image,
                                                  size: 16,
                                                );
                                              },
                                            )
                                          : Icon(
                                              isFolder
                                                  ? Icons.folder_rounded
                                                  : Icons.image,
                                              size: 16,
                                            ),
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
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
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
        TextButton(
          onPressed: () {
            setState(() {
              selectedIds.clear();
            });
          },
          child: const Text('Reset'),
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
