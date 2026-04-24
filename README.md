# Issue-Flow

Issue-Flow is a workflow plugin for coding agents. It ships an issue-driven delivery orchestrator plus a lightweight bugfix repair flow so agents can either drive a feature from issue creation to review or take a bug from reproduction to verified fix.

Issue-Flow is built to work with [superpowers](https://github.com/obra/superpowers). Superpowers provides the core development workflows, and Issue-Flow adds a lightweight state machine around them so agent sessions can stay aligned with a single issue from start to finish.

## Why Issue-Flow

- Keep agent work anchored to one issue instead of drifting across unrelated tasks
- Make progress explicit with a state machine instead of relying on hidden session context
- Support both guided approval checkpoints and uninterrupted auto-mode execution
- Reuse mature workflows from superpowers instead of reimplementing planning and execution logic
- Stay lightweight: no third-party runtime dependencies, no separate service to run

## How It Works

Issue-Flow ships two workflow state machines:

### `issue-flow`

The issue-driven workflow has two parts: a pre-phase that produces a GitHub Issue number, and a persistent state machine that tracks delivery from that point on.

**Pre-phase** (session-scoped, not persistable):

- `issue-brainstorm` turns a rough request into a design direction
- `issue-create` turns the design spec into a GitHub Issue number

**Persistent state machine** (`.issue-flow/` created by `issue-pick`):

```text
picked -> researching -> planned -> implementing -> committing -> pring -> reviewing -> finished
```

Each persistent state maps to a focused skill:
- `issue-pick` attaches the session to a specific issue and branch context
- `issue-research` captures codebase findings before planning
- `issue-plan` creates an implementation plan
- `issue-implement` carries out the plan
- `issue-verify` checks tests, linting, and review feedback
- `issue-commit` prepares clean commits
- `issue-pr` opens the pull request and hands off into review
- `issue-finish` wraps up branch and workspace state

The top-level `issue-flow` skill is the orchestrator. It reads the current session state and routes the agent to the next correct step.

### `bugfix-flow`

The bugfix workflow is intentionally narrower. It is for cases where you already know there is a bug and want the agent to focus on reproducing, fixing, and verifying it before any commit or PR step.

**Persistent state machine** (`.bugfix-flow/` created by `bugfix-pick`):

```text
picked -> implementing -> ready -> finished
```

Each persistent state maps to a focused skill:

- `bugfix-pick` creates worktree/context from either a bug description or an existing issue
- `bugfix-implement` applies the minimal code changes needed for the fix
- `bugfix-verify` runs focused verification and loops back on failure
- `bugfix-finish` cleans up the bugfix session after the user decides to stop

The top-level `bugfix-flow` skill is the orchestrator. It routes the session until verification passes, then pauses in `ready` so a human can decide whether to commit or open a PR.

## Installation

Issue-Flow currently supports Claude Code and Codex.

### Requirements

Issue-Flow depends on:

- `git`
- `gh` for GitHub issue and pull request operations
- [superpowers](https://github.com/obra/superpowers) as a runtime dependency

### Claude Code

Install `superpowers` first:

```bash
/plugin install superpowers@claude-plugins-official
```

Then add the Issue-Flow marketplace and install the plugin:

```bash
/plugin marketplace add crazygit/issue-flow
/plugin install issue-flow@issue-flow-marketplace
```

Restart Claude Code if the new plugin does not appear immediately.

### Codex

Codex installation exposes `issue-flow` through either a personal marketplace or the repo marketplace, and the personal installer also enables the required plugins in user-level Codex config.

The Codex bundle entry point is [`.codex-plugin/plugin.json`](./.codex-plugin/plugin.json).

Recommended: personal marketplace

Run the installer from this repository:

```bash
bash scripts/install-codex.sh
```

The script will:

- stage this repository at `~/.codex/plugins/issue-flow`
- create or update `~/.agents/plugins/marketplace.json`
- preserve other marketplace entries while refreshing the managed `issue-flow` entry in your user-level marketplace config
- create or update `~/.codex/config.toml`
- preserve existing Codex plugin settings while enabling `superpowers@openai-curated`
- preserve existing Codex plugin settings while enabling `issue-flow@<your personal marketplace id>`

In other words, the installer does modify user-level Codex files, but it only merges the plugin entries it manages rather than overwriting the whole files.

If you are developing from the current checkout and want Codex to use the live repo instead of a copied snapshot, run:

```bash
bash scripts/install-codex.sh --dev-link
```

Then restart Codex and open the plugin directory to confirm that both `Superpowers` and `issue-flow` are enabled.

Alternative: repo marketplace only

If you only want to use `issue-flow` inside this repository, you can skip the installer. This repo already includes [`.agents/plugins/marketplace.json`](./.agents/plugins/marketplace.json), so open this repository in Codex, trust the project, enable `Superpowers` from `OpenAI Curated` if needed, then choose `Issue Flow Plugins` and install or enable `issue-flow`.

Before starting a workflow, confirm both plugins are enabled:

- `Superpowers` under `OpenAI Curated`
- `issue-flow` under `Personal Plugins` or `Issue Flow Plugins`

### Start A Workflow

After installation, start or resume a workflow:

```bash
/issue-flow Add email login support
/issue-flow --auto Add email login support
/issue-flow #42
/issue-flow
/bugfix-flow Fix panic when config file is empty
/bugfix-flow --auto Fix panic when config file is empty
/bugfix-flow #42
/bugfix-flow
```

In Codex environments that expose commands without the leading slash, `issue-flow` and `bugfix-flow` also work.

Use `issue-flow` when the work should stay anchored to a GitHub issue through planning, implementation, review, and PR handling.

Use `bugfix-flow` when you want a lighter repair loop that stops after verification succeeds and does not force brainstorming, issue creation, commit, or PR creation.

### Updating

Claude Code:

```bash
/plugin marketplace update issue-flow-marketplace
/plugin update issue-flow@issue-flow-marketplace
```

Codex:

```bash
bash scripts/install-codex.sh
```

### Uninstalling

Claude Code:

```bash
/plugin uninstall issue-flow@issue-flow-marketplace
/plugin marketplace remove issue-flow-marketplace
```

Codex:

- Disable or uninstall `issue-flow` and `Superpowers` from the plugin UI
- Remove `~/.codex/plugins/issue-flow` if you also want to delete the local staged copy
- Remove the `issue-flow` entry from `~/.agents/plugins/marketplace.json` if you no longer want it listed in `Personal Plugins`
- Remove the managed `issue-flow` plugin entry from `~/.codex/config.toml` if you no longer want it auto-enabled

## Who This Is For

Issue-Flow is a good fit if you want:

- A reproducible agent workflow tied to issues and pull requests
- Stronger control over long-running implementation sessions
- A small orchestration layer on top of superpowers
- A plugin that can run in both Claude Code and Codex-oriented setups

It is probably not a fit if you want a standalone coding methodology without the `superpowers` dependency.

## Project Structure

```text
issue-flow/
├── skills/                 # Workflow skills and references
├── hooks/                  # Session start and state-transition enforcement
├── agents/                 # Supporting review agents
├── docs/                   # Architecture, installation, testing, packaging
├── tests/                  # State-machine and skill-loading checks
├── .agents/plugins/        # Repo-scoped Codex marketplace catalog
├── .claude-plugin/         # Claude Code plugin metadata
├── .codex/                 # Repo-scoped Codex config and hooks
└── .codex-plugin/          # Codex plugin metadata
```

## Documentation

- [docs/README.md](docs/README.md) - documentation index
- [docs/architecture.md](docs/architecture.md) - architecture and design boundaries
- [docs/distribution.md](docs/distribution.md) - packaging model and runtime dependency notes
- [docs/testing.md](docs/testing.md) - test suites and verification commands
- [CONTRIBUTING.md](CONTRIBUTING.md) - contributor workflow and repository rules

## Current Status

Issue-Flow is usable today, but it is still opinionated and intentionally narrow:

- `superpowers` is a required runtime dependency
- Claude Code installs through the standard marketplace flow, even though this repository currently publishes only one plugin
- Claude Code has the strongest native integration because it supports hooks and skill chaining
- Codex uses the plugin-bundle model and depends on `superpowers`; the personal installer stages `issue-flow`, merges marketplace and hook config, and auto-enables both plugins in user-level Codex config

## Contributing

Contributions are welcome, especially around documentation, workflow polish, and platform compatibility. Before opening a pull request, read [CONTRIBUTING.md](CONTRIBUTING.md) for repository-specific rules around state transitions, skill definitions, and tests.

## License

[MIT](LICENSE)
