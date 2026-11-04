import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import '../models/aac_card_model.dart';
import '../services/card_storage_service.dart';
import '../services/multilingual_concept_service.dart';
import '../services/network_policy_service.dart';
import 'smart_image_search_dialog.dart';

enum CardEditorAction { saved, addSubCard }

class CardEditorDialog extends StatefulWidget {
  final AACCard card;
  final bool isNew;
  final List<String> categories;
  final AudioPlayer audioPlayer;
  final VoidCallback? onPickImage;

  const CardEditorDialog({
    Key? key,
    required this.card,
    required this.isNew,
    required this.categories,
    required this.audioPlayer,
    this.onPickImage,
  }) : super(key: key);

  @override
  State<CardEditorDialog> createState() => _CardEditorDialogState();
}

class _CardEditorDialogState extends State<CardEditorDialog> {
  final AudioRecorder _recorder = AudioRecorder();
  final ImagePicker _picker = ImagePicker();

  StreamSubscription<void>? _completeSub;

  late final TextEditingController _controllerEn;
  late final TextEditingController _controllerSi;
  late final TextEditingController _controllerTa;

  String _selectedCategory = 'General';
  String _selectedType = 'word';
  bool _isRecording = false;
  double _recordProgress = 0.0;
  Timer? _recordTimer;
  DateTime? _recordStart;
  bool _isPlaying = false;
  String _detectedConcept = '';

  @override
  void initState() {
    super.initState();
    _controllerEn = TextEditingController(text: widget.card.label);
    _controllerSi = TextEditingController(text: widget.card.labelSinhala ?? '');
    _controllerTa = TextEditingController(text: widget.card.labelTamil ?? '');
    _selectedCategory = widget.card.category;
    _selectedType = widget.card.type;

    _controllerEn.addListener(_updateConcept);
    _controllerSi.addListener(_updateConcept);
    _controllerTa.addListener(_updateConcept);
    _updateConcept();
  }

  void _updateConcept() {
    final text = _controllerSi.text.isNotEmpty
        ? _controllerSi.text
        : (_controllerTa.text.isNotEmpty ? _controllerTa.text : _controllerEn.text);
    final concept = MultilingualConceptService.normalizeConcept(text);
    if (concept != _detectedConcept) {
      setState(() {
        _detectedConcept = concept;
      });
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _completeSub?.cancel();
    _recorder.dispose();
    _controllerEn.dispose();
    _controllerSi.dispose();
    _controllerTa.dispose();
    super.dispose();
  }

  String _safeIdForFile(String raw) {
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      final permanentPath = await CardStorageService.persistMediaFile(
        image.path,
        cardId: widget.card.id,
        mediaType: 'images',
      );
      setState(() {
        widget.card.imagePath = permanentPath;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo != null) {
      final permanentPath = await CardStorageService.persistMediaFile(
        photo.path,
        cardId: widget.card.id,
        mediaType: 'images',
      );
      setState(() {
        widget.card.imagePath = permanentPath;
      });
    }
  }

  Future<void> _openSmartSearch() async {
    final isOnline = NetworkPolicyService.instance.isOnlineEnabled;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Online Features are currently disabled in the drawer menu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final query = _detectedConcept.isNotEmpty
        ? _detectedConcept
        : (_controllerEn.text.isNotEmpty ? _controllerEn.text : '');

    final resultPath = await showDialog<String>(
      context: context,
      builder: (context) => SmartImageSearchDialog(
        initialQuery: query,
        cardId: widget.card.id,
      ),
    );

    if (resultPath != null && mounted) {
      setState(() {
        widget.card.imagePath = resultPath;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    _recordTimer = null;
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordProgress = 0.0;
    });
    if (path != null) {
      widget.card.voicePath = path;
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }

    final dir = await CardStorageService.mediaDirectory('voices');
    final safeId = _safeIdForFile(widget.card.id);
    final path = '${dir.path}/voice_${safeId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: path);
    _recordStart = DateTime.now();
    setState(() {
      _isRecording = true;
      _recordProgress = 0.0;
    });

    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_recordStart == null) return;
      final elapsedMs = DateTime.now().difference(_recordStart!).inMilliseconds;
      final progress = (elapsedMs / 15000).clamp(0.0, 1.0);
      if (!mounted) return;
      setState(() {
        _recordProgress = progress;
      });
      if (elapsedMs >= 15000) {
        _stopRecording();
      }
    });
  }

  void _disposePlayback() {
    _completeSub?.cancel();
    _completeSub = null;
  }

  Future<void> _stopPlayback() async {
    if (!_isPlaying) return;
    await widget.audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _startPlayback() async {
    if (_isRecording) {
      await _stopRecording();
    }
    if (widget.card.voicePath == null) return;
    if (!await File(widget.card.voicePath!).exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recorded file not found')),
        );
      }
      return;
    }
    _disposePlayback();

