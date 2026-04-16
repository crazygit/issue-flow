# Architecture

## Overview

Issue-flow is an issue-driven development orchestrator built on a state machine pattern. It coordinates 10 workflow skills through a central orchestrator, with [superpowers](https://github.com/obra/superpowers) as a peer dependency providing core development capabilities.

## Repository Structure

```
issue-flow/
├── .claude-plugin/          # Claude Code plugin manifests
├── .codex/                  # Codex installation
├── .github/                 # Issue/PR templates
├── AGENTS.md                # Codex runtime instructions (@-references)
├── CLAUDE.md                # Contributor guidelines
├── agents/                  # Subagent definitions
├── hooks/                   # Hook scripts and declarations
├── references/              # Shared reference docs
├── scripts/                 # Utility scripts
├── skills/                  # Skill definitions
├── tests/                   # Test suites
└── docs/                    # Project documentation
```

## Components

### Orchestrator (`issue-flow`)

The central state machine coordinator. Responsibilities:
- Detect current development phase by reading `.issue-flow/state`
- Dispatch the appropriate sub-skill for the current phase
- Advance or rollback state based on sub-skill results
- Manage manual vs auto mode behavior

The orchestrator does NOT contain any execution logic — all concrete work is delegated to sub-skills.

### Workflow Skills (`issue-*`)

10 skills covering the full development lifecycle:

| Skill | Purpose | Superpowers Dependency |
|-------|---------|----------------------|
| `issue-brainstorm` | Requirement analysis → design spec | `brainstorming` |
| `issue-create` | Design spec → GitHub Issue | — |
| `issue-pick` | Issue → worktree + branch setup | `using-git-worktrees` |
| `issue-plan` | Issue → implementation plan | `writing-plans` |
| `issue-implement` | Plan → code changes | `subagent-driven-development`, `executing-plans` |
| `issue-verify` | Code → test + lint + review | — |
| `issue-commit` | Changes → git commits | — |
| `issue-pr` | Commits → Pull Request | — |
| `issue-finish` | PR done → cleanup | `finishing-a-development-branch` |

### Superpowers (peer dependency)

[superpowers](https://github.com/obra/superpowers) provides the core development capabilities:

| Superpowers Skill | Used By | Purpose |
|-------------------|---------|---------|
| `brainstorming` | `issue-brainstorm` | Structured design analysis |
| `writing-plans` | `issue-plan` | Plan generation from design specs |
| `subagent-driven-development` | `issue-implement` | Parallel plan execution via subagents |
| `executing-plans` | `issue-implement` | Sequential plan execution (fallback) |
| `using-git-worktrees` | `issue-pick` | Worktree and branch management |
| `finishing-a-development-branch` | `issue-finish` | Branch lifecycle management |

### Agents

Subagent definitions in `agents/`:
- `code-reviewer` — Used by `issue-verify` for structured code review

### Hooks

Two hook mechanisms, declared in `hooks/hooks.json`:

| Hook Type | Script | Purpose |
|-----------|--------|---------|
| `SessionStart` | `hooks/session-start` | Injects issue-flow awareness at every session start |
| `PreToolUse` | `hooks/state-transition-guard` | Validates legal state transitions for `Skill(issue-*)` calls |

## State Machine

```
none → brainstorm → picked → planned → implementing → verifying → committing → pring → finished
                                       ↑________________↓
```

See `skills/issue-flow/references/state-schema.md` for the full definition.

## State Persistence

Session state is stored in `.issue-flow/` at the worktree root:
- `state` — Current phase (read/write by orchestrator only)
- `mode` — `auto` or `manual`
- `issue.json` — Issue metadata (number, title, url, type)
- `plan-path` — Path to the implementation plan
- `verify-report.md` — Verification results

## Dependency Design

Skills declare dependencies by listing `Skill(name)` in `allowed-tools`:

```yaml
allowed-tools:
  - Skill(superpowers:brainstorming)  # peer dependency
```

Issue-flow requires superpowers to be installed. The SessionStart hook checks availability and prompts installation if missing.

## Multi-Platform Support

### Claude Code
Full support: Agent, Skill, AskUserQuestion, hooks.

### Codex
Limited support: no Agent/Skill tools, no hooks. Skills fall back to sequential execution and auto-mode behavior. See `skills/issue-flow/references/codex-tools.md` for tool mapping.
