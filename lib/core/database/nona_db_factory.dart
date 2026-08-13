import 'nona_app_database.dart';
import 'nona_db_factory_io.dart'
    if (dart.library.js_interop) 'nona_db_factory_web.dart' as impl;

/// 打开 Nona 主数据库（drift）。
///
/// - io 平台：文件库（`<support>/nona.db`），失败降级内存库；
/// - Web：返回 null（保持既有 *_web.dart 回退链，WasmDatabase 接入后续启用）；
/// - 结果记忆化：并发调用共享同一次打开；[wasFresh] 语义见 [NonaAppDatabase]。
Future<NonaAppDatabase?> openNonaDatabase({bool forceMemory = false}) =>
    impl.openNonaDatabase(forceMemory: forceMemory);

/// 测试辅助：重置数据库单例。
void resetNonaDatabaseForTest() => impl.resetNonaDatabaseForTest();
