---
name: issue-commit
description: >-
  智能 Git 提交。使用 Conventional Commit + Emoji 格式创建提交。
  自动分析变更、建议拆分、运行 pre-commit 检查。
  支持 manual 和 auto 模式，可关联 .issue-flow 上下文。
argument-hint: "[message] | --no-verify | --amend"
disable-model-invocation: false
allowed-tools:
  - Read
  - Glob
  - Grep
  - AskUserQuestion
  - Bash(git add *)
  - Bash(git status *)
  - Bash(git commit *)
  - Bash(git diff *)
  - Bash(git log *)
  - Bash(git branch *)
  - Bash(pre-commit *)
---

# 智能 Git 提交

创建格式良好的提交: $ARGUMENTS

## 执行步骤

### 1. 检查变更状态

运行 `git status --short`，判断：
- 无变更 → 提示用户当前没有可提交内容，直接结束
- 有未暂存变更 → 继续下一步

### 2. 检测运行模式

检查 `.issue-flow/mode`：
- `auto` → **auto 模式**
- 其他/不存在 → **manual 模式**

### 3. 自动运行检查

除非指定 `--no-verify`：
- 如果项目配置了 `pre-commit`，尝试运行
- 检查常见代码问题（格式错误、尾随空格等）

### 4. 智能添加

- 没有暂存文件 → 自动 `git add` 所有修改和新增文件
- 有暂存文件 → 只提交被暂存的文件

### 5. 分析变更

运行 `git diff` 理解变更内容。

如果存在 `.issue-flow/issue.json`，读取 Issue 标题和类型辅助推断 commit type。

### 6. 拆分建议

检测到多个逻辑不相关的变更时，按以下标准建议拆分：

1. **不同关注点**: 不同模块（如 `frontend` vs `backend`）
2. **不同变更类型**: 混合了功能添加、Bug 修复和重构
3. **文件类型**: 源代码 vs 文档
4. **逻辑分组**: 分开提交以便于理解和审查

### 7. 生成提交消息

读取 `references/commit-templates.md`，按模板格式生成 Conventional Commit + Emoji 消息。

- 消息格式：`<Emoji> <type>(<scope>): <subject>`
- subject 使用英文祈使句，首字母小写，句末不加句号
- header 整行不超过 72 字符
- 当 `.issue-flow/issue.json` 存在时，footer 添加 `Refs #<N>`

### 8. 提交代码

#### Manual 模式

1. 向用户展示变更摘要和建议的 commit message（或拆分方案）
2. 使用 AskUserQuestion 等待用户确认或修改
3. 用户确认后，执行 `git add` + `git commit`

#### Auto 模式

1. 直接按分析结果拆分 commit（如有必要）
2. 自动 `git add` 和 `git commit`，不询问确认
3. 所有 commit message 使用英文

### 9. 输出

- 提交后的 commit log（最近 3 条）
- 当前分支名
- 下一步建议：进入 PR 阶段或继续验证

## 命令选项

- `--no-verify`: 跳过 pre-commit 检查
- `--amend`: 修改上一次提交。仅对尚未推送的本地提交使用

## 提交规范

- **时态**: 祈使句（`add feature` 而非 `added feature`）
- **简洁**: 第一行保持在 72 字符以内
- **commit message 使用英文**（遵循 CLAUDE.md 规则）

## 规则

- 只提交到本地，不自动 push
- 如果没有暂存文件，自动暂存所有修改和新增的文件
- 检测到多个逻辑变更时，建议拆分提交
- 始终检查 diff 和 commit message 是否匹配
