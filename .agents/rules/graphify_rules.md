# Graphify — Knowledge Base Operating Rules

This repository maintains a persistent Graphify knowledge graph under `graphify-out/`.

### Knowledge Base Artifacts
- **`graphify-out/graph.json`**: GraphRAG-ready semantic + AST knowledge graph containing all nodes, relationships, and communities.
- **`graphify-out/GRAPH_REPORT.md`**: Executive codebase knowledge base report with detected architecture, god nodes, cross-module dependencies, and risk areas.
- **`graphify-out/graph.html`**: Interactive web visualization of the entire codebase topology.
- **`graphify-out/wiki/`**: Modular Markdown wiki articles for every cluster and subsystem.
- **`graphify-out/simple_aac_play_release-callflow.html`**: Mermaid interactive call-flow diagrams.

### Operating Instructions
1. **Querying Codebase Architecture:**
   - Before guessing how modules connect, query the knowledge graph:
     ```bash
     graphify query "<question>"
     ```
   - For tracing paths between concepts:
     ```bash
     graphify path "NodeA" "NodeB"
     ```
   - For plain-language node explanations:
     ```bash
     graphify explain "NodeName"
     ```
2. **Keeping the Graph Updated:**
   - Re-extract AST after major code modifications:
     ```bash
     graphify update .
     ```
   - Git hooks are installed to auto-sync graph state on commits/merges.
