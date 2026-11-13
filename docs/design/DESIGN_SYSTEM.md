# Simple AAC — Design System & Architectural Knowledge Base

This document provides a comprehensive, code-backed reference for the user interface, design system, and key technical subsystems of **Simple AAC (Sri Lanka)**.

---

## 1. UI & Visual Design System

### 1.1 Color Architecture
Colors are dynamically resolved to support both **Light Mode** and **Dark Mode**, as well as specialized **Color-Blind Safe Mode**.

| Color Role | Default Hex | Dark Mode Equivalent | Semantic Meaning |
| :--- | :--- | :--- | :--- |
| **Primary App Color** | `#0277BD` (Light Blue 800) | Preserved or `#0277BD` | Brand identity, App Bar, drawer hero, primary buttons |
| **Canvas Background** | `#FFFFFF` | `#121212` | Communication board background |
| **Card Surface** | Dynamic per card or `#FFFFFF` | `#1E1E1E` (Custom tint preserved) | Communication card background |
| **Global Text** | `#FFFFFF` (on primary) / `#212121` | `#FFFFFF` / `#E0E0E0` | App-wide body and button typography |
| **Success / Online** | `#2E7D32` (Green 800) | `#4CAF50` (Green 500) | Online features enabled, verified checks |
| **Warning / Alert** | `#ED6C02` (Orange) | `#FF9800` (Orange 500) | Attention required, unsaved state |
| **Destructive / Error**| `#D32F2F` (Red 700) | `#EF5350` (Red 400) | Delete actions, permission denials |

### 1.2 Modified Fitzgerald Key for AAC Cards
Communication cards use an intuitive color-coding system based on the Fitzgerald Key standard widely adopted in AAC speech therapy:
* **Yellow (`0xFFFFF59D` / `0xFFFFE082`):** People, pronouns, greetings (e.g., "Hello").
* **Blue (`0xFF90CAF9` / `0xFF64B5F6`):** Feelings, emotional states, adjectives (e.g., "Happy", "Sad").
* **Red (`0xFFEF9A9A` / `0xFFE57373`):** Urgency, negatives, boundaries (e.g., "Angry", "No", "Stop").
* **Green (`0xFFA5D6A7` / `0xFF81C784`):** Actions, verbs, folder categories (e.g., "Actions", "Eat", "Play").
* **Orange (`0xFFFFCC80` / `0xFFFFB74D`):** Nouns, foods, objects (e.g., "Water", "Chair").
* **Purple (`0xFFCE93D8` / `0xFFBA68C8`):** Social phrases, questions, polite words.

### 1.3 Typography
* **Font Family:** `GoogleFonts.roboto()` with native system fallback.
* **Header Title:** 24–26 logical pixels, bold (`FontWeight.w700`).
* **Card Label:** 16 logical pixels (mobile) / 20 logical pixels (tablet), bold (`FontWeight.bold`), max 2 lines.
* **Drawer Row Title:** 15–16 logical pixels, medium (`FontWeight.w600`).
* **Drawer Row Subtitle:** 12–13 logical pixels, regular (`FontWeight.w400`), muted.
* **Indic Scripts (Sinhala & Tamil):** Displayed with adequate line-height (`1.2`–`1.3`) so ascenders and descenders (kombuva, aelapilla, pulli) are never clipped.

### 1.4 Spacing & Corner Radii
* **Standard Grid Spacing:** 8dp increments (4dp, 8dp, 12dp, 16dp, 20dp, 24dp, 32dp).
* **Card Corner Radius:** 16dp on mobile, 20dp on tablet.
* **Dialog Corner Radius:** 24dp or 28dp (Material 3 standard).
* **Button Corner Radius:** 12dp or 14dp.
* **Icon Badges in Lists:** 10dp or 12dp rounded square containers with 12% opacity brand tint.

---

## 2. Approved UI Component Specifications

### 2.1 Home App Bar (`lib/widgets/home_app_bar.dart`)
* **Layout:** `[ PIN (48×48) ] | Simple AAC [ MENU (48×48) ]`
* **Left PIN Button:**
  * Rounded rectangle (`BorderRadius.circular(12)`).
  * Subtle translucent white border (`Border.all(color: Colors.white30, width: 1.2)`).
  * Icon: `Icons.push_pin_rounded` (unpinned) or `Icons.push_pin` (pinned).
  * Minimum accessible tap target: 48×48 logical pixels.
* **Vertical Divider:** Thin translucent separator (`width: 1`, `height: 24`, `color: Colors.white24`).
* **Title:** Clean, bold white typography ("Simple AAC").
* **Right Hamburger Menu:** Matches PIN button geometry, opens `HomeDrawer`.
* **Invariant:** No distracting app logo in the header.

### 2.2 Reusable Color Picker Dialog (`lib/widgets/professional_color_picker_dialog.dart`)
A 3-tier compact dialog replacing bloated full-screen pickers:
1. **Live Contextual Preview:**
   * **`PickerPreviewType.app`:** Shows a miniature `HomeAppBar` that updates its background in real time.
   * **`PickerPreviewType.text`:** Shows 3 mock cards ("Hello", "Hello", "Hello") with live label color changes against yellow backgrounds.
   * **`PickerPreviewType.background`:** Shows a mini board canvas behind 3 cards ("Hello", "Sad", "Angry") reflecting the selected body color.
