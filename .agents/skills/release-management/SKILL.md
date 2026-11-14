---
name: release-management
description: Release engineering procedures, versioning rules, Git branching practices, changelog updates, and Play Store qualification protocols for Simple AAC.
---

# Simple AAC Release Management Skill

This skill governs the end-to-end release lifecycle for Simple AAC, establishing strict versioning, git safety, verification tracking, changelog maintenance, application identity, signing configuration, and Play Store deployment controls.

---

## 1. Release Architecture & Branching Model

### 1.1 Branch Hierarchy
* **`main` / `master`:** Protected baseline branch.
* **`release/play-YYYY-MM-DD`:** Dedicated release candidate branch (e.g. `release/play-2026-11-14`).
  * Used for hardening, UI refinement, bug fixes, QA evidence generation, and release documentation.
  * Work is conducted in isolated worktrees:
    `/media/yasas/New Volume2/yasas/PersonalProjects/simple aac/simple_aac_play_release`

### 1.2 Stable Historical Baselines & Rollback Points
Always preserve and reference verified points in the Git graph:
* **`e6fc156` (release/play-v1.0.2):** Original production Play Store release (`versionCode = 3`, `lk.yasas.simpleaac`).
* **`0549334` (`tag: simple-aac-tts-stable-v1`):** Lightweight stable multilingual Google TTS baseline.
* **`185f207` (release-candidate/lightweight-multilingual-v1):** Base release candidate with ranked offline voice routing.
* **`fc7afef`:** Hardened backup and restore engine with Zip Slip traversal guards.
* **`8fbfa53`:** Initial November 14 release readiness documentation.
* **`6027a0d` (`tag: checkpoint/pre-color-picker-redesign`):** Checkpoint commit for home header redesign.
* **`fe4b0e5` (`tag: v1.1.0-build7-2026-11-14`):** Build 7 release candidate (*Rejected by Play Console due to package mismatch `com.example.simple_aac_app`*).
* **`908d41d` (`tag: v1.1.0-build8-2026-11-14`):** **Official Production Build 8** (`versionCode = 8`, `applicationId = lk.yasas.simpleaac`). Accepted by Google Play and In Review.

---

## 2. Production Application Identity Standards

### 2.1 The Immutable Google Play Package Name
* **Required Production Application ID:** **`lk.yasas.simpleaac`**
* **CRITICAL INVARIANT:** Never build production release artifacts with `com.example.simple_aac_app`. Google Play Console will reject the bundle with:
  > *"Your APK or Android App Bundle needs to have the package name `lk.yasas.simpleaac`."*

