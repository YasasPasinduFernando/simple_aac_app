# Simple AAC Sri Lanka — Official Release Practices & Playbook

This runbook defines the standard release engineering practices, security protocols, signing procedures, and Google Play Console deployment processes for **Simple AAC Sri Lanka** (`lk.yasas.simpleaac`).

---

## 1. Code Freeze & Release Branching Protocols

1. **Frozen Baseline:**
   - Production builds must **never** be generated from uncommitted or dirty working directories.
   - All release branches follow the naming convention:
     ```
     release/play-store-rc-YYYYMMDD-vX.Y.Z
     ```
   - Once a release candidate is finalized and verified, the release branch enters **Release Freeze**. Only confirmed release-blocking defect fixes may be committed to this branch.

2. **Branch Synchronization:**
   - Before building artifacts, verify local and remote branch parity:
     ```bash
     git rev-parse HEAD
     git rev-parse origin/<release-branch>
     ```
   - Both SHAs must match exactly.

---

## 2. Cryptographic Signing & Keystore Management

### 2.1 Two-Tier Signing Architecture
* **Tier 1 (Local Upload Keystore):**
  - Path: `android/app/upload-keystore.jks`
  - Alias: `upload`
  - Configuration: `android/key.properties` (never committed to public repositories).
  - Purpose: Authenticates uploads to Google Play Console.
* **Tier 2 (Google Play App Signing):**
  - Google securely holds the master app signing key.
  - Google verifies the upload signature, replaces it with the master release certificate, and generates optimized distribution APKs/split-APKs for end-user devices.

### 2.2 Secure Verification Command
To verify that an AAB or APK is signed with the correct production upload certificate:
```bash
apksigner verify --verbose --print-certs path/to/app-release.apk
```

---

## 3. Production Build Generation

### 3.1 Google Play App Bundle (AAB)
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`
Matching ProGuard Mapping: `build/app/outputs/mapping/release/mapping.txt`

### 3.2 Universal Production APK Generation (for Caregiver Sideloading)
Do not build a debug APK for sideloading. Use `bundletool` with the production keystore:
```bash
bundletool build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=build/app/outputs/bundle/release/app-release.apks \
  --mode=universal \
  --ks=android/app/upload-keystore.jks \
  --ks-pass=file:android/key.properties \
  --ks-key-alias=upload \
  --key-pass=file:android/key.properties

unzip -p build/app/outputs/bundle/release/app-release.apks universal.apk > build/app/outputs/apk/release/app-release-universal.apk
```

---

## 4. Integrity Verification & Checksum Standard

Every release artifact must have its SHA-256 cryptographic checksum computed and verified before upload or distribution:
```bash
sha256sum build/app/outputs/bundle/release/app-release.aab
sha256sum build/app/outputs/apk/release/app-release-universal.apk
```
* **Mandatory Action:** Record the exact SHA-256 in [RELEASE_LOG.md](file:///media/yasas/New%20Volume2/yasas/PersonalProjects/simple%20aac/simple_aac_play_release/RELEASE_LOG.md).
* Never distribute or upload an artifact whose checksum does not match the build log.

---

## 5. Google Play Console Deployment Rules

1. **Track Selection:**
   - **Internal Testing:** Fast iteration with internal QA team (immediate availability).
   - **Closed / Open Testing:** Pre-release verification with pilot schools and speech clinics.
   - **Production:** Public release on Google Play Store.

2. **Managed Publishing:**
   - Always ensure **Managed Publishing** is turned **ON** if coordination with clinical partners or localized marketing is required.
   - This ensures Google Play review approvals do not auto-publish until the team triggers manual rollout.

3. **Release Notes (Localized in 3 Languages):**
   Provide user-facing notes in English, Sinhala, and Tamil for each release:
   - `<en-GB>...</en-GB>`
   - `<si-LK>...</si-LK>`
   - `<ta-LK>...</ta-LK>`

---

## 6. Emergency Hotfix & Rollback Procedure

If a critical crash or regression is identified post-release:
1. Identify the root cause in the release branch.
2. Formulate a minimal, single-point surgical fix following lazy senior dev rules.
3. Increment `versionCode` by +1 in `pubspec.yaml` (Google Play rejects re-uploading an existing versionCode).
4. Run full automated suite: `flutter test` (must pass 100%).
5. Generate signed AAB and universal APK.
6. Submit new hotfix build to Google Play Console with expedited review request.
