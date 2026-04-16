# PR 模板

```markdown
## 概述

{1-3 句话描述本次变更}

## 关联 Issue

Closes #<N>

## 变更内容

- [ ] {变更 1}
- [ ] {变更 2}
- [ ] ...

## 验收标准覆盖

- ✅ {验收标准 1} — 通过 {测试/代码路径}
- ✅ {验收标准 2} — 通过 {测试/代码路径}
- ⚠️ {未完全覆盖的标准} — {原因}

## 测试

- {测试方式 1}
- {测试方式 2}

## 注意事项

{升级指南、Breaking Changes、兼容性问题等；没有可写"无"}
```

附加规范：

- PR title 使用英文 Conventional Commits
- PR body 使用中文描述变更
- 关联 Issue 时使用 `Closes #<N>`
- 本地开发中的 commit 如需关联 Issue，使用 `Refs #<N>`，不要使用 `Closes/Fixes #<N>`

如果未能关联 Issue，省略"关联 Issue"和"验收标准覆盖"两个 section。
