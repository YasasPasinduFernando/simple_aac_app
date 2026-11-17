# Simple AAC — Agent Operating Guide

Welcome to the **Simple AAC** codebase. This document is the primary reference for AI agents, developers, and code reviewers working on this application.

---

## 1. Project Overview

**Simple AAC (Sri Lanka)** is an Augmentative and Alternative Communication (AAC) application designed for non-verbal individuals, children with speech delays, autistic communicators, and adults recovering from stroke or speech impairment.

* **Target Version:** `v1.1.0` (Build `8`, `versionCode = 8`)
* **Production Package ID:** `lk.yasas.simpleaac`
* **Isolated Dev Package ID:** `lk.yasas.simpleaac.dev`
* **Target Release Date:** November 14, 2026
* **Target Release Branch:** `release/play-2026-11-14`
* **Release Worktree:** `/media/yasas/New Volume2/yasas/PersonalProjects/simple aac/simple_aac_play_release`
* **Language Support:** Trilingual (Sinhala `si`, Tamil `ta`, English `en`)
* **Platform:** Flutter 3.47+ / Dart 3.13+ targeting Android (Min SDK 24, Target SDK 36) and iOS.

---

## 2. Codebase Architecture & File Map

The codebase follows a modular Flutter architecture organized into models, services, widgets, pages, and utilities:

```
lib/
├── main.dart                               # App entry point, MaterialApp, theme setup
├── data/
│   └── default_seed_cards.dart             # Default starter cards (Hello, Happy, Sad, Angry, More)
├── models/
│   ├── aac_card_model.dart                 # AACCard data model with JSON serialization
│   ├── tts_token.dart                      # Tokens assembled in speech bar for sequential playback
│   └── image_search_result.dart            # Results model for child-safe Smart Image Search
├── pages/
│   └── home_page.dart                      # Main AAC communication board, grid, and coordinator
├── services/
│   ├── backup_service.dart                 # Zip-based hardened backup & restore (Zip Slip safe)
│   ├── card_storage_service.dart           # Atomic card JSON persistence with backup failover
│   ├── speech_engine.dart                  # Multilingual Google TTS engine with script routing
│   ├── network_policy_service.dart         # Child-safe offline policy enforcer
│   └── openverse_search_provider.dart      # Creative Commons child-safe image search provider
├── utils/
│   ├── animated_media_helper.dart          # GIF detection, animated thumbnail rendering
│   ├── app_permissions_helper.dart         # Dual-permission handler (Camera + Audio)
│   ├── camera_object_helper.dart           # Offline ML Kit vision object classifier
│   ├── card_image.dart                     # Memory-bounded image decoder with gapless playback
│   ├── multilingual_speech_router.dart     # Unicode-script text splitter (Sinhala/Tamil/English)
│   ├── theme_accessibility.dart            # Dark mode & color-blind state notifiers
│   └── ui_mode_helper.dart                 # System UI and screen orientation controller
└── widgets/
    ├── home_app_bar.dart                   # Approved home header ([PIN] | Simple AAC [MENU])
    ├── home_drawer.dart                    # Modern settings drawer with live preview chips
    ├── professional_color_picker_dialog.dart # Compact 3-tier color picker with real-time preview
    ├── card_editor_dialog.dart             # Card edit modal with camera, gallery, voice recording
    ├── smart_image_search_dialog.dart      # Child-safe image search sheet
    ├── styled_dialog_header.dart           # Standardized dialog header widget
    ├── tts_bar.dart                        # Sentence construction bar with Play/Clear/Delete
    └── edit_mode_bar.dart                  # Visible bar indicating board editing is active
```

---

## 3. Project Skills & Discovery

Specialized engineering workflows are packaged into project-local Agent Skills in `.agents/skills/`:

