---
name: issue-flow
description: >-
  以 GitHub Issue 为交付事实来源的开发编排器。
  通过 .issue-flow/ 状态机管理开发全流程，支持 manual 和 auto 两种模式。
  负责识别当前阶段并调用对应子 skill，不承载具体执行规则。
argument-hint: "[<需求描述> | #<Issue编号> | --auto ...]"
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
  - Bash(gh issue create *)
  - Bash(gh pr create *)
  - Bash(mkdir *)
  - Bash(echo *)
  - Bash(cat *)
  - Bash(date *)
  - Bash(rm -f .issue-flow/pending.json)
  - Bash(rm -r .issue-flow)
  - Bash(pwd)
  - Skill(issue-brainstorm)
  - Skill(issue-create)
  - Skill(issue-pick)
  - Skill(issue-research)
  - Skill(issue-plan)
  - Skill(issue-implement)
  - Skill(issue-verify)
  - Skill(issue-commit)
  - Skill(issue-pr)
  - Skill(issue-finish)
  - Skill(superpowers:brainstorming)
  - Skill(superpowers:writing-plans)
  - Skill(superpowers:using-git-worktrees)
  - Skill(superpowers:subagent-driven-development)
  - Skill(superpowers:executing-plans)
  - Skill(superpowers:finishing-a-development-branch)
---

# Issue-Driven Development（编排器）

`issue-flow` 是 Issue 驱动开发的状态机编排器。它只负责：

1. 判断当前处于哪个开发阶段
2. 调用对应子 skill 完成该阶段工作
3. 根据子 skill 结果推进或回退状态

所有具体执行规则（如何创建 Issue、如何写计划、如何验证）由对应子 skill 负责。

## 入口模式

- `/issue-flow <需求描述>` → 模式 A（manual）
- `/issue-flow --auto <需求描述>` 或 `/issue-flow auto <需求描述>` → 模式 A（auto）
- `/issue-flow #123` → 模式 B（manual）
- `/issue-flow auto #123` → 模式 B（auto）
- `/issue-flow` → 模式 C（恢复已有会话）

## 状态持久化

Issue-Flow 有两个状态位置：

1. **pre-worktree pending state**：在目标 worktree 尚未创建前，状态保存在启动命令所在仓库根目录的 `.issue-flow/pending.json`
2. **正式状态机 state**：目标 worktree 创建后，状态保存在目标 worktree 根目录的 `.issue-flow/`

正式开发会话状态保存在 worktree 根目录的 `.issue-flow/` 中：

```
.issue-flow/
  state       # 当前阶段
  mode        # auto | manual
  issue.json  # Issue 元数据
  research-notes.md # 调研结果
  plan-path   # 计划文件路径
```

预阶段（worktree 尚未创建，使用源仓库 `.issue-flow/pending.json` 暂存）：

```
brainstorm → issue-create → [进入持久化状态机]
```

`pending.json` 不是正式状态机 state，只用于短期恢复和 handoff。建议字段：

```json
{
  "flow": "issue-flow",
  "mode": "manual",
  "phase": "brainstorming|issue-created|picking",
  "request": "...",
  "issue_number": 123,
  "created_at": "...",
  "updated_at": "..."
}
```

持久化状态机（`.issue-flow/` 在 `issue-pick` 时创建，从 `picked` 开始可恢复）：

```
picked → researching → planned → implementing → committing → pring → reviewing → finished
                              ↑______________↓（verify 失败时回退）
                                                                           ↑_____↓（PR 后反馈循环）
```

## 执行流程

### 前置检查（所有模式）

1. `gh auth status` — 失败则停止，提示 `gh auth login -h github.com`
2. `git remote -v` — 失败则停止，提示当前目录不是 git 仓库或没有 GitHub remote
3. superpowers 可用性检查 — 必须确认以下运行时 skill 可发现：`brainstorming`、`writing-plans`、`using-git-worktrees`、`subagent-driven-development`、`executing-plans`、`finishing-a-development-branch`
   - Claude Code：优先检查 `~/.claude/plugins/superpowers/skills/` 下对应 `SKILL.md` 是否存在且可读
   - Codex：优先检查已安装的 `superpowers` 插件是否可用；优先假设其来自 `OpenAI Curated`
   - 若缺失任一必需 skill，则**立即停止**，不要创建或修改 `.issue-flow/`
   - Claude Code 安装提示：`/plugin install superpowers@claude-plugins-official`
   - Claude Code 安装 `issue-flow`：`/plugin marketplace add crazygit/issue-flow`，然后 `/plugin install issue-flow@issue-flow-marketplace`
   - Codex 安装提示：
     - 先在 Codex 插件目录的 `OpenAI Curated` 中安装或启用 `Superpowers`
     - 在当前仓库根目录执行：`bash scripts/install-codex.sh`
     - 脚本会准备 `~/.codex/plugins/issue-flow` 和 `~/.agents/plugins/marketplace.json`
     - 脚本会把 `issue-flow` 注册到个人 marketplace `Personal Plugins`
     - 重启 Codex 后在 `Personal Plugins` 中安装或启用 `issue-flow`
   - 错误提示必须说明：缺失的是 superpowers 运行时依赖，而不是 GitHub、仓库、worktree 或 Issue 配置错误

