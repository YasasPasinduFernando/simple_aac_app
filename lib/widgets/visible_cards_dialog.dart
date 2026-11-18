import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';
import '../utils/card_image.dart';
import 'preview/live_preview_panel.dart';
import 'preview/visible_cards_preview.dart';
import 'styled_dialog_header.dart';

/// Navigation frame model representing a single folder level in the Visible Cards dialog.
class _FolderLevel {
  final String id;
  final String title;
  final List<AACCard> cards;
  final AACCard? folderCard;

  const _FolderLevel({
    required this.id,
    required this.title,
    required this.cards,
    this.folderCard,
  });
}

/// Interactive Visible Cards selection dialog supporting nested sub-card visibility management
/// and a reactive Live Board Preview.
///
/// Selecting or deselecting cards updates the preview and count badge immediately before saving.
/// Tapping the manage arrow button '>' on any folder card navigates into its sub-cards view.
/// Parent folder visibility and child card visibility are strictly decoupled and managed independently.
class VisibleCardsDialog extends StatefulWidget {
  final List<AACCard> cards;
  final String categoryName;
  final String currentLanguage;
  final Set<String> initialSelectedIds;
  final int gridColumns;
  final ValueChanged<Set<String>> onSubmit;

  // Optional extensions for full nested folder visibility management
  final List<AACCard>? allCards;
  final List<AACCard>? initialParentStack;
  final Map<String, Set<String>>? visibleCardIdsByParent;
  final ValueChanged<Map<String, Set<String>>>? onSaveMap;

  const VisibleCardsDialog({
    Key? key,
    required this.cards,
    this.categoryName = 'All',
    required this.currentLanguage,
    required this.initialSelectedIds,
    this.gridColumns = 2,
    required this.onSubmit,
    this.allCards,
    this.initialParentStack,
    this.visibleCardIdsByParent,
    this.onSaveMap,
  }) : super(key: key);

  @override
  State<VisibleCardsDialog> createState() => _VisibleCardsDialogState();
}

class _VisibleCardsDialogState extends State<VisibleCardsDialog> {
  late final List<_FolderLevel> _folderStack;
  late final Map<String, Set<String>> _draftVisibleMap;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // 1. Initialize draft visibility map
    _draftVisibleMap = {};
    if (widget.visibleCardIdsByParent != null) {
      for (final entry in widget.visibleCardIdsByParent!.entries) {
        _draftVisibleMap[entry.key] = Set<String>.from(entry.value);
      }
    }

    // 2. Setup root level
    final rootCards = widget.allCards ?? widget.cards;
    final rootLevel = _FolderLevel(
      id: '__root__',
      title: 'Home',
      cards: rootCards,
    );

    // 3. Build navigation stack
    _folderStack = [rootLevel];
    if (widget.initialParentStack != null &&
        widget.initialParentStack!.isNotEmpty) {
      for (final parent in widget.initialParentStack!) {
        _folderStack.add(_FolderLevel(
          id: parent.id,
          title: parent.getLabel(widget.currentLanguage),
          cards: parent.subCards,
          folderCard: parent,
        ));
      }
    }

