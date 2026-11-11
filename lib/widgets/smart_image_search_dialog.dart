import 'package:flutter/material.dart';

import '../models/image_search_result.dart';
import '../services/network_policy_service.dart';
import '../services/openverse_search_provider.dart';

class SmartImageSearchDialog extends StatefulWidget {
  final String initialQuery;
  final String cardId;

  const SmartImageSearchDialog({
    Key? key,
    required this.initialQuery,
    required this.cardId,
  }) : super(key: key);

  @override
  State<SmartImageSearchDialog> createState() => _SmartImageSearchDialogState();
}

class _SmartImageSearchDialogState extends State<SmartImageSearchDialog> {
  late final TextEditingController _searchController;
  final OpenverseSearchProvider _searchProvider = OpenverseSearchProvider();

  bool _isLoading = false;
  bool _isDownloading = false;
  String? _errorMessage;
  List<ImageSearchResult> _results = [];
  ImageSearchResult? _selectedImage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    if (NetworkPolicyService.instance.isOnlineEnabled && widget.initialQuery.trim().isNotEmpty) {
      _executeSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _executeSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    if (!NetworkPolicyService.instance.isOnlineEnabled) {
      setState(() {
        _errorMessage = 'Online features are currently disabled. Enable Online Features in the drawer to search.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _results = [];
      _selectedImage = null;
    });

    try {
      final items = await _searchProvider.searchImages(cleanQuery);
      if (!mounted) return;
      setState(() {
        _results = items;
        _isLoading = false;
        if (items.isEmpty) {
          _errorMessage =
              'No child-safe CC0/public-domain images found for "$cleanQuery". Try another keyword.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _confirmAndDownloadImage(ImageSearchResult result) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final localPath = await _searchProvider.downloadAndPersistImage(
        result.imageUrl,
        cardId: widget.cardId,
      );
      if (mounted) {
        Navigator.pop(context, localPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;
    final isOnline = NetworkPolicyService.instance.isOnlineEnabled;
    final dialogWidth = (media.width - 32).clamp(280.0, 580.0);
    final availableHeight = (media.height - viewInsetsBottom).clamp(180.0, media.height);
    final dialogHeight = (availableHeight * 0.86).clamp(180.0, 680.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Smart Image Search',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Free child-safe images & photos',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 18),

              if (!isOnline) ...[
                _buildOfflineWarning(context),
              ] else ...[
                // Search Input Box
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search (e.g., cat, ball, water)...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Clear',
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                        ),
                        onSubmitted: _executeSearch,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(76, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _executeSearch(_searchController.text),
                      child: const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Content Area
                Expanded(
                  child: _isDownloading
                      ? _buildDownloadingState()
                      : _isLoading
                          ? _buildLoadingState()
                          : _errorMessage != null
                              ? _buildErrorState()
                              : _selectedImage != null
                                  ? _buildConfirmationView(_selectedImage!)
                                  : _buildResultsGrid(dialogWidth),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredStatus(List<Widget> children) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _buildOfflineWarning(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: _buildCenteredStatus([
        Icon(Icons.wifi_off_rounded, size: 52, color: colorScheme.outline),
        const SizedBox(height: 12),
        const Text(
          'Offline Mode Is Active',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Simple AAC is in 100% strict offline mode. Web image searches and network calls are blocked.\n\nTo use Smart Image Search, enable Online Features in the drawer menu.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          icon: const Icon(Icons.check_rounded),
          label: const Text('Close'),
          onPressed: () => Navigator.pop(context),
        ),
      ]),
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildCenteredStatus([
      const CircularProgressIndicator(),
      const SizedBox(height: 16),
      Text(
        'Searching safe public-domain images...',
        textAlign: TextAlign.center,
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
      ),
    ]);
  }

  Widget _buildDownloadingState() {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildCenteredStatus([
      const CircularProgressIndicator(color: Colors.green),
      const SizedBox(height: 16),
      const Text(
        'Downloading and saving locally to your device...',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      const SizedBox(height: 4),
      Text(
        'This image will work 100% offline forever.',
        textAlign: TextAlign.center,
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
      ),
    ]);
  }

  Widget _buildErrorState() {
    return _buildCenteredStatus([
      Icon(Icons.search_off_rounded, size: 48, color: Colors.amber.shade700),
      const SizedBox(height: 12),
      Text(
        _errorMessage ?? 'Search error',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 16),
      FilledButton.tonalIcon(
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Retry Search'),
        onPressed: () => _executeSearch(_searchController.text),
      ),
    ]);
  }

  Widget _buildResultsGrid(double dialogWidth) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'Type a word and tap Search to find images.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    if (!NetworkPolicyService.instance.isOnlineEnabled) {
      return const SizedBox.shrink();
    }

    final columns = dialogWidth > 460 ? 4 : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Tap an image to preview and confirm:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final item = _results[index];
              final isFreeDomain = item.isPublicDomainOrCc0;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    _selectedImage = item;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item.thumbnail,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          size: 28,
                          color: Colors.grey,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.65),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isFreeDomain
                                      ? Colors.greenAccent
                                      : Colors.amberAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  item.license.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationView(ImageSearchResult item) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFreeDomain = item.isPublicDomainOrCc0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back to results',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caregiver Confirmation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      'Preview before saving offline',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: NetworkPolicyService.instance.isOnlineEnabled
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (_, __, ___) => Image.network(
                      item.thumbnail,
                      fit: BoxFit.contain,
                    ),
                  )
                : Center(
                    child: Icon(Icons.wifi_off_rounded, size: 40, color: colorScheme.outline),
                  ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isFreeDomain
                            ? Colors.green.withValues(alpha: 0.14)
                            : Colors.amber.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isFreeDomain
                              ? Colors.green.withValues(alpha: 0.5)
                              : Colors.amber.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        item.license.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isFreeDomain
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.green.shade300
                                  : Colors.green.shade800)
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'By ${item.creator}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Pick Another',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  icon: const Icon(Icons.download_done_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Save Offline',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _confirmAndDownloadImage(item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
