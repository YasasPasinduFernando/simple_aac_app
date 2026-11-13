---
name: flutter-ui-ux
description: Standards, patterns, and checklists for building and refining polished, responsive, and maintainable Flutter interfaces in Simple AAC without unnecessary complexity.
---

# Flutter UI/UX Engineering Skill

This skill guides engineers and agents in designing, implementing, and reviewing user interfaces within the Simple AAC application. Simple AAC is an Augmentative and Alternative Communication (AAC) app where clarity, direct manipulation, tactile feedback, and visual stability directly affect the user's voice and independence.

---

## 1. Core Design Philosophy

1. **Clarity Over Novelty:** Every UI element must communicate its purpose instantly. No decorative animations that delay interaction.
2. **Minimal Working Diff:** Do not introduce widget wrappers or speculative abstractions. Prefer Flutter's standard layout widgets (`Column`, `Row`, `Wrap`, `LayoutBuilder`, `SingleChildScrollView`).
3. **Inspect Before Changing:** Always review the existing widget tree, active theme keys (`ThemeAccessibility`), and styling helpers before introducing new styling.
4. **Resilience to Constraint Extremes:** The interface must render cleanly on narrow screens (320 logical pixels wide), standard smartphones (Samsung Galaxy A34 — 384 logical pixels), and tablets (600+ logical pixels) across font scale factors up to 2.0x.

---

## 2. Layout & Responsive Structure

### 2.1 The 8dp Spacing System
All margins, padding, and gaps must follow the standard 8dp grid:
* **Micro (4dp):** Inner badge padding, small chip margins.
* **Standard (8dp / 12dp):** Card internal padding, gap between icon and title.
* **Section (16dp / 20dp):** Screen horizontal padding, drawer body margins, dialog insets.
* **Structural (24dp / 32dp):** Drawer section separation, dialog header spacing.

### 2.2 Screen Adapters & Constraint Safety
* Never hardcode fixed heights for widgets containing user-translated or multi-line text (e.g., Sinhala, Tamil, English). Use `Flexible`, `Expanded`, or allow auto-sizing with `minLines` / `maxLines`.
* When building responsive sheets, drawers, or dialogs, use `LayoutBuilder` or `MediaQuery.of(context)`:
  ```dart
  final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
  final screenWidth = MediaQuery.of(context).size.width;
  final isCompact = screenWidth <= 340;
  ```
* Always wrap vertical dialog content in `SingleChildScrollView` with an intrinsic-safe parent layout to prevent `RenderFlex overflowed` when on-screen keyboards appear.

---

## 3. Component Architecture & Patterns

### 3.1 App Bars & Headers
* **Home App Bar (`HomeAppBar`):**
  * Structure: `[ PIN (48×48) ] | [ App Title ] [ Hamburger Menu (48×48) ]`.
  * Title: Clean, bold typography ("Simple AAC").
  * Background: Uses active `themePrimaryColor`.
  * **Rule:** Do not add a distracting circular logo into the home app bar. The official branding lives in launcher icons, the About dialog, and the drawer header.

### 3.2 AAC Communication Cards (`_buildCardWidget`)
* **Aspect & Surface:** Rounded rectangular cards (`BorderRadius.circular(16)` on mobile, `20` on tablet).
* **Overlay Mode (`useImageOverlayLabel = true`):** Image occupies the full card surface with text anchored at the bottom with a 50% dark translucent scrim and text shadow for legibility.
* **Stacked Mode (`useImageOverlayLabel = false`):** Image occupies top flex (flex 3), text occupies bottom container (flex 1).
* **Tactile Pop Animation:**
  * Uses `AnimatedScale` targeting `1.08` with `Curves.easeOutBack` (110ms pop, 160ms settle).
  * 3D aura box shadow: `blurRadius: 18`, `spreadRadius: 2`, `offset: (0, 8)` matching `card.colorValue`.
  * Haptic pulse: `HapticFeedback.mediumImpact()` invoked if `_enableHaptics == true`.

### 3.3 Dialogs & Modals
* **Header Standard:** Always use `StyledDialogHeader`:
  ```dart
  StyledDialogHeader(
    icon: Icons.palette_rounded,
    title: 'Text color',
    subtitle: 'Pick a color for Normal Mode',
  )
  ```
* **Corner Radius:** `RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))` or `28` (Material 3 dialog standard).
* **Option Tiles:** Use `DialogOptionTile` with left rounded icon badge, title, subtitle, and full-width tap target.

### 3.4 Color Pickers (`ProfessionalColorPickerDialog`)
* Reusable, compact picker dialog with three clear vertical sections:
  1. **Live Contextual Preview:**
     * Background / Body color: Displays miniature AAC board canvas behind 3 mock cards.
     * Text color: Displays 3 mock cards with variable text colors against stable backgrounds.
     * App / Header color: Displays miniature `HomeAppBar` preview.
  2. **Quick Color Swatches:** 8 primary AAC swatches (White, Blue, Green, Yellow, Orange, Red, Purple, etc.) with checkmark on active color.
  3. **Custom HSV Palette & Hex:** Fine-tuned saturation/value 2D box, horizontal rainbow hue slider, live color preview tile, and formatted `#RRGGBB` hex display.

### 3.5 Settings Drawer (`HomeDrawer`)
* **Header:** Hero container with app icon, "Simple AAC", "Sri Lanka" subtitle, and `v1.1.0` version pill.
* **Grouping:** Clean cards grouped under uppercase section tags:
  * `CONNECTIVITY & PRIVACY`
  * `COMMUNICATION & SPEECH`
  * `LAYOUT & DISPLAY`
  * `APPEARANCE & THEME`
  * `CARDS & STORAGE`
* **Descriptive Preview Tiles:** Settings rows for colors must feature live interactive previews (e.g. mini header preview for Primary App Color, "Aa Sample Text" preview for Text Color, mini board preview for Background Color) rather than plain circular dots.

---

## 4. Theme & Accessibility Integration

* **Dark Mode:** Driven by `ThemeAccessibility.darkModeNotifier`. Cards, drawers, and dialogs must read `_isDarkMode` and supply dark-compatible contrast values (`0xFF121212`, `0xFF1E1E1E`, `0xFF2C2C2C`).
* **Color-Blind Mode:** High-contrast borders (`Border.all(color: Colors.black87, width: 2)` in light mode, `Colors.white54` in dark mode) to delineate cards regardless of hue perception.
* **Switch Themes:** Ensure switch thumbs have stark contrast against active tracks (`thumbColor: onPrimary` over `trackColor: primary`).

---

## 5. UI/UX Verification Checklist

Before finishing any UI change:
- [ ] No `RenderFlex overflowed` errors across 320px, 384px, and 600px widths.
- [ ] Tap targets meet or exceed 48×48 logical pixels.
- [ ] Text contrast meets WCAG AA (minimum 4.5:1 for normal text, 3:1 for large text).
- [ ] Multilingual labels (Sinhala, Tamil, English) render without truncation or clipping.
- [ ] Component respects both Light and Dark modes.
- [ ] Dialogs dismiss cleanly on Android back press or Cancel action.
- [ ] No unnecessary rebuilds: state updates are localized and performant.
