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

### 1. Run the installer

Before running the installer, install or enable `Superpowers` from the Codex plugin directory under `OpenAI Curated`.

```bash
bash scripts/install-codex.sh
```

The script will:

- copy this repository into `~/.codex/local-plugins/issue-flow`
- create or update `~/.agents/plugins/marketplace.json`
- register `issue-flow` under the `Local Plugins` marketplace

If you are developing Issue-Flow locally and want Codex to use the live checkout instead of a copied snapshot, run:

```bash
bash scripts/install-codex.sh --dev-link
```

### 2. Enable the plugins in Codex

Restart Codex, confirm `Superpowers` is enabled under `OpenAI Curated`, then choose `Local Plugins` and install or enable `issue-flow`.

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
bash scripts/install-codex.sh
```

## Uninstalling

### Claude Code

```bash
/plugin uninstall issue-flow@issue-flow-marketplace
/plugin marketplace remove issue-flow-marketplace
```

### Codex

```bash
# Disable or uninstall `issue-flow` and `superpowers` from the Codex plugin directory UI.
# If you want to remove the local copies too, delete:
#   ~/.codex/local-plugins/issue-flow
# and remove its entry from ~/.agents/plugins/marketplace.json.
# `Superpowers` is managed from the `OpenAI Curated` marketplace.
```
