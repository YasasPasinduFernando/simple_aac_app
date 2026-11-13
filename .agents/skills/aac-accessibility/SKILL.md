---
name: aac-accessibility
description: Accessibility and inclusive design standards for Simple AAC, ensuring high usability for non-verbal individuals, motor-impaired users, and caregivers without clinical assumptions.
---

# AAC Accessibility & Inclusive Design Skill

Simple AAC is an Augmentative and Alternative Communication (AAC) tool designed for individuals who have difficulty speaking or communicating verbally, including non-verbal children, adults recovering from neurological events, autistic communicators, and their caregivers, educators, and speech therapists in Sri Lanka and worldwide.

Accessibility is not an optional polish layer in this project; **accessibility is the core functionality**.

---

## 1. Guiding Principles

1. **Zero Clinical Assumptions:** Never assume a specific diagnosis, motor capability, visual acuity, or cognitive profile. Design interfaces with high baseline tolerance for tremors, low dexterity, reduced vision, and sensory overload.
2. **Every Tap Speaks:** Direct interaction is paramount. Tapping a card should immediately deliver auditory, visual, and tactile confirmation.
3. **Respect User-Created Data:** Caregivers spend hours photographing familiar objects, recording family voices, and organizing communication boards. Never delete, discard, or overwrite user cards or voice recordings during migrations, resets, or updates.
4. **Predictable Navigation:** Never surprise the user with modal loops, automatic redirects, or unexpected layout shifts.

---

## 2. Touch & Physical Motor Targets

### 2.1 Minimum 48×48 dp Tap Targets
Every interactive element (buttons, cards, switches, dialog options) must provide a touch target of at least **48×48 logical pixels** (WCAG 2.5.5 and Android Material Design Guidelines).
```dart
// Example: Bounded minimum touch area for custom icon buttons
IconButton(
  iconSize: 24,
  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
  padding: const EdgeInsets.all(12),
  onPressed: onAction,
  icon: const Icon(Icons.close_rounded),
)
```

### 2.2 Generous Card Tap Bounds
* AAC communication cards on the grid must occupy full cell bounds (`Expanded` or `SizedBox.expand`).
* Padding between cards must be sufficient (8dp–12dp) to prevent accidental neighboring card triggers for users with motor tremors.

### 2.3 Tactile Haptic Feedback
* Physical confirmation reinforces successful communication for users with motor control challenges or low vision.
* Every card tap triggers `HapticFeedback.mediumImpact()`.
* Must be user-toggleable via **Settings Drawer -> Communication & Speech -> Haptic Feedback** to accommodate individuals with sensory sensitivities.

---

## 3. Visual & Cognitive Accessibility

### 3.1 High Contrast Typography & Colors
* **Normal Text:** Contrast ratio must be at least **4.5:1** against its background (WCAG AA).
* **Large Text / Card Titles (≥18pt or bold ≥14pt):** Minimum contrast ratio of **3:1**.
* In dark mode, avoid pure `#000000` text on dark grey surfaces; use high-contrast white `#FFFFFF` or off-white `#F5F5F5`.
* For card labels overlaid on images (`useImageOverlayLabel = true`):
  * Use a subtle dark scrim (`Colors.black38` or `Colors.black54`).
  * Add multi-offset drop shadows (`Shadow(blurRadius: 6, color: Colors.black54, offset: Offset(0, 2))`) to maintain legibility over photos with bright backgrounds (e.g., white walls, sunlight).

### 3.2 Color-Blind Support
* Hue alone must **never** be the sole indicator of card category, state, or folder status.
* When Color-Blind mode is active:
  * Add distinct 2dp solid high-contrast borders around cards (`Colors.black87` in light mode, `Colors.white54` in dark mode).
  * Folder cards display a visible folder glyph badge (`Icons.arrow_forward` or folder indicator) in addition to folder grouping colors.
* In the Settings Drawer, color chips include visual textual labels or icons indicating selected states (e.g. checkmarks) rather than relying on color alone.

### 3.3 Clutter Reduction & Calm Aesthetics
* Minimize unnecessary visual embellishments, complex gradients, or distracting animated loops.
* Keep the Home header calm and clear: `[ PIN ] | Simple AAC [ Menu ]`. Do not introduce animated characters or logos that distract from the communication cards.

---

## 4. Multilingual & Screen-Reader Semantics

### 4.1 Script Diversity in Sri Lanka
Simple AAC serves a trilingual user base:
* **English (`en`)**
* **Sinhala (`si`)** — e.g. "හෙලෝ", "සතුටුයි", "කෑම"
* **Tamil (`ta`)** — e.g. "வணக்கம்", "மகிழ்ச்சி", "சாப்பாடு"

**Rules:**
1. Never clip or truncate Sinhala or Tamil glyphs. Indic scripts feature dependent vowel signs (kombuva, aelapilla, ispilla, papilla) that extend above and below standard Latin x-height. Always allow sufficient `lineHeight` (`1.2`–`1.3`) in `TextStyle`.
2. Support mixed-script utterances (code-switching, e.g. "මට water එකක් දෙන්න") via `MultilingualSpeechRouter`.

### 4.2 Semantic Screen Reader Annotations
* Non-text icons must carry meaningful `tooltip` or `Semantics(label: ...)`:
  ```dart
  Semantics(
    button: true,
    label: 'Pin screen to prevent caregiver menu access',
    child: InkWell(...),
  )
  ```
* Communication cards announce card label and card type (e.g. "Hello, communication card" or "Food, folder with 8 items").

---

## 5. Caregiver & Safety Features

1. **Screen Pinning:** Protects the child or user from unintentionally opening settings or deleting cards during active communication sessions.
2. **PIN Protection:** PIN access dialog must be accessible with large keypad numbers, clear error messages, and immediate audible/haptic feedback.
3. **Edit Mode Safeguard:** Edit mode must display a persistent, visible notification bar (`EditModeBar`) with a clear "Done" action so caregivers never leave edit mode active by mistake.
4. **Child-Safe Network Policy:** Offline-first architecture (`NetworkPolicyService`). When online features are disabled, the app makes zero network calls and remains 100% functional.
