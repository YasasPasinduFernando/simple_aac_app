# Simple AAC Sri Lanka (v1.1.0) — User Guide Typography & Layout QA Report

**Audit Date:** November 13, 2026  
**Target Release:** November 14, 2026 Play Store Release  
**Branch:** `release/play-2026-11-14`  
**Documents Audited:**
1. `Simple_AAC_User_Guide_EN.pdf` (English)
2. `Simple_AAC_User_Guide_SI.pdf` (Sinhala — සිංහල)

---

## 1. Executive Summary & Pagination Optimization

The initial unformatted documentation spanned **27 pages** due to unbound portrait screenshots (each up to 820px tall), detached figure captions, broken inline tags (`inline-block` breaking continuous sentences), and unconstrained page flow.

Through semantic `<figure>` architecture, responsive flexbox rows (`.fig-row` and `.fig-row-3`), clean typographic hierarchy, and explicit page-break management, both English and Sinhala user guides have been optimized into a clean, compact, professional **7-page reference manual** without removing a single sentence, feature explanation, or screenshot.

### Summary Metrics

| Metric | Initial Raw Export | Optimized English Guide | Optimized Sinhala Guide | Status |
| :--- | :---: | :---: | :---: | :---: |
| **Page Count** | 27 Pages | **7 Pages** | **7 Pages** | **PASS** (74% space reduction) |
| **Isolated Screenshots** | 11 occurrences | **0** | **0** | **PASS** (all bound to captions) |
| **Broken Inline Words** | Multiple (`jumping`, `Feelings`) | **0** (continuous flow) | **0** (continuous flow) | **PASS** (verified via `pdftotext`) |
| **Chapters Preserved** | 8 Chapters | **8 Chapters (100%)** | **8 Chapters (100%)** | **PASS** (complete parity) |
| **Authentic Screenshots** | 22 PNGs + 2 GIFs | **22 PNGs + 2 GIFs** | **22 PNGs + 2 GIFs** | **PASS** (100% real ADB assets) |
| **Running Headers/Footers**| Browser URL/timestamp | Vector page numbers | Vector page numbers | **PASS** (`--no-pdf-header-footer`) |

---

## 2. Typographic Hierarchy & Specifications

### 2.1 English Typography Specifications

- **Font Family:** `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`
- **Document Title (H1):** `21 pt`, Bold, `#01579b` (Primary Navy Blue), line-height `1.15`, letter-spacing `-0.3px`
- **Subtitle:** `9.5 pt`, Medium, `#475569`, bottom margin `10px`
- **Chapter Headings (H2):** `14.5 pt`, Bold, `#0277bd` (Vibrant Blue), line-height `1.2`, space above `14 pt`, space below `4 pt`, border-bottom `1.2px solid #e2e8f0`
- **Section Headings (H3):** `11.0 pt`, Semibold, `#0369a1` (Ocean Blue), line-height `1.2`, space above `9 pt`, space below `3 pt`
- **Body Text:** `9.5 pt`, Regular, `#334155` (Slate), line-height `1.38`, left-aligned (`text-align: left`), orphans `3`, widows `3`
- **Figure Captions:** `8.0 pt`, Italic, `#64748b` (Muted Slate), line-height `1.2`, margin-top `4px`
- **Code & Inline Pills:** `8.5 pt`, `ui-monospace, Menlo, Monaco, monospace`, background `#f1f5f9`, border `#e2e8f0`, `display: inline` (prevents text-layer splitting)
- **Callout Boxes:** Background `#f0f9ff`, border-left `3px solid #0284c7`, font-size `8.5 pt`, color `#0369a1`

### 2.2 Sinhala Typography Specifications

- **Font Family:** `'Noto Sans Sinhala', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif` (native Linux HarfBuzz complex text shaping verified)
- **Document Title (H1):** `20 pt`, Bold, `#01579b`, line-height `1.25`
- **Subtitle:** `9.5 pt`, Medium, `#475569`, bottom margin `10px`
- **Chapter Headings (H2):** `13.5 pt`, Bold, `#0277bd`, line-height `1.25`, space above `13 pt`, space below `4 pt`, border-bottom `1.2px solid #e2e8f0`
- **Section Headings (H3):** `10.5 pt`, Semibold, `#0369a1`, line-height `1.25`, space above `8 pt`, space below `3 pt`
- **Body Text:** `9.3 pt`, Regular, `#334155`, line-height `1.50` (optimized for Sinhala diacritics / kombu / ispilla), left-aligned
- **Figure Captions:** `8.0 pt`, Regular, `#64748b`, line-height `1.25`, margin-top `4px`
- **Callout Boxes:** Background `#f0f9ff`, border-left `3px solid #0284c7`, font-size `8.5 pt`, color `#0369a1`

---

## 3. Structural & Heading Parity