    // 4. Seed root selection with initialSelectedIds if not already populated
    if (!_draftVisibleMap.containsKey('__root__')) {
      _draftVisibleMap['__root__'] = widget.initialSelectedIds.toSet();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  _FolderLevel get _currentLevel => _folderStack.last;

  Set<String> _getSelectedIdsForLevel(_FolderLevel level) {
    return _draftVisibleMap.putIfAbsent(
      level.id,
      () => level.cards.map((c) => c.id).toSet(),
    );
  }

  void _navigateToFolder(AACCard folder) {
    final folderLevel = _FolderLevel(
      id: folder.id,
      title: folder.getLabel(widget.currentLanguage),
      cards: folder.subCards,
      folderCard: folder,
    );
    // If this folder has no draft entry yet, default to all of its children visible
    if (!_draftVisibleMap.containsKey(folder.id)) {
      _draftVisibleMap[folder.id] = folder.subCards.map((c) => c.id).toSet();
    }
    setState(() {
      _folderStack.add(folderLevel);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _navigateBack() {
    if (_folderStack.length > 1) {
      setState(() {
        _folderStack.removeLast();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  void _navigateToStackIndex(int index) {
    if (index >= 0 && index < _folderStack.length - 1) {
      setState(() {
        _folderStack.removeRange(index + 1, _folderStack.length);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  void _selectAll() {
    final level = _currentLevel;
    setState(() {
      _draftVisibleMap[level.id] = level.cards.map((c) => c.id).toSet();
    });
  }

  void _clearAll() {
    final level = _currentLevel;
    setState(() {
      _draftVisibleMap[level.id] = <String>{};
    });
  }

  void _toggleCard(String cardId, bool? value) {
    final level = _currentLevel;
    final selected = _getSelectedIdsForLevel(level);
    setState(() {
      if (value == true) {
        selected.add(cardId);
      } else {
        selected.remove(cardId);
      }
    });
  }

  void _handleReset() {
    final level = _currentLevel;
    setState(() {
      _draftVisibleMap[level.id]?.clear();
    });
  }

  void _handleDone() {
    final rootSelection = _draftVisibleMap['__root__'] ??
        _folderStack.first.cards.map((c) => c.id).toSet();
    widget.onSubmit(rootSelection);
    widget.onSaveMap?.call(_draftVisibleMap);
    Navigator.pop(context);
  }

  Widget _buildBreadcrumbBar(ThemeData theme, bool isDark) {
    if (_folderStack.length <= 1) {
      return const SizedBox.shrink();
    }
    final bg = isDark ? const Color(0xFF1E2838) : const Color(0xFFE8F1FC);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFD0E2F9);

    return Container(
      key: const ValueKey('manage_subcards_breadcrumb_bar'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 0.8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _folderStack.length; i++) ...[
              if (i > 0) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
              if (i == _folderStack.length - 1)
                Text(
                  _folderStack[i].title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF0F3B7A),
                  ),
                )
              else
                InkWell(
                  key: ValueKey('manage_breadcrumb_item_$i'),
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => _navigateToStackIndex(i),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    child: Text(
                      _folderStack[i].title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF0267C1),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context).size;
    final isLandscape = media.width > media.height;

    final infoBg = isDark ? const Color(0xFF1E2838) : const Color(0xFFE8F1FC);
    final infoBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFD0E2F9);
    final infoTextColor =
        isDark ? const Color(0xFFBFDBFE) : const Color(0xFF0F3B7A);

    final dialogWidth = (isLandscape ? media.width * 0.75 : media.width - 32)
        .clamp(280.0, 540.0);
    // Leave safe headroom for dialog insets (32), title (~64), and actions (~56)
    final maxAvailableContentHeight =
        media.height - (isLandscape ? 140.0 : 190.0);
    final dialogHeight = maxAvailableContentHeight.clamp(200.0, 640.0);

    final isRoot = _folderStack.length <= 1;
    final currentLevel = _currentLevel;
    final currentCards = currentLevel.cards;
    final currentSelectedIds = _getSelectedIdsForLevel(currentLevel);
    final visibleCount = currentCards
        .where((c) => currentSelectedIds.contains(c.id))
        .length;

    return PopScope(
      canPop: isRoot,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _folderStack.length > 1) {
          _navigateBack();
        }
      },
      child: AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isLandscape ? 10 : 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: StyledDialogHeader(
          icon: Icons.remove_red_eye_rounded,
          title: isRoot ? 'Visible Cards' : 'Manage Sub-cards',
          subtitle: isRoot
              ? 'Choose cards shown on your board'
              : 'Show or hide individual cards',
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
              currentCards.isEmpty
                  ? '0 cards'
                  : '$visibleCount of ${currentCards.length} visible',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.primary,
              ),
            ),
          ),
        ),
        content: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Breadcrumb path navigation bar (visible inside folders)
              _buildBreadcrumbBar(theme, isDark),

              // Live Board Preview Panel
              LivePreviewPanel(
                title: 'LIVE BOARD PREVIEW',
                icon: Icons.grid_view_rounded,
                minHeight: isLandscape ? 50 : 100,
                maxHeight: isLandscape ? 65 : 150,
                padding: const EdgeInsets.all(8.0),
                child: VisibleCardsPreview(
                  cards: currentCards,
                  selectedIds: currentSelectedIds,
                  language: widget.currentLanguage,
                  columns: widget.gridColumns,
                  isDarkMode: isDark,
                ),
              ),
              const SizedBox(height: 6),

              if (currentCards.isEmpty)
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2836)
                            : colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: isDark
                                ? colorScheme.surfaceContainerHighest
                                : colorScheme.primaryContainer
                                    .withValues(alpha: 0.45),
                            child: Icon(
                              Icons.style_outlined,
                              size: 28,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isRoot
                                ? (widget.categoryName == 'All'
                                    ? 'No cards found'
                                    : 'No cards found in "${widget.categoryName}" category')
                                : 'No sub-cards found in "${currentLevel.title}"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isRoot
                                ? 'Please create some cards in Edit Mode first to choose which ones to show on your board.'
                                : 'Tap + in Edit Words Mode to add cards or sub-cards into this folder.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                // Informational Safety Notice (compact or hidden in landscape)
                if (!isLandscape) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: infoBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: infoBorder, width: 0.8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF0267C1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Only the selected cards are shown on your board. Unchecking a card hides it (it\'s not deleted).',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: infoTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Quick Action Buttons: Select All & Clear All
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        onPressed: _selectAll,
                        icon: const Icon(Icons.check_box_outlined, size: 15),
                        label: const Text(
                          'Select all',
                          style: TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        onPressed: _clearAll,
                        icon: const Icon(Icons.disabled_by_default_rounded,
                            size: 15),
                        label: const Text(
                          'Clear all',
                          style: TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Scrollable list of cards with checkboxes
                Expanded(
                  child: Material(
                    color: isDark
                        ? const Color(0xFF1E2836)
                        : colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: ListView.separated(
                        key: const PageStorageKey<String>(
                            'visible_cards_list_storage_key'),
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        itemCount: currentCards.length,
                        cacheExtent: 600,
                        padding: const EdgeInsets.only(top: 2, bottom: 8),
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          indent: 52,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.35),
                        ),
                        itemBuilder: (context, index) {
                          final card = currentCards[index];
                          final label = card.getLabel(widget.currentLanguage);
                          final checked = currentSelectedIds.contains(card.id);
                          final isFolder =
                              card.type == 'folder' || card.subCards.isNotEmpty;
                          final subCount = card.subCards.length;
                          final isSubFolderOnly = subCount > 0 &&
                              card.subCards.every((c) => c.type == 'folder');
                          final subLabel = isSubFolderOnly
                              ? (subCount == 1
                                  ? '1 sub-folder'
                                  : '$subCount sub-folders')
                              : (subCount == 1
                                  ? '1 sub-card'
                                  : '$subCount sub-cards');

                          return CheckboxListTile(
                            key:
                                ValueKey<String>('visible_card_tile_${card.id}'),
                            value: checked,
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            secondary: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Color(card.colorValue),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.08),
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
                            title: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
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
                                            const SizedBox(width: 5),
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
                                      if (isFolder) ...[
                                        const SizedBox(height: 1),
                                        Text(
                                          subLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isFolder) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _navigateToFolder(card),
                                    child: Container(
                                      key: ValueKey<String>(
                                          'manage_subcards_${card.id}'),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? colorScheme.primaryContainer
                                                .withValues(alpha: 0.40)
                                            : const Color(0xFFE0EDFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.25),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: isDark
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            onChanged: (value) => _toggleCard(card.id, value),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (isRoot) ...[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (currentCards.isNotEmpty)
              TextButton(
                onPressed: _handleReset,
                child: const Text('Reset'),
              ),
            FilledButton(
              onPressed: _handleDone,
              child: const Text('Done'),
            ),
          ] else ...[
            OutlinedButton.icon(
              key: const ValueKey('manage_subcards_back_button'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _navigateBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back'),
            ),
            FilledButton(
              onPressed: _handleDone,
              child: const Text('Done'),
            ),
          ],
        ],
      ),
    );
  }
}
