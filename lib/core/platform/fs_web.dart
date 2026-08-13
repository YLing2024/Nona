/// 文件系统访问（Web 版）：Web 无本地文件系统。
library;

/// 路径分隔符（Web 恒用 /）。
String get pathSeparator => '/';

/// Web 平台无本地文件，恒 false。
bool fileExists(String path) => false;

/// 恒 null。
Future<String?> readTextFile(String path) async => null;

/// 无操作。
Future<void> writeTextFile(String path, String content) async {}
