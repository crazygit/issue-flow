# Issue-Flow

Issue-driven development orchestrator. Manages the full development lifecycle through a state machine, from requirement brainstorming to PR creation.

**Requires [superpowers](https://github.com/obra/superpowers) plugin.**

## Features

- **State machine workflow**: Brainstorm → Pick → Plan → Implement → Verify → Commit → PR → Finish
- **Manual & Auto modes**: Manual mode pauses for approval at each gate; auto mode runs continuously
- **Hook-based enforcement**: SessionStart hook injects skill awareness; PreToolUse hook validates state transitions
- **Code review agent**: Built-in agent for structured code review against acceptance criteria
- **Multi-platform**: Supports Claude Code and Codex

## Quick Start

```bash
# Claude Code
/plugin install superpowers@claude-plugins-official
git clone https://github.com/crazygit/issue-flow ~/.claude/plugins/issue-flow

# Codex
git clone https://github.com/obra/superpowers ~/.codex/superpowers
ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
git clone https://github.com/crazygit/issue-flow ~/.codex/issue-flow
ln -s ~/.codex/issue-flow/skills ~/.agents/skills/issue-flow
```

See [INSTALL.md](INSTALL.md) for detailed instructions.

## Usage

```bash
/issue-flow Add email login support       # Manual mode from requirement
/issue-flow --auto Add email login support  # Auto mode
/issue-flow #42                            # From existing issue
/issue-flow                                # Resume session
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│                 issue-flow (orchestrator)        │
│     reads .issue-flow/state → dispatches skill  │
└──────────────────────┬──────────────────────────┘
                       │
            ┌──────────▼──────────┐
            │   Core Skills       │
            │   (issue-*)         │──uses──▶ superpowers
            │                     │
            └─────────────────────┘

┌─────────────────────┐     ┌──────────────────┐
│ Hooks               │     │ Agents           │
│ session-start       │     │ code-reviewer    │
│ state-transition    │     └──────────────────┘
└─────────────────────┘
```

## State Machine

```
none → brainstorm → picked → planned → implementing → verifying → committing → pring → finished
                                       ↑_________________________↓
                                       (verify failure → retry)
```

## Skills

| Skill | Purpose | Superpowers Dependency |
|-------|---------|----------------------|
| `issue-flow` | Main orchestrator | `brainstorming`, `writing-plans`, `subagent-driven-development`, `finishing-a-development-branch` |
| `issue-brainstorm` | Requirements → design spec | `brainstorming` |
| `issue-create` | Design spec → GitHub Issue | — |
| `issue-pick` | Issue → worktree + branch | `using-git-worktrees` |
| `issue-plan` | Issue → implementation plan | `writing-plans` |
| `issue-implement` | Plan → code changes | `subagent-driven-development`, `executing-plans` |
| `issue-verify` | Test + lint + code review | — |
| `issue-commit` | Smart git commits | — |
| `issue-pr` | Pull Request creation | — |
| `issue-finish` | Cleanup | `finishing-a-development-branch` |

## Contributing

See [CLAUDE.md](CLAUDE.md) for contributor guidelines.

## License

[MIT](LICENSE)
