---
name: issue-finish
description: >-
  Issue 开发收尾。调用 finishing-a-development-branch，清理 worktree/分支，
  删除 .issue-flow 状态目录。支持 manual 和 auto 模式。
disable-model-invocation: false
allowed-tools:
  - Read
  - Bash(git worktree list)
  - Bash(git worktree remove *)
  - Bash(git branch *)
  - Bash(git status *)
  - Bash(rm -r .issue-flow)
  - AskUserQuestion
  - Skill(superpowers:finishing-a-development-branch)
---

# Issue Finish

完成 Issue 开发流程的收尾工作：worktree 清理、分支管理、状态目录删除。

## 执行步骤

### 1. 前置检查

1. 查找 `.issue-flow/` 目录（当前目录向上递归）
2. 若未找到，停止并提示："未找到 issue-flow 会话，无需清理"

### 2. 检测运行模式

检查 `.issue-flow/mode`：
- `auto` → **auto 模式**
- 其他/不存在 → **manual 模式**

### 3. 分支收尾

#### Manual 模式

调用 `superpowers:finishing-a-development-branch`，但限制选项：
- 选项 1：Merge back（如用户选择）
- 选项 3：Keep branch（保留分支，但清理 worktree）
- 选项 4：Discard（丢弃分支和 worktree）

PR 已在 `issue-pr` 阶段处理，此处不再重复创建 PR。

#### Auto 模式

默认行为：
1. 保留分支（等待 PR merge 后再由 GitHub 自动删除）
2. 清理 worktree
3. 不自动 merge

执行：
```bash
# 获取当前 worktree 路径
git worktree list | grep "$(git branch --show-current)"
# 移除 worktree
git worktree remove <path>
```

### 4. 清理 .issue-flow

无论 manual 还是 auto，在收尾完成后删除 `.issue-flow/` 目录：

```bash
rm -r .issue-flow
```

### 5. 输出

输出最终报告：

- Issue 编号和标题
- 分支处理结果（保留 / 删除 / 合并）
- Worktree 清理状态
- `.issue-flow/` 清理状态
- 下一步建议（如等待 PR review、关闭 Issue 等）

## 规则

- 不自动 merge PR
- 不自动删除已推送到远端的 branch（默认保留）
- `.issue-flow/` 在 `finished` 后必须清理
- 删除时仅清理当前 worktree 根目录下的 `.issue-flow/`，不要泛化到其他路径
- worktree 移除前确认没有未保存的更改
- 如有未提交且未 push 的重要更改，先提醒用户
