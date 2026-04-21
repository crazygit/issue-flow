# Codex Hooks 处理机制

本文档记录 Codex 中 hooks 的发现链路、`issue-flow` 在 Codex 下的 hooks 组织方式，以及用户级安装时为什么需要安全合并 `~/.codex/config.toml` 与 `~/.codex/hooks.json`。文中的 `issue-flow` 仅作为示例插件。

本文档主要参考官方文档：

- https://developers.openai.com/codex/hooks
- https://developers.openai.com/codex/config-reference
- https://developers.openai.com/codex/plugins/build#manifest-fields

## 目录结构

按 `issue-flow` 当前的两条常见使用路径，相关文件大致如下。

### Repo 级 hooks

```text
issue-flow/
├── .codex/
│   ├── config.toml        # 打开 codex_hooks feature flag
│   └── hooks.json         # 仓库级 hooks 声明
├── hooks/
│   ├── run-hook.cmd       # hook 包装器
│   ├── session-start      # SessionStart hook 实际脚本
│   └── state-transition-guard
└── .codex-plugin/
    └── plugin.json
```

### 用户级 hooks

```text
~/
└── .codex/
    ├── config.toml                    # 用户级 Codex 配置
    ├── hooks.json                     # 用户级 hooks 配置
    └── plugins/
        └── issue-flow/
            ├── .codex-plugin/
            ├── .codex/
            ├── hooks/
            └── ...
```

两条路径的作用不同：

- `$REPO_ROOT/.codex/config.toml` 与 `$REPO_ROOT/.codex/hooks.json`：只在当前仓库打开 Codex 时生效
- `~/.codex/config.toml` 与 `~/.codex/hooks.json`：对当前用户的 Codex 会话生效

## 1. Codex 如何发现 hooks

Codex 不从 `.codex-plugin/plugin.json` 读取 hooks。官方文档明确说明：

1. hooks 由 `config.toml` 的 feature flag 控制
2. Codex 会在激活配置层旁边寻找 `hooks.json`
3. 多个配置层的 `hooks.json` 可以同时生效

对 `issue-flow` 而言，最重要的两个位置是：

- `~/.codex/hooks.json`
- `$REPO_ROOT/.codex/hooks.json`

对应的 feature flag 为：

```toml
[features]
codex_hooks = true
```

这也是为什么 `issue-flow` 不能把 hooks 写在 `.codex-plugin/plugin.json` 中。`plugin.json` 负责声明插件 bundle 的元数据和组件入口，但 hooks 的发现入口属于 Codex 配置层，不属于 plugin manifest。

## 2. Repo 级 hooks 如何组织

`issue-flow` 当前在仓库内使用的是 repo 级 hooks：

- [../.codex/config.toml](../.codex/config.toml)
- [../.codex/hooks.json](../.codex/hooks.json)

当前 hooks 声明的关键部分如下：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$(git rev-parse --show-toplevel)/hooks/run-hook.cmd\" session-start",
            "statusMessage": "Loading issue-flow workspace context"
          }
        ]
      }
    ]
  }
}
```

这表示：

- 事件类型是 `SessionStart`
- `matcher` 按官方文档匹配 `startup` 或 `resume`
- 命中的 hook 会执行仓库内的 `hooks/run-hook.cmd session-start`

`session-start` 脚本会输出官方要求的 `hookSpecificOutput.additionalContext` 结构，把 `issue-flow` 的核心上下文注入到当前 Codex 会话。

## 3. 用户级安装为什么不能只 copy 插件目录

如果只把仓库 copy 到 `~/.codex/plugins/issue-flow`，但不处理用户级配置，Codex 并不会自动把插件目录里的 `.codex/config.toml` 当作用户当前会话的激活配置层。

换句话说：

- `~/.codex/plugins/issue-flow/.codex/config.toml` 只是插件目录里的文件
- 它不会替代 `~/.codex/config.toml`
- `~/.codex/plugins/issue-flow/.codex/hooks.json` 也不会自动替代 `~/.codex/hooks.json`

因此，用户级安装如果希望 hooks 真正生效，必须显式处理用户级配置。`issue-flow` 当前的 [../scripts/install-codex.sh](../scripts/install-codex.sh) 已经实现了这一步：

1. 在 `~/.codex/config.toml` 中确保 `[features].codex_hooks = true`
2. 在 `~/.codex/hooks.json` 中合并 `issue-flow` 的 managed hook

这和 personal marketplace 的处理逻辑是同一类问题：

- marketplace 需要安全合并 `~/.agents/plugins/marketplace.json`
- hooks 需要安全合并 `~/.codex/config.toml` 与 `~/.codex/hooks.json`

## 4. 用户级 hooks 如何被安全合并

用户级安装的目标不是覆盖用户自己的 Codex 配置，而是只管理 `issue-flow` 需要的最小子集。

`issue-flow` 当前安装脚本的行为如下：

### `~/.codex/config.toml`

只管理：

```toml
[features]
codex_hooks = true
```

当前脚本会：

- 保留用户已有的其他配置项
- 如果已有 `[features]`，只更新或追加 `codex_hooks = true`
- 不删除其他 feature
- 重复安装时保持幂等，不产生重复键

### `~/.codex/hooks.json`

只管理一条 `issue-flow` 的 `SessionStart` hook。写入后的效果类似：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"/Users/<user>/.codex/plugins/issue-flow/hooks/run-hook.cmd\" session-start",
            "statusMessage": "Loading issue-flow workspace context"
          }
        ]
      }
    ]
  }
}
```

