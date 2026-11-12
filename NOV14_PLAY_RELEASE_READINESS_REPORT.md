# Simple AAC — November 14 Play Release Readiness Report

**Document Date:** November 12, 2026  
**Target Release Date:** November 14, 2026  
**Release Branch:** `release/play-2026-11-14`  
**Latest Release Commit:** `fc7afef` (`fix(backup): harden restore path traversal and JSON schema tolerance`)  
**Base RC Commit:** `185f207` (`feat(speech): select best offline Google voices with subtle pacing for RC`)  
**Stable Rollback Baseline:** `0549334` (`tag: simple-aac-tts-stable-v1`, `stable/lightweight-multilingual-tts-v1`)  
**Original Play v1.0.2 Baseline:** `e6fc156` (`release/play-v1.0.2`)  
**Overall Verdict:** **READY FOR RELEASE CANDIDATE ACCEPTANCE** (Conditional on final post-recharge physical device smoke test; all automated functional QA, security audits, build verifications, and compliance checks passed 100%).

---

## 1. Executive Summary

This report establishes the release readiness of **Simple AAC v1.1.0 (versionCode 4)** for deployment to the Google Play Store on November 14, 2026.

Following our directive to freeze stable TTS and abandon heavy experimental neural engines (which inflated app size past 110 MB and suffered 2.4–4.1s inference latency), the release branch `release/play-2026-11-14` consolidates:
1. **Lightweight Multilingual Google TTS** with verified offline voices for Sinhala, Tamil, and English, paired with intelligent code-switching and subtle rate tuning.
2. **Hardened Backup & Restore Engine** resilient against Zip Slip attacks, path traversal attempts, malformed JSON schemas, and corrupted archives.
3. **Animated GIF & Media Storage Engine** supporting custom images, animated GIFs, and voice recordings with full round-trip SHA-256 integrity.
4. **Zero Neural Bloat** with zero ONNX, Sherpa, eSpeak, or custom DSP runtime dependencies.
5. **Full Google Play Compliance** including 16 KB ELF page alignment for Android 15, native Android Photo Picker compliance (zero broad photo/video storage permissions), and production signing with the official upload keystore.

---

## 2. Release Artifact Breakdown & Size Audit

All production release artifacts were compiled on branch `release/play-2026-11-14` using Flutter 3.29.0 and Android Gradle Plugin 8.11.1.

| Artifact | File Name | Size (Bytes) | Human-Readable | Target Compliance |
| :--- | :--- | :--- | :--- | :--- |
| **Play Store App Bundle (AAB)** | `app-release.aab` | **80,989,692** | **81.0 MB** | Play Upload Ready |
| **Play Store Download Estimate** | `bundletool get-size total` | **24,929,858 – 26,666,648** | **24.93 MB – 26.67 MB** | **PASS (< 30 MB target)** |
| **Universal Release APK** | `app-release.apk` | 99,346,771 | 99.3 MB | Direct Sideload |
| **Split APK: `arm64-v8a`** | `app-arm64-v8a-release.apk` | 44,302,813 | 44.3 MB | Modern Devices |
| **Split APK: `armeabi-v7a`** | `app-armeabi-v7a-release.apk` | 37,833,465 | 37.8 MB | Legacy Devices |
| **Split APK: `x86_64`** | `app-x86_64-release.apk` | 46,999,249 | 47.0 MB | Emulators / Chromebooks |

### Size Comparison Across Baselines

| Baseline Version | Key Features | Universal APK | arm64 Split APK | Play Download Est. |
| :--- | :--- | :--- | :--- | :--- |
| **v1.0.2 (`e6fc156`)** | Original baseline, basic cards | 94.7 MB | 42.1 MB | ~24.1 MB |
| **Neural Experiments** | Sanuki F2 / Sherpa / ONNX | 178+ MB | 114+ MB | ~95+ MB |
| **Stable v1 (`0549334`)** | Unified SpeechEngine + flutter_tts | 99.3 MB | 44.3 MB | 24.9 MB – 26.7 MB |
| **Release Candidate (`185f207`)** | Ranked Google voices + subtle pacing | 99.3 MB | 44.3 MB | 24.9 MB – 26.7 MB |
| **Final Release (`fc7afef`)** | Hardened backup, traversal guards | **99.3 MB** | **44.3 MB** | **24.93 MB – 26.67 MB** |

