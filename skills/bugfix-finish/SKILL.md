---
name: bugfix-finish
description: >-
  Bug 修复收尾。清理 worktree/分支与 .bugfix-flow/ 状态目录。支持 manual 和 auto 模式。
disable-model-invocation: false
allowed-tools:
  - Read
  - Bash(git worktree list)
  - Bash(git worktree remove *)
  - Bash(git branch *)
  - Bash(git status *)
  - Bash(rm -rf .bugfix-flow)
  - AskUserQuestion
  - Skill(superpowers:finishing-a-development-branch)
---

# Bugfix Finish

完成 bug 修复流程的收尾工作：worktree 清理、分支管理、状态目录删除。

## 执行步骤

### 1. 前置检查

1. 查找 `.bugfix-flow/` 目录
2. 若未找到，停止并提示："未找到 bugfix-flow 会话，无需清理"

### 2. 检测运行模式

检查 `.bugfix-flow/mode`：
- `auto` → **auto 模式**
- 其他/不存在 → **manual 模式**

同时读取并暂存最终报告需要的 bug 摘要、当前分支名、worktree 路径和未提交变更摘要。

### 3. 清理 `.bugfix-flow`

在任何可能移除 worktree 的操作之前，删除当前 worktree 根目录下的 `.bugfix-flow/`：

```bash
rm -rf .bugfix-flow
```

### 4. 分支收尾

#### Manual 模式

调用 `superpowers:finishing-a-development-branch`，但默认建议：

- Keep branch
- 或仅清理 worktree

bugfix-flow 默认不要求在此阶段创建 PR。

#### Auto 模式

默认行为：

1. 保留分支
2. 清理 worktree
3. 不自动 merge

### 5. 输出

输出最终报告：

- bug 摘要
- 分支处理结果
- worktree 清理状态
- `.bugfix-flow/` 清理状态

## 规则

- 不自动 merge PR
- 不自动删除远端 branch
- `.bugfix-flow/` 在 `finished` 后必须清理，并且必须先于 worktree 移除执行
- 删除时仅清理当前 worktree 根目录下的 `.bugfix-flow/`
