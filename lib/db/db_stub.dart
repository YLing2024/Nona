/// Web 平台 sqlite3 存根：仅保证编译通过。
///
/// 实际运行中 NonaDatabase.open() 在 Web 返回 null，服务层提前返回，
/// 以下类型不会被调用；任何直接调用都会抛 [UnsupportedError]。
library;

/// 顶层 `sqlite3` 入口存根（与 io 包同名对象对齐）。
Sqlite3 get sqlite3 => throw UnsupportedError(
  'sqlite3 is not available on this platform',
);

/// sqlite3 顶层对象存根。
class Sqlite3 {
  Sqlite3._();

  Database open(String path, [OpenMode mode = OpenMode.readWriteCreate]) =>
      throw UnsupportedError('sqlite3 is not available on this platform');

  Database openInMemory() =>
      throw UnsupportedError('sqlite3 is not available on this platform');
}

/// 打开模式。
enum OpenMode {
  readOnly,
  readWrite,
  readWriteCreate,
}

/// sqlite3 数据库存根。
class Database {
  Database._();

  List<Row> select(String sql, [List<Object?> parameters = const []]) =>
      throw UnsupportedError('sqlite3 is not available on this platform');

  void execute(String sql, [List<Object?> parameters = const []]) =>
      throw UnsupportedError('sqlite3 is not available on this platform');

  void dispose() {}
}

/// 查询结果行存根。
class Row {
  Row._();

  Object? operator [](String name) => null;

  Object? columnAt(int index) => null;
}

/// 兼容 sqlite3 的错误类型。
class SqliteException implements Exception {
  final int resultCode;
  final String message;

  SqliteException(this.resultCode, this.message);

  @override
  String toString() => 'SqliteException($resultCode): $message';
}
