# Functional Regression Audit Report
**Project:** Simple AAC Sri Lanka  
**Package:** `lk.yasas.simpleaac` / `lk.yasas.simpleaac.dev`  
**Date:** November 20, 2026  
**Status:** Certified / 0 Regressions in Core Features  

---

## 1. Feature Verification Matrix

| Module | Feature | Expected Behavior | Verification Status |
| :--- | :--- | :--- | :---: |
| **Home Board** | Root Cards | 4 child characters (Hello, Happy, Sad, Angry) + More + Default | **PASS** |
| **Home Board** | Artwork Coverage | Full card filling without unintended inner boxes or borders | **PASS** |
| **Home Board** | More Category Card | Distinct stickman illustration (`assets/images/seed_v2/more.webp`) | **PASS** |
| **Home Board** | Default Category Card | Harmonized cover illustration (`assets/home/default_folder_cover.webp`) | **PASS** |
| **Navigation** | Category Drilldown | Breadcrumbs update correctly; folder back cards navigate up | **PASS** |
| **Navigation** | Sub-card Visibility | Pinned sub-cards and nested folders render without loops | **PASS** |
| **Sentence Bar** | Chip Insertion | Tapping a card appends word chip with label and image | **PASS** |
| **Sentence Bar** | Delete & Clear | Independent toggles in Settings; backspace and clear work | **PASS** |
| **Speech (TTS)**| Trilingual Speech | Auto-detects Sinhala, Tamil, English; synthesizes sentence | **PASS** |
| **Speech (TTS)**| Offline Speech | Operates with zero network dependency using Android TTS | **PASS** |
| **Pin Mode** | Press-and-Hold Unpin | Long press with haptic required; single tap warns user | **PASS** |
| **Pin Mode** | Child Lock Bounds | Android back, header back, drawer, and edit mode locked | **PASS** |
| **Caregiver Lock**| Settings Protection | PIN / biometric prompt protects settings and reset flows | **PASS** |
| **Personalize**| Global Text Color | Live mini app header preview with Pin, Title, Menu icons | **PASS** |
| **Personalize**| Card Text Color | Independent control for card labels with mini card preview | **PASS** |
| **Personalize**| Color Blind Modes | Protanopia, Deuteranopia, Tritanopia, Monochromacy filters | **PASS** |
| **Personalize**| Dark Theme | Complete dark mode styling across drawer, dialogs, cards | **PASS** |
| **Edit Mode** | Drag-and-Drop | Transactional session (Cancel/Done/Undo) with haptic feedback | **PASS** |
| **Data Storage**| Backup & Restore | Scoped storage ZIP export via MediaStore; lossless restore | **PASS** |
| **Data Storage**| Default Resync | Safely restores built-in starter pack without losing custom cards | **PASS** |

---

## 2. Multilingual Speech Routing Detail

```
[Input Sentence Text] ──> [SpeechEngine.speakTrilingualSentence()]
                                   │
                                   ▼
                       [Unicode Script Segmenter]
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         ▼                         ▼                         ▼
   Sinhala Range             Tamil Range               Latin Range
 [\u0D80 - \u0DFF]         [\u0B80 - \u0BFF]         [Basic Latin / ASCII]
         │                         │                         │
         ▼                         ▼                         ▼
   Locale: "si-LK"           Locale: "ta-LK" / "ta-IN"  Locale: "en-US" / "en-GB"
         │                         │                         │
         └─────────────────────────┼─────────────────────────┘
                                   ▼
                      [flutter_tts MethodChannel]
                                   │
                                   ▼
                   [Android System Text-to-Speech]
```
- **Trilingual Sentence Composition:** Validated on mixed phrases (e.g., Sinhala greeting + English word). Segmenter splits chunks cleanly without cutting off syllables.
- **Audio Focus:** Handles standard Android audio focus requests, ducking background sounds gracefully.

---

## 3. Data Migration & Persistence

- **Legacy Seed Migration (`CardStorageService`):**
  - Existing users with legacy PNG paths (`assets/images/seed/hello.png`) are automatically normalized to modern high-efficiency WebP files (`assets/home/hello.webp`).
  - Custom user cards with user-captured camera images or gallery photos retain their local filesystem URIs without alteration.
  - Card deletion safety: Deleted cards are transferred to the in-memory/on-disk Recycle Bin for safe recovery.

---

## 4. Regression Audit Verdict: PASS
*Zero regressions identified across core AAC communication, settings, speech synthesis, and security.*