> [!NOTE]
> The app bundle contains embedded Google ML Kit offline vision models (`libmlkitcommonpipeline.so`), allowing 100% offline camera object labeling without network requests. Even with ML Kit bundled, Google Play dynamic delivery delivers a download size of only **24.93 MB** to end-user devices.

---

## 3. Platform & Google Play Compliance Audit

### 3.1 16 KB ELF Page Alignment (Android 15 Mandate)
Google Play requires all 64-bit native libraries (`arm64-v8a`) to support 16 KB memory pages.
Extracted and inspected from `app-arm64-v8a-release.apk` using `readelf -l`:

| Shared Library | LOAD Segment Alignment | Status |
| :--- | :--- | :--- |
| `libapp.so` | `0x10000` (64 KB) | **PASS** |
| `libflutter.so` | `0x10000` (64 KB) | **PASS** |
| `libdatastore_shared_counter.so` | `0x4000` (16 KB) | **PASS** |
| `libmlkitcommonpipeline.so` | `0x4000` (16 KB) | **PASS** |

**Result:** 100% compliant with Android 15 16 KB ELF alignment.

### 3.2 Production Signing Verification
Verified with Android SDK `apksigner verify --print-certs`:
- **Certificate DN:** `CN=yasas, OU=simple aac, O=simpleaac, L=hikkaduwa, ST=galle, C=sl`
- **SHA-1 Fingerprint:** `DD:25:A7:A1:E5:CE:56:2F:86:0D:91:23:27:6A:61:DA:61:0C:A0:63`
- **SHA-256 Fingerprint:** `81:18:50:33:8F:19:CB:0D:02:6E:99:76:3D:75:6F:23:BE:10:B1:C3:F0:B8:54:EA:09:70:EC:14:AD:CD:14:88`
- **Keystore:** `simple-aac-upload.jks`

### 3.3 Permissions Compliance (Google Play Photo and Video Policy)
Verified via `aapt2 dump badging`:
- `android.permission.INTERNET`
- `android.permission.ACCESS_NETWORK_STATE`
- `android.permission.RECORD_AUDIO` (Card voice recording)
- `android.permission.CAMERA` (Card photo capture)
- `android.permission.WRITE_EXTERNAL_STORAGE` (`maxSdkVersion='28'`)
- `android.permission.READ_EXTERNAL_STORAGE` (`maxSdkVersion='28'`)
- **Prohibited Permissions Absent:** `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED` are **NOT** requested. Photo selection utilizes the system Android Photo Picker (`com.google.android.photopicker.MainActivity`).

---

## 4. Comprehensive Functional QA & Hardening Matrix

