---
name: issue-pr
description: >-
  创建 Pull Request。支持 manual 模式（--web 浏览器审核）和 auto 模式（直接创建）。
  负责确认 PR 基本前提、关联 Issue、起草 PR 文案。
argument-hint: "[Issue 编号]（可选，默认自动推断）"
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - AskUserQuestion
  - Bash(git status *)
  - Bash(git diff *)
  - Bash(git log *)
  - Bash(git branch *)
  - Bash(git show *)
  - Bash(git remote -v)
  - Bash(git rev-parse *)
  - Bash(gh auth status *)
  - Bash(gh pr create --web *)
  - Bash(gh pr create *)
  - Bash(gh pr list --head *)
  - Bash(gh issue view --comments *)
  - Bash(mktemp *)
  - Bash(rm *)
---

创建 PR。该 skill 只负责 PR 草稿和创建，不负责测试、review、commit、push 或分支收尾。

## 前置条件

- 当前不在 `main`/`master` 等主分支
- 当前变更已经过验证，适合进入评审
- 远端分支如需先推送，应在进入本 skill 前完成

## 执行步骤

### 1. 前置检查

1. 运行 `gh auth status`，失败则停止，提示运行 `gh auth login -h github.com`
2. 运行 `git remote -v` 确认仓库
3. 确认当前分支不是 main/master，否则停止
4. 运行 `git status`，如果存在未提交变更，提示用户先处理提交，再继续创建 PR

### 2. 检测运行模式

检查 `.issue-flow/mode`：
- 如果存在且内容为 `auto` → **auto 模式**
- 否则 → **manual 模式**（默认）

### 3. 关联 Issue

按以下优先级尝试提取 Issue 编号：

1. 分支名中的数字（如 `feature/123-xxx` → `#123`）
2. `git log` 中 `Refs/Fixes/Closes/Resolves #N` 引用
3. 当前分支已有的 PR（`gh pr list --head <branch>`）
4. `$ARGUMENTS` 中的 Issue 编号

提取到编号后，运行 `gh issue view <N> --comments` 读取 Issue 内容，用于生成标题和正文。

如果所有来源都无法提取：
- 提示用户手动提供 Issue 编号
- 如果用户明确表示没有关联 Issue，可以继续，但不得编造关联关系

### 4. 检查是否已存在 PR

- 运行 `gh pr list --head <branch>`
- 如果当前分支已经存在 open PR，停止并返回已有 PR 信息，避免重复创建

### 5. 起草 PR 内容

1. 根据 `references/templates.md` 中的 PR 模板起草内容，优先使用 `Write` 写入 `mktemp` 创建的临时文件，避免依赖 shell 重定向
2. PR 标题概括当前分支的最终交付内容
3. 如果已关联 Issue，在正文中加入 `Closes #N`
4. 变更说明必须严格来源于 `git diff`、提交记录和 Issue 内容，不编造

### 6. 创建 PR

#### Manual 模式

1. 先向用户展示 PR 标题和正文草稿，供其确认
2. 运行以下命令：
   ```bash
   TMPFILE=$(mktemp /tmp/pr-draft.XXXXXX.md)
   # 使用 Write 将 PR body 写入 $TMPFILE
   gh pr create --web --title "..." --body-file "$TMPFILE"
   rm -f "$TMPFILE"
   ```
3. 使用 `--web` 让用户在浏览器中审核后手动提交
4. 命令结束后清理临时文件

#### Auto 模式

直接执行：
```bash
TMPFILE=$(mktemp /tmp/pr-draft.XXXXXX.md)
# 使用 Write 将 PR body 写入 $TMPFILE
gh pr create --title "..." --body-file "$TMPFILE"
rm -f "$TMPFILE"
```

捕获并输出 PR URL。

## 规则

- `issue-pr` 不负责 commit 规范、测试规范、review 流程和分支清理
- PR 标题和正文以仓库现有协作习惯为准
- PR 正文使用中文
- 找到 Issue 时，正文应关联 Issue（`Closes #N`）
- 不自动 `git push`
- manual 模式下所有 GitHub 写操作使用 `--web` 由人工审核
- 未找到关联 Issue 时提示用户，不编造关联关系
- 不要编造变更内容 — 严格从 `git diff` 和 Issue 中提取
