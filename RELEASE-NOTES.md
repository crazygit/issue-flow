# Release Notes

## v1.1.0

State lifecycle update for issue and bugfix workflows.

### Features
- Added pre-worktree pending state with `.issue-flow/pending.json` for issue-flow.
- Added optional `.bugfix-flow/pending.json` for bugfix-flow clarification before worktree creation.
- Made pick skills create the initial formal `state=picked` and `mode` files in target worktrees.
- Clarified pending ownership, cleanup, and mode-detection precedence across workflow docs.

### Tests
- Added coverage for pending files not being treated as formal state.
- Added skill-loading checks for pending-state contracts and pick-owned initial state.

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
