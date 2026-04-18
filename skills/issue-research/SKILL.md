---
name: issue-research
description: >-
  在实现计划前执行显式调研：阅读 Issue 上下文与代码库现状，整理受影响模块、
  约束、风险和待确认点，输出到 .issue-flow/research-notes.md。
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash(cat *)
  - Bash(gh issue view *)
---

# Issue Research

在 `issue-pick` 与 `issue-plan` 之间执行显式调研，避免在不了解代码现状时直接产出计划。

## 执行步骤

### 1. 前置检查

1. 检查当前目录是否存在 `.issue-flow/issue.json`
2. 若不存在，向父目录逐级查找（最多到 git 仓库根目录）
3. 若仍未找到，停止并提示："未找到 .issue-flow/issue.json，请先通过 `/issue-flow #<编号>` 初始化上下文"

### 2. 读取上下文

1. 读取 `.issue-flow/issue.json`
2. 运行 `gh issue view <N> --comments`，提取：
   - 目标
   - 验收标准
   - 约束
   - 已有设计讨论

### 3. 调研代码库现状

围绕 Issue 描述中的模块、术语和路径，使用 `Glob`、`Grep`、`Read` 检查：

- 现有实现入口在哪里
- 哪些文件最可能受影响
- 已有模式或先例是什么
- 是否存在明显风险、缺口或不一致

如果仓库中已经有与该需求相关的文档、设计稿或计划，也应纳入调研结果。

### 4. 产出 research notes

使用 `Write` 将结果写入 `.issue-flow/research-notes.md`：

```markdown
# Research Notes

## Issue Summary
- 目标:
- 验收标准:
- 约束:

## Current Codebase Findings
- 相关模块:
- 关键文件:
- 现有模式:

## Risks
- 风险 1:

## Open Questions
- 问题 1:

## Planning Guidance
- 后续计划应优先关注:
```

### 5. 输出

输出：

- 关键发现摘要
- 主要受影响文件
- 风险与待确认点
- 提示："已生成 `.issue-flow/research-notes.md`，可通过 `/issue-flow` 继续进入计划阶段"

## 规则

- `issue-research` 只负责理解现状，不直接实现代码
- 不编造代码库中不存在的结构或约束
- research notes 必须来源于 Issue 内容和实际代码阅读结果
- 若发现 Issue 与代码现状冲突，应明确写入风险或待确认点，而不是自行假设
