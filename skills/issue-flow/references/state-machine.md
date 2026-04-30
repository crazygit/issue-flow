# Issue-Flow 状态机

## 预阶段（pre-worktree pending）

```text
brainstorm -> issue-create -> [进入持久化状态机]
```

- `brainstorm`：需求讨论与 design spec 生成，发生在目标 worktree 创建之前
- `issue-create`：桥接动作，将 design spec 变为 GitHub Issue 编号
- 这两个阶段使用源仓库根目录的 `.issue-flow/pending.json` 做短期恢复；`pending.json` 不是正式状态机 state

### 预阶段模式传递

由于预阶段运行时正式 `.issue-flow/mode` 尚不存在，`issue-flow` 编排器通过 Skill args 将模式传递给预阶段子 skill：

- auto 模式：编排器调用时传入 `--auto` 标志 + 需求描述
- manual 模式：编排器调用时仅传入需求描述

子 skill 按优先级检测模式：`$ARGUMENTS` 中的 `--auto` → `.issue-flow/pending.json` → `.issue-flow/mode` → 默认 manual。

## 持久化状态机（`.issue-flow/` 在 `issue-pick` 时创建）

```text
picked
  -> researching
  -> planned
  -> implementing
  -> committing
  -> pring
  -> reviewing
  -> finished
```

特殊回路：

- `implementing -> issue-verify -> committing`
- `implementing -> issue-verify(失败) -> implementing`
- `reviewing -> issue-verify -> reviewing`（无阻塞 PR feedback / checks 时）
- `reviewing -> issue-implement -> implementing`（存在需要改代码的 PR feedback / failed checks 时）

设计意图：

- `researching`：在计划前显式阅读代码库和约束，避免直接从 Issue 跳到实现计划
- `reviewing`：PR 已创建后的反馈窗口，用于处理 review comments、CI 修复和补充验证
- `finished`：仅表示用户明确决定收尾，随后由 `issue-finish` 清理会话
