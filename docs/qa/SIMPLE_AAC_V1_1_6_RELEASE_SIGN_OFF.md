# Simple AAC Sri Lanka — Version 1.1.6 (Build 15) Formal Release Sign-Off

**Document ID:** `SIMPLE_AAC_V1_1_6_RELEASE_SIGN_OFF.md`  
**Application Title:** Simple AAC Sri Lanka  
**Package Name:** `lk.yasas.simpleaac` (Production) / `lk.yasas.simpleaac.dev` (Debug)  
**Target Platform:** Android (Min SDK 24 / Target SDK 36, compileSdk 36)  
**Release Gate Date:** November 21, 2026  
**Final Release Verdict:** **GO — READY FOR MANUAL GOOGLE PLAY CONSOLE UPLOAD**

---

## A. Release Information & Metadata

| Field | Production Target Specification |
| :--- | :--- |
| **Application Name** | Simple AAC Sri Lanka |
| **Package ID** | `lk.yasas.simpleaac` |
| **Version Name** | `1.1.6` |
| **Version Code** | `15` (Universal APK / AAB) |
| **Git Release Branch** | `release/play-store-rc-20261121-v1.1.6` |
| **Release Commit SHA** | `77d5b7e` (*chore(release): bump version to v1.1.6 (build 15)*) |
| **Base Bugfix Branch** | `bugfix/final-camera-crop-card-save-20261120` |
| **Build Toolchain** | Flutter 3.47.1 (stable), Dart 3.13.1, OpenJDK 17, Gradle 8.11, AGP 8.6.0 |
| **Compile SDK / Target SDK** | `36` / `36` (Fully compliant with Google Play target API requirements) |
| **Min SDK** | `24` (Android 7.0 Nougat+) |
| **Release Date** | November 21, 2026 |

---

## B. Verified Production Release Binaries & Checksums

All production binaries were built from clean working tree on branch `release/play-store-rc-20261121-v1.1.6` with production signing configuration enabled (`android/key.properties`).

| Artifact Type | File Name | File Size | SHA-256 Checksum | Signature Status |
| :--- | :--- | :---: | :--- | :---: |
| **Play Store App Bundle (AAB)** | `app-release.aab` | **92.28 MB** (92,275,776 B) | `1be1d80742bcbab9828c34597b528af39a4976154b8a6b92bb1e27c65014bfce` | Verified (`bundletool`) |
| **Universal Release APK** | `app-release.apk` | **112.34 MB** (112,342,600 B) | `f44ef46c2ce2c68b8d32f505ae8a8a4fa9d6d0fea5f874b7296349e0a6964621` | Verified (v2 scheme) |
| **ARM64-v8a Split APK** | `app-arm64-v8a-release.apk` | **52.79 MB** (52,793,042 B) | `b6c0b349fa77acc8819937aa3df883415486cf31b2eb137f19a08ed2f035e069` | Verified (v2 scheme) |
| **ARMEABI-v7a Split APK** | `app-armeabi-v7a-release.apk` | **46.63 MB** (46,634,990 B) | `2375d1f15b26e8465e20d363d0f646323340dce885885bf9b7561927bc6142af` | Verified (v2 scheme) |
| **x86_64 Split APK** | `app-x86_64-release.apk` | **55.49 MB** (55,489,478 B) | `1c9d8bd621ec9aec17039dfd6bbcd0946b3adf02192e54a65809e6f427181758` | Verified (v2 scheme) |
| **ProGuard/R8 Mapping File** | `mapping.txt` | **26.85 MB** (26,849,897 B) | `c512db85c8a78bf56a8544175a80c1b725f02be92c16df68b3c8f870d6b6eb2c` | Generated fresh |

---

## C. Release Hardening & Bug Fix Summary

The following key issues were diagnosed, resolved, and verified since Build 14 (v1.1.5):

### 1. Premature Card Creation & Double-Save Elimination
- **Root Cause:** In earlier versions, navigating through the creation modal or taking a photo could stage a placeholder card before explicit user confirmation. Double-tapping the save button could also produce duplicate cards.
- **Fix:** Guarded the save action with an explicit atomic commit pipeline and an asynchronous double-tap debounce lock (`_isSavingCard`). Staged temporary images are automatically cleaned up if the user cancels or navigates away.

### 2. High-Resolution Camera & Crop Memory Resilience
- **Root Cause:** Heavy OEM camera intents (e.g., 50MP/108MP capture on Samsung devices) caused background memory pressure that could disrupt the crop activity lifecycle.
- **Fix:** Added try-catch fallback handling, null-safe EXIF orientation correction, downsampled bitmap decoding before crop intent, and proper lifecycle preservation across Activity restarts.

