---
name: issue-implement
description: >-
  执行 Issue 的实现计划。读取 .issue-flow/plan-path，调用
  subagent-driven-development 按任务执行代码变更。支持 manual 和 auto 模式。
argument-hint: ""
disable-model-invocation: false
allowed-tools:
  - Read
  - Bash(cat *)
  - Bash(git status *)
  - Bash(git branch *)
  - Skill(superpowers:subagent-driven-development)
  - Skill(superpowers:executing-plans)
---

# Issue Implement

读取 `.issue-flow/plan-path` 中的实现计划并执行。

## 执行步骤

### 1. 前置检查

1. 检查当前目录是否存在 `.issue-flow/plan-path`
2. 若不存在，向父目录逐级查找（最多到 git 仓库根目录）
3. 若仍未找到，停止并提示："未找到 .issue-flow/plan-path，请先通过 `issue-plan` 生成计划"

读取 `.issue-flow/plan-path` 内容，确认文件存在且格式有效（包含 checkbox 任务列表）。

### 2. 确认工作区

运行 `git branch --show-current`，确认当前不在 `main`/`master` 分支。

若在当前分支，提示用户先创建 feature branch 或进入 worktree。

### 3. 执行计划

调用 `superpowers:subagent-driven-development` 执行计划文件。

若 Agent 工具不可用（如 Codex 等平台），直接使用 `superpowers:executing-plans` 顺序执行计划。

### 4. 输出

执行完成后输出：

- 执行结果：`成功` / `失败` / `阻塞`
- 已完成的任务数 / 总任务数
- 当前 git status 摘要（变更文件数、未提交状态）
- 下一步建议：
  - 成功 → "计划已执行完毕，建议进入验证阶段"
  - 失败 → 显示失败原因和修复建议

## 规则

- 不修改计划范围外的代码
- 执行过程中产生的中间问题，由 subagent-execution 内部处理
- 执行完成后不自动提交（提交由 `issue-commit` 负责）
- 若 plan 文件格式无效，停止并提示重新生成计划
