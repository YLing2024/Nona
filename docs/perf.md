# 性能记录（J-04 冷启动）

> 测量方式：profile 模式（`flutter run --profile`）观察 `[startup]` 日志。
> 目标：桌面冷启动→首帧 ≤2s、Android ≤2.5s。

## 已实施的优化

1. **网络日志恢复改非阻塞**：`main.dart` 中 `NetworkLogService.init()` 由
   `await` 改为 `unawaited`（首帧后异步执行，不再拖慢冷启动）。
2. **首帧打点**：`main()` 内 `Stopwatch` 记录各阶段耗时；
   `addPostFrameCallback` 输出「first frame at Xms」debug 日志。
3. **分级加载**：tiktoken 预加载 / 知识库迁移 / checkpoint 恢复 /
   恢复收敛 / 桌面基座 / 工作流调度均已在首帧前 `unawaited` 后台执行。
4. **会话懒加载**：`home_screen` 使用 `loadGuarded` 异步加载，
   首帧先渲染占位。

## 实测数据

（在 Windows 开发机 profile 模式补录后回填。）

| 阶段 | 耗时 |
|---|---|
| dotenv + 设置加载 | 待录 |
| 首帧 | 待录 |

## 后续可做

- 预编译 drift schema（`NativeDatabase` + precompiled statements）。
- 桌面端 splash 期间预热 tiktoken。
