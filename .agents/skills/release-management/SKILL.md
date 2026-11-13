---
name: release-management
description: Release engineering procedures, versioning rules, Git branching practices, changelog updates, and Play Store qualification protocols for Simple AAC.
---

# Simple AAC Release Management Skill

This skill governs the end-to-end release lifecycle for Simple AAC, establishing strict versioning, git safety, verification tracking, changelog maintenance, and Play Store deployment controls.

---

## 1. Release Architecture & Branching Model

### 1.1 Branch Hierarchy
* **`main` / `master`:** Protected baseline branch.
* **`release/play-YYYY-MM-DD`:** Dedicated release candidate branch (e.g. `release/play-2026-11-14`).
  * Used for hardening, UI refinement, bug fixes, QA evidence generation, and release documentation.
  * Work is conducted in isolated worktrees:
    `/media/yasas/New Volume2/yasas/PersonalProjects/simple aac/simple_aac_play_release`

### 1.2 Stable Historical Baselines & Rollback Points
Always preserve and reference verified points in the Git graph:
* **`e6fc156` (release/play-v1.0.2):** Original production Play Store release.
* **`0549334` (`tag: simple-aac-tts-stable-v1`):** Lightweight stable multilingual Google TTS baseline.
* **`185f207` (release-candidate/lightweight-multilingual-v1):** Base release candidate with ranked offline voice routing.
* **`fc7afef`:** Hardened backup and restore engine with Zip Slip traversal guards.
* **`8fbfa53`:** Initial November 14 release readiness documentation.
* **`6027a0d` (`tag: checkpoint/pre-color-picker-redesign`):** Checkpoint commit for home header redesign.

---

## 2. Versioning & Conventions

### 2.1 Version Code & Semantic Versioning
In `pubspec.yaml`:
```yaml
version: 1.1.0+4
```
* **Semantic Version (`1.1.0`):** Visible version shown to users in the About dialog, settings drawer header, and Google Play listing.
* **Version Code (`4`):** Strictly monotonically increasing integer required by Google Play for updates (`1.0.2` = 2, `1.0.3` = 3, `1.1.0` = 4).

### 2.2 Conventional Commits
All Git commit messages on release branches must follow the Conventional Commits standard:
* `feat(ui): ...` — New user-facing UI enhancements (e.g. color picker, haptics).
* `fix(speech): ...` or `fix(media): ...` — Bug fixes.
* `docs(release): ...` — Documentation and changelog updates.
* `test(...): ...` — Adding or refining automated tests.
* `build(release): ...` — Build script, signing, or dependency changes.

---

## 3. Mandatory Release Workflow for Code Changes

Whenever application code is updated:
1. **Identify Change:** Determine user-visible impact (Added, Changed, Fixed, Security, Deprecated, Removed).
2. **Execute Full Quality Suite:**
   ```bash
   flutter analyze && flutter test
   ```
   Both commands must pass with zero issues.
3. **Commit Locally First:** Create a discrete local commit with an appropriate conventional message.
4. **Update `CHANGELOG.md`:** Place new changes under `## [Unreleased]` or the target release version section.
5. **Update Release Document:** Record the new commit hash and verification results in `docs/releases/2026-11-14-v1.1.0.md`.
6. **No Spurious Claims:** Mark incomplete items as "Pending" or "Unverified". Never report an unexecuted test as passed.

---

## 4. Google Play Artifact Standards

| Attribute | Play Store Requirement | Simple AAC Status |
| :--- | :--- | :--- |
| **Format** | Android App Bundle (`.aab`) | Compiled via `flutter build appbundle --release` |
| **Signing** | Official Upload Keystore | Configured in `android/key.properties` |
| **Android 15 Page Alignment** | 16 KB ELF boundary for `.so` | Verified (`vaddr` aligned to `0x4000`) |
| **Storage Permissions** | Native Photo Picker compliance | Compliant (Zero broad `READ_EXTERNAL_STORAGE` or `MANAGE_EXTERNAL_STORAGE`) |
| **Download Size** | Project constraint < 30 MB | **~25.17 MB – 27.03 MB** (Measured via bundletool) |
| **Target SDK** | API 34+ (Android 14/15) | Target SDK 34 configured in `app/build.gradle` |

---

## 5. Pre-Release Gate Checklist

Before proposing or executing an upload to Google Play Console:
- [ ] Working tree is clean (`git status`).
- [ ] `flutter analyze` reports `No issues found!`.
- [ ] All 87+ tests pass (`flutter test`).
- [ ] Official Simple AAC icons verified in `android/app/src/main/res/mipmap-*/`.
- [ ] `docs/releases/2026-11-14-v1.1.0.md` reflects current HEAD commit.
- [ ] `CHANGELOG.md` is updated.
- [ ] No API keys, credentials, or keystores staged in Git.
- [ ] Approval from repository owner obtained before push or publish.
