# Technical Evidence Report: Application Feature Audit

**Document:** `01_Application_Feature_Evidence.md`  
**Project:** Simple AAC (Sri Lanka)  
**Package Identifier:** `lk.yasas.simpleaac`  
**Inspected Application Version:** `1.1.4+12` (Version 1.1.4, Build 12)  
**Repository Working Tree Branch:** `main` (Git commit `98ccc45`)  
**Target Audience:** Medical Student Research Leads (J.G.D. Thamalka, D.V.W. Gunawardana), Co-Investigator (Dr. Gayani Punchihewa, Senior Lecturer & Psychiatrist), and Technical Collaborator / Developer (Yasas Pasindu Fernando).  
**Document Purpose:** Grounded, code-level technical feature verification to inform the prospective feasibility study protocol and ethics evaluation.

---

## 1. Classification Framework

Every identified capability is categorised using one of the following strict status labels:
- **`IMPLEMENTED`**: Fully present and functional in the application source code.
- **`PARTIALLY IMPLEMENTED`**: Core code exists, but functionality is constrained, relies on manual workarounds, or lacks completeness.
- **`NOT IMPLEMENTED`**: No source code, UI, or dedicated logic exists in the repository.
- **`NOT VERIFIED`**: Code is present, but functionality has not been verified on target hardware or requires specific device conditions.
- **`REQUIRES CLINICAL ASSESSMENT`**: Functionality is technically present, but its therapeutic suitability, clinical safety, or cognitive appropriateness for children with Autism Spectrum Disorder (ASD) can only be established through clinical investigation.
- **`REQUIRES TEAM CONFIRMATION`**: Implementation details or historical decisions that require formal sign-off from the medical student research leads and psychiatrist.

---

## 2. Feature-by-Feature Technical Evidence

### A. Picture-Based Communication (AAC Core)

#### 1. Picture Communication Cards (Grid Layout)
- **Status:** `IMPLEMENTED` / `REQUIRES CLINICAL ASSESSMENT`
- **File Reference:** `lib/models/aac_card_model.dart` (Lines 1–78), `lib/pages/home_page.dart` (Lines 1450–1620), `lib/widgets/aac_card_widget.dart`
- **Technical Operation:** Cards are rendered as visual tiles in a scrollable `GridView`. Each card stores a unique `id`, primary text `label` (English), optional local language labels (`labelSinhala`, `labelTamil`), an image reference (`imagePath`), an optional recorded audio path (`voicePath`), an associated `category`, an integer colour value (`colorValue`), and an item type (`'word'` or `'folder'`).
- **Medical Relevance for ASD:** Provides visual graphic representations to support individuals with limited or absent speech in expressing basic needs, objects, and concepts through direct selection (pointing or tapping).
- **Verification Limitations:** Tested on an Android 16 physical device (Samsung Galaxy A34 5G) and through widget tests (`test/widget_test.dart`). However, physical motor accessibility, visual clarity of icons, and cognitive comprehension among children with ASD require formal clinical observation.

#### 2. Folders and Sub-Cards (Hierarchical Navigation)
- **Status:** `IMPLEMENTED` / `REQUIRES CLINICAL ASSESSMENT`
- **File Reference:** `lib/models/aac_card_model.dart` (Lines 10, 24, 35, 40–45, 57–59), `lib/pages/home_page.dart` (Lines 1320–1360), `lib/screens/sub_card_page.dart`
- **Technical Operation:** Cards configured with `type: 'folder'` store a recursive list of child cards in `subCards: List<AACCard>`. Tapping a folder card opens a dedicated sub-card view displaying its nested items, with a back navigation arrow returning to the parent level.
- **Medical Relevance for ASD:** Enables categorised organisation of vocabulary (e.g., nesting "Milk", "Water", and "Juice" under a "Drinks" folder), reducing initial visual clutter on the home board.
- **Verification Limitations:** Navigation depth is theoretically unlimited, but nested navigation may pose cognitive working memory challenges or cause navigation disorientation for young children with ASD. This transition requires clinical usability evaluation.

