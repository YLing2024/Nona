/// 平台环境检测（条件导出）。
library;

export 'env_io.dart' if (dart.library.js_interop) 'env_web.dart';
