#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
PASS=0
FAIL=0

echo "=== Skill Loading Tests ==="

for skill_dir in "$SKILLS_DIR"/issue-*/; do
  skill_name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"

  if [ ! -f "$skill_file" ]; then
    echo "  FAIL: $skill_name/SKILL.md not found"
    FAIL=$((FAIL + 1))
    continue
  fi

  # Check YAML frontmatter exists (starts with ---)
  echo -n "  $skill_name: frontmatter ... "
  if head -1 "$skill_file" | grep -q '^---$'; then
    echo -n "ok, "
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    FAIL=$((FAIL + 1))
    continue
  fi

  # Check name field
  echo -n "name ... "
  if grep -q '^name:' "$skill_file"; then
    echo -n "ok, "
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    FAIL=$((FAIL + 1))
    continue
  fi

  # Check description field
  echo -n "description ... "
  if grep -q '^description:' "$skill_file"; then
    echo -n "ok, "
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    FAIL=$((FAIL + 1))
    continue
  fi

  # Check frontmatter ends (second ---)
  echo -n "format ... "
  if awk 'NR==1{next} /^---$/{found=1; exit} END{exit !found}' "$skill_file"; then
    PASS=$((PASS + 1))
    echo "ok"
  else
    echo "FAIL"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
