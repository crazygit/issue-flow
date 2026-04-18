# Codex Tool Mapping

Issue-flow skills use Claude Code tool names. Codex uses different names.

## Tool Mapping

| Claude Code | Codex | Available |
|-------------|-------|-----------|
| `Read` | `Read` | Yes |
| `Write` | `Write` | Yes |
| `Edit` | `Edit` | Yes |
| `Glob` | `Glob` | Yes |
| `Grep` | `Grep` | Yes |
| `Bash(cmd)` | `Bash(cmd)` | Yes |
| `Agent` | (N/A) | No — use direct analysis |
| `Skill(name)` | (N/A) | No — invoke directly by name |
| `AskUserQuestion` | (N/A) | No — use auto-mode behavior |

## Impact on Skills

- `issue-flow`: `finish` 仍是显式入口；Codex 无 `AskUserQuestion` 时按 auto-mode 语义执行
- `issue-implement`: Falls back to `superpowers:executing-plans` (sequential, no subagents)
- `issue-verify`: Code review done via direct diff analysis instead of `Agent(code-reviewer)`; PR review loop should prefer `gh pr view --comments` and `gh pr checks`
- `issue-brainstorm`: No user interaction, outputs design spec directly
- `issue-create`: Always uses direct creation (no `--web` option)
- `issue-research`: Runs as a normal explicit phase before planning
- `issue-pr`: Always uses direct creation and defaults to draft PR (no `--web` option)
- `issue-commit`: Commits directly without user confirmation
- `issue-finish`: Treat user confirmation as an explicit command (`/issue-flow finish`) rather than an interactive question
- All skills: Auto-mode behavior by default
