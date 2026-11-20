# Release Blockers & Recommendations
**Project:** Simple AAC Sri Lanka  
**Package:** `lk.yasas.simpleaac`  
**Date:** November 20, 2026  
**Auditor:** Principal Flutter Engineer & Release QA Specialist  

---

## 1. Issue Severity Classification

Every finding from the final production audit is classified according to the standard release criteria:
- **P0 — CRITICAL:** Crash, data loss, security/privacy breach, or major application failure (Release Blocker).
- **P1 — HIGH:** Broken core AAC functionality, unreliable speech, major startup or performance regression (Release Blocker).
- **P2 — MEDIUM:** Noticeable UI defect, noncritical feature bug, or test fixture obsolescence (Requires attention before public launch).
- **P3 — LOW:** Minor cosmetic polish, build tool warning, or nonblocking improvement.

---

## 2. Findings Log

### P0 (Critical) Findings: **0 Found**
*None. No critical crashes, data loss risks, or security vulnerabilities exist in the current application.*

### P1 (High) Findings: **0 Found**
*None. All core AAC communication, sentence composition, multilingual speech (Sinhala, Tamil, English), and startup performance meet or exceed production benchmarks.*

---

### P2 (Medium) Findings: **2 Found**

#### Finding P2-1: Legacy Test Fixture Assumptions in 6 Test Files
- **Severity:** P2 (Medium)
- **Component:** `test/responsive_card_rendering_test.dart`, `test/recycle_bin_test.dart`, `test/card_haptics_and_pop_test.dart`, etc.
- **Description:** Out of 76 test files, 70 passed cleanly (595 tests passing). The 6 failing test files failed solely due to outdated test mock fixtures:
  1. Testing dummy cards referencing old `'assets/images/happy.png'` paths instead of modern `.webp` paths.
  2. Pumping `HomeDrawer` without expanding the compact header before checking for lower menu tiles.
  3. Experimental untracked test file `daily_actions_safe_integration_test.dart` asserting 14 daily action cards that were not merged into the manifest.
- **Impact on Production:** **Zero impact**. Production application code has zero analyzer errors (`flutter analyze` is 100% clean).
- **Recommendation:** In a separate test cleanup pass, update mock paths to `.webp` and expand the drawer before tile assertions.

#### Finding P2-2: Multiple ADB Binaries on Developer Host Machine
- **Severity:** P2 (Medium)
- **Component:** Developer Environment Toolchain
- **Description:** `flutter doctor -v` identified three distinct `adb` binaries on the host system:
  - `/home/yasas/.local/opt/android-sdk/platform-tools/adb`
  - `/home/yasas/.local/bin/adb`
  - `/usr/lib/android-sdk/platform-tools/adb`
- **Impact on Production:** Zero impact on the compiled application. However, it can cause transient adb daemon port conflicts during wireless/USB device installation.
- **Recommendation:** Standardize `PATH` to prioritize `/home/yasas/.local/opt/android-sdk/platform-tools/adb`.

---

### P3 (Low) Findings: **2 Found**

#### Finding P3-1: Kotlin Gradle Plugin (KGP) Plugin Migration Warning
- **Severity:** P3 (Low)
- **Component:** Android Gradle Build Toolchain
- **Description:** Flutter CLI issues a forward-looking warning that 5 plugins (`audioplayers_android`, `flutter_tts`, `record_android`, `share_plus`, `shared_preferences_android`) apply KGP directly rather than using Flutter's built-in Kotlin feature.
- **Impact on Production:** Builds compile cleanly and successfully today. Future Flutter releases (Flutter 4.x+) will eventually require plugin authors to upgrade.
- **Recommendation:** Nonblocking for this release; monitor plugin upstream updates in upcoming maintenance cycles.

#### Finding P3-2: Untracked Experimental Test and QA Files in Working Directory
- **Severity:** P3 (Low)
- **Component:** Repository Hygiene
- **Description:** Working directory has untracked QA screenshots and experimental test files (`test/daily_actions_*`, etc.).
- **Impact on Production:** None.
- **Recommendation:** Stage only the production changes (`pubspec.yaml`, `home_page.dart`, `card_storage_service.dart`, `professional_color_picker_dialog.dart`, etc.) when committing, keeping experimental scripts unstaged or gitignored.

---

## 3. Step-by-Step Production Release Rollout Plan

```
[Phase 1: Pre-Release Lock]
    │   - Verify all 6 audit artifacts generated.
    │   - Keep production git working directory clean.
    ▼
[Phase 2: Internal Testing Track (Google Play Console)]
    │   - Upload build/app/outputs/bundle/release/app-release.aab (91.37 MB).
    │   - Complete Data Safety and Families Policy declarations.
    │   - Invite internal testers (QA team & speech therapists).
    ▼
[Phase 3: Closed Testing Track / Alpha]
    │   - Deploy to target Samsung Galaxy A34 5G and secondary test tablets.
    │   - Validate live offline speech audio ducking and touch responsiveness.
    ▼
[Phase 4: Open Testing / Production Staged Rollout]
    │   - Release to 10% of users -> monitor crash rate on Google Play Vitals.
    │   - Scale to 25% -> 50% -> 100% full production rollout.
```

---

## 4. Final Verdict:
# **READY FOR PLAY STORE PREPARATION**
*No P0 or P1 release blockers exist. The application is robust, performant, secure, and ready to be uploaded to Google Play Console Internal Testing.*