### 模式 A：需求到 Issue 再到实现

```
需求描述
  → 1. issue-flow 写入源仓库 `.issue-flow/pending.json`，phase=brainstorming
  → 2. issue-brainstorm（按模式传入 args，生成 design spec）
  → 3. issue-create（按模式传入 args，将 design spec 写入 Issue 描述并创建 GitHub Issue）
      manual: 直接通过 API 创建 Issue，分享 URL 供用户确认，完成后提示用户继续 `/issue-flow #N`
      auto:   直接创建，获取编号后自动继续
  → 4. issue-flow 更新 pending，phase=issue-created，并记录 issue_number
  → 5. issue-flow 更新 pending，phase=picking
  → 6. issue-pick（创建 worktree + 分支 + 正式 .issue-flow/）
  → 7. issue-flow 删除源仓库的 `.issue-flow/pending.json`
  → [进入状态机循环]
```

Issue-Flow 使用 GitHub Issue 描述作为 design spec 的持久化位置。调用 `superpowers:brainstorming` 时必须把这个偏好传给子 skill：
- 不要写入 `docs/superpowers/specs/`
- 不要提交 design spec 文档
- 最终 design spec 由 `issue-create` 完整写入 GitHub Issue 描述

调用 `issue-brainstorm` 和 `issue-create` 时，通过 Skill args 传递模式标记：
- auto 模式：args 包含 `--auto` + 需求描述
- manual 模式：args 仅包含需求描述（不带 `--auto`）

### 模式 B：基于已有 Issue 开发

```
Issue #N
  → 1. issue-flow 在源仓库 `.issue-flow/pending.json` 记录 picking 状态
  → 2. issue-pick（创建 worktree + 分支 + 正式 .issue-flow/）
  → 3. issue-flow 删除源仓库的 `.issue-flow/pending.json`
  → [进入状态机循环]
