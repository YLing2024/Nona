import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/chat_message.dart';
import '../../models/chat_options.dart';
import '../../models/chat_session.dart';
import '../../models/citation_source.dart';
import '../../services/document_extractor.dart' show ChatDocument;
import '../../services/search_service.dart';
import '../nona_app_database.dart';

/// 会话/消息 DAO：drift 类型安全读写，替代旧 `SessionPersistenceSqlite`
/// 的手写 SQL（会话表 + bigram 倒排索引）。
class SessionDao {
  final NonaAppDatabase db;

  SessionDao(this.db);

  // ---------------- 会话读写 ----------------

  /// 读取全部会话（含消息与压缩块）；无任何数据返回 null。
  Future<List<ChatSession>?> readAll() async {
    final rows = await (db.select(db.sessions)
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .get();
    if (rows.isEmpty) return null;
    final result = <ChatSession>[];
    for (final row in rows) {
      final session = await _sessionFromRow(row);
      if (session != null) result.add(session);
    }
    return result;
  }

  /// 全量保存（覆盖全部会话；事务内先清后写）。
  Future<void> writeAll(List<ChatSession> sessions) async {
    await db.transaction(() async {
      await db.delete(db.messageTokens).go();
      await db.delete(db.messages).go();
      await db.delete(db.sessions).go();
      for (var i = 0; i < sessions.length; i++) {
        await _insertSession(sessions[i], i);
      }
    });
  }

  /// 增量保存单个会话（保留原 sort_order，无则追加到末尾）。
  Future<void> writeSession(ChatSession session) async {
    await db.transaction(() async {
      final existing = await (db.select(db.sessions)
            ..where((t) => t.id.equals(session.id)))
          .get();
      final order = existing.isEmpty
          ? await _nextSortOrder()
          : existing.first.sortOrder;
      await _deleteSessionInternal(session.id);
      await _insertSession(session, order);
    });
  }

  /// 删除单个会话（级联删除消息/索引/压缩块）。
  Future<void> deleteSession(String id) async {
    await db.transaction(() async {
      await _deleteSessionInternal(id);
    });
  }

  /// 增量更新单条消息字段（B-06 流式 checkpoint 用）。
  ///
  /// 只更新非 null 字段，不重写整会话；消息定位按 (session_id,
  /// message_index)（消息 id 由两者派生）。
  Future<void> updateMessageIncremental({
    required String sessionId,
    required int messageIndex,
    String? content,
    String? reasoningContent,
    String? toolCallsJson,
    String? toolStepsJson,
    String? citationsJson,
    String? partsJson,
    String? streamingState,
    bool clearStreamingState = false,
    bool? interrupted,
    bool? failed,
    int? promptTokens,
    int? completionTokens,
    int? elapsedMs,
    String? providerName,
    String? modelId,
    int? sentAt,
  }) async {
    final values = MessagesCompanion(
      content: content == null ? const Value.absent() : Value(content),
      reasoningContent: reasoningContent == null
          ? const Value.absent()
          : Value(reasoningContent),
      toolCallsJson: toolCallsJson == null
          ? const Value.absent()
          : Value(toolCallsJson),
      toolStepsJson: toolStepsJson == null
          ? const Value.absent()
          : Value(toolStepsJson),
      citationsJson: citationsJson == null
          ? const Value.absent()
          : Value(citationsJson),
      partsJson: partsJson == null ? const Value.absent() : Value(partsJson),
      streamingState: clearStreamingState
          ? const Value(null)
          : streamingState == null
          ? const Value.absent()
          : Value(streamingState),
      interrupted: interrupted == null
          ? const Value.absent()
          : Value(interrupted),
      failed: failed == null ? const Value.absent() : Value(failed),
      promptTokens: promptTokens == null
          ? const Value.absent()
          : Value(promptTokens),
      completionTokens: completionTokens == null
          ? const Value.absent()
          : Value(completionTokens),
      elapsedMs: elapsedMs == null ? const Value.absent() : Value(elapsedMs),
      providerName: providerName == null
          ? const Value.absent()
          : Value(providerName),
      modelId: modelId == null ? const Value.absent() : Value(modelId),
      sentAt: sentAt == null ? const Value.absent() : Value(sentAt),
    );
    await (db.update(db.messages)
          ..where(
            (t) =>
                t.sessionId.equals(sessionId) &
                t.messageIndex.equals(messageIndex),
          ))
        .write(values);
  }

  /// 更新消息 bigram 索引（替换单条消息的全部 token）。
  Future<void> reindexMessage({
    required String sessionId,
    required String messageId,
    required String content,
  }) async {
    await db.transaction(() async {
      await (db.delete(db.messageTokens)
            ..where(
              (t) =>
                  t.sessionId.equals(sessionId) & t.messageId.equals(messageId),
            ))
          .go();
      final tokens = bigrams(content.toLowerCase());
      if (tokens.isEmpty) return;
      await db.batch((batch) {
        batch.insertAll(
          db.messageTokens,
          [
            for (var p = 0; p < tokens.length; p++)
              MessageTokensCompanion.insert(
                token: tokens[p],
                sessionId: sessionId,
                messageId: messageId,
                position: p,
              ),
          ],
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  // ---------------- 全文搜索（bigram 倒排） ----------------

  /// 搜索消息内容与会话标题；命中返回带会话/索引/匹配位置的结果。
  Future<List<MessageSearchHit>> search(String query, {int limit = 50}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    // 标题命中优先
    final titleRows = await (db.selectOnly(db.sessions)
          ..addColumns([db.sessions.id])
          ..where(db.sessions.title.lower().like('%$q%')))
        .get();
    final titleIds = {for (final r in titleRows) r.read(db.sessions.id)!};

    final hits = <MessageSearchHit>[];
    if (q.length >= 2) {
      final tokens = bigrams(q);
      final tokenRows = await (db.selectOnly(db.messageTokens)
            ..addColumns([
              db.messageTokens.messageId,
              db.messageTokens.messageId.count(),
            ])
            ..where(db.messageTokens.token.isIn(tokens))
            ..groupBy([db.messageTokens.messageId])
            ..orderBy([
              OrderingTerm.desc(db.messageTokens.messageId.count()),
            ])
            ..limit(limit * 4))
          .get();
      for (final row in tokenRows) {
        if (hits.length >= limit) break;
        final messageId = row.read(db.messageTokens.messageId)!;
        final hit = await _hitFromMessageId(messageId, q);
        if (hit != null) hits.add(hit);
      }
      // 标题命中但无消息命中：定位最早用户消息
      for (final sid in titleIds) {
        if (hits.any((h) => h.session.id == sid)) continue;
        final sessionRows = await (db.select(db.sessions)
              ..where((t) => t.id.equals(sid)))
            .get();
        if (sessionRows.isEmpty) continue;
        final session = await _sessionFromRow(sessionRows.first);
        if (session == null) continue;
        final idx = session.messages.indexWhere((m) => m.role == 'user');
        final target = idx >= 0 ? idx : 0;
        if (session.messages.isNotEmpty && session.messages.length > target) {
          hits.add(
            MessageSearchHit(
              session: session,
              messageIndex: target,
              message: session.messages[target],
              matchStart: 0,
            ),
          );
        }
      }
    } else {
      // 单字符查询：直接子串扫描
      final sessions = await readAll();
      for (final s in sessions ?? const <ChatSession>[]) {
        for (var i = 0; i < s.messages.length; i++) {
          if (hits.length >= limit) break;
          final pos = s.messages[i].content.toLowerCase().indexOf(q);
          if (pos >= 0) {
            hits.add(
              MessageSearchHit(
                session: s,
                messageIndex: i,
                message: s.messages[i],
                matchStart: pos,
              ),
            );
          }
        }
        if (hits.length >= limit) break;
      }
    }

    // 排序：标题命中优先 → 更新时间倒序
    hits.sort((a, b) {
      final aTitle = titleIds.contains(a.session.id);
      final bTitle = titleIds.contains(b.session.id);
      if (aTitle != bTitle) return aTitle ? -1 : 1;
      return b.session.updatedAt.compareTo(a.session.updatedAt);
    });
    return hits;
  }

  Future<MessageSearchHit?> _hitFromMessageId(
    String messageId,
    String q,
  ) async {
    final msgRows = await (db.select(db.messages)
          ..where((t) => t.id.equals(messageId)))
        .get();
    if (msgRows.isEmpty) return null;
    final row = msgRows.first;
    final sessionRows = await (db.select(db.sessions)
          ..where((t) => t.id.equals(row.sessionId)))
        .get();
    if (sessionRows.isEmpty) return null;
    final session = await _sessionFromRow(sessionRows.first);
    if (session == null || row.messageIndex >= session.messages.length) {
      return null;
    }
    final m = session.messages[row.messageIndex];
    final pos = m.content.toLowerCase().indexOf(q);
    if (pos < 0) return null;
    return MessageSearchHit(
      session: session,
      messageIndex: row.messageIndex,
      message: m,
      matchStart: pos,
    );
  }

  // ---------------- 内部 ----------------

  Future<int> _nextSortOrder() async {
    final row = await (db.selectOnly(db.sessions)
          ..addColumns([db.sessions.sortOrder.max()]))
        .get();
    final max = row.first.read(db.sessions.sortOrder.max()) ?? -1;
    return max + 1;
  }

  Future<void> _insertSession(ChatSession s, int order) async {
    await db.into(db.sessions).insertOnConflictUpdate(
      SessionsCompanion.insert(
        id: s.id,
        title: s.title,
        optionsJson: jsonEncode(s.options.toJson()),
        providerId: Value(s.providerId),
        modelId: Value(s.modelId),
        agentId: Value(s.agentId),
        pinned: Value(s.pinned),
        sortOrder: Value(order),
        createdAt: s.createdAt.millisecondsSinceEpoch,
        updatedAt: s.updatedAt.millisecondsSinceEpoch,
        summary: Value(s.summary),
        summaryTokens: Value(s.summaryTokens),
        memory: Value(s.memory),
        tagsJson: Value(s.tags.isEmpty ? null : jsonEncode(s.tags)),
        truncateIndex: Value(s.truncateIndex),
      ),
    );
    for (final block in s.compressedBlocks) {
      await db.into(db.compressedBlocks).insertOnConflictUpdate(
        CompressedBlocksCompanion.insert(
          id: '${s.id}:${block.id}',
          sessionId: s.id,
          startIndex: block.startIndex,
          endIndex: block.endIndex,
          summary: block.summary,
          messagesJson: Value(
            jsonEncode(block.messages.map((m) => m.toJson()).toList()),
          ),
          createdAt: block.createdAt.millisecondsSinceEpoch,
        ),
      );
    }
    final tokenRows = <MessageTokensCompanion>[];
    final messageRows = <MessagesCompanion>[];
    for (var i = 0; i < s.messages.length; i++) {
      final m = s.messages[i];
      messageRows.add(_messageCompanion(s.id, i, m));
      final tokens = bigrams(m.content.toLowerCase());
      for (var p = 0; p < tokens.length; p++) {
        tokenRows.add(
          MessageTokensCompanion.insert(
            token: tokens[p],
            sessionId: s.id,
            messageId: '${s.id}:$i',
            position: p,
          ),
        );
      }
    }
    await db.batch((batch) {
      batch.insertAll(
        db.messages,
        messageRows,
        mode: InsertMode.insertOrReplace,
      );
      batch.insertAll(
        db.messageTokens,
        tokenRows,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  MessagesCompanion _messageCompanion(
    String sessionId,
    int index,
    ChatMessage m,
  ) {
    return MessagesCompanion.insert(
      id: '$sessionId:$index',
      sessionId: sessionId,
      messageIndex: index,
      role: m.role,
      content: m.content,
      reasoningContent: Value(m.reasoningContent),
      imagesJson: Value(
        jsonEncode(m.images.map((img) => img.toJson()).toList()),
      ),
      documentsJson: Value(jsonEncode([
        for (final d in m.documents) {'name': d.name, 'text': d.text},
      ])),
      alternativesJson: Value(
        jsonEncode(m.alternatives.map((a) => a.toJson()).toList()),
      ),
      toolCallId: Value(m.toolCallId),
      toolCallsJson: Value(m.toolCallsJson),
      interrupted: Value(m.interrupted),
      failed: Value(m.failed),
      promptTokens: Value(m.promptTokens),
      completionTokens: Value(m.completionTokens),
      elapsedMs: Value(m.elapsedMs),
      providerName: Value(m.providerName),
      modelId: Value(m.modelId),
      sentAt: Value(m.sentAt?.millisecondsSinceEpoch),
      partsJson: Value(m.partsJson),
      citationsJson: Value(
        m.citations.isEmpty
            ? null
            : jsonEncode(m.citations.map((c) => c.toJson()).toList()),
      ),
      toolStepsJson: Value(m.toolStepsJson),
      streamingState: Value(m.streamingState),
    );
  }

  Future<void> _deleteSessionInternal(String sessionId) async {
    await (db.delete(db.messageTokens)
          ..where((t) => t.sessionId.equals(sessionId)))
        .go();
    await (db.delete(db.compressedBlocks)
          ..where((t) => t.sessionId.equals(sessionId)))
        .go();
    await (db.delete(db.messages)..where((t) => t.sessionId.equals(sessionId)))
        .go();
    await (db.delete(db.sessions)..where((t) => t.id.equals(sessionId))).go();
  }

  Future<ChatSession?> _sessionFromRow(SessionRow row) async {
    try {
      final options = ChatOptions.fromJson(
        jsonDecode(row.optionsJson) as Map<String, dynamic>,
      );
      final messageRows = await (db.select(db.messages)
            ..where((t) => t.sessionId.equals(row.id))
            ..orderBy([(t) => OrderingTerm.asc(t.messageIndex)]))
          .get();
      final messages = [for (final m in messageRows) _messageFromRow(m)];
      final blockRows = await (db.select(db.compressedBlocks)
            ..where((t) => t.sessionId.equals(row.id))
            ..orderBy([(t) => OrderingTerm.asc(t.startIndex)]))
          .get();
      final blocks = <CompressedBlock>[];
      for (final b in blockRows) {
        blocks.add(
          CompressedBlock(
            id: b.id,
            startIndex: b.startIndex,
            endIndex: b.endIndex,
            summary: b.summary,
            messages: (jsonDecode(b.messagesJson) as List<dynamic>)
                .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
                .toList(),
            createdAt: DateTime.fromMillisecondsSinceEpoch(b.createdAt),
          ),
        );
      }
      return ChatSession(
        id: row.id,
        title: row.title,
        options: options,
        providerId: row.providerId,
        modelId: row.modelId,
        agentId: row.agentId,
        pinned: row.pinned,
        messages: messages,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
        summary: row.summary,
        summaryTokens: row.summaryTokens,
        memory: row.memory,
        tags: _parseStringList(row.tagsJson),
        truncateIndex: row.truncateIndex,
        compressedBlocks: blocks,
      );
    } catch (e) {
      // 单条损坏跳过（对齐旧实现：不阻塞整体加载）
      return null;
    }
  }

  ChatMessage _messageFromRow(MessageRow m) => ChatMessage(
    role: m.role,
    content: m.content,
    reasoningContent: m.reasoningContent,
    images: _parseImages(m.imagesJson),
    documents: _parseDocuments(m.documentsJson),
    alternatives: _parseAlternatives(m.alternativesJson),
    toolCallId: m.toolCallId,
    toolCallsJson: m.toolCallsJson,
    interrupted: m.interrupted,
    failed: m.failed,
    promptTokens: m.promptTokens,
    completionTokens: m.completionTokens,
    elapsedMs: m.elapsedMs,
    providerName: m.providerName,
    modelId: m.modelId,
    sentAt: m.sentAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(m.sentAt!),
    citations: _parseCitations(m.citationsJson),
    partsJson: m.partsJson,
    toolStepsJson: m.toolStepsJson,
    streamingState: m.streamingState,
  );

  List<String> _parseStringList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<CitationSource> _parseCitations(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(CitationSource.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<ChatImage> _parseImages(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ChatImage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<ChatDocument> _parseDocuments(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          if (e is Map<String, dynamic>)
            ChatDocument(
              name: e['name'] as String? ?? '',
              text: e['text'] as String? ?? '',
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  List<ChatMessage> _parseAlternatives(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
