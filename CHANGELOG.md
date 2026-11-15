# Changelog

All notable changes to the Simple AAC application are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Project-local Agent Skills (`flutter-ui-ux`, `aac-accessibility`, `design-system`, `flutter-quality`, `release-management`) under `.agents/skills/`.
- Root agent operational guide (`AGENTS.md`) and operational rules (`.agents/rules/flutter_rules.md`).
- Centralized design system documentation in `docs/design/DESIGN_SYSTEM.md`.
- Comprehensive versioned release tracking in `docs/releases/2026-11-14-v1.1.0.md`.

---

## [1.1.1] - 2026-11-16

### Added
- **TTS Bar Settings & Independent Action Controls (`77de384`):**
  - Renamed "TTS Bar Sizing" dialog and drawer item to "TTS Bar Settings".
  - Introduced separate, independent switch toggles for "Show Delete Button" and "Show Clear Button" (both default enabled).
  - Integrated real-time Live Preview reflecting size scaling and independent button visibility.
- **Child-Safe Press-and-Hold Unpin Protection (`afc95de`):**
  - Board unpinning now strictly requires a 700ms press-and-hold with haptic vibration feedback.
  - Prevents unintended unpinning from accidental taps by children and learners.
- **Interactive First-Run App Guide & Onboarding Tour (`20755a7`, `472202b`, `bee2caa`):**
  - 9-step trilingual interactive onboarding walkthrough with hole-punch spotlighting (`HighlightPainter`).
  - Automatic drawer close on Step 4 next-advance and back-navigation.
  - Permanent "Interactive App Guide" replay option in Settings Drawer.
- **Color Vision Deficiency Support & Card Adaptation (`1e41e00`, `e40bb74`, `63a3558`):**
  - Real color-blind safe palettes (Protanopia, Deuteranopia, Tritanopia, Monochromacy).
  - Real-time image color filtering adapting photo cards and illustrations for color-blind users.
  - High-contrast card border ring customizer (1–10px thickness, auto-contrast or custom colors).
  - High-contrast mini palette preview chips in Settings Drawer.
- **Interactive Add Category Modal (`fdc6e9c`):**
  - Live category badge preview with quick preset chips (Food, School, Feelings), icon selector, color accent picker, and card assignment checklist.
- **Direct Runtime Permission Requests (`a221078`):**
  - Native Android runtime dialogs for Camera and Microphone triggered on first use without forcing user to system settings.
- **Tactile Haptic Feedback (`02a1763`):**
  - Strong heavy-impact tactile feedback and custom vibration pulse on card taps.
- **Caregiver Lock Security (`71c6fe8`):**
  - Native biometrics (fingerprint/face) and device lock pattern/PIN protection with fallback PIN.
- **Reactive Live Previews (`e59eca6`):**
  - Live preview panels for Grid Density, TTS Bar, and Visible Cards dialogs.
- **Empty Category Support in Visible Cards Dialog (`3e45799`):**
  - Allow Visible Cards dialog to open even when category has 0 cards, showing an empty state explaining cards can be created in Edit Mode first.

### Changed
- **Toolchain & Build Optimization (`4ca787a`, `487d2bb`):**
  - Upgraded to Android Gradle Plugin 9.0.1 and Gradle 9.1.0.
  - Enabled optimized R8 full-mode shrinking with ProGuard keep rules for offline ML Kit models.
  - Bumped version to `1.1.1+9` for Google Play Console release.

---

## [1.1.0] - 2026-11-14

### Documentation
- **Trilingual User Documentation Suite (English, Sinhala, Tamil):**
  - Published complete, professionally localized user guides in both vector PDF (7 pages) and editable Microsoft Word DOCX formats (13–14 pages) under `docs/user-guide/`.
  - Comprehensive 8-chapter coverage with 22 authentic ADB screenshots and 2 animated GIF walkthroughs across all three languages.
  - Full Unicode font metrics validation for Latin (`Calibri`), Sinhala (`Noto Sans Sinhala`), and Tamil (`Noto Sans Tamil`), verifying complex conjunct shaping and diacritics.
  - Consolidated QA certifications documented in `docs/user-guide/TRILINGUAL_DOCUMENT_QA_REPORT.md`.

### Added
- **Tactile Card Interaction & Haptics (`e8e05a5`):**
  - Enhanced card pop animation scaling to 1.08 with organic spring curve (`Curves.easeOutBack`) and matching accent aura lighting.
  - Physical taptic vibration (`HapticFeedback.mediumImpact()`) on card and folder taps.
  - Added user-facing "Haptic Feedback" toggle in Settings Drawer under Communication & Speech (default ON).
  - Declared `android.permission.VIBRATE` in AndroidManifest.xml.