| Skill | Path | When to Use |
| :--- | :--- | :--- |
| **`flutter-ui-ux`** | `.agents/skills/flutter-ui-ux/SKILL.md` | Designing or refining UI components, layouts, spacing, themes, and responsiveness. |
| **`aac-accessibility`** | `.agents/skills/aac-accessibility/SKILL.md` | Ensuring large tap targets (≥48×48dp), WCAG contrast, screen-reader semantics, and color-blind safety. |
| **`design-system`** | `.agents/skills/design-system/SKILL.md` | Verifying colors, radii, spacing, typography, dialog patterns, and approved UI invariants. |
| **`flutter-quality`** | `.agents/skills/flutter-quality/SKILL.md` | Executing tests, static analysis, overflow checks, and release qualification. |
| **`release-management`** | `.agents/skills/release-management/SKILL.md` | Managing versioning, changelogs, Git checkpoints, Play Store requirements, and release evidence. |
| **`graphify`** | `.agents/skills/graphify/SKILL.md` | Querying codebase knowledge graph, file relationships, god nodes, and tracing paths. |
| **`ponytail`** | `.agents/skills/ponytail/SKILL.md` | Enforcing lazy senior dev mode: YAGNI, shortest working diff, stdlib/native first. |
| **`ponytail-review`** | `.agents/skills/ponytail-review/SKILL.md` | Code review hunting for over-engineering, unneeded abstractions, and bloat. |
| **`ponytail-audit`** | `.agents/skills/ponytail-audit/SKILL.md` | Whole-repo audit scanning for dead code, unneeded dependencies, and simplification. |
| **`ponytail-debt`** | `.agents/skills/ponytail-debt/SKILL.md` | Tracking deliberate shortcuts, deferrals, and `ponytail:` comments across the repo. |
| **`ponytail-gain`** | `.agents/skills/ponytail-gain/SKILL.md` | Displaying measured impact and productivity metrics. |
| **`ponytail-help`** | `.agents/skills/ponytail-help/SKILL.md` | Quick reference card for all ponytail modes, commands, and options. |

---

## 4. Codebase Knowledge Base (Graphify)

A comprehensive, GraphRAG-ready architectural knowledge base is generated and maintained in `graphify-out/`:

* **Knowledge Graph Report:** `graphify-out/GRAPH_REPORT.md` (architecture summary, 383 communities, hub nodes)
* **Interactive Topology Visualizer:** `graphify-out/graph.html` (open in browser for 2D interactive force-directed graph)
* **Knowledge Graph JSON:** `graphify-out/graph.json` (2,867 nodes, 3,709 edges)
* **Architecture Call-Flow:** `graphify-out/simple_aac_play_release-callflow.html` (Mermaid sequence & flow diagrams)
* **Codebase Wiki:** `graphify-out/wiki/index.md` (393 cross-referenced Markdown articles)

---

## 5. Key Verification & Test Commands

Always verify changes before considering tasks complete:

```bash
# 1. Static code analysis (must have 0 errors, 0 warnings)
flutter analyze

# 2. Run targeted test file
flutter test test/<test_file_name>_test.dart

# 3. Run full automated regression suite (all 87+ tests must pass)
flutter test

# 4. Check git status
git status
```

---

## 6. Documentation & Release Knowledge

* **Play Store Signing & Identity Guide:** `docs/releases/PLAY_STORE_SIGNING_AND_IDENTITY_GUIDE.md`
* **Release Management Skill:** `.agents/skills/release-management/SKILL.md`
* **Design System Reference:** `docs/design/DESIGN_SYSTEM.md`
* **November 14 Release Log:** `docs/releases/2026-11-14-v1.1.0.md`
* **Release Readiness Report:** `NOV14_PLAY_RELEASE_READINESS_REPORT.md`
* **Camera / Video Audit:** `docs/qa/CAMERA_VIDEO_FORENSIC_AUDIT.md`
* **Project Changelog:** `CHANGELOG.md`

---

## 7. Development Rules & Operational Boundaries

1. **Lazy Senior Dev Mode (Ponytail):** Minimal working diffs. Use native Flutter widgets and Dart standard library. No unnecessary abstractions or dependencies. Follow `.agents/rules/ponytail_rules.md`.
2. **Knowledge Base Navigation (Graphify):** Query `graphify-out/` knowledge graph before complex architectural changes. Follow `.agents/rules/graphify_rules.md`.
3. **Never Report Unexecuted Checks as Passed:** Always run the actual commands and inspect the output.
4. **No Unapproved Push or Publish:** Never execute `git push`, merges to main, or Play Console deployments without explicit user confirmation.
5. **Preserve User Data:** Never wipe user cards, voice recordings, or camera images during migrations or testing.
6. **Strict Production Package ID (`lk.yasas.simpleaac`):** The production `applicationId` MUST ALWAYS be `lk.yasas.simpleaac`. Never revert to `com.example.simple_aac_app`. Keep `namespace = "com.example.simple_aac_app"` separate from `applicationId` in `build.gradle.kts`. Debug variants use `applicationIdSuffix = ".dev"` (`lk.yasas.simpleaac.dev`).
7. **Official Upload Key Requirement:** Production releases MUST be signed with `/home/yasas/simple-aac-signing/simple-aac-upload.jks` (alias `simpleaacupload`, RSA 3072, SHA-256 fingerprint `81:18:50:33:8F:19:CB:0D:02:6E:99:76:3D:75:6F:23:BE:10:B1:C3:F0:B8:54:EA:09:70:EC:14:AD:CD:14:88`). Never commit `.jks`, passwords, or `key.properties` to Git.
