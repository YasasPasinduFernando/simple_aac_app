import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';
import '../models/recycle_bin_entry.dart';
import '../services/recycle_bin_service.dart';
import '../utils/card_image.dart';

/// Screen displaying deleted cards and folders for up to 30 days.
/// Provides safe restore, permanent deletion, and empty recycle bin actions.
class RecycleBinPage extends StatefulWidget {
  final List<AACCard> activeCards;
  final String currentLanguage;
  final Color themePrimary;
  final Color themeText;
  final bool isDarkMode;
  final List<RecycleBinEntry>? initialEntriesForTesting;
  final void Function(AACCard restoredCard, String? parentId, int index)? onRestoreCard;

  const RecycleBinPage({
    Key? key,
    required this.activeCards,
    this.initialEntriesForTesting,
    this.currentLanguage = 'en',
    this.themePrimary = const Color(0xFF0D6EFD),
    this.themeText = Colors.white,
    this.isDarkMode = false,
    this.onRestoreCard,
  }) : super(key: key);

  @override
  State<RecycleBinPage> createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends State<RecycleBinPage> {
  List<RecycleBinEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEntriesForTesting != null) {
      _entries = List.from(widget.initialEntriesForTesting!);
      _isLoading = false;
    } else {
      _loadEntries();
    }
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    // Purge expired entries first (30 days threshold)
    await RecycleBinService.instance.purgeExpiredEntries(
      activeCards: widget.activeCards,
    );
    final entries = await RecycleBinService.instance.loadEntries();
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreEntry(RecycleBinEntry entry) async {
    final cardLabel = entry.card.getLabel(widget.currentLanguage);
    final parentId = entry.parentId;
    final originalIndex = entry.originalIndex;

    final AACCard? restoredCard;
    if (widget.initialEntriesForTesting != null) {
      restoredCard = entry.card;
    } else {
      restoredCard = await RecycleBinService.instance.restoreEntry(
        entryId: entry.entryId,
        activeCards: widget.activeCards,
      );
    }

    if (restoredCard != null) {
      widget.onRestoreCard?.call(restoredCard, parentId, originalIndex);
      setState(() {
        _entries.removeWhere((e) => e.entryId == entry.entryId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restored "$cardLabel"'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmDeletePermanent(RecycleBinEntry entry) {
    final cardLabel = entry.card.getLabel(widget.currentLanguage);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text(
          'Remove "$cardLabel" forever? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () async {
              Navigator.pop(ctx);
              if (widget.initialEntriesForTesting == null) {
                await RecycleBinService.instance.removeEntry(
                  entry.entryId,
                  activeCards: widget.activeCards,
                );
              }
              setState(() {
                _entries.removeWhere((e) => e.entryId == entry.entryId);
              });
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Permanently deleted "$cardLabel"'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyRecycleBin() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Recycle Bin?'),
        content: const Text(
          'All deleted cards and folders will be permanently removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () async {
              Navigator.pop(ctx);
              if (widget.initialEntriesForTesting == null) {
                await RecycleBinService.instance.emptyRecycleBin(
                  activeCards: widget.activeCards,
                );
              }
              setState(() {
                _entries.clear();
              });
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recycle Bin emptied'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Empty'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDarkMode || theme.brightness == Brightness.dark;
    final primaryColor = widget.themePrimary;
    final lighterPrimary = Color.lerp(primaryColor, Colors.white, 0.08)!;
    final darkerPrimary = Color.lerp(primaryColor, Colors.black, 0.12)!;

    final bgColor = isDark ? const Color(0xFF0F141C) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Curved App Header
            _buildHeader(lighterPrimary, darkerPrimary),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        const SizedBox(height: 12),
                        // 30-Day Info Callout
                        _buildInfoPanel(isDark),

                        // Section Header: RECENTLY DELETED [3 items]
                        _buildSectionHeader(isDark),

                        // List of items or Empty state
                        if (_entries.isEmpty)
                          _buildEmptyState(isDark)
                        else ...[
                          for (final entry in _entries)
                            _buildEntryCard(entry, isDark),
                          const SizedBox(height: 16),
                          _buildBottomActions(isDark),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color lighter, Color darker) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lighter, darker],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _RecycleBinWavePainter(waveColor: Colors.white),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: topPadding + 10,
              bottom: 16,
              left: 14,
              right: 14,
            ),
            child: Row(
              children: [
                // Back Button
                Semantics(
                  button: true,
                  label: 'Back',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const ValueKey('recycle_bin_back_btn'),
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Recycle Bin Icon
                const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 10),
                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Recycle Bin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Simple AAC Sri Lanka',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2433) : const Color(0xFFEBF3FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A384F) : const Color(0xFFD0E2F9),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 28,
            color: Color(0xFF0D6EFD),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 34,
            color: isDark ? const Color(0xFF2A384F) : const Color(0xFFD0E2F9),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deleted cards stay here for 30 days.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0B3B70),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Restore them anytime before automatic removal.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF4A6B8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Text(
            'RECENTLY DELETED',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDCEBFA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_entries.length} ${_entries.length == 1 ? 'item' : 'items'}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1D4ED8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(RecycleBinEntry entry, bool isDark) {
    final card = entry.card;
    final isFolder = card.subCards.isNotEmpty || card.type == 'folder';

    return Container(
      key: ValueKey('recycle_entry_${entry.entryId}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B26) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3447) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Card Thumbnail
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Color(card.colorValue),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: card.imagePath != null && card.imagePath!.isNotEmpty
                  ? buildCardImage(
                      card.imagePath!,
                      fit: BoxFit.contain,
                      targetLogicalWidth: 52,
                    )
                  : Center(
                      child: Icon(
                        isFolder ? Icons.folder_rounded : Icons.image_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.getLabel(widget.currentLanguage),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (isFolder) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFFE0EDFB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${card.subCards.length} sub-cards',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  entry.getDeletionStatusText(RecycleBinService.now),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Actions Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'delete_permanent',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever_rounded,
                            color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete permanently',
                            style: TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'delete_permanent') {
                    _confirmDeletePermanent(entry);
                  }
                },
              ),
              const SizedBox(height: 2),
              OutlinedButton.icon(
                key: ValueKey('restore_btn_${entry.entryId}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D6EFD),
                  side: const BorderSide(color: Color(0xFF0D6EFD), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.replay_rounded, size: 15),
                label: const Text(
                  'Restore',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _restoreEntry(entry),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            key: const ValueKey('empty_recycle_bin_btn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text(
              'Empty Recycle Bin',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            onPressed: _confirmEmptyRecycleBin,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              'Deleted media is removed only when no card needs it.',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 38,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Recycle Bin is empty',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Deleted cards will appear here for up to 30 days.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecycleBinWavePainter extends CustomPainter {
  final Color waveColor;

  const _RecycleBinWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final path1 = Path()
      ..moveTo(0, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.12,
        size.width * 0.55,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.82,
        size.width,
        size.height * 0.45,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final paint1 = Paint()
      ..color = waveColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path1, paint1);

    final path2 = Path()
      ..moveTo(0, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.25,
        size.width * 0.42,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.82,
        size.width * 0.85,
        0,
      )
      ..lineTo(0, 0)
      ..close();

    final paint2 = Paint()
      ..color = waveColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _RecycleBinWavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor;
}
