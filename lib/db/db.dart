/// sqlite3 条件导出：io 平台走真实 sqlite3；Web 平台用 [Database]/[Row]
/// 存根（服务层在 Web 上 open() 返回 null 提前返回，存根不会被调用，
/// 仅保证编译通过）。
library;

export 'package:sqlite3/sqlite3.dart'
    if (dart.library.js_interop) 'db_stub.dart';
