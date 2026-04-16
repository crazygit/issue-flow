# Contributing to Issue-Flow

Thank you for your interest in contributing! This file contains guidelines for contributors.

## AI Agent Warnings

- Search existing issues and PRs before creating new ones
- Verify that the problem is real and not a misunderstanding
- Read this entire file before making any changes

## What Will Not Be Accepted

- Changes that break existing state machine transitions
- New superpowers dependencies without justification
- Platform-specific code for platforms other than Claude Code and Codex
- Third-party dependencies (issue-flow must remain lightweight)
- Speculative fixes without reproduction steps
- Bundled changes (one PR per concern)
- Fabricated test results or benchmarks

## Skill Change Requirements

- All skill changes must preserve the existing state machine contract (see `skills/issue-flow/references/state-schema.md`)
- Skills must keep their YAML frontmatter valid
- `allowed-tools` must be explicitly listed (no wildcards)
- Changes to state transitions must update `references/state-machine.md` and `hooks/state-transition-guard.sh`
- Test changes with the test suite in `tests/`

## Code Style

- SKILL.md files: Chinese instructions, English technical terms
- YAML frontmatter: `name`, `description` required; `allowed-tools` must be explicit
- References files: markdown format, keep concise
- Commit messages: English, Conventional Commits format

## Pull Request Process

1. Create a feature branch from main
2. Make changes following the guidelines above
3. Run tests: `bash tests/state-machine/run-tests.sh && bash tests/skill-loading/run-tests.sh`
4. Update documentation if behavior changes
5. Submit PR with clear description of changes
