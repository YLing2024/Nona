import 'dart:io';

import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../platform/env.dart' show isFlutterTest;
import '../platform/fs.dart' show pathSeparator;
import '../utils/logger.dart';
import 'nona_app_database.dart';

NonaAppDatabase? _opened;
Future<NonaAppDatabase?>? _opening;

/// io 平台实现：文件库（`<support>/nona.db`）→ 内存库降级。
///
/// 打开结果按 Future 记忆化（并发首调共享同一次打开，避免竞态分叉到
/// 文件存储）；测试环境（isFlutterTest）不记忆化——每次调用打开全新
/// 内存库，与旧 NonaDatabase 的「每实例独立内存库」测试语义一致。
Future<NonaAppDatabase?> openNonaDatabase({bool forceMemory = false}) {
  if (isFlutterTest) return _openOnce(forceMemory: true);
  if (_opened != null) return Future.value(_opened);
  return _opening ??= _openOnce(forceMemory: forceMemory);
}

Future<NonaAppDatabase?> _openOnce({required bool forceMemory}) async {
  NonaAppDatabase db;
  try {
    if (isFlutterTest || forceMemory) {
      throw StateError('测试环境，使用内存数据库');
    }
    final support = await getApplicationSupportDirectory();
    final dbPath = '${support.path}$pathSeparator${'nona.db'}';
    final fresh = !File(dbPath).existsSync();
    db = NonaAppDatabase(NativeDatabase(File(dbPath)));
    db.wasFresh = fresh;
  } catch (_) {
    // 无插件环境（测试）/打开失败：内存数据库
    try {
      db = NonaAppDatabase(NativeDatabase.memory());
      db.wasFresh = false;
    } catch (e) {
      Logger.warn('db', 'SQLite 不可用，回退文件存储');
      Logger.error('db', '打开数据库失败', e);
      _opening = null;
      return null;
    }
  }
  try {
    // 首次查询触发迁移；确保默认知识库存在
    await db.ensureDefaultLibrary();
  } catch (e) {
    Logger.error('db', '数据库初始化失败', e);
  }
  if (!isFlutterTest) _opened = db;
  return db;
}

/// 测试辅助：重置单例（下次调用重新打开内存库）。
void resetNonaDatabaseForTest() {
  _opened = null;
  _opening = null;
}
