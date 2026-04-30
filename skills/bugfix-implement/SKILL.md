---
name: bugfix-implement
description: >-
  执行 bug 修复。读取 .bugfix-flow/context.json，围绕复现路径和验证目标做最小修改，
  支持从 ready 重新进入修复循环。
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Edit
  - MultiEdit
  - Glob
  - Grep
  - Bash(cat *)
  - Bash(git status *)
  - Bash(git branch *)
---

# Bugfix Implement

读取 `.bugfix-flow/context.json` 中的修复上下文并执行最小范围修改。

## 执行步骤

### 1. 前置检查

1. 检查当前目录是否存在 `.bugfix-flow/context.json`
2. 若不存在，向父目录逐级查找
3. 若仍未找到，停止并提示："未找到 .bugfix-flow/context.json，请先通过 `bugfix-pick` 初始化上下文"

读取 `.bugfix-flow/context.json`，提取：

- `summary`
- `reproduction`
- `expected`
- `verification_targets`

### 2. 确认工作区

运行 `git branch --show-current`，确认当前不在 `main`/`master` 分支。

若在主分支，停止并提示用户先进入 bugfix worktree。

### 3. 执行修复

围绕 `reproduction` 与 `expected` 执行代码修改：

- 优先做最小可行修复，不扩大范围
- 如需要补测试，测试内容应直接覆盖 `verification_targets`
- 若当前 `state=ready` 且用户重新进入本阶段，视为处理验证中暴露的新缺口
- 优先使用 `Edit` / `MultiEdit` 做局部修改；只有创建新文件或整体生成文件时才使用 `Write`

### 4. 输出

执行完成后输出：

- 修复结果：`成功` / `失败` / `阻塞`
- 触达的主要文件
- 是否补充或更新了测试
- 下一步建议："建议进入验证阶段"

## 规则

- 不引入与 bug 无关的重构
- 修改应尽量直接服务于 `verification_targets`
- 不自动提交；提交和 PR 由用户在 `ready` 后自行决定
