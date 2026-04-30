# Issue-Flow 状态契约

本文件定义 `issue-flow` 状态机使用的持久化格式。所有子 skill 都应遵循此约定。

## 目录结构

Issue-Flow 有两个状态位置：

- pre-worktree 阶段：在启动命令所在仓库根目录使用 `.issue-flow/pending.json`
- 正式状态机阶段：在目标 **worktree 根目录**下创建 `.issue-flow/`

每个被 `issue-flow` 接管的正式开发会话，在 **worktree 根目录**下创建 `.issue-flow/`：

```
.issue-flow/
  state              # 当前阶段（纯文本，一行）
  mode               # 运行模式：auto | manual
  issue.json         # Issue 元数据（JSON）
  research-notes.md  # 调研结果（可选，markdown）
  plan-path          # plan 文件绝对/相对路径（纯文本，一行）
  verify-report.md   # 验证报告（可选，markdown）
```

> `.issue-flow/` 应被添加到 `.gitignore` 中，避免提交到仓库。

## 文件格式

### `pending.json`

`.issue-flow/pending.json` 是 pre-worktree 暂存文件，不是正式状态机 state。它只用于 `brainstorm -> issue-create -> issue-pick` 之间的短期恢复和 handoff。

建议格式：

```json
{
  "flow": "issue-flow",
  "mode": "manual",
  "phase": "brainstorming",
  "request": "支持用户使用邮箱登录",
  "issue_number": 123,
  "created_at": "2026-04-30T12:00:00Z",
  "updated_at": "2026-04-30T12:05:00Z"
}
```

约束：

- `phase` 取值：`brainstorming`, `issue-created`, `picking`
- `issue_number` 仅在 Issue 创建后存在
- 同一 repo root 只允许一个 pending 流程；如已存在，编排器必须提示用户恢复、覆盖或取消
- `pending.json` 不参与 `state-transition-guard` 的正式 state 校验

### `state`

合法值（按流转顺序）：

> `brainstorm` 和 `issue-create` 发生在 `.issue-flow/` 创建之前，属于预阶段，不会出现在 `state` 文件中。
> 持久化状态机从 `picked` 开始。

```
picked → researching → planned → implementing → committing → pring → reviewing → finished
                      ↑___________________________↓（issue-verify 失败时回退到 implementing）
                                                                   ↑___________↓（PR 后反馈循环）
```

- `picked`：已创建 worktree/分支，等待调研
- `researching`：已完成 Issue 接手，正在/已完成代码库调研，等待生成计划
- `planned`：已生成计划，等待执行
- `implementing`：正在/已执行实现计划
- `committing`：代码已验证通过，等待提交
- `pring`：代码已提交，等待创建 PR
- `reviewing`：PR 已创建，等待或处理 review/CI 反馈
- `finished`：流程已明确结束，可清理 `.issue-flow/`

> `issue-verify` 是 workflow 动作，不单独持久化为 `state` 值。

### `mode`

合法值：

- `manual`：人工确认模式。每个门控点暂停，等用户确认后再继续。
- `auto`：全自动模式。连续自动推进，GitHub 写操作通过 API 直接创建（使用 `--body-file` 而非 `--web`，避免 URL 长度限制）。

### `issue.json`

```json
{
  "number": 123,
  "title": "支持用户使用邮箱登录",
  "url": "https://github.com/owner/repo/issues/123",
  "type": "feature"
}
```

- `type` 用于分支命名推断，取值：`feature`, `fix`, `refactor`, `chore`, `docs`, `perf`

### `plan-path`

指向 plan 文件的路径，通常为：

```
docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md
```

## 状态查找规则

子 skill 查找 `.issue-flow/` 时，按以下优先级：

1. 当前目录是否存在 `.issue-flow/state`
2. 若不存在，向父目录逐级递归查找（类似 `.git` 查找逻辑）
3. 若找到，以找到 `.issue-flow/` 的目录为基准读取其他文件
4. 若未找到正式 state，编排器可以读取当前 git 仓库根目录的 `.issue-flow/pending.json` 恢复 pre-worktree 流程
5. 若正式 state 和 pending 都未找到，视为不在 issue-flow 会话中

## 子 skill 行为约定

- **读取**：子 skill 可以读取 `.issue-flow/` 中的文件获取上下文
- **写入**：子 skill 可以写入 `research-notes.md`、`plan-path`、`verify-report.md` 等业务文件
- 写入 `.issue-flow/` 状态文件时，优先使用 `Write`，不要依赖 `cat > file`、`echo ... > file` 这类 shell 重定向
- **初始状态**：`issue-pick` 是唯一允许创建正式 `.issue-flow/state` 初始值的子 skill，初始 state 为 `picked`
- **状态更新**：初始创建之后，`.issue-flow/state` 由 `issue-flow` 编排器统一维护，其他子 skill 不应直接修改
- **mode 适配**：子 skill 在执行门控操作前，应按以下优先级检测运行模式：
  1. 检查 `$ARGUMENTS` 是否包含 `--auto`（由编排器传入，用于预阶段 skill）
  2. 读取 `.issue-flow/pending.json` 的 `mode`（用于 pre-worktree 恢复阶段）
  3. 读取 `.issue-flow/mode`（用于持久化状态机阶段的 skill）
  4. 默认 `manual` 模式
  - `mode=auto` 时跳过 AskUserQuestion、`--web` 等人工门控
  - `mode=manual` 或文件不存在时保留人工门控，GitHub 写操作同样通过 API 创建并展示 URL 供用户审查（不使用 `--web`，因其有 URL 长度限制）

## 新会话初始化顺序

新建会话时，编排器在源仓库根目录写入 `.issue-flow/pending.json`，但不得在源仓库预先创建正式 `.issue-flow/state`。正确顺序是：

1. `issue-flow` 在源仓库根目录写入或更新 `.issue-flow/pending.json`
2. `issue-pick` 创建目标 worktree 和分支
3. `issue-pick` 在目标 worktree 根目录写入 `.issue-flow/mode`、`.issue-flow/state` 和 `.issue-flow/issue.json`
4. `issue-flow` 回到源仓库根目录并删除 `.issue-flow/pending.json`
5. 正式状态机从 `picked` 开始恢复和推进
