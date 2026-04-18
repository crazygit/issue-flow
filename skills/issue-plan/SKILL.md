---
name: issue-plan
description: >-
  基于 GitHub Issue 生成实现计划。读取 .issue-flow 上下文，调用 writing-plans
  生成可执行计划文件，保存到 .issue-flow/plan-path。支持 manual 和 auto 模式。
argument-hint: ""
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - AskUserQuestion
  - Bash(cat *)
  - Bash(echo *)
  - Bash(mkdir *)
  - Bash(date *)
  - Bash(gh issue view *)
  - Skill(superpowers:writing-plans)
---

# Issue Plan

基于 `.issue-flow/issue.json` 和 `.issue-flow/research-notes.md` 生成实现计划。

## 执行步骤

### 1. 前置检查

1. 检查当前目录是否存在 `.issue-flow/issue.json`
2. 若不存在，向父目录逐级查找（最多到 git 仓库根目录）
3. 若仍未找到，停止并提示："未找到 .issue-flow/issue.json，请先通过 `/issue-flow #<编号>` 或 `issue-pick` 初始化上下文"
4. 检查 `.issue-flow/research-notes.md` 是否存在；若不存在，停止并提示："未找到 research notes，请先通过 `/issue-flow` 执行 research 阶段"

### 2. 读取 Issue 上下文

读取 `.issue-flow/issue.json`，提取：
- Issue 编号、标题、URL、类型

读取 `.issue-flow/research-notes.md`，提取：
- 相关模块
- 关键文件
- 风险
- 计划约束

运行 `gh issue view <N> --comments`，提取：
- 目标
- 验收标准
- 约束
- 任何设计讨论

### 3. 检测运行模式

检查 `.issue-flow/mode`：
- 如果存在且内容为 `auto` → **auto 模式**
- 否则 → **manual 模式**（默认）

### 4. 生成实现计划

调用 `superpowers:writing-plans`，传入 Issue 内容、research notes 和代码库上下文。

`writing-plans` 会自动将计划保存到 `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`。

### 5. 记录 plan 路径

获取生成的 plan 文件路径后，使用 `Write` 写入 `.issue-flow/plan-path`，文件内容仅包含一行：

```text
<plan-file-path>
```

### 6. 模式处理

#### Manual 模式

1. 读取生成的 plan 文件内容
2. 向用户展示计划摘要（目标、任务列表、关键文件）
3. 使用 AskUserQuestion 询问用户是否批准计划
4. 用户批准后，输出 "计划已批准，可通过 `/issue-flow` 进入实现阶段"
5. 若用户要求修改，根据反馈调整 plan 文件，然后重新展示

#### Auto 模式

1. 验证 plan 文件格式正确（包含 checkbox 任务列表）
2. 直接输出 "计划已生成并保存到 <plan-path>"
3. 不做额外确认，继续执行

### 7. 输出

- Plan 文件路径
- 任务数量
- 下一步建议（manual 模式下）

## 规则

- 计划必须基于 Issue 的验收标准，不能偏离目标
- 计划必须显式吸收 research 结论，不能忽略已发现的风险和文件边界
- 若 Issue 信息不足，基于代码库和 Issue 描述合理补充，不猜测
- 文件路径必须精确，不能含糊
- `.issue-flow/plan-path` 使用相对路径或绝对路径均可，但必须指向实际存在的文件
- manual 模式下必须获得用户明确批准后才声称计划完成
