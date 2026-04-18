#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INSTALL_MODE="copy"
LOCAL_PLUGINS_DIR="${HOME}/.codex/local-plugins"
ISSUE_FLOW_DIR="${LOCAL_PLUGINS_DIR}/issue-flow"
MARKETPLACE_DIR="${HOME}/.agents/plugins"
MARKETPLACE_FILE="${MARKETPLACE_DIR}/marketplace.json"

usage() {
  cat <<'EOF'
Usage: bash scripts/install-codex.sh [--copy|--dev-link] [--help]

Prepare a personal Codex marketplace entry for issue-flow.

Options:
  --copy      Copy the current repository into ~/.codex/local-plugins/issue-flow (default)
  --dev-link  Symlink the current repository into ~/.codex/local-plugins/issue-flow
  --help      Show this help text
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --copy)
      INSTALL_MODE="copy"
      ;;
    --dev-link)
      INSTALL_MODE="dev-link"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command python3

prepare_directories() {
  mkdir -p "$LOCAL_PLUGINS_DIR" "$MARKETPLACE_DIR"
}

stage_issue_flow() {
  rm -rf "$ISSUE_FLOW_DIR"

  if [ "$INSTALL_MODE" = "dev-link" ]; then
    ln -s "$REPO_ROOT" "$ISSUE_FLOW_DIR"
    return
  fi

  cp -R "$REPO_ROOT" "$ISSUE_FLOW_DIR"
  rm -rf "$ISSUE_FLOW_DIR/.git"
}

write_marketplace() {
  MARKETPLACE_FILE="$MARKETPLACE_FILE" python3 <<'PY'
import json
import os
from pathlib import Path

marketplace_path = Path(os.environ["MARKETPLACE_FILE"])
marketplace_path.parent.mkdir(parents=True, exist_ok=True)

default_doc = {
    "name": "codex-local-plugins",
    "interface": {
        "displayName": "Local Plugins",
    },
    "plugins": [],
}

if marketplace_path.exists():
    with marketplace_path.open("r", encoding="utf-8") as fh:
        existing = json.load(fh)
else:
    existing = default_doc

if not isinstance(existing, dict):
    raise SystemExit(f"Expected JSON object in {marketplace_path}")

existing.setdefault("name", "codex-local-plugins")
existing.setdefault("interface", {})
existing["interface"].setdefault("displayName", "Local Plugins")

plugins = existing.get("plugins")
if not isinstance(plugins, list):
    plugins = []

managed = {
    "issue-flow": {
        "name": "issue-flow",
        "source": {
            "source": "local",
            "path": "./.codex/local-plugins/issue-flow",
        },
        "policy": {
            "installation": "AVAILABLE",
            "authentication": "ON_INSTALL",
        },
        "category": "Productivity",
    },
}

filtered = []
seen = set()
for plugin in plugins:
    if not isinstance(plugin, dict):
        filtered.append(plugin)
        continue
    name = plugin.get("name")
    if name in managed:
      if name not in seen:
        filtered.append(managed[name])
        seen.add(name)
      continue
    filtered.append(plugin)

for name in ("issue-flow",):
    if name not in seen:
        filtered.append(managed[name])

existing["plugins"] = filtered

with marketplace_path.open("w", encoding="utf-8") as fh:
    json.dump(existing, fh, indent=2)
    fh.write("\n")
PY
}

print_summary() {
  cat <<EOF
Codex local plugin install complete.

Installed paths:
  issue-flow:  $ISSUE_FLOW_DIR
  marketplace: $MARKETPLACE_FILE

Next steps:
  1. Restart Codex.
  2. Install or enable "Superpowers" from "OpenAI Curated" if it is not already enabled.
  3. Open the plugin directory, choose "Local Plugins", and install or enable "issue-flow".
EOF
}

prepare_directories
stage_issue_flow
write_marketplace
print_summary