当前脚本会：

- 保留用户已有的其他 hook 事件
- 保留 `SessionStart` 下其他非 `issue-flow` hook
- 只刷新 `issue-flow` 自己管理的那条 hook
- 重复安装时保持幂等，不产生重复 hook

从维护边界来看，`issue-flow` 当前只对“自己管理的 command”负责，而不是重写整个 `hooks.json`。

## 5. 为什么 `state-transition-guard` 不能直接照搬到 Codex

这一点和 Claude Code 的行为差异很大。

根据官方 Codex hooks 文档，当前：

- `SessionStart` 支持 `startup|resume` matcher
- `PreToolUse` 目前只拦截 `Bash`
- `PostToolUse` 目前也只针对 `Bash`
- `PreToolUse`/`PostToolUse` 目前不拦截 `Skill`

因此，Claude Code 中基于 skill 调用的 `state-transition-guard` 不能直接迁移到 Codex hooks。

对 `issue-flow` 来说，这意味着：

- `SessionStart` 上下文注入可以在 Codex 生效
- skill 状态机拦截不能依赖 Codex hook 强制实现
- 这部分仍然要靠 orchestrator skill 与技能说明自身来约束

## 6. `issue-flow` 在 Codex 下的 hooks 处理约定

当前实现与文档约定可以总结为：

1. `.codex-plugin/plugin.json` 不声明 hooks
2. repo 级 hooks 通过 `$REPO_ROOT/.codex/config.toml` 与 `$REPO_ROOT/.codex/hooks.json` 组织
3. 用户级安装若希望 hooks 真正生效，需要安全合并：
   - `~/.codex/config.toml`
   - `~/.codex/hooks.json`
4. `issue-flow` 只管理自己的 `SessionStart` hook，不重写用户的其他 hooks
5. Codex 当前不能像 Claude Code 那样用 hooks 强制拦截 skill 状态转移

## 7. 和 marketplace 文档的关系

- [codex-marketplace.md](codex-marketplace.md) 解释的是“Codex 如何发现 marketplace 与 plugin”
- 本文档解释的是“Codex 如何发现并执行 hooks，以及用户级安装时为什么需要额外合并用户配置”

如果把两者连起来看，personal 安装链路可以理解为：

```text
scripts/install-codex.sh
  → 复制或链接 issue-flow 到 ~/.codex/plugins/issue-flow
  → 安全合并 ~/.agents/plugins/marketplace.json
  → 安全合并 ~/.codex/config.toml
  → 安全合并 ~/.codex/hooks.json
  → Codex 在用户配置层发现 Personal Plugins 与 issue-flow hooks
```

repo 路径则可以理解为：

```text
$REPO_ROOT/.agents/plugins/marketplace.json
  → Codex 发现 issue-flow plugin
  → $REPO_ROOT/.codex/config.toml
  → $REPO_ROOT/.codex/hooks.json
  → 当前仓库会话启用 issue-flow 的 repo 级 hooks
```
