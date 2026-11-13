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

## [1.1.0] - 2026-11-14

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
