# Simple AAC Sri Lanka — Skills, Tools & MCP Integration Guide

This guide details the specialized developer tools, Agent Skills, Model Context Protocol (MCP) servers, and subagent capabilities integrated into the **Simple AAC Sri Lanka** development environment.

---

## 1. Graphify Knowledge Graph Engine

[Graphify](https://github.com/YasasPasinduFernando/simple_aac_app/tree/main/graphify-out) transforms this entire codebase, documentation, and asset collection into a persistent, queryable knowledge graph with community clustering and architectural call-flows.

### Current Graph Statistics (v1.1.6):
* **Nodes:** 4,402
* **Edges:** 6,008
* **Communities:** 439
* **Wiki Articles:** 449 (`graphify-out/wiki/index.md`)

### Common Commands:
* **Natural Language Query (BFS Traversal):**
  ```bash
  graphify query "How does SpeechEngine handle Sinhala voice fallback?"
  ```
* **Directed Path Finding (Shortest Connection):**
  ```bash
  graphify path "CardEditorDialog" "CaregiverLockService"
  ```
* **Node Explanation:**
  ```bash
  graphify explain "AacCardWidget"
  ```
* **Incremental Re-Extraction (on Code Changes):**
  ```bash
  graphify update .
  ```
* **Export Interactive Visualizations:**
  ```bash
  graphify export html        # Emits graphify-out/graph.html
  graphify export wiki        # Updates graphify-out/wiki/ articles
  graphify export callflow-html  # Emits Mermaid architecture diagrams
  ```

---

## 2. Model Context Protocol (MCP) Servers

### 2.1 Android CLI & Device Hub
* **Server:** `android-cli` / `android-device-hub`
* **Use Cases:**
  - Discovering connected physical devices (Samsung Galaxy A34) and Android Virtual Devices (AVDs).
  - Capturing authentic full-resolution screenshots (`android screen capture`).
  - Inspecting UI accessibility hierarchies (`android layout`).
  - Executing live adb shell commands for memory and process lifecycle testing.

### 2.2 Chrome DevTools MCP
* **Server:** `chrome-devtools`
* **Use Cases:**
  - Automated inspection and navigation of Google Play Console releases.
  - Verifying Web app versions and cloud backup APIs.
  - Inspecting responsive layouts and accessibility contrast ratios.

### 2.3 Flutter & Dart MCP Server
* **Server:** `flutter_dart-mcp-server`
* **Tools:**
  - `analyze_files`: Fast static code analysis via Dart Analysis Server.
  - `get_runtime_errors`: Locates uncaught exceptions and active stack traces during development.
  - `pub_dev_search` / `pub`: Dependency resolution and conflict fixing.
  - `hot_reload` / `hot_restart`: Instant UI updates during live development.

---

## 3. Specialized AI Agent Skills

| Skill Name | Purpose in Simple AAC Project |
| :--- | :--- |
| **`ponytail`** | Enforces the "lazy senior dev" philosophy: cuts unnecessary abstractions, minimizes diffs, and prefers standard library/Flutter native features. |
| **`ponytail-audit`** | Scans the codebase for over-engineering, dead code, or redundant dependencies. |
| **`graphify`** | Queries codebase architecture and module dependencies via AST extraction and persistent graph storage. |
| **`dart-run-static-analysis`** | Runs `dart analyze` and mechanical automated fixes (`dart fix --apply`). |
| **`audio-requirements-analyzer`** | Analyzes clinical voice notes from speech therapists to derive AAC feature requirements. |
| **`job-application-pipeline`** | Prepares professional documentation and verified release artifacts. |

---

## 4. Subagent Delegation Guidelines

* **`research` Subagent:** Use for broad survey tasks, reading external Android/Flutter documentation, or exploring historical commits without cluttering the main context.
* **`browser` Subagent:** Delegated for interacting with live web applications or Google Play Console when automated verification is needed.
* **`self` Subagent:** Used for isolated multi-step verification tasks that need full write and shell tools in a parallel thread.
