import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';
import '../models/category_metadata.dart';
import '../utils/card_image.dart';
import 'styled_dialog_header.dart';

/// Dedicated Manage Sub-Cards Dialog for Simple AAC Sri Lanka.
///
/// Features:
/// - Styled header showing folder name and sub-cards count.
/// - Live horizontal preview carousel of sub-card thumbnails.
/// - Responsive scrollable list of sub-cards with thumbnails and metadata.
/// - Edit existing sub-card.
/// - Move individual sub-card to the root Home board.
/// - Delete individual sub-card with confirmation.
/// - Move all sub-cards to Home in a single batch operation.
/// - Add new sub-card directly to this folder.
/// - Full trilingual label and dark/light mode support.
class ManageSubCardsDialog extends StatefulWidget {
  final AACCard folderCard;
  final List<AACCard> rootCards;
  final String currentLanguage;
  final Map<String, CategoryMetadata> customMetadata;
  final VoidCallback onCardsChanged;
  final Future<void> Function(AACCard subCard)? onEditSubCard;
  final Future<void> Function()? onAddSubCard;
  final void Function(String message)? onRecordUndo;

  const ManageSubCardsDialog({
    Key? key,
    required this.folderCard,
    required this.rootCards,
    required this.currentLanguage,
    required this.customMetadata,
    required this.onCardsChanged,
    this.onEditSubCard,
    this.onAddSubCard,
    this.onRecordUndo,
  }) : super(key: key);

  @override
  State<ManageSubCardsDialog> createState() => _ManageSubCardsDialogState();
}

class _ManageSubCardsDialogState extends State<ManageSubCardsDialog> {
  CategoryMetadata _resolveMeta(String categoryName) {
    return CategoryMetadata.resolve(
      categoryName,
      customMetadata: widget.customMetadata,
      fallbackColorValue: 0xFF0277BD,
    );
  }

  int _countTotalDescendants(AACCard card) {
    int count = 0;
    for (final child in card.subCards) {
      count += 1 + _countTotalDescendants(child);
    }
    return count;
  }

