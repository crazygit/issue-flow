# Codex Marketplace 与 Plugin 发现机制

本文档记录 Codex 中本地 marketplace 的发现链路：marketplace 如何定义、Codex 如何识别 marketplace、以及 Codex 如何继续识别其中的插件并加载插件内容。文中的 `issue-flow` 仅作为示例插件。

在 Codex 中，本地 marketplace 主要有两条常见路径：

- personal marketplace：`~/.agents/plugins/marketplace.json`，这是默认推荐路径
- repo marketplace：`$REPO_ROOT/.agents/plugins/marketplace.json`，适合只在当前仓库中暴露插件

## 目录结构

按 `issue-flow` 当前推荐的 personal marketplace 路径，相关文件大致如下：

```text
~/
├── .agents/
│   └── plugins/
│       └── marketplace.json          # 用户级 marketplace 定义
└── .codex/
    └── plugins/
        └── issue-flow/               # 本地插件源码目录（脚本 copy 或 symlink 生成）
            ├── .codex-plugin/
            │   └── plugin.json       # Codex 插件清单
            ├── skills/
            ├── hooks/
            ├── agents/
            ├── docs/
            └── ...
```

如果使用 repo marketplace，则相关文件大致如下：

```text
issue-flow/
├── .agents/plugins/marketplace.json  # 仓库级 marketplace 定义
└── .codex-plugin/plugin.json         # 插件 bundle manifest
```

两条路径的作用不同：

- `~/.agents/plugins/marketplace.json`：用户级 marketplace，适合个人长期使用、跨仓库可见
- `$REPO_ROOT/.agents/plugins/marketplace.json`：仓库级 marketplace，只在当前仓库打开 Codex 时可见

## 1. Marketplace 的定义

### Personal marketplace 文件

默认推荐路径是 personal marketplace，由 `~/.agents/plugins/marketplace.json` 定义。

`scripts/install-codex.sh` 会把它写成类似下面的结构：

```json
{
  "name": "codex-personal-plugins",
  "interface": {
    "displayName": "Personal Plugins"
  },
  "plugins": [
    {
      "name": "issue-flow",
      "source": {
        "source": "local",
        "path": "./.codex/plugins/issue-flow"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
```

关键字段：

| 字段                      | 说明                                                                            |
| ------------------------- | ------------------------------------------------------------------------------- |
| `name`                    | marketplace 内部标识。当前 personal 路线用 `codex-personal-plugins`             |
| `interface.displayName`   | Codex UI 中展示的 marketplace 名称。当前 personal 路线显示为 `Personal Plugins` |
| `plugins[]`               | 该 marketplace 暴露的插件列表                                                   |
| `plugins[].name`          | 插件标识，这里是 `issue-flow`                                                   |
| `plugins[].source.source` | 插件来源类型。当前是 `local`                                                    |
| `plugins[].source.path`   | 插件源码目录路径。这里指向 `~/.codex/plugins/issue-flow`                        |

### Repo marketplace 文件

如果不想写用户目录，也可以只维护仓库内的 `$REPO_ROOT/.agents/plugins/marketplace.json`。

`issue-flow` 仓库当前就带了一份 repo marketplace：

```json
{
  "name": "issue-flow-marketplace",
  "interface": {
    "displayName": "Issue Flow Plugins"
  },
  "plugins": [
    {
      "name": "issue-flow",
      "source": {
        "source": "local",
        "path": "./"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
```

这里的 `path: "./"` 指向仓库根目录，因此 Codex 可以直接把当前仓库视为插件源码位置。

### 为什么脚本叫“注册插件”

对 Codex 这条路径来说，“注册插件”并不是调用独立 API，而是完成下面两步：

1. 准备插件目录 `~/.codex/plugins/issue-flow`
2. 把该目录写进 `~/.agents/plugins/marketplace.json` 的 `plugins[]`

只要这条记录存在，Codex 就能在该 marketplace 下发现 `issue-flow`。

## 2. Codex 如何识别 Marketplace

Codex 会把每个 marketplace 文件都视为一个可选 source。对 `issue-flow` 而言，常见 source 有两种：

- personal marketplace：`~/.agents/plugins/marketplace.json`
- repo marketplace：`$REPO_ROOT/.agents/plugins/marketplace.json`

无论是哪一种，Codex 的识别逻辑都可以理解为：

1. 读取某个 marketplace.json
2. 把这个 JSON 文档当作一个 marketplace 定义
3. 读取其中的 `name` 和 `interface.displayName`
4. 在插件 UI 中展示该 marketplace
5. 遍历 `plugins[]`，把每个插件条目作为可安装或可启用插件

对 `issue-flow` 而言，marketplace 名字和插件列表都直接来自对应的 marketplace 文件。

## 3. Codex 如何识别 Marketplace 里的插件

当 Codex 读取到 `plugins[]` 里的某个条目后，会继续看它的 `source`。

personal marketplace 路径下，`issue-flow` 当前使用的是：

```json
{
  "source": {
    "source": "local",
    "path": "./.codex/plugins/issue-flow"
  }
}
```

这表示：

- 插件来源是本地目录，不是远程仓库
- 目标目录是 `~/.codex/plugins/issue-flow`

随后 Codex 会把这个目录当作插件根目录，并继续寻找其中的插件 manifest。

repo marketplace 路径下，当前使用的是：

```json
{
  "source": {
    "source": "local",
    "path": "./"
  }
}
```

这表示插件根目录就是当前仓库根目录。

## 4. Codex 如何识别插件根目录

插件根目录能否被当作 Codex 插件，取决于其中是否存在 `.codex-plugin/plugin.json`。