#### 3. Sentence Bar / Communication Strip (Multi-Card Combination)
- **Status:** `IMPLEMENTED` / `REQUIRES CLINICAL ASSESSMENT`
- **File Reference:** `lib/widgets/tts_bar.dart` (Lines 6–249), `lib/pages/home_page.dart` (Lines 1380–1430), `lib/models/tts_token.dart`
- **Technical Operation:** When `showTtsInput` is enabled, a persistent horizontal bar (`TtsBar`) sits above the main card grid. Tapping a card appends a `TtsToken` containing the card's image thumbnail, localized label, and audio path to a horizontally scrollable sequence. The user can press a speaker button to speak the full multi-card utterance in order, delete the last token, or clear the entire bar.
- **Medical Relevance for ASD:** Mirrors the physical PECS (Picture Exchange Communication System) sentence strip, allowing children to move beyond single-word requesting towards combining concepts into multi-word phrases (e.g., "I want" + "Water").
- **Verification Limitations:** Verified on physical hardware and in automated tests (`test/widget_test.dart`, `test/settings_live_preview_dialogs_test.dart`). Whether children with ASD can independently sequence cards on a touchscreen requires structured clinical evaluation.

#### 4. Multi-Category Filtering ("Choose Categories")
- **Status:** `IMPLEMENTED`
- **File Reference:** `lib/widgets/select_category_dialog.dart` (Lines 21–414), `lib/models/category_metadata.dart` (Lines 1–130), `lib/pages/home_page.dart` (Lines 94–105)
- **Technical Operation:** Caregivers or users can filter the home board by one or more categories simultaneously. The dialog presents checkboxes for all available categories alongside an "All Cards" option (mutually exclusive with individual selections). A live board preview shows selected category chips and card thumbnails. The board displays the mathematical union of unique cards belonging to all selected categories, preventing duplicates.
- **Medical Relevance for ASD:** Allows a caregiver or therapist to restrict the visible environment to situation-specific cards (e.g., only "Food" and "Feelings" during lunchtime), reducing sensory distraction.
- **Verification Limitations:** Software logic verified on a physical Samsung Galaxy A34 5G and automated in `test/select_category_dialog_test.dart`.

#### 5. Card Creation, Editing, and Deletion
- **Status:** `IMPLEMENTED`
- **File Reference:** `lib/widgets/card_editor_dialog.dart` (Lines 25–950), `lib/services/card_storage_service.dart` (Lines 210–380)
- **Technical Operation:** Users can create custom cards or edit existing ones. The editor supports capturing pictures from the camera, selecting from the device gallery, picking animated GIFs, recording custom voice audio, specifying trilingual labels (English, Sinhala, Tamil), picking custom card colours, and assigning categories.
- **Medical Relevance for ASD:** Allows personalisation of communication stimuli using familiar household objects, family members, and local food items, which is recognized as important in ASD interventions.
- **Verification Limitations:** Verified in automated tests (`test/card_editor_dialog_test.dart`) and manual device testing.

---

### B. Visual Communication Support

#### 1. Dedicated Visual Schedules
- **Status:** `NOT IMPLEMENTED`
- **File Reference:** None (Grep confirmation across `lib/`: zero matches for visual schedule workflows).
- **Technical Operation:** There is no dedicated schedule engine, linear time-ordered task checklist, routine timer, or visual check-off interface.
- **Medical Relevance for ASD:** Visual schedules are standard clinical supports for helping autistic children predict upcoming transitions and reduce transition-related anxiety.
- **Alternative / Workaround:** A caregiver could manually create a folder named "Schedule" and insert sequenced cards (e.g., "Brush Teeth", "Breakfast", "School"), but the application provides no formal scheduling logic or completed-task dimming.
- **Clinical Implication:** The research team must not claim that the application contains a visual scheduling feature.

#### 2. First–Then Boards
- **Status:** `NOT IMPLEMENTED`
- **File Reference:** None.
- **Technical Operation:** No two-part "First [Demand] / Then [Reward]" structured layout exists in the code.
- **Medical Relevance for ASD:** First–Then contingencies are commonly used in behavioural and communication interventions to motivate completion of non-preferred tasks.
- **Clinical Implication:** Must be documented as an absent feature that could be investigated as a future requirement during the feasibility study.

#### 3. Social Stories and Visual Instructional Narratives
- **Status:** `NOT IMPLEMENTED`
- **File Reference:** None.
- **Technical Operation:** No multi-page narrative reader, book layout, or visual story tool is implemented.
- **Clinical Implication:** Must be excluded from descriptions of current application capabilities.

