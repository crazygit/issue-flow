---
name: bugfix-verify
description: >-
  Bug 修复验证器。运行聚焦测试与 lint，对照 .bugfix-flow/context.json 中的验证目标
  检查修复是否成立，输出 verify-report。
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
---

# Bugfix Verify

对当前分支的 bug 修复进行验证：测试、lint、变更审查，以及验证目标覆盖度检查。

## 执行步骤

### 1. 前置检查

1. 查找 `.bugfix-flow/context.json`
2. 若未找到，停止并提示："未找到 bugfix 上下文，建议先通过 `/bugfix-flow` 初始化"
3. 读取 `.bugfix-flow/context.json`，提取 `verification_targets`

检查 `.bugfix-flow/mode`：
- `auto` → **auto 模式**
- 其他/不存在 → **manual 模式**

### 2. 运行测试与 Lint

按项目文件自动检测并执行：

| 文件 | 测试命令 | Lint 命令 |
|------|---------|----------|
| `package.json` | `npm test` | `npm run lint` |
| `go.mod` | `go test ./...` | `go vet ./...` |
| `pyproject.toml` / `setup.cfg` | `pytest` | `ruff check` |
| `Cargo.toml` | `cargo test` | `cargo clippy` |

如果命令不存在或失败：

- 记录失败原因
- manual 模式下展示失败项，让用户决定是否回到修复阶段
- auto 模式下停止执行，并保留现场

### 3. 变更检查

1. 运行 `git diff <base>...HEAD` 或等价 diff，查看本次修复的实际改动
2. 判断变更是否覆盖 `verification_targets`
3. 如存在明显未覆盖的目标，在报告中标记为 ❌ 或 ⚠️

### 4. 生成验证报告

将结果写入 `.bugfix-flow/verify-report.md`：

```markdown
# Verify Report

## 测试与 Lint
- {test 结果}
- {lint 结果}

## 验证目标覆盖
- ✅ {目标 1}
- ❌ {目标 2} — {原因}

## 结论
{通过 / 未通过}
```

### 5. 模式处理与输出

#### 通过时

- **manual**：展示报告摘要，提示当前已进入 `ready`，可决定是否提交、开 PR 或继续补改
- **auto**：输出 "验证通过，已进入 ready"

#### 失败时

- **manual**：展示失败项详情，告知用户修复后可通过 `/bugfix-flow` 重新进入验证
- **auto**：输出失败报告，停止执行，保留 worktree 供排查

## 规则

- 任何完成声明前必须先运行验证命令
- 不猜测测试通过，必须看到实际通过结果
- 验证基线来自 `.bugfix-flow/context.json` 的 `verification_targets`
- bugfix-flow 不读取 PR comments 或 review loop；它只关注本地修复是否成立
