# Claude Code Marketplace 与 Plugin 机制

本文档记录 Claude Code 如何发现 marketplace、注册插件、以及加载已安装插件的全流程，方便开发时理解 issue-flow 在 Claude Code 插件体系中的位置。

## 目录结构

Claude Code 的插件相关文件存放在 `~/.claude/plugins/` 下：

```
~/.claude/plugins/
├── known_marketplaces.json      # 已注册的 marketplace 列表
├── installed_plugins.json       # 已安装的插件注册表
├── install-counts-cache.json    # 安装计数缓存
├── blocklist.json               # 插件黑名单
├── marketplaces/                # marketplace 仓库 clone 目录
│   ├── claude-plugins-official/ # 官方 marketplace（git clone）
│   └── issue-flow-marketplace/  # issue-flow marketplace（git clone）
└── cache/                       # 已安装插件的运行副本
    ├── claude-plugins-official/
    │   ├── superpowers/5.0.5/
    │   ├── code-review/b664e152af57/
    │   └── ...
    └── issue-flow-marketplace/
        └── issue-flow/1.0.0/
```

## 1. Marketplace 发现与注册

### 添加 Marketplace

用户执行 `/plugin marketplace add <owner>/<repo>`，Claude Code 做以下操作：

1. 将 GitHub 仓库 **git clone** 到 `~/.claude/plugins/marketplaces/<marketplace-name>/`
2. 在仓库根目录查找 `.claude-plugin/marketplace.json`，解析出可用插件列表
3. 将 marketplace 信息写入 `known_marketplaces.json`

### known_marketplaces.json 结构

```json
{
  "claude-plugins-official": {
    "source": {
      "source": "github",
      "repo": "anthropics/claude-plugins-official"
    },
    "installLocation": "~/.claude/plugins/marketplaces/claude-plugins-official",
    "lastUpdated": "2026-03-01T02:06:54.437Z"
  },
  "issue-flow-marketplace": {
    "source": {
      "source": "github",
      "repo": "crazygit/issue-flow"
    },
    "installLocation": "~/.claude/plugins/marketplaces/issue-flow-marketplace",
    "lastUpdated": "2026-04-18T00:35:10.897Z"
  }
}
```

### marketplace.json 结构

位于仓库的 `.claude-plugin/marketplace.json`，声明该 marketplace 包含哪些插件：

```json
{
  "name": "issue-flow-marketplace",
  "owner": { "name": "Crazygit" },
  "metadata": {
    "description": "Marketplace for installing the Issue-Flow Claude Code plugin.",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "issue-flow",
      "description": "Issue-driven development orchestrator with state machine workflow",
      "version": "1.0.0",
      "source": "./",
      "author": { "name": "Crazygit" }
    }
  ]
}
```

关键字段：

| 字段               | 说明                                                                      |
| ------------------ | ------------------------------------------------------------------------- |
| `plugins[].name`   | 插件唯一标识，安装时格式为 `<name>@<marketplace-name>`                    |
| `plugins[].source` | 插件源码路径，相对于 marketplace.json 所在目录。`"./"` 表示整个仓库根目录 |

## 2. 插件安装

用户执行 `/plugin install <name>@<marketplace-name>`，Claude Code 做以下操作：

1. 从对应 marketplace 的 `marketplace.json` 中找到插件条目
2. 根据 `source` 字段定位插件源码目录
3. **将该目录内容完整复制**到 cache：

```
~/.claude/plugins/cache/<marketplace-name>/<plugin-name>/<version>/
```

4. 在 `installed_plugins.json` 中注册：

```json
{
  "version": 2,
  "plugins": {
    "issue-flow@issue-flow-marketplace": [
      {
        "scope": "user",
        "installPath": "~/.claude/plugins/cache/issue-flow-marketplace/issue-flow/1.0.0",
        "version": "1.0.0",
        "installedAt": "2026-04-18T00:35:43.411Z",
        "gitCommitSha": "dff28250ff7f1bf4f0e2ce239c061b008935245b"
      }
    ]
  }
}
```

### source 字段与文件复制的关系

`source` 决定了哪些文件会被复制到 cache：

| source 值                 | 效果                                              |
| ------------------------- | ------------------------------------------------- |
| `"./"`                    | 整个仓库根目录内容都被复制（issue-flow 当前用法） |
| `"./plugins/issue-flow/"` | 只复制子目录内容                                  |

> **注意：** `source: "./"` 意味着 tests/、docs/、scripts/、.github/ 等开发文件也会被复制到 cache，虽然不影响运行，但会占用额外磁盘空间。

## 3. 插件加载（会话启动时）

每次启动 Claude Code 会话时：

1. 读取 `installed_plugins.json`，遍历所有已安装插件
2. 进入每个插件的 `installPath` 目录
3. 解析 `.claude-plugin/plugin.json` 获取组件路径
4. 加载以下组件：

| 组件       | 路径模式                   | 加载行为                                   |
| ---------- | -------------------------- | ------------------------------------------ |
| Skills     | `skills/*/SKILL.md`        | 注入到会话的可用 skill 列表                |
| Agents     | `agents/*.md`              | 注册为可用 subagent 类型                   |
| Hooks      | `hooks/hooks.json`         | 注册事件钩子（tool 调用等）                |
| References | `skills/*/references/*.md` | 作为 skill 的参考文档随 skill 加载         |

## 4. Monorepo vs 单插件 Marketplace 的差异

### 官方 marketplace（Monorepo 结构）

```
claude-plugins-official/          ← marketplace 仓库
├── README.md
├── plugins/
│   ├── superpowers/              ← 每个插件独立子目录
│   │   ├── .claude-plugin/
│   │   ├── skills/
│   │   └── ...
│   ├── feature-dev/
│   └── ...
└── external_plugins/
```

- `marketplace.json` 中每个插件的 `source` 指向各自的子目录
- `marketplaces/` 目录看起来干净整洁
- 但安装后 `cache/` 中每个插件仍包含完整文件（包括 tests、docs 等）

### issue-flow marketplace（单插件结构）

```
issue-flow-marketplace/           ← marketplace 仓库（= 插件源码）
├── .claude-plugin/
│   ├── marketplace.json          ← source: "./"
│   └── plugin.json
├── skills/
├── agents/
├── hooks/
├── tests/                        ← 开发文件也被 clone 和复制
├── docs/
└── ...
```

- `source: "./"` 导致整个仓库被当作插件源码
- `marketplaces/` 目录包含所有开发文件，看起来杂乱
- 但**运行时行为与 monorepo 结构完全一致**
