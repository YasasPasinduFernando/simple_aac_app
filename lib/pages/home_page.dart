import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../data/default_seed_cards.dart';
import '../models/aac_card_model.dart';
import '../models/tts_token.dart';
import '../services/backup_service.dart';
import '../services/card_storage_service.dart';
import '../services/network_policy_service.dart';
import '../services/speech_engine.dart';
import '../widgets/card_editor_dialog.dart';
import '../widgets/professional_color_picker_dialog.dart';

import '../widgets/edit_mode_bar.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_drawer.dart';
import '../widgets/landscape_menu.dart';
import '../widgets/styled_dialog_header.dart';
import '../widgets/tts_bar.dart';
import '../widgets/visible_cards_dialog.dart';
import '../utils/animated_media_helper.dart';
import '../utils/app_permissions_helper.dart';
import '../utils/camera_object_helper.dart';
import '../utils/card_image.dart';
import '../utils/theme_accessibility.dart';
import '../utils/ui_mode_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _gridController = ScrollController();

  List<AACCard> cards = [];
  int gridColumns = 2;
  Map<String, Set<String>> visibleCardIdsByParent = {};
  String currentLanguage = 'en';
  bool showTtsInput = true;
  String selectedCategory = 'All';
  Set<String> allCategories = {'General'};
  AACCard? activeParentCard;
  bool isEditMode = false;
  bool isCardEditorOpen = false;
  String? highlightedCardId;
  String? _tapAnimatedCardId;
  Timer? _highlightTimer;
  Timer? _tapAnimTimer;
  String orientationMode = 'portrait';
  bool fullScreen = false;
  bool isPinned = false;
  DateTime? _lastBackPress;
  final List<TtsToken> _ttsTokens = [];
  String searchQuery = '';
  List<AACCard>? _editSnapshotCards;
  Map<String, Set<String>>? _editSnapshotVisible;
  Set<String>? _editSnapshotCategories;
  String? _editSnapshotSelectedCategory;
  String? _editSnapshotActiveParentId;
  static const int _defaultPrimaryColorValue = 0xFF0277BD;
  int _themePrimaryColor = _defaultPrimaryColorValue;
  int _themeTextColor = Colors.white.value;
  int _themeBackgroundColor = Colors.white.value;
  double _ttsBarSize = 1.0;
  bool _showTtsActions = true;
  bool _hideTtsText = false;
  bool _useImageOverlayLabel = true;
  bool _applyTextColorToCards = false;
  bool _isDarkMode = ThemeAccessibility.darkModeNotifier.value;
  bool _isColorBlindMode = false;
  SpeechCapabilityReport? _speechCapabilities;
  bool _isBusyOperation = false;

  @visibleForTesting
  bool get useImageOverlayLabelForTesting => _useImageOverlayLabel;

  @visibleForTesting
  set useImageOverlayLabelForTesting(bool value) => _useImageOverlayLabel = value;

  @visibleForTesting
  void resetSettingsForTesting() => _resetSettingsToDefaults();

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _initTts() async {
    await SpeechEngine.instance.initialize();
    final report = await SpeechEngine.instance.probeCapabilities();
    if (mounted && report != null) {
      setState(() {
        _speechCapabilities = report;
      });
    }
  }

  Future<void> _loadCards() async {
    final sw = Stopwatch()..start();
    final results = await Future.wait<dynamic>([
      SharedPreferences.getInstance(),
      CardStorageService.loadCards(defaultCardsBuilder: _createSeedImageCards),
    ]);
    if (!mounted) return;

    final prefs = results[0] as SharedPreferences;
    final loadedCards = results[1] as List<AACCard>;

    final nextGridColumns = prefs.getInt('gridColumns') ?? 2;
    final nextShowTtsInput = prefs.getBool('showTtsInput') ?? true;
    final nextOrientation = prefs.getString('orientationMode') ?? 'portrait';
    final nextFullScreen = prefs.getBool('fullScreen') ?? true;
    final nextLanguage = prefs.getString('language') ?? 'en';
    final nextPrimary =
        prefs.getInt('themePrimaryColor') ?? _defaultPrimaryColorValue;
    final nextText = prefs.getInt('themeTextColor') ?? Colors.white.value;
    final nextBg = prefs.getInt('themeBackgroundColor') ?? Colors.white.value;
    final nextTtsSize = prefs.getDouble('ttsBarSize') ?? 1.0;
    final nextShowActions = prefs.getBool('showTtsActions') ?? true;
    final nextHideTts = prefs.getBool('hideTtsText') ?? false;
    final nextOverlay = prefs.getBool('useImageOverlayLabel') ?? true;
    final nextApplyText = prefs.getBool('applyTextColorToCards') ?? false;
    final nextDark =
        prefs.getBool(ThemeAccessibility.darkModePrefKey) ?? _isDarkMode;
    final nextColorBlind =
        prefs.getBool(ThemeAccessibility.colorBlindPrefKey) ?? false;

    setState(() {
      cards = loadedCards;
      gridColumns = nextGridColumns;
      _loadVisibleSelections(prefs);
      showTtsInput = nextShowTtsInput;
      orientationMode = nextOrientation;
      fullScreen = nextFullScreen;
      currentLanguage = nextLanguage;
      _themePrimaryColor = nextPrimary;
      _themeTextColor = nextText;
      _themeBackgroundColor = nextBg;
      _ttsBarSize = nextTtsSize;
      _showTtsActions = nextShowActions;
      _hideTtsText = nextHideTts;
      _useImageOverlayLabel = nextOverlay;
      _applyTextColorToCards = nextApplyText;
      _isDarkMode = nextDark;
      _isColorBlindMode = nextColorBlind;
      _updateCategories();
      _migrateVisibleCountIfNeeded(prefs);
    });

    if (ThemeAccessibility.darkModeNotifier.value != nextDark) {
      ThemeAccessibility.darkModeNotifier.value = nextDark;
    }
    UiModeHelper.applyOrientation(nextOrientation);
    UiModeHelper.applySystemUi(nextFullScreen);
    debugPrint('[HomePage] cold loadCards completed in ${sw.elapsedMilliseconds}ms');

    // Initialize TTS after first frame paints and loaded language/voice settings are known.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initTts());
    });
  }

  List<AACCard> _createSeedImageCards() {
    return createDefaultSeedCards();
  }

  // ignore: unused_element
  List<AACCard> _createDefaultCards() {
    return _createSeedImageCards();
  }

  void _loadVisibleSelections(SharedPreferences prefs) {
    final savedMap = prefs.getString('visibleCardIdsByParent');
    if (savedMap != null) {
      final decoded = jsonDecode(savedMap) as Map<String, dynamic>;
      visibleCardIdsByParent = decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List).map((v) => v.toString()).toSet(),
        ),
      );
      return;
    }

    final savedVisibleIds = prefs.getStringList('visibleCardIds') ?? [];
    if (savedVisibleIds.isNotEmpty) {
      visibleCardIdsByParent['__root__'] = savedVisibleIds.toSet();
    }
  }

  void _migrateVisibleCountIfNeeded(SharedPreferences prefs) {
    if (visibleCardIdsByParent.isNotEmpty) return;
    final legacyCount = prefs.getInt('visibleCardCount') ?? 0;
    if (legacyCount <= 0) return;
    final base = _getBaseDisplayedCards();
    visibleCardIdsByParent['__root__'] =
        base.take(legacyCount).map((c) => c.id).toSet();
  }

  void _updateCategories() {
    allCategories.clear();
    allCategories.add('All');
    for (var card in cards) {
      allCategories.add(card.category);
      for (var subCard in card.subCards) {
        allCategories.add(subCard.category);
      }
    }
  }

  Future<void> _saveCards() async {
    await Future.wait([
      CardStorageService.saveCards(cards),
      SharedPreferences.getInstance().then((prefs) async {
        final encodedVisible = jsonEncode(
          visibleCardIdsByParent.map(
            (key, value) => MapEntry(key, value.toList()),
          ),
        );
        await Future.wait([
          prefs.setInt('gridColumns', gridColumns),
          prefs.setString('visibleCardIdsByParent', encodedVisible),
          prefs.setBool('showTtsInput', showTtsInput),
          prefs.setString('orientationMode', orientationMode),
          prefs.setBool('fullScreen', fullScreen),
          prefs.setString('language', currentLanguage),
          prefs.setInt('themePrimaryColor', _themePrimaryColor),
          prefs.setInt('themeTextColor', _themeTextColor),
          prefs.setInt('themeBackgroundColor', _themeBackgroundColor),
          prefs.setDouble('ttsBarSize', _ttsBarSize),
          prefs.setBool('showTtsActions', _showTtsActions),
          prefs.setBool('hideTtsText', _hideTtsText),
          prefs.setBool('useImageOverlayLabel', _useImageOverlayLabel),
          prefs.setBool('applyTextColorToCards', _applyTextColorToCards),
          prefs.setBool(ThemeAccessibility.darkModePrefKey, _isDarkMode),
          prefs.setBool(
              ThemeAccessibility.colorBlindPrefKey, _isColorBlindMode),
        ]);
      }),
    ]);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _speak(String text, {bool waitForCompletion = false}) async {
    try {
      await _audioPlayer.stop();
      final result = await SpeechEngine.instance.speak(
        text,
        preferredLanguage: currentLanguage,
        waitForCompletion: waitForCompletion,
      );
      if (!result.isSuccess &&
          result.status != SpeechStatus.emptyText &&
          mounted) {
        final missingLang = result.missingLanguages.isNotEmpty
            ? _getLanguageName(result.missingLanguages.first)
            : _getLanguageName(currentLanguage);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                result.status == SpeechStatus.languageUnavailable
                    ? '$missingLang speech voice is not installed on this device.'
                    : 'Speech engine unavailable for $missingLang.',
              ),
              action: SnackBarAction(
                label: 'Install Voice',
                onPressed: () {
                  unawaited(SpeechEngine.instance.openSystemTtsInstaller());
                },
              ),
            ),
          );
      }
    } catch (e) {
      debugPrint('[HomePage] TTS speak error: $e');
    }
  }

  void _appendToTtsInput(
    String text, {
    String? imagePath,
    String? voicePath,
  }) {
    if (!showTtsInput) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _ttsTokens.add(TtsToken(trimmed, imagePath, voicePath: voicePath));
    });
  }

  void _clearTtsInput() {
    setState(() {
      _ttsTokens.clear();
    });
  }

  void _deleteLastWord() {
    if (_ttsTokens.isNotEmpty) {
      setState(() {
        _ttsTokens.removeLast();
      });
      return;
    }
  }

  void _resetTtsInput() {
    _ttsTokens.clear();
  }

  void _triggerWordTapAnimation(String cardId) {
    _tapAnimTimer?.cancel();
    setState(() {
      highlightedCardId = null;
      _tapAnimatedCardId = cardId;
    });
    _tapAnimTimer = Timer(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      setState(() {
        _tapAnimatedCardId = null;
      });
    });
  }

  Future<bool> _playVoice(String path) async {
    try {
      await SpeechEngine.instance.stop();
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(path));
      return true;
    } catch (e) {
      debugPrint('[HomePage] Voice playback failed: $e');
      return false;
    }
  }

  Future<void> _speakOrPlayCard(AACCard card, String label) async {
    final voicePath = card.voicePath;
    if (voicePath != null && await File(voicePath).exists()) {
      final played = await _playVoice(voicePath);
      if (played) return;
    }
    await _speak(label);
  }

  Future<void> _playTtsTokens() async {
    final snapshot = List<TtsToken>.of(_ttsTokens);
    for (final token in snapshot) {
      final voicePath = token.voicePath;
      if (voicePath != null && await File(voicePath).exists()) {
        final played = await _playVoice(voicePath);
        if (played) {
          try {
            await _audioPlayer.onPlayerComplete.first.timeout(
              const Duration(seconds: 20),
            );
            continue;
          } catch (_) {}
        }
      }
      await _speak(token.label, waitForCompletion: true);
    }
  }

  Future<void> _pickImage(AACCard card) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: const StyledDialogHeader(
          icon: Icons.add_a_photo_rounded,
          title: 'Choose Image Source',
          subtitle: 'Add a photo or short GIF to this card',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogOptionTile(
                icon: Icons.camera_alt_rounded,
                title: 'Camera',
                subtitle: 'Take a new photo now',
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              DialogOptionTile(
                icon: Icons.photo_library_rounded,
                title: 'Gallery',
                subtitle: 'Choose a photo from your device',
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              DialogOptionTile(
                icon: Icons.gif_box_rounded,
                title: 'GIF / Short Video',
                subtitle: 'Max 30s video clip or existing .gif',
                onTap: () => Navigator.pop(context, 'gif'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (choice == 'gif') {
      final gifPath = await AnimatedMediaHelper.pickOrCreateAnimatedGif(
        context,
        cardId: card.id,
      );
      if (gifPath != null && mounted) {
        setState(() {
          card.imagePath = gifPath;
        });
        _saveCards();
      }
      return;
    }

    if (choice == 'camera') {
      try {
        final outcome = await CameraObjectHelper.captureAndVerify(
          context,
          cardId: card.id,
          imageQuality: 80,
        );
        if (outcome != null && mounted) {
          setState(() {
            card.imagePath = outcome.imagePath;
          });
          _saveCards();
          if (outcome.analysis.analyzerAvailable &&
              outcome.analysis.hasObject &&
              outcome.analysis.labels.isNotEmpty) {
            final suggested = outcome.analysis.labels.first;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Detected (offline): $suggested'),
                action: SnackBarAction(
                  label: 'Use Word',
                  onPressed: () {
                    if (!mounted) return;
                    setState(() {
                      card.label = suggested;
                    });
                    _saveCards();
                  },
                ),
              ),
            );
          }
        }
      } catch (error, stackTrace) {
        debugPrint('[HomePage] camera capture failed: $error');
        debugPrint(stackTrace.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera photo could not be saved. Check permissions if needed.'),
            ),
          );
        }
      }
    } else if (choice == 'gallery') {
      final allowed = await AppPermissionsHelper.ensureLegacyStorageIfNeeded(context);
      if (!allowed || !mounted) return;

      try {
        final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (image != null) {
          final permanentPath = await CardStorageService.persistMediaFile(
            image.path,
            cardId: card.id,
            mediaType: 'images',
          );
          debugPrint(
            '[HomePage] image selected for card ${card.id}: '
            'pickerPath=${image.path}, savedPath=$permanentPath',
          );
          setState(() {
            card.imagePath = permanentPath;
          });
          _saveCards();
        }
      } catch (error, stackTrace) {
        debugPrint('[HomePage] image save failed: $error');
        debugPrint(stackTrace.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image could not be selected. Check permissions if needed.'),
            ),
          );
        }
      }
    }
  }

  void _setHighlight(String cardId) {
    _highlightTimer?.cancel();
    setState(() {
      highlightedCardId = cardId;
    });
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        highlightedCardId = null;
      });
    });
  }

  Future<void> _editCard(
    AACCard card, {
    bool isNew = false,
    void Function(AACCard card)? onSave,
  }) async {
    if (isCardEditorOpen) return;
    isCardEditorOpen = true;
    final action = await showDialog<CardEditorAction>(
      context: context,
      builder: (context) => CardEditorDialog(
        card: card,
        isNew: isNew,
        categories: allCategories.toList(),
        audioPlayer: _audioPlayer,
        onPickImage: () {
          Navigator.pop(context);
          _pickImage(card);
        },
      ),
    );
    if (mounted) {
      setState(() {
        isCardEditorOpen = false;
      });
    } else {
      isCardEditorOpen = false;
    }
    if (action == CardEditorAction.addSubCard) {
      _createCard(parent: card);
    } else if (action == CardEditorAction.saved) {
      debugPrint(
        '[HomePage] card editor saved: id=${card.id}, label=${card.label}, '
        'imagePath=${card.imagePath}, voicePath=${card.voicePath}',
      );
      if (onSave != null) {
        onSave(card);
      } else {
        _updateCategories();
        _saveCards();
      }
    }
  }

  void _createCard({AACCard? parent}) {
    if (isCardEditorOpen) return;
    final newCard = AACCard(
      id: DateTime.now().toString(),
      label: 'New',
      colorValue: parent != null
          ? Color.lerp(Color(parent.colorValue), Colors.white, 0.25)!.toARGB32()
          : Colors.primaries[cards.length % Colors.primaries.length].toARGB32(),
      category: parent != null
          ? parent.category
          : (selectedCategory == 'All' ? 'General' : selectedCategory),
    );
    debugPrint(
      '[HomePage] opening create card editor: id=${newCard.id}, '
      'parentId=${parent?.id}',
    );

    _editCard(
      newCard,
      isNew: true,
      onSave: (savedCard) {
        setState(() {
          if (parent != null) {
            parent.type = 'folder';
            parent.subCards.add(savedCard);
            activeParentCard = parent;
            _includeInVisibleSelection(parent.id, savedCard.id);
          } else {
            cards.add(savedCard);
            _includeInVisibleSelection('__root__', savedCard.id);
          }
        });
        _updateCategories();
        _saveCards();
        debugPrint(
          '[HomePage] new card saved: id=${savedCard.id}, '
          'parentId=${parent?.id}, imagePath=${savedCard.imagePath}',
        );
        _setHighlight(savedCard.id);
        _scrollToEnd();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New card created')),
        );
      },
    );
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_gridController.hasClients) return;
      _gridController.animateTo(
        _gridController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSubCards(AACCard card) {
    if (card.type != 'folder') return;
    setState(() {
      _resetTtsInput();
      activeParentCard = card;
    });
  }

  void _confirmDelete(AACCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: const StyledDialogHeader(
          icon: Icons.delete_forever_rounded,
          title: 'Delete Card',
          accentColor: Colors.red,
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.delete_sweep_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Remove "${card.getLabel(currentLanguage)}" from your communication board?',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete'),
            onPressed: () {
              debugPrint(
                '[HomePage] deleting card: id=${card.id}, '
                'label=${card.label}, activeParentId=${activeParentCard?.id}',
              );
              setState(() {
                if (activeParentCard != null) {
                  activeParentCard!.subCards.remove(card);
                } else {
                  cards.remove(card);
                }
              });
              _updateCategories();
              _saveCards();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'si':
        return '\u0dc3\u0dd2\u0d82\u0dc4\u0dbd (Sinhala)';
      case 'ta':
        return '\u0ba4\u0bae\u0bbf\u0bb4\u0bcd (Tamil)';
      default:
        return 'English';
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        void selectLang(String code) {
          setState(() {
            currentLanguage = code;
          });
          unawaited(_initTts());
          _saveCards();
          Navigator.pop(context);
          Navigator.pop(context);
        }

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          title: const StyledDialogHeader(
            icon: Icons.translate_rounded,
            title: 'Select Language',
            subtitle: 'Board & voice output language',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DialogOptionTile(
                  icon: Icons.language_rounded,
                  badgeText: 'EN',
                  title: 'English',
                  subtitle: 'English labels & speech',
                  selected: currentLanguage == 'en',
                  onTap: () => selectLang('en'),
                ),
                DialogOptionTile(
                  icon: Icons.translate_rounded,
                  badgeText: 'සි',
                  title: '\u0dc3\u0dd2\u0d82\u0dc4\u0dbd (Sinhala)',
                  subtitle: 'සිංහල පුවරු සහ කථනය',
                  selected: currentLanguage == 'si',
                  onTap: () => selectLang('si'),
                ),
                DialogOptionTile(
                  icon: Icons.g_translate_rounded,
                  badgeText: 'த',
                  title: '\u0ba4\u0bae\u0bbf\u0bb4\u0bcd (Tamil)',
                  subtitle: 'தமிழ் பலகை மற்றும் பேச்சு',
                  selected: currentLanguage == 'ta',
                  onTap: () => selectLang('ta'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  String _speechDrawerSubtitle() {
    final report = _speechCapabilities;
    if (report == null) return 'Automatic offline voice';
    final unsupported = report.unsupportedLanguages;
    if (unsupported.isEmpty) {
      return report.missingLanguages.isEmpty
          ? 'English, Sinhala & Tamil ready offline'
          : 'English, Sinhala & Tamil ready';
    }
    return 'Check voice data: ${unsupported.map(_getLanguageName).join(', ')}';
  }

  void _showOfflineSpeechDialog() {
    Navigator.pop(context);
    var report = _speechCapabilities;
    var probing = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> refreshProbe() async {
              setDialogState(() => probing = true);
              final fresh =
                  await SpeechEngine.instance.probeCapabilities(forceRefresh: true);
              if (mounted) {
                setState(() => _speechCapabilities = fresh);
              }
              if (dialogContext.mounted) {
                setDialogState(() {
                  report = fresh;
                  probing = false;
                });
              }
            }

            if (report == null && !probing) {
              unawaited(refreshProbe());
            }

            const languages = [
              ('en', 'English', 'en-US'),
              ('si', 'Sinhala (සිංහල)', 'si-LK'),
              ('ta', 'Tamil (தமிழ்)', 'ta-IN'),
            ];

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              title: const StyledDialogHeader(
                icon: Icons.record_voice_over_rounded,
                title: 'Offline Speech',
                subtitle: 'Automatic multilingual speech engine',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (report?.defaultEngine != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Engine: ${report!.defaultEngine}',
                          style: Theme.of(dialogContext).textTheme.bodySmall,
                        ),
                      ),
                    for (final (code, name, locale) in languages)
                      Builder(
                        builder: (_) {
                          final status = report?.languages[code];
                          final offlineReady = status?.hasOfflineVoice ?? false;
                          final available = status?.isLanguageAvailable ?? false;
                          final sub = status == null
                              ? 'Checking device speech engine...'
                              : (offlineReady
                                  ? 'Offline voice ready ($locale)'
                                  : (available
                                      ? 'Voice ready ($locale, uses device fallback)'
                                      : 'Language pack not installed ($locale)'));
                          return DialogOptionTile(
                            icon: offlineReady || available
                                ? Icons.check_circle_rounded
                                : Icons.download_for_offline_outlined,
                            title: name,
                            subtitle: sub,
                            selected: offlineReady || available,
                            onTap: () => unawaited(
                              SpeechEngine.instance.speak(
                                switch (code) {
                                  'si' => 'ආයුබෝවන්! මට water ඕනේ.',
                                  'ta' => 'வணக்கம்! எனக்கு water வேண்டும்.',
                                  _ => 'Hello! Ready to speak.',
                                },
                                preferredLanguage: code,
                              ),
                            ),
                          );
                        },
                      ),
                    if (probing)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
              actions: [
                if ((report?.missingLanguages ?? const []).isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      unawaited(SpeechEngine.instance.openSystemTtsInstaller());
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Install Voices'),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    final sample = switch (currentLanguage) {
                      'si' => 'ආයුබෝවන්, මට water ඕනේ.',
                      'ta' => 'வணக்கம், எனக்கு water வேண்டும்.',
                      _ => 'Hello, I am ready to speak.',
                    };
                    unawaited(_speak(sample));
                  },
                  icon: const Icon(Icons.volume_up_rounded, size: 18),
                  label: const Text('Test'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCategoryDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: const StyledDialogHeader(
          icon: Icons.category_rounded,
          title: 'Select Category',
          subtitle: 'Filter cards shown on board',
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (MediaQuery.of(context).size.height * 0.55).clamp(180.0, 460.0),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: allCategories
                  .map(
                    (cat) => DialogOptionTile(
                      icon: cat == 'All'
                          ? Icons.apps_rounded
                          : Icons.folder_outlined,
                      title: cat,
                      selected: selectedCategory == cat,
                      onTap: () {
                        setState(() {
                          selectedCategory = cat;
                          activeParentCard = null;
                          _resetTtsInput();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    Navigator.pop(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: const StyledDialogHeader(
          icon: Icons.create_new_folder_rounded,
          title: 'Add New Category',
          subtitle: 'Group related AAC cards together',
        ),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g., Food, School, Emotions',
              prefixIcon: const Icon(Icons.label_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
            onPressed: () {
              final clean = controller.text.trim();
              if (clean.isNotEmpty) {
                setState(() {
                  allCategories.add(clean);
                });
                _saveCards();
                Navigator.pop(context);
                _showMessage('Category "$clean" added!');
              }
            },
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _showGridOptions() {
    Navigator.pop(context);
    final labels = ['Extra Large', 'Large', 'Medium', 'Small', 'Extra Small'];
    int tempColumns = gridColumns.clamp(1, 5);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            title: const StyledDialogHeader(
              icon: Icons.grid_view_rounded,
              title: 'Select Grid Size',
              subtitle: 'Choose card size & column density',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$tempColumns ${tempColumns == 1 ? 'Column' : 'Columns'} • ${labels[tempColumns - 1]}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Slider(
                    value: (6 - tempColumns).toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: labels[tempColumns - 1],
                    onChanged: (value) {
                      setLocalState(() => tempColumns = 6 - value.round());
                    },
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(
                    labels.length,
                    (index) {
                      final cols = index + 1;
                      return DialogOptionTile(
                        icon: Icons.view_module_rounded,
                        badgeText: '${cols}x',
                        title: labels[index],
                        subtitle: '$cols ${cols == 1 ? 'card' : 'cards'} per row',
                        selected: tempColumns == cols,
                        onTap: () => setLocalState(() => tempColumns = cols),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() => gridColumns = tempColumns);
                  _saveCards();
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmResetSettings() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: StyledDialogHeader(
          icon: Icons.restart_alt_rounded,
          title: 'Reset Settings',
          subtitle: 'Restore default look & layout',
          accentColor: Colors.orange.shade700,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Resets grid size, colors, language & layout to defaults.',
                      style: TextStyle(fontSize: 12.5, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Your AAC cards, photos & voice recordings stay safe.',
                      style: TextStyle(fontSize: 12.5, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Reset'),
            onPressed: () {
              debugPrint(
                '[HomePage] resetting settings only; card data is preserved',
              );
              _resetSettingsToDefaults();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _resetSettingsToDefaults() {
    setState(() {
      gridColumns = 2;
      showTtsInput = true;
      orientationMode = 'portrait';
      fullScreen = true;
      currentLanguage = 'en';
      _themePrimaryColor = _defaultPrimaryColorValue;
      _themeTextColor = Colors.white.value;
      _themeBackgroundColor = Colors.white.value;
      _ttsBarSize = 1.0;
      _showTtsActions = true;
      _hideTtsText = false;
      _useImageOverlayLabel = true;
      _applyTextColorToCards = false;
      _isDarkMode = false;
      _isColorBlindMode = false;
      ThemeAccessibility.darkModeNotifier.value = false;
      selectedCategory = 'All';
      visibleCardIdsByParent.clear();
      _resetTtsInput();
    });
    UiModeHelper.applyOrientation(orientationMode);
    UiModeHelper.applySystemUi(fullScreen);
    _saveCards();
  }

  void _showVisibleCountDialog() {
    Navigator.pop(context);
    final total = _getBaseDisplayedCards().length;
    if (total == 0) return;
    final allCards = _getBaseDisplayedCards();
    showDialog(
      context: context,
      builder: (context) => VisibleCardsDialog(
        cards: allCards,
        currentLanguage: currentLanguage,
        initialSelectedIds: _getVisibleSelection().toSet(),
        onSubmit: (selectedIds) {
          setState(() {
            visibleCardIdsByParent[_visibleSelectionKey()] = selectedIds;
          });
          _saveCards();
        },
      ),
    );
  }

  void _showSearchDialog() {
    final controller = TextEditingController(text: searchQuery);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        final colorScheme = Theme.of(context).colorScheme;
        return AnimatedPadding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: viewInsets.bottom + 24,
            top: 16,
          ),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Material(
            borderRadius: BorderRadius.circular(24),
            color: colorScheme.surface,
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const StyledDialogHeader(
                      icon: Icons.search_rounded,
                      title: 'Search Cards',
                      subtitle: 'Find a word across the current board',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Search cards',
                        hintText: 'Type keyword...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              searchQuery = '';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final pattern = controller.text.trim();
                            if (pattern.isEmpty) {
                              setState(() {
                                searchQuery = '';
                              });
                              Navigator.pop(context);
                              return;
                            }
                            try {
                              RegExp(pattern);
                              setState(() {
                                searchQuery = pattern;
                              });
                              Navigator.pop(context);
                            } catch (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Invalid regex pattern')),
                              );
                            }
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  Map<String, dynamic> _buildBackupSettings() {
    return {
      'gridColumns': gridColumns,
      'visibleCardIdsByParent': visibleCardIdsByParent.map(
        (key, value) => MapEntry(key, value.toList()),
      ),
      'showTtsInput': showTtsInput,
      'orientationMode': orientationMode,
      'fullScreen': fullScreen,
      'language': currentLanguage,
      'themePrimaryColor': _themePrimaryColor,
      'themeTextColor': _themeTextColor,
      'themeBackgroundColor': _themeBackgroundColor,
      'ttsBarSize': _ttsBarSize,
      'showTtsActions': _showTtsActions,
      'hideTtsText': _hideTtsText,
      'useImageOverlayLabel': _useImageOverlayLabel,
      'applyTextColorToCards': _applyTextColorToCards,
      'darkMode': _isDarkMode,
      'colorBlindMode': _isColorBlindMode,
      'selectedCategory': selectedCategory,
    };
  }

  List<AACCard> _getFilteredCards() {
    if (selectedCategory == 'All') {
      return cards;
    }
    return cards.where((card) => card.category == selectedCategory).toList();
  }

  List<AACCard> _getBaseDisplayedCards() {
    if (activeParentCard != null) {
      return activeParentCard!.subCards;
    }
    return _getFilteredCards();
  }

  List<AACCard> _getDisplayedCards() {
    final base = _getBaseDisplayedCards();
    final visibleIds = _getVisibleSelection();
    if (visibleIds.isEmpty) {
      return _filterBySearch(base);
    }
    return _filterBySearch(
        base.where((card) => visibleIds.contains(card.id)).toList());
  }

  List<AACCard> _filterBySearch(List<AACCard> cardsList) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return cardsList;
    try {
      final regex = RegExp(searchQuery, caseSensitive: false);
      return cardsList
          .where((card) => regex.hasMatch(card.getLabel(currentLanguage)))
          .toList();
    } catch (_) {
      return cardsList;
    }
  }

  String _visibleSelectionKey() {
    return activeParentCard?.id ?? '__root__';
  }

  Set<String> _getVisibleSelection() {
    return visibleCardIdsByParent[_visibleSelectionKey()] ?? {};
  }

  String _getVisibleCardsLabel() {
    final selected = _getVisibleSelection();
    if (selected.isEmpty) {
      return 'All cards';
    }
    return '${selected.length} selected';
  }

  void _includeInVisibleSelection(String parentKey, String cardId) {
    final current = visibleCardIdsByParent[parentKey];
    if (current == null || current.isEmpty) return;
    current.add(cardId);
  }

  void _toggleEditMode() {
    Navigator.pop(context);
    if (isEditMode) {
      _exitEditMode();
    } else {
      _enterEditMode();
    }
  }

  void _enterEditMode() {
    if (isEditMode) return;
    setState(() {
      isEditMode = true;
      _editSnapshotCards = _cloneCards(cards);
      _editSnapshotVisible = _cloneVisibleMap(visibleCardIdsByParent);
      _editSnapshotCategories = Set<String>.from(allCategories);
      _editSnapshotSelectedCategory = selectedCategory;
      _editSnapshotActiveParentId = activeParentCard?.id;
    });
  }

  void _exitEditMode() {
    setState(() {
      isEditMode = false;
      _clearEditSnapshot();
    });
    _saveCards();
  }

  void _clearEditSnapshot() {
    _editSnapshotCards = null;
    _editSnapshotVisible = null;
    _editSnapshotCategories = null;
    _editSnapshotSelectedCategory = null;
    _editSnapshotActiveParentId = null;
  }

  void _undoEditChanges() {
    if (_editSnapshotCards == null) return;
    debugPrint('[HomePage] undoing edit-mode changes from snapshot');
    setState(() {
      cards = _cloneCards(_editSnapshotCards!);
      visibleCardIdsByParent = _cloneVisibleMap(_editSnapshotVisible ?? {});
      allCategories = Set<String>.from(_editSnapshotCategories ?? {'All'});
      selectedCategory = _editSnapshotSelectedCategory ?? 'All';
      activeParentCard = _editSnapshotActiveParentId == null
          ? null
          : _findCardById(_editSnapshotActiveParentId!);
    });
    _saveCards();
  }

  List<AACCard> _cloneCards(List<AACCard> source) {
    return source.map((card) => AACCard.fromJson(card.toJson())).toList();
  }

  Map<String, Set<String>> _cloneVisibleMap(Map<String, Set<String>> source) {
    return source.map(
      (key, value) => MapEntry(key, Set<String>.from(value)),
    );
  }

  AACCard? _findCardById(String id, [List<AACCard>? list]) {
    final cardsList = list ?? cards;
    for (final card in cardsList) {
      if (card.id == id) return card;
      final found = _findCardById(id, card.subCards);
      if (found != null) return found;
    }
    return null;
  }

  void _showOrientationDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) {
        void selectOrientation(String mode) {
          setState(() => orientationMode = mode);
          _saveCards();
          UiModeHelper.applyOrientation(orientationMode);
          Navigator.pop(context);
        }

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          title: const StyledDialogHeader(
            icon: Icons.screen_rotation_rounded,
            title: 'Screen Orientation',
            subtitle: 'Choose preferred layout direction',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DialogOptionTile(
                  icon: Icons.stay_current_portrait_rounded,
                  title: 'Portrait',
                  subtitle: 'Tall card grid with top toolbar',
                  selected: orientationMode != 'landscape',
                  onTap: () => selectOrientation('portrait'),
                ),
                DialogOptionTile(
                  icon: Icons.stay_current_landscape_rounded,
                  title: 'Landscape',
                  subtitle: 'Wide card grid with side rail',
                  selected: orientationMode == 'landscape',
                  onTap: () => selectOrientation('landscape'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showThemeColorDialog({
    required String title,
    String? subtitle,
    required Color initialColor,
    ColorPickerPreviewType previewType = ColorPickerPreviewType.appHeader,
    required ValueChanged<Color> onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) => ProfessionalColorPickerDialog(
        title: title,
        subtitle: subtitle ?? 'Pick a color for Normal Mode',
        initialColor: initialColor,
        previewType: previewType,
        onApply: onSelected,
      ),
    );
  }

  void _showTtsBarSizeDialog() {
    Navigator.pop(context);
    double tempSize = _ttsBarSize;
    bool tempShowActions = _showTtsActions;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            title: const StyledDialogHeader(
              icon: Icons.format_size_rounded,
              title: 'TTS Bar Sizing',
              subtitle: 'Adjust speech composer bar height',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Size: ${(tempSize * 100).round()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Slider(
                    value: tempSize,
                    min: 0.5,
                    max: 2.5,
                    divisions: 20,
                    label: '${(tempSize * 100).round()}%',
                    onChanged: (value) {
                      setLocalState(() => tempSize = value);
                    },
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: SwitchListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      secondary: const Icon(Icons.backspace_outlined, size: 20),
                      title: const Text(
                        'Show Delete / Clear',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      value: tempShowActions,
                      onChanged: (value) {
                        setLocalState(() => tempShowActions = value);
                      },
                    ),
                  ),
                ],
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
                    _ttsBarSize = 1.0;
                    _showTtsActions = true;
                  });
                  _saveCards();
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _ttsBarSize = tempSize;
                    _showTtsActions = tempShowActions;
                  });
                  _saveCards();
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _backupWithPicker() async {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: const StyledDialogHeader(
          icon: Icons.backup_rounded,
          title: 'Export Backup',
          subtitle: 'Save cards, photos & voices cleanly',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogOptionTile(
                icon: Icons.folder_rounded,
                title: 'App Folder',
                subtitle: 'Save locally inside app storage',
                onTap: () async {
                  Navigator.pop(context);
                  await _backupToAppDocsZip();
                },
              ),
              DialogOptionTile(
                icon: Icons.download_rounded,
                title: 'Downloads',
                subtitle: 'Save aac_backup.zip to Downloads',
                onTap: () async {
                  Navigator.pop(context);
                  await _backupToDownloads();
                },
              ),
              DialogOptionTile(
                icon: Icons.share_rounded,
                title: 'Share Backup',
                subtitle: 'Send zip via messaging or Drive',
                onTap: () async {
                  Navigator.pop(context);
                  await _backupAndShare();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreWithPicker() async {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: const StyledDialogHeader(
          icon: Icons.restore_page_rounded,
          title: 'Import Restore',
          subtitle: 'Restore board & media from zip',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogOptionTile(
                icon: Icons.folder_rounded,
                title: 'App Folder',
                subtitle: 'Restore from saved local zip',
                onTap: () async {
                  Navigator.pop(context);
                  await _restoreFromAppDocsZip();
                },
              ),
              DialogOptionTile(
                icon: Icons.file_open_rounded,
                title: 'Pick Backup File',
                subtitle: 'Browse zip file from device',
                onTap: () async {
                  Navigator.pop(context);
                  await _restoreFromPickedFile();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _runAsyncOperation({
    required String title,
    required String subtitle,
    required Future<void> Function() task,
  }) async {
    if (_isBusyOperation || !mounted) return;
    _isBusyOperation = true;
    final rootNav = Navigator.of(context, rootNavigator: true);
    var dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          content: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    try {
      await task();
    } finally {
      if (dialogOpen && rootNav.mounted) {
        rootNav.pop();
        dialogOpen = false;
      }
      _isBusyOperation = false;
    }
  }

  Future<void> _backupAndShare() async {
    String? sharePath;
    await _runAsyncOperation(
      title: 'Preparing Backup...',
      subtitle: 'Packaging cards, GIFs & voice clips',
      task: () async {
        final zipBytes = await BackupService.buildBackupZip(
          cards,
          settings: _buildBackupSettings(),
        );
        if (zipBytes == null) {
          _showMessage('Backup failed to create zip');
          return;
        }
        final docsDir = await getApplicationDocumentsDirectory();
        final path = '${docsDir.path}/aac_backup.zip';
        await File(path).writeAsBytes(zipBytes, flush: true);
        sharePath = path;
      },
    );
    if (sharePath != null && mounted) {
      await Share.shareXFiles(
        [XFile(sharePath!)],
        text: 'AAC App backup',
      );
    }
  }

  Future<void> _backupToDownloads() async {
    if (Platform.isAndroid && mounted) {
      await AppPermissionsHelper.ensureLegacyStorageIfNeeded(context);
      if (!mounted) return;
    }
    await _runAsyncOperation(
      title: 'Saving Backup...',
      subtitle: 'Writing compressed archive in background',
      task: () async {
        final zipBytes = await BackupService.buildBackupZip(
          cards,
          settings: _buildBackupSettings(),
        );
        if (zipBytes == null) {
          _showMessage('Backup failed to create zip');
          return;
        }
        try {
          final savedPath = await BackupService.saveZipToDownloads(zipBytes);
          if (savedPath == null) {
            throw Exception('Downloads save failed');
          }
          _showMessage('Backup saved to $savedPath');
        } catch (_) {
          final fallback = await BackupService.saveZipToAppDocs(zipBytes);
          _showMessage('Cannot save to Downloads. Backup saved to $fallback');
        }
      },
    );
  }

  Future<void> _restoreFromPickedFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true,
      );
      if (result == null || !mounted) return;

      final picked = result.files.single;
      await _runAsyncOperation(
        title: 'Restoring Backup...',
        subtitle: 'Unpacking cards, GIFs & settings safely',
        task: () async {
          var zipBytes = picked.bytes;
          if (zipBytes == null && picked.path != null) {
            zipBytes = await File(picked.path!).readAsBytes();
          }
          if (zipBytes == null) {
            _showMessage('Cannot read selected backup');
            return;
          }
          final payload = await BackupService.restoreFromZipBytes(zipBytes);
          if (!mounted) return;
          if (payload.cards.isEmpty) {
            _showMessage('Backup not found in selected file');
            return;
          }
          _applyRestoredBackup(payload);
          _showMessage('Backup restored successfully!');
        },
      );
    } catch (e) {
      debugPrint('[HomePage] Backup restore failed: $e');
      _showMessage('Invalid or unreadable backup ZIP file');
    }
  }

  void _applyRestoredBackup(BackupPayload payload) {
    final settings = payload.settings;
    final restoredCards = payload.cards;
    debugPrint(
      '[HomePage] applying restored backup: ${restoredCards.length} '
      'top-level cards, ${CardStorageService.countCards(restoredCards)} '
      'total cards',
    );
    setState(() {
      cards = restoredCards;
      activeParentCard = null;
      selectedCategory = settings['selectedCategory']?.toString() ?? 'All';

      final visibleRaw = settings['visibleCardIdsByParent'];
      if (visibleRaw is Map) {
        visibleCardIdsByParent = {
          for (final entry in visibleRaw.entries)
            if (entry.value is List)
              entry.key.toString():
                  (entry.value as List).map((v) => v.toString()).toSet(),
        };
      } else {
        visibleCardIdsByParent.clear();
      }

      gridColumns = (settings['gridColumns'] as num?)?.toInt() ?? gridColumns;
      showTtsInput = settings['showTtsInput'] as bool? ?? showTtsInput;
      orientationMode =
          settings['orientationMode']?.toString() ?? orientationMode;
      fullScreen = settings['fullScreen'] as bool? ?? fullScreen;
      currentLanguage = settings['language']?.toString() ?? currentLanguage;
      _themePrimaryColor = (settings['themePrimaryColor'] as num?)?.toInt() ??
          _themePrimaryColor;
      _themeTextColor =
          (settings['themeTextColor'] as num?)?.toInt() ?? _themeTextColor;
      _themeBackgroundColor =
          (settings['themeBackgroundColor'] as num?)?.toInt() ??
              _themeBackgroundColor;
      _ttsBarSize = (settings['ttsBarSize'] as num?)?.toDouble() ?? _ttsBarSize;
      _showTtsActions = settings['showTtsActions'] as bool? ?? _showTtsActions;
      _hideTtsText = settings['hideTtsText'] as bool? ?? _hideTtsText;
      _useImageOverlayLabel =
          settings['useImageOverlayLabel'] as bool? ?? _useImageOverlayLabel;
      _applyTextColorToCards =
          settings['applyTextColorToCards'] as bool? ?? _applyTextColorToCards;
      _isDarkMode = settings['darkMode'] as bool? ?? _isDarkMode;
      _isColorBlindMode =
          settings['colorBlindMode'] as bool? ?? _isColorBlindMode;
      // Legacy 'ttsVoiceProfile' key in older backups is ignored intentionally.
      ThemeAccessibility.darkModeNotifier.value = _isDarkMode;

      _resetTtsInput();
    });
    unawaited(_initTts());
    _updateCategories();
    if (!allCategories.contains(selectedCategory)) {
      setState(() {
        selectedCategory = 'All';
      });
    }
    UiModeHelper.applyOrientation(orientationMode);
    UiModeHelper.applySystemUi(fullScreen);
    _saveCards();
  }

  Future<void> _backupToAppDocsZip() async {
    await _runAsyncOperation(
      title: 'Saving Backup...',
      subtitle: 'Creating local backup ZIP in background',
      task: () async {
        try {
          final zipBytes = await BackupService.buildBackupZip(
            cards,
            settings: _buildBackupSettings(),
          );
          if (!mounted) return;
          if (zipBytes == null) {
            _showMessage('Backup failed to create zip');
            return;
          }
          final path = await BackupService.saveZipToAppDocs(zipBytes);
          _showMessage('Backup saved to $path');
        } catch (e) {
          debugPrint('[HomePage] AppDocs backup failed: $e');
          _showMessage('Backup could not be saved');
        }
      },
    );
  }

  Future<void> _restoreFromAppDocsZip() async {
    await _runAsyncOperation(
      title: 'Restoring Backup...',
      subtitle: 'Restoring local backup ZIP safely',
      task: () async {
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          final zipFile = File('${docsDir.path}/aac_backup.zip');
          if (!await zipFile.exists()) {
            _showMessage('No backup found in app folder');
            return;
          }
          final payload = await BackupService.restoreFromZipBytes(
            await zipFile.readAsBytes(),
          );
          if (!mounted) return;
          if (payload.cards.isEmpty) {
            _showMessage('Backup not found in app folder file');
            return;
          }
          _applyRestoredBackup(payload);
          _showMessage('Backup restored successfully!');
        } catch (e) {
          debugPrint('[HomePage] AppDocs restore failed: $e');
          _showMessage('Backup file could not be restored');
        }
      },
    );
  }

  void _showAbout() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          title: const StyledDialogHeader(
            icon: Icons.forum_rounded,
            title: 'About Simple AAC',
            subtitle: 'Simple AAC Sri Lanka • v1.1.0',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Created to support Sri Lankan children with speech and communication difficulties using an accessible, offline-ready communication board.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_rounded, color: colorScheme.primary),
                  title: const Text('Yasas Pasindu Fernando'),
                  subtitle: const Text('Creator & Developer'),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.email_rounded, color: colorScheme.primary),
                  title: const Text('yasaspasindufernando@gmail.com'),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.phone_rounded, color: colorScheme.primary),
                  title: const Text('+94 77 690 5654'),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final customPrimary = Color(_themePrimaryColor);
    final customText = Color(_themeTextColor);
    final customBackground = Color(_themeBackgroundColor);
    final themePrimary = _isDarkMode ? const Color(0xFF1B263B) : customPrimary;
    final themeText = _isDarkMode ? const Color(0xFFF1F5F9) : customText;
    final themeBackground =
        _isDarkMode ? const Color(0xFF111418) : customBackground;

    return WillPopScope(
      onWillPop: () async {
        if (isPinned) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Screen is locked')),
          );
          return false;
        }
        if (activeParentCard != null) {
          setState(() {
            _resetTtsInput();
            activeParentCard = null;
          });
          return false;
        }
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Press back again to exit')),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: themeBackground,
        appBar: isLandscape
            ? null
            : HomeAppBar(
                title: activeParentCard == null
                    ? 'Simple AAC'
                    : activeParentCard!.getLabel(currentLanguage),
                backgroundColor: themePrimary,
                showBack: activeParentCard != null && !isPinned,
                onBack: () {
                  setState(() {
                    _resetTtsInput();
                    activeParentCard = null;
                  });
                },
                showPin: true,
                isPinned: isPinned,
                onTogglePin: () {
                  setState(() {
                    isPinned = !isPinned;
                    if (isPinned) {
                      fullScreen = true;
                    }
                  });
                  UiModeHelper.applySystemUi(fullScreen);
                },
                isEditMode: isEditMode,
                showMenu: !isPinned,
                onOpenMenu: () => _scaffoldKey.currentState?.openEndDrawer(),
                titleTextColor: themeText,
              ),
        endDrawer: isPinned
            ? null
            : HomeDrawer(
                selectedCategory: selectedCategory,
                currentLanguageLabel: _getLanguageName(currentLanguage),
                speechStatusLabel: _speechDrawerSubtitle(),
                gridColumns: gridColumns,
                visibleCardsLabel: _getVisibleCardsLabel(),
                isEditMode: isEditMode,
                showTtsInput: showTtsInput,
                orientationLabel:
                    orientationMode == 'landscape' ? 'Landscape' : 'Portrait',
                fullScreen: fullScreen,
                headerColor: themePrimary,
                headerTextColor: themeText,
                hideTtsText: _hideTtsText,
                useImageOverlayLabel: _useImageOverlayLabel,
                applyTextColorToCards: _applyTextColorToCards,
                isDarkMode: _isDarkMode,
                isColorBlindMode: _isColorBlindMode,
                primaryColorSwatch: customPrimary,
                textColorSwatch: customText,
                backgroundColorSwatch: customBackground,
                isOnlineEnabled: NetworkPolicyService.instance.isOnlineEnabled,
                onToggleOnline: (enabled) async {
                  await NetworkPolicyService.instance.setOnlineEnabled(enabled);
                  if (mounted) setState(() {});
                },
                onToggleDarkMode: (enabled) async {
                  setState(() {
                    _isDarkMode = enabled;
                  });
                  await ThemeAccessibility.setDarkMode(enabled);
                  await _saveCards();
                },
                onChangeColorBlindMode: (enabled) {
                  setState(() {
                    _isColorBlindMode = enabled;
                  });
                  _saveCards();
                },
                onSelectCategory: _showCategoryDialog,
                onAddCategory: _showAddCategoryDialog,
                onToggleEdit: _toggleEditMode,
                onToggleTtsInput: () {
                  Navigator.pop(context);
                  setState(() {
                    showTtsInput = !showTtsInput;
                  });
                  _saveCards();
                },
                onToggleTtsText: () {
                  Navigator.pop(context);
                  setState(() {
                    _hideTtsText = !_hideTtsText;
                  });
                  _saveCards();
                },
                onToggleCardImageLabel: () {
                  Navigator.pop(context);
                  setState(() {
                    _useImageOverlayLabel = !_useImageOverlayLabel;
                  });
                  _saveCards();
                },
                onToggleApplyTextColorToCards: () {
                  Navigator.pop(context);
                  setState(() {
                    _applyTextColorToCards = !_applyTextColorToCards;
                  });
                  _saveCards();
                },
                onChangeOrientation: _showOrientationDialog,
                onPickPrimaryColor: () {
                  Navigator.pop(context);
                  _showThemeColorDialog(
                    title: 'App color',
                    subtitle: 'Pick a color for Normal Mode',
                    initialColor: customPrimary,
                    previewType: ColorPickerPreviewType.appHeader,
                    onSelected: (color) {
                      setState(() {
                        _themePrimaryColor = color.value;
                      });
                      _saveCards();
                    },
                  );
                },
                onPickTextColor: () {
                  Navigator.pop(context);
                  _showThemeColorDialog(
                    title: 'Text color',
                    subtitle: 'Pick a color for Normal Mode text',
                    initialColor: customText,
                    previewType: ColorPickerPreviewType.textColor,
                    onSelected: (color) {
                      setState(() {
                        _themeTextColor = color.value;
                      });
                      _saveCards();
                    },
                  );
                },
                onPickBackgroundColor: () {
                  Navigator.pop(context);
                  _showThemeColorDialog(
                    title: 'Background color',
                    subtitle: 'Pick a color for board background',
                    initialColor: customBackground,
                    previewType: ColorPickerPreviewType.backgroundColor,
                    onSelected: (color) {
                      setState(() {
                        _themeBackgroundColor = color.value;
                      });
                      _saveCards();
                    },
                  );
                },
                onShowTtsBarSize: _showTtsBarSizeDialog,
                onToggleFullScreen: () {
                  Navigator.pop(context);
                  setState(() {
                    fullScreen = !fullScreen;
                  });
                  _saveCards();
                  UiModeHelper.applySystemUi(fullScreen);
                },
                onShowLanguage: _showLanguageDialog,
                onShowOfflineSpeech: _showOfflineSpeechDialog,
                onShowGrid: _showGridOptions,
                onShowVisibleCount: _showVisibleCountDialog,
                onBackup: _backupWithPicker,
                onRestore: _restoreWithPicker,
                onResetSettings: _confirmResetSettings,
                onManagePermissions: () async {
                  Navigator.pop(context);
                  await AppPermissionsHelper.requestAllAndShowStatus(context);
                },
                onShowAbout: _showAbout,
              ),
        body: SafeArea(
          child: isLandscape
              ? Row(
                  children: [
                    Expanded(
                      child: Container(
                        color: themeBackground,
                        child: _buildMainContent(
                          isTablet,
                          themePrimary,
                          themeText,
                        ),
                      ),
                    ),
                    LandscapeMenu(
                      isPinned: isPinned,
                      canGoBack: activeParentCard != null,
                      baseColor: themePrimary,
                      textColor: themeText,
                      onTogglePin: () {
                        setState(() {
                          isPinned = !isPinned;
                          if (isPinned) {
                            fullScreen = true;
                          }
                        });
                        UiModeHelper.applySystemUi(fullScreen);
                      },
                      onOpenMenu: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      onGoBack: () {
                        setState(() {
                          _resetTtsInput();
                          activeParentCard = null;
                        });
                      },
                      onHome: () {
                        setState(() {
                          selectedCategory = 'All';
                          activeParentCard = null;
                          searchQuery = '';
                          _resetTtsInput();
                        });
                      },
                      onUp: () {
                        if (!_gridController.hasClients) return;
                        final next = _gridController.offset - 300;
                        _gridController.animateTo(
                          next < 0 ? 0 : next,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      },
                      onDown: () {
                        if (!_gridController.hasClients) return;
                        final max = _gridController.position.maxScrollExtent;
                        final next = _gridController.offset + 300;
                        _gridController.animateTo(
                          next > max ? max : next,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      },
                      onSearch: _showSearchDialog,
                    ),
                  ],
                )
              : Container(
                  color: themeBackground,
                  child: _buildMainContent(isTablet, themePrimary, themeText),
                ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
    bool isTablet,
    Color themePrimary,
    Color themeText,
  ) {
    final displayedCards = _getDisplayedCards();
    final colorScheme = Theme.of(context).colorScheme;
    final viewKey = ValueKey(
      '${activeParentCard?.id ?? 'root'}_${selectedCategory}_${displayedCards.isEmpty ? 'empty' : 'grid'}',
    );

    Widget topBanner = const SizedBox.shrink(key: ValueKey('no_banner'));
    if (isEditMode) {
      topBanner = EditModeBar(
        key: const ValueKey('edit_mode_bar'),
        onDone: _exitEditMode,
        onUndo: _undoEditChanges,
        baseColor: themePrimary,
        textColor: themeText,
        onAdd: () {
          if (!isPinned) {
            _createCard(parent: activeParentCard);
          }
        },
      );
    } else if (showTtsInput) {
      topBanner = TtsBar(
        key: const ValueKey('tts_bar'),
        tokens: _ttsTokens,
        isTablet: isTablet,
        onDelete: _deleteLastWord,
        onClear: _clearTtsInput,
        onSpeak: () async {
          if (_ttsTokens.isNotEmpty) {
            await _playTtsTokens();
          }
        },
        speakerColor: _isDarkMode
            ? Theme.of(context).colorScheme.primary
            : themePrimary,
        sizeFactor: _ttsBarSize,
        showActions: _showTtsActions,
        showText: !_hideTtsText,
      );
    }

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: topBanner,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: displayedCards.isEmpty
                ? Center(
                    key: viewKey,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.style_outlined,
                              size: 30,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No cards in this category',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + in Edit Mode to add a photo or GIF card.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    key: viewKey,
                    controller: _gridController,
                    cacheExtent: 360,
                    padding: EdgeInsets.all(isTablet ? 20 : 12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet
                          ? (gridColumns == 1 ? 2 : gridColumns + 1)
                          : gridColumns,
                      crossAxisSpacing: isTablet ? 16 : 12,
                      mainAxisSpacing: isTablet ? 16 : 12,
                      childAspectRatio: isTablet ? 1.1 : 1.0,
                    ),
                    itemCount: displayedCards.length,
                    itemBuilder: (context, i) {
                      final card = displayedCards[i];
                      return RepaintBoundary(
                        key: ValueKey(card.id),
                        child: _buildCardWidget(card, isTablet),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardWidget(AACCard card, bool isTablet) {
    final displayLabel = card.getLabel(currentLanguage);
    final isTapAnimated = _tapAnimatedCardId == card.id;
    final useImageOverlay = _useImageOverlayLabel && card.imagePath != null;
    final cardSurfaceColor = ThemeAccessibility.resolveCardSurface(
      Color(card.colorValue),
      isDarkMode: _isDarkMode,
      isColorBlindMode: _isColorBlindMode,
    );
    final cardTextColor = useImageOverlay
        ? (_applyTextColorToCards ? Color(_themeTextColor) : Colors.white)
        : ThemeAccessibility.resolveCardTextColor(
            cardSurfaceColor,
            isDarkMode: _isDarkMode,
            isColorBlindMode: _isColorBlindMode,
            applyCustomTextColor: _applyTextColorToCards,
            customTextColor: Color(_themeTextColor),
          );
    final useLightShadow = cardTextColor.computeLuminance() > 0.5;
    final cardBorder = highlightedCardId == card.id
        ? Border.all(
            color: _isColorBlindMode
                ? const Color(0xFF0072B2)
                : Colors.yellow.shade200,
            width: 3,
          )
        : _isColorBlindMode
            ? Border.all(
                color: _isDarkMode ? Colors.white54 : Colors.black87,
                width: 2,
              )
            : _isDarkMode
                ? Border.all(color: Colors.white24, width: 1)
                : null;

    return GestureDetector(
      onTap: () {
        if (isEditMode) {
          _editCard(card);
          return;
        }
        if (card.type == 'folder') {
          _showSubCards(card);
          unawaited(_speakOrPlayCard(card, displayLabel));
          return;
        }

        _triggerWordTapAnimation(card.id);
        _appendToTtsInput(
          displayLabel,
          imagePath: card.imagePath,
          voicePath: card.voicePath,
        );
        unawaited(_speakOrPlayCard(card, displayLabel));
      },
      child: AnimatedScale(
        scale: isTapAnimated ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: cardSurfaceColor,
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            border: cardBorder,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (!useImageOverlay)
                Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: card.imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(isTablet ? 20 : 16)),
                              child: buildCardImage(
                                card.imagePath!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.broken_image,
                                        size: 60, color: Colors.white70),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Icon(Icons.image,
                                  size: isTablet ? 80 : 60,
                                  color: Colors.white70),
                            ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        child: Text(
                          displayLabel,
                          style: TextStyle(
                            color: cardTextColor,
                            fontSize: isTablet ? 20 : 16,
                            fontWeight: FontWeight.bold,
                            shadows: useLightShadow
                                ? const [
                                    Shadow(
                                      blurRadius: 3,
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              if (useImageOverlay)
                ClipRRect(
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  child: buildCardImage(
                    card.imagePath!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image,
                            size: 60, color: Colors.white70),
                      );
                    },
                  ),
                ),
              if (useImageOverlay)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Text(
                    displayLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cardTextColor,
                      fontSize: isTablet ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.black54,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              if (card.voicePath != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 16),
                  ),
                ),
              if (card.type == 'folder')
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 16),
                  ),
                ),
              if (isEditMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(card),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _tapAnimTimer?.cancel();
    unawaited(SpeechEngine.instance.stop());
    _audioPlayer.dispose();
    _gridController.dispose();
    super.dispose();
  }
}
