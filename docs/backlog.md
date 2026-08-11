# Backlog（暂缓项）

> 工程质量重构（Phase 1-4 + 二轮补做 + 三轮黄色项）已完成。
> 剩余唯一暂缓项：Q12 的 deep-link（路由集中已先行完成）。

## 已解决（历史记录）

- ~~T7 版本号硬编码~~：`lib/version.dart` 由 `tool/gen_version.dart` 生成
  （读 pubspec.yaml 单一事实源），about 页与测试均引用生成常量。
- ~~Q3 流式 UI 批处理~~：`lib/utils/stream_flusher.dart` + 5 个单测。
- ~~Q2 全部~~：`confirm_dialog.dart`（11 处）、`settings_tiles.dart`（3 屏）、
  `app_snackbar.dart`（6 屏）、`model_resolver.dart`（3 处）、
  `focus_utils.dart`（21 处）。
- ~~T6 测试目录镜像~~：services_test/features_test/ui_pages_test 拆 13 文件；
  三轮完成全部 36 个测试文件按 lib 子目录镜像
  （controllers/db/models/routes/screens/services/{chat,protocol,mcp,export,
  sync,web_search}/theme/utils/widgets/regression），
  CWD 参照文件（tiktoken_reference*.json）留在 test/ 根。
- ~~Q10 主题 hex 收敛~~：`AppColors` 全量常量提取（浅色/深色/OLED 三套
  surface 系列、onSurface、outline、shadow），`statusSuccess=success`、
  `defaultAccent` 删除（无引用）；`rg "0xFF" lib/theme` 仅 AppColors 块，
  screens/widgets 零裸 hex。
- ~~Q12 路由集中（路由表部分）~~：`lib/routes/app_routes.dart` 收敛全部
  22 处 `MaterialPageRoute`（类型化工厂 + `test/routes/` 参数透传测试），
  REQ-027 导航只需改这一处。

## REQ-027 关联：Deep-link（Q12 余项）

路由集中已完成；deep-link（`nona://` scheme 直达）仍需内嵌服务器
基础设施，与 REQ-027 一并实施。

## 其他候选

- `Logger` 构造注入（`Logger({enabled})`）：Dart 不允许静态/实例同名
  成员，现有 `setEnabled` 已满足测试需求，保持静态 API。
- `AppHttpClient` 底层 `http.Client` 构造注入：`overrideForTesting` 已覆盖
  测试替换；连接池实例注入留待需要多客户端场景。
- ChatController 的 DI 树注册：回调与宿主生命周期（home setState）绑定，
  保持宿主持有（服务经 DI 注入），不迁移到 Provider 树。
