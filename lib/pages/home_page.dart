import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../data/default_seed_cards.dart';
import '../models/aac_card_model.dart';
import '../models/tts_token.dart';
import '../models/tutorial_step.dart';
import '../services/backup_service.dart';
import '../services/card_storage_service.dart';
import '../services/caregiver_lock_service.dart';
import '../services/multilingual_concept_service.dart';
import '../services/network_policy_service.dart';
import '../services/speech_engine.dart';
import '../services/tutorial_service.dart';
import '../models/category_metadata.dart';
import '../models/edit_session_snapshot.dart';
import '../services/recycle_bin_service.dart';
import '../services/personalize_service.dart';
import '../services/starter_pack_service.dart';
import 'recycle_bin_page.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/card_editor_dialog.dart';
import '../widgets/crop_zoom_dialog.dart';
import '../widgets/personalize_setup_dialog.dart';
import '../widgets/manage_sub_cards_dialog.dart';
import '../widgets/select_category_dialog.dart';
import '../widgets/select_grid_size_dialog.dart';
import '../widgets/color_vision_dialog.dart';
import '../widgets/professional_color_picker_dialog.dart';

import '../widgets/child_friendly_splash.dart';
import '../widgets/edit_mode_bar.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_drawer.dart';
import '../widgets/landscape_menu.dart';
import '../widgets/styled_dialog_header.dart';
import '../widgets/tts_bar.dart';
import '../widgets/visible_cards_dialog.dart';
import '../widgets/preview/live_preview_panel.dart';
import '../widgets/preview/tts_composer_preview.dart';
import '../widgets/tutorial/mini_guides_dialog.dart';
import '../widgets/tutorial/tutorial_overlay.dart';
import '../widgets/tutorial/welcome_tour_dialog.dart';
import '../utils/animated_media_helper.dart';
import '../utils/app_permissions_helper.dart';
import '../utils/camera_object_helper.dart';
import '../utils/card_image.dart';
import '../utils/category_helper.dart';
import '../utils/theme_accessibility.dart';
import '../utils/ui_mode_helper.dart';

class HomePage extends StatefulWidget {
  /// Strong tactile haptic feedback: Combines heavyImpact (crisp click for linear actuators)
  /// and vibrate (full physical pulse providing spin-up momentum for ERM/traditional motors).
  static Future<void> defaultHapticPerformer() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  @visibleForTesting
  static Future<void> Function() hapticPerformer = defaultHapticPerformer;
  @visibleForTesting
  static Future<void> Function(String text)? speakPerformer;
  @visibleForTesting
  static bool enableTtsInit = true;
  static bool enableTutorialInit = false;
  static bool enablePersonalizeInit = false;
  @visibleForTesting
  static bool skipSplashForTesting = false;
  @visibleForTesting
  static bool forceSplashForTesting = false;
  @visibleForTesting
  static Duration? injectedStartupDelayForTesting;
  @visibleForTesting
  static bool? forceStartupErrorForTesting;
  @visibleForTesting
  static List<AACCard>? initialCardsForTesting;

  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

enum CardDropHoverState {
  none,
  reorderBefore,
  reorderAfter,
  moveInside,
}

class DraggedCardData {
  final AACCard card;
  final int sourceIndex;

  const DraggedCardData({
    required this.card,
    required this.sourceIndex,
  });
}

class EditUndoStep {
  final List<AACCard> cards;
  final Map<String, Set<String>> visibleMap;
  final String? activeParentId;
  final List<String> parentStackIds;
  final String description;
  final String? recycleBinEntryId;

  EditUndoStep({
    required this.cards,
    required this.visibleMap,
    required this.activeParentId,
    required this.parentStackIds,
    required this.description,
    this.recycleBinEntryId,
  });
}

class _HomePageState extends State<HomePage> {
  Future<void>? _loadCardsFuture;
  @visibleForTesting
  Future<void>? get loadCardsFutureForTesting => _loadCardsFuture;

  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _gridController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  bool _hasHorizontalOverflow = false;
  bool _canScrollHorizontallyLeft = false;
  bool _canScrollHorizontallyRight = false;
  bool _isInitialLoading = true;
  bool _splashDismissed = false;
  bool _showStartupLoader = false;
  bool _hasStartupError = false;
  String? _startupErrorMessage;
  Timer? _startupLoadingTimer;

  List<AACCard> cards = [];
  int gridColumns = 2;
  Map<String, Set<String>> visibleCardIdsByParent = {};
  String currentLanguage = 'en';
  bool showTtsInput = true;
  Set<String> selectedCategories = {'All'};
  String get selectedCategory {
    if (selectedCategories.contains('All') || selectedCategories.isEmpty) {
      return 'All';
    }
    if (selectedCategories.length == 1) {
      return selectedCategories.first;
    }
    return '${selectedCategories.length} Categories';
  }
  set selectedCategory(String val) {
    if (val == 'All' || val.isEmpty) {
      selectedCategories = {'All'};
    } else {
      selectedCategories = {val};
    }
  }
  Set<String> allCategories = {'General'};
  Set<String> _customCategories = {};
  Map<String, CategoryMetadata> _customCategoryMetadata = {};
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
  EditSessionSnapshot? _editSessionSnapshot;
  final Set<String> _sessionCreatedMediaFiles = <String>{};
  final Set<String> _sessionRecycleBinEntryIds = <String>{};
  final List<EditUndoStep> _undoHistory = [];
  final List<AACCard> _parentStack = [];
  final GlobalKey _gridAreaKey = GlobalKey();
  Timer? _autoScrollTimer;
  double _autoScrollVelocityY = 0.0;
  double _autoScrollVelocityX = 0.0;
  static const int _defaultPrimaryColorValue = 0xFF0277BD;
  int _themePrimaryColor = _defaultPrimaryColorValue;
  int _themeTextColor = Colors.white.value;
  int _themeBackgroundColor = Colors.white.value;
  int _cardTextColor = const Color(0xFF111827).value;
  double _ttsBarSize = 1.0;
  double _cardTextScale = 1.0;
  bool _isDrawerExpanded = false;
  bool _showTtsDelete = true;
  bool _showTtsClear = true;
  bool _hideTtsText = false;
  bool _useImageOverlayLabel = true;
  bool _applyTextColorToCards = false;
  bool _enableHaptics = true;
  bool _disableBackCardInPinMode = false;
  bool _isDarkMode = ThemeAccessibility.darkModeNotifier.value;
  bool _isColorBlindMode = false;
  SpeechCapabilityReport? _speechCapabilities;
  bool _isBusyOperation = false;

  @visibleForTesting
  bool get useImageOverlayLabelForTesting => _useImageOverlayLabel;

  @visibleForTesting
  set useImageOverlayLabelForTesting(bool value) =>
      _useImageOverlayLabel = value;

  @visibleForTesting
  bool get enableHapticsForTesting => _enableHaptics;

  @visibleForTesting
  set enableHapticsForTesting(bool value) => _enableHaptics = value;

  @visibleForTesting
  bool get disableBackCardInPinModeForTesting => _disableBackCardInPinMode;

  @visibleForTesting
  set disableBackCardInPinModeForTesting(bool value) =>
      _disableBackCardInPinMode = value;

  @visibleForTesting
  void resetSettingsForTesting() => _resetSettingsToDefaults();

  final GlobalKey _menuButtonKey = GlobalKey();
  final GlobalKey _drawerResizeKey = GlobalKey();
  final GlobalKey _drawerEditModeKey = GlobalKey();
  final GlobalKey _addNewCardKey = GlobalKey();
  final Map<String, GlobalKey> _cardKeys = {};

  @override
  void initState() {
    super.initState();
    _horizontalScrollController.addListener(_handleHorizontalScroll);
    TutorialService.instance.registerKey('app_bar_menu_button', _menuButtonKey);
    TutorialService.instance
        .registerKey('drawer_resize_button', _drawerResizeKey);
    TutorialService.instance
        .registerKey('drawer_edit_mode_toggle', _drawerEditModeKey);
    TutorialService.instance
        .registerKey('edit_mode_add_new_button', _addNewCardKey);
    TutorialService.instance.currentStepNotifier
        .addListener(_handleTutorialStepChanged);

    CaregiverLockService.instance.init();

    TutorialService.instance.onActionRequested = (step) {
      if (!mounted) return;
      if (step == TutorialStepType.openMenu) {
        _scaffoldKey.currentState?.openEndDrawer();
      } else if (step == TutorialStepType.drawerExplore) {
        setState(() => _isDrawerExpanded = !_isDrawerExpanded);
        _saveCards();
      } else if (step == TutorialStepType.enableEditMode) {
        _closeDrawerIfOpen();
        if (!isEditMode) {
          _enterEditMode();
        }
      } else if (step == TutorialStepType.addNewCard) {
        _closeDrawerIfOpen();
        if (!isPinned && !isCardEditorOpen) {
          _createCard(parent: activeParentCard);
        }
      }
    };

    final bool isTestEnv =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final bool shouldSkipSplash = HomePage.skipSplashForTesting ||
        ((isTestEnv || HomePage.initialCardsForTesting != null) &&
            !HomePage.forceSplashForTesting &&
            HomePage.injectedStartupDelayForTesting == null &&
            HomePage.forceStartupErrorForTesting != true);

    if (shouldSkipSplash) {
      cards = List.of(HomePage.initialCardsForTesting ?? []);
      _isInitialLoading = false;
      _splashDismissed = true;
      _showStartupLoader = false;
      _updateCategories();
    } else {
      if (HomePage.forceSplashForTesting) {
        _showStartupLoader = true;
      } else {
        // StartupLoadingView is only displayed if initialization genuinely takes >380ms
        _startupLoadingTimer = Timer(const Duration(milliseconds: 380), () {
          if (mounted && _isInitialLoading) {
            setState(() {
              _showStartupLoader = true;
            });
          }
        });
      }
    }
    _loadCardsFuture = _loadCards();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!HomePage.enableTutorialInit && !HomePage.enablePersonalizeInit) return;
      if (HomePage.initialCardsForTesting != null) return;

      final prefs = await SharedPreferences.getInstance();

      if (HomePage.enablePersonalizeInit &&
          PersonalizeService.shouldShowFirstLaunchSetup(prefs)) {
        if (!mounted) return;
        final result = await PersonalizeSetupDialog.show(
          context,
          initialLanguage: currentLanguage,
          initialAppBarColor: Color(_themePrimaryColor),
          initialBoardColor: Color(_themeBackgroundColor),
          isFirstLaunch: true,
        );

        if (result != null) {
          await PersonalizeService.markCompleted(prefs);
          if (mounted) {
            setState(() {
              currentLanguage = result.language;
              _themePrimaryColor = result.appBarColor.value;
              _themeBackgroundColor = result.boardColor.value;
            });
            await prefs.setString('language', currentLanguage);
            await prefs.setInt('themePrimaryColor', _themePrimaryColor);
            await prefs.setInt('themeBackgroundColor', _themeBackgroundColor);
            await _saveCards();
          }
        } else {
          await PersonalizeService.markCompleted(prefs);
        }
      }