Both documents adhere to an identical heading structure and sequence:

| Section | English User Guide (`Simple_AAC_User_Guide_EN`) | Sinhala User Guide (`Simple_AAC_User_Guide_SI`) | Page |
| :---: | :--- | :--- | :---: |
| **Doc Title** | Simple AAC Sri Lanka — Complete User Guide (v1.1.0) | Simple AAC ශ්‍රී ලංකා — සම්පූර්ණ පරිශීලක මාර්ගෝපදේශය (v1.1.0) | 1 |
| **TOC** | Table of Contents | පටුන (Table of Contents) | 1 |
| **Ch. 1** | Chapter 1 — Getting Started with Simple AAC | 1 වන පරිච්ඡේදය — Simple AAC භාවිතය ආරම්භ කිරීම | 1 |
| 1.1 | 1.1 Main Interface Overview | 1.1 ප්‍රධාන තිරය හඳුනා ගැනීම | 1 |
| **Ch. 2** | Chapter 2 — Speaking and Sentence Composition | 2 වන පරිච්ඡේදය — කථනය සහ වාක්‍ය සකස් කිරීම | 2 |
| 2.1 | 2.1 Tapping to Speak | 2.1 කාඩ්පතක් ස්පර්ශ කර කථා කිරීම (Tap to Speak) | 2 |
| 2.2 | 2.2 Constructing Multi-Word Sentences | 2.2 සම්පූර්ණ වාක්‍ය ගොඩනැගීම (Sentence Composer) | 2 |
| **Ch. 3** | Chapter 3 — Customizing Cards and Multilingual Content | 3 වන පරිච්ඡේදය — කාඩ්පත් සැකසීම සහ භාෂා ත්‍රිත්වය | 3 |
| 3.1 | 3.1 Enabling Edit Mode & Card Editor | 3.1 Edit Mode සහ Card Editor වෙත පිවිසීම | 3 |
| 3.2 | 3.2 Adding Authentic Photos & Smart Search | 3.2 කැමරාවෙන් සහ Gallery මගින් සැබෑ ඡායාරූප එක් කිරීම | 3 |
| 3.3 | 3.3 Trilingual Support & Custom Voice Recording | 3.3 භාෂා ත්‍රිත්වය (සිංහල, දෙමළ, ඉංග්‍රීසි) සහ සැබෑ හඬ පටිගත කිරීම | 4 |
| **Ch. 4** | Chapter 4 — Animated GIFs and Video Loops | 4 වන පරිච්ඡේදය — චලන රූප (GIF) සහ වීඩියෝ ලූප | 4 |
| **Ch. 5** | Chapter 5 — Folders and Category Organization | 5 වන පරිච්ඡේදය — කාණ්ඩ (Categories) සහ ෆෝල්ඩර මගින් සංවිධානය කිරීම | 5 |
| **Ch. 6** | Chapter 6 — Appearance, Themes and Haptic Feedback | 6 වන පරිච්ඡේදය — පෙනුම, වර්ණ තේමා සහ ස්පර්ශක ප්‍රතිචාරය (Haptics) | 5 |
| 6.1 | 6.1 Settings Drawer & Live Color Customization | 6.1 Settings Drawer සහ Live Color Preview | 5 |
| 6.2 | 6.2 Redesigned Color Pickers | 6.2 අලුත්ම Color Pickers මගින් වර්ණ තේරීම | 6 |
| 6.3 | 6.3 Color Vision Support & Haptic Feedback | 6.3 වර්ණ අන්ධභාවය සඳහා සහාය (Color-Blind Mode) සහ Haptic Feedback | 6 |
| **Ch. 7** | Chapter 7 — Safety, Board Pinning and Child Lock | 7 වන පරිච්ඡේදය — පුවරුව අගුළු දැමීම සහ ළමා ආරක්ෂාව | 7 |
| 7.1 | 7.1 Enabling Board Pinning with a PIN | 7.1 PIN අංකයක් මගින් Board Pinning සක්‍රිය කිරීම | 7 |
| **Ch. 8** | Chapter 8 — Data Backup, Restore and Offline Privacy | 8 වන පරිච්ඡේදය — දත්ත උපස්ථ කිරීම (Backup), නැවත ලබාගැනීම (Restore) සහ නොබැඳි රහස්‍යතාව | 7 |
| 8.1 | 8.1 Strict Offline Privacy Model | 8.1 100% නොබැඳි රහස්‍යතාව (Strict Offline Privacy) | 7 |
| 8.2 | 8.2 Exporting & Restoring Backups | 8.2 Backups ලබාගැනීම (Export) සහ නැවත පිහිටුවීම (Import Restore) | 7 |

---

## 4. Visual Layout & Pagination Inspection Checklist

Each compiled page was rendered to a 150 DPI raster image and evaluated for vertical bounds, margin adherence, and content flow:

| Page | Content Scope | Figures Included | Content Height (150 DPI) | Bottom Margin | Layout Evaluation |
| :---: | :--- | :--- | :---: | :---: | :---: |
| **1** | Title, TOC, Chapter 1, Section 1.1 | Fig 1.1 (`01_home_screen`), Fig 1.2 (`02_aac_cards_grid`) | 1630 px / 1754 px | 33 px | **Balanced** — Clean introduction & 2-col cards grid |
| **2** | Chapter 2, Section 2.1, Section 2.2 | Fig 2.1 (`card_tap_speak.gif`), Fig 2.2 (`03_speaking_card`), Fig 2.3 (`04_sentence_bar`) | 1633 px / 1754 px | 33 px | **Balanced** — Speech mechanics & sentence bar |
| **3** | Chapter 3, Section 3.1, Section 3.2 | Fig 3.1 (`05_edit_mode_active`), Fig 3.2 (`06_card_editor_dialog`), Fig 3.3 (`08_camera_flow`), Fig 3.4 (`10_smart_image_search`) | 1633 px / 1754 px | 33 px | **Balanced** — Card editor and photo capture |
| **4** | Section 3.3, Chapter 4 | Fig 3.5 (`14_multilingual_labels`), Fig 3.6 (`13_custom_voice_recorder`), Fig 4.1 (`11_animated_gifs`), Fig 4.2 (`12_video_to_gif`) | 1634 px / 1754 px | 33 px | **Balanced** — Trilingual audio, voice recording & GIFs |
| **5** | Chapter 5, Chapter 6, Section 6.1 | Fig 5.1 (`07_folder_view`), Fig 6.1 (`16_settings_drawer`), Fig 6.2 (`color_picker_flow.gif`) | 1633 px / 1754 px | 33 px | **Balanced** — Categories & settings drawer |
| **6** | Section 6.2, Section 6.3 | Fig 6.3 (`17_color_picker_app_color`), Fig 6.4 (`18_color_picker_text_color`), Fig 6.5 (`19_color_picker_board_background`), Fig 6.6 (`20_appearance_and_color_vision`) | 1634 px / 1754 px | 33 px | **Balanced** — 3-column color picker & accessibility |
| **7** | Chapter 7, Section 7.1, Chapter 8, Section 8.1, Section 8.2 | Fig 7.1 (`15_pin_dialog`), Fig 7.2 (`15_pin_mode_locked`), Fig 8.1 (`21_backup_export`), Fig 8.2 (`24_offline_speech_settings`) | 1633 px / 1754 px | 33 px | **Balanced** — PIN security, offline backup & closure |

---

## 5. Deliverables & Forensic Checksum Manifest

All final files reside within the repository worktree at `/media/yasas/New Volume2/yasas/PersonalProjects/simple aac/simple_aac_play_release/docs/user-guide/`:

| Relative File Path | Size | SHA-256 Checksum | Purpose |
| :--- | :---: | :--- | :--- |
| `english/Simple_AAC_User_Guide_EN.md` | 10.8 KB | `3bf645c2dc7446d427383dbaac0dde755bfbe8f4025a533e335be987675a0d4e` | Master English Markdown Source |
| `english/Simple_AAC_User_Guide_EN.html` | 20.7 KB | `c6618b0d677a6fa4d35a90d9b61e98c73cb8b11bd7658e4a6f79a033b0d982e4` | Semantic HTML Print Source (English) |
| `english/Simple_AAC_User_Guide_EN.pdf` | 16.9 MB | `bfbe353e215e2f3a0a7eb30f57bb254a411a7b10a1da60628c69376bc37bd82b` | Production-Grade Vector PDF (7 Pages) |
| `sinhala/Simple_AAC_User_Guide_SI.md` | 20.4 KB | `c25b7b8f06c2de83c17edebd62e9d6ed2532098ce74cc1bb019a7ce907ae5ed3` | Master Sinhala Markdown Source |
| `sinhala/Simple_AAC_User_Guide_SI.html` | 30.0 KB | `e5aef56554468b7d51888e288ae2086eef126cc5cd8f22301bc612b898a7d32a` | Semantic HTML Print Source (Sinhala) |
| `sinhala/Simple_AAC_User_Guide_SI.pdf` | 17.0 MB | `a969ec0991cc03deb1b0a7bce81dd8a8bd2d465fd546c95ef022be2e2e751d9d` | Production-Grade Vector PDF (7 Pages) |
| `Simple_AAC_v1.1.0_User_Guides_EN_SI.zip`| 59.9 MB | `7e91ea7e1c8cffa145cec1db4452475cba37fd08130393b4a3357012bb8e4e24` | Complete Multi-Language User Guide Bundle |

---

*Verified by Antigravity Senior Technical Documentation Designer & QA Engineer.*
