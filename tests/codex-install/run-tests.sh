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

echo -n "  install script does not embed or require python ... "
if ! grep -Eq 'python3?|<<'"'"'PY'"'"'' "$INSTALL_SCRIPT"; then
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
  config_file="$HOME/.codex/config.toml"
  if [ -f "$marketplace_file" ] \
    && [ -f "$issue_flow_plugin" ] \
    && [ -f "$config_file" ] \
    && grep -q '"name": "codex-personal-plugins"' "$marketplace_file" \
    && grep -q '"displayName": "Personal Plugins"' "$marketplace_file" \
    && grep -q '"name": "issue-flow"' "$marketplace_file" \
    && grep -q '"path": "./.codex/plugins/issue-flow"' "$marketplace_file" \
    && grep -q '^\[plugins\."superpowers@openai-curated"\]$' "$config_file" \
    && grep -q '^\[plugins\."issue-flow@codex-personal-plugins"\]$' "$config_file" \
    && grep -q '^enabled = true$' "$config_file" \
    && ! grep -q '"name": "superpowers"' "$marketplace_file" \
    && [ ! -e "$HOME/.codex/plugins/superpowers" ]; then
    record_pass
  else
    record_fail
  fi
else
  record_fail
fi

echo -n "  install script enables codex_hooks in user config without losing other settings ... "
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
HOME="$tmpdir/home"
mkdir -p "$HOME/.codex"
cat >"$HOME/.codex/config.toml" <<'EOF'
model = "gpt-5"

[features]
other_feature = true
codex_hooks = false

[profiles.fast]
model = "gpt-5-mini"
EOF

if HOME="$HOME" "$INSTALL_SCRIPT" --copy >/dev/null 2>&1; then
  config_file="$HOME/.codex/config.toml"
  if [ -f "$config_file" ] \
    && grep -q '^model = "gpt-5"$' "$config_file" \
    && grep -q '^\[features\]$' "$config_file" \
    && grep -q '^other_feature = true$' "$config_file" \
    && grep -q '^codex_hooks = true$' "$config_file" \
    && ! grep -q '^codex_hooks = false$' "$config_file" \
    && grep -q '^\[plugins\."superpowers@openai-curated"\]$' "$config_file" \
    && grep -q '^\[plugins\."issue-flow@codex-personal-plugins"\]$' "$config_file" \
    && grep -q '^\[profiles.fast\]$' "$config_file"; then
    record_pass
  else
    record_fail
  fi
else
  record_fail
fi

echo -n "  install script merges managed SessionStart hook into user hooks config ... "
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
HOME="$tmpdir/home"
mkdir -p "$HOME/.codex"
cat >"$HOME/.codex/hooks.json" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "echo existing-session-hook"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo stop-hook"
          }
        ]
      }
    ]
  }
}
EOF

if HOME="$HOME" "$INSTALL_SCRIPT" --copy >/dev/null 2>&1; then
  hooks_file="$HOME/.codex/hooks.json"
  issue_flow_hook_count=$(grep -c 'hooks/run-hook.cmd\\" session-start' "$hooks_file" || true)
  if [ -f "$hooks_file" ] \
    && grep -Eq '"command"[[:space:]]*:[[:space:]]*"echo existing-session-hook"' "$hooks_file" \
    && grep -Eq '"command"[[:space:]]*:[[:space:]]*"echo stop-hook"' "$hooks_file" \
    && grep -Eq '"matcher"[[:space:]]*:[[:space:]]*"startup\|resume"' "$hooks_file" \
    && grep -q "$HOME/.codex/plugins/issue-flow/hooks/run-hook.cmd" "$hooks_file" \
    && [ "$issue_flow_hook_count" -eq 1 ]; then
    record_pass
  else
    record_fail
  fi
else
  record_fail
fi

echo -n "  install script keeps managed user hook idempotent across repeated installs ... "
if HOME="$HOME" "$INSTALL_SCRIPT" --copy >/dev/null 2>&1 \
  && HOME="$HOME" "$INSTALL_SCRIPT" --copy >/dev/null 2>&1; then
  hooks_file="$HOME/.codex/hooks.json"
  config_file="$HOME/.codex/config.toml"
  issue_flow_hook_count=$(grep -c 'hooks/run-hook.cmd\\" session-start' "$hooks_file" || true)
  codex_hooks_count=$(grep -c '^codex_hooks = true$' "$config_file" || true)
  superpowers_plugin_count=$(grep -c '^\[plugins\."superpowers@openai-curated"\]$' "$config_file" || true)
  issue_flow_plugin_count=$(grep -c '^\[plugins\."issue-flow@codex-personal-plugins"\]$' "$config_file" || true)
  if [ "$issue_flow_hook_count" -eq 1 ] \
    && [ "$codex_hooks_count" -eq 1 ] \
    && [ "$superpowers_plugin_count" -eq 1 ] \
    && [ "$issue_flow_plugin_count" -eq 1 ]; then
    record_pass
  else
    record_fail
  fi