2. **Quick Colors:** 8 accessible swatches with checkmark on active color.
3. **Custom HSV & Hex:** 2D saturation/value box, horizontal hue slider, live swatch chip, and editable `#RRGGBB` hex code field.

### 2.3 Settings Drawer (`lib/widgets/home_drawer.dart`)
* **Hero Header:** Displays the official Simple AAC speech bubble icon, "Simple AAC", "Sri Lanka", and `v1.1.0` version pill.
* **Sectioned Cards:** Encapsulated in rounded white/dark cards with uppercase section headers:
  * `CONNECTIVITY & PRIVACY` — Online features switch with child-safe privacy guarantee.
  * `COMMUNICATION & SPEECH` — Edit mode, Tap to Speak, Voice profile, Hide TTS bar, Text on card image, Custom card text color, Haptic Feedback.
  * `LAYOUT & DISPLAY` — Language, Grid columns, Visible cards count, Screen orientation, Full screen mode, TTS bar sizing.
  * `APPEARANCE & THEME` — Dark mode switch, Primary App Color (mini header chip), Global Text Color (Aa text chip), Board Background Color (mini board chip), Color Vision Support.
  * `CARDS & STORAGE` — Category filtering, Backup board, Restore board, Reset settings to defaults, About app.

### 2.4 Card Interaction & Tactile Feedback (`lib/pages/home_page.dart`)
* **Scale Pop:** `AnimatedScale` scales from `1.0` to `1.08` with `Curves.easeOutBack` (110ms pop, 160ms settle).
* **Lighting Aura:** `BoxShadow` elevates to `blurRadius: 18`, `spreadRadius: 2`, `offset: (0, 8)` with matching card color.
* **Haptic Vibration:** `HapticFeedback.mediumImpact()` invoked on tap (defaults to ON, toggleable in Settings).
* **Folder Cards:** Display a folder badge and trigger the same tactile pop and haptics before opening the sub-card grid.

---

## 3. Subsystem Architecture Reference

### 3.1 Multilingual Google TTS (`lib/services/speech_engine.dart`)
* **Engines:** Powered by Android's native Google Text-to-Speech via `flutter_tts`.
* **Zero Neural Bloat:** Rejects heavy neural runtimes (ONNX, Sherpa, eSpeak) in favor of the lightweight native platform engine (keeps app download < 26 MB).
* **Language Routing (`MultilingualSpeechRouter`):** Analyzes raw text Unicode scripts:
  * Sinhala Unicode range `[\u0D80-\u0DFF]` -> routes to `si-LK`.
  * Tamil Unicode range `[\u0B80-\u0BFF]` -> routes to `ta-IN` / `ta-LK`.
  * Latin range `[a-zA-Z]` -> routes to `en-US` / `en-GB`.
* **Mixed-Script Code-Switching:** Splits sentences like `"මට water එකක් දෙන්න"` into sequential language segments and plays them seamlessly.

### 3.2 Atomic Card Storage (`lib/services/card_storage_service.dart`)
* **Primary Store:** `aac_cards_v1.json` stored in the application documents directory.
* **Atomic Writes:** Writes to `.tmp` file and performs atomic rename to prevent corruption on unexpected power loss.
* **Automatic Backup:** Maintains `aac_cards_v1.json.bak` and migrates legacy SharedPreferences stores automatically.
* **Media Migration:** Automatically migrates camera and gallery media into local app sandbox (`aac_media/images/` and `aac_media/voices/`).

### 3.3 Hardened Backup & Restore (`lib/services/backup_service.dart`)
* **Archive Format:** Standard `.zip` archive containing `manifest.json` and bundled media files (`files/`).
* **Path Traversal Protection:** Validates every zip entry name against Zip Slip directory traversal attacks (rejects `../`, absolute paths, and system root targets).
* **Integrity Checking:** Verifies SHA-256 hashes of restored files.

### 3.4 Media Engine & Animated GIFs (`lib/utils/animated_media_helper.dart` & `card_image.dart`)
* **Memory Bounded Decoding:** `buildCardImage` wraps images in `ResizeImage(..., width: cacheWidth)` to prevent OOM errors when decoding multi-megapixel photos.
* **Animated GIFs:** Detects GIF headers (`GIF87a` / `GIF89a`) and renders animated thumbnails with gapless playback.
* **Video Playback:** Validates MP4/video files up to 30 seconds with bounded previews.

### 3.5 Camera, Gallery & Offline ML Kit (`lib/utils/camera_object_helper.dart` & `app_permissions_helper.dart`)
* **Android Photo Picker:** Complies with Android 13+ Photo Picker standard without requesting legacy broad storage permissions.
* **Package Query Intent Resolution:** Declares explicit `<queries>` intents in `AndroidManifest.xml` (`ACTION_IMAGE_CAPTURE`, `ACTION_VIDEO_CAPTURE`) to ensure reliable camera dispatch on Android 11+.
* **Offline ML Kit:** Uses bundled Google ML Kit vision models (`libmlkitcommonpipeline.so`) for 100% offline card labeling when taking photos.