      if (!HomePage.enableTutorialInit) return;
      await TutorialService.instance.init();
      if (mounted && TutorialService.instance.isWelcomeVisibleNotifier.value) {
        unawaited(WelcomeTourDialog.show(context, language: currentLanguage));
      }
    });
  }

  Future<void> _initTts() async {
    if (!HomePage.enableTtsInit) return;
    await SpeechEngine.instance.initialize();
    final report = await SpeechEngine.instance.probeCapabilities();
    if (mounted && report != null) {
      setState(() {
        _speechCapabilities = report;
      });
    }
  }

  Future<void> _loadCards() async {
    try {
      final sw = Stopwatch()..start();
      if (HomePage.injectedStartupDelayForTesting != null) {
        await Future.delayed(HomePage.injectedStartupDelayForTesting!);
      }
      if (HomePage.forceStartupErrorForTesting == true) {
        throw Exception('Injected startup failure for testing');
      }
      final List<dynamic> results;
      if (HomePage.initialCardsForTesting != null) {
        results = [
          await SharedPreferences.getInstance(),
          List<AACCard>.of(HomePage.initialCardsForTesting!),
        ];
      } else {
        results = await Future.wait<dynamic>([
          SharedPreferences.getInstance(),
          CardStorageService.loadCards(
              defaultCardsBuilder: _createSeedImageCards),
        ]);
      }
      if (!mounted) return;

      final prefs = results[0] as SharedPreferences;
      final loadedCards = results[1] as List<AACCard>;

      final nextGridColumns =
          (prefs.getInt('gridColumns') ?? prefs.getInt('grid_columns') ?? 2)
              .clamp(1, 30);
      final nextShowTtsInput = prefs.getBool('showTtsInput') ?? true;
      final nextOrientation = prefs.getString('orientationMode') ?? 'portrait';
      final nextFullScreen = prefs.getBool('fullScreen') ?? true;
      final nextLanguage = prefs.getString('language') ?? 'en';
      final nextPrimary =
          prefs.getInt('themePrimaryColor') ?? _defaultPrimaryColorValue;
      final nextText = prefs.getInt('themeTextColor') ?? Colors.white.value;
      final nextBg = prefs.getInt('themeBackgroundColor') ?? Colors.white.value;
      final nextCardText =
          prefs.getInt('cardTextColor') ?? const Color(0xFF111827).value;
      final nextTtsSize = prefs.getDouble('ttsBarSize') ?? 1.0;
      final nextCardTextScale = prefs.getDouble('cardTextScale') ?? 1.0;
      final nextDrawerExpanded = prefs.getBool('drawerFullScreen') ?? false;
      final nextShowActions = prefs.getBool('showTtsActions') ?? true;
      final nextShowDelete = prefs.getBool('showTtsDelete') ?? nextShowActions;
      final nextShowClear = prefs.getBool('showTtsClear') ?? nextShowActions;
      final nextHideTts = prefs.getBool('hideTtsText') ?? false;
      final nextOverlay = prefs.getBool('useImageOverlayLabel') ?? true;
      final nextApplyText = prefs.getBool('applyTextColorToCards') ?? false;
      final nextHaptics = prefs.getBool('enableHaptics') ?? true;
      final nextDisableBackCard =
          prefs.getBool('disableBackCardInPinMode') ?? false;
      final nextDark =
          prefs.getBool(ThemeAccessibility.darkModePrefKey) ?? _isDarkMode;
      final nextColorBlind =
          prefs.getBool(ThemeAccessibility.colorBlindPrefKey) ?? false;

      // Precache visible root cards so images render synchronously with zero skeleton flash
      if (mounted) {
        final visibleRootCards = loadedCards.take(12);
        for (final card in visibleRootCards) {
          final path = card.imagePath;
          if (path != null && path.isNotEmpty) {
            try {
              final ImageProvider provider = isAssetImagePath(path)
                  ? AssetImage(path)
                  : FileImage(File(path)) as ImageProvider;
              unawaited(precacheImage(provider, context));
            } catch (_) {}
          }
        }
      }

      _startupLoadingTimer?.cancel();
      setState(() {
        cards = loadedCards;
        _isInitialLoading = false;
        _hasStartupError = false;
        _startupErrorMessage = null;
        if (!_showStartupLoader) {
          _splashDismissed = true;
        }
        gridColumns = nextGridColumns;
        _loadVisibleSelections(prefs);
        showTtsInput = nextShowTtsInput;
        orientationMode = nextOrientation;
        fullScreen = nextFullScreen;
        currentLanguage = nextLanguage;
        _themePrimaryColor = nextPrimary;
        _themeTextColor = nextText;
        _themeBackgroundColor = nextBg;
        _cardTextColor = nextCardText;
        _ttsBarSize = nextTtsSize;
        _cardTextScale = nextCardTextScale;
        _isDrawerExpanded = nextDrawerExpanded;
        _showTtsDelete = nextShowDelete;
        _showTtsClear = nextShowClear;
        _hideTtsText = nextHideTts;
        _useImageOverlayLabel = nextOverlay;
        _applyTextColorToCards = nextApplyText;
        _enableHaptics = nextHaptics;
        _disableBackCardInPinMode = nextDisableBackCard;
        _isDarkMode = nextDark;
        _isColorBlindMode = nextColorBlind;
        ThemeAccessibility.colorBlindMode = nextColorBlind;
        _customCategories =
            (prefs.getStringList('customCategories') ?? []).toSet();
        final rawMeta = prefs.getString('customCategoryMetadata');
        if (rawMeta != null && rawMeta.isNotEmpty) {
          try {
            final decoded = jsonDecode(rawMeta) as Map<String, dynamic>;
            _customCategoryMetadata = decoded.map(
              (key, val) => MapEntry(
                key,
                CategoryMetadata.fromJson(val as Map<String, dynamic>),
              ),
            );
          } catch (e) {
            debugPrint('[HomePage] Error loading customCategoryMetadata: $e');
            _customCategoryMetadata = {};
          }
        } else {
          _customCategoryMetadata = {};
        }
        final savedCatList = prefs.getStringList('selectedCategories');
        if (savedCatList != null && savedCatList.isNotEmpty) {
          selectedCategories = savedCatList.toSet();
        } else {
          final legacyCat = prefs.getString('selectedCategory');
          if (legacyCat != null && legacyCat.isNotEmpty && legacyCat != 'All') {
            selectedCategories = {legacyCat};
          } else {
            selectedCategories = {'All'};
          }
        }
        _updateCategories();
        _migrateVisibleCountIfNeeded(prefs);
      });
      if (ThemeAccessibility.darkModeNotifier.value != nextDark) {
        ThemeAccessibility.darkModeNotifier.value = nextDark;
      }
      UiModeHelper.applyOrientation(nextOrientation);
      UiModeHelper.applySystemUi(nextFullScreen);
      debugPrint(
          '[HomePage] cold loadCards completed in ${sw.elapsedMilliseconds}ms');

      // Initialize TTS after first frame paints and loaded language/voice settings are known.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_initTts());
      });
      // Lightweight 30-day Recycle Bin cleanup
      unawaited(RecycleBinService.instance.purgeExpiredEntries(activeCards: loadedCards));
    } catch (e, st) {
      _startupLoadingTimer?.cancel();
      debugPrint('[_loadCards] ERROR: $e\n$st');
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _showStartupLoader = true;
          _hasStartupError = true;
          _startupErrorMessage = e.toString();
        });
      }
    }
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

  List<AACCard>? _cachedFilteredCards;
  Set<String>? _cachedFilterCategories;

  void _invalidateFilteredCardsCache() {
    _cachedFilteredCards = null;
    _cachedFilterCategories = null;
  }

  bool get _isCategoryFiltered =>
      !selectedCategories.contains('All') &&
      !selectedCategories.contains('All Cards') &&
      selectedCategories.isNotEmpty;

  void _updateCategories() {
    allCategories.clear();
    allCategories.add('All');
    final discovered = CategoryHelper.discoverCategories(cards);
    allCategories.addAll(discovered);
    allCategories.addAll(_customCategories);
    _invalidateFilteredCardsCache();
  }

  Future<void> _saveCards() async {
    if (isEditMode) {
      debugPrint(
        '[HomePage] staged edit session active; deferring card persistence until Done',
      );
      return;
    }
    await Future.wait([
      CardStorageService.saveCards(cards),
      SharedPreferences.getInstance().then((prefs) async {
        final encodedVisible = jsonEncode(
          visibleCardIdsByParent.map(
            (key, value) => MapEntry(key, value.toList()),
          ),
        );
        await Future.wait([
          prefs.setInt('gridColumns', gridColumns.clamp(1, 30)),
          prefs.setInt('grid_columns', gridColumns.clamp(1, 30)),
          prefs.setString('visibleCardIdsByParent', encodedVisible),
          prefs.setBool('showTtsInput', showTtsInput),
          prefs.setString('orientationMode', orientationMode),
          prefs.setBool('fullScreen', fullScreen),
          prefs.setString('language', currentLanguage),
          prefs.setInt('themePrimaryColor', _themePrimaryColor),
          prefs.setInt('themeTextColor', _themeTextColor),
          prefs.setInt('themeBackgroundColor', _themeBackgroundColor),
          prefs.setInt('cardTextColor', _cardTextColor),
          prefs.setDouble('ttsBarSize', _ttsBarSize),
          prefs.setDouble('cardTextScale', _cardTextScale),
          prefs.setBool('drawerFullScreen', _isDrawerExpanded),
          prefs.setBool('showTtsActions', _showTtsDelete || _showTtsClear),
          prefs.setBool('showTtsDelete', _showTtsDelete),
          prefs.setBool('showTtsClear', _showTtsClear),
          prefs.setBool('hideTtsText', _hideTtsText),
          prefs.setBool('useImageOverlayLabel', _useImageOverlayLabel),
          prefs.setBool('applyTextColorToCards', _applyTextColorToCards),
          prefs.setBool('enableHaptics', _enableHaptics),
          prefs.setBool(
              'disableBackCardInPinMode', _disableBackCardInPinMode),
          prefs.setBool(ThemeAccessibility.darkModePrefKey, _isDarkMode),
          prefs.setBool(
              ThemeAccessibility.colorBlindPrefKey, _isColorBlindMode),
          prefs.setStringList(
              'customCategories', _customCategories.toList()),
          prefs.setStringList(
              'selectedCategories', selectedCategories.toList()),
          prefs.setString('selectedCategory', selectedCategory),
          prefs.setString(
            'customCategoryMetadata',
            jsonEncode(
              _customCategoryMetadata.map((k, v) => MapEntry(k, v.toJson())),
            ),
          ),
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
    if (HomePage.speakPerformer != null) {
      await HomePage.speakPerformer!(text);
      return;
    }
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
    if (_enableHaptics) {
      unawaited(HomePage.hapticPerformer());
    }
    _tapAnimTimer?.cancel();
    setState(() {
      highlightedCardId = null;
      _tapAnimatedCardId = cardId;
    });
    _tapAnimTimer = Timer(const Duration(milliseconds: 180), () {
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
          final cropped = await CropZoomDialog.show(context, imagePath: outcome.imagePath);
          if (cropped == null || !mounted) return;

          final permanentPath = await CardStorageService.persistMediaFile(
            cropped,
            cardId: card.id,
            mediaType: 'images',
          );
          if (isEditMode) {
            _sessionCreatedMediaFiles.add(permanentPath);
          }
          setState(() {
            card.imagePath = permanentPath;
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
                      final translation =
                          MultilingualConceptService.lookupTranslations(
                              suggested);
                      if (translation != null) {
                        if (card.labelSinhala == null ||
                            card.labelSinhala!.trim().isEmpty) {
                          card.labelSinhala = translation.sinhala;
                        }
                        if (card.labelTamil == null ||
                            card.labelTamil!.trim().isEmpty) {
                          card.labelTamil = translation.tamil;
                        }
                      }
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
              content: Text(
                  'Camera photo could not be saved. Check permissions if needed.'),
            ),
          );
        }
      }
    } else if (choice == 'gallery') {
      final allowed =
          await AppPermissionsHelper.ensureLegacyStorageIfNeeded(context);
      if (!allowed || !mounted) return;

      try {
        final image = await _picker.pickImage(
            source: ImageSource.gallery, imageQuality: 80);
        if (image != null && mounted) {
          final cropped = await CropZoomDialog.show(context, imagePath: image.path);
          if (cropped == null || !mounted) return;

          final permanentPath = await CardStorageService.persistMediaFile(
            cropped,
            cardId: card.id,
            mediaType: 'images',
          );
          if (isEditMode) {
            _sessionCreatedMediaFiles.add(permanentPath);
          }
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
              content: Text(
                  'Image could not be selected. Check permissions if needed.'),
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

    final preEditSnapshot = _cloneCards(cards);
    final preEditVisibleMap = _cloneVisibleMap(visibleCardIdsByParent);
    final List<AACCard> movedCardsToHome = [];
    AACCard? duplicateCandidateCard;

    final action = await showDialog<CardEditorAction>(
      context: context,
      builder: (context) => CardEditorDialog(
        card: card,
        isNew: isNew,
        categories: allCategories.toList(),
        audioPlayer: _audioPlayer,
        language: currentLanguage,
        onMoveSubCardsToHome: (moved) {
          movedCardsToHome.addAll(moved);
        },
        onMediaCreated: (path) {
          if (isEditMode) {
            _sessionCreatedMediaFiles.add(path);
          }
        },
        onDuplicate: (candidate) {
          duplicateCandidateCard = candidate;
        },
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
    } else if (action == CardEditorAction.manageSubCards) {
      _showManageSubCardsDialog(card);
    } else if (action == CardEditorAction.duplicate) {
      await _duplicateCard(card, candidateData: duplicateCandidateCard);
    } else if (action == CardEditorAction.saved) {
      debugPrint(
        '[HomePage] card editor saved: id=${card.id}, label=${card.label}, '
        'imagePath=${card.imagePath}, voicePath=${card.voicePath}',
      );
      if (onSave != null) {
        onSave(card);
      } else {
        if (movedCardsToHome.isNotEmpty) {
          for (final mc in movedCardsToHome) {
            if (!cards.any((c) => c.id == mc.id)) {
              cards.add(mc);
              _includeInVisibleSelection('__root__', mc.id);
            }
          }
        }
        _undoHistory.add(EditUndoStep(
          cards: preEditSnapshot,
          visibleMap: preEditVisibleMap,
          activeParentId: activeParentCard?.id,
          parentStackIds: _parentStack.map((c) => c.id).toList(),
          description: 'Edit ${card.getLabel(currentLanguage)}',
        ));
        if (_undoHistory.length > 50) {
          _undoHistory.removeAt(0);
        }
        _updateCategories();
        _saveCards();

        if (movedCardsToHome.isNotEmpty && mounted) {
          final hiddenCount = movedCardsToHome.where((c) {
            return !CategoryHelper.matchesAnyCategory(
              c.category,
              selectedCategories,
            );
          }).length;

          if (hiddenCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Moved ${movedCardsToHome.length} card(s) to Home board. '
                  'Note: $hiddenCount card(s) may be hidden by current category filter.',
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } else if (action == null && !isNew) {
      final orig = _findCardById(card.id, preEditSnapshot);
      if (orig != null) {
        card.label = orig.label;
        card.labelSinhala = orig.labelSinhala;
        card.labelTamil = orig.labelTamil;
        card.category = orig.category;
        card.type = orig.type;
        card.colorValue = orig.colorValue;
        card.imagePath = orig.imagePath;
        card.voicePath = orig.voicePath;
      }
    }
  }

  Future<void> _showManageSubCardsDialog(AACCard folderCard) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ManageSubCardsDialog(
        folderCard: folderCard,
        rootCards: cards,
        currentLanguage: currentLanguage,
        customMetadata: _customCategoryMetadata,
        onCardsChanged: () {
          setState(() {});
          _updateCategories();
          _saveCards();
        },
        onRecordUndo: (description) {
          _recordUndoStep(description);
        },
        onEditSubCard: (subCard) async {
          await _editCard(subCard);
        },
        onAddSubCard: () async {
          _createCard(parent: folderCard);
        },
      ),
    );
    setState(() {});
    _updateCategories();
    _saveCards();
  }

  AACCard? _findParentFolderOf(String cardId, [List<AACCard>? list]) {
    final searchList = list ?? cards;
    for (final card in searchList) {
      if (card.subCards.any((c) => c.id == cardId)) {
        return card;
      }
      final found = _findParentFolderOf(cardId, card.subCards);
      if (found != null) return found;
    }
    return null;
  }

  static int _duplicateCounter = 0;

  String _generateUniqueCardId(String baseId) {
    var newId =
        'card_${DateTime.now().microsecondsSinceEpoch}_${_duplicateCounter++}';
    while (_findCardById(newId, cards) != null) {
      newId =
          'card_${DateTime.now().microsecondsSinceEpoch}_${_duplicateCounter++}';
    }
    return newId;
  }

  Future<void> _duplicateCard(
    AACCard originalCard, {
    AACCard? candidateData,
  }) async {
    // 1. Strict guard: folder cards or cards with sub-cards can NEVER be duplicated
    if (originalCard.type != 'word' || originalCard.subCards.isNotEmpty) {
      debugPrint(
        '[DuplicateCard] Safely rejected attempt to duplicate non-word card: '
        'id=${originalCard.id}, type=${originalCard.type}, subCards=${originalCard.subCards.length}',
      );
      return;
    }

    _recordUndoStep('Duplicate ${originalCard.getLabel(currentLanguage)}');

    final newCardId = _generateUniqueCardId(originalCard.id);

    // 2. Safe media duplication
    String? newImagePath = candidateData?.imagePath ?? originalCard.imagePath;
    String? newVoicePath = candidateData?.voicePath ?? originalCard.voicePath;

    if (newImagePath != null && newImagePath.isNotEmpty) {
      newImagePath = await CardStorageService.copyMediaFile(
        newImagePath,
        cardId: newCardId,
        mediaType: 'images',
      );
      if (isEditMode && newImagePath != null) {
        _sessionCreatedMediaFiles.add(newImagePath);
      }
    }

    if (newVoicePath != null && newVoicePath.isNotEmpty) {
      newVoicePath = await CardStorageService.copyMediaFile(
        newVoicePath,
        cardId: newCardId,
        mediaType: 'voices',
      );
      if (isEditMode && newVoicePath != null) {
        _sessionCreatedMediaFiles.add(newVoicePath);
      }
    }

    // 3. Construct independent duplicate AACCard
    final duplicate = AACCard(
      id: newCardId,
      label: candidateData?.label ?? originalCard.label,
      labelSinhala: candidateData?.labelSinhala ?? originalCard.labelSinhala,
      labelTamil: candidateData?.labelTamil ?? originalCard.labelTamil,
      category: candidateData?.category ?? originalCard.category,
      type: 'word',
      colorValue: candidateData?.colorValue ?? originalCard.colorValue,
      imagePath: newImagePath,
      voicePath: newVoicePath,
      subCards: const [],
    );

    // 4. Insert immediately after original in same parent container
    setState(() {
      if (activeParentCard != null) {
        final idx = activeParentCard!.subCards
            .indexWhere((c) => c.id == originalCard.id);
        if (idx != -1) {
          activeParentCard!.subCards.insert(idx + 1, duplicate);
        } else {
          activeParentCard!.subCards.add(duplicate);
        }
        _includeInVisibleSelection(activeParentCard!.id, duplicate.id);
      } else {
        final rootIdx = cards.indexWhere((c) => c.id == originalCard.id);
        if (rootIdx != -1) {
          cards.insert(rootIdx + 1, duplicate);
          _includeInVisibleSelection('__root__', duplicate.id);
        } else {
          final parent = _findParentFolderOf(originalCard.id, cards);
          if (parent != null) {
            final pIdx =
                parent.subCards.indexWhere((c) => c.id == originalCard.id);
            if (pIdx != -1) {
              parent.subCards.insert(pIdx + 1, duplicate);
            } else {
              parent.subCards.add(duplicate);
            }
            _includeInVisibleSelection(parent.id, duplicate.id);
          } else {
            cards.add(duplicate);
            _includeInVisibleSelection('__root__', duplicate.id);
          }
        }
      }
    });

    _updateCategories();
    await _saveCards();
    _setHighlight(duplicate.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Card duplicated successfully'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: _undoEditChanges,
          ),
        ),
      );
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
        _recordUndoStep('Add new card');
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
          if (TutorialService.instance.currentStepNotifier.value ==
              TutorialStepType.testNewCard) {
            isEditMode = false;
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
    if (card.type != 'folder' && card.subCards.isEmpty) return;
    setState(() {
      if (!_parentStack.contains(card)) {
        _parentStack.add(card);
      }
      activeParentCard = card;
    });
  }

  void _navigateBackFromSubCards() {
    setState(() {
      if (_parentStack.isNotEmpty) {
        _parentStack.removeLast();
        activeParentCard = _parentStack.isNotEmpty ? _parentStack.last : null;
      } else {
        activeParentCard = null;
      }
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
            color: Theme.of(context)
                .colorScheme
                .errorContainer
                .withValues(alpha: 0.35),
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
            onPressed: () async {
              debugPrint(
                '[HomePage] deleting card: id=${card.id}, '
                'label=${card.label}, activeParentId=${activeParentCard?.id}',
              );
              final parentFolder = activeParentCard ?? _findParentFolderOf(card.id, cards);
              final parentId = parentFolder?.id;
              final originalIndex = parentFolder != null
                  ? parentFolder.subCards.indexOf(card)
                  : cards.indexOf(card);

              // 1. Transactionally record into Recycle Bin
              final binEntry = await RecycleBinService.instance.moveToRecycleBin(
                card: card,
                parentId: parentId,
                originalIndex: originalIndex >= 0 ? originalIndex : 0,
              );
              if (isEditMode) {
                _sessionRecycleBinEntryIds.add(binEntry.entryId);
              }

              // 2. Record undo step with entry id
              _recordUndoStep(
                'Delete ${card.getLabel(currentLanguage)}',
                recycleBinEntryId: binEntry.entryId,
              );

              // 3. Remove card from board
              setState(() {
                if (parentFolder != null) {
                  parentFolder.subCards.remove(card);
                } else {
                  cards.remove(card);
                }
              });
              _updateCategories();
              _saveCards();
              if (context.mounted) {
                Navigator.pop(context);
              }
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
        }

        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
            TextButton(
              onPressed: () => selectLang('en'),
              child: const Text('Reset'),
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
    var report = _speechCapabilities;
    var probing = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> refreshProbe() async {
              setDialogState(() => probing = true);
              final fresh = await SpeechEngine.instance
                  .probeCapabilities(forceRefresh: true);
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
                title: 'Offline Speech Test',
                subtitle: 'Test voice output & verify offline speech engine',
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
                          final available =
                              status?.isLanguageAvailable ?? false;
                          final sub = status == null
                              ? 'Checking device speech engine...'
                              : (offlineReady
                                  ? 'Offline voice ready ($locale)'
                                  : (available
                                      ? 'Voice ready ($locale, uses device fallback)'
                                      : 'Language pack not installed ($locale)'));
                          return DialogOptionTile(
                            icon: offlineReady || available
                                ? Icons.volume_up_rounded
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
                  label: const Text('Test Voice'),
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
    showDialog(
      context: context,
      builder: (context) => SelectCategoryDialog(
        categories: allCategories.toList(),
        selectedCategories: selectedCategories,
        availableCards: cards,
        customMetadata: _customCategoryMetadata,
        currentLanguage: currentLanguage,
        onApply: (newCategories) {
          setState(() {
            selectedCategories = newCategories;
            activeParentCard = null;
            _resetTtsInput();
          });
          _saveCards();
        },
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        availableCards: cards,
        existingCategories: allCategories,
        currentLanguage: currentLanguage,
        onAddCategory: (cleanName, selectedCardIds, colorValue, icon) async {
          setState(() {
            _customCategories.add(cleanName);
            _customCategoryMetadata[cleanName] = CategoryMetadata(
              name: cleanName,
              icon: icon,
              colorValue: colorValue,
            );
            if (selectedCardIds.isNotEmpty) {
              for (var card in cards) {
                if (selectedCardIds.contains(card.id)) {
                  card.category = cleanName;
                }
                for (var subCard in card.subCards) {
                  if (selectedCardIds.contains(subCard.id)) {
                    subCard.category = cleanName;
                  }
                }
              }
              final rootVisible = visibleCardIdsByParent['__root__'];
              if (rootVisible != null && rootVisible.isNotEmpty) {
                rootVisible.addAll(selectedCardIds);
              }
            }
            _updateCategories();
          });

          _showMessage(selectedCardIds.isEmpty
              ? 'Category "$cleanName" created!'
              : 'Category "$cleanName" created with ${selectedCardIds.length} cards!');

          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(
              'customCategories', _customCategories.toList());
          await prefs.setString(
            'customCategoryMetadata',
            jsonEncode(
              _customCategoryMetadata.map((k, v) => MapEntry(k, v.toJson())),
            ),
          );

          await _saveCards();
        },
      ),
    );
  }

  void _showGridOptions() {
    showDialog(
      context: context,
      builder: (context) => SelectGridSizeDialog(
        currentColumns: gridColumns,
        cards: _getBaseDisplayedCards(),
        currentLanguage: currentLanguage,
        cardTextScale: _cardTextScale,
        cardTextColor: _cardTextColor,
        isDarkMode: _isDarkMode,
        onApply: (newCols) {
          setState(() => gridColumns = newCols);
          _saveCards();
        },
      ),
    );
  }

  void _confirmResetSettings() {
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
                border:
                    Border.all(color: Colors.orange.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded,
                      color: Colors.orange.shade700, size: 20),
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
                  Icon(Icons.verified_user_rounded,
                      color: Colors.green.shade700, size: 20),
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

  void _showStarterPackDialog() {
    _closeDrawerIfOpen();
    final isInstalled = StarterPackService.isStarterPackInstalled(cards);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.auto_awesome_rounded,
          color: Color(0xFF0277BD),
          size: 40,
        ),
        title: Text(
          isInstalled ? 'Starter Pack Installed' : 'Import Starter Pack?',
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isInstalled
                  ? 'All 128 Sri Lankan starter cards are installed in the "Default" folder across 13 categories.'
                  : 'Add 128 ready-colored Sri Lankan communication cards organized in 13 categories (Family, Food, Drinks, Feelings, Personal Care, and more) under a "Default" folder.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF0284C7), size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your existing cards, custom photos, audio recordings, and board layout remain 100% safe.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            if (isInstalled) ...[
              const SizedBox(height: 12),
              const Text(
                'Tip: You can re-sync to restore any missing starter cards without affecting cards you have edited.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(isInstalled ? 'Close' : 'Cancel'),
          ),
          FilledButton.icon(
            key: const ValueKey('confirm_import_starter_pack_btn'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0277BD),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(isInstalled ? Icons.sync_rounded : Icons.download_rounded, size: 18),
            label: Text(isInstalled ? 'Re-sync Cards' : 'Import 128 Cards'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _handleImportStarterPack();
            },
          ),
        ],
      ),
    );
  }

  void _handleImportStarterPack() {
    final result = StarterPackService.importStarterPack(cards);
    _saveCards();
    _updateCategories();
    setState(() {});

    if (result.alreadyInstalled && result.cardsAdded == 0) {
      _showMessage('Starter Pack is up to date. All 128 cards are already present.');
    } else {
      _showMessage(
        result.alreadyInstalled
            ? 'Re-synced ${result.cardsAdded} missing starter cards.'
            : 'Imported 128 starter cards into "Default" folder!',
      );
    }
  }

  Future<void> _openRecycleBin() async {
    _closeDrawerIfOpen();
    await RecycleBinService.instance.purgeExpiredEntries(activeCards: cards);
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecycleBinPage(
          activeCards: cards,
          currentLanguage: currentLanguage,
          themePrimary: Color(_themePrimaryColor),
          themeText: Color(_themeTextColor),
          isDarkMode: _isDarkMode,
          onRestoreCard: (restoredCard, parentId, index) {
            setState(() {});
            _updateCategories();
            _saveCards();
          },
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
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
      _cardTextColor = const Color(0xFF111827).value;
      _ttsBarSize = 1.0;
      _cardTextScale = 1.0;
      _isDrawerExpanded = false;
      _showTtsDelete = true;
      _showTtsClear = true;
      _hideTtsText = false;
      _useImageOverlayLabel = true;
      _applyTextColorToCards = false;
      _enableHaptics = true;
      _disableBackCardInPinMode = false;
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
    final currentCards = _getBaseDisplayedCards();
    final parentKey = _visibleSelectionKey();
    final currentVisible = visibleCardIdsByParent[parentKey];
    final initialIds = currentVisible != null
        ? currentVisible.toSet()
        : currentCards.map((c) => c.id).toSet();

    showDialog(
      context: context,
      builder: (context) => VisibleCardsDialog(
        cards: currentCards,
        allCards: cards,
        initialParentStack:
            activeParentCard != null ? List<AACCard>.from(_parentStack) : null,
        visibleCardIdsByParent: visibleCardIdsByParent,
        categoryName: selectedCategory,
        currentLanguage: currentLanguage,
        initialSelectedIds: initialIds,
        gridColumns: gridColumns,
        onSubmit: (selectedIds) {
          setState(() {
            if (selectedIds.isEmpty) {
              visibleCardIdsByParent.remove(parentKey);
            } else {
              visibleCardIdsByParent[parentKey] = selectedIds;
            }
          });
          _saveCards();
        },
        onSaveMap: (updatedMap) {
          setState(() {
            visibleCardIdsByParent.clear();
            for (final entry in updatedMap.entries) {
              if (entry.value.isNotEmpty) {
                visibleCardIdsByParent[entry.key] =
                    Set<String>.from(entry.value);
              }
            }
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
      'gridColumns': gridColumns.clamp(1, 30),
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
      'cardTextColor': _cardTextColor,
      'ttsBarSize': _ttsBarSize,
      'cardTextScale': _cardTextScale,
      'drawerFullScreen': _isDrawerExpanded,
      'showTtsActions': _showTtsDelete || _showTtsClear,
      'showTtsDelete': _showTtsDelete,
      'showTtsClear': _showTtsClear,
      'hideTtsText': _hideTtsText,
      'useImageOverlayLabel': _useImageOverlayLabel,
      'applyTextColorToCards': _applyTextColorToCards,
      'enableHaptics': _enableHaptics,
      'disableBackCardInPinMode': _disableBackCardInPinMode,
      'darkMode': _isDarkMode,
      'colorBlindMode': _isColorBlindMode,
      'colorBlindType': ThemeAccessibility.colorBlindType,
      'colorBlindBorderWidth': ThemeAccessibility.colorBlindBorderWidth,
      'colorBlindBorderColor': ThemeAccessibility.colorBlindBorderColor,
      'colorBlindBoldText': ThemeAccessibility.colorBlindBoldText,
      'colorBlindFilterImages': ThemeAccessibility.colorBlindFilterImages,
      'customCategories': _customCategories.toList(),
      'customCategoryMetadata':
          _customCategoryMetadata.map((k, v) => MapEntry(k, v.toJson())),
      'selectedCategories': selectedCategories.toList(),
      'selectedCategory': selectedCategory,
    };
  }

  List<AACCard> _getFilteredCards() {
    if (!_isCategoryFiltered) {
      return cards;
    }
    if (_cachedFilteredCards != null &&
        setEquals(_cachedFilterCategories, selectedCategories)) {
      return _cachedFilteredCards!;
    }
    final result = CategoryHelper.getWordCardsForCategories(
      cards,
      selectedCategories: selectedCategories,
    );
    _cachedFilteredCards = result;
    _cachedFilterCategories = Set<String>.from(selectedCategories);
    return result;
  }

  List<AACCard> _getBaseDisplayedCards() {
    if (activeParentCard != null) {
      return activeParentCard!.subCards;
    }
    return _getFilteredCards();
  }

  List<AACCard> _getDisplayedCards() {
    final base = _getBaseDisplayedCards();
    if (_isCategoryFiltered && activeParentCard == null) {
      return _filterBySearch(base);
    }
    final key = _visibleSelectionKey();
    if (!visibleCardIdsByParent.containsKey(key)) {
      return _filterBySearch(base);
    }
    final visibleIds = visibleCardIdsByParent[key]!;
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

  String _getVisibleCardsLabel() {
    final key = _visibleSelectionKey();
    if (!visibleCardIdsByParent.containsKey(key)) {
      return 'All cards';
    }
    final selected = visibleCardIdsByParent[key]!;
    return '${selected.length} selected';
  }

  void _includeInVisibleSelection(String parentKey, String cardId) {
    final current = visibleCardIdsByParent[parentKey];
    if (current == null || current.isEmpty) return;
    current.add(cardId);
  }

  void _collectMediaPaths(List<AACCard> cardList, Set<String> paths) {
    for (final card in cardList) {
      if (card.imagePath != null && card.imagePath!.isNotEmpty) {
        paths.add(card.imagePath!);
      }
      if (card.voicePath != null && card.voicePath!.isNotEmpty) {
        paths.add(card.voicePath!);
      }
      if (card.subCards.isNotEmpty) {
        _collectMediaPaths(card.subCards, paths);
      }
    }
  }

  void _toggleEditMode() async {
    if (!isEditMode && CaregiverLockService.instance.isEnabled) {
      final allowed = await CaregiverLockService.instance.authenticate(
        context,
        title: 'Unlock Edit Mode',
        reason: 'Confirm screen lock to edit words and cards',
      );
      if (!allowed || !mounted) return;
    }
    _scaffoldKey.currentState?.closeEndDrawer();
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    if (isEditMode) {
      if (!_hasEditSessionChanges()) {
        await _cancelEditSession(confirmed: true);
      } else {
        final choice = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes in Edit Mode. What would you like to do?',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                key: const ValueKey('drawer_unsaved_keep_editing_btn'),
                onPressed: () => Navigator.pop(ctx, 'keep'),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                key: const ValueKey('drawer_unsaved_discard_btn'),
                style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                onPressed: () => Navigator.pop(ctx, 'discard'),
                child: const Text('Discard Changes'),
              ),
              FilledButton(
                key: const ValueKey('drawer_unsaved_save_btn'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, 'save'),
                child: const Text('Save & Exit'),
              ),
            ],
          ),
        );
        if (choice == 'discard') {
          await _cancelEditSession(confirmed: true);
        } else if (choice == 'save') {
          await _handleEditDone();
        }
      }
    } else {
      _enterEditMode();
    }
  }

  void _enterEditMode() {
    if (isEditMode) return;
    setState(() {
      isEditMode = true;
      _undoHistory.clear();
      _sessionCreatedMediaFiles.clear();
      _sessionRecycleBinEntryIds.clear();

      final initialMedia = <String>{};
      _collectMediaPaths(cards, initialMedia);

      _editSessionSnapshot = EditSessionSnapshot(
        cards: _cloneCards(cards),
        visibleCardIdsByParent: _cloneVisibleMap(visibleCardIdsByParent),
        allCategories: Set<String>.from(allCategories),
        customCategories: Set<String>.from(_customCategories),
        selectedCategories: Set<String>.from(selectedCategories),
        selectedCategory: selectedCategory,
        customCategoryMetadata:
            Map<String, CategoryMetadata>.from(_customCategoryMetadata),
        activeParentId: activeParentCard?.id,
        parentStackIds: _parentStack.map((c) => c.id).toList(),
        initialMediaPaths: initialMedia,
      );
    });
  }

  bool _hasEditSessionChanges() {
    final snapshot = _editSessionSnapshot;
    if (snapshot == null) return false;

    final currentCardsJson =
        jsonEncode(cards.map((c) => c.toJson()).toList());
    final snapshotCardsJson =
        jsonEncode(snapshot.cards.map((c) => c.toJson()).toList());
    if (currentCardsJson != snapshotCardsJson) return true;

    final currentVisible = jsonEncode(
      visibleCardIdsByParent.map((k, v) => MapEntry(k, v.toList())),
    );
    final snapshotVisible = jsonEncode(
      snapshot.visibleCardIdsByParent.map((k, v) => MapEntry(k, v.toList())),
    );
    if (currentVisible != snapshotVisible) return true;

    if (!setEquals(allCategories, snapshot.allCategories)) return true;
    if (!setEquals(_customCategories, snapshot.customCategories)) return true;

    return false;
  }

  Future<void> _handleEditCancel() async {
    if (!_hasEditSessionChanges()) {
      await _cancelEditSession(confirmed: true);
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard Changes?'),
        content: const Text(
          'All changes made during this editing session will be lost. Your previously saved cards will remain unchanged.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel_dialog_keep_editing_btn'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            key: const ValueKey('cancel_dialog_discard_btn'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard Changes'),
          ),
        ],
      ),
    );

    if (discard == true) {
      await _cancelEditSession(confirmed: true);
    }
  }

  Future<void> _cancelEditSession({required bool confirmed}) async {
    final snapshot = _editSessionSnapshot;
    if (!confirmed || snapshot == null) {
      for (final entryId in _sessionRecycleBinEntryIds) {
        await RecycleBinService.instance.removeEntry(
          entryId,
          activeCards: cards,
        );
      }
      _sessionRecycleBinEntryIds.clear();
      setState(() {
        isEditMode = false;
        _stopAutoScroll();
        _undoHistory.clear();
        _editSessionSnapshot = null;
        _sessionCreatedMediaFiles.clear();
      _sessionRecycleBinEntryIds.clear();
      });
      return;
    }

    final restoredCards = _cloneCards(snapshot.cards);
    final restoredVisible = _cloneVisibleMap(snapshot.visibleCardIdsByParent);
    final restoredCategories = Set<String>.from(snapshot.allCategories);
    final restoredCustomCategories = Set<String>.from(snapshot.customCategories);
    final restoredSelectedCategories =
        Set<String>.from(snapshot.selectedCategories);
    final restoredSelectedCategory = snapshot.selectedCategory;
    final restoredCustomMetadata =
        Map<String, CategoryMetadata>.from(snapshot.customCategoryMetadata);

    final restoredParentStack = <AACCard>[];
    for (final id in snapshot.parentStackIds) {
      final found = _findCardById(id, restoredCards);
      if (found != null) restoredParentStack.add(found);
    }
    final restoredActiveParent = snapshot.activeParentId == null
        ? null
        : _findCardById(snapshot.activeParentId!, restoredCards);

    // Roll back Recycle Bin entries created during this uncommitted editing session
    for (final entryId in _sessionRecycleBinEntryIds) {
      await RecycleBinService.instance.removeEntry(
        entryId,
        activeCards: restoredCards,
      );
    }
    _sessionRecycleBinEntryIds.clear();

    // Clean up temporary media files created during this session that are NOT in restored cards
    final restoredMedia = <String>{};
    _collectMediaPaths(restoredCards, restoredMedia);

    for (final path in _sessionCreatedMediaFiles) {
      if (!restoredMedia.contains(path) &&
          !snapshot.initialMediaPaths.contains(path)) {
        try {
          final f = File(path);
          if (await f.exists()) {
            await f.delete();
            debugPrint('[EditSession] safely removed uncommitted media file: $path');
          }
        } catch (e) {
          debugPrint('[EditSession] media cleanup warning: $e');
        }
      }
    }

    setState(() {
      cards = restoredCards;
      visibleCardIdsByParent = restoredVisible;
      allCategories = restoredCategories;
      _customCategories = restoredCustomCategories;
      selectedCategories = restoredSelectedCategories;
      selectedCategory = restoredSelectedCategory;
      _customCategoryMetadata = restoredCustomMetadata;
      _parentStack.clear();
      _parentStack.addAll(restoredParentStack);
      activeParentCard = restoredActiveParent;
      isEditMode = false;
      _stopAutoScroll();
      _undoHistory.clear();
      _editSessionSnapshot = null;
      _sessionCreatedMediaFiles.clear();
      _sessionRecycleBinEntryIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes discarded. Original board restored.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _validateCardHierarchy(List<AACCard> cardList) {
    final seenIds = <String>{};

    String? checkCard(AACCard card, Set<String> ancestors) {
      if (card.id.trim().isEmpty) {
        return 'Found card with empty ID';
      }
      if (ancestors.contains(card.id)) {
        return 'Circular parent-child relationship detected for card "${card.label}"';
      }
      if (seenIds.contains(card.id)) {
        return 'Duplicate card ID detected: ${card.id}';
      }
      seenIds.add(card.id);

      final nextAncestors = Set<String>.from(ancestors)..add(card.id);
      for (final sub in card.subCards) {
        final err = checkCard(sub, nextAncestors);
        if (err != null) return err;
      }
      return null;
    }

    for (final c in cardList) {
      final err = checkCard(c, {});
      if (err != null) return err;
    }
    return null;
  }

  Future<void> _handleEditDone() async {
    final validationError = _validateCardHierarchy(cards);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot save: $validationError'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    setState(() {
      isEditMode = false;
      _stopAutoScroll();
      _undoHistory.clear();
      _editSessionSnapshot = null;
      _sessionCreatedMediaFiles.clear();
      _sessionRecycleBinEntryIds.clear();
    });

    await _saveCards();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes saved successfully.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _recordUndoStep(String description, {String? recycleBinEntryId}) {
    _undoHistory.add(EditUndoStep(
      cards: _cloneCards(cards),
      visibleMap: _cloneVisibleMap(visibleCardIdsByParent),
      activeParentId: activeParentCard?.id,
      parentStackIds: _parentStack.map((c) => c.id).toList(),
      description: description,
      recycleBinEntryId: recycleBinEntryId,
    ));
    if (_undoHistory.length > 50) {
      _undoHistory.removeAt(0);
    }
  }

  void _undoEditChanges() {
    if (_undoHistory.isNotEmpty) {
      final step = _undoHistory.removeLast();
      debugPrint('[HomePage] undoing edit-mode action: ${step.description}');
      if (step.recycleBinEntryId != null) {
        RecycleBinService.instance.removeEntry(
          step.recycleBinEntryId!,
          activeCards: step.cards,
        );
        _sessionRecycleBinEntryIds.remove(step.recycleBinEntryId);
      }
      setState(() {
        cards = _cloneCards(step.cards);
        visibleCardIdsByParent = _cloneVisibleMap(step.visibleMap);
        _parentStack.clear();
        for (final id in step.parentStackIds) {
          final found = _findCardById(id, cards);
          if (found != null) {
            _parentStack.add(found);
          }
        }
        activeParentCard = step.activeParentId == null
            ? null
            : _findCardById(step.activeParentId!, cards);
      });
      _updateCategories();
      _saveCards();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Undid: ${step.description}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nothing to undo'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isDescendantOf(AACCard potentialDescendant, AACCard ancestor) {
    if (potentialDescendant.id == ancestor.id) return true;
    for (final child in ancestor.subCards) {
      if (_isDescendantOf(potentialDescendant, child)) return true;
    }
    return false;
  }

  void _handleReorderCard(
    AACCard draggedCard,
    AACCard targetCard, {
    required bool insertAfter,
  }) {
    if (draggedCard.id == targetCard.id) return;

    final currentList =
        activeParentCard != null ? activeParentCard!.subCards : cards;
    final oldIndex = currentList.indexWhere((c) => c.id == draggedCard.id);
    final targetIndex = currentList.indexWhere((c) => c.id == targetCard.id);
    if (oldIndex == -1 || targetIndex == -1) return;

    int newIndex = insertAfter ? targetIndex + 1 : targetIndex;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (newIndex == oldIndex) return;

    _recordUndoStep('Reorder cards');
    setState(() {
      final item = currentList.removeAt(oldIndex);
      currentList.insert(newIndex, item);
    });
    _saveCards();
    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reordered cards'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFF38BDF8),
          onPressed: _undoEditChanges,
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _requestNestingConfirmation(
    AACCard draggedCard,
    AACCard targetCard,
  ) async {
    if (draggedCard.id == targetCard.id) return;
    if (_isDescendantOf(targetCard, draggedCard)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot move a card into its own sub-cards'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isTargetFolder = targetCard.type == 'folder';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _NestingConfirmationDialog(
        draggedCard: draggedCard,
        targetCard: targetCard,
        isTargetFolder: isTargetFolder,
        currentLanguage: currentLanguage,
      ),
    );

    if (confirmed == true && mounted) {
      _handleMoveCardInside(draggedCard, targetCard);
    }
  }

  void _handleMoveCardInside(AACCard draggedCard, AACCard targetCard) {
    if (draggedCard.id == targetCard.id) return;
    if (_isDescendantOf(targetCard, draggedCard)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot move a card into its own sub-cards'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cardName = draggedCard.getLabel(currentLanguage);
    final targetName = targetCard.getLabel(currentLanguage);
    _recordUndoStep('Move $cardName into $targetName');

    setState(() {
      final sourceList =
          activeParentCard != null ? activeParentCard!.subCards : cards;
      sourceList.removeWhere((c) => c.id == draggedCard.id);
      targetCard.subCards.add(draggedCard);
      if (targetCard.type != 'folder') {
        targetCard.type = 'folder';
      }
    });

    _saveCards();
    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Moved $cardName into $targetName'),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFF38BDF8),
          onPressed: _undoEditChanges,
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleMoveCardUp(AACCard card) {
    if (activeParentCard == null) return;

    final cardName = card.getLabel(currentLanguage);
    _recordUndoStep('Move $cardName up to Home');

    setState(() {
      activeParentCard!.subCards.removeWhere((c) => c.id == card.id);
      if (_parentStack.length > 1) {
        final grandParent = _parentStack[_parentStack.length - 2];
        grandParent.subCards.add(card);
      } else {
        cards.add(card);
      }
    });

    _saveCards();
    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Moved $cardName up to Home'),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFF38BDF8),
          onPressed: _undoEditChanges,
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  RenderBox? _findGridViewportBox() {
    final areaBox =
        _gridAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (areaBox != null && areaBox.hasSize) return areaBox;
    if (_gridController.hasClients) {
      final gridBox = _gridController
          .position.context.notificationContext
          ?.findRenderObject() as RenderBox?;
      if (gridBox != null && gridBox.hasSize) return gridBox;
    }
    return null;
  }

  void _checkAutoScroll(Offset globalPosition) {
    if (!isEditMode) {
      _stopAutoScroll();
      return;
    }
    final gridBox = _findGridViewportBox();
    if (gridBox == null || !gridBox.hasSize) {
      _stopAutoScroll();
      return;
    }

    final localPos = gridBox.globalToLocal(globalPosition);
    final width = gridBox.size.width;
    final height = gridBox.size.height;
    const edgeMargin = 72.0;
    const maxSpeed = 14.0;

    double vy = 0.0;
    double vx = 0.0;

    // Check vertical auto-scroll
    if (_gridController.hasClients &&
        _gridController.position.maxScrollExtent >
            _gridController.position.minScrollExtent) {
      if (localPos.dx >= -100.0 && localPos.dx <= width + 100.0) {
        if (localPos.dy >= -100.0 && localPos.dy < edgeMargin) {
          if (_gridController.offset > 0.0) {
            final intensity =
                ((edgeMargin - localPos.dy) / edgeMargin).clamp(0.15, 1.0);
            vy = -maxSpeed * intensity;
          }
        } else if (localPos.dy > height - edgeMargin &&
            localPos.dy <= height + 100.0) {
          if (_gridController.offset <
              _gridController.position.maxScrollExtent) {
            final intensity =
                ((localPos.dy - (height - edgeMargin)) / edgeMargin)
                    .clamp(0.15, 1.0);
            vy = maxSpeed * intensity;
          }
        }
      }
    }

    // Check horizontal auto-scroll (only if horizontal overflow actually exists!)
    if (_horizontalScrollController.hasClients &&
        _horizontalScrollController.position.maxScrollExtent >
            _horizontalScrollController.position.minScrollExtent + 1.0) {
      if (localPos.dy >= -100.0 && localPos.dy <= height + 100.0) {
        if (localPos.dx >= -100.0 && localPos.dx < edgeMargin) {
          if (_horizontalScrollController.offset > 0.0) {
            final intensity =
                ((edgeMargin - localPos.dx) / edgeMargin).clamp(0.15, 1.0);
            vx = -maxSpeed * intensity;
          }
        } else if (localPos.dx > width - edgeMargin &&
            localPos.dx <= width + 120.0) {
          if (_horizontalScrollController.offset <
              _horizontalScrollController.position.maxScrollExtent) {
            final intensity =
                ((localPos.dx - (width - edgeMargin)) / edgeMargin)
                    .clamp(0.15, 1.0);
            vx = maxSpeed * intensity;
          }
        }
      }
    }

    if (vy == 0.0 && vx == 0.0) {
      _stopAutoScroll();
    } else {
      _autoScrollVelocityY = vy;
      _autoScrollVelocityX = vx;
      if (_autoScrollTimer == null || !_autoScrollTimer!.isActive) {
        _autoScrollTimer =
            Timer.periodic(const Duration(milliseconds: 20), (timer) {
          bool scrolled = false;

          // Vertical scroll step
          if (_autoScrollVelocityY != 0.0 && _gridController.hasClients) {
            final pos = _gridController.position;
            final currentOffset = _gridController.offset;
            final targetOffset = (currentOffset + _autoScrollVelocityY)
                .clamp(pos.minScrollExtent, pos.maxScrollExtent);
            if ((targetOffset - currentOffset).abs() > 0.01) {
              _gridController.jumpTo(targetOffset);
              scrolled = true;
            } else {
              _autoScrollVelocityY = 0.0;
            }
          }

          // Horizontal scroll step
          if (_autoScrollVelocityX != 0.0 &&
              _horizontalScrollController.hasClients) {
            final pos = _horizontalScrollController.position;
            final currentOffset = _horizontalScrollController.offset;
            final targetOffset = (currentOffset + _autoScrollVelocityX)
                .clamp(pos.minScrollExtent, pos.maxScrollExtent);
            if ((targetOffset - currentOffset).abs() > 0.01) {
              _horizontalScrollController.jumpTo(targetOffset);
              scrolled = true;
            } else {
              _autoScrollVelocityX = 0.0;
            }
          }

          if (!scrolled &&
              _autoScrollVelocityY == 0.0 &&
              _autoScrollVelocityX == 0.0) {
            _stopAutoScroll();
          }
        });
      }
    }
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollVelocityY = 0.0;
    _autoScrollVelocityX = 0.0;
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
    if (isPinned) {
      _showPressAndHoldToUnpinNotice();
      return;
    }
    _closeDrawerIfOpen();
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
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
            TextButton(
              onPressed: () => selectOrientation('portrait'),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  void _openPersonalizeSetup() async {
    final result = await PersonalizeSetupDialog.show(
      context,
      initialLanguage: currentLanguage,
      initialAppBarColor: Color(_themePrimaryColor),
      initialBoardColor: Color(_themeBackgroundColor),
      isFirstLaunch: false,
    );
    if (result != null && mounted) {
      setState(() {
        currentLanguage = result.language;
        _themePrimaryColor = result.appBarColor.value;
        _themeBackgroundColor = result.boardColor.value;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', currentLanguage);
      await prefs.setInt('themePrimaryColor', _themePrimaryColor);
      await prefs.setInt('themeBackgroundColor', _themeBackgroundColor);
      await _saveCards();
    }
  }

  void _showThemeColorDialog({
    required String title,
    String? subtitle,
    required Color initialColor,
    Color? defaultColor,
    Color? headerColor,
    ColorPickerPreviewType previewType = ColorPickerPreviewType.appHeader,
    required ValueChanged<Color> onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) => ProfessionalColorPickerDialog(
        title: title,
        subtitle: subtitle ?? 'Pick a color for Normal Mode',
        initialColor: initialColor,
        defaultColor: defaultColor,
        headerColor: headerColor,
        previewType: previewType,
        language: currentLanguage,
        onApply: onSelected,
      ),
    );
  }

  void _showColorVisionDialog() {
    showDialog(
      context: context,
      builder: (context) => ColorVisionDialog(
        initialColorBlind: _isColorBlindMode,
        initialType: ThemeAccessibility.colorBlindType,
        initialBorderWidth: ThemeAccessibility.colorBlindBorderWidth,
        initialBorderColor: ThemeAccessibility.colorBlindBorderColor,
        initialBoldText: ThemeAccessibility.colorBlindBoldText,
        initialFilterImages: ThemeAccessibility.colorBlindFilterImages,
        isDarkMode: _isDarkMode,
        onApply: (enabled, type, borderWidth, borderColor, boldText, filterImages) async {
          setState(() {
            _isColorBlindMode = enabled;
          });
          ThemeAccessibility.colorBlindMode = enabled;
          await ThemeAccessibility.saveColorBlindSettings(
            enabled: enabled,
            type: type,
            borderWidth: borderWidth,
            borderColor: borderColor,
            boldText: boldText,
            filterImages: filterImages,
          );
          await _saveCards();
        },
      ),
    );
  }

  void _showTtsBarSizeDialog() {
    double tempSize = _ttsBarSize;
    bool tempShowDelete = _showTtsDelete;
    bool tempShowClear = _showTtsClear;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          final colorScheme = Theme.of(context).colorScheme;
          return AlertDialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            title: const StyledDialogHeader(
              icon: Icons.text_increase_rounded,
              title: 'TTS Bar Settings',
              subtitle: 'Configure size, Delete & Clear action buttons',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LivePreviewPanel(
                    title: 'LIVE PREVIEW',
                    icon: Icons.record_voice_over_rounded,
                    minHeight: 80,
                    maxHeight: 140,
                    trailing: TtsComposerPreview.buildActionChips(
                      showDelete: tempShowDelete,
                      showClear: tempShowClear,
                      isDark: _isDarkMode,
                    ),
                    child: Center(
                      child: TtsComposerPreview(
                        sizeFactor: tempSize,
                        showDelete: tempShowDelete,
                        showClear: tempShowClear,
                        showText: !_hideTtsText,
                        speakerColor: _isDarkMode
                            ? colorScheme.primary
                            : Color(_themePrimaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primaryContainer.withValues(alpha: 0.45),
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
                  Material(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(14)),
                            ),
                            secondary:
                                const Icon(Icons.backspace_outlined, size: 20),
                            title: const Text(
                              'Show Delete Button',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Remove last tapped word card',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: tempShowDelete,
                            onChanged: (value) {
                              setLocalState(() => tempShowDelete = value);
                            },
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                          SwitchListTile(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(14)),
                            ),
                            secondary:
                                const Icon(Icons.clear_rounded, size: 20),
                            title: const Text(
                              'Show Clear Button',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Clear entire sentence bar',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: tempShowClear,
                            onChanged: (value) {
                              setLocalState(() => tempShowClear = value);
                            },
                          ),
                        ],
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
              TextButton(
                onPressed: () {
                  setLocalState(() {
                    tempSize = 1.0;
                    tempShowDelete = true;
                    tempShowClear = true;
                  });
                },
                child: const Text('Reset'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _ttsBarSize = tempSize;
                    _showTtsDelete = tempShowDelete;
                    _showTtsClear = tempShowClear;
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

  String _getCardTextScaleLabel() {
    if ((_cardTextScale - 0.85).abs() < 0.04) return 'Small (85%)';
    if ((_cardTextScale - 1.0).abs() < 0.04) return 'Medium (100%)';
    if ((_cardTextScale - 1.15).abs() < 0.04) return 'Large (115%)';
    if ((_cardTextScale - 1.30).abs() < 0.04) return 'Extra Large (130%)';
    return '${(_cardTextScale * 100).round()}%';
  }

  void _showCardTextColorDialog() {
    _showThemeColorDialog(
      title: 'Card text color',
      subtitle: 'Pick a text color for cards',
      initialColor: Color(_cardTextColor),
      defaultColor: const Color(0xFF111827),
      previewType: ColorPickerPreviewType.textPreview,
      onSelected: (color) {
        setState(() {
          _cardTextColor = color.value;
          _applyTextColorToCards = true;
        });
        _saveCards();
      },
    );
  }

  void _showCardTextSizeDialog() {
    double tempScale = _cardTextScale;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          final colorScheme = Theme.of(context).colorScheme;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          final sampleTextColor = _applyTextColorToCards
              ? Color(_cardTextColor)
              : (isDark ? Colors.white : const Color(0xFF111827));

          return AlertDialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            title: const StyledDialogHeader(
              icon: Icons.format_size_rounded,
              title: 'Card Text Size',
              subtitle: 'Scale card label text size',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 104,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.7),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildScalePreviewCard(
                            label: 'Hello',
                            icon: Icons.waving_hand_rounded,
                            cardBg: const Color(0xFFFFF59D),
                            textColor: sampleTextColor,
                            scale: tempScale,
                            isTablet: isTablet,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildScalePreviewCard(
                            label: 'කන්න',
                            icon: Icons.restaurant_rounded,
                            cardBg: const Color(0xFFBBDEFB),
                            textColor: sampleTextColor,
                            scale: tempScale,
                            isTablet: isTablet,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildScalePreviewCard(
                            label: 'வணக்கம்',
                            icon: Icons.chat_bubble_rounded,
                            cardBg: const Color(0xFFC8E6C9),
                            textColor: sampleTextColor,
                            scale: tempScale,
                            isTablet: isTablet,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Size: ${(tempScale * 100).round()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildSizePresetChip(
                        label: 'Small',
                        value: 0.85,
                        current: tempScale,
                        onTap: (v) => setLocalState(() => tempScale = v),
                      ),
                      _buildSizePresetChip(
                        label: 'Medium',
                        value: 1.0,
                        current: tempScale,
                        onTap: (v) => setLocalState(() => tempScale = v),
                      ),
                      _buildSizePresetChip(
                        label: 'Large',
                        value: 1.15,
                        current: tempScale,
                        onTap: (v) => setLocalState(() => tempScale = v),
                      ),
                      _buildSizePresetChip(
                        label: 'Extra Large',
                        value: 1.30,
                        current: tempScale,
                        onTap: (v) => setLocalState(() => tempScale = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: tempScale,
                    min: 0.80,
                    max: 1.35,
                    divisions: 11,
                    label: '${(tempScale * 100).round()}%',
                    onChanged: (value) {
                      setLocalState(() => tempScale = value);
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Card labels scale smoothly and fit automatically without overflowing or distorting cards.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurfaceVariant,
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
                    _cardTextScale = 1.0;
                  });
                  _saveCards();
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _cardTextScale = tempScale;
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

  Widget _buildSizePresetChip({
    required String label,
    required double value,
    required double current,
    required ValueChanged<double> onTap,
  }) {
    final isSelected = (current - value).abs() < 0.04;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(value),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildScalePreviewCard({
    required String label,
    required IconData icon,
    required Color cardBg,
    required Color textColor,
    required double scale,
    required bool isTablet,
  }) {
    final baseFontSize = (isTablet ? 14.0 : 12.0) * scale;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.15),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.black87),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: textColor,
                  fontSize: baseFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _backupWithPicker() async {
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
      if (settings.containsKey('selectedCategories') &&
          settings['selectedCategories'] is List) {
        selectedCategories = (settings['selectedCategories'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toSet();
      } else if (settings.containsKey('selectedCategory')) {
        final legacy = settings['selectedCategory']?.toString() ?? 'All';
        selectedCategory = legacy;
      } else {
        selectedCategories = {'All'};
      }
      if (selectedCategories.isEmpty) {
        selectedCategories = {'All'};
      }

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

      gridColumns =
          ((settings['gridColumns'] as num?)?.toInt() ?? gridColumns).clamp(1, 30);
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
      _cardTextColor =
          (settings['cardTextColor'] as num?)?.toInt() ?? _cardTextColor;
      _ttsBarSize = (settings['ttsBarSize'] as num?)?.toDouble() ?? _ttsBarSize;
      _cardTextScale =
          (settings['cardTextScale'] as num?)?.toDouble() ?? _cardTextScale;
      _isDrawerExpanded =
          settings['drawerFullScreen'] as bool? ?? _isDrawerExpanded;
      final importedShowActions =
          settings['showTtsActions'] as bool? ?? (_showTtsDelete || _showTtsClear);
      _showTtsDelete =
          settings['showTtsDelete'] as bool? ?? importedShowActions;
      _showTtsClear =
          settings['showTtsClear'] as bool? ?? importedShowActions;
      _hideTtsText = settings['hideTtsText'] as bool? ?? _hideTtsText;
      _useImageOverlayLabel =
          settings['useImageOverlayLabel'] as bool? ?? _useImageOverlayLabel;
      _applyTextColorToCards =
          settings['applyTextColorToCards'] as bool? ?? _applyTextColorToCards;
      _enableHaptics = settings['enableHaptics'] as bool? ?? _enableHaptics;
      _disableBackCardInPinMode =
          settings['disableBackCardInPinMode'] as bool? ??
              _disableBackCardInPinMode;
      _isDarkMode = settings['darkMode'] as bool? ?? _isDarkMode;
      _isColorBlindMode =
          settings['colorBlindMode'] as bool? ?? _isColorBlindMode;

      if (settings.containsKey('customCategories') &&
          settings['customCategories'] is List) {
        _customCategories = (settings['customCategories'] as List)
            .map((c) => c.toString())
            .where((c) => c.isNotEmpty)
            .toSet();
      }

      if (settings.containsKey('customCategoryMetadata') &&
          settings['customCategoryMetadata'] is Map) {
        final raw = settings['customCategoryMetadata'] as Map;
        _customCategoryMetadata = raw.map((k, v) => MapEntry(
              k.toString(),
              CategoryMetadata.fromJson(Map<String, dynamic>.from(v as Map)),
            ));
      } else {
        _customCategoryMetadata = {};
      }

      final cbType = settings['colorBlindType']?.toString() ??
          ThemeAccessibility.colorBlindType;
      final cbWidth = (settings['colorBlindBorderWidth'] as num?)?.toDouble() ??
          ThemeAccessibility.colorBlindBorderWidth;
      final cbColor = settings['colorBlindBorderColor']?.toString() ??
          ThemeAccessibility.colorBlindBorderColor;
      final cbBold = settings['colorBlindBoldText'] as bool? ??
          ThemeAccessibility.colorBlindBoldText;
      final cbFilter = settings['colorBlindFilterImages'] as bool? ??
          ThemeAccessibility.colorBlindFilterImages;

      ThemeAccessibility.colorBlindMode = _isColorBlindMode;
      unawaited(ThemeAccessibility.saveColorBlindSettings(
        enabled: _isColorBlindMode,
        type: cbType,
        borderWidth: cbWidth,
        borderColor: cbColor,
        boldText: cbBold,
        filterImages: cbFilter,
      ));
      unawaited(ThemeAccessibility.setDarkMode(_isDarkMode));

      // Legacy 'ttsVoiceProfile' key in older backups is ignored intentionally.
      ThemeAccessibility.darkModeNotifier.value = _isDarkMode;

      _resetTtsInput();
    });
    unawaited(_initTts());
    _updateCategories();
    if (!selectedCategories.contains('All') &&
        !selectedCategories.contains('All Cards')) {
      selectedCategories.removeWhere(
        (c) =>
            !allCategories.any((cat) => CategoryHelper.matchesCategory(c, cat)),
      );
      if (selectedCategories.isEmpty) {
        setState(() {
          selectedCategories = {'All'};
        });
      }
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
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                  leading:
                      Icon(Icons.person_rounded, color: colorScheme.primary),
                  title: const Text('Yasas Pasindu Fernando'),
                  subtitle: const Text('Creator & Developer'),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.email_rounded, color: colorScheme.primary),
                  title: const Text('yasaspasindufernando@gmail.com'),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.phone_rounded, color: colorScheme.primary),
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

  Future<void> _handleTogglePin() async {
    if (isPinned && CaregiverLockService.instance.isEnabled) {
      final allowed = await CaregiverLockService.instance.authenticate(
        context,
        title: 'Unlock Board',
        reason: 'Confirm screen lock to unpin communication board',
      );
      if (!allowed || !mounted) return;
    }
    setState(() {
      isPinned = !isPinned;
      if (isPinned) {
        fullScreen = true;
      }
    });
    UiModeHelper.applySystemUi(fullScreen);
  }

  void _showPressAndHoldToUnpinNotice() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
    final message = currentLanguage == 'si'
        ? 'Unpin කිරීමට ඔබාගෙන සිටින්න'
        : currentLanguage == 'ta'
            ? 'அன்பின் செய்ய அழுத்திப் பிடிக்கவும்'
            : 'Press and hold to unpin';
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        width: 260,
      ),
    );
  }

  Future<void> _handleUnpinLongPress() async {
    await HomePage.hapticPerformer();
    await _handleTogglePin();
  }

  Future<void> _handleToggleCaregiverLock(bool enabled) async {
    if (!enabled) {
      final allowed = await CaregiverLockService.instance.authenticate(
        context,
        title: 'Disable Caregiver Lock',
        reason: 'Confirm screen lock to disable caregiver protection',
      );
      if (!allowed || !mounted) return;
    }
    await CaregiverLockService.instance.setEnabled(enabled);
    if (mounted) setState(() {});
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
          _navigateBackFromSubCards();
          return false;
        }
        if (isEditMode) {
          if (!_hasEditSessionChanges()) {
            await _cancelEditSession(confirmed: true);
            return false;
          }
          final choice = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Unsaved Changes'),
              content: const Text(
                'You have unsaved changes in Edit Mode. What would you like to do?',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                TextButton(
                  key: const ValueKey('back_unsaved_keep_editing_btn'),
                  onPressed: () => Navigator.pop(ctx, 'keep'),
                  child: const Text('Keep Editing'),
                ),
                TextButton(
                  key: const ValueKey('back_unsaved_discard_btn'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                  onPressed: () => Navigator.pop(ctx, 'discard'),
                  child: const Text('Discard Changes'),
                ),
                FilledButton(
                  key: const ValueKey('back_unsaved_save_btn'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, 'save'),
                  child: const Text('Save & Exit'),
                ),
              ],
            ),
          );

          if (choice == 'discard') {
            await _cancelEditSession(confirmed: true);
          } else if (choice == 'save') {
            await _handleEditDone();
          }
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
      child: Stack(
        children: [
          Scaffold(
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
                    onBack: _navigateBackFromSubCards,
                    showPin: true,
                    isPinned: isPinned,
                    onTogglePin: _handleTogglePin,
                    onUnpinLongPress: _handleUnpinLongPress,
                    onPinTapWhenPinned: _showPressAndHoldToUnpinNotice,
                    isEditMode: isEditMode,
                    showMenu: !isPinned,
                    menuButtonKey: _menuButtonKey,
                    onOrientation: _showOrientationDialog,
                    onOpenMenu: () {
                      TutorialService.instance.notifyMenuOpened();
                      if (_isDrawerExpanded) {
                        setState(() {
                          _isDrawerExpanded = false;
                        });
                      }
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                    titleTextColor: themeText,
                  ),
            endDrawer: isPinned
                ? null
                : HomeDrawer(
                    onClose: () => _scaffoldKey.currentState?.closeEndDrawer(),
                    selectedCategory: selectedCategory,
                    currentLanguageLabel: _getLanguageName(currentLanguage),
                    speechStatusLabel: _speechDrawerSubtitle(),
                    gridColumns: gridColumns,
                    visibleCardsLabel: _getVisibleCardsLabel(),
                    isEditMode: isEditMode,
                    showTtsInput: showTtsInput,
                    orientationLabel: orientationMode == 'landscape'
                        ? 'Landscape'
                        : 'Portrait',
                    fullScreen: fullScreen,
                    headerColor: themePrimary,
                    headerTextColor: themeText,
                    isCaregiverLockEnabled:
                        CaregiverLockService.instance.isEnabled,
                    onToggleCaregiverLock: _handleToggleCaregiverLock,
                    disableBackCardInPinMode: _disableBackCardInPinMode,
                    onToggleDisableBackCardInPinMode: (enabled) {
                      setState(() {
                        _disableBackCardInPinMode = enabled;
                      });
                      _saveCards();
                    },
                    hideTtsText: _hideTtsText,
                    enableHaptics: _enableHaptics,
                    onToggleHaptics: (enabled) {
                      setState(() {
                        _enableHaptics = enabled;
                      });
                      _saveCards();
                    },
                    useImageOverlayLabel: _useImageOverlayLabel,
                    applyTextColorToCards: _applyTextColorToCards,
                    isDarkMode: _isDarkMode,
                    isColorBlindMode: _isColorBlindMode,
                    primaryColorSwatch: customPrimary,
                    textColorSwatch: customText,
                    backgroundColorSwatch: customBackground,
                    cardTextColorSwatch: Color(_cardTextColor),
                    isOnlineEnabled:
                        NetworkPolicyService.instance.isOnlineEnabled,
                    onToggleOnline: (enabled) async {
                      await NetworkPolicyService.instance
                          .setOnlineEnabled(enabled);
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
                      ThemeAccessibility.colorBlindMode = enabled;
                      _saveCards();
                    },
                    onOpenColorBlindSettings: _showColorVisionDialog,
                    onSelectCategory: _showCategoryDialog,
                    onAddCategory: _showAddCategoryDialog,
                    onToggleEdit: _toggleEditMode,
                    onToggleTtsInput: () {
                      setState(() {
                        showTtsInput = !showTtsInput;
                      });
                      _saveCards();
                    },
                    onToggleTtsText: () {
                      setState(() {
                        _hideTtsText = !_hideTtsText;
                      });
                      _saveCards();
                    },
                    onToggleCardImageLabel: () {
                      setState(() {
                        _useImageOverlayLabel = !_useImageOverlayLabel;
                      });
                      _saveCards();
                    },
                    onToggleApplyTextColorToCards: () {
                      setState(() {
                        _applyTextColorToCards = !_applyTextColorToCards;
                      });
                      _saveCards();
                    },
                    onChangeOrientation: _showOrientationDialog,
                    onPickPrimaryColor: () {
                      _showThemeColorDialog(
                        title: 'App color',
                        subtitle: 'Pick a color for Normal Mode',
                        initialColor: customPrimary,
                        defaultColor: const Color(_defaultPrimaryColorValue),
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
                      _showThemeColorDialog(
                        title: 'Global Text Color',
                        subtitle: 'App-wide text and icons',
                        initialColor: customText,
                        defaultColor: Colors.white,
                        headerColor: customPrimary,
                        previewType: ColorPickerPreviewType.globalTextPreview,
                        onSelected: (color) {
                          setState(() {
                            _themeTextColor = color.value;
                          });
                          _saveCards();
                        },
                      );
                    },
                    onPickBackgroundColor: () {
                      _showThemeColorDialog(
                        title: 'Background color',
                        subtitle:
                            'Pick a color for the main content area (body)',
                        initialColor: customBackground,
                        defaultColor: Colors.white,
                        previewType: ColorPickerPreviewType.backgroundPreview,
                        onSelected: (color) {
                          setState(() {
                            _themeBackgroundColor = color.value;
                          });
                          _saveCards();
                        },
                      );
                    },
                    onOpenPersonalizeSetup: _openPersonalizeSetup,
                    onPickCardTextColor: _showCardTextColorDialog,
                    onShowTtsBarSize: _showTtsBarSizeDialog,
                    cardTextScaleLabel: _getCardTextScaleLabel(),
                    onShowCardTextSize: _showCardTextSizeDialog,
                    isExpanded: _isDrawerExpanded,
                    onToggleExpanded: (val) {
                      setState(() {
                        _isDrawerExpanded = val;
                      });
                      TutorialService.instance.notifyDrawerResized();
                      _saveCards();
                    },
                    onToggleFullScreen: () {
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
                    onShowStarterPack: _showStarterPackDialog,
                    onOpenRecycleBin: _openRecycleBin,
                    onResetSettings: _confirmResetSettings,
                    onManagePermissions: () async {
                      await AppPermissionsHelper.requestAllAndShowStatus(
                          context);
                    },
                    resizeButtonKey: _drawerResizeKey,
                    editModeKey: _drawerEditModeKey,
                    onReplayTutorial: () {
                      _closeDrawerIfOpen();
                      TutorialService.instance.resetAndReplayTour();
                    },
                    onShowMiniGuides: () => MiniGuidesDialog.show(context,
                        language: currentLanguage),
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
                          showPin: true,
                          isPinned: isPinned,
                          canGoBack: activeParentCard != null,
                          baseColor: themePrimary,
                          textColor: themeText,
                          showHorizontalArrows: _hasHorizontalOverflow,
                          canScrollLeft: _canScrollHorizontallyLeft,
                          canScrollRight: _canScrollHorizontallyRight,
                          onTogglePin: _handleTogglePin,
                          onUnpinLongPress: _handleUnpinLongPress,
                          onPinTapWhenPinned: _showPressAndHoldToUnpinNotice,
                          onOpenMenu: () {
                            if (_isDrawerExpanded) {
                              setState(() {
                                _isDrawerExpanded = false;
                              });
                            }
                            _scaffoldKey.currentState?.openEndDrawer();
                          },
                          onGoBack: _navigateBackFromSubCards,
                          onHome: () {
                            setState(() {
                              selectedCategory = 'All';
                              _parentStack.clear();
                              activeParentCard = null;
                              searchQuery = '';
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
                            final max =
                                _gridController.position.maxScrollExtent;
                            final next = _gridController.offset + 300;
                            _gridController.animateTo(
                              next > max ? max : next,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            );
                          },
                          onLeft: () {
                            if (!_horizontalScrollController.hasClients) return;
                            final pos = _horizontalScrollController.position;
                            final step = pos.viewportDimension * 0.8;
                            final next = (pos.pixels - step).clamp(
                              pos.minScrollExtent,
                              pos.maxScrollExtent,
                            );
                            _horizontalScrollController.animateTo(
                              next,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          onRight: () {
                            if (!_horizontalScrollController.hasClients) return;
                            final pos = _horizontalScrollController.position;
                            final step = pos.viewportDimension * 0.8;
                            final next = (pos.pixels + step).clamp(
                              pos.minScrollExtent,
                              pos.maxScrollExtent,
                            );
                            _horizontalScrollController.animateTo(
                              next,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          onSearch: _showSearchDialog,
                          onOrientation: _showOrientationDialog,
                        ),
                      ],
                    )
                  : Container(
                      color: themeBackground,
                      child:
                          _buildMainContent(isTablet, themePrimary, themeText),
                    ),
            ),
          ),
          TutorialOverlay(language: currentLanguage),
          if (!_splashDismissed && _showStartupLoader)
            Positioned.fill(
              child: AnimatedOpacity(
                key: const ValueKey('home_animated_splash_layer'),
                opacity: _isInitialLoading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                onEnd: () {
                  if (!_isInitialLoading && mounted) {
                    setState(() {
                      _splashDismissed = true;
                    });
                  }
                },
                child: ChildFriendlySplash(
                  key: const ValueKey('home_animated_splash'),
                  language: currentLanguage,
                  errorMessage: _hasStartupError
                      ? (_startupErrorMessage ?? 'Initialization error')
                      : null,
                  onRetry: _hasStartupError
                      ? () {
                          setState(() {
                            _hasStartupError = false;
                            _startupErrorMessage = null;
                            _isInitialLoading = true;
                          });
                          _loadCards();
                        }
                      : null,
                ),
              ),
            )
          else if (!_splashDismissed && _isInitialLoading)
            Positioned.fill(
              child: ColoredBox(
                key: const ValueKey('home_static_splash_bridge'),
                color: const Color(0xFFEAF5FE),
                child: Center(
                  child: Container(
                    width: 184.0,
                    height: 184.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFBAE6FD).withValues(alpha: 0.6),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          blurRadius: 18,
                          spreadRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset(
                      'assets/loading/logo_transparent_640.webp',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/simple_aac_logo_transparent.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditHintBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? const Color(0xFF1E293B)
            : const Color(0xFFE2E8F0).withOpacity(0.6),
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode
                ? const Color(0xFF334155)
                : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'STEP 1: REORDER CARDS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: _isDarkMode
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.6),
                  width: 1.2,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.swap_vert_rounded,
                      size: 15,
                      color: Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Drag to reorder',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbPill({
    required Color themePrimary,
    required bool isEditMode,
  }) {
    final parentLabel = activeParentCard?.getLabel(currentLanguage) ?? 'Parent';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey(
          isEditMode
              ? 'edit_mode_breadcrumb_back'
              : 'normal_mode_breadcrumb_back',
        ),
        onTap: _navigateBackFromSubCards,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: isEditMode ? null : double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isDarkMode
                  ? Colors.white.withOpacity(0.18)
                  : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDarkMode ? 0.25 : 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: themePrimary,
                ),
                const SizedBox(width: 4),
                InkWell(
                  key: ValueKey(
                    isEditMode
                        ? 'edit_mode_breadcrumb_home'
                        : 'normal_mode_breadcrumb_home',
                  ),
                  onTap: () {
                    setState(() {
                      _parentStack.clear();
                      activeParentCard = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 1,
                    ),
                    child: Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode
                            ? Colors.white70
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                for (int i = 0; i < _parentStack.length - 1; i++) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                  InkWell(
                    key: ValueKey('breadcrumb_item_${_parentStack[i].id}'),
                    onTap: () {
                      setState(() {
                        final target = _parentStack[i];
                        _parentStack.removeRange(
                          i + 1,
                          _parentStack.length,
                        );
                        activeParentCard = target;
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 1,
                      ),
                      child: Text(
                        _parentStack[i].getLabel(currentLanguage),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isDarkMode
                              ? Colors.white70
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  parentLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalBreadcrumbBar(Color themePrimary) {
    return Container(
      key: const ValueKey('normal_mode_breadcrumb_bar'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: _buildBreadcrumbPill(
        themePrimary: themePrimary,
        isEditMode: false,
      ),
    );
  }

  Widget _buildEditBreadcrumbBar(Color themePrimary, Color themeText) {
    return DragTarget<DraggedCardData>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        _handleMoveCardUp(details.data.card);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isHovered
                ? const Color(0xFF00E5FF).withOpacity(0.2)
                : (_isDarkMode
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0).withOpacity(0.7)),
            border: Border(
              bottom: BorderSide(
                color: isHovered
                    ? const Color(0xFF00E5FF)
                    : (_isDarkMode
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1)),
                width: isHovered ? 2 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildBreadcrumbPill(
                    themePrimary: themePrimary,
                    isEditMode: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isHovered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Drop here to move up',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? const Color(0xFF0F172A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.vertical_align_top_rounded,
                        size: 13,
                        color: Color(0xFF00E5FF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Drop card to move up',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(
    bool isTablet,
    Color themePrimary,
    Color themeText,
  ) {
    final displayedCards = _getDisplayedCards();
    final isNestedFolder = activeParentCard != null;
    final showGridBackCard =
        isPinned && isNestedFolder && !_disableBackCardInPinMode;
    final totalGridItems = displayedCards.length + (showGridBackCard ? 1 : 0);
    final colorScheme = Theme.of(context).colorScheme;
    final viewKey = ValueKey(
      '${activeParentCard?.id ?? 'root'}_${selectedCategory}_${displayedCards.isEmpty ? 'empty' : 'grid'}',
    );

    Widget topBanner = const SizedBox.shrink(key: ValueKey('no_banner'));
    if (isEditMode) {
      topBanner = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EditModeBar(
            key: const ValueKey('edit_mode_bar'),
            addKey: _addNewCardKey,
            onCancel: _handleEditCancel,
            onDone: _handleEditDone,
            onUndo: _undoEditChanges,
            baseColor: themePrimary,
            textColor: themeText,
            onAdd: () {
              if (!isPinned) {
                _createCard(parent: activeParentCard);
              }
            },
          ),
          if (activeParentCard != null)
            _buildEditBreadcrumbBar(themePrimary, themeText)
          else
            _buildEditHintBar(),
        ],
      );
    } else {
      final showBreadcrumb = activeParentCard != null && !isPinned;
      if (!showTtsInput && !showBreadcrumb) {
        topBanner = const SizedBox.shrink(key: ValueKey('no_banner'));
      } else {
        topBanner = Column(
          key: const ValueKey('normal_top_banner'),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTtsInput)
              TtsBar(
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
                showActions: _showTtsDelete || _showTtsClear,
                showDelete: _showTtsDelete,
                showClear: _showTtsClear,
                showText: !_hideTtsText,
              ),
            if (showBreadcrumb)
              _buildNormalBreadcrumbBar(themePrimary),
          ],
        );
      }
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
          child: KeyedSubtree(
            key: _gridAreaKey,
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
            child: _isInitialLoading
                ? const SizedBox.shrink(key: ValueKey('grid_initial_loading'))
                : displayedCards.isEmpty
                    ? Center(
                        key: viewKey,
                        child: isNestedFolder
                            ? _buildEmptyFolderState(isTablet, colorScheme)
                            : _buildEmptyCategoryState(isTablet, colorScheme),
                      )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final effectiveCols = gridColumns.clamp(1, 30);
                      final padding = isTablet ? 20.0 : 12.0;
                      final spacing = isTablet ? 16.0 : 12.0;
                      final minCardWidth = isTablet
                          ? (isEditMode ? 100.0 : 90.0)
                          : (isEditMode ? 86.0 : 76.0);
                      final neededWidth = (effectiveCols * minCardWidth) +
                          ((effectiveCols - 1) * spacing) +
                          (padding * 2);
                      final bool needsHorizontalScroll =
                          neededWidth > constraints.maxWidth;
                      final double contentWidth =
                          needsHorizontalScroll ? neededWidth : constraints.maxWidth;

                      // Schedule post-frame measurement using actual scroll controller metrics
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        bool overflow = false;
                        if (_horizontalScrollController.hasClients) {
                          final pos = _horizontalScrollController.position;
                          overflow = pos.maxScrollExtent > pos.minScrollExtent + 1.0;
                        } else {
                          overflow = needsHorizontalScroll;
                        }
                        final canLeft = _horizontalScrollController.hasClients
                            ? _horizontalScrollController.position.pixels >
                                _horizontalScrollController.position.minScrollExtent + 1.0
                            : false;
                        final canRight = _horizontalScrollController.hasClients
                            ? _horizontalScrollController.position.pixels <
                                _horizontalScrollController.position.maxScrollExtent - 1.0
                            : overflow;
                        if (_hasHorizontalOverflow != overflow ||
                            _canScrollHorizontallyLeft != canLeft ||
                            _canScrollHorizontallyRight != canRight) {
                          setState(() {
                            _hasHorizontalOverflow = overflow;
                            _canScrollHorizontallyLeft = canLeft;
                            _canScrollHorizontallyRight = canRight;
                          });
                        }
                      });

                      final double childAspectRatio;
                      if (effectiveCols == 1) {
                        childAspectRatio = isEditMode ? 1.8 : 2.2;
                      } else {
                        childAspectRatio = isEditMode
                            ? (isTablet ? 0.84 : 0.78)
                            : (isTablet ? 1.05 : 0.98);
                      }

                      final double cardLogicalWidth =
                          ((contentWidth - (padding * 2) - ((effectiveCols - 1) * spacing)) /
                                  effectiveCols)
                              .clamp(40.0, 1200.0);

                      final gridView = GridView.builder(
                        key: viewKey,
                        controller: _gridController,
                        cacheExtent: 360,
                        padding: EdgeInsets.fromLTRB(
                          padding,
                          padding,
                          padding,
                          padding + 24,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: effectiveCols,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: totalGridItems,
                        itemBuilder: (context, i) {
                          if (showGridBackCard && i == 0) {
                            return RepaintBoundary(
                              key: const ValueKey('grid_back_navigation_card'),
                              child: _buildBackNavigationCard(
                                isTablet,
                                cardLogicalWidth,
                              ),
                            );
                          }
                          final cardIndex = showGridBackCard ? i - 1 : i;
                          final card = displayedCards[cardIndex];
                          return RepaintBoundary(
                            key: ValueKey(card.id),
                            child: _buildCardWidget(
                              card,
                              isTablet,
                              index: cardIndex,
                              cardLogicalWidth: cardLogicalWidth,
                            ),
                          );
                        },
                      );

                      if (!needsHorizontalScroll) {
                        return gridView;
                      }

                      final scrollbarTrackColor = _isDarkMode
                          ? const Color(0xFF334155).withValues(alpha: 0.60)
                          : const Color(0xFFE2E8F0).withValues(alpha: 0.85);
                      final scrollbarThumbColor = themePrimary;

                      return ScrollbarTheme(
                        data: ScrollbarThemeData(
                          thumbColor: WidgetStateProperty.all(scrollbarThumbColor),
                          trackColor: WidgetStateProperty.all(scrollbarTrackColor),
                          trackBorderColor: WidgetStateProperty.all(Colors.transparent),
                          radius: const Radius.circular(8),
                          thickness: WidgetStateProperty.all(6.0),
                          trackVisibility: WidgetStateProperty.all(true),
                          thumbVisibility: WidgetStateProperty.all(true),
                          crossAxisMargin: 2.0,
                          mainAxisMargin: padding,
                        ),
                        child: Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          interactive: true,
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: SizedBox(
                              width: contentWidth,
                              height: constraints.maxHeight,
                              child: gridView,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCategoryState(bool isTablet, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.surfaceContainerHighest,
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
    );
  }

  Widget _buildEmptyFolderState(bool isTablet, ColorScheme colorScheme) {
    final emptyHeading = currentLanguage == 'si'
        ? 'මෙම ෆෝල්ඩරයේ කාඩ්පත් නැත'
        : (currentLanguage == 'ta'
            ? 'இந்த கோப்புறையில் அட்டைகள் இல்லை'
            : 'No cards in this folder');
    final emptySubtext = currentLanguage == 'si'
        ? 'ආපසු යාමට ආපසු තෝරන්න'
        : (currentLanguage == 'ta'
            ? 'திரும்பிச் செல்ல பின்னே என்பதைத் தேர்ந்தெடுக்கவும்'
            : 'Choose Back to return');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isTablet ? 120 : 96,
            height: isTablet ? 90 : 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.folder_open_rounded,
                  size: isTablet ? 64 : 50,
                  color: const Color(0xFFD97706),
                ),
                Positioned(
                  top: 8,
                  right: 14,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: isTablet ? 20 : 16,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            emptyHeading,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.w800,
              color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: 0.2,
            ),
          ),
          if (!(isPinned && _disableBackCardInPinMode)) ...[
            const SizedBox(height: 6),
            Text(
              emptySubtext,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 15 : 13.5,
                fontWeight: FontWeight.w500,
                color: _isDarkMode
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            _buildBackNavigationCard(
              isTablet,
              isTablet ? 260.0 : 200.0,
              isLarge: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackNavigationCard(
    bool isTablet,
    double cardLogicalWidth, {
    bool isLarge = false,
  }) {
    final backLabel = currentLanguage == 'si'
        ? 'ආපසු'
        : (currentLanguage == 'ta' ? 'පின்னே' : 'Back');

    final bgColor = _isDarkMode
        ? const Color(0xFF134E4A)
        : const Color(0xFFB2F5EA);
    final borderColor = _isDarkMode
        ? const Color(0xFF2DD4BF).withValues(alpha: 0.4)
        : Colors.white;
    final arrowColor = _isDarkMode
        ? const Color(0xFF38BDF8)
        : const Color(0xFF0284C7);
    final textColor = _isDarkMode
        ? Colors.white
        : const Color(0xFF0F172A);

    final arrowSize = isLarge
        ? (isTablet ? 56.0 : 46.0)
        : (isTablet ? 42.0 : 34.0);
    final labelSize = isLarge
        ? (isTablet ? 20.0 : 17.0)
        : (isTablet ? 16.0 : 14.0);

    return Semantics(
      label: '$backLabel, navigate back to parent folder',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey(isLarge ? 'empty_folder_back_card' : 'grid_back_card'),
          onTap: () {
            try {
              HapticFeedback.lightImpact();
            } catch (_) {}
            _navigateBackFromSubCards();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: arrowColor.withValues(alpha: 0.2),
          highlightColor: arrowColor.withValues(alpha: 0.1),
          child: Ink(
            width: isLarge ? (isTablet ? 240.0 : 190.0) : null,
            height: isLarge ? (isTablet ? 170.0 : 130.0) : null,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isDarkMode ? 0.35 : 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isLarge ? 8 : 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: _isDarkMode ? 0.1 : 0.45),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: arrowSize,
                    color: arrowColor,
                  ),
                ),
                SizedBox(height: isLarge ? 8 : 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    backLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFace({
    required AACCard card,
    required bool isTablet,
    required String displayLabel,
    required Color cardSurfaceColor,
    required Color cardTextColor,
    required ColorFilter? cardImageFilter,
    required bool useImageOverlay,
    required bool useLightShadow,
    BoxBorder? border,
    bool isTapAnimated = false,
    bool showMicIcon = true,
    double? cardLogicalWidth,
  }) {
    final cardBorder = border ??
        (highlightedCardId == card.id
            ? Border.all(
                color: _isColorBlindMode
                    ? const Color(0xFF0072B2)
                    : Colors.yellow.shade200,
                width: 3,
              )
            : _isColorBlindMode
                ? Border.all(
                    color: ThemeAccessibility.resolveCardBorderColor(
                      isDarkMode: _isDarkMode,
                      isColorBlindMode: true,
                    ),
                    width: ThemeAccessibility.resolveCardBorderWidth(
                      isColorBlindMode: true,
                    ),
                  )
                : _isDarkMode
                    ? Border.all(color: Colors.white24, width: 1.5)
                    : Border.all(color: Colors.white, width: 3.5));

    final borderRadius = BorderRadius.circular(isTablet ? 20 : 16);

    // Distinct label zone background for Text OFF mode (preserves card outline & external size)
    final labelZoneBg = _isDarkMode
        ? (Color.lerp(cardSurfaceColor, Colors.black, 0.25) ?? cardSurfaceColor)
        : (Color.lerp(cardSurfaceColor, Colors.black, 0.08) ?? cardSurfaceColor);

    final isDefaultFolderCover = card.id == StarterPackService.starterPackRootId &&
        (card.imagePath == null ||
            card.imagePath!.isEmpty ||
            card.imagePath == 'assets/images/starter_pack_v8/starter_default.webp' ||
            card.imagePath == 'assets/home/default_folder_cover.webp');

    final effectiveImagePath = isDefaultFolderCover
        ? 'assets/home/default_folder_cover.webp'
        : card.imagePath;

    final isUserPhoto = effectiveImagePath != null &&
        effectiveImagePath.isNotEmpty &&
        !isAssetImagePath(effectiveImagePath);

    final isHomeChildCard = (card.id == 'seed_hello' ||
            card.id == 'seed_happy' ||
            card.id == 'seed_sad' ||
            card.id == 'seed_angry' ||
            card.id == 'seed_more') &&
        (effectiveImagePath != null &&
            (effectiveImagePath.startsWith('assets/home/') ||
                effectiveImagePath.contains('home/hello') ||
                effectiveImagePath.contains('home/happy') ||
                effectiveImagePath.contains('home/sad') ||
                effectiveImagePath.contains('home/angry') ||
                effectiveImagePath.contains('seed_v2/more') ||
                effectiveImagePath.contains('seed/blocks')));

    final isFullBleedCard =
        isUserPhoto || isDefaultFolderCover || isHomeChildCard;

    // For user-uploaded photographs and full-bleed covers, use a neutral dark/light surface
    // behind the photo and neutral shadows, so no bright card background colors peek through.
    final effectiveBgColor = isFullBleedCard
        ? (_isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
        : cardSurfaceColor;

    final effectiveShadowColor = isTapAnimated
        ? (_isColorBlindMode
            ? Colors.black.withValues(alpha: _isDarkMode ? 0.55 : 0.28)
            : isFullBleedCard
                ? Colors.black.withValues(alpha: _isDarkMode ? 0.60 : 0.35)
                : Color(StarterPackService.resolveCardColorValue(card))
                    .withValues(alpha: _isDarkMode ? 0.60 : 0.40))
        : Colors.black.withValues(alpha: _isDarkMode ? 0.30 : 0.08);

    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;

    return AnimatedScale(
      scale: isTapAnimated ? 1.08 : 1.0,
      duration: Duration(milliseconds: isTapAnimated ? 110 : 160),
      curve: isTapAnimated ? Curves.easeOutBack : Curves.easeInOut,
      child: AnimatedContainer(
        duration: Duration(milliseconds: isTapAnimated ? 110 : 160),
        decoration: BoxDecoration(
          color: effectiveBgColor,
          borderRadius: borderRadius,
          border: cardBorder,
          boxShadow: [
            BoxShadow(
              color: effectiveShadowColor,
              blurRadius: isTapAnimated ? 18 : 10,
              spreadRadius: isTapAnimated ? 2 : 1,
              offset: isTapAnimated ? const Offset(0, 8) : const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isTablet ? 17 : 13),
          child: Stack(
            children: [
              if (isFullBleedCard && effectiveImagePath != null) ...[
                // Full-bleed cover (user photograph or Default folder cover): Fills entire card face with BoxFit.cover
                Positioned.fill(
                  child: buildCardImage(
                    effectiveImagePath,
                    fit: BoxFit.cover,
                    targetLogicalWidth: cardLogicalWidth,
                    devicePixelRatio: dpr,
                    colorFilter: cardImageFilter,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.white70,
                        ),
                      );
                    },
                  ),
                ),
                // Gradient overlay at bottom for readable label
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      6,
                      isTablet ? 26 : 20,
                      6,
                      isTablet ? 10 : 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.40),
                          Colors.black.withOpacity(0.78),
                        ],
                        stops: const [0.0, 0.40, 1.0],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (card.subCards.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.60),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${card.subCards.length} ${card.subCards.length == 1 ? "sub-card" : "sub-cards"}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      (isTablet ? 11 : 9.5) * _cardTextScale,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayLabel,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      (isTablet ? 19 : 15) * _cardTextScale,
                                  fontWeight: FontWeight.bold,
                                  shadows: const [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black,
                                      offset: Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                              ),
                              if (card.type == 'folder' ||
                                  card.subCards.isNotEmpty) ...[
                                const SizedBox(width: 5),
                                Container(
                                  width: (isTablet ? 22 : 18) * _cardTextScale,
                                  height:
                                      (isTablet ? 22 : 18) * _cardTextScale,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.60),
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: (isTablet ? 13 : 11) *
                                        _cardTextScale,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Standard presentation for Starter Pack illustrations, default seed assets & icon/folder cards
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Upper Image Area (76% of card height) - unclipped, BoxFit.contain
                    Expanded(
                      flex: 76,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? 4.0 : 2.0,
                          isTablet ? 6.0 : 4.0,
                          isTablet ? 4.0 : 2.0,
                          0.0,
                        ),
                        child: Center(
                          child: card.imagePath != null
                              ? buildCardImage(
                                  card.imagePath!,
                                  fit: BoxFit.contain,
                                  targetLogicalWidth: cardLogicalWidth,
                                  devicePixelRatio: dpr,
                                  colorFilter: cardImageFilter,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 48,
                                        color: Colors.white70,
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Icon(
                                    card.isFolder ? Icons.folder_rounded : Icons.image,
                                    size: isTablet ? 64 : 48,
                                    color: Colors.white70,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Lower Label Area (24% of card height) - ON: continuous; OFF: distinct deeper container
                    Expanded(
                      flex: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: useImageOverlay ? Colors.transparent : labelZoneBg,
                          border: useImageOverlay
                              ? null
                              : Border(
                                  top: BorderSide(
                                    color: _isDarkMode
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.06),
                                    width: 1.0,
                                  ),
                                ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (card.subCards.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${card.subCards.length} ${card.subCards.length == 1 ? "sub-card" : "sub-cards"}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          (isTablet ? 11 : 9.5) * _cardTextScale,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    displayLabel,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: cardTextColor,
                                      fontSize:
                                          (isTablet ? 19 : 15) * _cardTextScale,
                                      fontWeight: _isColorBlindMode &&
                                              ThemeAccessibility
                                                  .colorBlindBoldText
                                          ? FontWeight.w900
                                          : FontWeight.bold,
                                      shadows: useImageOverlay
                                          ? (_isColorBlindMode &&
                                                  ThemeAccessibility
                                                      .colorBlindBoldText
                                              ? ThemeAccessibility
                                                  .resolveCardTextShadow(
                                                  cardSurface: Colors.black54,
                                                  isColorBlindMode: true,
                                                )
                                              : const [
                                                  Shadow(
                                                    blurRadius: 4,
                                                    color: Colors.black45,
                                                    offset: Offset(0, 1.5),
                                                  ),
                                                ])
                                          : ((_isColorBlindMode &&
                                                  ThemeAccessibility
                                                      .colorBlindBoldText)
                                              ? ThemeAccessibility
                                                  .resolveCardTextShadow(
                                                  cardSurface: cardSurfaceColor,
                                                  isColorBlindMode:
                                                      _isColorBlindMode,
                                                )
                                              : (useLightShadow
                                                  ? const [
                                                      Shadow(
                                                        blurRadius: 3,
                                                        color: Colors.black26,
                                                        offset: Offset(0, 1),
                                                      ),
                                                    ]
                                                  : null)),
                                    ),
                                  ),
                                  if (card.type == 'folder' ||
                                      card.subCards.isNotEmpty) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      width: (isTablet ? 22 : 18) * _cardTextScale,
                                      height:
                                          (isTablet ? 22 : 18) * _cardTextScale,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.55),
                                        shape: BoxShape.circle,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        size:
                                            (isTablet ? 13 : 11) * _cardTextScale,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (showMicIcon && card.voicePath != null)
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardWidget(
    AACCard card,
    bool isTablet, {
    int index = 0,
    double? cardLogicalWidth,
  }) {
    final cardKey = _cardKeys.putIfAbsent(card.id, () => GlobalKey());
    TutorialService.instance.registerKey('aac_card_${card.id}', cardKey);
    final displayed = _getDisplayedCards();
    if (displayed.isNotEmpty && card.id == displayed.first.id) {
      TutorialService.instance.registerKey('aac_first_card', cardKey);
    }

    final displayLabel = card.getLabel(currentLanguage);
    final isTapAnimated = _tapAnimatedCardId == card.id;
    final useImageOverlay = _useImageOverlayLabel && card.imagePath != null;
    final effectiveColorValue = StarterPackService.resolveCardColorValue(card);
    final cardSurfaceColor = ThemeAccessibility.resolveCardSurface(
      Color(effectiveColorValue),
      isDarkMode: _isDarkMode,
      isColorBlindMode: _isColorBlindMode,
    );
    final cardTextColor = useImageOverlay
        ? (_applyTextColorToCards ? Color(_cardTextColor) : Colors.white)
        : ThemeAccessibility.resolveCardTextColor(
            cardSurfaceColor,
            isDarkMode: _isDarkMode,
            isColorBlindMode: _isColorBlindMode,
            applyCustomTextColor: _applyTextColorToCards,
            customTextColor: Color(_cardTextColor),
          );
    final useLightShadow = cardTextColor.computeLuminance() > 0.5;
    final cardImageFilter = ThemeAccessibility.resolveCardImageFilter(
      isColorBlindMode: _isColorBlindMode,
    );

    final cardFace = GestureDetector(
      key: cardKey,
      onTap: () {
        if (TutorialService.instance.currentStepNotifier.value ==
            TutorialStepType.testNewCard) {
          setState(() {
            isEditMode = false;
          });
          _triggerWordTapAnimation(card.id);
          if (card.type == 'folder' || card.subCards.isNotEmpty) {
            _showSubCards(card);
            unawaited(_speakOrPlayCard(card, displayLabel));
          } else {
            _appendToTtsInput(
              displayLabel,
              imagePath: card.imagePath,
              voicePath: card.voicePath,
            );
            unawaited(_speakOrPlayCard(card, displayLabel));
          }
          TutorialService.instance.notifyNewCardTapped(card.id);
          return;
        }
        TutorialService.instance.notifyNewCardTapped(card.id);
        if (isEditMode) {
          if (card.type == 'folder' || card.subCards.isNotEmpty) {
            _showSubCards(card);
            return;
          } else {
            _editCard(card);
            return;
          }
        }
        _triggerWordTapAnimation(card.id);
        if (card.type == 'folder' || card.subCards.isNotEmpty) {
          _showSubCards(card);
          unawaited(_speakOrPlayCard(card, displayLabel));
          return;
        }

        _appendToTtsInput(
          displayLabel,
          imagePath: card.imagePath,
          voicePath: card.voicePath,
        );
        unawaited(_speakOrPlayCard(card, displayLabel));
      },
      child: _buildCardFace(
        card: card,
        isTablet: isTablet,
        displayLabel: displayLabel,
        cardSurfaceColor: cardSurfaceColor,
        cardTextColor: cardTextColor,
        cardImageFilter: cardImageFilter,
        useImageOverlay: useImageOverlay,
        useLightShadow: useLightShadow,
        isTapAnimated: isTapAnimated,
        cardLogicalWidth: cardLogicalWidth,
      ),
    );

    if (isEditMode) {
      final isSingleCol = gridColumns.clamp(1, 30) == 1;
      final isVirtualCategoryView =
          _isCategoryFiltered && activeParentCard == null;
      return _DragAndDropCardItem(
        key: ValueKey('drag_item_${card.id}'),
        card: card,
        index: index,
        isTablet: isTablet,
        isSingleColumn: isSingleCol,
        isEditMode: isEditMode,
        cardSurfaceColor: cardSurfaceColor,
        cardTextColor: cardTextColor,
        currentLanguage: currentLanguage,
        onReorder: isVirtualCategoryView ? null : _handleReorderCard,
        onMoveInside:
            isVirtualCategoryView ? null : _requestNestingConfirmation,
        onAutoScroll: _checkAutoScroll,
        onStopAutoScroll: _stopAutoScroll,
        isDescendant: _isDescendantOf,
        contentOnly: _buildCardContentOnly(
          card,
          isTablet,
          displayLabel,
          cardSurfaceColor,
          cardTextColor,
          cardImageFilter,
          useImageOverlay,
          useLightShadow,
          cardLogicalWidth: cardLogicalWidth,
        ),
        onEdit: () => _editCard(card),
        onDelete: () => _confirmDelete(card),
        child: cardFace,
      );
    }
    return cardFace;
  }

  Widget _buildCardContentOnly(
    AACCard card,
    bool isTablet,
    String displayLabel,
    Color cardSurfaceColor,
    Color cardTextColor,
    ColorFilter? cardImageFilter,
    bool useImageOverlay,
    bool useLightShadow, {
    double? cardLogicalWidth,
  }) {
    return _buildCardFace(
      card: card,
      isTablet: isTablet,
      displayLabel: displayLabel,
      cardSurfaceColor: cardSurfaceColor,
      cardTextColor: cardTextColor,
      cardImageFilter: cardImageFilter,
      useImageOverlay: useImageOverlay,
      useLightShadow: useLightShadow,
      border: Border.all(color: Colors.transparent),
      showMicIcon: false,
      cardLogicalWidth: cardLogicalWidth,
    );
  }

  void _closeDrawerIfOpen() {
    if (_isDrawerExpanded) {
      setState(() => _isDrawerExpanded = false);
    }
    _scaffoldKey.currentState?.closeEndDrawer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (_scaffoldKey.currentState?.isEndDrawerOpen ?? false)) {
        _scaffoldKey.currentState?.closeEndDrawer();
      }
    });
  }

  void _handleTutorialStepChanged() {
    if (!mounted) return;
    final step = TutorialService.instance.currentStepNotifier.value;
    if (step == null) {
      _closeDrawerIfOpen();
      return;
    }

    switch (step) {
      case TutorialStepType.openMenu:
        _closeDrawerIfOpen();
        break;
      case TutorialStepType.drawerExplore:
        if (!(_scaffoldKey.currentState?.isEndDrawerOpen ?? false)) {
          _scaffoldKey.currentState?.openEndDrawer();
        }
        break;
      case TutorialStepType.enableEditMode:
        if (!(_scaffoldKey.currentState?.isEndDrawerOpen ?? false)) {
          _scaffoldKey.currentState?.openEndDrawer();
        }
        break;
      case TutorialStepType.addNewCard:
        _closeDrawerIfOpen();
        if (!isEditMode) {
          _enterEditMode();
        }
        break;
      case TutorialStepType.chooseMedia:
      case TutorialStepType.multilingualLabels:
      case TutorialStepType.voiceRecording:
      case TutorialStepType.saveCard:
      case TutorialStepType.testNewCard:
      case TutorialStepType.completed:
        _closeDrawerIfOpen();
        break;
    }
  }

  void _handleHorizontalScroll() {
    if (!_horizontalScrollController.hasClients) return;
    final pos = _horizontalScrollController.position;
    final overflow = pos.maxScrollExtent > pos.minScrollExtent + 1.0;
    final canLeft = pos.pixels > pos.minScrollExtent + 1.0;
    final canRight = pos.pixels < pos.maxScrollExtent - 1.0;
    if (_hasHorizontalOverflow != overflow ||
        _canScrollHorizontallyLeft != canLeft ||
        _canScrollHorizontallyRight != canRight) {
      if (mounted) {
        setState(() {
          _hasHorizontalOverflow = overflow;
          _canScrollHorizontallyLeft = canLeft;
          _canScrollHorizontallyRight = canRight;
        });
      }
    }
  }

  @override
  void dispose() {
    _startupLoadingTimer?.cancel();
    _stopAutoScroll();
    TutorialService.instance.currentStepNotifier
        .removeListener(_handleTutorialStepChanged);
    _highlightTimer?.cancel();
    _tapAnimTimer?.cancel();
    unawaited(SpeechEngine.instance.stop());
    _audioPlayer.dispose();
    _gridController.dispose();
    _horizontalScrollController.removeListener(_handleHorizontalScroll);
    _horizontalScrollController.dispose();
    super.dispose();
  }
}

class _DragAndDropCardItem extends StatefulWidget {
  final AACCard card;
  final int index;
  final bool isTablet;
  final bool isSingleColumn;
  final bool isEditMode;
  final Color cardSurfaceColor;
  final Color cardTextColor;
  final String currentLanguage;
  final void Function(AACCard dragged, AACCard target, {required bool insertAfter})? onReorder;
  final void Function(AACCard dragged, AACCard target)? onMoveInside;
  final void Function(Offset globalPosition) onAutoScroll;
  final VoidCallback onStopAutoScroll;
  final bool Function(AACCard potentialDescendant, AACCard ancestor) isDescendant;
  final Widget contentOnly;
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DragAndDropCardItem({
    super.key,
    required this.card,
    required this.index,
    required this.isTablet,
    required this.isSingleColumn,
    required this.isEditMode,
    required this.cardSurfaceColor,
    required this.cardTextColor,
    required this.currentLanguage,
    this.onReorder,
    this.onMoveInside,
    required this.onAutoScroll,
    required this.onStopAutoScroll,
    required this.isDescendant,
    required this.contentOnly,
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DragAndDropCardItem> createState() => _DragAndDropCardItemState();
}

class _DragAndDropCardItemState extends State<_DragAndDropCardItem> {
  CardDropHoverState _hoverState = CardDropHoverState.none;
  bool _isDragging = false;

  Widget _buildFeedback() {
    return Material(
      color: Colors.transparent,
      child: Transform.rotate(
        angle: -0.04, // subtle -2.3° tilt
        child: SizedBox(
          width: widget.isTablet ? 200 : 160,
          height: widget.isTablet ? 200 : 160,
          child: Container(
            decoration: BoxDecoration(
              color: widget.cardSurfaceColor,
              borderRadius: BorderRadius.circular(widget.isTablet ? 20 : 16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: const Color(0xFF00E5FF),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.isTablet ? 19 : 15),
              child: widget.contentOnly,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTray() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = widget.isTablet;

    return Container(
      height: isTablet ? 38 : 32,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Drag Handle (Immediate Draggable)
          Expanded(
            child: widget.onReorder != null
                ? Draggable<DraggedCardData>(
                    key: ValueKey('card_drag_handle_${widget.card.id}'),
                    data: DraggedCardData(
                        card: widget.card, sourceIndex: widget.index),
                    onDragStarted: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _isDragging = true);
                    },
                    onDragUpdate: (details) {
                      widget.onAutoScroll(details.globalPosition);
                    },
                    onDragEnd: (_) {
                      widget.onStopAutoScroll();
                      setState(() => _isDragging = false);
                    },
                    onDraggableCanceled: (_, __) {
                      widget.onStopAutoScroll();
                      setState(() => _isDragging = false);
                    },
                    onDragCompleted: () {
                      widget.onStopAutoScroll();
                      setState(() => _isDragging = false);
                    },
                    feedback: _buildFeedback(),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: Center(
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color:
                              isDark ? Colors.white54 : const Color(0xFF64748B),
                          size: isTablet ? 20 : 17,
                        ),
                      ),
                    ),
                    child: Tooltip(
                      message: 'Drag to reorder',
                      child: Center(
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF64748B),
                          size: isTablet ? 20 : 17,
                        ),
                      ),
                    ),
                  )
                : Tooltip(
                    message: 'Reordering disabled in category views',
                    child: Center(
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color:
                            isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        size: isTablet ? 20 : 17,
                      ),
                    ),
                  ),
          ),
          // Divider
          Container(
            width: 1,
            height: isTablet ? 18 : 14,
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
          // 2. Edit Pencil
          Expanded(
            child: IconButton(
              key: ValueKey('card_edit_pencil_${widget.card.id}'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.edit_rounded,
                color: const Color(0xFF1E88E5),
                size: isTablet ? 18 : 15,
              ),
              tooltip: 'Edit Card',
              onPressed: widget.onEdit,
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: isTablet ? 18 : 14,
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
          // 3. Delete Button
          Expanded(
            child: IconButton(
              key: ValueKey('card_delete_btn_${widget.card.id}'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: const Color(0xFFE53935),
                size: isTablet ? 18 : 15,
              ),
              tooltip: 'Delete',
              onPressed: widget.onDelete,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditMode) {
      return widget.child;
    }

    return DragTarget<DraggedCardData>(
      onWillAcceptWithDetails: (details) {
        if (widget.onReorder == null || widget.onMoveInside == null) return false;
        final dragged = details.data.card;
        if (dragged.id == widget.card.id) return false;
        // Don't accept if target is a descendant of dragged
        if (widget.isDescendant(widget.card, dragged)) return false;
        return true;
      },
      onMove: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        final size = renderBox.size;
        final dragCenter = details.offset + Offset(size.width / 2, size.height / 2);
        final localPos = renderBox.globalToLocal(dragCenter);

        // Central region (middle 70% of card) is moveInside
        final horizontalInset = size.width * 0.15;
        final verticalInset = size.height * 0.15;
        final centerRect = Rect.fromLTRB(
          horizontalInset,
          verticalInset,
          size.width - horizontalInset,
          size.height - verticalInset,
        );

        CardDropHoverState newState;
        if (centerRect.contains(localPos)) {
          newState = CardDropHoverState.moveInside;
        } else {
          // If in single column (vertical list), split top vs bottom half
          // If in multi-column grid, split left vs right
          if (widget.isSingleColumn) {
            newState = localPos.dy < size.height / 2
                ? CardDropHoverState.reorderBefore
                : CardDropHoverState.reorderAfter;
          } else {
            newState = localPos.dx < size.width / 2
                ? CardDropHoverState.reorderBefore
                : CardDropHoverState.reorderAfter;
          }
        }

        if (newState != _hoverState) {
          setState(() => _hoverState = newState);
        }
      },
      onLeave: (data) {
        if (_hoverState != CardDropHoverState.none) {
          setState(() => _hoverState = CardDropHoverState.none);
        }
      },
      onAcceptWithDetails: (details) {
        widget.onStopAutoScroll();
        final dragged = details.data.card;
        final currentHover = _hoverState;
        setState(() => _hoverState = CardDropHoverState.none);

        if (dragged.id == widget.card.id) return;

        if (currentHover == CardDropHoverState.moveInside) {
          widget.onMoveInside?.call(dragged, widget.card);
        } else if (currentHover == CardDropHoverState.reorderBefore) {
          widget.onReorder?.call(dragged, widget.card, insertAfter: false);
        } else if (currentHover == CardDropHoverState.reorderAfter) {
          widget.onReorder?.call(dragged, widget.card, insertAfter: true);
        } else {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final size = renderBox.size;
            final dragCenter = details.offset + Offset(size.width / 2, size.height / 2);
            final localPos = renderBox.globalToLocal(dragCenter);
            final horizontalInset = size.width * 0.15;
            final verticalInset = size.height * 0.15;
            final centerRect = Rect.fromLTRB(
              horizontalInset,
              verticalInset,
              size.width - horizontalInset,
              size.height - verticalInset,
            );
            if (centerRect.contains(localPos)) {
              widget.onMoveInside?.call(dragged, widget.card);
            } else if (localPos.dx < size.width / 2) {
              widget.onReorder?.call(dragged, widget.card, insertAfter: false);
            } else {
              widget.onReorder?.call(dragged, widget.card, insertAfter: true);
            }
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty && _hoverState != CardDropHoverState.none;
        final canDrag = widget.onReorder != null;

        final draggableCardFace = canDrag
            ? LongPressDraggable<DraggedCardData>(
                data: DraggedCardData(card: widget.card, sourceIndex: widget.index),
                delay: const Duration(milliseconds: 300),
                hapticFeedbackOnStart: true,
                onDragStarted: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _isDragging = true);
                },
                onDragUpdate: (details) {
                  widget.onAutoScroll(details.globalPosition);
                },
                onDragEnd: (_) {
                  widget.onStopAutoScroll();
                  setState(() => _isDragging = false);
                },
                onDraggableCanceled: (_, __) {
                  widget.onStopAutoScroll();
                  setState(() => _isDragging = false);
                },
                onDragCompleted: () {
                  widget.onStopAutoScroll();
                  setState(() => _isDragging = false);
                },
                feedback: _buildFeedback(),
                childWhenDragging: Opacity(
                  opacity: 0.35,
                  child: widget.child,
                ),
                child: Opacity(
                  opacity: _isDragging ? 0.35 : 1.0,
                  child: widget.child,
                ),
              )
            : widget.child;

        final actionTray = _buildActionTray();

        final tile = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: draggableCardFace),
            const SizedBox(height: 5),
            actionTray,
          ],
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            tile,
            if (isHovered && _hoverState == CardDropHoverState.moveInside)
              _buildMoveInsideOverlay(),
            if (isHovered && _hoverState == CardDropHoverState.reorderBefore)
              _buildInsertionLine(isBefore: true),
            if (isHovered && _hoverState == CardDropHoverState.reorderAfter)
              _buildInsertionLine(isBefore: false),
          ],
        );
      },
    );
  }

  Widget _buildMoveInsideOverlay() {
    final targetLabel = widget.card.getLabel(widget.currentLanguage);
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.isTablet ? 20 : 16),
          border: Border.all(
            color: const Color(0xFF00E5FF),
            width: 3.5,
          ),
          color: const Color(0xFF00E5FF).withOpacity(0.12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.4),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xF00F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00E5FF),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_open_rounded,
                color: Color(0xFF00E5FF),
                size: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Move inside $targetLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsertionLine({required bool isBefore}) {
    if (widget.isSingleColumn) {
      return Positioned(
        top: isBefore ? -3 : null,
        bottom: isBefore ? null : -3,
        left: 4,
        right: 4,
        child: Container(
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.8),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      );
    } else {
      return Positioned(
        top: 4,
        bottom: 4,
        left: isBefore ? -3 : null,
        right: isBefore ? null : -3,
        child: Container(
          width: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.8),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _NestingConfirmationDialog extends StatelessWidget {
  final AACCard draggedCard;
  final AACCard targetCard;
  final bool isTargetFolder;
  final String currentLanguage;

  const _NestingConfirmationDialog({
    required this.draggedCard,
    required this.targetCard,
    required this.isTargetFolder,
    required this.currentLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final draggedLabel = draggedCard.getLabel(currentLanguage);
    final targetLabel = targetCard.getLabel(currentLanguage);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: StyledDialogHeader(
        icon: Icons.create_new_folder_rounded,
        title: isTargetFolder ? 'Add as Sub-Card?' : 'Convert to Folder & Add?',
        accentColor: const Color(0xFF0284C7),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCardPreview(draggedCard, draggedLabel, isDark),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF0284C7),
                  size: 26,
                ),
                _buildCardPreview(targetCard, targetLabel, isDark,
                    isFolder: isTargetFolder),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isTargetFolder
                ? 'Add "$draggedLabel" as a sub-card inside "$targetLabel"?'
                : '"$targetLabel" is currently a Word Card. Adding "$draggedLabel" inside it will convert it into a Folder Card.\n\nDo you want to continue?',
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        TextButton(
          key: const ValueKey('nesting_dialog_cancel_btn'),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('nesting_dialog_confirm_btn'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(isTargetFolder ? 'Add as Sub-Card' : 'Convert & Add'),
        ),
      ],
    );
  }

  Widget _buildCardPreview(
    AACCard card,
    String label,
    bool isDark, {
    bool isFolder = false,
  }) {
    final cardColor = Color(StarterPackService.resolveCardColorValue(card));

    return Container(
      width: 76,
      height: 86,
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
                      targetLogicalWidth: 76,
                    )
                  : Container(
                      color: cardColor,
                      child: Center(
                        child: Icon(
                          isFolder ? Icons.folder_rounded : Icons.image,
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
}

