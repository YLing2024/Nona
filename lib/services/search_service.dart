import '../models/chat_message.dart';
import '../models/chat_session.dart';

/// 高亮片段：一段文本及其是否命中关键词。
class SearchSpan {
  final String text;
  final bool isMatch;

  const SearchSpan(this.text, this.isMatch);
}

/// 一条消息命中结果。
class MessageSearchHit {
  final ChatSession session;
  final int messageIndex;
  final ChatMessage message;
  final int matchStart;

  const MessageSearchHit({
    required this.session,
    required this.messageIndex,
    required this.message,
    required this.matchStart,
  });

  /// 匹配位置所在的完整消息内容。
  String get matchText => message.content;

  /// 生成展示片段：匹配位置前后各保留 [radius] 字符，用省略号标记截断。
  String snippet({int radius = 40}) {
    final text = message.content;
    if (text.isEmpty) return '';
    final start = (matchStart - radius).clamp(0, text.length);
    final end = (matchStart + radius).clamp(0, text.length);
    final prefix = start > 0 ? '…' : '';
    final suffix = end < text.length ? '…' : '';
    return '$prefix${text.substring(start, end)}$suffix';
  }
}

/// 会话全文搜索服务。
///
/// - 大小写不敏感子串匹配；
/// - 同时搜索标题与消息正文；
/// - 标题命中优先排序，其余按会话更新时间倒序；
/// - 提供高亮片段切分供 UI 渲染。
class SearchService {
  /// 搜索全部会话；空查询返回空列表。
  static List<MessageSearchHit> search(
    List<ChatSession> sessions,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    // 标题命中的会话 id 集合（标题命中优先展示）
    final titleHit = <String>{};
    for (final s in sessions) {
      if (s.title.toLowerCase().contains(q)) titleHit.add(s.id);
    }

    final hits = <MessageSearchHit>[];
    for (final s in sessions) {
      var messageMatched = false;
      for (var i = 0; i < s.messages.length; i++) {
        final m = s.messages[i];
        final idx = m.content.toLowerCase().indexOf(q);
        if (idx < 0) continue;
        messageMatched = true;
        hits.add(
          MessageSearchHit(
            session: s,
            messageIndex: i,
            message: m,
            matchStart: idx,
          ),
        );
      }
      // 标题命中但消息未命中：产出指向最早用户消息的条目，保证会话可被找到
      if (!messageMatched && titleHit.contains(s.id)) {
        final idx = s.messages.indexWhere((m) => m.role == 'user');
        final target = idx >= 0 ? idx : (s.messages.isEmpty ? 0 : 0);
        if (s.messages.isNotEmpty) {
          final m = s.messages[target];
          hits.add(
            MessageSearchHit(
              session: s,
              messageIndex: target,
              message: m,
              matchStart: 0,
            ),
          );
        }
      }
    }

    hits.sort((a, b) {
      final aTitle = titleHit.contains(a.session.id);
      final bTitle = titleHit.contains(b.session.id);
      if (aTitle != bTitle) return aTitle ? -1 : 1;
      return b.session.updatedAt.compareTo(a.session.updatedAt);
    });
    return hits;
  }

  /// 将文本按关键词切分为高亮片段（大小写不敏感，全部命中段）。
  static List<SearchSpan> highlight(String text, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty || text.isEmpty) return [SearchSpan(text, false)];

    final spans = <SearchSpan>[];
    var pos = 0;
    final lower = text.toLowerCase();
    while (true) {
      final idx = lower.indexOf(q, pos);
      if (idx < 0) {
        if (pos < text.length) {
          spans.add(SearchSpan(text.substring(pos), false));
        }
        break;
      }
      if (idx > pos) {
        spans.add(SearchSpan(text.substring(pos, idx), false));
      }
      spans.add(SearchSpan(text.substring(idx, idx + q.length), true));
      pos = idx + q.length;
    }
    if (spans.isEmpty) return [SearchSpan(text, false)];
    return spans;
  }

  /// 标题是否命中查询（用于结果条目副标题标注）。
  static bool titleMatches(ChatSession session, String query) {
    final q = query.trim().toLowerCase();
    return q.isNotEmpty && session.title.toLowerCase().contains(q);
  }
}

/// 字符 bigram 切分；不足 2 字符返回空列表。
///
/// 用于 SQLite 倒排索引（中文/英文无需分词器，全平台一致）。
List<String> bigrams(String lowerText) {
  if (lowerText.length < 2) return const [];
  final tokens = <String>[];
  for (var i = 0; i < lowerText.length - 1; i++) {
    tokens.add(lowerText.substring(i, i + 2));
  }
  return tokens;
}
