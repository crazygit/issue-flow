# Contributing to Issue-Flow

Thanks for contributing. Issue-Flow is a small project with a strict workflow contract, so the fastest way to get a change accepted is to keep the scope tight and follow the repository rules below.

## Before You Start

- Search existing issues and pull requests before opening a new one
- Verify the problem is real and reproducible
- Read [README.md](README.md), [docs/architecture.md](docs/architecture.md), and [docs/testing.md](docs/testing.md) before changing workflow behavior
- Keep one pull request focused on one concern

## What We Accept

- Documentation improvements that make the project easier to install, use, or contribute to
- Bug fixes with clear reproduction steps
- Workflow improvements that preserve the existing state-machine contract
- Compatibility work for supported platforms: Claude Code and Codex

## What We Do Not Accept

- Changes that break existing state transitions
- New third-party dependencies
- Speculative fixes without a clear problem statement
- Platform-specific work for unsupported agent environments
- Bundled changes that mix unrelated features, refactors, and docs
- Fabricated test results, screenshots, or benchmarks

## Repository Rules

### Skill Changes

- Keep `SKILL.md` frontmatter valid
- `allowed-tools` must be explicit and must not use wildcards
- Preserve the contract defined in `skills/issue-flow/references/state-schema.md`
- If state transitions change, also update the matching documentation and guard logic

### Writing Style

- `SKILL.md` instructions should stay in Chinese with English technical terms where appropriate
- Reference documents should stay concise and markdown-based
- Commit messages should use English and follow Conventional Commits

### Dependencies

- Issue-Flow must remain lightweight
- `superpowers` is an explicit runtime dependency, not something to duplicate into this repository without strong justification

## Development Workflow

1. Create a branch from `main`
2. Make a focused change
3. Run the relevant tests
4. Update docs when behavior changes
5. Open a pull request with a clear summary and verification notes

## Running Tests

Run the repository test suite before submitting a pull request:

```bash
bash tests/state-machine/run-tests.sh
bash tests/skill-loading/run-tests.sh
```

See [docs/testing.md](docs/testing.md) for what each suite covers.

## Pull Request Checklist

- Explain the problem and the approach clearly
- List the exact verification commands you ran
- Call out any behavior changes, especially around workflow state or supported platforms
- Update user-facing and contributor-facing docs when needed

## Agent Notes

Repository-specific agent guidance also exists in [AGENTS.md](AGENTS.md). That file is primarily for runtime and tool behavior. This document is the source of truth for human contributors and pull requests.
