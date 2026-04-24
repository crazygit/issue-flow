---
name: bugfix-flow
description: >-
  轻量 bug 修复编排器。通过 .bugfix-flow/ 状态机管理从问题接手到验证完成的修复流程，
  支持 manual 和 auto 两种模式，默认在验证通过后暂停等待人工决定是否提交或创建 PR。
argument-hint: "[<bug 描述> | #<Issue编号> | --auto ...]"
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - AskUserQuestion
  - Bash(git remote -v)
  - Bash(git rev-parse --is-inside-work-tree)
  - Bash(git status *)
  - Bash(git branch *)
  - Bash(git worktree *)
  - Bash(gh auth status *)
  - Bash(gh repo view *)
  - Bash(gh issue view *)
  - Bash(mkdir *)
  - Bash(cat *)
  - Bash(rm -r .bugfix-flow)
  - Skill(bugfix-pick)
  - Skill(bugfix-implement)
  - Skill(bugfix-verify)
  - Skill(bugfix-finish)
  - Skill(superpowers:using-git-worktrees)
  - Skill(superpowers:finishing-a-development-branch)
---

# Bugfix Development（编排器）

`bugfix-flow` 是面向 bug 修复的轻量状态机编排器。它只负责：

1. 判断当前处于哪个修复阶段
2. 调用对应子 skill 完成该阶段工作
3. 根据验证结果推进或回退状态

它不承载 brainstorm、issue-create、plan、commit、pr 的完整交付流程；目标是尽快把 bug 修好并验证完成。

## 入口模式

- `/bugfix-flow <bug 描述>` → 模式 A（manual）
- `/bugfix-flow --auto <bug 描述>` 或 `/bugfix-flow auto <bug 描述>` → 模式 A（auto）
- `/bugfix-flow #123` → 模式 B（manual）
- `/bugfix-flow auto #123` → 模式 B（auto）
- `/bugfix-flow` → 模式 C（恢复已有会话）

## 状态持久化

开发会话状态保存在 worktree 根目录的 `.bugfix-flow/` 中：

```text
.bugfix-flow/
  state            # 当前阶段
  mode             # auto | manual
  context.json     # bug 上下文（Issue 或 adhoc）
  verify-report.md # 验证报告
```

持久化状态机（`.bugfix-flow/` 在 `bugfix-pick` 时创建）：

```text
picked → implementing → ready → finished
         ↑__________↓
           verify 失败
```

## 执行流程

### 前置检查（所有模式）

1. `git rev-parse --is-inside-work-tree` — 失败则停止，提示当前目录不是 git 仓库
2. `git remote -v` — 失败则停止，提示仓库缺少 remote
3. 若参数是 `#N`，额外执行 `gh auth status` 和 `gh issue view`
4. superpowers 可用性检查 — 必须确认以下运行时 skill 可发现：`using-git-worktrees`、`finishing-a-development-branch`
   - Claude Code：优先检查 `~/.claude/plugins/superpowers/skills/` 下对应 `SKILL.md`
   - Codex：优先检查已安装的 `superpowers` 插件；优先假设其来自 `OpenAI Curated`
   - 若缺失任一必需 skill，则立即停止，且不要创建或修改 `.bugfix-flow/`

### 模式 A：从 bug 描述开始

```text
bug 描述
  → 1. bugfix-pick（创建 worktree + 分支 + .bugfix-flow/context.json）
  → [进入状态机循环]
```

### 模式 B：基于已有 Issue 修复

```text
Issue #N
  → 1. bugfix-pick（读取 Issue + 创建 worktree + 分支）
  → [进入状态机循环]
```

### 模式 C：恢复会话

1. 查找当前目录或父目录中的 `.bugfix-flow/state`
2. 读取 `state` 和 `mode`
3. 按状态调用对应子 skill
4. 更新状态后，根据 mode 决定是继续还是暂停

### 状态机循环

| 当前 state      | 调用子 skill       | 成功后 state                                |
| --------------- | ------------------ | ------------------------------------------- |
| `picked`        | `bugfix-implement` | `implementing`                              |
| `implementing`  | `bugfix-verify`    | `ready`（失败则保持 `implementing`）        |
| `ready`         | `bugfix-implement` | `implementing`                              |
| `finished`      | `bugfix-finish`    | 删除 `.bugfix-flow/`                        |

#### Manual 模式行为

每调用完一个子 skill 并更新 state 后：

1. 输出当前进展摘要
2. 告知用户当前 state 和下一步建议
3. 停止，等待用户下一次输入 `/bugfix-flow`

#### Auto 模式行为

`bugfix-flow` 连续自动调用子 skill，直到：

- `state` 变为 `ready`
- 某个子 skill 返回失败/阻塞
- 遇到需要人工介入的不可恢复错误

## 状态查找规则

1. 从当前目录开始，检查是否存在 `.bugfix-flow/state`
2. 若不存在，向父目录逐级递归查找（最多到 git 仓库根目录）
3. 若找到，以该目录为 worktree 根目录读取 `.bugfix-flow/` 下所有文件
4. 若未找到，视为新会话，进入模式 A 或 B

## Mode 判定与写入

解析 `$ARGUMENTS`：

- 如果以 `--auto ` 或 `auto ` 开头 → `mode=auto`
- 否则 → `mode=manual`

若参数为 `finish` / `--finish`：

- 仅在当前 `state=ready` 时有效
- `bugfix-flow` 先将 `.bugfix-flow/state` 写为 `finished`
- 然后调用 `bugfix-finish`

新建会话时（模式 A/B），在调用 `bugfix-pick` 前创建 `.bugfix-flow/mode`。

## 状态更新规则

`bugfix-flow` 统一负责更新 `.bugfix-flow/state`：

- 子 skill 返回成功 → 按状态流转表写入下一个 state
- `bugfix-verify` 失败 → 保持 `implementing`
- `bugfix-finish` 只在用户显式要求收尾时触发，不因验证通过自动触发

## 核心治理规则

- bugfix-flow 允许没有 GitHub Issue 的 adhoc 修复
- 若存在 Issue，则只作为上下文与后续 PR 关联依据；不强制在流程中提交或开 PR
- `.bugfix-flow/` 不应提交到仓库，必要时提醒用户添加到 `.gitignore`
- 验证通过后默认进入 `ready`，等待人工决定是否提交、开 PR 或继续补改
- `ready` 阶段允许重新进入 `bugfix-implement` 处理新发现的问题

## 错误处理

- `gh` 未安装或未认证且用户输入 `#N` → 停止，提示修复
- Issue 不存在或无权限 → 停止，让用户确认
- bug 描述不足以形成可验证修复目标 → manual 模式下澄清；auto 模式下停止并说明缺失项
- 子 skill 执行失败 → 保留 `.bugfix-flow/` 和 worktree，输出失败详情，提示用户修复后继续
- 找不到 `.bugfix-flow/` 但用户意图是恢复 → 提示用户先执行 `/bugfix-flow <bug 描述>` 或 `/bugfix-flow #<编号>`
- 用户要求 `finish` 但当前不在 `ready` → 停止，提示先完成验证
