---
name: bugfix-pick
description: >-
  接手一个 bug 修复任务：从 GitHub Issue 或自由文本构建修复上下文，创建隔离 worktree 和分支，
  初始化 .bugfix-flow/。为后续修改和验证做准备。
argument-hint: "<bug 描述 | #Issue编号>"
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - AskUserQuestion
  - Bash(git remote -v)
  - Bash(git rev-parse --is-inside-work-tree)
  - Bash(git fetch origin main)
  - Bash(gh auth status *)
  - Bash(gh repo view *)
  - Bash(gh issue view *)
  - Bash(git worktree add *)
  - Bash(git branch *)
  - Bash(mkdir *)
  - Skill(superpowers:using-git-worktrees)
---

# 接手 Bug

接手 bug 修复任务：`$ARGUMENTS`

## 执行步骤

### 1. 前置检查

1. 运行 `git rev-parse --is-inside-work-tree`
2. 运行 `git remote -v`
3. 如果参数是 `#N`，再运行 `gh auth status` 与 `gh repo view --json nameWithOwner -q .nameWithOwner`

任何一步失败则停止，不继续后续步骤。

### 2. 解析输入

#### 输入是 `#N`

运行 `gh issue view <N> --comments`，提取：

- bug 摘要
- 复现线索
- 预期行为
- 可验证条件

若 Issue 信息不足：
- manual 模式下使用 `AskUserQuestion` 补齐
- auto 模式下停止，并说明缺失项

#### 输入是自由文本

将文本视为 `summary` 的初始值，并判断是否已包含：

- 最小复现线索
- 预期行为
- 至少一条 `verification_targets`

若缺失：
- manual 模式下补问，直到能形成最小可验证上下文
- auto 模式下停止，并说明需要更明确的 bug 描述

### 3. 创建 worktree 和分支

1. 运行 `git fetch origin main` 更新远程分支信息
2. 使用 `superpowers:using-git-worktrees` 基于 `origin/main` 创建隔离工作区
3. 分支命名：
   - 有 Issue：`fix/<N>-<slug>`
   - 无 Issue：`fix/<slug>`

### 4. 初始化 `.bugfix-flow/`

进入 worktree 根目录后：

1. 使用 `Bash(mkdir *)` 创建 `.bugfix-flow/`
2. 使用 `Write` 写入 `.bugfix-flow/context.json`

`context.json` 最少包含：

```json
{
  "source": "issue|adhoc",
  "type": "fix",
  "summary": "...",
  "reproduction": "...",
  "expected": "...",
  "verification_targets": ["..."]
}
```

若来自 Issue，则追加：

```json
"issue": {
  "number": <N>,
  "title": "<Issue标题>",
  "url": "<Issue URL>"
}
```

> `bugfix-pick` 不修改 `.bugfix-flow/state`，状态由 `bugfix-flow` 编排器统一维护。

### 5. 输出

完成时输出：

- bug 摘要
- 复现与预期行为
- 验证目标列表
- 分支名和 worktree 路径
- 提示："已初始化 `.bugfix-flow/context.json`，可通过 `/bugfix-flow` 继续进入修复阶段"

## 规则

- 不直接实现代码，只做接手准备
- 不编造 Issue 或 bug 描述中不存在的信息
- `.bugfix-flow/` 不提交到仓库，必要时提醒用户添加到 `.gitignore`
- 分支命名优先使用 `fix/` 前缀，突出这是 bug 修复工作
