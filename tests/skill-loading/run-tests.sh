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
echo "=== Content Constraint Tests ==="

echo -n "  issue-create: default label + assignee + Chinese ... "
if grep -F -q -- '--label "..."' "$SKILLS_DIR/issue-create/SKILL.md" \
  && grep -q -- '--assignee "@me"' "$SKILLS_DIR/issue-create/SKILL.md" \
  && grep -q 'Issue 标题和正文全部使用中文' "$SKILLS_DIR/issue-create/SKILL.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  issue-pr: default label + assignee + Chinese ... "
if grep -F -q -- '--label "..."' "$SKILLS_DIR/issue-pr/SKILL.md" \
  && grep -q -- '--assignee "@me"' "$SKILLS_DIR/issue-pr/SKILL.md" \
  && grep -q 'PR 标题和正文全部使用中文' "$SKILLS_DIR/issue-pr/SKILL.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  issue-commit: commit message stays English ... "
if grep -q 'commit message 使用英文' "$SKILLS_DIR/issue-commit/SKILL.md" \
  && grep -q '不要改成中文' "$SKILLS_DIR/issue-commit/SKILL.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
