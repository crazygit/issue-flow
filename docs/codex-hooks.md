# Codex Hooks 处理机制

本文档记录为什么 `issue-flow` 不再依赖 Codex `SessionStart` hook 注入 skill 上下文，以及当前在 Codex 下保留了哪些边界。

## 1. 为什么不再使用 `SessionStart`

当前仓库不再通过 Codex `SessionStart` hook 把完整 `SKILL.md` 注入 `additionalContext`。

原因：

1. Codex 已经能通过 `.codex-plugin/plugin.json` 里的 `skills` 入口发现插件 skill
2. 额外注入整份 orchestrator skill 文本会重复占用上下文
3. 每次启动或恢复都注入静态长文本，收益低于成本

因此，Codex 下现在直接依赖原生 plugin skill 发现，不再维护 `session-start` 注入脚本，也不再要求用户级或 repo 级 `codex_hooks` 配置。

## 2. 为什么 `state-transition-guard` 不能直接照搬到 Codex

根据官方 Codex hooks 文档，当前：

- `SessionStart` 支持 `startup|resume` matcher
- `PreToolUse` 目前只拦截 `Bash`
- `PostToolUse` 目前也只针对 `Bash`
- `PreToolUse`/`PostToolUse` 目前不拦截 `Skill`

这意味着：

- Codex 可以直接发现 `issue-flow` 与 `bugfix-flow` skills
- skill 状态机拦截不能依赖 Codex hook 强制实现
- 这部分仍然要靠 orchestrator skill 与技能说明自身来约束

## 3. 当前约定

当前实现与文档约定可以总结为：

1. Codex 通过 marketplace + `.codex-plugin/plugin.json` 发现插件和 skills
2. `scripts/install-codex.sh` 只管理 personal marketplace 与插件启用配置
3. `issue-flow` 不再管理任何 Codex `SessionStart` hook
4. Claude Code 侧仍可使用自己的 hook 机制做 skill 状态转移守卫
