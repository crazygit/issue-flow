---
name: issue-brainstorm
description: >-
  需求头脑风暴：将用户的一个想法或需求，通过调研和结构化讨论，整理成
  可用于创建 GitHub Issue 的 design spec。支持 manual 和 auto 两种模式。
argument-hint: "<需求描述>"
disable-model-invocation: false
allowed-tools:
  - Read
  - Glob
  - Grep
  - AskUserQuestion
  - Bash(cat *)
  - Skill(superpowers:brainstorming)
---

# Issue Brainstorm

将需求描述转化为结构化的 design spec，用于后续创建 GitHub Issue：`$ARGUMENTS`

## 执行步骤

### 1. 检测运行模式

按以下优先级依次检查：

1. **检查 `$ARGUMENTS`**：如果包含 `--auto` → **auto 模式**
2. **检查 `.issue-flow/pending.json`**：如果存在且 `mode=auto` → **auto 模式**
3. **检查 `.issue-flow/mode`**：如果存在且内容为 `auto` → **auto 模式**
4. **默认** → **manual 模式**

> 模式检测完成后，从 `$ARGUMENTS` 中移除 `--auto` 标记，剩余部分作为需求描述供后续步骤使用。
> 当由 `issue-flow` 编排器调用时，模式优先通过 `$ARGUMENTS` 中的 `--auto` 标志传递；若处于可恢复的 pre-worktree 阶段，可从 `.issue-flow/pending.json` 读取。
> 当独立调用或处于持久化状态机阶段时，模式从 `.issue-flow/mode` 文件读取。

### 2. 需求澄清

- 如果 `$ARGUMENTS` 足够清晰 → 继续下一步
- 如果需求过于模糊 → 向用户提问以明确目标、约束和验收标准

### 3. 设计评审

调用 `superpowers:brainstorming` 进行设计评审。

输入：需求描述 + 任何补充上下文。

调用时必须明确声明 Issue-Flow 的 spec 持久化偏好：
- GitHub Issue 描述是最终 design spec 的存放位置
- 不要写入 `docs/superpowers/specs/`
- 不要提交 design spec 文档
- 不要在 brainstorm 结束后进入 `writing-plans`，后续由 `issue-create` 创建 Issue 后再进入状态机

输出：一份结构化的 design spec，至少包含：
- 目标（一句话说明交付结果）
- 背景（为什么做）
- 验收标准（可验证条件列表）
- 范围（包含 / 不包含）
- 技术约束（如有）
- 风险与依赖（如有）

### 4. 模式处理

#### Manual 模式

向用户展示 design spec，等待确认或修正。

使用 AskUserQuestion 展示：
- 目标
- 背景
- 验收标准
- 范围
- 技术约束
- 风险与依赖

用户确认后，输出最终的 design spec。

#### Auto 模式

直接输出 design spec，不做额外确认。

### 5. 输出

输出格式：

```markdown
## Design Spec

### 目标
{目标}

### 背景
{背景}

### 验收标准
- [ ] {标准 1}
- [ ] {标准 2}

### 范围
**包含：**
- {范围 1}

**不包含：**
- {范围外 1}

### 技术约束
{约束}

### 风险与依赖
{风险与依赖}
```

## 规则

- 不编造内容，严格从用户输入和对话上下文中推导
- 验收标准必须可验证
- 范围必须明确，避免无限蔓延
- Issue-Flow 不使用 `docs/superpowers/specs/` 作为 design spec 产物目录
- 不要创建或提交任何 design spec 文档；最终 design spec 必须输出给 `issue-create` 写入 GitHub Issue 描述
- 如果用户在设计评审过程中提出重大修改，更新 design spec 后重新展示
