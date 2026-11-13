# Simple AAC — Agent Operational Rules

1. **Safety & Git Scope:**
   - Always verify current worktree (`git status`) before touching files.
   - Do not modify production signing configs, keystores, or permissions without explicit authorization.
   - Never push to remote, merge, or publish without explicit user instruction.

2. **Verification Before Claiming Success:**
   - Never claim a bug is fixed, a test passes, or code compiles without executing the relevant command (`flutter analyze`, `flutter test`) and confirming the result.
   - Maintain the existing 87+ automated test suite regression-free.

3. **Code & Dependency Discipline:**
   - Prefer standard library, native Flutter widgets, and existing codebase helpers.
   - No speculative abstractions or unrequested packages.
   - Respect user-created communication cards and family voice recordings.

4. **Skill Discovery:**
   - Refer to project skills in `.agents/skills/` (`flutter-ui-ux`, `aac-accessibility`, `design-system`, `flutter-quality`, `release-management`) when designing or verifying changes.