```

### 模式 C：恢复会话

1. 查找当前目录或父目录中的 `.issue-flow/state`
2. 若找到正式 state，读取 `state` 和 `mode`，按状态调用对应子 skill
3. 若未找到正式 state，查找当前 git 仓库根目录的 `.issue-flow/pending.json`
4. 若找到 pending，则按 `phase` 恢复 pre-worktree 流程；同一 repo root 只允许一个 pending 流程
5. 若同一 repo root 已存在 pending，新请求必须提示用户恢复、覆盖或取消，不自动并行创建第二个 pending

### 状态机循环

| 当前 state     | 调用子 skill      | 成功后 state                               |
| -------------- | ----------------- | ------------------------------------------ |
| `picked`       | `issue-research`  | `researching`                              |
| `researching`  | `issue-plan`      | `planned`                                  |
| `planned`      | `issue-implement` | `implementing`                             |
| `implementing` | `issue-verify`    | `committing`（失败则保持 `implementing`）  |
| `committing`   | `issue-commit`    | `pring`                                    |
| `pring`        | `issue-pr`        | `reviewing`                                |
| `reviewing`    | 见 review 分流     | `reviewing` 或 `implementing`              |
| `finished`     | `issue-finish`    | 删除 `.issue-flow/`                        |

#### Review 分流

`reviewing` 状态先判断 PR feedback 与 checks：

- 无阻塞反馈 → 调用 `issue-verify`，验证通过后保持 `reviewing`
- 存在需改代码的反馈 → 调用 `issue-implement`，成功后写回 `implementing` 并重新进入验证/提交/PR 更新闭环
- 反馈不清晰或需要产品判断 → manual 模式下暂停询问；auto 模式下停止并输出阻塞原因

#### Manual 模式行为

每调用完一个子 skill 并更新 state 后：

1. 输出当前进展摘要
2. 告知用户当前 state 和下一步建议
3. **停止**，等待用户下一次输入 `/issue-flow` 或确认后再继续

#### Auto 模式行为

`issue-flow` **连续自动调用**子 skill，直到：

- `state` 变为 `reviewing`
- 某个子 skill 返回失败/阻塞
- 遇到需要人工介入的不可恢复错误

Auto 模式下，子 skill 应跳过 `--web` 和 AskUserQuestion，直接执行。

## 状态查找规则

1. 从当前目录开始，检查是否存在 `.issue-flow/state`
2. 若不存在，向父目录逐级递归查找（最多到 git 仓库根目录）
3. 若找到，以该目录为 worktree 根目录读取正式 `.issue-flow/` 下所有文件
4. 若未找到正式 state，检查当前 git 仓库根目录的 `.issue-flow/pending.json`
5. 若找到 pending，恢复 pre-worktree 流程
6. 若都未找到，视为新会话，进入模式 A 或 B

## Mode 判定与写入

解析 `$ARGUMENTS`：

- 如果以 `--auto ` 或 `auto ` 开头 → `mode=auto`
- 否则 → `mode=manual`

若参数为 `finish` / `--finish`：

- 仅在当前 `state=reviewing` 时有效
- `issue-flow` 先将 `.issue-flow/state` 写为 `finished`
- 然后调用 `issue-finish`

新建会话时（模式 A/B），在源仓库根目录创建 `.issue-flow/pending.json`，记录 pre-worktree 状态。
同一 repo root 已存在 pending 时，不自动覆盖；必须提示用户恢复、覆盖或取消。

`issue-pick` 创建目标 worktree 后，必须在目标 worktree 根目录创建正式 `.issue-flow/` 并写入：

```text
mode: manual | auto
state: picked
```

正式状态写入成功后，`issue-flow` 删除源仓库的 `.issue-flow/pending.json`，完成 handoff。

pending 生命周期由 `issue-flow` 编排器统一维护：
- `issue-flow` 负责创建、更新和删除源仓库 `.issue-flow/pending.json`
- `issue-pick` 只负责在目标 worktree 创建正式 `.issue-flow/`
- 删除 pending 必须在源仓库根目录执行 `rm -f .issue-flow/pending.json`

注意：`issue-brainstorm` 和 `issue-create` 在 `.issue-flow/mode` 创建之前执行，
编排器仅在 auto 模式下通过 Skill args 将 `--auto` 标志传递给这两个子 skill，
子 skill 通过 `$ARGUMENTS` 检测模式，而不依赖 `.issue-flow/mode` 文件。

## 状态更新规则

`issue-flow` 统一负责更新 `.issue-flow/state`：

- 子 skill 返回成功 → 按状态流转表写入下一个 state
- 子 skill 返回失败 → 保持当前 state 不变（`verify` 特殊：失败时回退到 `implementing`）
- `issue-create` 在 manual 模式下直接通过 API 创建 Issue 并分享 URL，用户确认编号后继续
- pre-worktree 阶段每完成一个动作，更新源仓库 `.issue-flow/pending.json` 的 `phase` 和 `updated_at`
- `issue-pick` 成功写入正式状态后，`issue-flow` 回到源仓库根目录删除 `.issue-flow/pending.json`
- `issue-pr` 负责在创建 PR 前确保当前分支已推送到远端；成功创建或发现已有 PR 后进入 `reviewing`
- `issue-verify` 在 `reviewing` 状态成功后保持 `reviewing`，不自动收尾
- `reviewing` 下若发现需要代码修改的 PR feedback，先切到 `issue-implement`，成功后 state 写为 `implementing`
- `issue-finish` 仅在用户显式要求收尾时触发，不因 PR 创建自动触发

## 核心治理规则

- Issue 是任务入口，没有明确 Issue 不直接实现
- PR 必须关联 Issue（Body 包含 `Closes #N`）
- 所有 GitHub 写操作在 manual 模式下通过 API 直接执行，创建后分享 URL 供人工审核
- git push 在 manual 模式下不自动执行，必须人工确认
- `issue-flow` 不定义 commit、测试、review、PR 的模板细则，这些由对应 skill 负责
- `.issue-flow/` 不应提交到仓库，必要时提醒用户添加到 `.gitignore`
- `issue-plan` 前必须经过一次显式 research，不能从 `picked` 直接跳到计划
- PR 创建后默认进入 `reviewing`，通过 review/CI 闭环处理反馈，而不是立即结束流程

## 错误处理

- `gh` 未安装或未认证 → 停止，提示修复
- superpowers 缺失或必需 skill 不可发现 → 停止，输出对应平台安装命令；不要创建 `.issue-flow/` 中间状态
- Issue 不存在或无权限 → 停止，让用户确认
- Issue 描述不清 → 通过子 skill 澄清，不猜测
- 子 skill 执行失败 → 保留 `.issue-flow/` 和 worktree，输出失败详情，提示用户修复后继续
- 找不到 `.issue-flow/` 但用户意图是恢复 → 提示用户先执行 `/issue-flow #<编号>`
- 找到 `.issue-flow/pending.json` 但找不到正式 state → 恢复 pre-worktree 流程，不把 pending 当成正式 state
- 用户要求 `finish` 但当前不在 `reviewing` → 停止，提示先完成 PR 创建并进入 review 阶段
