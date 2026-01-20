import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/aac_card_model.dart';

enum CardEditorAction { saved, addSubCard }

class CardEditorDialog extends StatefulWidget {
  final AACCard card;
  final bool isNew;
  final List<String> categories;
  final AudioPlayer audioPlayer;
  final VoidCallback onPickImage;

  const CardEditorDialog({
    Key? key,
    required this.card,
    required this.isNew,
    required this.categories,
    required this.audioPlayer,
    required this.onPickImage,
  }) : super(key: key);

  @override
  State<CardEditorDialog> createState() => _CardEditorDialogState();
}

class _CardEditorDialogState extends State<CardEditorDialog> {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
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
  Duration _playDuration = Duration.zero;
  Duration _playPosition = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controllerEn = TextEditingController(text: widget.card.label);
    _controllerSi =
        TextEditingController(text: widget.card.labelSinhala ?? '');
    _controllerTa = TextEditingController(text: widget.card.labelTamil ?? '');
    _selectedCategory = widget.card.category;
    _selectedType = widget.card.type;
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
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

    final dir = await getApplicationDocumentsDirectory();
    final safeId = _safeIdForFile(widget.card.id);
    final path =
        '${dir.path}/voice_${safeId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: path);
    _recordStart = DateTime.now();
    setState(() {
      _isRecording = true;
      _recordProgress = 0.0;
    });

    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_recordStart == null) return;
      final elapsedMs =
          DateTime.now().difference(_recordStart!).inMilliseconds;
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
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    _positionSub = null;
    _durationSub = null;
    _completeSub = null;
  }

  Future<void> _stopPlayback() async {
    if (!_isPlaying) return;
    await widget.audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _playPosition = Duration.zero;
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

    _durationSub = widget.audioPlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() {
        _playDuration = d;
      });
    });
    _positionSub = widget.audioPlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() {
        _playPosition = p;
      });
    });
    _completeSub = widget.audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _playPosition = Duration.zero;
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
    widget.card.label = _controllerEn.text;
    widget.card.labelSinhala =
        _controllerSi.text.isEmpty ? null : _controllerSi.text;
    widget.card.labelTamil =
        _controllerTa.text.isEmpty ? null : _controllerTa.text;
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
    final maxWidth = (isLandscape ? media.width * 0.7 : media.width * 0.9)
        .clamp(320.0, 520.0);
    final maxHeight = media.height * 0.8;
    final fieldSpacing = isLandscape ? 12.0 : 8.0;

    return WillPopScope(
      onWillPop: () async {
        await _stopAll();
        return true;
      },
      child: AlertDialog(
        title: Text(widget.isNew ? 'Create Card' : 'Edit Card'),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 24 : 16,
          vertical: 16,
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                int columns = 1;
                if (isLandscape && constraints.maxWidth >= 700) {
                  columns = 3;
                } else if (isLandscape && constraints.maxWidth >= 420) {
                  columns = 2;
                }
                final totalSpacing = fieldSpacing * (columns - 1);
                final fieldWidth = columns == 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - totalSpacing) / columns;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: fieldSpacing,
                      runSpacing: fieldSpacing,
                      children: [
                        SizedBox(
                          width: fieldWidth,
                          child: TextField(
                            controller: _controllerEn,
                            decoration: const InputDecoration(
                              labelText: 'English',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextField(
                            controller: _controllerSi,
                            decoration: const InputDecoration(
                              labelText: 'Sinhala (?????)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextField(
                            controller: _controllerTa,
                            decoration: const InputDecoration(
                              labelText: 'Tamil (?????)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: widget.categories
                                .map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(
                                  () => _selectedCategory = value ?? 'General');
                            },
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'word', child: Text('Word')),
                              DropdownMenuItem(
                                  value: 'folder', child: Text('Folder')),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedType = value ?? 'word');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onPickImage,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Photo'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (_isRecording) {
                                await _stopRecording();
                              } else {
                                await _startRecording();
                              }
                            },
                            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                            label: Text(_isRecording ? 'Stop' : 'Voice'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording ? Colors.red : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isRecording)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            LinearProgressIndicator(value: _recordProgress),
                            const SizedBox(height: 6),
                            Text(
                                'Recording ${(_recordProgress * 15).ceil()}/15s'),
                          ],
                        ),
                      ),
                    if (widget.card.voicePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(_isPlaying
                                      ? Icons.stop
                                      : Icons.play_arrow),
                                  onPressed: () async {
                                    if (_isPlaying) {
                                      await _stopPlayback();
                                    } else {
                                      await _startPlayback();
                                    }
                                  },
                                ),
                                const Text('Play Recorded Voice'),
                              ],
                            ),
                            Slider(
                              value: _playDuration.inMilliseconds == 0
                                  ? 0
                                  : _playPosition.inMilliseconds
                                      .clamp(0, _playDuration.inMilliseconds)
                                      .toDouble(),
                              max: _playDuration.inMilliseconds == 0
                                  ? 1
                                  : _playDuration.inMilliseconds.toDouble(),
                              onChanged: (value) async {
                                if (_playDuration.inMilliseconds == 0) return;
                                final position =
                                    Duration(milliseconds: value.toInt());
                                await widget.audioPlayer.seek(position);
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: widget.isNew
                          ? null
                          : () async {
                              await _stopAll();
                              Navigator.pop(
                                  context, CardEditorAction.addSubCard);
                            },
                      icon: const Icon(Icons.add_box),
                      label: const Text('Add Sub-Card'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _stopAll();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _stopAll();
              _saveCard();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