---

### C. Emotional Communication

#### 1. Emotion and Feeling Communication Cards
- **Status:** `IMPLEMENTED` / `REQUIRES CLINICAL ASSESSMENT`
- **File Reference:** `lib/data/default_seed_cards.dart` (Lines 41–63), `lib/models/category_metadata.dart` (Line 26, Preset "Feelings")
- **Technical Operation:** The application includes a pre-configured "Feelings" category with seed cards for "Happy" (සතුටුයි / மகிழ்ச்சி), "Sad" (දුකයි / சோகம்), and "Angry" (තරහයි / கோபம்). Users can add custom emotion cards (e.g., "Tired", "Pain", "Scared") with images and voice notes.
- **Medical Relevance for ASD:** Supports the expression of internal emotional states and discomfort, which can help mitigate frustration and communicative meltdowns in minimally verbal children.
- **Verification Limitations:** Present in software and verified on device. Clinical appropriateness of visual emotion symbols for children with varying cognitive levels requires clinician assessment.

#### 2. Automatic Facial-Expression Recognition / Emotion AI
- **Status:** `NOT IMPLEMENTED` (Intentionally Excluded)
- **File Reference:** `android/app/src/main/kotlin/com/example/simple_aac_app/MainActivity.kt` (Lines 18–26, 48–65), `lib/utils/camera_object_helper.dart` (Lines 69–120)
- **Technical Operation:** The application incorporates Google ML Kit vision libraries (`ImageLabeler`, `ObjectDetector`). These are used strictly to identify inanimate physical objects in camera photos (e.g., identifying a "cup" or "bottle" to auto-suggest a card name). No facial landmark detection, emotion classification, or affective computing models exist in the code.
- **Clinical Implication:** The research protocol must clearly state that emotional communication is user-directed through picture cards, with zero automated facial analysis.

---

### D. Speech Output and Audio Support

#### 1. Device Text-to-Speech (TTS) Engine Integration
- **Status:** `IMPLEMENTED` / `NOT VERIFIED` (Hardware/Voice Dependent)
- **File Reference:** `lib/services/speech_engine.dart` (Lines 69–488), `lib/utils/multilingual_speech_router.dart` (Lines 23–268), `android/app/src/main/AndroidManifest.xml` (Lines 56–60)
- **Technical Operation:** Uses the Flutter `flutter_tts` plugin communicating with Android's underlying `TextToSpeech` service. Speech rate is calibrated to a steady pace (`0.5`), with pitch at `1.0`. The `AndroidManifest.xml` declares `<intent><action android:name="android.intent.action.TTS_SERVICE" /></intent>` to query installed system speech engines.
- **Medical Relevance for ASD:** Provides clear, audible spoken feedback when a card or sentence is selected, bridging non-verbal selection and spoken auditory communication.
- **Verification Limitations:** The application requests speech output for specified locales (`en-US`, `si-LK`, `ta-IN`). However, actual spoken output depends entirely on whether the physical Android device has compatible voice data installed (e.g., Google Speech Services). If a voice engine lacks Sinhala or Tamil acoustic models, speech output may fail or fall back silently. A non-blocking diagnostic tool (`SpeechCapabilityReport`) exists in the settings drawer to inspect voice engine readiness.

#### 2. Recorded Custom Audio (Caregiver / Child Voice)
- **Status:** `IMPLEMENTED`
- **File Reference:** `lib/widgets/card_editor_dialog.dart` (Lines 110–135, 480–620), `lib/pages/home_page.dart` (Lines 350–390), `pubspec.yaml` (Dependencies `record: ^5.0.1`, `audioplayers: ^5.2.0`)
- **Technical Operation:** When editing a card, a user can record custom audio via the device microphone. The recording is saved locally as an `.m4a` audio file in the app's documents directory. When the card is selected, the application plays the recorded audio via `AudioPlayer`. If recorded audio is present, it takes priority over synthetic TTS.
- **Medical Relevance for ASD:** Allows parents or therapists to record familiar family voices, dialect-appropriate pronunciations, or authentic maternal vocalizations, which can be less startling or more reinforcing for an autistic child than synthetic TTS.
- **Verification Limitations:** Verified on a physical Samsung Galaxy A34 5G and automated in `test/release_qa_backup_restore_test.dart`.

