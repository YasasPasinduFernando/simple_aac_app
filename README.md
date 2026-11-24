# Simple AAC Sri Lanka (සිංහල • தமிழ் • English)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://www.android.com)
[![License](https://img.shields.io/badge/License-Proprietary-blue.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-708%20Passing-success)](test/)

**Simple AAC Sri Lanka** (`lk.yasas.simpleaac`) is an Augmentative and Alternative Communication (AAC) platform engineered specifically for Sri Lankan children and individuals with speech and language impairments.

It gives a clear, dignified voice to children with Autism Spectrum Disorder (ASD), Cerebral Palsy (CP), Down Syndrome, and verbal apraxia through personalized visual communication boards, localized offline text-to-speech, and authentic human voice recordings.

---

## 📚 Essential Project Documentation

* **[RELEASE_LOG.md](RELEASE_LOG.md):** Complete release matrix, build version codes, git commits, branches, and SHA-256 artifact checksums.
* **[PROJECT_KNOWLEDGE.md](PROJECT_KNOWLEDGE.md):** Comprehensive technical architecture, subsystem breakdown, data models, and folder structure.
* **[docs/RELEASE_PRACTICES.md](docs/RELEASE_PRACTICES.md):** Production signing, AAB/APK compilation, checksum verification, and Google Play Console release playbook.
* **[docs/BEST_PRACTICES.md](docs/BEST_PRACTICES.md):** "Lazy Senior Dev" (Ponytail) engineering principles, Flutter standards, and accessibility guidelines.
* **[docs/SKILLS_AND_MCP_GUIDE.md](docs/SKILLS_AND_MCP_GUIDE.md):** Guide to Graphify, MCP servers, and specialized developer skills.
* **[docs/user-guides/v1.1.6/](docs/user-guides/v1.1.6/):** Official trilingual user guides (English, Sinhala, Tamil) in PDF, HTML, and Markdown.

---

## ✨ Key Features (v1.1.6 / Build 16)

* **Trilingual Native Offline Speech:** High-clarity speech synthesis in Sinhala (`si-LK`), Tamil (`ta-LK`), and English (`en-LK`/`en-GB`) with asynchronous pre-warming.
* **Custom Voice Recording:** Parents and therapists can record familiar voices for any card to maximize comfort and connection.
* **Dynamic Grid Density:** Adjustable from 1 to 30 columns with dedicated landscape accessibility layouts.
* **Transactional Edit Mode:** Drag-and-drop card reordering, move into subcards, and multi-step Undo/Cancel/Done session controls.
* **30-Day Safe Recycle Bin:** Media reference-counted soft deletion with instant restore and permanent shredding.
* **1:1 Crop & Zoom:** Image framing tool for camera captures and gallery imports.
* **Appearance & Theme Customization:**
  - Independent Light and Dark mode **Text-to-Speech Bar Colour**.
  - Seamless Dark Mode pastel fills for transparent symbols.
  - High-contrast safeguards and Color Vision Deficiency (CVD) support (Protanopia, Deuteranopia, Tritanopia).
  - British English (`Colour`, `Colours`) UI terminology standardization.
* **Caregiver Lock:** Custom 4-digit PIN protection for edit mode, settings, and factory resets.
* **Offline-First & Private:** Zero internet required for core communication; encrypted cloud and local backup exports (`.aacbackup`).

---

## 🧠 Codebase Knowledge Graph (Graphify)

This repository includes a persistent, queryable knowledge graph generated via [Graphify](docs/SKILLS_AND_MCP_GUIDE.md):
* **Nodes:** 4,402
* **Edges:** 6,008
* **Communities:** 439
* **Wiki:** 449 articles at [graphify-out/wiki/index.md](graphify-out/wiki/index.md)
* **Interactive Visualizer:** [graphify-out/graph.html](graphify-out/graph.html)

Query the graph anytime from the terminal:
```bash
graphify query "Explain the SpeechEngine architecture"
```

---

## 🚀 Development Quick Start

```bash
# Clone the repository
git clone https://github.com/YasasPasinduFernando/simple_aac_app.git
cd simple_aac_app

# Fetch dependencies
flutter pub get

# Run static analysis
flutter analyze

# Execute test suite (708 tests)
flutter test

# Launch on connected device or emulator
flutter run
```

---

## 🔒 Security & Privacy

Simple AAC Sri Lanka does not track users, log audio data, or connect to third-party ad networks. All user data, custom cards, and recorded voices are stored strictly inside the device's private sandbox.

---
*Developed with ❤️ by Yasas Pasindu Fernando for the children of Sri Lanka.*
