# Commit Message 模板

## 消息格式

```
<Emoji> <type>(<scope>): <subject>（≤72 字符）

<optional body>

Refs #<N>
```

## 字段说明

- **header**：`<Emoji> <type>(<scope>): <subject>`，整行不超过 72 字符
  - `Emoji`：从映射表选取
  - `type`：从映射表选取（小写）
  - `scope`（可选）：变更影响的模块/组件（如 `auth`, `api`, `cli`），括号包裹
  - `subject`：简述变更内容，英文祈使句，首字母小写，句末不加句号
- **body**（可选）：详细说明变更动机和影响，与 header 之间空一行
- **footer**：当 `.issue-flow/issue.json` 存在时，添加 `Refs #<N>`（关联 Issue）

## Emoji + Type 映射表

| Emoji | Type | 用途 |
| ----- | ---- | ---- |
| ✨ | `feat` | 新功能 |
| 🐛 | `fix` | Bug 修复 |
| 📝 | `docs` | 文档变更 |
| 💄 | `style` | 格式/样式 |
| ♻️ | `refactor` | 重构 |
| ⚡️ | `perf` | 性能优化 |
| ✅ | `test` | 测试 |
| 🔧 | `chore` | 工具/配置 |
| 🚀 | `ci` | CI/CD |
| 🗑️ | `revert` | 回滚 |
| 🚨 | `fix` | 修复编译器/Linter 警告 |
| 🔒️ | `fix` | 修复安全问题 |
| 🏗️ | `refactor` | 架构变更 |
| 📦️ | `chore` | 编译文件/包 |
| ➕ | `chore` | 添加依赖 |
| ➖ | `chore` | 移除依赖 |
| 🏷️ | `feat` | 类型定义 |
| 💥 | `feat` | 破坏性变更 |
| 🚧 | `wip` | 进行中 |
| 🚑️ | `fix` | 关键热修复 |

## 示例

### 带 scope 的 feat + Issue 关联

```
✨ feat(auth): add email login support

Refs #42
```

### 带 body 的 fix

```
🐛 fix(api): handle null response from user endpoint

The /api/user endpoint could return null when the user was
deleted mid-session, causing a 500 error.

Refs #17
```

### 不带 footer 的 refactor

```
♻️ refactor(cli): extract argument parsing into separate module
```

### 带破坏性变更的 feat

```
💥 feat(db): switch from MySQL to PostgreSQL

Refs #88
```
