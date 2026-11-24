# Simple AAC Sri Lanka — Comprehensive Project Knowledge Base

This document serves as the primary technical architecture guide and domain knowledge reference for **Simple AAC Sri Lanka** (`lk.yasas.simpleaac`).

---

## 1. Project Mission & Target Users

Simple AAC Sri Lanka is an Augmentative and Alternative Communication (AAC) application engineered specifically for Sri Lankan children and individuals with communication impairments, including:
- Autism Spectrum Disorder (ASD)
- Cerebral Palsy (CP)
- Down Syndrome & Intellectual Disabilities
- Apraxia of Speech & Developmental Language Delays
- Non-verbal or minimally verbal individuals

### Core Philosophical Pillars:
1. **100% Offline-First & Private:** Core communication, text-to-speech, and image displays require no internet access or third-party servers. No telemetry, user tracking, or data collection.
2. **Trilingual from Ground Zero:** Built from the ground up for Sinhala (සිංහල), Tamil (தமிழ்), and English.
3. **Cognitive Ease & Low Sensory Load:** High visual predictability, customizable card grid densities (1 to 30 columns), high contrast safeguards, and customizable acoustic pacing.
4. **Caregiver Empowerment:** Frictionless customization, custom voice recording, personalized photos, and 4-digit PIN protection.

---

## 2. Technical Stack & Specifications

* **Framework:** Flutter SDK 3.x (Dart 3.x)
* **Target Platform:** Android (minSdkVersion: `21` / Android 5.0 Lollipop, targetSdkVersion: `35` / Android 15)
* **Application ID / Package:** `lk.yasas.simpleaac`
* **Release Signing:** Google Play App Signing + Local RSA-2048 `upload-keystore.jks`
* **Local Storage:** `shared_preferences`, scoped internal storage (`path_provider`), JSON serialization
* **Audio Engine:** `flutter_tts` (low-latency offline speech) + `audioplayers` (custom voice recordings)
* **Media Handling:** `image_picker`, custom 1:1 crop & zoom engine, animated GIF decoding

---

## 3. Directory Structure & Architecture

```
simple_aac_play_release/
├── android/                   # Native Android configuration, manifests, signing keys
├── assets/                    # Bundled offline assets
│   ├── audio/                 # Audio feedback and system cues
│   ├── icons/                 # System and category vector icons
│   ├── images/
│   │   └── starter_pack_v8/   # 114 pre-colored starter cards (WebP)
│   └── symbols/               # Essential offline communication symbols
├── lib/
│   ├── data/                  # Seed catalogs, manifests, default card registries
│   ├── models/                # Immutable domain data models
│   ├── pages/                 # Full-screen application pages (Home, Recycle Bin)
│   ├── services/              # Singleton business logic and platform abstraction
│   ├── utils/                 # Pure helper functions (cropping, colors, camera)
│   ├── widgets/               # Modular UI widgets and interactive dialogs
│   │   ├── preview/           # Live preview widgets for settings
│   │   └── tutorial/          # Interactive onboarding and guided tour components
│   └── main.dart              # Application entry point & theme initialization
├── test/                      # 708 automated unit, widget, and integration tests
├── docs/                      # Technical documentation, QA reports, user guides
├── graphify-out/              # Knowledge graph (4402 nodes, 6008 edges, 449 wiki pages)
└── RELEASE_LOG.md             # Master release register and build audit trail
```

---

## 4. Key Subsystems & Implementation Details

### 4.1 Speech & Audio Subsystem (`SpeechEngine`)
* **Location:** `lib/services/speech_engine.dart`
* **Multilingual Fallback Hierarchy:**
  1. If a custom voice recording exists for the card (`voiceRecordingPath`), play it immediately via `AudioPlayer`.
  2. Otherwise, synthesize text using `flutter_tts` with localized language codes (`si-LK`, `ta-LK`, `en-US` or `en-GB`).
  3. If native Sinhala/Tamil TTS voices are absent on older devices, gracefully fall back to default Google TTS voice engines.
* **Asynchronous Pre-Warming:** To eliminate audio lag on cold launch, `SpeechEngine` executes an un-awaited background initialization during splash loading, caching engine availability.

### 4.2 Card & Grid Layout Engine
* **Location:** `lib/pages/home_page.dart`, `lib/widgets/aac_card_widget.dart`
* **Responsive Layout:**
  - Automatic column computation based on orientation and screen size (1 to 30 columns configurable).
  - Dedicated 4-column landscape mode optimized for accessibility tablet stands.
* **Transactional Edit Mode (`lib/widgets/edit_mode_bar.dart`):**
  - Card modifications (drag-and-drop reordering, moving into sub-cards, deletions, edits) are staged in a transactional session.
  - Users can perform multi-level **Undo**, or exit cleanly via **Cancel** (reverting all changes) or **Done** (committing to persistent storage).
* **30-Day Safe Recycle Bin (`lib/services/recycle_bin_service.dart`):**
  - Deleted cards are soft-deleted into the Recycle Bin with media reference counts.
  - Image and audio files are never purged from disk while other cards reference them.
  - Auto-expires deleted items after 30 days; supports full restoration and permanent shredding.

### 4.3 Color & Visual Accessibility System
* **Location:** `lib/widgets/professional_color_picker_dialog.dart`, `lib/widgets/color_vision_dialog.dart`
* **British English UI Standardization:**
  - In compliance with Sri Lankan English standards, all user-visible text uses British English spelling (`Colour`, `Colours`).
  - Underlying code constants, Flutter types (`Color`), and database serialization keys remain untouched for compatibility.
* **Text-to-Speech Bar Colour Setting:**
  - Independent colour preferences for Light Mode and Dark Mode.
  - Live preview widget allows immediate visual verification before saving.
* **Dark Mode Seamless Card Fill:**
  - Transparent PNG and WebP symbols on cards automatically render against seamless pastel backdrops in Dark Mode to eliminate jarring bright white boxes while maintaining maximum contrast.
* **Color Vision Deficiency (CVD) Support:**
  - Includes real-time simulation and contrast compensation for Protanopia, Deuteranopia, and Tritanopia.

### 4.4 Camera Flow & Android Process Recovery
* **Location:** `lib/widgets/card_editor_dialog.dart`, `lib/pages/home_page.dart`
* **Process Reclamation Protection:**
  - High-resolution external camera apps can trigger aggressive Android OS memory reclamation (killing the Flutter activity in background).
  - Draft state (card label, selected category, audio paths) is saved to persistent scratch storage before launching the camera intent.
  - Upon return, draft state and active folder navigation stacks are restored seamlessly.

### 4.5 Security & Caregiver Protection (`CaregiverLockService`)
* **Location:** `lib/services/caregiver_lock_service.dart`
* **Capabilities:**
  - Custom 4-digit PIN protection.
  - Restricts Edit Mode, Settings Drawer access, Card Deletion, and Factory Reset.
  - Unlocked state auto-locks after configurable inactivity periods.

---

## 5. Testing & Quality Assurance Architecture

The test suite in `test/` comprises **708 automated tests**:
* **Unit Tests:** Serialization, data models, color conversions, recycle bin retention arithmetic.
* **Widget & Interaction Tests:** Modal dialogs, color pickers, category editors, drawer navigation.
* **Live Preview Tests:** Assertion of live previews in settings without relying on flaky goldens.
* **Physical Device QA Suite:** Automated and manual test scripts for Samsung Galaxy A34 (Android 14 / One UI 6.1) covering 20 cold-start scroll cycles, orientation flips, and process recreations.
