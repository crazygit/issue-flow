# Codex Installation

Issue-Flow for Codex is packaged as a plugin bundle. The supported install path is the Codex plugin directory plus marketplace-backed local plugin entries, not direct `skills/` symlinks.

## Requirements

- Codex CLI
- `git`
- `gh` authenticated against GitHub
- [superpowers](https://github.com/obra/superpowers)
- A Codex plugin directory that reads plugin entries from `~/.agents/plugins/marketplace.json`

The repository includes [`.codex-plugin/plugin.json`](../.codex-plugin/plugin.json) for the plugin bundle and [`.agents/plugins/marketplace.json`](../.agents/plugins/marketplace.json) for a repo-scoped marketplace entry that exposes `issue-flow`.

## Install `superpowers`

Clone the `superpowers` plugin bundle into the Codex plugin directory:

```bash
git clone https://github.com/obra/superpowers ~/.codex/plugins/superpowers
```

Add or update `~/.agents/plugins/marketplace.json` so it exposes the local `superpowers` plugin:

```json
{
  "name": "local-plugins",
  "interface": {
    "displayName": "Local Plugins"
  },
  "plugins": [
    {
      "name": "superpowers",
      "source": {
        "source": "local",
        "path": "./.codex/plugins/superpowers"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
```

Restart Codex, open the plugin directory, choose `Local Plugins`, and install `superpowers`.

## Install `issue-flow`

This repository already contains a repo-scoped marketplace at [`.agents/plugins/marketplace.json`](../.agents/plugins/marketplace.json). It exposes `issue-flow` as a local plugin whose `source.path` points at the repository root.

Open this repository in Codex, restart if needed, choose `Issue-Flow Local Plugins` in the plugin directory, and install `issue-flow`.

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

Issue-Flow is still useful in Codex, but the Claude Code path remains the more fully integrated experience. The supported Codex setup is still plugin-based: install `superpowers` from the local plugin directory entry, and install `issue-flow` from this repository's marketplace entry.

## Updating

```bash
cd /path/to/issue-flow && git pull
```

## Uninstalling

```bash
# Disable or uninstall `issue-flow` from the Codex plugin directory UI,
# then remove its entry from ./.agents/plugins/marketplace.json if needed.
```