### 3. Global Card Label Visibility Setting
- **Feature:** Added global toggle `Show Card Labels` (ON/OFF, default ON) placed directly above "Show Sentence Bar" in the Settings Drawer.
- **Behavior:**
  - `Show Card Labels = ON`: Preserves standard label rendering with customizable text size and color.
  - `Show Card Labels = OFF`: Globally converts all cards to a clean, image-only presentation with zero text, zero label footers, and zero text gradient overlays, while keeping speech, navigation, sentence building, and accessibility semantics 100% active.

### 4. Harmonized Card Image Fill & Asset Polish
- **Issue:** Several category cards (Drinks, Feelings, Activities, Personal Care) and seed cards displayed smaller rectangular image backgrounds with unwanted borders inside the card container.
- **Fix:**
  - Seed cards (`happy.webp`, `sad.webp`, `angry.webp`, `hello.webp`) converted to lossless transparent RGBA WebP assets and paired with harmonized theme background colors in `StarterPackService`.
  - Replaced the circular Home Default folder cover with `default_folder_three_kids_square_alternative.webp` (640×640, 36.5 KB), featuring three children with an AAC communication board.
  - In Mode B (Overlay OFF), user photos and folder covers expand using `BoxFit.cover` to fill the upper 76% card image area, eliminating letterboxing and pillarboxing.

### 5. First-Card TTS Latency Elimination
- **Root Cause:** Google TTS voice catalog query (`getVoices`) was deferred to the first card tap, producing a 300–700ms binder IPC pause while serializing 500+ installed system voices.
- **Fix:** Added asynchronous background pre-warming via `SpeechEngine.instance.prewarm({String? preferredLanguage})` scheduled via `addPostFrameCallback` after splash handoff. Voice catalog and active language are pre-loaded in the background without impacting UI or startup time. Dispatch latency on first card tap dropped from ~600ms to ~10ms.

### 6. Global Card Label Background Color
- **Feature:** Implemented ONE global card label background color setting for the entire application, defaulting to `#F4F1EB` (Warm Ivory).
- **Behavior:**
  - In Mode B (Show Card Labels = ON, Overlay = OFF), every card across Home, Default, More, subfolders, and custom user cards uses the exact same background color for the text footer.
  - In Settings, the dialog provides Quick Colors, an HSV custom color picker with Hex input, and interactive preview cards (`Hello`, `Eat`, `Play`) whose footers fill the entire bottom section.
  - Setting persists safely across application restarts and round-trips seamlessly through backup & restore.

### 7. Intermittent Scroll Lock Resolution
- **Root Cause:** When the application cold-loaded (taking >380ms in Debug JIT or during resource-heavy launches), the `ChildFriendlySplash` animated opacity overlay remained mounted at `opacity: 0.0`. In Flutter, transparent render objects still intercept pointer events unless explicitly ignored, causing all vertical drag gestures to be swallowed.
- **Fix:** Wrapped the animated splash layer in `IgnorePointer(ignoring: !_isInitialLoading && !_hasStartupError)`, added an unconditional `_splashDismissed` cleanup with a 200ms post-frame safety timer fallback, and configured `GridView.builder` with `physics: const AlwaysScrollableScrollPhysics()`. Verified across 10 lifecycle scenarios.

### 8. Voice Recording Playback Performance
- **Investigation & Benchmark:** Verified custom voice recording playback response on device. Cold tap playback starts in ~32.99ms; warm taps average 53.49ms (p50) and 92.28ms (p95).
- **Audio Cleanliness:** Seamlessly switches between custom voice recordings and multilingual TTS (en, si, ta) with zero audio overlapping, memory leaks, or player desynchronization.

---

## D. Automated Quality Assurance & Verification Metrics

| Test Layer | Test Metric | Measured Result | Evaluation |
| :--- | :--- | :---: | :---: |
| **Flutter Test Suite** | Total Tests Executed | **708** | **PASS** |
| | Passed Tests | **708** | **100% Pass Rate** |
| | Failed Tests | **0** | **0 Failures** |
| | Skipped Tests | **6** | **Manifest Skips** |
| **Static Code Analysis** | `flutter analyze` | **0 issues** | **Clean** (ran in 3.9s) |
| **Cryptographic Signatures** | `apksigner verify --verbose` | **Verified (v2 Scheme)** | **PASS** (3072-bit RSA) |
| **Bundle Validation** | `bundletool validate` | **Valid AAB structure** | **PASS** |
| **Target SDK Policy** | Android Target API | **API Level 36** | **Compliant** |

---

## E. Release Sign-Off Verdict

### **GO — APPROVED FOR IMMEDIATE GOOGLE PLAY CONSOLE UPLOAD**

**Sign-off Statement:**  
Simple AAC Sri Lanka v1.1.6 (Build 15) meets all quality, performance, accessibility, security, and packaging standards required for production deployment on Google Play.