    _completeSub = widget.audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
      });
      _disposePlayback();
    });

    try {
      await widget.audioPlayer.play(DeviceFileSource(widget.card.voicePath!));
      if (!mounted) return;
      setState(() {
        _isPlaying = true;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to play recorded audio')),
        );
      }
    }
  }

  Future<void> _stopAll() async {
    if (_isRecording) {
      await _stopRecording();
    }
    await _stopPlayback();
    _disposePlayback();
  }

  void _saveCard() {
    widget.card.label = _controllerEn.text.trim();
    widget.card.labelSinhala = _controllerSi.text.trim().isEmpty ? null : _controllerSi.text.trim();
    widget.card.labelTamil = _controllerTa.text.trim().isEmpty ? null : _controllerTa.text.trim();
    widget.card.category = _selectedCategory;
    widget.card.type = _selectedType;
    if (widget.card.type == 'word') {
      widget.card.subCards.clear();
    }
    Navigator.pop(context, CardEditorAction.saved);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final isLandscape = media.width > media.height;
    final maxWidth = (isLandscape ? media.width * 0.75 : media.width * 0.95).clamp(320.0, 560.0);
    final maxHeight = (isLandscape ? media.height * 0.58 : media.height * 0.64).clamp(280.0, 640.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _stopAll();
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Icon(
              widget.isNew ? Icons.add_circle : Icons.edit,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text(
              widget.isNew ? 'Create New Card' : 'Edit Card',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Preview & Action Selector Card
                _buildImageSection(context),
                const SizedBox(height: 16),

                // Multilingual Label Fields
                _buildLabelSection(context),
                const SizedBox(height: 16),

                // Audio Recording & Playback Section
                _buildAudioSection(context),
                const SizedBox(height: 16),

                // Card Properties (Category & Type)
                _buildPropertiesSection(context),

                if (!widget.isNew && widget.card.type == 'folder') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Manage Sub-Cards'),
                    onPressed: () async {
                      await _stopAll();
                      if (context.mounted) {
                        Navigator.pop(context, CardEditorAction.addSubCard);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _stopAll();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await _stopAll();
              _saveCard();
            },
            child: const Text('Save Card', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final imagePath = widget.card.imagePath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    final isOnline = NetworkPolicyService.instance.isOnlineEnabled;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Image Preview Container
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageView(imagePath),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.6),
                          radius: 16,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close, color: Colors.white, size: 18),
                            onPressed: () {
                              setState(() {
                                widget.card.imagePath = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 6),
                        Text(
                          'No Image Selected',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 10),

          // Concept hint chip if detected
          if (_detectedConcept.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: _openSmartSearch,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Concept: "$_detectedConcept"',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade800),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(Tap to search)',
                        style: TextStyle(fontSize: 10, color: Colors.blue.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Action Chips: Smart Search | Gallery | Camera
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: isOnline ? const Color(0xFF0288D1) : Colors.grey,
                  ),
                  label: Text(
                    isOnline ? 'Smart Search' : 'Search (Offline)',
                    style: TextStyle(fontSize: 11, color: isOnline ? null : Colors.grey),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _openSmartSearch,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Gallery', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _pickFromGallery,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Camera', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _pickFromCamera,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageView(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.contain);
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.contain);
    }
    return Image.network(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
    );
  }

  Widget _buildLabelSection(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controllerEn,
          decoration: InputDecoration(
            labelText: 'English Label',
            hintText: 'e.g., Cat, Water, Happy',
            prefixIcon: const Icon(Icons.language, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controllerSi,
          decoration: InputDecoration(
            labelText: 'Sinhala Label (සිංහල)',
            hintText: 'e.g., පූසා, වතුර, සතුටුයි',
            prefixIcon: const Icon(Icons.translate, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controllerTa,
          decoration: InputDecoration(
            labelText: 'Tamil Label (தமிழ்)',
            hintText: 'e.g., பூனை, தண்ணீர், மகிழ்ச்சி',
            prefixIcon: const Icon(Icons.g_translate, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Custom Voice Recording (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_isRecording) {
                      await _stopRecording();
                    } else {
                      await _startRecording();
                    }
                  },
                  icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record, size: 18),
                  label: Text(_isRecording ? 'Stop Recording' : 'Record Voice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (widget.card.voicePath != null) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                  onPressed: () async {
                    if (_isPlaying) {
                      await _stopPlayback();
                    } else {
                      await _startPlayback();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      widget.card.voicePath = null;
                    });
                  },
                ),
              ],
            ],
          ),
          if (_isRecording) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _recordProgress, color: Colors.red),
            const SizedBox(height: 4),
            Text(
              'Recording ${(_recordProgress * 15).ceil()}/15s',
              style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPropertiesSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: widget.categories
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedCategory = value ?? 'General');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: InputDecoration(
              labelText: 'Card Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'word', child: Text('Word Card')),
              DropdownMenuItem(value: 'folder', child: Text('Folder Card')),
            ],
            onChanged: (value) {
              setState(() => _selectedType = value ?? 'word');
            },
          ),
        ),
      ],
    );
  }
}
