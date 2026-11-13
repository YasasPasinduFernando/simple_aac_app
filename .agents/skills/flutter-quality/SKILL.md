---
name: flutter-quality
description: Verification workflows, static analysis commands, test execution rules, and release qualification checklists for Simple AAC.
---

# Flutter Code Quality & Verification Skill

This skill enforces strict testing, verification, and regression prevention standards for Simple AAC. No work is considered complete, fixed, or ready until verified by actual command outputs and test execution.

> [!IMPORTANT]
> **Strict Verification Rule:** Never report an unexecuted check as passed. Never claim "tests pass" without running `flutter test` and confirming the exit code and summary.

---

## 1. Local Verification Protocol

Whenever code, configuration, or documentation changes are made in the project:

### Step 1: Static Analysis
Execute static analysis across the entire project:
```bash
flutter analyze
```
* **Acceptance criteria:** Must report `No issues found!`. Zero errors, zero warnings, zero hints unless explicitly documented and accepted.

### Step 2: Targeted Test Execution
Run the specific test file that covers the modified feature or bug fix:
```bash
flutter test test/<specific_test>.dart
```
* Verify individual assertions pass and investigate any failure at the root cause.

### Step 3: Full Regression Test Suite
Run all automated unit and widget tests:
```bash
flutter test
```
* Simple AAC maintains an 87+ test suite covering backup/restore, TTS multilingual routing, media storage, permission handling, camera object detection, UI responsiveness, and haptics. All tests must pass.

---

## 2. Specialized Quality Checklists

### 2.1 Small-Screen & Overflow Check
Test widgets on a simulated narrow device (320px logical width, e.g. compact Android device):
```dart
testWidgets('Component renders without overflow on 320px screen', (tester) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(home: TestedWidget()));
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull, reason: 'Must not trigger RenderFlex overflow');
});
```

### 2.2 Text Scaling & Internationalization Check
Ensure typography does not clip when the user enables Android System Large Text (1.5x or 2.0x font scaling):
```dart
tester.view.platformDispatcher.textScaleFactorTestValue = 1.8;
addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);
```

### 2.3 Accessibility & Touch Target Check
Verify interactive controls have minimum 48×48 dp tap targets:
```dart
final size = tester.getSize(find.byKey(buttonKey));
expect(size.width, greaterThanOrEqualTo(48.0));
expect(size.height, greaterThanOrEqualTo(48.0));
```

### 2.4 Multilingual Speech & TTS Isolation
When writing widget tests that pump `HomePage`:
* Set `HomePage.enableTtsInit = false;` in `setUp()` to avoid unmocked native platform method channels hanging the `FakeAsync` event loop.
* Set `HomePage.speakPerformer = (_) async {};` to bypass unmocked audio playback.
* Provide `HomePage.initialCardsForTesting = [...]` for immediate synchronous card mounting without disk I/O.

---

## 3. Android Release Build Verification

When validating a release candidate:

### 3.1 App Bundle (AAB) Build
```bash
flutter build appbundle --release
```
* Verifies Gradle build succeeds, ProGuard/R8 rules do not strip required reflection classes (e.g. `archive`, `audioplayers`), and production signing is applied.

### 3.2 16 KB ELF Page Alignment (Android 15 Compatibility)
Android 15 requires all native `.so` shared libraries inside the APK/AAB to be aligned to 16 KB page boundaries:
```bash
unzip -q -o build/app/outputs/bundle/release/app-release.aab -d /tmp/aab_verify
find /tmp/aab_verify -name "*.so" -exec objdump -p {} + | grep LOAD -A 1
```
* Verify `vaddr` and `paddr` alignment satisfies `0x4000` (16,384 bytes).

### 3.3 Dynamic Delivery Download Size Check
Measure real Google Play download footprint using `bundletool`:
```bash
bundletool get-size total --apks=release.apks
```
* Must remain strictly below the **30 MB** project limit.

---

## 4. Hardware Smoke Verification (When Device Connected)

If a physical Android device (e.g. Samsung Galaxy A34) is connected via `adb`:
1. Check battery status (`adb shell dumpsys battery | grep level`) before running long test sequences.
2. Confirm active package (`adb shell dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'`).
3. Verify Camera launch and Photo Picker activity without crashes or security exceptions.
4. Verify card tap haptic pulse and pop feel.
