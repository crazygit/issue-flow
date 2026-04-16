#!/usr/bin/env bash
# run-hook.cmd — polyglot wrapper for hooks
# Claude Code auto-detects .sh files (2.1+), but this wrapper
# ensures compatibility across platforms and hook invocation styles.
#
# Usage: run-hook.cmd <hook-name>
#   run-hook.cmd session-start
#   run-hook.cmd state-transition-guard

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_NAME="${1:-}"

if [ -z "$HOOK_NAME" ]; then
  echo "Usage: run-hook.cmd <hook-name>" >&2
  exit 1
fi

HOOK_SCRIPT="${SCRIPT_DIR}/${HOOK_NAME}"

if [ ! -f "$HOOK_SCRIPT" ]; then
  echo "Hook not found: ${HOOK_SCRIPT}" >&2
  exit 1
fi

exec bash "$HOOK_SCRIPT"
