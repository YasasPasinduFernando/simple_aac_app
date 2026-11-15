# Simple AAC — November 16 Google Play Release Sign-Off Report

**Document Date:** November 16, 2026  
**Target Release:** Simple AAC v1.1.1 (versionCode: 9)  
**Target Release Channel:** Google Play Store (Production Track)  
**Release Branch:** `feature/v1.1.1-settings-live-previews`  
**Latest Release Commit:** `a1380a5` (`chore(release): bump version to 1.1.1+9 for Google Play Console release`)  
**Package Identifier:** `lk.yasas.simpleaac`  
**Overall Verdict:** **100% PRODUCTION SIGN-OFF APPROVED (ALL GATES PASSED)**

---

## 1. Executive Summary

This formal Sign-Off Report certifies **Simple AAC v1.1.1 (Build 9)** as ready for production rollout to Google Play Console.

All features, bug fixes, UI/UX enhancements, and accessibility additions requested by the product team have been implemented, verified through automated unit, integration, and stress tests, and validated directly on physical Samsung Galaxy A34 5G hardware.

---

## 2. Release Artifacts & Verification Table

| Artifact | File Name | Size (Bytes) | Size (MB) | SHA-256 Checksum | Channel / Use Case |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Play Store App Bundle (AAB)** | `app-release.aab` | **82,229,590** | **82.2 MB** | `83efc7cdbc0d8241a1d3fbbb29c94901dcdafad11cdb178270c7c89b8b051779` | **Google Play Console Upload** |
| **Universal Release APK** | `app-release.apk` | **100,645,836** | **100.6 MB** | `dc9e9c31770d8cb3b6a554e27259fc5b7b8378bbaaf647ddb995e043a0a3aeb1` | Direct Device Testing / Sideload |

