import '../models/chat_session.dart';
import 'search_service.dart';

/// 会话持久化的底层存储抽象。
///
/// 桌面/移动端由 SQLite 存储实现（会话/消息表 + bigram 搜索索引，
/// 失败时回退文件存储）；Web 端退化为 shared_preferences 全量存储。
abstract class SessionPersistence {
  /// 读取全部会话；无任何数据返回 null（调用方据此触发旧数据迁移）。
  Future<List<ChatSession>?> readAll();

  /// 全量保存（覆盖全部会话）。
  Future<void> writeAll(List<ChatSession> sessions);

  /// 增量保存单个会话（其余会话不受影响；实现可退化为全量）。
  Future<void> writeSession(ChatSession session);

  /// 删除单个会话。
  Future<void> deleteSession(String id);
}

/// 可选能力：基于索引的高效全文搜索（SQLite 实现提供；
/// 其余实现返回 null，由调用方回退内存全量扫描）。
abstract class IndexedSessionSearch {
  /// 按索引搜索消息内容；未命中返回空列表。
  Future<List<MessageSearchHit>> search(String query, {int limit = 50});
}