else
  record_fail
fi

echo -n "  install script writes the marketplace path under .codex/plugins, not .codex/local-plugins ... "
if HOME="$HOME" "$INSTALL_SCRIPT" --copy >/dev/null 2>&1; then
  marketplace_file="$HOME/.agents/plugins/marketplace.json"
  if [ -f "$marketplace_file" ] \
    && grep -q '"path": "./.codex/plugins/issue-flow"' "$marketplace_file" \
    && ! grep -q '"path": "./.codex/local-plugins/issue-flow"' "$marketplace_file"; then
    record_pass
  else
    record_fail
  fi
else
  record_fail
fi

echo -n "  install script preserves other marketplace plugins while refreshing issue-flow ... "
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
HOME="$tmpdir/home"
mkdir -p "$HOME/.agents/plugins"
cat >"$HOME/.agents/plugins/marketplace.json" <<'EOF'
{
  "plugins": [
    {
      "name": "other-plugin",
      "source": {
        "source": "local",
        "path": "./.codex/plugins/other-plugin"
      }
    },
    {
      "name": "issue-flow",
      "source": {
        "source": "local",
        "path": "./.codex/local-plugins/issue-flow"
      }
    }
  ]
}
EOF

if HOME="$HOME" "$INSTALL_SCRIPT" --copy >/dev/null 2>&1; then
  marketplace_file="$HOME/.agents/plugins/marketplace.json"
  issue_flow_count=$(grep -c '"name": "issue-flow"' "$marketplace_file" || true)
  if [ -f "$marketplace_file" ] \
    && grep -Eq '"name"[[:space:]]*:[[:space:]]*"other-plugin"' "$marketplace_file" \
    && grep -Eq '"path"[[:space:]]*:[[:space:]]*"\./\.codex/plugins/issue-flow"' "$marketplace_file" \
    && ! grep -Eq '"path"[[:space:]]*:[[:space:]]*"\./\.codex/local-plugins/issue-flow"' "$marketplace_file" \
    && [ "$issue_flow_count" -eq 1 ]; then
    record_pass
  else
    record_fail
  fi
else
  record_fail
fi

echo -n "  install script preserves existing marketplace id and enables issue-flow with that id ... "
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
HOME="$tmpdir/home"
mkdir -p "$HOME/.agents/plugins" "$HOME/.codex"
cat >"$HOME/.agents/plugins/marketplace.json" <<'EOF'
{
  "name": "my-local-market",
  "interface": {
    "displayName": "My Local Market"
  },
  "plugins": [
    {
      "name": "issue-flow",
      "source": {
        "source": "local",
        "path": "./.codex/plugins/issue-flow"
      }
    }
  ]
}
EOF

if HOME="$HOME" "$INSTALL_SCRIPT" --copy >/dev/null 2>&1; then
  marketplace_file="$HOME/.agents/plugins/marketplace.json"
  config_file="$HOME/.codex/config.toml"
  if [ -f "$marketplace_file" ] \
    && [ -f "$config_file" ] \
    && grep -q '"name": "my-local-market"' "$marketplace_file" \
    && grep -q '"displayName": "My Local Market"' "$marketplace_file" \
    && grep -q '^\[plugins\."issue-flow@my-local-market"\]$' "$config_file" \
    && ! grep -q '^\[plugins\."issue-flow@codex-personal-plugins"\]$' "$config_file"; then
    record_pass
  else
    record_fail
  fi
else
  record_fail
fi

echo -n "  install script does not remove other plugins whose metadata mentions issue-flow ... "
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
HOME="$tmpdir/home"
mkdir -p "$HOME/.agents/plugins"
cat >"$HOME/.agents/plugins/marketplace.json" <<'EOF'
{
  "plugins": [
    {
      "name": "helper-plugin",
      "metadata": {
        "name": "issue-flow"
      },
      "source": {
        "source": "local",
        "path": "./.codex/plugins/helper-plugin"
      }
    }
  ]
}
EOF

if HOME="$HOME" "$INSTALL_SCRIPT" --copy >/dev/null 2>&1; then
  marketplace_file="$HOME/.agents/plugins/marketplace.json"
  if [ -f "$marketplace_file" ] \
    && grep -Eq '"name"[[:space:]]*:[[:space:]]*"helper-plugin"' "$marketplace_file" \
    && grep -Eq '"metadata"[[:space:]]*:[[:space:]]*\{' "$marketplace_file" \
    && grep -Eq '"name"[[:space:]]*:[[:space:]]*"issue-flow"' "$marketplace_file"; then
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
