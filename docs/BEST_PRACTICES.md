# Simple AAC Sri Lanka — Code & Engineering Best Practices

This guide establishes the coding standards, design principles, and maintenance guidelines for developers and AI agents working on **Simple AAC Sri Lanka**.

---

## 1. The "Lazy Senior Dev" (Ponytail) Philosophy

> *The best code is the code never written. Lazy means efficient, not careless.*

Before writing or modifying any code in Simple AAC Sri Lanka, climb the efficiency ladder:

1. **Does this need to be built at all? (YAGNI):** Do not build speculative features or preemptive abstractions.
2. **Does it already exist in the codebase?:** Always grep the codebase first. Reuse existing widgets (`AacCardWidget`, `HomeDrawer`), services (`CardStorageService`, `SpeechEngine`), and utility functions.
3. **Does the standard library / Flutter framework already do this?:** Use built-in widgets and Dart standard library features rather than writing custom logic.
4. **Does an already-installed package solve it?:** Check `pubspec.yaml` before adding any new dependency.
5. **Shortest working diff wins:** Fix the root cause in the shared component once, rather than placing multiple defensive patches across call sites.
6. **Deletion over addition:** Simplifying or removing redundant code is always preferred over adding complexity.

---

## 2. Flutter & Dart Development Standards

### 2.1 State Management & Widget Lifecycle
* **Minimize Rebuild Scopes:** Avoid triggering top-level `setState()` on `HomePage` when local widget states (`AacCardWidget`, dialogs) can handle state transitions internally.
* **Stream & Controller Cleanup:** Every `TextEditingController`, `AnimationController`, `ScrollController`, and `StreamSubscription` must be disposed in `dispose()`.
* **Const Constructors:** Use `const` constructors wherever possible to enable compile-time widget caching.

### 2.2 Defensive UI Modifications
* **String Replacement Safety:**
  - When updating user-facing UI text (e.g. British English spelling `Color` -> `Colour`), modify **only display strings** (titles, descriptions, tooltips, dialogs).
  - **NEVER** modify Flutter API names (`Color`, `Colors`), variable names (`cardColor`), `SharedPreferences` keys (`app_primary_color`), database columns, or backup JSON serialization keys.
* **Null Safety:** Strict null safety is enforced. Never use unchecked force-unwrap (`!`) on nullable data models unless guarded by an immediate prior null check.

---

## 3. AAC UI/UX & Sensory Accessibility Standards

1. **Touch Targets & Motor Accessibility:**
   - Minimum tap target size: **48x48 dp** (Android accessibility standard).
   - Generous hit-test padding on card action buttons and dialog triggers.
   - Support for touch hold delays to prevent accidental double-taps for users with tremors or fine-motor difficulties.

2. **Visual Ergonomics & Contrast:**
   - Text on cards must maintain a contrast ratio of at least **4.5:1** against the background.
   - Dark Mode must use soft, non-fatiguing pastel fills behind transparent symbol icons rather than harsh white cards.
   - Respect user-configured Color Vision Deficiency (CVD) modes throughout all dynamic color calculations.

3. **Acoustic Reliability:**
   - Voice feedback must trigger with sub-100ms latency.
   - Always allow custom human voice recordings to supersede synthetic TTS for personalized, comforting child communication.

---

## 4. Testing & Verification Rules

1. **No Untested Non-Trivial Logic:**
   - Non-trivial logic must have at least one runnable test verifying it.
   - Keep tests focused, readable, and assert-based. No bloated mock frameworks.
2. **Static Analysis Zero-Tolerance:**
   - Run `flutter analyze` before any commit.
   - Zero errors, zero warnings, zero lints permitted in production branches.
3. **Physical Hardware QA:**
   - Simulator tests do not substitute for physical device checks. Always verify memory behavior, camera intent handling, and audio synthesis on real hardware (e.g., Samsung Galaxy A34).
