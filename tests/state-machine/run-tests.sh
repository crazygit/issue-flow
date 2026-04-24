#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GUARD_SCRIPT="$SCRIPT_DIR/../../hooks/state-transition-guard"
PASS=0
FAIL=0

run_test() {
  local description="$1"
  local current_state="$2"
  local skill="$3"
  local expected_exit="$4"
  local state_dir="${5:-.issue-flow}"

  echo -n "  $description ... "

  local tmpdir
  tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/$state_dir"
  echo "$current_state" > "$tmpdir/$state_dir/state"

  local input
  input=$(printf '{"tool_input":{"name":"%s"}}' "$skill")

  cd "$tmpdir"
  local exit_code
  exit_code=$(echo "$input" | bash "$GUARD_SCRIPT" >/dev/null 2>&1; echo $?)
  cd - >/dev/null

  rm -rf "$tmpdir"

  if [ "$exit_code" -eq "$expected_exit" ]; then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL (expected exit $expected_exit, got $exit_code)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== State Transition Guard Tests ==="
echo ""
echo "Legal transitions (should exit 0):"
run_test "none → issue-brainstorm" "none" "issue-brainstorm" 0
run_test "none → issue-pick (mode B)" "none" "issue-pick" 0
run_test "brainstorm → issue-create" "brainstorm" "issue-create" 0
run_test "brainstorm → issue-pick" "brainstorm" "issue-pick" 0
run_test "picked → issue-research" "picked" "issue-research" 0
run_test "researching → issue-plan" "researching" "issue-plan" 0
run_test "planned → issue-implement" "planned" "issue-implement" 0
run_test "implementing → issue-verify" "implementing" "issue-verify" 0
run_test "committing → issue-commit" "committing" "issue-commit" 0
run_test "pring → issue-pr" "pring" "issue-pr" 0
run_test "reviewing → issue-verify" "reviewing" "issue-verify" 0
run_test "reviewing → issue-implement" "reviewing" "issue-implement" 0
run_test "finished → issue-finish" "finished" "issue-finish" 0

echo ""
echo "Illegal transitions (should exit 2):"
run_test "none → issue-plan" "none" "issue-plan" 2
run_test "none → issue-implement" "none" "issue-implement" 2
run_test "picked → issue-plan" "picked" "issue-plan" 2
run_test "picked → issue-implement" "picked" "issue-implement" 2
run_test "picked → issue-brainstorm" "picked" "issue-brainstorm" 2
run_test "implementing → issue-commit" "implementing" "issue-commit" 2
run_test "planned → issue-verify" "planned" "issue-verify" 2
run_test "verifying → issue-implement" "verifying" "issue-implement" 2
run_test "verifying → issue-commit" "verifying" "issue-commit" 2
run_test "committing → issue-verify" "committing" "issue-verify" 2
run_test "pring → issue-finish" "pring" "issue-finish" 2
run_test "researching → issue-verify" "researching" "issue-verify" 2

echo ""
echo "Non-issue skills (should exit 0):"
run_test "other-skill passes through" "picked" "other-skill" 0

echo ""
echo "Bugfix transitions (should exit 0):"
run_test "none → bugfix-pick" "none" "bugfix-pick" 0 ".bugfix-flow"
run_test "picked → bugfix-implement" "picked" "bugfix-implement" 0 ".bugfix-flow"
run_test "implementing → bugfix-verify" "implementing" "bugfix-verify" 0 ".bugfix-flow"
run_test "ready → bugfix-implement" "ready" "bugfix-implement" 0 ".bugfix-flow"
run_test "finished → bugfix-finish" "finished" "bugfix-finish" 0 ".bugfix-flow"

echo ""
echo "Illegal bugfix transitions (should exit 2):"
run_test "none → bugfix-verify" "none" "bugfix-verify" 2 ".bugfix-flow"
run_test "picked → bugfix-verify" "picked" "bugfix-verify" 2 ".bugfix-flow"
run_test "implementing → bugfix-finish" "implementing" "bugfix-finish" 2 ".bugfix-flow"
run_test "ready → bugfix-finish" "ready" "bugfix-finish" 2 ".bugfix-flow"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
