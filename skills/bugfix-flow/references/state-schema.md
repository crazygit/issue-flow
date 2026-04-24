# Bugfix-Flow 状态契约

本文件定义 `bugfix-flow` 状态机使用的持久化格式。所有子 skill 都应遵循此约定。

## 目录结构

每个被 `bugfix-flow` 接管的开发会话，在 **worktree 根目录**下创建 `.bugfix-flow/`：

```text
.bugfix-flow/
  state            # 当前阶段（纯文本，一行）
  mode             # 运行模式：auto | manual
  context.json     # bug 上下文（JSON）
  verify-report.md # 验证报告（可选，markdown）
```

> `.bugfix-flow/` 应被添加到 `.gitignore` 中，避免提交到仓库。

## 文件格式

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
4. 若未找到，视为不在 bugfix-flow 会话中

## 子 skill 行为约定

- **读取**：子 skill 可以读取 `.bugfix-flow/` 中的文件获取上下文
- **写入**：子 skill 可以写入 `context.json`、`verify-report.md` 等业务文件
- 写入 `.bugfix-flow/` 状态文件时，优先使用 `Write`，不要依赖 shell 重定向
- **状态更新**：`.bugfix-flow/state` 由 `bugfix-flow` 编排器统一维护，子 skill 不应直接修改
- **mode 适配**：子 skill 优先读取 `.bugfix-flow/mode`，若不存在则默认 `manual`
