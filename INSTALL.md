# Installation

## Prerequisites

- **git**: Required for worktree and branch management
- **gh** (GitHub CLI): Required for Issue and PR operations
- **[superpowers](https://github.com/obra/superpowers)**: Required peer dependency

## Claude Code

### Install superpowers

```bash
/plugin install superpowers@claude-plugins-official
```

### Install issue-flow

```bash
git clone https://github.com/crazygit/issue-flow ~/.claude/plugins/issue-flow
```

Restart Claude Code. The SessionStart hook will automatically inject issue-flow awareness.

### Hook Setup (optional)

The state-transition-guard hook is automatically configured via `.claude-plugin/hooks.json`. If you need manual setup, add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Skill",
        "command": "bash ~/.claude/plugins/issue-flow/hooks/state-transition-guard.sh"
      }
    ]
  }
}
```

## Codex

See [.codex/INSTALL.md](.codex/INSTALL.md) for Codex-specific instructions.

## Verification

```bash
# Claude Code
/issue-flow

# Codex
issue-flow
```

## Updating

```bash
cd ~/.claude/plugins/issue-flow && git pull
```

Or use the version bump script: `bash scripts/bump-version.sh <new-version>`

## Uninstalling

```bash
# Claude Code
rm -rf ~/.claude/plugins/issue-flow

# Codex
rm ~/.agents/skills/issue-flow
rm -rf ~/.codex/issue-flow
```