#### 3. Mixed-Script Multilingual Speech Routing
- **Status:** `IMPLEMENTED`
- **File Reference:** `lib/utils/multilingual_speech_router.dart` (Lines 23–268)
- **Technical Operation:** Splits composite text into language-tagged segments using Unicode character block analysis (Latin, Sinhala, Tamil). Additionally contains an unambiguous Romanized dictionary (e.g., "ayubowan" -> "ආයුබෝවන්", "vanakkam" -> "வணக்கம்"), allowing bilingual combinations (e.g., "Hello, kohomada") to be routed to appropriate language voice engines without phonetic distortion.
- **Medical Relevance for ASD:** Reflects the linguistic reality of Sri Lankan households, where caregivers frequently blend English and Sinhala/Tamil words during daily communication.

---

### E. Local Language Support (Trilingual Capabilities)

#### 1. Trilingual Card Metadata Storage
- **Status:** `IMPLEMENTED`
- **File Reference:** `lib/models/aac_card_model.dart` (Lines 4–5, 29–30, 62–77)
- **Technical Operation:** The data model explicitly stores three string fields: `label` (English), `labelSinhala`, and `labelTamil`. The helper method `getLabel(String language)` returns the requested language string; if the local language string is null, empty, or whitespace, it safely falls back to the English `label`.
- **Medical Relevance for ASD:** Enables bilingual or trilingual language exposure in multi-ethnic Sri Lankan settings, allowing communication in the child's mother tongue.
- **Verification Limitations:** Fallback behaviour ensures UI stability, but means un-translated cards will display English text even when the app is set to Sinhala or Tamil.

#### 2. Default Seed Vocabulary
- **Status:** `PARTIALLY IMPLEMENTED`
- **File Reference:** `lib/data/default_seed_cards.dart` (Lines 13–28, 30–91)
- **Technical Operation:** The initial factory seed database contains exactly 5 top-level cards ("Hello", "Happy", "Sad", "Angry", "More") and 2 sub-cards ("Good", "Play"). All 7 seed cards have fully verified English, Sinhala, and Tamil translations.
- **Verification Limitations:** While 100% of the initial factory seed cards have trilingual labels, this starter set is minimal (7 words). Real-world communication requires substantial vocabulary expansion by caregivers or clinicians.

#### 3. Curated Trilingual Concept Dictionary (Offline Translation Bank)
- **Status:** `IMPLEMENTED` / `REQUIRES CLINICAL ASSESSMENT`
- **File Reference:** `lib/services/multilingual_concept_service.dart` (Lines 5–746)
- **Technical Operation:** Contains an offline lookup table of 179 curated AAC concepts (`AacTranslation`) covering Core Social, Family/People, Food & Drinks, School/Daily Life, Animals, Actions, and Emotions. When a user creates a card and types an English, Sinhala, or Tamil word, `lookupTranslations()` automatically populates the other two language fields and assigns a category.
- **Medical Relevance for ASD:** Reduces literacy burden on parents and ensures standardized, accurate spellings for common everyday words.
- **Verification Limitations:** Automated in `test/multilingual_concept_test.dart`. While technically verified, the vocabulary list has not been formally reviewed by a speech and language therapist or certified linguist for developmental suitability.

---

### F. User Interface and Cognitive Accessibility

#### 1. Configurable Grid Density (1 to 5 Columns)
- **Status:** `IMPLEMENTED` / `REQUIRES CLINICAL ASSESSMENT`
- **File Reference:** `lib/pages/home_page.dart` (Lines 90, 850–920), `lib/widgets/preview/grid_density_preview.dart`
- **Technical Operation:** Caregivers can select the number of grid columns (from 1 up to 5) with a live interactive preview. Changing the column count dynamically scales card sizes, icon dimensions, and label fonts.
- **Medical Relevance for ASD:** Crucial for tailoring visual density to the individual child's visual processing, fine motor precision, and cognitive stage. A child early in AAC intervention may require large cards (1 or 2 columns), whereas an advanced communicator can navigate a denser grid (4 or 5 columns).
- **Verification Limitations:** Verified in unit and real-device tests. Optimal grid sizes for specific age bands and developmental profiles must be determined during clinical user trials.

