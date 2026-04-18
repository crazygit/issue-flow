# Installation

This guide covers the currently supported installation paths for Issue-Flow.

## Requirements

Issue-Flow depends on:

- `git`
- `gh` (GitHub CLI) for issue and pull request operations
- [superpowers](https://github.com/obra/superpowers) as a runtime dependency

Issue-Flow ships plugin metadata for supported platforms. Claude Code uses the standard marketplace flow. Codex uses the local plugin bundle plus marketplace flow recommended by the official Codex plugin docs.

## Claude Code

Install `superpowers` first:

```bash
/plugin install superpowers@claude-plugins-official
```

Then add the Issue-Flow marketplace and install the plugin:

```bash
/plugin marketplace add crazygit/issue-flow
/plugin install issue-flow@issue-flow-marketplace
```

Restart Claude Code after installation.

## Codex

Issue-Flow is packaged as a local Codex plugin bundle rooted at this repository. Codex discovers it through a marketplace file instead of direct `skills/` symlinks.

### 1. Install `superpowers`

```bash
git clone https://github.com/obra/superpowers ~/.codex/plugins/superpowers
```

Add or update `~/.agents/plugins/marketplace.json` so it includes:

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

### 2. Install `issue-flow`

This repository already contains a repo-scoped marketplace at [`.agents/plugins/marketplace.json`](.agents/plugins/marketplace.json). It exposes `issue-flow` as a local plugin whose `source.path` points at the repository root.

Open this repository in Codex, restart if needed, choose `Issue-Flow Local Plugins` in the plugin directory, and install `issue-flow`.

### 3. Confirm both plugins are enabled

The plugin directory should show both `superpowers` and `issue-flow` as enabled before you start a workflow.

## Verify The Install

After installation, start or resume a workflow:

```bash
/issue-flow
```

or in Codex:

```bash
issue-flow
```

## Updating

```bash
/plugin marketplace update issue-flow-marketplace
/plugin update issue-flow@issue-flow-marketplace
```

For Codex installations:

```bash
cd /path/to/issue-flow && git pull
```

## Uninstalling

### Claude Code

```bash
/plugin uninstall issue-flow@issue-flow-marketplace
/plugin marketplace remove issue-flow-marketplace
```

### Codex

```bash
# Disable or uninstall `issue-flow` from the Codex plugin directory UI,
# then remove its entry from ./.agents/plugins/marketplace.json if you no longer want this repo to expose it.
```
