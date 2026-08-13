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

（2026-08-14，Windows 开发机，profile 模式 `build\windows\x64\runner\Profile\nona.exe`
两次冷启动取样；时间从进程内 `main()` 开始计时，不包含引擎/插件原生初始化。）

| 阶段 | 耗时 |
|---|---|
| dotenv + 设置加载 | 1ms / 0ms |
| 首帧（设置加载后重置计时） | 30ms / 29ms |

> 结论：进程内启动路径（dotenv → 设置 → runApp → 首帧）远低于 2s 目标；
> 冷启动大头在 Flutter 引擎与原生插件初始化（进程启动 → Dart 代码入口），
> 该段由平台层决定，未计入本表。Android 首帧达标数据待真机 profile 补录。

## 后续可做

- 预编译 drift schema（`NativeDatabase` + precompiled statements）。
- 桌面端 splash 期间预热 tiktoken。
