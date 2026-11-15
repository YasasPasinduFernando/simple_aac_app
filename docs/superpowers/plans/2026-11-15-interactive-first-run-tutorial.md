# Simple AAC Sri Lanka — Interactive First-Run Tutorial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a complete, live, animated, interactive in-app tutorial for Simple AAC Sri Lanka (`lk.yasas.simpleaac`) where users learn by tapping the REAL buttons inside the app, with first-launch welcome sheet, coachmark spotlight overlays, pulsing rings, animated hand cues, trilingual instructions (EN/SI/TA), replay from Settings, and mini-guides.

**Architecture:** A lightweight, pure Flutter overlay system (`TutorialService` + `TutorialOverlay` + `TutorialSpotlightPainter`) that measures real live widget `RenderBox` bounds, draws a dimmed cutout with glowing pulsing rings, renders an animated pointing hand and trilingual speech bubble, and passes touches directly to the real underlying widget so user actions trigger genuine application transitions.

**Tech Stack:** Flutter / Dart (Standard Library: `CustomPainter`, `AnimationController`, `OverlayEntry`, `SharedPreferences`), Material 3.

**Spec:** `/home/yasas/Downloads/ANTIGRAVITY_LIVE_TUTORIAL_MASTER_IMPLEMENTATION_PROMPT.md`

## Global Constraints

- Android Application ID: `lk.yasas.simpleaac`
- Frozen Build 8 protection: Do not touch or overwrite `/home/yasas/Desktop/Simple_AAC_Play_Release_2026-11-14/`
- Current development branch: `feature/interactive-first-run-onboarding-v1.1.1` (base commit `72b78d2`)
- No third-party coachmark library dependencies (use clean Flutter primitives)
- Offline-first & privacy preservation: Online Features remain OFF by default unless opted in
- Trilingual support: English, Sinhala (`සිංහල`), Tamil (`தமிழ்`)
- Accessibility: Honor reduced motion preferences, screen reader semantics, min 48dp touch targets
- No automated push, PR, merge, or tag without explicit user approval

## Review Focus

1. Scrim touch pass-through: Touches inside the highlighted target box must reach the real underlying widget (e.g. Hamburger menu, Enable Edit Mode, Add New, Save Card).
2. Clean dismissal and lifecycle: Skipping or finishing the tutorial must cleanly detach the overlay entry without leaving a black screen or absorbing touches.
3. Rotation and layout resilience: If screen size or orientation changes, spotlight cutouts must dynamically recalculate or cleanly reposition.
4. Multilingual label safety: AI recognition or tutorial completion must never replace card labels with empty values, null, or `(unavailable)`.
5. Non-intrusive first-run: Caregivers can dismiss "Not Now" on first launch and immediately use all communication cards without being forced into onboarding.

---

### Task 1: Tutorial State Machine, Strings & Storage (`TutorialService`)

**Files:**
- Create: `lib/services/tutorial_service.dart`
- Create: `lib/models/tutorial_step.dart`
- Create: `lib/utils/tutorial_strings.dart`
- Test: `test/tutorial_service_test.dart`

**Steps:**
- [ ] Write failing test in `test/tutorial_service_test.dart` for tutorial step state transitions, persistence keys (`has_seen_welcome_v111`, `tutorial_completed_v111`), and trilingual string resolution.
- [ ] Implement `TutorialStep` enum and configuration model (`openMenu`, `drawerExplore`, `enableEditMode`, `addNewCard`, `mediaChoices`, `labelFields`, `voiceRecording`, `saveCard`, `testNewCard`, `completed`).
- [ ] Implement `TutorialStrings` providing English, Sinhala, and Tamil strings for titles, subtitles, instructions, and buttons.
- [ ] Implement `TutorialService` singleton with `ValueNotifier<TutorialStep?>`, `startTour()`, `nextStep()`, `previousStep()`, `skipTour()`, `finishTour()`, and `SharedPreferences` persistence.
- [ ] Run `flutter test test/tutorial_service_test.dart` and confirm all tests pass.

---

### Task 2: Coachmark Spotlight, Pulsing Ring & Hand Pointer Overlay (`TutorialOverlay`)

**Files:**
- Create: `lib/widgets/tutorial/tutorial_overlay.dart`
- Create: `lib/widgets/tutorial/tutorial_spotlight_painter.dart`
- Create: `lib/widgets/tutorial/tutorial_hand_pointer.dart`
- Create: `lib/widgets/tutorial/tutorial_speech_bubble.dart`
- Test: `test/tutorial_overlay_test.dart`

**Steps:**
- [ ] Write failing widget test in `test/tutorial_overlay_test.dart` verifying spotlight cutout geometry, pulse animation, speech bubble rendering, and touch pass-through in target rect.
- [ ] Implement `TutorialSpotlightPainter` rendering dark scrim (`Colors.black54`) with rounded-rectangle cutout and animated pulsing concentric rings.
- [ ] Implement `TutorialHandPointer` with smooth vertical/curved translation animation pointing directly at the target.
- [ ] Implement `TutorialSpeechBubble` with direction pointer arrow, step badge (`1/8`), trilingual text, Back, Next, and Skip actions.
- [ ] Implement `TutorialOverlay` integrating target measurement, speech bubble placement above/below target, and `Listener` / `CustomHitTest` pass-through.
- [ ] Run `flutter test test/tutorial_overlay_test.dart` and confirm tests pass.

