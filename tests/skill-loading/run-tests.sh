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

for skill_dir in "$SKILLS_DIR"/bugfix-*/; do
  skill_name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"

  if [ ! -f "$skill_file" ]; then
    echo "  FAIL: $skill_name/SKILL.md not found"
    FAIL=$((FAIL + 1))
    continue
  fi

  echo -n "  $skill_name: frontmatter ... "
  if head -1 "$skill_file" | grep -q '^---$'; then
    echo -n "ok, "
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    FAIL=$((FAIL + 1))
    continue
  fi

  echo -n "name ... "
  if grep -q '^name:' "$skill_file"; then
    echo -n "ok, "
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    FAIL=$((FAIL + 1))
    continue
  fi

  echo -n "description ... "
  if grep -q '^description:' "$skill_file"; then
    echo -n "ok, "
    PASS=$((PASS + 1))
  else
    echo "FAIL"
    FAIL=$((FAIL + 1))
    continue
  fi

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

echo -n "  codex plugin manifest exposes bundled skills ... "
if [ -f "$REPO_ROOT/.codex-plugin/plugin.json" ] \
  && grep -q '"skills": "./skills/"' "$REPO_ROOT/.codex-plugin/plugin.json"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  codex repo marketplace exposes issue-flow plugin ... "
if [ -f "$REPO_ROOT/.agents/plugins/marketplace.json" ] \
  && grep -q '"name": "issue-flow"' "$REPO_ROOT/.agents/plugins/marketplace.json" \
  && grep -q '"path": "./"' "$REPO_ROOT/.agents/plugins/marketplace.json"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  issue-create: default label + assignee + Chinese ... "
if grep -q -- '--label' "$SKILLS_DIR/issue-create/SKILL.md" \
  && grep -q -- '--assignee "@me"' "$SKILLS_DIR/issue-create/SKILL.md" \
  && grep -q 'Issue 标题和正文全部使用中文' "$SKILLS_DIR/issue-create/SKILL.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  issue-pr: default draft + label + assignee + Chinese ... "
if grep -F -q -- '--draft' "$SKILLS_DIR/issue-pr/SKILL.md" \
  && grep -F -q -- '--label "..."' "$SKILLS_DIR/issue-pr/SKILL.md" \
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

echo -n "  issue-flow: declares required superpowers runtime skills ... "
if grep -q 'brainstorming' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q 'issue-research' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q 'writing-plans' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q 'using-git-worktrees' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q 'subagent-driven-development' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q 'executing-plans' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q 'finishing-a-development-branch' "$SKILLS_DIR/issue-flow/SKILL.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  issue-verify: review loop reads PR comments and checks ... "
if grep -F -q 'Bash(gh pr list --head *)' "$SKILLS_DIR/issue-verify/SKILL.md" \
  && grep -F -q 'Bash(gh pr view *)' "$SKILLS_DIR/issue-verify/SKILL.md" \
  && grep -F -q 'Bash(gh pr checks *)' "$SKILLS_DIR/issue-verify/SKILL.md" \
  && grep -F -q 'gh pr view <number> --comments' "$SKILLS_DIR/issue-verify/SKILL.md" \
  && grep -F -q 'gh pr checks <number>' "$SKILLS_DIR/issue-verify/SKILL.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  issue-flow: finish remains explicit review-stage action ... "
if grep -q '若参数为 `finish` / `--finish`' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q '仅在当前 `state=reviewing` 时有效' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q 'issue-finish' "$SKILLS_DIR/issue-flow/SKILL.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  bugfix-flow: declares lightweight bugfix lifecycle ... "
if grep -q 'Skill(bugfix-pick)' "$SKILLS_DIR/bugfix-flow/SKILL.md" \
  && grep -q 'Skill(bugfix-implement)' "$SKILLS_DIR/bugfix-flow/SKILL.md" \
  && grep -q 'Skill(bugfix-verify)' "$SKILLS_DIR/bugfix-flow/SKILL.md" \
  && grep -q '验证通过后默认进入 `ready`' "$SKILLS_DIR/bugfix-flow/SKILL.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  bugfix-pick: supports issue and adhoc contexts ... "
if grep -q '"source": "issue|adhoc"' "$SKILLS_DIR/bugfix-pick/SKILL.md" \
  && grep -q '有 Issue：`fix/<N>-<slug>`' "$SKILLS_DIR/bugfix-pick/SKILL.md" \
  && grep -q '无 Issue：`fix/<slug>`' "$SKILLS_DIR/bugfix-pick/SKILL.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  bugfix-verify: relies on local verification targets ... "
if grep -q '\.bugfix-flow/context.json' "$SKILLS_DIR/bugfix-verify/SKILL.md" \
  && grep -q 'verification_targets' "$SKILLS_DIR/bugfix-verify/SKILL.md" \
  && grep -q 'bugfix-flow 不读取 PR comments' "$SKILLS_DIR/bugfix-verify/SKILL.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  issue-pick: updates local main before creating worktree ... "
if grep -q 'Bash(git fetch origin main)' "$SKILLS_DIR/issue-pick/SKILL.md" \
  && grep -q 'Bash(git checkout main)' "$SKILLS_DIR/issue-pick/SKILL.md" \
  && grep -q 'Bash(git merge --ff-only origin/main)' "$SKILLS_DIR/issue-pick/SKILL.md" \
  && grep -q '先更新本地 `main` 到最新 `origin/main`' "$SKILLS_DIR/issue-pick/SKILL.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  issue-flow: install guidance covers Claude and Codex ... "
if grep -q '/plugin install superpowers@claude-plugins-official' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q '/plugin marketplace add crazygit/issue-flow' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q '/plugin install issue-flow@issue-flow-marketplace' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q 'OpenAI Curated' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q 'bash scripts/install-codex.sh' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q '~/.codex/plugins/issue-flow' "$SKILLS_DIR/issue-flow/SKILL.md" \
  && grep -q '\.agents/plugins/marketplace.json' "$SKILLS_DIR/issue-flow/SKILL.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  codex install docs prefer plugin marketplace flow ... "
if grep -q '\.codex-plugin/plugin.json' "$REPO_ROOT/README.md" \
  && grep -q '\.agents/plugins/marketplace.json' "$REPO_ROOT/README.md" \
  && grep -q 'bash scripts/install-codex.sh' "$REPO_ROOT/README.md" \
  && ! grep -q '~/.agents/skills/' "$REPO_ROOT/README.md" \
  && ! grep -q 'ln -s ' "$REPO_ROOT/README.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  codex install docs no longer depend on session-start hook injection ... "
if ! [ -e "$REPO_ROOT/hooks/session-start" ] \
  && ! [ -e "$REPO_ROOT/.codex/hooks.json" ] \
  && ! [ -e "$REPO_ROOT/.codex/config.toml" ] \
  && grep -q '原生 plugin skill 发现' "$REPO_ROOT/docs/codex-hooks.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo -n "  README documents bugfix-flow usage ... "
if grep -q '/bugfix-flow' "$REPO_ROOT/README.md" \
  && grep -q '\.bugfix-flow/' "$REPO_ROOT/README.md" \
  && grep -q 'Use `bugfix-flow` when you want a lighter repair loop' "$REPO_ROOT/README.md"; then
  echo "ok"
  PASS=$((PASS + 1))
else
  echo "FAIL"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
