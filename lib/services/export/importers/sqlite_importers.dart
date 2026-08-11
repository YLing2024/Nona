/// SQLite 导入器条件导出：io 平台含 RikkaHub/Kelivo 真实实现；
/// Web 平台用存根（matchesFile 恒 false，importSqlite 返回空）。
library;

export 'sqlite_importers_io.dart'
    if (dart.library.js_interop) 'sqlite_importers_web.dart';