---

### Task 3: First-Run Welcome Sheet & HomePage Integration

**Files:**
- Create: `lib/widgets/tutorial/welcome_tour_dialog.dart`
- Modify: `lib/pages/home_page.dart`
- Modify: `lib/widgets/home_app_bar.dart`
- Modify: `lib/widgets/edit_mode_bar.dart`
- Test: `test/tutorial_home_integration_test.dart`

**Steps:**
- [ ] Write failing widget test in `test/tutorial_home_integration_test.dart` verifying first-run welcome dialog display, "Start Quick Tour" launching Step 1, "Not Now" dismissing cleanly, and Menu button spotlight.
- [ ] Implement `WelcomeTourDialog` with friendly Simple AAC illustration, title "Welcome to Simple AAC Sri Lanka", description, "Start Quick Tour" button and "Not Now" button.
- [ ] Add tutorial target `GlobalKey`s to `HomeAppBar` (menu button) and `EditModeBar` (`+ Add New` button).
- [ ] Wire `TutorialService` listener in `_HomePageState` to mount the `TutorialOverlay` entry and advance steps on real user taps.
- [ ] Run `flutter test test/tutorial_home_integration_test.dart` and verify tests pass.

---

### Task 4: Settings Drawer Integration & Replay Entry Point

**Files:**
- Modify: `lib/widgets/home_drawer.dart`
- Modify: `lib/pages/home_page.dart`
- Test: `test/tutorial_drawer_integration_test.dart`

**Steps:**
- [ ] Write failing widget test in `test/tutorial_drawer_integration_test.dart` verifying drawer expand/shrink/close guide, "Enable Edit Mode" spotlight, and "Replay Quick Tour" button in Settings.
- [ ] Add tutorial target `GlobalKey` to "Enable Edit Mode" card and expand/shrink chevron button in `HomeDrawer`.
- [ ] Add `Quick Tour` list tile under Help / About in `HomeDrawer` with subtitle `Replay interactive app guide` and `onReplayTutorial` callback.
- [ ] When tutorial is in `drawerExplore` step, guide the user through drawer interactions, and advance to `enableEditMode`.
- [ ] Run `flutter test test/tutorial_drawer_integration_test.dart` and verify tests pass.

---

### Task 5: Card Editor Dialog Integration (Media, Labels, Voice & Save)

**Files:**
- Modify: `lib/widgets/card_editor_dialog.dart`
- Modify: `lib/pages/home_page.dart`
- Test: `test/tutorial_card_editor_integration_test.dart`

**Steps:**
- [ ] Write failing test in `test/tutorial_card_editor_integration_test.dart` verifying media choice spotlight, label preview guidance, voice recording guide, and Save Card spotlight.
- [ ] Add tutorial target `GlobalKey`s in `CardEditorDialog` for Media buttons row (`Smart Search`, `Gallery`, `Camera`, `GIF`), multilingual label fields, Voice Recording button, and `Save Card` button.
- [ ] Hook `CardEditorDialog` callbacks to `TutorialService` so choosing a media method, confirming labels, or tapping Save Card automatically triggers the next tutorial step.
- [ ] When card is saved, return to AAC board, spotlight the newly added card, prompt user to tap it, play audio, and celebrate completion!
- [ ] Run `flutter test test/tutorial_card_editor_integration_test.dart` and verify tests pass.

---

### Task 6: Replayable Settings Mini-Guides (PIN, Backup, Permissions, Online Privacy)

**Files:**
- Create: `lib/widgets/tutorial/mini_guides_dialog.dart`
- Modify: `lib/widgets/home_drawer.dart`
- Test: `test/mini_guides_test.dart`

**Steps:**
- [ ] Write failing test in `test/mini_guides_test.dart` for Caregiver PIN unlock guide, Backup & Restore guide, Permissions status guide, and Online Features privacy guide.
- [ ] Implement `MiniGuidesDialog` allowing users to select any specific guide to view anytime.
- [ ] Wire "Mini Guides" entry point in `HomeDrawer` under Help / Settings.
- [ ] Run `flutter test test/mini_guides_test.dart` and verify tests pass.

---

### Task 7: Full Test Suite, Analyzer & Physical Device Live Verification

**Files:**
- Verify: All tests across project (`flutter test`)
- Verify: Code health (`flutter analyze --no-pub`)
- Verify: Physical Samsung Galaxy A34 5G live interaction & screenshot capture

**Steps:**
- [ ] Run `flutter analyze --no-pub` and confirm 0 warnings / 0 errors.
- [ ] Run full project test suite `flutter test` and confirm 100% tests pass.
- [ ] Build release APK (`flutter build apk --release`).
- [ ] Install APK on connected Samsung Galaxy A34 5G (`192.168.8.118:42665`).
- [ ] Test live on-device: First launch welcome dialog, Menu tap spotlight, Drawer interactions, Enable Edit Mode, Add New Card, Media picker, Label confirmation, Save Card, New card tap, and Settings replay.
- [ ] Capture genuine screenshots of every live tutorial step on the device.
- [ ] Deliver structured final report (Sections 1 to 21).
