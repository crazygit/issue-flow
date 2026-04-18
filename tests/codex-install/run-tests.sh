#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INSTALL_SCRIPT="$REPO_ROOT/scripts/install-codex.sh"
PASS=0
FAIL=0

record_pass() {
  echo "PASS"
  PASS=$((PASS + 1))
}

record_fail() {
  echo "FAIL"
  FAIL=$((FAIL + 1))
}

echo "=== Codex Install Tests ==="

echo -n "  install script exists and is executable ... "
if [ -x "$INSTALL_SCRIPT" ]; then
  record_pass
else
  record_fail
fi

echo -n "  install script stages only issue-flow locally and updates marketplace config ... "
tmpdir=$(mktemp -d)
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

HOME="$tmpdir/home"
mkdir -p "$HOME"

if HOME="$HOME" "$INSTALL_SCRIPT" --copy >/dev/null 2>&1; then
  marketplace_file="$HOME/.agents/plugins/marketplace.json"
  issue_flow_plugin="$HOME/.codex/plugins/issue-flow/.codex-plugin/plugin.json"
  if [ -f "$marketplace_file" ] \
    && [ -f "$issue_flow_plugin" ] \
    && grep -q '"name": "codex-local-plugins"' "$marketplace_file" \
    && grep -q '"name": "issue-flow"' "$marketplace_file" \
    && grep -q '"path": "./.codex/plugins/issue-flow"' "$marketplace_file" \
    && ! grep -q '"name": "superpowers"' "$marketplace_file" \
    && [ ! -e "$HOME/.codex/plugins/superpowers" ]; then
    record_pass
  else
    record_fail
  fi
else
  record_fail
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
