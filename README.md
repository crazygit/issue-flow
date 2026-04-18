# Issue-Flow

Issue-Flow is an issue-driven development orchestrator for coding agents. It turns a feature request or GitHub issue into a structured delivery workflow: clarify the problem, write a plan, implement changes, verify the result, and package the work for review.

Issue-Flow is built to work with [superpowers](https://github.com/obra/superpowers). Superpowers provides the core development workflows, and Issue-Flow adds a lightweight state machine around them so agent sessions can stay aligned with a single issue from start to finish.

## Why Issue-Flow

- Keep agent work anchored to one issue instead of drifting across unrelated tasks
- Make progress explicit with a state machine instead of relying on hidden session context
- Support both guided approval checkpoints and uninterrupted auto-mode execution
- Reuse mature workflows from superpowers instead of reimplementing planning and execution logic
- Stay lightweight: no third-party runtime dependencies, no separate service to run

## How It Works

Issue-Flow tracks a development session through a small workflow state machine:

```text
brainstorm -> picked -> planned -> implementing -> verifying -> committing -> pring -> finished
```

Each phase maps to a focused skill:

- `issue-brainstorm` turns a rough request into a design direction
- `issue-pick` attaches the session to a specific issue and branch context
- `issue-plan` creates an implementation plan
- `issue-implement` carries out the plan
- `issue-verify` checks tests, linting, and review feedback
- `issue-commit` prepares clean commits
- `issue-pr` opens the pull request
- `issue-finish` wraps up branch and workspace state

The top-level `issue-flow` skill is the orchestrator. It reads the current session state and routes the agent to the next correct step.

## Quick Start

Issue-Flow currently supports Claude Code and Codex.

### Claude Code

```bash
/plugin install superpowers@claude-plugins-official
/plugin marketplace add crazygit/issue-flow
/plugin install issue-flow@issue-flow-marketplace
```

### Codex

Preferred path: install `Superpowers` from `OpenAI Curated`, then use the installer script to prepare a personal Codex marketplace entry for `issue-flow`.

First, enable `Superpowers` from the Codex plugin directory under `OpenAI Curated`.

```bash
bash scripts/install-codex.sh
```

The script will:

- copy this repository into `~/.codex/local-plugins/issue-flow`
- create or update `~/.agents/plugins/marketplace.json` with the local `issue-flow` entry

For local development against the current checkout, use:

```bash
bash scripts/install-codex.sh --dev-link
```

Then restart Codex if needed, open the plugin directory, choose `Local Plugins`, and install or enable `issue-flow`.
Then start a workflow:

```bash
/issue-flow Add email login support
/issue-flow --auto Add email login support
/issue-flow #42
/issue-flow
```

For platform-specific details, see [INSTALL.md](INSTALL.md).

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
└── .codex-plugin/          # Codex plugin metadata
```

## Documentation

- [INSTALL.md](INSTALL.md) - installation and update instructions
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
- Codex uses the plugin-bundle model and depends on `superpowers`, but `superpowers` is expected to come from `OpenAI Curated` while this repository's script only stages `issue-flow`

## Contributing

Contributions are welcome, especially around documentation, workflow polish, and platform compatibility. Before opening a pull request, read [CONTRIBUTING.md](CONTRIBUTING.md) for repository-specific rules around state transitions, skill definitions, and tests.

## License

[MIT](LICENSE)
