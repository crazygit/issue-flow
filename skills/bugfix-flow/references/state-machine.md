# Bugfix-Flow 状态机

## 持久化状态机（`.bugfix-flow/` 在 `bugfix-pick` 时创建）

```text
picked
  -> implementing
  -> ready
  -> finished
```

特殊回路：

- `implementing -> bugfix-verify -> ready`
- `implementing -> bugfix-verify(失败) -> implementing`
- `ready -> bugfix-implement -> implementing`

设计意图：

- `picked`：完成上下文收集、分支与 worktree 准备，但尚未开始改代码
- `implementing`：聚焦修复代码与补充必要测试，不引入完整计划阶段
- `ready`：验证通过后的暂停点，等待人工决定是否提交或继续补改
- `finished`：用户明确结束本轮 bugfix 会话，随后由 `bugfix-finish` 清理状态目录
