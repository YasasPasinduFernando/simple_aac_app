---
name: design-system
description: Project-specific design system specifications, color palettes, typography rules, component patterns, and approved UI decisions for Simple AAC.
---

# Simple AAC Design System Reference

This skill maintains design consistency across Simple AAC. All specifications here reflect real code implementations, approved mockups, and verified release designs on branch `release/play-2026-11-14`.

---

## 1. Approved Architecture & Core Decisions

| UI Area | Approved Standard | Implementation Reference |
| :--- | :--- | :--- |
| **Home Header** | `[ PIN ] \| Simple AAC [ MENU ]` with vertical divider; no logo in header. | `lib/widgets/home_app_bar.dart` |
| **Header Left Button** | Translucent rounded rectangle with subtle white border (48×48dp). | `HomeAppBar` left action |
| **Header Right Button** | Translucent rounded rectangle matching left button (48×48dp). | `HomeAppBar` right action |
| **Color Picker Dialog** | Compact 3-section dialog: Live Contextual Preview, Quick Colors, HSV/Hex. | `lib/widgets/professional_color_picker_dialog.dart` |
| **App Color Preview** | Miniature `HomeAppBar` preview showing header color changes. | `ProfessionalColorPickerDialog` (mode `app`) |
| **Text Color Preview** | Three mock communication cards with live text color changes. | `ProfessionalColorPickerDialog` (mode `text`) |
| **Background Color Preview** | Miniature AAC canvas with 3 cards over live colored body background. | `ProfessionalColorPickerDialog` (mode `background`) |
| **Settings Drawer Tiles** | Rich card-styled rows with descriptive preview widgets instead of plain dots. | `lib/widgets/home_drawer.dart` |
| **Card Pop Animation** | 1.08 punchy scale with `Curves.easeOutBack` + accent aura shadow. | `lib/pages/home_page.dart` (`_buildCardWidget`) |
| **Card Haptics** | `HapticFeedback.mediumImpact()` on card and folder taps (default ON). | `HomePage.hapticPerformer` |

---

## 2. Color Palette & Theming

### 2.1 Brand Identity Colors
* **Primary Blue:** `#0277BD` (Material Light Blue 800) — Primary brand header color.
* **Accent Cyan / Teal:** `#00ACC1` / `#26A69A` — Connectivity, success, and active states.
* **Surface Light:** `#FFFFFF` — Default canvas and card background.
* **Surface Dark:** `#121212` (Scaffold background), `#1E1E1E` (Card surface), `#242424` (Elevated surfaces).

### 2.2 Standard AAC Color Coding (Modified Fitzgerald Key)
* **Yellow (`#FFF59D` / `#FFE082`):** People, pronouns, greetings (e.g. Hello).
* **Blue (`#90CAF9` / `#64B5F6`):** Feelings, adjectives, states (e.g. Happy, Sad).
* **Red (`#EF9A9A` / `#E57373`):** Urgent, stop, anger, negatives (e.g. Angry, No).
* **Green (`#A5D6A7` / `#81C784`):** Actions, verbs, folders (e.g. Actions, Go, Eat).
* **Orange (`#FFCC80` / `#FFB74D`):** Objects, nouns, food.
* **Purple (`#CE93D8` / `#BA68C8`):** Social expressions, questions.

### 2.3 Theme Swatches & Persistence
Theme colors are stored in `SharedPreferences` and managed dynamically:
* `themePrimaryColor` (default `0xFF0277BD`)
* `themeTextColor` (default `0xFFFFFFFF`)
* `themeBackgroundColor` (default `0xFFFFFFFF`)
* Dark mode is bound to `ThemeAccessibility.darkModeNotifier`.

---

## 3. Typography & Text Standards

* **Font Family:** Clean sans-serif via `GoogleFonts.roboto()` or platform default fallbacks.
* **Hierarchy:**
  * **App Bar Title:** 24–26 logical pixels, bold, responsive to screen width (`clamp(18.0, screenWidth * 0.055, 26.0)`).
  * **Card Labels:** 16 logical pixels (mobile) / 20 logical pixels (tablet), bold, max 2 lines, centered, ellipsis overflow.
  * **Drawer Section Headers:** 12–13 logical pixels, bold, uppercase, tracked (`letterSpacing: 0.8`), colored with primary brand hue.
  * **Settings Row Titles:** 15–16 logical pixels, medium (`FontWeight.w600`).
  * **Settings Row Subtitles:** 12–13 logical pixels, regular, secondary muted text (`Colors.grey[600]` or `Colors.white60`).

---

## 4. Radii, Shadows & Elevations

### 4.1 Corner Radii Standards
* **AAC Communication Cards:** `16dp` on phone, `20dp` on tablet.
* **Dialogs (`AlertDialog`):** `24dp` or `28dp` rounded corners.
* **Buttons / Action Chips:** `12dp` or `14dp`.
* **Drawer Row Badges (Icon containers):** `10dp` or `12dp`.
* **Color Preview Tiles in Drawer:** `8dp` or `10dp`.

### 4.2 Shadow Elevation & Glow
* **Card Resting:** `BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: Offset(0, 4))`.
* **Card Popped (Active Tap):** `BoxShadow(color: accentColor.withValues(alpha: 0.45), blurRadius: 18, spreadRadius: 2, offset: Offset(0, 8))`.
* **Dialog Drop Shadow:** Elevation `8` with soft barrier scrim.

---

## 5. Standard Component Guidelines

### 5.1 Reusable Dialog Header
Always use `StyledDialogHeader`:
```dart
StyledDialogHeader(
  icon: Icons.palette_rounded,
  title: 'Header Title',
  subtitle: 'Concise explanation',
  accentColor: optionalAccentColor,
  showCloseButton: true,
)
```

### 5.2 Settings Drawer Rows
In `HomeDrawer`, use the specialized builder methods:
* `_buildSwitchItem`: For boolean toggles (Online features, Edit mode, Haptic feedback, Dark mode).
* `_buildColorRow`: For theme color pickers, displaying custom live preview chip + arrow indicator.
* `_buildNavigationItem`: For navigation items (Language, Grid columns, Visible count, Orientation).

---

## 6. Design Invariants (Do Not Change Without Explicit Approval)

1. **Do not put a logo in the Home App Bar.** The reference design explicitly requires `[ PIN ] | Simple AAC [ Menu ]`.
2. **Do not use full-screen color pickers.** The 3-tier compact dialog (`ProfessionalColorPickerDialog`) is the approved, verified design.
3. **Do not replace live preview tiles in the drawer with plain colored dots.** The rich visual preview chips are approved and verified.
4. **Do not remove or alter the PIN button on the home header.**
