---
name: issue-create
description: >-
  创建 GitHub Issue。从对话上下文提取需求信息，按类型选择模板。
  支持 manual 模式（--web 浏览器审核）和 auto 模式（直接创建）。
argument-hint: "[简要描述（可选）]"
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - AskUserQuestion
  - Bash(git remote -v)
  - Bash(git rev-parse --is-inside-work-tree)
  - Bash(gh issue create --web *)
  - Bash(gh issue create *)
  - Bash(mktemp *)
  - Bash(rm -f "$TMPFILE")
---

创建 GitHub Issue。优先从当前对话上下文中提取和整理需求信息，`$ARGUMENTS` 作为补充说明（可选）。

## 执行步骤

### 1. 收集需求信息

回顾当前对话上下文，整理出以下要素：
- 类型：bug / feature / 其他
- 要做什么（what）
- 为什么做（why）
- 验收标准（acceptance criteria）
- 影响范围（scope）
- 如有 `$ARGUMENTS`，将其作为额外补充

### 2. 检测目标仓库

运行 `git remote -v` 确定当前仓库和 remote URL。如果当前目录不是 git 仓库或没有 remote，立即报错退出，不要继续后续步骤。

### 3. 检测运行模式

按以下优先级依次检查：

1. **检查 `$ARGUMENTS`**：如果包含 `--auto` → **auto 模式**
2. **检查 `.issue-flow/mode`**：如果存在且内容为 `auto` → **auto 模式**
3. **默认** → **manual 模式**

> 模式检测完成后，从 `$ARGUMENTS` 中移除 `--auto` 标记，剩余部分作为补充说明供后续步骤使用。
> 当由 `issue-flow` 编排器调用时，模式通过 `$ARGUMENTS` 中的 `--auto` 标志传递（此时 `.issue-flow/` 尚未创建）。
> 当独立调用或处于持久化状态机阶段时，模式从 `.issue-flow/mode` 文件读取。

### 4. 确认需求（manual 模式）

使用 AskUserQuestion 按以下结构逐项展示给用户，等待确认或修正：
- 标题（中文，简洁描述要交付的结果）
- 类型 → 对应默认 label
- 背景
- 验收标准（逐条列出）
- 范围（包含 / 不包含）
- bug 类还需：复现步骤、期望行为 vs 实际行为、环境信息

### 5. 起草 Issue

根据确认后的需求（manual）或收集的需求信息（auto），按类型选择 `references/templates.md` 中对应模板，填充内容后写入临时文件。优先使用 `Write` 写入 `mktemp` 创建的临时文件，避免依赖 shell 重定向。标题使用中文，不加前缀。创建时默认将 Issue 指派给当前登录用户（`@me`）。类型与默认 label 的映射：
- 新功能 → `enhancement`
- 缺陷修复 → `bug`
- 代码重构 → `refactor`
- 文档更新 → `documentation`
- 工具/CI/构建 → `chore`
- 性能优化 → `performance`

### 6. 创建 Issue

> ⛔ **禁止使用 `--web` 标志！** `gh issue create --web` 将整个 title + body + labels 编码到浏览器 URL 中。当 body 较长（设计规格、详细描述 — 在 issue-flow 工作流中很常见）时会触发 `maximum URL length exceeded` 错误。无论 manual 还是 auto 模式，都直接通过 API 创建，使用 `--body-file` 传递 body 内容。

#### Manual 模式

直接通过 API 创建 Issue（不用 `--web`），然后让用户在 GitHub 上审核：
```bash
TMPFILE=$(mktemp /tmp/issue-draft.XXXXXX.md)
# 使用 Write 将起草的 Issue 内容写入 $TMPFILE
gh issue create --title "..." --label "..." --assignee "@me" --body-file "$TMPFILE"
```

捕获输出中的 Issue URL，展示给用户。用户可直接在 GitHub 网页上编辑 Issue 内容。
如果用户需要修改，重新生成内容到临时文件后使用 `gh issue edit <N> --body-file "$TMPFILE"` 更新。
确认 Issue 无需进一步修改后，执行 `rm -f "$TMPFILE"` 清理临时文件。

创建完成后，提示用户："Issue 已创建：`<URL>`，可在网页上审核/编辑。继续 `/issue-flow #<编号>` 进入下一步。"

#### Auto 模式

直接执行（与 manual 相同的命令）：
```bash
TMPFILE=$(mktemp /tmp/issue-draft.XXXXXX.md)
# 使用 Write 将起草的 Issue 内容写入 $TMPFILE
gh issue create --title "..." --label "..." --assignee "@me" --body-file "$TMPFILE"
rm -f "$TMPFILE"
```

捕获输出中的 Issue URL，解析出 Issue 编号，并输出：
- Issue 编号
- Issue URL
- 标题

## 规则

- Issue 标题和正文全部使用中文
- 标题表达结果，不加 `feat:`、`fix:` 等前缀
- 默认分类通过 `--label` 参数实现，不硬编码到标题
- 创建 Issue 时默认使用 `--assignee "@me"` 将其分配给自己
- 不要编造内容 — 严格从对话上下文和用户输入中推导
- 对话中的要点列表自动转换为验收标准
- 概述保持简洁（1-3 句）
- 背景解释"为什么"，不重复"做什么"
- **⛔ 禁止使用 `--web`** — body 较长时会触发 URL 长度限制错误，始终通过 API 直接创建
- manual 模式下先创建 Issue，再让用户在 GitHub 网页上审核/编辑
- auto 模式下直接创建，输出编号和 URL 供后续步骤使用
