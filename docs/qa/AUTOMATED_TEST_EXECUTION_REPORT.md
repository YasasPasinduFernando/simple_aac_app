# Simple AAC Sri Lanka — Automated QA Test Execution Report (v1.1.6 Build 15)

**Execution Date:** November 21, 2026  
**Target Git Branch:** `release/play-store-rc-20261121-v1.1.6`  
**Execution Environment:** Linux 6.8, Flutter 3.47.1, Dart 3.13.1  
**Total Tests Executed:** 708  
**Total Passed:** 708 (100%)  
**Total Failed:** 0  
**Skipped Tests:** 6 (Manifest expansion markers)  
**Static Code Analysis:** `flutter analyze` — 0 issues found (3.9s)  

---

## 1. Test Suite Coverage Breakdown

| Category | Key Test Suites | Test Count | Status |
| :--- | :--- | :---: | :---: |
| **Card Presentation & Layout** | `home_cards_and_image_presentation_test.dart`<br>`responsive_card_rendering_test.dart`<br>`folder_card_image_filling_test.dart`<br>`card_image_rendering_consistency_test.dart` | 42 | **PASS** |
| **Global Card Label Color** | `global_card_label_background_color_test.dart`<br>`global_label_color_backup_restore_verification_test.dart`<br>`render_global_card_label_color_artifacts_test.dart` | 38 | **PASS** |
| **Scroll Lock & Gestures** | `scroll_lock_reproduction_test.dart` (10 Scenarios) | 10 | **PASS** |
| **Voice Playback & Performance** | `voice_recording_playback_benchmark_and_safety_test.dart` (Benchmarking + Scenarios A–I) | 20 | **PASS** |
| **Settings & Drawer Features** | `drawer_enhancement_test.dart`<br>`settings_drawer_expand_discovery_test.dart`<br>`render_responsive_modes_test.dart`<br>`quick_orientation_access_test.dart` | 58 | **PASS** |
| **TTS & Multilingual Speech** | `trilingual_text_to_speech_test.dart`<br>`offline_tts_reliability_test.dart`<br>`speech_prewarm_test.dart` | 36 | **PASS** |
| **Camera & Image Cropping** | `camera_crop_lifecycle_resilience_test.dart`<br>`image_crop_helper_test.dart`<br>`safe_media_picker_test.dart` | 28 | **PASS** |
| **Card Data Persistence** | `card_storage_service_test.dart`<br>`atomic_file_write_test.dart`<br>`starter_pack_integration_test.dart`<br>`stickman_v2_migration_test.dart` | 64 | **PASS** |
| **Security & PIN Lock** | `pinned_child_mode_navigation_test.dart`<br>`disable_back_card_in_pin_mode_test.dart`<br>`pin_mode_header_consistency_test.dart` | 38 | **PASS** |
| **Backup & Restore Resilience** | `release_qa_backup_restore_test.dart`<br>`animated_media_backup_test.dart`<br>`large_dataset_performance_stress_test.dart`<br>`recycle_bin_test.dart` | 45 | **PASS** |
| **Other Core & Regression** | All additional component, service, and widget test suites | 329 | **PASS** |
| **TOTAL** | **87 Test Suites** | **708** | **PASS** |

---

## 2. Key Regressions & New Capabilities Verified

1. **Global Card Label Color Setting:** Verified that ONE global label background color (`#F4F1EB` Warm Ivory default) applies to all cards across Home, Default, More, and custom folders when `Show Card Labels = ON` and `Overlay = OFF`.
2. **Scroll Lock Elimination:** Verified that the transparent `ChildFriendlySplash` overlay is properly ignored with `IgnorePointer` and cleaned up with a fallback timer, completely resolving the intermittent vertical scroll lock on app reopen across 10 lifecycle scenarios.
3. **Voice Recording Playback Performance:** Verified that custom recorded voice playback has minimal latency (Cold: 32.99ms, p50: 53.49ms, p95: 92.28ms) with zero audio overlap or player leaks.
4. **Card Save & Double-Tap:** Verified that single taps save exactly once, double-taps do not create duplicates, and cancelling card creation leaves no orphan temporary image files.
5. **First-Tap TTS Delay:** Verified that `SpeechEngine.instance.prewarm()` runs asynchronously upon startup, pre-populating the voice catalog and eliminating card tap latency.
6. **Card Labels Toggle:** Verified that `Show Card Labels = OFF` removes all card text, label footers, and text gradient overlays across home cards, category cards, and custom user photos while preserving speech on tap.
7. **Overlay Labels on Images Toggle:** Verified that Mode A (Overlay ON) presents full-bleed cards with text gradient over the bottom, and Mode B (Overlay OFF) presents an upper image area (using `BoxFit.cover` for user photos) with a solid footer.
8. **Home Default Folder Image:** Verified that the replacement cover asset `default_folder_three_kids_square_alternative.webp` renders without unwanted inner borders or letterboxing, and existing user customized cards are preserved.
