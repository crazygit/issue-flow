# Bugfix-Flow 状态契约

本文件定义 `bugfix-flow` 状态机使用的持久化格式。所有子 skill 都应遵循此约定。

## 目录结构

Bugfix-Flow 有两个状态位置：

- pre-worktree 阶段：默认不创建；仅在 pick 前需要澄清或暂停时，在启动命令所在仓库根目录使用 `.bugfix-flow/pending.json`
- 正式状态机阶段：在目标 **worktree 根目录**下创建 `.bugfix-flow/`

每个被 `bugfix-flow` 接管的正式开发会话，在 **worktree 根目录**下创建 `.bugfix-flow/`：

```text
.bugfix-flow/
  state            # 当前阶段（纯文本，一行）
  mode             # 运行模式：auto | manual
  context.json     # bug 上下文（JSON）
  verify-report.md # 验证报告（可选，markdown）
```

> `.bugfix-flow/` 应被添加到 `.gitignore` 中，避免提交到仓库。

## 文件格式

### `pending.json`

`.bugfix-flow/pending.json` 是 pre-worktree 暂存文件，不是正式状态机 state。它只用于 pick 前澄清或暂停时的短期恢复。

建议格式：

```json
{
  "flow": "bugfix-flow",
  "mode": "manual",
  "phase": "clarifying",
  "summary": "空配置文件会导致服务启动 panic",
  "created_at": "2026-04-30T12:00:00Z",
  "updated_at": "2026-04-30T12:05:00Z"
}
```

约束：

- `phase` 取值：`clarifying`, `picking`
- 同一 repo root 只允许一个 pending 流程；如已存在，编排器必须提示用户恢复、覆盖或取消
- `pending.json` 不参与 `state-transition-guard` 的正式 state 校验

### `state`

合法值（按流转顺序）：

```text
picked → implementing → ready → finished
         ↑__________↓（bugfix-verify 失败时回退到 implementing）
```

- `picked`：已创建 worktree/分支并写入 bug 上下文，等待开始修复
- `implementing`：正在/已执行 bug 修复
- `ready`：验证通过，等待人工决定是否提交或继续修改
- `finished`：流程已明确结束，可清理 `.bugfix-flow/`

### `mode`

合法值：

- `manual`：人工确认模式。每个门控点暂停，等用户确认后再继续
- `auto`：全自动模式。连续自动推进，直到进入 `ready` 或遇到阻塞

### `context.json`

```json
{
  "source": "issue",
  "type": "fix",
  "summary": "空配置文件会导致服务启动 panic",
  "reproduction": "使用空 config.yaml 启动服务",
  "expected": "服务应返回明确错误而不是 panic",
  "verification_targets": [
    "空配置文件启动时不 panic",
    "错误信息包含配置为空"
  ],
  "issue": {
    "number": 123,
    "title": "fix: avoid panic on empty config",
    "url": "https://github.com/owner/repo/issues/123"
  }
}
```

约束：

- `source`：`issue` 或 `adhoc`
- `type`：固定为 `fix`
- `summary`：本次修复的简要目标
- `reproduction`：最小复现步骤；若未知可写明当前缺口
- `expected`：修复后的预期行为
- `verification_targets`：验证时必须检查的结果列表
- `issue`：仅在 `source=issue` 时存在

## 状态查找规则

子 skill 查找 `.bugfix-flow/` 时，按以下优先级：

1. 当前目录是否存在 `.bugfix-flow/state`
2. 若不存在，向父目录逐级递归查找
3. 若找到，以找到 `.bugfix-flow/` 的目录为基准读取其他文件
4. 若未找到正式 state，编排器可以读取当前 git 仓库根目录的 `.bugfix-flow/pending.json` 恢复 pick 前澄清流程
5. 若正式 state 和 pending 都未找到，视为不在 bugfix-flow 会话中

## 子 skill 行为约定

- **读取**：子 skill 可以读取 `.bugfix-flow/` 中的文件获取上下文
- **写入**：子 skill 可以写入 `context.json`、`verify-report.md` 等业务文件
- 写入 `.bugfix-flow/` 状态文件时，优先使用 `Write`，不要依赖 shell 重定向
- **初始状态**：`bugfix-pick` 是唯一允许创建正式 `.bugfix-flow/state` 初始值的子 skill，初始 state 为 `picked`
- **状态更新**：初始创建之后，`.bugfix-flow/state` 由 `bugfix-flow` 编排器统一维护，其他子 skill 不应直接修改
- **mode 适配**：子 skill 在执行门控操作前，应按以下优先级检测运行模式：
  1. 检查 `$ARGUMENTS` 是否包含 `--auto`
  2. 读取 `.bugfix-flow/pending.json` 的 `mode`（用于 pick 前恢复阶段）
  3. 读取 `.bugfix-flow/mode`（用于持久化状态机阶段）
  4. 默认 `manual` 模式

## 新会话初始化顺序

新建会话时，编排器不得在源仓库预先创建正式 `.bugfix-flow/state`。仅当 pick 前需要澄清或暂停时，写入 `.bugfix-flow/pending.json`。正确顺序是：

1. 如需澄清或暂停，`bugfix-flow` 在源仓库根目录写入或更新 `.bugfix-flow/pending.json`
2. `bugfix-pick` 创建目标 worktree 和分支
3. `bugfix-pick` 在目标 worktree 根目录写入 `.bugfix-flow/mode`、`.bugfix-flow/state` 和 `.bugfix-flow/context.json`
4. `bugfix-flow` 回到源仓库根目录并删除 `.bugfix-flow/pending.json`（如果存在）
5. 正式状态机从 `picked` 开始恢复和推进
