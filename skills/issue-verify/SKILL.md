---
name: issue-verify
description: >-
  Issue 验收验证器。运行 test + lint，调用 code review，比对 Issue 验收标准
  与当前变更。输出 verify-report，支持自动修复重试。适配 manual 和 auto 模式。
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - AskUserQuestion
  - Bash(cat *)
  - Bash(git diff *)
  - Bash(git log *)
  - Bash(npm test *)
  - Bash(npm run *)
  - Bash(npx *)
  - Bash(pytest *)
  - Bash(python *)
  - Bash(python -m *)
  - Bash(uv run *)
  - Bash(ruff check *)
  - Bash(ruff format *)
  - Bash(go test *)
  - Bash(go build *)
  - Bash(go vet *)
  - Bash(cargo test *)
  - Bash(cargo clippy *)
  - Bash(gh issue view *)
  - Bash(gh pr list --head *)
  - Bash(gh pr view *)
  - Bash(gh pr checks *)
  - Agent
---

# Issue Verify

对当前分支的变更进行端到端验证：测试、代码审查、验收标准覆盖度检查，并在 PR 已创建后处理 review/CI 闭环。

## 执行步骤

### 1. 前置检查

1. 查找 `.issue-flow/issue.json`（当前目录向上递归）
2. 若未找到，停止并提示："未找到 Issue 上下文，建议先通过 `/issue-flow #<编号>` 初始化"
3. 读取 Issue 内容，提取验收标准列表

### 2. 检测运行模式

检查 `.issue-flow/mode`：
- `auto` → **auto 模式**
- 其他/不存在 → **manual 模式**

读取 `.issue-flow/state`：
- `implementing`：实现后的首次验证
- `reviewing`：PR 已创建后的再次验证，需额外关注 review/CI 反馈是否已被处理

如果当前 `state=reviewing`：

1. 运行 `gh pr list --head <branch>` 定位当前分支关联的 PR
2. 若找到 PR，运行 `gh pr view <number> --comments` 读取 review feedback 与讨论上下文
3. 运行 `gh pr checks <number>` 读取 CI/check 状态摘要
4. 若未找到 PR，记录为 review loop 缺口，并在报告中明确说明

### 3. 运行测试与 Lint

按项目文件自动检测并执行：

| 文件 | 测试命令 | Lint 命令 |
|------|---------|----------|
| `package.json` | `npm test` | `npm run lint` |
| `go.mod` | `go test ./...` | `go vet ./...` |
| `pyproject.toml` / `setup.cfg` | `pytest` | `ruff check` |
| `Cargo.toml` | `cargo test` | `cargo clippy` |

如果命令不存在或失败：
- 记录失败原因
- 尝试自动修复（lint 类优先尝试 `--fix`，test 类 dispatch fix subagent）
- 重新运行，最多重试 3 次
- 3 次后仍失败，进入失败处理流程

### 4. 代码审查

调用 `code-review` agent 审查当前分支相对 base branch（main/master）的所有变更。

收集审查结果并按 Critical > Warning > Suggestion 分类。

如果有 Critical/Warning：
- auto 模式下自动 dispatch fix subagent 修复
- manual 模式下向用户展示 findings，由用户决定是否修复
- 修复后重新审查，最多 3 次

> **Codex 回退**：如果 Agent 工具不可用，直接分析 `git diff` 输出进行代码审查，不使用 subagent。

### 5. 验收标准比对

1. 运行 `git diff <base>...HEAD` 获取当前变更
2. 逐条检查 Issue 中的验收标准是否被代码/测试覆盖
3. 标记：✅ 已覆盖 / ❌ 未覆盖 / ⚠️ 部分覆盖

对于 ❌ 或 ⚠️ 项：
- auto 模式下尝试自动补充实现（dispatch subagent），然后重新比对，最多 3 次
- manual 模式下向用户报告缺口，等待用户处理

### 6. Review Loop 检查（仅 `state=reviewing`）

基于 PR 上下文补充检查：

1. review comments 中是否存在明显未处理的阻塞反馈
2. `gh pr checks` 是否仍存在失败或 pending 的关键检查
3. 当前分支变更是否已覆盖本轮反馈中要求补充的内容

若存在阻塞项：
- manual 模式下向用户报告，建议回到实现或继续处理反馈
- auto 模式下停止自动推进，保持 `reviewing` 或回退 `implementing`

### 7. 生成验证报告

将结果写入 `.issue-flow/verify-report.md`：

```markdown
# Verify Report

## 测试与 Lint
- {test 结果}
- {lint 结果}

## Code Review
- Critical: {N}
- Warning: {N}
- Suggestion: {N}

## 验收标准覆盖
- ✅ {标准 1}
- ❌ {标准 2} — {原因}

## Review Loop
- PR: {编号或未找到}
- Review Feedback: {已处理 / 未处理 / 无}
- Checks: {通过 / 失败 / pending / 未找到}

## 结论
{通过 / 未通过}
```

### 8. 模式处理与输出

#### 通过时

- **manual**：展示报告摘要，告知用户验证通过，建议进入提交阶段
- **manual**：若当前 `state=reviewing`，提示用户当前仍处于 review 阶段，可继续等待反馈或在确认结束后使用 `/issue-flow finish` 收尾
- **auto**：直接输出 "验证通过"

> 若当前 `state=reviewing`，应以前述第二条为准，不再提示进入提交阶段。

#### 失败时

- **manual**：展示失败项详情，告知用户修复后可通过 `/issue-flow` 重新进入验证
- **auto**：输出失败报告，停止执行，保留 worktree 供排查

## 规则

- 任何完成声明前必须先运行验证命令（遵循 verification-before-completion 原则）
- 不猜测测试通过，必须看到 0 failures 的输出
- 自动修复最多 3 次，超过则停止并报错
- manual 模式下所有自动修复需向用户汇报结果
- 验收标准比对必须基于实际代码变更，不能仅基于测试通过就推断
- 当 `state=reviewing` 时，验证通过也不自动视为流程结束
- 当 `state=reviewing` 时，必须显式读取 PR feedback 与 check 状态，不能只重复本地测试