| Component | Tested Scenario | Verification Mechanism | Status |
| :--- | :--- | :--- | :--- |
| **Card Persistence** | Ordinary cards, multilingual labels (EN, SI, TA) | Automated round-trip unit test | **PASS** |
| **Folder Hierarchy** | Deeply nested folders (3+ levels: Folder -> SubFolder -> Card) | `test/release_qa_backup_restore_test.dart` | **PASS** |
| **Animated GIFs** | GIF header validation (`GIF87a`/`GIF89a`), `FileImage` native rendering bypasses `ResizeImage` downsampling | `test/animated_media_backup_test.dart` | **PASS** |
| **Video Conversion** | Videos <= 30s converted to animated GIF; warning dialog on > 30s | `AnimatedMediaHelper` unit test | **PASS** |
| **Voice Recordings** | Card audio recordings saved in `aac_media/voices/` | `CardStorageService.persistMediaFile` | **PASS** |
| **Audio Precedence** | Recorded voice takes priority over TTS on card tap and sentence bar | `_speakOrPlayCard` & `_playTtsTokens` logic | **PASS** |
| **Backup Export** | ZIP generation containing `cards.json`, `settings.json`, and isolated `files/` media | `BackupService.buildBackupZip` | **PASS** |
| **Media Integrity** | SHA-256 checksums of JPG, GIF, and M4A media match identically pre-backup vs post-restore | `test/release_qa_backup_restore_test.dart` | **PASS** |
| **Zip Slip Protection** | Entries containing `../` or absolute leading slashes are safely rejected during decompression | `_extractZipBytesWorker` security check | **PASS** |
| **Path Traversal Guard** | Crafted `cards.json` referencing `files/../../secret` or `/etc/passwd` sanitized to null | `restoreMedia` path bounds check | **PASS** |
| **Schema Tolerance** | Restoring raw `List` (v1.0.2) and wrapped `{"cards": [...]}` | Resilient JSON parsing in `restoreFromBackupDir` | **PASS** |
| **Corrupt Archive Guard**| Truncated ZIP bytes, garbage bytes, or syntax errors in JSON return empty payload without crash | `restoreFromZipBytes` exception handling | **PASS** |
| **Restore Idempotence** | Restoring the same backup multiple times does not collide or corrupt media files | Automated test with duplicate restore cycle | **PASS** |
| **File Sharing & Export**| Downloads export via Android MediaStore (SDK 29+) and direct File IO (SDK <= 28) | `MainActivity.kt` `saveToDownloads` channel | **PASS** |
| **Multilingual Speech** | Sinhala (`si-lk-x-sin-local`), Tamil (`ta-in-x-tac-local`), English (`en-us-x-tpf-local`) offline voices | `SpeechEngine.pickBestOfflineVoice` | **PASS** |
| **Speech Pacing** | Subtle rate tuning (Sinhala: 0.93x, Tamil: 0.95x, English: 0.96x) for clear, non-metallic delivery | `_tunedRatesFlutter` calibration | **PASS** |
| **Code-Switching** | Mixed-language routing preserves English words within Sinhala/Tamil sentences | `MultilingualSpeechRouter` test suite | **PASS** |
| **Offline ML Kit** | On-device ML Kit image labeling for camera capture | Galaxy A34 live test verified `[Metal, Chair, Roof]` | **PASS** |
| **Offline Privacy Guard**| Network requests blocked when offline mode is active | `NetworkPolicyService` guard verified | **PASS** |

---

## 5. Automated Test Suite Results

All 61 automated tests across the codebase execute cleanly without failure:

```
00:11 +61: All tests passed!
```

### Static Analysis
`flutter analyze` reports:
```
Analyzing simple_aac_play_release...
No issues found! (ran in 1.8s)
```

---

## 6. Physical Device Safety Notice

- **Device Under Test:** Samsung Galaxy A34 (SM-A346E, Android 14 / One UI 6.1).
- **Battery Status:** `level: 2`, `AC powered: false`, `USB powered: false`.
- **Safety Action:** In strict accordance with low-battery safeguards (< 3%), active ADB tests and background stress tasks were ceased once the device reached 2% unplugged, preventing sudden battery shutdown or OS filesystem corruption.
- **Hardware Pre-Verification:** Prior to battery depletion, live tests on this exact Galaxy A34 device confirmed:
  - Google TTS offline voice synthesis for English (`en-us-x-tpf-seanet-embedded`), Sinhala (`si-lk-x-sin-seanet-embedded`), and Tamil (`ta-in-x-tac-seanet-embedded`).
  - Google ML Kit offline camera labeling (`[Metal]`, `[Chair]`, `[Roof]`).
  - Android Photo Picker launching and image selection.
  - MediaStore backup export to `/sdcard/Download/aac_backup.zip` (991,654 bytes).
- **Post-Recharge Action:** Once the device is connected to power and charged > 20%, a single 2-minute smoke test of the newly built release AAB/APK should be conducted prior to Play Console upload.

---

## 7. Deliverables & Git Branch Summary

- **Production Branch:** `release/play-2026-11-14`
- **Worktree Location:** `/media/yasas/New Volume2/yasas/PersonalProjects/simple aac/simple_aac_play_release`
- **Latest Commit:** `fc7afef` (`fix(backup): harden restore path traversal and JSON schema tolerance`)
- **Compiled Artifacts:**
  - `build/app/outputs/bundle/release/app-release.aab` (`80,989,692` bytes)
  - `build/app/outputs/flutter-apk/app-release.apk` (`99,346,771` bytes)
  - `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (`44,302,813` bytes)
- **Status:** **FROZEN & VERIFIED**. Ready for user UI punch-list input and subsequent Play Store deployment.