  void _moveCardToHome(AACCard card) {
    widget.folderCard.subCards.removeWhere((c) => c.id == card.id);
    if (!widget.rootCards.any((c) => c.id == card.id)) {
      widget.rootCards.add(card);
    }
    final cardName = card.getLabel(widget.currentLanguage);
    widget.onRecordUndo?.call('Move $cardName to Home');
    widget.onCardsChanged();
    setState(() {});

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moved "$cardName" to Home board'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDeleteCard(AACCard card) async {
    final cardName = card.getLabel(widget.currentLanguage);
    final totalDescendants = _countTotalDescendants(card);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const StyledDialogHeader(
          icon: Icons.delete_forever_rounded,
          title: 'Delete Sub-Card?',
          accentColor: Colors.red,
        ),
        content: Text(
          totalDescendants > 0
              ? 'Are you sure you want to delete "$cardName"?\n\n'
                  'This card contains $totalDescendants nested sub-card(s) '
                  'that will also be permanently deleted.'
              : 'Are you sure you want to delete "$cardName"?\n\n'
                  'This action cannot be undone except via Undo.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.folderCard.subCards.removeWhere((c) => c.id == card.id);
      widget.onRecordUndo?.call('Delete $cardName');
      widget.onCardsChanged();
      setState(() {});

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "$cardName"'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmMoveAllToHome() async {
    final count = widget.folderCard.subCards.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const StyledDialogHeader(
          icon: Icons.unarchive_rounded,
          title: 'Move All to Home?',
          accentColor: Color(0xFF0284C7),
        ),
        content: Text(
          'Move all $count sub-card(s) to the root Home board?\n\n'
          'All sub-cards and their nested cards will become accessible from the main board.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Move All ($count)'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final moved = List<AACCard>.from(widget.folderCard.subCards);
      for (final card in moved) {
        if (!widget.rootCards.any((c) => c.id == card.id)) {
          widget.rootCards.add(card);
        }
      }
      widget.folderCard.subCards.clear();
      final folderName = widget.folderCard.getLabel(widget.currentLanguage);
      widget.onRecordUndo?.call('Move all sub-cards of $folderName to Home');
      widget.onCardsChanged();
      setState(() {});

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved all $count sub-card(s) to Home board'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context).size;
    final isLandscape = media.width > media.height;
    final maxWidth = (isLandscape ? media.width * 0.72 : media.width - 32)
        .clamp(280.0, 520.0);
    final maxHeight = (media.height * (isLandscape ? 0.85 : 0.78))
        .clamp(320.0, 720.0);

    final subCards = widget.folderCard.subCards;
    final folderName = widget.folderCard.getLabel(widget.currentLanguage);
    final folderColor = Color(widget.folderCard.colorValue);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: StyledDialogHeader(
                icon: Icons.folder_copy_rounded,
                accentColor: folderColor,
                title: 'Manage Sub-Cards',
                subtitle: 'Inside "$folderName"',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: folderColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${subCards.length} ${subCards.length == 1 ? "Card" : "Cards"}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: folderColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Live Preview Section
                    _buildPreviewSection(context, isDark, subCards),
                    const SizedBox(height: 16),

                    // Section Title
                    Row(
                      children: [
                        Icon(
                          Icons.view_list_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Cards in this folder (${subCards.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Cards List
                    if (subCards.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 28, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 44,
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'This folder is currently empty',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add sub-cards using the "+ Add Sub-Card" button below.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: subCards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final card = subCards[index];
                          return _buildCardRow(context, card, isDark);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final moveAllBtn = OutlinedButton.icon(
                    icon: const Icon(Icons.unarchive_outlined, size: 18),
                    label: const Text(
                      'Move All to Home',
                      style: TextStyle(fontSize: 13),
                    ),
                    onPressed:
                        subCards.isEmpty ? null : _confirmMoveAllToHome,
                  );

                  final addCardBtn = FilledButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      '+ Add Sub-Card',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () async {
                      if (widget.onAddSubCard != null) {
                        await widget.onAddSubCard!();
                        if (mounted) setState(() {});
                      }
                    },
                  );

                  final doneBtn = TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  );

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      moveAllBtn,
                      addCardBtn,
                      doneBtn,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(
      BuildContext context, bool isDark, List<AACCard> subCards) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SUB-CARDS PREVIEW',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subCards.isEmpty
                      ? 'No cards to preview'
                      : '${subCards.length} cards inside folder',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.grey.shade300
                        : const Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal scroll row of thumbnails
          if (subCards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Cards added to this folder will appear here.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (int i = 0; i < subCards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    _buildPreviewCardThumbnail(context, subCards[i], isDark),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewCardThumbnail(
      BuildContext context, AACCard card, bool isDark) {
    final label = card.getLabel(widget.currentLanguage);
    final cardColor = Color(card.colorValue);

    return Container(
      width: 74,
      height: 84,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: card.imagePath != null && card.imagePath!.isNotEmpty
                  ? buildCardImage(
                      card.imagePath!,
                      fit: BoxFit.contain,
                    )
                  : Container(
                      color: cardColor,
                      child: Center(
                        child: Icon(
                          card.type == 'folder'
                              ? Icons.folder_rounded
                              : Icons.image,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardRow(BuildContext context, AACCard card, bool isDark) {
    final label = card.getLabel(widget.currentLanguage);
    final cardColor = Color(card.colorValue);
    final nestedCount = _countTotalDescendants(card);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Card thumbnail
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: card.imagePath != null && card.imagePath!.isNotEmpty
                  ? buildCardImage(
                      card.imagePath!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: cardColor,
                      child: Center(
                        child: Icon(
                          card.type == 'folder'
                              ? Icons.folder_rounded
                              : Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Label and metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (card.type == 'folder') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Folder',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      _resolveMeta(card.category).icon,
                      size: 12,
                      color: _resolveMeta(card.category).color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      card.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (nestedCount > 0) ...[
                      Text(
                        ' • $nestedCount nested',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 19),
                tooltip: 'Edit Card',
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  if (widget.onEditSubCard != null) {
                    await widget.onEditSubCard!(card);
                    if (mounted) setState(() {});
                  }
                },
              ),
              // Move to Home button
              IconButton(
                icon: const Icon(Icons.drive_file_move_outlined, size: 19),
                tooltip: 'Move to Home Board',
                visualDensity: VisualDensity.compact,
                color: const Color(0xFF0284C7),
                onPressed: () => _moveCardToHome(card),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
                tooltip: 'Delete Sub-Card',
                visualDensity: VisualDensity.compact,
                color: Colors.red.shade400,
                onPressed: () => _confirmDeleteCard(card),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
