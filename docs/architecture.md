# Architecture

Issue-Flow is a thin orchestration layer for issue-driven development. It does not try to replace a full coding methodology. Instead, it coordinates a small set of workflow-specific skills and keeps the current session aligned with a single issue lifecycle.

## Design Goals

- Keep the repository lightweight
- Reuse proven workflows from `superpowers`
- Make workflow progress explicit through a persisted state machine
- Support both guided and automated execution styles
- Work across Claude Code and Codex without splitting the codebase into separate products

## High-Level Model

Issue-Flow has three main responsibilities:

1. Track the current workflow phase
2. Route the agent to the correct skill for that phase
3. Prevent invalid transitions where the host platform allows enforcement

Everything else should remain delegated to focused skills or to `superpowers`.

## Core Components

### Orchestrator skill

`skills/issue-flow/SKILL.md` is the entry point. It reads session state from `.issue-flow/`, determines the current phase, and hands control to the next workflow skill.

The orchestrator should stay small. It owns coordination, not execution details.

### Workflow skills

The `skills/issue-*` files implement each phase of the lifecycle:

| Skill | Responsibility |
|-------|----------------|
| `issue-brainstorm` | Turn a request into a design direction |
| `issue-create` | Convert a refined idea into a GitHub issue |
| `issue-pick` | Attach work to a specific issue and branch context |
| `issue-research` | Research the current codebase before planning |
| `issue-plan` | Turn issue context into an implementation plan |
| `issue-implement` | Execute the approved plan |
| `issue-verify` | Run verification and review steps |
| `issue-commit` | Prepare commits with predictable structure |
| `issue-pr` | Open or update the pull request and hand off to review |
| `issue-finish` | Clean up and close out the workflow |

### Hooks

`hooks/` contains the platform-side enforcement pieces:

- `session-start` reminds the host about Issue-Flow context at the start of a session
- `state-transition-guard` blocks invalid `issue-*` skill transitions where hook support exists

### Agents

`agents/` contains supporting agent definitions, such as the code-review worker used during verification flows.

## State Model

Issue-Flow persists session state in a `.issue-flow/` directory at the worktree root. Typical files include:

- `state` - current workflow phase
- `mode` - manual or auto
- `issue.json` - issue metadata
- `research-notes.md` - explicit pre-plan research summary
- `plan-path` - current implementation plan path
- `verify-report.md` - verification output

The source of truth for valid states and transitions is [../skills/issue-flow/references/state-schema.md](../skills/issue-flow/references/state-schema.md).

## Why Issue-Flow Depends On Superpowers

Issue-Flow intentionally does not duplicate brainstorming, planning, or execution methodology. Those capabilities already exist in `superpowers`, which remains the runtime dependency for:

- structured design refinement
- implementation planning
- execution workflows
- development branch finalization

This keeps Issue-Flow focused on orchestration instead of evolving into a second general-purpose agent framework.

## Platform Support

### Claude Code

Claude Code is the primary integration target because it supports:

- plugin manifests
- hooks
- skill chaining
- stronger session-level workflow enforcement

### Codex

Codex is supported through the plugin-bundle structure recommended by the official Codex plugin docs: a plugin manifest at `.codex-plugin/plugin.json` plus a repo marketplace at `.agents/plugins/marketplace.json`. The workflow still depends on a separately installed `superpowers` plugin, and some host-level behavior remains less strict than Claude Code.

## Repository Layout

```text
.
├── skills/           # Workflow skills and per-skill references
├── hooks/            # Hook declarations and guard scripts
├── agents/           # Supporting agent definitions
├── docs/             # User-facing and contributor-facing docs
├── tests/            # State machine and skill-loading tests
├── .agents/plugins/  # Repo-scoped Codex marketplace catalog
├── .claude-plugin/   # Claude Code plugin metadata
└── .codex-plugin/    # Codex plugin metadata
```

## Change Boundaries

When changing the project, keep these boundaries in mind:

- State-machine changes are high-risk and require matching updates to docs and guards
- Skill files should stay focused on phase-specific behavior
- `superpowers` dependencies should remain explicit, not copied into this repository casually
- Platform-specific behavior should be additive where possible, not separate forks of the workflow