#### 2. Selective Card Visibility ("Visible Cards" Filter)
- **Status:** `IMPLEMENTED`
- **File Reference:** `lib/pages/home_page.dart` (Lines 91, 1020–1080), `lib/widgets/visible_cards_dialog.dart`, `lib/widgets/preview/visible_cards_preview.dart`
- **Technical Operation:** Caregivers can selectively hide specific cards from the board without deleting them. Hidden cards remain in storage but do not render in the grid.
- **Medical Relevance for ASD:** Prevents cognitive overload by allowing gradual introduction of vocabulary (errorless learning or stepped vocabulary expansion) without permanently modifying the catalog.

#### 3. Board Pinning and Child-Safe Unpinning
- **Status:** `IMPLEMENTED`
- **File Reference:** `lib/pages/home_page.dart` (Lines 500–560), `lib/widgets/home_app_bar.dart`
- **Technical Operation:** Tapping the Pin icon in the app bar locks the application interface, disabling the settings drawer, edit buttons, and dialog triggers. Back button events are intercepted. To unpin, the user must press and hold the pin button continuously for 1.5 seconds, accompanied by a visual countdown and tactile haptic feedback.
- **Medical Relevance for ASD:** Prevents children from accidentally navigating away from their communication board, altering settings, or deleting vocabulary during communication attempts.
- **Verification Limitations:** Verified in automated tests (`test/pin_press_and_hold_test.dart`) and on device. Effectiveness against persistent exploratory tapping by children requires user testing.

#### 4. Caregiver Authentication Lock
- **Status:** `IMPLEMENTED`
- **File Reference:** `lib/services/caregiver_lock_service.dart` (Lines 1–180), `android/app/src/main/kotlin/com/example/simple_aac_app/MainActivity.kt` (Lines 39–41, 70–82)
- **Technical Operation:** Protects sensitive configuration areas (Edit Mode, Settings Drawer) behind device-level authentication (Fingerprint, Face Unlock, Device Pattern/PIN). If device biometrics are unavailable, it falls back to an in-app 4-digit PIN (default `1234`).
- **Medical Relevance for ASD:** Ensures that only authorized adults can reconfigure the communication system, delete records, or modify vocabulary structures.

#### 5. Tactile Haptic Feedback
- **Status:** `IMPLEMENTED`
- **File Reference:** `lib/pages/home_page.dart` (Lines 51–64)
- **Technical Operation:** Tapping any communication card executes a compound haptic pattern: `HapticFeedback.heavyImpact()` combined with `HapticFeedback.vibrate()`. This ensures activation on both linear resonant actuators and traditional eccentric rotating mass vibration motors.
- **Medical Relevance for ASD:** Provides multi-sensory reinforcement, confirming that a touch was registered. This can assist children with motor planning difficulties or sensory seeking tendencies.
- **Verification Limitations:** Verified in `test/card_haptics_and_pop_test.dart`. Sensory acceptability across hyper-sensitive or sensory-defensive children requires clinical monitoring.

#### 6. Color Vision and High Contrast Modes
- **Status:** `IMPLEMENTED`
- **File Reference:** `lib/utils/theme_accessibility.dart` (Lines 1–373), `lib/widgets/color_vision_dialog.dart`
- **Technical Operation:** Provides matrix-based real-time color filters for color vision deficiencies (Protanopia, Deuteranopia, Tritanopia) and a High Contrast mode with dark borders, saturated accents, and optimized font weights.
- **Medical Relevance for ASD:** Supports individuals with co-occurring visual impairments or atypical visual processing.

---

### G. Offline Architecture and Network Policy

#### 1. Strict Offline-by-Default Network Gate
- **Status:** `IMPLEMENTED`
- **File Reference:** `lib/services/network_policy_service.dart` (Lines 1–83), `lib/main.dart` (Lines 13–20)
- **Technical Operation:** Core communication operates 100% offline. The application includes a centralized `NetworkPolicyService` where `online_features_enabled` defaults to `false`. When disabled, `OfflineGatedHttpClient` intercepts and blocks every outbound HTTP request, throwing an `OfflineModeException`. Google Fonts runtime network fetching is explicitly disabled in `main.dart` (`GoogleFonts.config.allowRuntimeFetching = false`).
- **Medical Relevance for ASD:** Guarantees that communication functionality remains uninterrupted in resource-constrained environments, rural areas, or clinical settings with poor cellular reception. Protects children from unwanted ads, pop-ups, or internet distractions.
- **Verification Limitations:** Verified via unit tests (`test/network_policy_test.dart`).

