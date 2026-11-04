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
      setState(() {
        _results = items;
        _isLoading = false;
        if (items.isEmpty) {
          _errorMessage = 'No child-safe CC0/public-domain images found for "$cleanQuery". Try another keyword.';
        }
      });
    } catch (e) {
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
    final isOnline = NetworkPolicyService.instance.isOnlineEnabled;
    final dialogWidth = (MediaQuery.of(context).size.width * 0.9).clamp(320.0, 600.0);
    final dialogHeight = (MediaQuery.of(context).size.height * 0.8).clamp(400.0, 700.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF0288D1), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart Image Search',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Free CC0/Public Domain via Openverse',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            if (!isOnline) ...[
              _buildOfflineWarning(context),
            ] else ...[
              // Search Input Box
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search image (e.g., cat, ball, water)...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onSubmitted: _executeSearch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : () => _executeSearch(_searchController.text),
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
                                : _buildResultsGrid(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineWarning(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Offline Mode Is Active',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Simple AAC is in 100% strict offline mode. Web image searches and network calls are blocked.\n\nTo use Smart Image Search, enable Online Features in the drawer menu.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Searching safe public-domain images...',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Downloading and saving locally to your device...',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'This image will work 100% offline forever.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.amber.shade700),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Search error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry Search'),
              onPressed: () => _executeSearch(_searchController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsGrid() {
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'Type a word and tap Search to find images.',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Tap an image to preview and confirm:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final item = _results[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedImage = item;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 28, color: Colors.grey),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black.withOpacity(0.65),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            item.license.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
              const Text('Caregiver Confirmation', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.network(item.thumbnail, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Creator: ${item.creator} • License: ${item.license.toUpperCase()}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  child: const Text('Pick Another'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Save to Card (Offline)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
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