### 2.2 Gradle Decoupled Namespace Pattern
In `android/app/build.gradle.kts`:
```kotlin
android {
    // Keep namespace as com.example.simple_aac_app so Kotlin/Java code does not break
    namespace = "com.example.simple_aac_app"

    defaultConfig {
        // MUST be lk.yasas.simpleaac for production Google Play acceptance
        applicationId = "lk.yasas.simpleaac"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // Suffix provides isolated dev installation alongside production
            applicationIdSuffix = ".dev"
            manifestPlaceholders["appName"] = "Simple AAC DEV"
        }
        release {
            // Zero suffix: exactly "lk.yasas.simpleaac"
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 2.3 Provider Authorities
All Android FileProviders and component providers automatically namespace to the final `applicationId`:
* `lk.yasas.simpleaac.flutter.image_provider`
* `lk.yasas.simpleaac.flutter.share_provider`
* `lk.yasas.simpleaac.mlkitinitprovider`
* `lk.yasas.simpleaac.androidx-startup`

---

## 3. Google Play Upload Keystore & Signing Configuration

### 3.1 Keystore Metadata
* **Keystore File Location:** `/home/yasas/simple-aac-signing/simple-aac-upload.jks`
* **Key Alias:** `simpleaacupload`
* **Algorithm:** RSA 3072-bit, SHA256withRSA
* **Subject / Issuer:** `CN=yasas, OU=simple aac, O=simpleaac, L=hikkaduwa, ST=galle, C=sl`
* **Validity:** Mon Nov 02 12:18:18 IST 2026 through Fri Mar 20 12:18:18 IST 2054
* **Backup Certificate File:** `/home/yasas/simple-aac-signing/upload_certificate.pem`

### 3.2 Public Certificate Fingerprints (Upload Key)
* **SHA-256 Fingerprint:**  
  `81:18:50:33:8F:19:CB:0D:02:6E:99:76:3D:75:6F:23:BE:10:B1:C3:F0:B8:54:EA:09:70:EC:14:AD:CD:14:88`
* **SHA-1 Fingerprint:**  
  `DD:25:A7:A1:E5:CE:56:2F:86:0D:91:23:27:6A:61:DA:61:0C:A0:63`

### 3.3 Google Play App Signing Architecture
* Simple AAC utilizes **Google Play App Signing**.
* The keystore `simple-aac-upload.jks` contains the registered **Upload Key**.
* Developers sign the release App Bundle (`.aab`) with this upload key.
* When uploaded, Google Play verifies the upload signature against the registered certificate fingerprint (`81:18:50:...`), strips the upload signature, and re-signs the delivered APKs with Google's managed production App Signing key.
* **SECURITY RULE:** Never commit `key.properties`, passwords, or `.jks` files to Git. `android/key.properties` must point to the local filesystem path outside the repository.

---

## 4. User Data Sandboxing & In-Place Upgrades

### 4.1 Production In-Place Upgrade Path
* In Android, app data is sandboxed under `/data/user/0/<applicationId>/app_flutter/`.
* When users update from version `1.0.2` (`versionCode = 3`, `lk.yasas.simpleaac`) to version `1.1.0` (`versionCode = 8`, `lk.yasas.simpleaac`), Android treats this as an **in-place update**.
* **Zero data loss occurs:** Custom communication cards (`aac_cards_v1.json`), audio recordings (`aac_media/voices/`), and images/GIFs (`aac_media/images/`) are 100% preserved.

### 4.2 Cross-Package Sandbox Limitation
* Test builds installed under `com.example.simple_aac_app` (or `.dev`) reside in `/data/user/0/com.example.simple_aac_app/`.
* Because Android enforces process isolation between distinct application IDs, `lk.yasas.simpleaac` cannot read another package's private sandbox.
* Caregivers and testers who created cards in test builds must use Simple AAC's built-in **Export Backup** feature to create a `.zip` file, and then **Import Backup** into `lk.yasas.simpleaac`.

---

## 5. Versioning & Conventions

### 5.1 Version Code & Semantic Versioning
In `pubspec.yaml`:
```yaml
version: 1.1.0+8
```
* **Semantic Version (`1.1.0`):** Visible version shown to users in Settings and Play Store listing.
* **Version Code (`8`):** Strictly monotonically increasing integer required by Google Play for updates (`1.0.2` = 3, `1.1.0 Build 7` = 7, `1.1.0 Build 8` = 8).

### 5.2 Conventional Commits
All Git commit messages on release branches must follow Conventional Commits:
* `feat(ui): ...` — New user-facing UI enhancements.
* `fix(release): ...` — Release configuration or bug fixes.
* `docs(release): ...` — Documentation and changelog updates.
* `test(...): ...` — Automated tests.

---

## 6. Mandatory Quality Gate Workflow

Before any release artifact is qualified:
1. **Analyze:** `flutter analyze` must report `No issues found!`.
2. **Test:** `flutter test` must pass 100% of all tests (117/117).
3. **Build Bundle:** `flutter build appbundle --release`.
4. **Inspect Manifest:** Verify package name with bundletool:
   ```bash
   java -jar /home/yasas/.local/bin/bundletool.jar dump manifest --bundle=build/app/outputs/bundle/release/app-release.aab | grep 'package="lk.yasas.simpleaac"'
   ```
5. **Verify Signing:**
   ```bash
   jarsigner -verify build/app/outputs/bundle/release/app-release.aab
   ```
6. **Verify 16 KB ELF Alignment:** Check all 64-bit `.so` files using `readelf -W -l`.
