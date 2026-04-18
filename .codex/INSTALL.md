# Codex Installation

Issue-Flow for Codex is packaged as a plugin bundle. The supported install path is the Codex plugin directory plus marketplace-backed local plugin entries, not direct `skills/` symlinks.

## Requirements

- Codex CLI
- `gh` authenticated against GitHub
- [superpowers](https://github.com/obra/superpowers)
- A Codex plugin directory that reads plugin entries from `~/.agents/plugins/marketplace.json`
- `python3` for marketplace JSON updates in the installer script

The repository includes [`.codex-plugin/plugin.json`](../.codex-plugin/plugin.json) for the plugin bundle and [`.agents/plugins/marketplace.json`](../.agents/plugins/marketplace.json) for a repo-scoped marketplace entry that exposes `issue-flow`.

## Run the installer

Before running the installer, install or enable `Superpowers` from the Codex plugin directory under `OpenAI Curated`.

Run the installer from the repository root:

```bash
bash scripts/install-codex.sh
```

This prepares a personal Codex marketplace by:

- copying this repository to `~/.codex/local-plugins/issue-flow`
- creating or updating `~/.agents/plugins/marketplace.json`
- registering the local `issue-flow` entry under `Local Plugins`

If you want Codex to use your current working tree directly while developing the plugin, use:

```bash
bash scripts/install-codex.sh --dev-link
```

## Enable the plugin

Restart Codex if needed, confirm `Superpowers` is enabled under `OpenAI Curated`, then choose `Local Plugins` and install or enable `issue-flow`.

## Verify The Install

Confirm both `superpowers` and `issue-flow` are enabled in the plugin directory. Then start a workflow:

```bash
issue-flow Add user authentication
issue-flow --auto Add user authentication
issue-flow #42
issue-flow
```

## Codex Compatibility Notes

Codex support is intentionally narrower than Claude Code support:

| Capability | Status in Codex | Practical impact |
|------------|-----------------|------------------|
| Skill routing | Supported through installed skills | Core workflow works |
| Hooks | Not available | State enforcement relies on skill instructions |
| Agent tool | Limited compared with Claude Code | Some execution paths fall back to simpler behavior |
| Browser-driven flows | Not available | Web-assisted paths are skipped |

Issue-Flow is still useful in Codex, but the Claude Code path remains the more fully integrated experience. The supported Codex setup is still plugin-based; `Superpowers` comes from `OpenAI Curated`, and the installer simply stages local `issue-flow` files plus the marketplace entry.

## Updating

```bash
cd /path/to/issue-flow && git pull
```

## Uninstalling

```bash
# Disable or uninstall `issue-flow` from the Codex plugin directory UI.
# Then remove ~/.codex/local-plugins/issue-flow plus its entry from ~/.agents/plugins/marketplace.json if needed.
# `Superpowers` is managed from `OpenAI Curated`.
```
