# Simple AAC — Google Play Signing & Application Identity Guide

**Last Updated:** November 14, 2026  
**Applicable Application:** Simple AAC Sri Lanka  
**Target Release:** Version 1.1.0 (Build 8)  

---

## 1. Application Identity: `lk.yasas.simpleaac` vs `com.example.simple_aac_app`

### 1.1 The Golden Rule of Package Identity
* **Official Google Play Application ID:** **`lk.yasas.simpleaac`**
* **The Root Problem:** The initial Flutter application template defaulted to `com.example.simple_aac_app`. If an AAB is compiled with `com.example.simple_aac_app`, Google Play Console will reject the release immediately with the error:
  > *"Your APK or Android App Bundle needs to have the package name `lk.yasas.simpleaac`."*
* **The Solution:** In `android/app/build.gradle.kts`, set:
  ```kotlin
  defaultConfig {
      applicationId = "lk.yasas.simpleaac"
  }
  ```

### 1.2 The Decoupled Namespace Pattern
To prevent breaking existing Kotlin/Java code or requiring mass-renaming of source trees:
* **`namespace = "com.example.simple_aac_app"`** governs internal Java/Kotlin packages and the generated `R` class.
* **`applicationId = "lk.yasas.simpleaac"`** governs the operating system package identity and Google Play listing.
* These two properties do NOT need to match. This decoupled pattern allows `MainActivity.kt` and `VideoGifEncoder.kt` to stay in `package com.example.simple_aac_app` while the final compiled AAB is published under `lk.yasas.simpleaac`.

### 1.3 Build Type Suffixes for Development Isolation
```kotlin
buildTypes {
    debug {
        applicationIdSuffix = ".dev" // Installs as lk.yasas.simpleaac.dev
        manifestPlaceholders["appName"] = "Simple AAC DEV"
    }
    profile {
        applicationIdSuffix = ".dev" // Installs as lk.yasas.simpleaac.dev
        manifestPlaceholders["appName"] = "Simple AAC DEV"
    }
    release {
        // Zero suffix! Publishes exactly as lk.yasas.simpleaac
        signingConfig = signingConfigs.getByName("release")
    }
}
```

---

## 2. Google Play Upload Keystore & Signing Architecture

### 2.1 Keystore Specifications
* **Keystore Location:** `/home/yasas/simple-aac-signing/simple-aac-upload.jks`
* **Key Alias:** `simpleaacupload`
* **Key Type:** 3072-bit RSA
* **Signature Algorithm:** SHA256withRSA
* **Subject / Issuer:** `CN=yasas, OU=simple aac, O=simpleaac, L=hikkaduwa, ST=galle, C=sl`
* **Validity Period:** November 2, 2026 to March 20, 2054
* **Backup Certificate:** `/home/yasas/simple-aac-signing/upload_certificate.pem`

### 2.2 Public Certificate Fingerprints
* **SHA-256:** `81:18:50:33:8F:19:CB:0D:02:6E:99:76:3D:75:6F:23:BE:10:B1:C3:F0:B8:54:EA:09:70:EC:14:AD:CD:14:88`
* **SHA-1:** `DD:25:A7:A1:E5:CE:56:2F:86:0D:91:23:27:6A:61:DA:61:0C:A0:63`

### 2.3 How Google Play App Signing Works
1. When building a release App Bundle, Gradle signs `app-release.aab` with `simple-aac-upload.jks` (the **Upload Key**).
2. The developer uploads `app-release.aab` to Google Play Console.
3. Google Play Console verifies that the signature matches the registered upload certificate fingerprint (`81:18:50:...`).
4. Google Play removes the upload key signature and signs the generated device-optimized APKs with the managed **Google Play App Signing Key**.
5. End users receive APKs signed by Google's key.

### 2.4 Critical Security Policy
* **NEVER commit `simple-aac-upload.jks`, `key.properties`, or passwords into Git.**
* `key.properties` must be listed in `.gitignore`.
* `key.properties` must point to the secure absolute location outside the repository:
  ```properties
  storeFile=/home/yasas/simple-aac-signing/simple-aac-upload.jks
  keyAlias=simpleaacupload
  # Passwords stored in secure personal password manager
  ```

---

## 3. Data Migration & Sandbox Boundaries

### 3.1 Seamless In-Place Play Store Upgrades
* Android app storage paths are tied to `applicationId`: `/data/user/0/<applicationId>/app_flutter/`.
* When existing Google Play users update from `1.0.2` (`versionCode = 3`, `lk.yasas.simpleaac`) to `1.1.0` (`versionCode = 8`, `lk.yasas.simpleaac`), Android treats this as an **in-place update**.
* **Zero data loss:** All cards in `aac_cards_v1.json`, custom recorded voice clips in `aac_media/voices/`, and card images in `aac_media/images/` remain untouched and accessible.

### 3.2 Test Builds Cross-Package Migration
* If a caregiver or QA tester created cards in a build configured with `com.example.simple_aac_app` (or `.dev`), Android sandboxes that data in `/data/user/0/com.example.simple_aac_app/`.
* The Android OS prevents `lk.yasas.simpleaac` from accessing `/data/user/0/com.example.simple_aac_app/`.
* **Migration Procedure:** Use Simple AAC's built-in **Export Backup** feature to generate a standard `.zip` archive on the device or Cloud storage, and then use **Import Backup** in `lk.yasas.simpleaac` to restore all cards and media.

---

## 4. Verification Cheat-Sheet for Future Releases

```bash
# 1. Build Production App Bundle
flutter build appbundle --release

# 2. Verify Manifest Package Name & Version
java -jar /home/yasas/.local/bin/bundletool.jar dump manifest \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  | head -n 5

# 3. Verify Signature & Certificate
jarsigner -verify -verbose -certs \
  build/app/outputs/bundle/release/app-release.aab

# 4. Verify 16 KB Page Alignment on 64-bit binaries
unzip -q -o build/app/outputs/bundle/release/app-release.aab "base/lib/*" -d /tmp/test_libs
find /tmp/test_libs/base/lib -name "*.so" | while read so; do
    echo "=== $so ==="
    readelf -W -l "$so" | grep LOAD
done
rm -rf /tmp/test_libs
```
