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
import '../utils/app_permissions_helper.dart';
import 'smart_image_search_dialog.dart';
import 'styled_dialog_header.dart';

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
    final primary = _controllerSi.text.trim().isNotEmpty
        ? _controllerSi.text.trim()
        : (_controllerTa.text.trim().isNotEmpty
            ? _controllerTa.text.trim()
            : _controllerEn.text.trim());
    var concept = MultilingualConceptService.normalizeConcept(primary);

    // If Sinhala/Tamil input was outside our offline glossary while English is filled,
    // use the normalized English label for fast accurate search.
    if (!MultilingualConceptService.isLatinScript(concept) &&
        _controllerEn.text.trim().isNotEmpty) {
      concept = MultilingualConceptService.normalizeConcept(_controllerEn.text);
    }

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

  Future<void> _pickImageFromSource(ImageSource source) async {
    final allowed = source == ImageSource.camera
        ? await AppPermissionsHelper.ensureCameraPermission(context)
        : await AppPermissionsHelper.ensureLegacyStorageIfNeeded(context);
    if (!allowed || !mounted) return;

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;
      final permanentPath = await CardStorageService.persistMediaFile(
        picked.path,
        cardId: widget.card.id,
        mediaType: 'images',
      );
      if (!mounted) return;
      setState(() {
        widget.card.imagePath = permanentPath;
      });
    } catch (e) {
      if (!mounted) return;
      final label = source == ImageSource.camera ? 'Camera' : 'Gallery';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label unavailable or permission denied. Check App Permissions if needed.',
          ),
        ),
      );
    }
  }

  Future<void> _pickFromGallery() => _pickImageFromSource(ImageSource.gallery);

  Future<void> _pickFromCamera() => _pickImageFromSource(ImageSource.camera);

  Future<void> _openSmartSearch() async {
    final query = _detectedConcept.isNotEmpty
        ? _detectedConcept
        : (_controllerEn.text.trim().isNotEmpty
            ? _controllerEn.text.trim()
            : '');

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
    try {
      final path = await _recorder.stop();
      if (path != null) {
        widget.card.voicePath = path;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordProgress = 0.0;
    });
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    final allowed = await AppPermissionsHelper.ensureMicrophonePermission(context);
    if (!allowed) return;
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
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final isLandscape = media.width > media.height;
    final maxWidth =
        (isLandscape ? media.width * 0.72 : media.width - 32).clamp(280.0, 520.0);
    final availableHeight = (media.height - viewInsetsBottom).clamp(240.0, media.height);
    final maxHeight =
        (availableHeight * (isLandscape ? 0.68 : 0.72)).clamp(220.0, 660.0);

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
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        title: StyledDialogHeader(
          icon: widget.isNew
              ? Icons.add_photo_alternate_rounded
              : Icons.edit_rounded,
          title: widget.isNew ? 'Create New Card' : 'Edit Card',
        ),
        content: SizedBox(
          width: maxWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImageSection(context),
                  const SizedBox(height: 14),
                  _buildLabelSection(context),
                  const SizedBox(height: 14),
                  _buildAudioSection(context),
                  const SizedBox(height: 14),
                  _buildPropertiesSection(context),
                  if (!widget.isNew && widget.card.type == 'folder') ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text('Manage Sub-Cards'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await _stopAll();
              _saveCard();
            },
            child: const Text(
              'Save Card',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final imagePath = widget.card.imagePath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    final isOnline = NetworkPolicyService.instance.isOnlineEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageView(imagePath),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              setState(() {
                                widget.card.imagePath = null;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 38,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No Image Selected',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          if (_detectedConcept.isNotEmpty) ...[
            InkWell(
              onTap: _openSmartSearch,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isOnline
                      ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOnline
                        ? colorScheme.primary.withValues(alpha: 0.25)
                        : colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    SmartSearchIcon(
                      size: 16,
                      color: isOnline ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Concept: "$_detectedConcept"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOnline
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Search' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOnline
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MediaSourceTile(
                    iconWidget: SmartSearchIcon(
                      size: 22,
                      color: isOnline ? colorScheme.primary : colorScheme.outline,
                    ),
                    label: isOnline ? 'Smart Search' : 'Web (Offline)',
                    accentColor: isOnline ? colorScheme.primary : colorScheme.outline,
                    isMuted: !isOnline,
                    onTap: _openSmartSearch,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MediaSourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    accentColor: colorScheme.secondary,
                    onTap: _pickFromGallery,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MediaSourceTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    accentColor: colorScheme.tertiary,
                    onTap: _pickFromCamera,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageView(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        cacheWidth: 640,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        cacheWidth: 640,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
      );
    }
    if (!NetworkPolicyService.instance.isOnlineEnabled) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
      );
    }
    return Image.network(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
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
            prefixIcon: const Icon(Icons.language_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controllerSi,
          decoration: InputDecoration(
            labelText: 'Sinhala Label (සිංහල)',
            hintText: 'e.g., පූසා, වතුර, සතුටුයි',
            prefixIcon: const Icon(Icons.translate_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controllerTa,
          decoration: InputDecoration(
            labelText: 'Tamil Label (தமிழ்)',
            hintText: 'e.g., பூனை, தண்ணீர், மகிழ்ச்சி',
            prefixIcon: const Icon(Icons.g_translate_rounded, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Voice Recording (Optional)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    if (_isRecording) {
                      await _stopRecording();
                    } else {
                      await _startRecording();
                    }
                  },
                  icon: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.fiber_manual_record,
                    size: 18,
                  ),
                  label: Text(
                    _isRecording ? 'Stop Recording' : 'Record Voice',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: _isRecording ? Colors.red : colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (widget.card.voicePath != null) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: _isPlaying ? 'Stop playback' : 'Play recording',
                  icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  onPressed: () async {
                    if (_isPlaying) {
                      await _stopPlayback();
                    } else {
                      await _startPlayback();
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Delete recording',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
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
              style: const TextStyle(
                fontSize: 11,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPropertiesSection(BuildContext context) {
    final categoryItems = <String>{
      ...widget.categories,
      _selectedCategory,
    }.toList();

    Widget buildCategoryField() {
      return DropdownButtonFormField<String>(
        initialValue: _selectedCategory,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: categoryItems
            .map(
              (cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() => _selectedCategory = value ?? 'General');
        },
      );
    }

    Widget buildTypeField() {
      return DropdownButtonFormField<String>(
        initialValue: _selectedType,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Card Type',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: const [
          DropdownMenuItem(
            value: 'word',
            child: Text('Word Card', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          DropdownMenuItem(
            value: 'folder',
            child: Text('Folder Card', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
        onChanged: (value) {
          setState(() => _selectedType = value ?? 'word');
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            children: [
              buildCategoryField(),
              const SizedBox(height: 10),
              buildTypeField(),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: buildCategoryField()),
            const SizedBox(width: 10),
            Expanded(child: buildTypeField()),
          ],
        );
      },
    );
  }
}

class _MediaSourceTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final Color accentColor;
  final bool isMuted;
  final VoidCallback onTap;

  const _MediaSourceTile({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.accentColor,
    this.isMuted = false,
    required this.onTap,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: isMuted
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : accentColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMuted
                  ? colorScheme.outlineVariant
                  : accentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget ?? Icon(icon!, size: 20, color: accentColor),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isMuted
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