`issue-flow` 的 manifest 位于：

- [../.codex-plugin/plugin.json](../.codex-plugin/plugin.json)

当前内容的关键部分如下：

```json
{
  "name": "issue-flow",
  "version": "1.0.0",
  "skills": "./skills/",
  "interface": {
    "displayName": "Issue Flow"
  }
}
```

关键字段：

| 字段          | 说明                    |
| ------------- | ----------------------- |
| `name`        | 插件内部标识            |
| `version`     | 插件版本                |
| `skills`      | skill 目录入口          |
| `interface.*` | UI 展示文案、能力说明等 |

所以，marketplace 条目只能告诉 Codex“插件在哪里”；真正告诉 Codex“这个目录里有哪些组件可加载”的，是 `.codex-plugin/plugin.json`。

## 5. 插件内容如何继续被加载

当 Codex 确认插件目录是合法插件根目录后，会按 `.codex-plugin/plugin.json` 里的路径继续装载组件。

以 `issue-flow` 为例：

- `skills: "./skills/"` 指向 skills 目录
- Codex hooks 不在 plugin manifest 中声明，而是通过 `.codex/config.toml` 开启，并从同层的 `.codex/hooks.json` 自动发现

对应到仓库结构：

```text
issue-flow/
├── .codex-plugin/plugin.json
├── .codex/
│   ├── config.toml
│   └── hooks.json
├── skills/
│   ├── issue-flow/SKILL.md
│   ├── issue-plan/SKILL.md
│   └── ...
├── hooks/
│   ├── session-start
│   └── state-transition-guard
└── agents/
```

personal marketplace 路径的加载链路：

```text
~/.agents/plugins/marketplace.json
  → plugins[].source.path = ~/.codex/plugins/issue-flow
  → ~/.codex/plugins/issue-flow/.codex-plugin/plugin.json
  → skills/ 等插件内容
  → ~/.codex/plugins/issue-flow/.codex/config.toml
  → ~/.codex/plugins/issue-flow/.codex/hooks.json
```

repo marketplace 路径的加载链路：

```text
$REPO_ROOT/.agents/plugins/marketplace.json
  → plugins[].source.path = ./
  → $REPO_ROOT/.codex-plugin/plugin.json
  → skills/ 等插件内容
  → $REPO_ROOT/.codex/config.toml
  → $REPO_ROOT/.codex/hooks.json
```

## 6. `scripts/install-codex.sh` 到底做了什么

个人安装脚本 [../scripts/install-codex.sh](../scripts/install-codex.sh) 主要做三件事：

1. 创建目录 `~/.codex/plugins/` 与 `~/.agents/plugins/`
2. 将当前仓库复制或链接到 `~/.codex/plugins/issue-flow`
3. 生成或更新 `~/.agents/plugins/marketplace.json`

其中第 3 步并不是简单覆盖整个插件列表。脚本会：

1. 读取现有 `marketplace.json`
2. 解析其中的 `plugins[]`
3. 保留其他插件条目
4. 删除旧的 `issue-flow` 条目
5. 写回新的 `issue-flow` 条目

因此，`issue-flow` 的安装脚本可以理解为“维护 personal marketplace 里的一个插件条目”。

如果使用纯 repo marketplace 路线，则不需要运行这个脚本。

操作方式是：

1. 在当前仓库中打开 Codex
2. 确认 `Superpowers` 已在 `OpenAI Curated` 中安装或启用
3. 打开插件目录
4. 选择 `Issue Flow Plugins`
5. 安装或启用 `issue-flow`

## 7. OpenAI Curated 与本地 Marketplace 的关系

当前推荐安装方式里，Codex 中会同时出现两类来源：

- `OpenAI Curated`：用于安装或启用 `Superpowers`
- `Personal Plugins`：用于安装或启用 personal marketplace 下的本地 `issue-flow`

两者不是同一种来源：

- `OpenAI Curated` 是 Codex 自带或官方提供的插件来源
- `Personal Plugins` 是 `~/.agents/plugins/marketplace.json` 定义出来的用户级 marketplace

这也是为什么 `scripts/install-codex.sh` 只负责 `issue-flow`，不会去安装 `Superpowers`。

## 8. 推荐用法

对 `issue-flow` 当前仓库，推荐顺序是：

1. 优先使用 personal marketplace 路线
2. 如果只是临时在当前仓库里测试或开发，可直接使用 repo marketplace 路线

选择 personal marketplace 时：

- 运行 `bash scripts/install-codex.sh`
- 插件会出现在 `Personal Plugins`
- 该 source 对你个人是跨仓库可见的

选择 repo marketplace 时：

- 不需要安装脚本
- 直接在当前仓库打开 Codex
- 通过仓库内的 `.agents/plugins/marketplace.json` 暴露 `issue-flow`

## 9. 对 issue-flow 的实际结论

如果只看推荐的 personal marketplace 路径，可以把发现机制简化成一句话：

> `scripts/install-codex.sh` 先把仓库放进 `~/.codex/plugins/issue-flow`，再把这个路径登记到 `~/.agents/plugins/marketplace.json`，Codex 因此能在 `Personal Plugins` 下发现 `issue-flow`，随后再通过 `.codex-plugin/plugin.json` 加载插件内容。

如果只看 repo marketplace 路径，也可以简化成一句话：

> Codex 在当前仓库读取 `.agents/plugins/marketplace.json`，发现 `issue-flow` 指向仓库根目录，再通过 `.codex-plugin/plugin.json` 加载插件内容。

对于当前仓库和当前安装方式，这两条路径就是 `issue-flow` 在 Codex 中的实际发现链路。
