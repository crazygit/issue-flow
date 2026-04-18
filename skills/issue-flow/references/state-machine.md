# Issue-Flow 状态机

当前状态流转如下：

```text
none
  -> brainstorm
  -> picked
  -> researching
  -> planned
  -> implementing
  -> committing
  -> pring
  -> reviewing
  -> finished
```

特殊回路：

- `implementing -> issue-verify -> committing`
- `implementing -> issue-verify(失败) -> implementing`
- `reviewing -> issue-verify -> reviewing`
- `reviewing -> issue-implement -> implementing`

设计意图：

- `researching`：在计划前显式阅读代码库和约束，避免直接从 Issue 跳到实现计划
- `reviewing`：PR 已创建后的反馈窗口，用于处理 review comments、CI 修复和补充验证
- `finished`：仅表示用户明确决定收尾，随后由 `issue-finish` 清理会话