* **AAB Absolute Path:** [`simple_aac_play_release/build/app/outputs/bundle/release/app-release.aab`](file:///media/yasas/New%20Volume2/yasas/PersonalProjects/simple%20aac/simple_aac_play_release/build/app/outputs/bundle/release/app-release.aab)
* **APK Absolute Path:** [`simple_aac_play_release/build/app/outputs/flutter-apk/app-release.apk`](file:///media/yasas/New%20Volume2/yasas/PersonalProjects/simple%20aac/simple_aac_play_release/build/app/outputs/flutter-apk/app-release.apk)

### Manifest & Keystore Verification:
- **Package ID:** `lk.yasas.simpleaac`
- **versionCode:** `9` *(Incremented from production Build 8 to satisfy Google Play Console upload rules)*
- **versionName:** `1.1.1`
- **minSdkVersion:** `24` (Android 7.0+)
- **targetSdkVersion:** `36` (Android 15 ready)
- **Signing Keystore:** Signed with official Google Play upload key (`android/key.properties`).
- **16 KB ELF Page Alignment:** Verified compliant for Android 15.

---

## 3. Comprehensive Feature & Fix Breakdown (v1.1.1)

### 3.1 TTS Bar Settings & Independent Action Controls
- Renamed Settings Drawer item and modal header from *"TTS Bar Sizing"* to **"TTS Bar Settings"** (`"Bar size, Delete & Clear buttons"`).
- Replaced the single toggle with **two independent switches**:
  - **Show Delete Button** (*"Remove last tapped word card"*)
  - **Show Clear Button** (*"Clear entire sentence bar"*)
- Both buttons enabled by default (`true`).
- Reactive **Live Preview** in the dialog reflecting height scaling and independent button visibility in real time.
- Main `TtsBar` conditionally renders Delete and Clear buttons independently.
- Full backup, export, and import schema tolerance.

### 3.2 Child-Safe Board Unpin Guard
- Unpinning the communication board now requires a **press-and-hold (700ms)** with haptic feedback vibration.
- Prevents children or non-verbal communicators from accidentally unpinning the board.

### 3.3 Interactive Trilingual Onboarding Tour
- 9-step guided tour explaining navigation, card selection, sentence building, speech synthesis, settings, and card editing.
- Dynamic hole-punch spotlighting (`HighlightPainter`) highlighting active controls.
- Automatic drawer close on Step 4 next-advance and back-navigation.
- Step 9 celebration dialog with permanent *"Interactive App Guide"* replay in Settings Drawer.

### 3.4 Color Vision Deficiency Support & Card Adaptation
- Color-Blind Safe Mode with Protanopia, Deuteranopia, Tritanopia, and Monochromacy palettes.
- Real-time color deficiency matrix shader adapting card photos and illustrations so picture details remain clear.
- High-contrast border customizer (1–10px thickness, auto-contrast or custom colors).
- Drawer preview chips updated with high-contrast text and icon rendering.

### 3.5 Interactive Add New Category Modal
- Live category badge preview.
- Quick preset chips (`Food`, `School`, `Feelings`).
- Custom icon picker (10 AAC symbols) and 8 high-contrast color swatches.
- Card assignment checklist with search filtering, Select All, and Clear Selection.

### 3.6 Direct Android Runtime Permissions
- First-time Camera / Microphone activation triggers the standard Android runtime permission popup directly rather than forcing the user into system settings.

### 3.7 Tactile Haptics
- Strong heavy-impact tactile feedback and custom vibration pulse on card taps.

### 3.8 Toolchain & Build Optimization
- Upgraded to Android Gradle Plugin 9.0.1 and Gradle 9.1.0.
- Optimized R8 ProGuard keep rules preserving offline ML Kit vision reflection models.
- Font tree-shaking active (98.5% reduction in Material Icons size).

---

## 4. Verification & QA Quality Gates

| Gate | Requirement | Actual Result | Status |
| :--- | :--- | :--- | :--- |
| **Dart Analyzer** | Zero warnings, zero errors | `flutter analyze --no-pub` → 0 issues | **PASS** |
| **Automated Tests** | 100% test pass rate | `flutter test` → 198 / 198 tests passed | **PASS** |
| **Data Integrity Stress** | 1,000 cards + 1,000 GIFs/audio SHA-256 match | Stage 2 certified in 39s | **PASS** |
| **Physical Hardware** | Live execution on target device | Samsung Galaxy A34 5G (`SM_A346E`, Android 14) | **PASS** |
| **Live Device ADB Install** | Clean update over wireless ADB | `Performing Streamed Install` → `Success` | **PASS** |
| **Production AAB** | Signed Google Play App Bundle | `app-release.aab` (82.2 MB, versionCode 9) | **PASS** |

---

## 5. Google Play Console Deployment Instructions

1. Log in to [Google Play Console](https://play.google.com/console).
2. Select **Simple AAC (Sri Lanka)** (`lk.yasas.simpleaac`).
3. Navigate to **Release > Production** (or **Open Testing** / **Internal Testing** as desired).
4. Click **Create new release**.
5. Upload the App Bundle:
   - File: [`simple_aac_play_release/build/app/outputs/bundle/release/app-release.aab`](file:///media/yasas/New%20Volume2/yasas/PersonalProjects/simple%20aac/simple_aac_play_release/build/app/outputs/bundle/release/app-release.aab)
6. Enter Release Name: `1.1.1 (9)`.
7. Paste the localized Release Notes (provided in Section 6 below).
8. Click **Save** and **Review release**.
9. Complete rollout.

---

## 6. Official Play Store What's New / Release Notes

### English (en-US / en-GB):
```text
What's New in Simple AAC v1.1.1:
• TTS Bar Settings: Independently customize Delete and Clear action buttons with live composer preview.
• Child-Safe Board Lock: Require press-and-hold with haptic feedback to unpin the communication board.
• Interactive Quick Tour: 9-step guided walkthrough to easily learn and master all app features.
• Color Vision Support: Color-blind safe palettes and real-time photo adaptation for enhanced visual accessibility.
• Add Category Enhancement: New interactive dialog with quick presets, icons, and card assignment.
• Improved Camera & Microphone access with seamless permission prompts.
• Performance optimizations and Android 15 compatibility.
```

### Sinhala (si-LK):
```text
Simple AAC v1.1.1 හි අලුත් දේ:
• TTS Bar සැකසුම්: Delete සහ Clear බොත්තම් ඔබගේ කැමැත්ත පරිදි වෙන වෙනම සකසා ගත හැක.
• ළමා ආරක්ෂිත Unpin ආරක්ෂාව: බෝඩ් එක අත්වැරදීමකින් unpin වීම වැළැක්වීමට තත්පරයක් ඔබාගෙන සිටීම (Press & Hold) අනිවාර්ය කර ඇත.
• අන්තර්ක්‍රියාකාරී මඟපෙන්වීම: ඇප් එකේ සියලු පහසුකම් පියවරෙන් පියවර කියාදෙන Interactive Quick Tour එකක් එක් කර ඇත.
• වර්ණාන්ධතා සහාය (Color Vision): විශේෂ වර්ණ රටා සහ පින්තූර පැහැදිලිව පෙනෙන Adaptive Visual Mode පහසුකම.
• නව කාණ්ඩ (Category) එක්කිරීම: පහසුවෙන් කාණ්ඩ සැකසීමට නව අතුරුමුහුණතක් සහ අයිකන.
• කැමරා සහ ශබ්ද පටිගත කිරීමේ පහසුකම් වඩාත් සුමට කර ඇත.
```

### Tamil (ta-LK):
```text
Simple AAC v1.1.1 இல் புதியவை:
• TTS பார் அமைப்புகள்: Delete மற்றும் Clear பொத்தான்களை தனித்தனியாக மாற்றியமைக்கும் வசதி.
• குழந்தைகளுக்கான பாதுகாப்பு பூட்டு: பலகையை தவறுதலாக விடுவிப்பதைத் தடுக்க நீண்ட நேரம் அழுத்திப் பிடிக்கும் (Press & Hold) முறை.
• ஊடாடும் வழிகாட்டி: பயன்பாட்டின் அனைத்து அம்சங்களையும் எளிதாகக் கற்றுக்கொள்ள 9-படி வழிகாட்டி.
• வண்ண பார்வை ஆதரவு: பார்வைக் குறைபாடுள்ளவர்களுக்கு ஏற்ற வண்ணங்கள் மற்றும் புகைப்பட முறை.
• புதிய வகை சேர்த்தல்: சுலபமாக வகைகளை உருவாக்க புதிய இடைமுகம் மற்றும் சின்னங்கள்.
• கேமரா மற்றும் ஆடியோ அணுகல் மேலும் எளிதாக்கப்பட்டுள்ளது.
```

---

## 7. Sign-Off Authorization

- **Release Engineer:** Senior Release & QA Engineer (Antigravity AI)
- **Status:** **APPROVED FOR IMMEDIATE GOOGLE PLAY RELEASE**
- **Date:** November 16, 2026
