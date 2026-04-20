# Release Notes

## v1.0.0

Initial release.

### Features
- State machine orchestrator with 10 workflow skills
- Manual and auto execution modes
- Superpowers integration for brainstorming, planning, worktrees, and execution
- SessionStart hook for skill awareness injection
- State transition guard hook (PreToolUse)
- Code review agent definition
- Multi-platform support: Claude Code and Codex

### Skills
- `issue-flow` — Main orchestrator
- `issue-brainstorm` — Requirements → design spec
- `issue-create` — Design spec → GitHub Issue
- `issue-pick` — Issue → worktree + branch
- `issue-research` — Codebase research before planning
- `issue-plan` — Issue → implementation plan
- `issue-implement` — Plan → code changes
- `issue-verify` — Test + lint + review
- `issue-commit` — Smart git commits
- `issue-pr` — Pull Request creation
- `issue-finish` — Cleanup
