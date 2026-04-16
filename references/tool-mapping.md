# Platform Tool Mapping

Issue-flow skills use Claude Code tool names. Other platforms may need different names.

## Core Tools

| Claude Code | Codex | Description |
|-------------|-------|-------------|
| `Read` | `Read` | Read file contents |
| `Write` | `Write` | Write/create file |
| `Edit` | `Edit` | Edit existing file |
| `Glob` | `Glob` | Find files by pattern |
| `Grep` | `Grep` | Search file contents |
| `Bash(cmd)` | `Bash(cmd)` | Execute shell command |
| `AskUserQuestion` | (N/A) | Prompt user for input |
| `Agent` | (N/A) | Spawn sub-agent |
| `Skill(name)` | (N/A) | Invoke another skill |

## Platform-Specific Notes

### Claude Code
- Full tool support including `Agent`, `Skill`, `AskUserQuestion`
- Hooks supported via `settings.json`
- Skills loaded from `~/.claude/skills/` or plugins

### Codex
- No `Agent` tool — `issue-implement` falls back to `superpowers:executing-plans` (sequential)
- No `Skill` chaining — skills must be invoked directly
- No `AskUserQuestion` — auto mode behavior used by default
- No hooks — state transitions enforced by skill instructions only

### Other Platforms
For platforms not listed here, refer to the tool mapping above and adapt skill instructions accordingly.
