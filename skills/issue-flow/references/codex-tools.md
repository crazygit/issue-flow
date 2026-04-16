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

- `issue-implement`: Falls back to `superpowers:executing-plans` (sequential, no subagents)
- `issue-verify`: Code review done via direct diff analysis instead of `Agent(code-reviewer)`
- `issue-brainstorm`: No user interaction, outputs design spec directly
- `issue-create`: Always uses direct creation (no `--web` option)
- `issue-pr`: Always uses direct creation (no `--web` option)
- `issue-commit`: Commits directly without user confirmation
- All skills: Auto-mode behavior by default
