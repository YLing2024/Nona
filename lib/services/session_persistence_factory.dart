import 'session_persistence.dart';
import 'session_persistence_io.dart'
    if (dart.library.js_interop) 'session_persistence_web.dart' as impl;

/// 创建默认的会话持久化实现（io / web 按平台自动选择）。
///
/// io 平台：SQLite（会话/消息表 + bigram 索引），SQLite 不可用时
/// 内部自动回退文件存储（再退化内存）。
SessionPersistence createSessionPersistence() => impl.createSessionPersistence();