#### 2. Optional Smart Image Search (Openverse Integration)
- **Status:** `IMPLEMENTED` / `PARTIALLY IMPLEMENTED` (Requires User Toggle)
- **File Reference:** `lib/services/openverse_search_provider.dart` (Lines 1–180), `lib/widgets/smart_image_search_dialog.dart`
- **Technical Operation:** When (and only when) a caregiver explicitly enables "Online Features" in the settings drawer, the app can query the Openverse open-access Creative Commons image API to retrieve public-domain images and symbols. Downloaded images are stored locally in the app's sandboxed document storage.
- **Verification Limitations:** Requires active internet and explicit user opt-in. Zero communication features depend on this service.

---

### H. Data Storage, Backup, and Privacy

#### 1. Local Sandboxed Storage
- **Status:** `IMPLEMENTED`
- **File Reference:** `lib/services/card_storage_service.dart` (Lines 10–120), `lib/services/storage_service.dart`
- **Technical Operation:** All card data is stored as a structured JSON file (`aac_cards_v1.json`) within the private application documents directory (`/data/user/0/lk.yasas.simpleaac/app_flutter/`). Atomic file writes using a `.tmp` file and automatic backup copies (`.bak`) prevent database corruption during sudden device power loss. Images and voice recordings are copied directly into the app sandbox.
- **Medical Relevance for ASD:** Protects child privacy by ensuring personal photos (e.g., family members, private therapy routines) never leave the local handset.

#### 2. Backup and Restore (Zip Archive)
- **Status:** `IMPLEMENTED`
- **File Reference:** `lib/services/backup_service.dart` (Lines 22–250), `android/app/src/main/kotlin/com/example/simple_aac_app/MainActivity.kt` (Lines 70–82)
- **Technical Operation:** Generates an unencrypted standard ZIP archive (`aac_backup.zip`) containing `cards.json`, `settings.json`, and all referenced local media in a `files/` folder. On Android, it exports directly to the public `Downloads` directory via scoped storage MediaStore API, or invokes the Android system share sheet.
- **Medical Relevance for ASD:** Allows parents to transfer a child's personalized communication vocabulary across devices without manual reconfiguration.
- **Verification Limitations:** The ZIP archive is **unencrypted**. If a backup contains sensitive family photographs, it must be handled securely by the caregiver. There is no automated cloud synchronisation.

#### 3. Application Permissions
- **Status:** `IMPLEMENTED` (Hardened for Privacy)
- **File Reference:** `android/app/src/main/AndroidManifest.xml` (Lines 6–22), `lib/utils/app_permissions_helper.dart`
- **Technical Operation:** Requests only essential runtime permissions: `RECORD_AUDIO` (for custom card voice recording), `CAMERA` (for taking card pictures), and `VIBRATE` (for haptics). Broad media permissions (`READ_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`) are explicitly stripped using `tools:node="remove"`, complying with child safety and Google Play privacy policies.

---

### I. Platform Compatibility

#### 1. Android Platform Support
- **Status:** `IMPLEMENTED` / `VERIFIED`
- **File Reference:** `android/app/build.gradle.kts` (Lines 18–43), `android/local.properties`
- **Technical Operation:** Built for `compileSdk = 36`, `targetSdk = 36`, `minSdk = 24` (Android 7.0 Nougat through Android 16). Full production release signing and 16 KB ELF memory alignment verified.
- **Verification Limitations:** Verified on physical hardware (Samsung Galaxy A34 5G running Android 16) and Google Play Console release validation.

#### 2. iOS Platform Support
- **Status:** `NOT IMPLEMENTED` / `NOT VERIFIED`
- **File Reference:** `ios/Runner/AppDelegate.swift` (Lines 1–13), `ios/Runner.xcodeproj`
- **Technical Operation:** An iOS project directory exists as part of the default Flutter framework scaffolding. However, none of the application's native method channels (`aac_backup`, `aac_vision`, `aac_auth`) are implemented in iOS Swift/Objective-C. No iOS Podfile or dependencies are configured.
- **Clinical Implication:** The prospective study must be conducted exclusively on Android hardware. iOS cannot be claimed as a supported platform.

