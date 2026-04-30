# Bugfix-Flow 状态机

## 预阶段（可选 pending）

Bugfix-Flow 通常直接从输入进入 `bugfix-pick`。只有在 pick 前需要澄清或暂停时，才在源仓库根目录写入 `.bugfix-flow/pending.json`。

`pending.json` 不是正式状态机 state；正式状态机仍从目标 worktree 的 `picked` 开始。

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
