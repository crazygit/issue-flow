# Distribution

Issue-Flow includes metadata for both supported host surfaces:

- Claude Code: [../.claude-plugin/plugin.json](../.claude-plugin/plugin.json)
- Codex: [../.codex-plugin/plugin.json](../.codex-plugin/plugin.json)
- Codex repo marketplace: [../.agents/plugins/marketplace.json](../.agents/plugins/marketplace.json)

## Packaging Status

Issue-Flow is distributed using the standard Claude Code marketplace model and the Codex local plugin bundle model recommended by the official Codex plugin docs.

Today, users still need:

- the `superpowers` runtime dependency
- a host environment that can install or discover plugins

## Why Installation Is Still Two-Part

Issue-Flow is intentionally an orchestrator, not a bundled workflow platform. Keeping `superpowers` separate has a few advantages:

- workflow logic can evolve independently from orchestration logic
- Issue-Flow stays small and easier to reason about
- users who already rely on `superpowers` do not get a duplicated skill tree

## What The Plugin Metadata Solves

- Claude Code can install this repository through `.claude-plugin/marketplace.json`
- Codex can identify the repository root as an installable plugin package through `.codex-plugin/plugin.json`
- Codex can expose the plugin in a repo-scoped marketplace through `.agents/plugins/marketplace.json`
- Installation instructions can point to stable manifest and marketplace locations

## What It Does Not Solve Yet

- Removal of the `superpowers` dependency
- Perfectly identical behavior across Claude Code and Codex

## Recommendation

Treat Issue-Flow as a focused orchestration plugin with an explicit runtime dependency. For Codex, prefer the documented plugin-bundle flow: keep `.codex-plugin/plugin.json` at the plugin root, expose the repo through `.agents/plugins/marketplace.json`, and install from the plugin directory instead of wiring `skills/` into `~/.agents/skills/` manually.