- **Settings Drawer Appearance & Theme Modernization (`513e3f1`):**
  - Replaced plain circular color dots with live, contextual visual preview chips for Primary App Color, Global Text Color, and Board Background Color.
  - Enhanced grouped card containers, typography, and section headers.
- **Contextual Color Picker Previews (`96a1e57`):**
  - Specialized real-time preview logic: mini `HomeAppBar` for App Color, live text samples for Text Color, and board canvas behind 3 mock cards for Background Color.
- **Professional Color Picker Dialog UX (`57bca9e`):**
  - Compact 3-section dialog replacing bulky full-screen pickers: live preview, 8 quick swatches with checkmarks, and 2D HSV slider with hex code field.
- **Home Header Redesign (`6027a0d`):**
  - Approved `[ PIN ] | Simple AAC [ MENU ]` layout with vertical divider, 48×48dp accessible tap targets, and removal of distracting in-header logos.
- **Official Brand Logo Suite (`aeb9887`):**
  - Complete integration of official Simple AAC speech bubble icon into Android adaptive icons, legacy mipmaps, iOS asset catalogs, and 512×512 Google Play store assets.
- **Offline ML Kit Vision Classifier (`776b5f0`):**
  - Bundled Google ML Kit offline vision models (`libmlkitcommonpipeline.so`) providing 100% offline card labeling and word suggestions from photos.
- **Animated GIF & Video Clip Support (`e5d0bbc`):**
  - Support for custom animated GIF communication cards and <=30s video clips with gapless memory-bounded playback.
- **Child-Safe Smart Image Search (`fd88bec`):**
  - Creative Commons Openverse image search with strict safe-search filtering, zero ads, and one-tap offline toggle.

### Changed
- **Default Image Overlay Mode (`da594db`):** Clean install and settings reset default `useImageOverlayLabel` to `true` for maximum visual card area.
- **Card Editor Dialog Polish (`92d8f0f`):** Added explicit close button to header and replaced image clear button with an intuitive trash bin icon.
- **Switch Theme Contrast (`ae40de5`):** Restored stark contrast for selected switch thumbs (`onPrimary` against `primary` track).
- **Multilingual Google TTS Optimization (`185f207`, `0549334`):**
  - Abandoned heavy experimental neural models (which inflated app size by 80+ MB) in favor of lightweight, platform-native Google TTS.
  - Added intelligent Unicode-script routing (`MultilingualSpeechRouter`) supporting English, Sinhala, and Tamil code-switching.
  - Preserved ultra-compact Play download size of **~25.17 MB**.

### Fixed
- **Permanent Data Persistence & Storage Hardening:**
  - Resolved critical defect where a single read failure or corrupted `aac_cards_v1.json` could silently wipe the user's primary file, backup file, and legacy SharedPreferences with an empty list (`[]`).
  - Added multi-tier storage failover: Primary -> Backup (`.bak`) -> Pending (`.tmp`) -> Legacy SharedPreferences -> Quarantine (`.corrupt_<timestamp>`) -> Heuristic JSON salvage.
  - Hardened 0-byte truncated file handling: 0-byte or whitespace-only files trigger immediate recovery from backup rather than returning an empty board.
  - Implemented heuristic JSON recovery: salvages valid card records via suffix closure repair and regex object extraction from damaged storage files.
  - Fixed cross-device restore path remapping: backup archives containing foreign absolute paths (e.g. `/data/user/0/...`) now automatically resolve against archive media and re-anchor into local app documents.
  - Eliminated media persistence collisions: combined microsecond timestamps, atomic monotonic counters, and existence verification loops to ensure concurrent media imports never overwrite files.
- **Camera and Video Launch Resilience (`f224f4e`):**
  - Added explicit Android 11+ package queries for `ACTION_IMAGE_CAPTURE` and `ACTION_VIDEO_CAPTURE` in `AndroidManifest.xml`.
  - Implemented dual-permission verification (Camera + Audio) with fallback modal error guidance.
- **Backup & Restore Hardening (`fc7afef`):**
  - Eliminated Zip Slip vulnerabilities with strict entry path sanitization.
  - Added JSON schema version tolerance and SHA-256 media validation.

### Security
- Added path traversal guards preventing archive writes outside the app documents sandbox.
- Verified Android 13+ Photo Picker compliance with zero broad external storage permissions.
- Verified 16 KB ELF page alignment for native libraries to ensure Android 15 stability.

---

## [1.0.2] - 2026-08-15

### Added
- Initial production release of Simple AAC for Android on Google Play (`e6fc156`).
- Basic grid-based AAC communication board with seed cards.
- Speech synthesis for English and Sinhala via `flutter_tts`.
- Basic card customization with local image picker.
- Production signing with official Google Play upload key.
