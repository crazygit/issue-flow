# Codex Installation

## Prerequisites

- Codex CLI installed
- `gh` (GitHub CLI) installed and authenticated
- `git` installed

## Step 1: Install superpowers

```bash
git clone https://github.com/obra/superpowers ~/.codex/superpowers
ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
```

## Step 2: Install issue-flow

```bash
git clone https://github.com/crazygit/issue-flow ~/.codex/issue-flow
ln -s ~/.codex/issue-flow/skills ~/.agents/skills/issue-flow
```

## How it works in Codex

Codex discovers skills via the `~/.agents/skills/` symlink. When you type `issue-flow`, Codex reads `skills/issue-flow/SKILL.md` and follows the state machine.

Note: `AGENTS.md` at the repo root is a symlink to `CLAUDE.md` (contributor guidelines). This is intentional — runtime instructions come from the skill files, not AGENTS.md.

## Important limitations

Codex does not support these Claude Code features:

| Feature | Impact | Workaround |
|---------|--------|------------|
| `Agent` tool | No subagent dispatch | `issue-implement` falls back to sequential execution |
| `Skill` tool | No skill chaining | Skills invoked directly by name |
| `AskUserQuestion` | No user prompts | Auto-mode behavior used by default |
| Hooks | No state enforcement | State transitions enforced by skill instructions only |
| `--web` flag | No browser | `issue-create` and `issue-pr` create directly |

## Usage

```
issue-flow Add user authentication       # Manual mode
issue-flow --auto Add user auth          # Auto mode
issue-flow #42                           # From existing issue
issue-flow                               # Resume session
```

## Verification

```bash
ls -la ~/.agents/skills/issue-flow
```

You should see a symlink pointing to your issue-flow skills directory.

## Updating

```bash
cd ~/.codex/issue-flow && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/issue-flow
```

Optionally delete the clone: `rm -rf ~/.codex/issue-flow`.