---

## 3. Summary of Feature Implementation Status

| Feature Area | Specific Functionality | Status | Exact Source File Reference |
| :--- | :--- | :--- | :--- |
| **AAC Core** | Picture Grid Cards | `IMPLEMENTED` | `lib/models/aac_card_model.dart:1-78` |
| **AAC Core** | Folders & Sub-Cards | `IMPLEMENTED` | `lib/models/aac_card_model.dart:10-59` |
| **AAC Core** | Sentence Bar (TTS Strip) | `IMPLEMENTED` | `lib/widgets/tts_bar.dart:6-249` |
| **AAC Core** | Multi-Category Selection | `IMPLEMENTED` | `lib/widgets/select_category_dialog.dart:21-414` |
| **AAC Core** | Card & Category Management | `IMPLEMENTED` | `lib/widgets/card_editor_dialog.dart:25-950` |
| **Visual Support** | Visual Schedules | `NOT IMPLEMENTED` | *None* |
| **Visual Support** | First–Then Boards | `NOT IMPLEMENTED` | *None* |
| **Visual Support** | Social Stories | `NOT IMPLEMENTED` | *None* |
| **Emotional Support**| Emotion Cards & Category | `IMPLEMENTED` | `lib/data/default_seed_cards.dart:41-63` |
| **Emotional Support**| Facial Emotion Recognition AI | `NOT IMPLEMENTED` | *None* (ML Kit used only for object labels) |
| **Speech** | System Text-to-Speech | `IMPLEMENTED` | `lib/services/speech_engine.dart:69-488` |
| **Speech** | Custom Audio Recording | `IMPLEMENTED` | `lib/widgets/card_editor_dialog.dart:480-620` |
| **Speech** | Mixed-Script Router | `IMPLEMENTED` | `lib/utils/multilingual_speech_router.dart:23-268` |
| **Languages** | Trilingual Metadata (EN/SI/TA)| `IMPLEMENTED` | `lib/models/aac_card_model.dart:4-5,62-77` |
| **Languages** | Curated Concept Bank (179) | `IMPLEMENTED` | `lib/services/multilingual_concept_service.dart:5-746` |
| **Languages** | Default Seed Cards (7 words) | `PARTIALLY IMPLEMENTED` | `lib/data/default_seed_cards.dart:30-91` |
| **UI & A11y** | 1–5 Column Grid Density | `IMPLEMENTED` | `lib/pages/home_page.dart:90,850-920` |
| **UI & A11y** | Visible Cards Filter | `IMPLEMENTED` | `lib/pages/home_page.dart:91,1020-1080` |
| **UI & A11y** | Board Pinning (1.5s Hold) | `IMPLEMENTED` | `lib/pages/home_page.dart:500-560` |
| **UI & A11y** | Caregiver Lock / PIN | `IMPLEMENTED` | `lib/services/caregiver_lock_service.dart:1-180` |
| **UI & A11y** | Dual-Action Haptics | `IMPLEMENTED` | `lib/pages/home_page.dart:51-64` |
| **UI & A11y** | Color Vision Deficiency Modes | `IMPLEMENTED` | `lib/utils/theme_accessibility.dart:1-373` |
| **Offline Gate** | Strict Offline Enforcement | `IMPLEMENTED` | `lib/services/network_policy_service.dart:1-83` |
| **Data & Privacy** | Local Sandboxed JSON Storage | `IMPLEMENTED` | `lib/services/card_storage_service.dart:10-120` |
| **Data & Privacy** | Unencrypted ZIP Backup/Restore| `IMPLEMENTED` | `lib/services/backup_service.dart:22-250` |
| **Data & Privacy** | Scoped Media Permissions | `IMPLEMENTED` | `android/app/src/main/AndroidManifest.xml:6-22` |
| **Platforms** | Android (API 24–36) | `IMPLEMENTED` | `android/app/build.gradle.kts:18-43` |
| **Platforms** | iOS Support | `NOT IMPLEMENTED` | `ios/Runner/AppDelegate.swift:1-13` (No channels) |
