# Simple AAC Sri Lanka — Automated QA Test Execution Report (v1.1.6 Build 15)

**Execution Date:** November 21, 2026  
**Target Git Branch:** `release/play-store-rc-20261121-v1.1.6`  
**Execution Environment:** Linux 6.8, Flutter 3.47.1, Dart 3.13.1  
**Total Tests Executed:** 651  
**Total Passed:** 651 (100%)  
**Total Failed:** 0  
**Static Code Analysis:** `flutter analyze` — 0 issues found  

---

## 1. Test Suite Coverage Breakdown

| Category | Key Test Suites | Test Count | Status |
| :--- | :--- | :---: | :---: |
| **Card Presentation & Layout** | `home_cards_and_image_presentation_test.dart`<br>`responsive_card_rendering_test.dart`<br>`folder_card_image_filling_test.dart`<br>`card_image_rendering_consistency_test.dart` | 42 | **PASS** |
| **Settings & Drawer Features** | `drawer_enhancement_test.dart`<br>`settings_drawer_expand_discovery_test.dart`<br>`render_responsive_modes_test.dart`<br>`quick_orientation_access_test.dart` | 58 | **PASS** |
| **TTS & Multilingual Speech** | `trilingual_text_to_speech_test.dart`<br>`offline_tts_reliability_test.dart`<br>`speech_prewarm_test.dart` | 36 | **PASS** |
| **Camera & Image Cropping** | `camera_crop_lifecycle_resilience_test.dart`<br>`image_crop_helper_test.dart`<br>`safe_media_picker_test.dart` | 28 | **PASS** |
| **Card Data Persistence** | `card_storage_service_test.dart`<br>`atomic_file_write_test.dart`<br>`starter_pack_integration_test.dart`<br>`stickman_v2_migration_test.dart` | 64 | **PASS** |
| **Security & PIN Lock** | `pinned_child_mode_navigation_test.dart`<br>`disable_back_card_in_pin_mode_test.dart`<br>`pin_mode_header_consistency_test.dart` | 38 | **PASS** |
| **Backup & Restore Resilience** | `release_qa_backup_restore_test.dart`<br>`large_dataset_performance_stress_test.dart`<br>`recycle_bin_test.dart` | 45 | **PASS** |
| **Other Core & Regression** | All additional component, service, and widget test suites | 340 | **PASS** |
| **TOTAL** | **82 Test Suites** | **651** | **PASS** |

---

## 2. Key Regressions Verified

1. **Card Save & Double-Tap:** Verified that single taps save exactly once, double-taps do not create duplicates, and cancelling card creation leaves no orphan temporary image files.
2. **First-Tap TTS Delay:** Verified that `SpeechEngine.instance.prewarm()` runs asynchronously upon startup, pre-populating the voice catalog and eliminating card tap latency.
3. **Card Labels Toggle:** Verified that `Show Card Labels = OFF` removes all card text, label footers, and text gradient overlays across home cards, category cards, and custom user photos while preserving speech on tap.
4. **Overlay Labels on Images Toggle:** Verified that Mode A (Overlay ON) presents full-bleed cards with text gradient over the bottom, and Mode B (Overlay OFF) presents an upper image area (using `BoxFit.cover` for user photos) with a solid footer.
5. **Home Default Folder Image:** Verified that the replacement cover asset `default_folder_cover.webp` renders without unwanted inner borders or letterboxing, and existing user customized cards are preserved.
