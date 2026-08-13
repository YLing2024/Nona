/// 文件系统访问（条件导出）。
library;

export 'fs_io.dart' if (dart.library.js_interop) 'fs_web.dart';
