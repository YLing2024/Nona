import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nona_chat/features/chat/controllers/attachment_manager.dart';
import 'package:nona_chat/features/chat/controllers/chat_run_orchestrator.dart';
import 'package:nona_chat/features/chat/controllers/context_builder.dart';
import 'package:nona_chat/features/chat/controllers/message_ops.dart';
import 'package:nona_chat/core/services/session_manager.dart';
import 'package:nona_chat/l10n/app_localizations.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_options.dart';
import 'package:nona_chat/core/models/chat_provider.dart';
import 'package:nona_chat/core/models/chat_session.dart';
import 'package:nona_chat/core/services/chat_service.dart';
import 'package:nona_chat/core/services/provider_service.dart';
import 'package:nona_chat/core/services/session_persistence.dart';
import 'package:nona_chat/core/services/session_service.dart';
import 'package:nona_chat/core/services/settings_service.dart';
import 'package:nona_chat/core/services/title_generator.dart';

/// 内存版会话持久化（避免测试触碰 SQLite/文件/平台通道）。
class FakeSessionPersistence implements SessionPersistence {
  List<ChatSession>? stored;
  int writes = 0;
  int writeSessionCalls = 0;

  @override
  Future<List<ChatSession>?> readAll() async => stored;

  @override
  Future<void> writeAll(List<ChatSession> sessions) async {
    stored = List.of(sessions);
    writes++;
  }

  @override
  Future<void> writeSession(ChatSession session) async {
    writeSessionCalls++;
    final current = stored ?? [];
    final index = current.indexWhere((s) => s.id == session.id);
    final updated = List<ChatSession>.of(current);
    if (index >= 0) {
      updated[index] = session;
    } else {
      updated.add(session);
    }
    stored = updated;
  }

  @override
  Future<void> deleteSession(String id) async {
    stored?.removeWhere((s) => s.id == id);
  }
}

ChatSession makeSession(String id, {String title = '会话', int messages = 0}) {
  return ChatSession(
    id: id,
    title: title,
    options: const ChatOptions(systemPrompt: '提示词'),
    messages: List.generate(
      messages,
      (i) => ChatMessage(role: i.isEven ? 'user' : 'assistant', content: '消息 $i'),
    ),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContextBuilder', () {
    test('estimateTokens 大于 0 且缓存命中返回相同值', () {
      final builder = ContextBuilder();
      final session = makeSession('s1', messages: 2);
      final tokens = builder.estimateTokens(session, tokenVersion: 1);
      expect(tokens, greaterThan(0));
      expect(builder.estimateTokens(session, tokenVersion: 1), tokens);
    });

    test('estimateTokens 版本号变化后重算', () {
      final builder = ContextBuilder();
      final session = makeSession('s1', messages: 2);
      final before = builder.estimateTokens(session, tokenVersion: 1);
      session.messages.add(ChatMessage(role: 'user', content: '加一条消息'));
      final after = builder.estimateTokens(session, tokenVersion: 2);
      expect(after, greaterThan(before));
    });

    test('contextLimitFor 显式配置优先于能力表', () {
      final builder = ContextBuilder();
      final session = makeSession('s1')
        ..options = const ChatOptions(maxContextTokens: 4096);
      expect(builder.contextLimitFor(session), 4096);
    });

    test('contextLimitFor 未显式配置时按能力表推断', () {
      final builder = ContextBuilder();
      final session = makeSession('s1')..modelId = 'm1';
      expect(builder.contextLimitFor(session), isNull);
    });

    test('sessionUsage 累加各消息用量', () {
      final builder = ContextBuilder();
      final session = makeSession('s1')
        ..messages.addAll([
          ChatMessage(role: 'user', content: 'a', promptTokens: 10),
          ChatMessage(role: 'assistant', content: 'b', completionTokens: 20),
        ]);
      final (prompt, completion) = builder.sessionUsage(session);
      expect(prompt, 10);
      expect(completion, 20);
    });

    test('trimContext 超限时移除最早消息', () {
      final builder = ContextBuilder();
      final session = makeSession('s1', messages: 5)
        ..options = const ChatOptions(maxContextTokens: 25, autoTrim: true);
      final removed = builder.trimContext(session);
      expect(removed, greaterThan(0));
      expect(session.messages.first.role, 'user');
    });

    test('trimContext 关闭自动裁剪时不删除', () {
      final builder = ContextBuilder();
      final session = makeSession('s1', messages: 5)
        ..options = const ChatOptions(maxContextTokens: 25, autoTrim: false);
      final before = session.messages.length;
      expect(builder.trimContext(session), 0);
      expect(session.messages.length, before);
    });
  });

  group('SessionManager', () {
    late FakeSessionPersistence persistence;
    late SessionManager manager;
    int notifies = 0;
    int bumps = 0;
    AppSettings currentSettings = const AppSettings();
    List<ChatProvider> currentProviders = [];

    SessionManager build() {
      return SessionManager(
        sessionService: SessionService(persistence: persistence),
        defaultTitle: () => '新对话',
        settings: () => currentSettings,
        providers: () => currentProviders,
        isLoading: () => false,
        onStateChanged: () => notifies++,
        bumpTokenVersion: () => bumps++,
        onSnack: (_) {},
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      persistence = FakeSessionPersistence();
      notifies = 0;
      bumps = 0;
      currentSettings = const AppSettings();
      currentProviders = [];
      manager = build();
    });

    tearDown(() => manager.dispose());

    test('load 无数据时创建默认会话并持久化', () async {
      await manager.load(title: '新对话');
      expect(manager.sessions, hasLength(1));
      expect(manager.currentSessionId, manager.sessions.first.id);
      expect(manager.sessions.first.title, '新对话');
      expect(persistence.stored, isNotNull);
    });

    test('persist 500ms 防抖：连续多次合并为一次增量落盘', () async {
      await manager.load(title: '新对话');
      final before = persistence.writeSessionCalls;
      await manager.persist();
      await manager.persist();
      await manager.persist();
      expect(
        persistence.writeSessionCalls,
        before,
        reason: '防抖窗口内不应落盘',
      );
      await Future.delayed(const Duration(milliseconds: 600));
      expect(
        persistence.writeSessionCalls,
        before + 1,
        reason: '防抖到期后批量增量落盘一次',
      );
      expect(persistence.writes, 1, reason: 'load 时全量写一次，此后只走增量写');
    });

    test('flushNow 取消防抖并立即落盘', () async {
      await manager.load(title: '新对话');
      final session = manager.sessions.first;
      session.title = '改了标题';
      await manager.persist();
      await manager.flushNow();
      expect(persistence.writeSessionCalls, greaterThan(0));
      expect(persistence.stored!.single.title, '改了标题');
    });

    test('deleteSession 增量删除：落盘后不复活', () async {
      await manager.load(title: '新对话');
      await manager.newSession();
      final deleted = manager.sessions.first;
      await manager.deleteSession(deleted);
      await manager.flushNow();
      expect(
        persistence.stored!.map((s) => s.id),
        isNot(contains(deleted.id)),
        reason: '删除必须显式落盘，增量写不会重写已删除会话',
      );
    });

    test('匿名模式下 persist 不落盘', () async {
      await manager.load(title: '新对话');
      final before = persistence.writeSessionCalls;
      manager.toggleAnonymous();
      await manager.persist();
      await manager.flushNow();
      expect(persistence.writeSessionCalls, before);
    });

    test('load 读取已有会话并选中第一个', () async {
      persistence.stored = [makeSession('a'), makeSession('b')];
      await manager.load(title: '新对话');
      expect(manager.sessions, hasLength(2));
      expect(manager.currentSessionId, 'a');
    });

    test('newSession 插入到列表头部并切换', () async {
      await manager.load(title: '新对话');
      final first = manager.sessions.first;
      await manager.newSession();
      expect(manager.sessions, hasLength(2));
      expect(manager.sessions.first, isNot(same(first)));
      expect(manager.currentSessionId, manager.sessions.first.id);
      expect(bumps, greaterThan(0));
      expect(notifies, greaterThan(0));
    });

    test('匿名模式下 persist 不持久化', () async {
      await manager.load(title: '新对话');
      final writesBefore = persistence.writes;
      manager.toggleAnonymous();
      expect(manager.isAnonymous, isTrue);
      expect(manager.currentSession, isNotNull);
      await manager.persist();
      expect(persistence.writes, writesBefore);
      manager.toggleAnonymous();
      expect(manager.isAnonymous, isFalse);
    });

    test('switchSession 切换当前会话', () async {
      persistence.stored = [makeSession('a'), makeSession('b')];
      await manager.load(title: '新对话');
      manager.switchSession('b');
      expect(manager.currentSessionId, 'b');
    });

    test('deleteSession 删除最后一个时自动重建空会话', () async {
      await manager.load(title: '新对话');
      await manager.deleteSession(manager.sessions.first);
      expect(manager.sessions, hasLength(1));
      expect(manager.sessions.first.messages, isEmpty);
    });

    test('pinSession 切换置顶', () async {
      await manager.load(title: '新对话');
      final s = manager.sessions.first;
      await manager.pinSession(s);
      expect(s.pinned, isTrue);
      await manager.pinSession(s);
      expect(s.pinned, isFalse);
    });

    test('duplicateSession 复制会话并持久化', () async {
      await manager.load(title: '新对话');
      final original = manager.sessions.first;
      await manager.duplicateSession(original);
      expect(manager.sessions, hasLength(2));
      expect(manager.sessions.first.title, contains(' (copy)'));
    });

    test('cleanupSessions 清理悬空服务商与模型引用', () {
      final s1 = makeSession('s1')..providerId = 'gone';
      final s2 = makeSession('s2')
        ..providerId = 'p1'
        ..modelId = 'm2';
      final changed = manager.cleanupSessions([s1, s2], [
        ChatProvider(id: 'p1', name: 'P', modelIds: ['m1']),
      ]);
      expect(changed, isTrue);
      expect(s1.providerId, isNull);
      expect(s2.modelId, isNull, reason: '模型已被删除时清空');
    });

    test('applyDefaultModel 填充包含默认模型的服务商', () {
      final session = makeSession('s1');
      manager.applyDefaultModel(
        session,
        const AppSettings(chatModel: 'gpt-4o'),
        [ChatProvider(id: 'p1', name: 'P', modelIds: ['gpt-4o'])],
      );
      expect(session.providerId, 'p1');
      expect(session.modelId, 'gpt-4o');
    });
  });

  group('MessageOps', () {
    late MessageOps ops;
    ChatSession? current;
    bool busy = false;
    ChatMessage? streaming;
    final restored = <String>[];
    var persisted = 0;
    var bumps = 0;
    int notifies = 0;
    final sentTexts = <String>[];
    var stopped = 0;

    void build() {
      ops = MessageOps(
        currentSession: () => current,
        isLoading: () => busy,
        streamingMessage: () => streaming,
        stop: () async => stopped++,
        sendText: (t) async => sentTexts.add(t),
        onRestoreInput: restored.add,
        persist: () async => persisted++,
        bumpTokenVersion: () => bumps++,
        onStateChanged: () => notifies++,
      );
    }

    setUp(() {
      current = null;
      busy = false;
      streaming = null;
      restored.clear();
      persisted = 0;
      bumps = 0;
      notifies = 0;
      sentTexts.clear();
      stopped = 0;
      build();
    });

    test('editMessage 就地修改并清除 assistant 失败标记', () {
      final session = makeSession('s1');
      final msg = ChatMessage(role: 'assistant', content: '旧', failed: true);
      session.messages.add(msg);
      ops.editMessage(msg, session, content: '新', reasoning: '思考');
      expect(msg.content, '新');
      expect(msg.reasoningContent, '思考');
      expect(msg.failed, isFalse);
      expect(persisted, greaterThan(0));
    });

    test('rollbackToMessage 截断消息并回填输入', () async {
      current = makeSession('s1')
        ..messages.addAll([
          ChatMessage(role: 'user', content: '问题'),
          ChatMessage(role: 'assistant', content: '回答'),
        ]);
      await ops.rollbackToMessage(current!.messages.first);
      expect(current!.messages, isEmpty);
      expect(restored, ['问题']);
      expect(persisted, greaterThan(0));
    });

    test('regenerateMessage 保存旧回复并重新发送', () async {
      current = makeSession('s1')
        ..messages.addAll([
          ChatMessage(role: 'user', content: 'a'),
          ChatMessage(role: 'assistant', content: '旧回复'),
        ]);
      final old = current!.messages.last;
      ops.regenerateMessage(old);
      expect(ops.regenerateOriginal, old);
      expect(current!.messages, hasLength(1));
      expect(sentTexts, ['']);
    });

    test('rollbackVersion 与最新历史版本交换内容', () {
      current = makeSession('s1');
      final msg = ChatMessage(
        role: 'assistant',
        content: '新版',
        alternatives: [ChatMessage(role: 'assistant', content: '旧版')],
      );
      current!.messages.add(msg);
      ops.rollbackVersion(msg);
      expect(msg.content, '旧版');
      expect(msg.alternatives.last.content, '新版');
    });

    test('deleteMessage 删除进行中的流式消息先停止', () async {
      current = makeSession('s1');
      final streamingMsg = ChatMessage(role: 'assistant', content: '生成中');
      current!.messages.addAll([
        ChatMessage(role: 'user', content: 'a'),
        streamingMsg,
      ]);
      busy = true;
      streaming = streamingMsg;
      await ops.deleteMessage(streamingMsg);
      expect(stopped, 1);
      expect(current!.messages, hasLength(1));
    });
  });

  group('AttachmentManager', () {
    test('addImageUrl 追加并通知', () {
      var notified = 0;
      final mgr = AttachmentManager(onStateChanged: () => notified++);
      mgr.addImageUrl(
        const ChatImage(url: 'data:image/png;base64,x', mimeType: 'image/png'),
      );
      expect(mgr.images, hasLength(1));
      expect(notified, 1);
    });

    test('removePendingImage 越界安全', () {
      final mgr = AttachmentManager();
      mgr.removePendingImage(-1);
      mgr.removePendingImage(0);
      expect(mgr.images, isEmpty);
    });

    test('removePendingDocument 越界安全', () {
      final mgr = AttachmentManager();
      mgr.removePendingDocument(0);
      mgr.removePendingDocument(-1);
      expect(mgr.documents, isEmpty);
    });

    test('mimeFromName 按扩展名映射', () {
      expect(AttachmentManager.mimeFromName('a.png'), 'image/png');
      expect(AttachmentManager.mimeFromName('a.JPG'), 'image/jpeg');
      expect(AttachmentManager.mimeFromName('a.webp'), 'image/webp');
      expect(AttachmentManager.mimeFromName('a.unknown'), 'image/*');
    });
  });

  group('TitleGenerator', () {
    test('未配置标题模型时回退首条消息', () {
      final gen = TitleGenerator(
        providerService: ProviderService(),
        chatService: ChatService(),
        settings: () => const AppSettings(titleModel: ''),
        defaultTitle: () => '新对话',
        persist: () async {},
      );
      final session = makeSession('s1')
        ..messages.add(ChatMessage(role: 'user', content: '这是一条很长很长的消息标题生成测试'));
      gen.maybeAutoTitle(session);
      expect(session.title, startsWith('这是一条很长'));
    });

    test('首条消息为纯图片时不生成标题', () {
      final gen = TitleGenerator(
        providerService: ProviderService(),
        chatService: ChatService(),
        settings: () => const AppSettings(titleModel: 'm1'),
        defaultTitle: () => '新对话',
        persist: () async {},
      );
      final session = makeSession('s1')
        ..messages.add(
          ChatMessage(
            role: 'user',
            content: '',
            images: [
              const ChatImage(
                url: 'data:image/png;base64,x',
                mimeType: 'image/png',
              ),
            ],
          ),
        );
      gen.maybeAutoTitle(session);
      expect(session.title, '会话', reason: '无文本可生成标题时维持原标题');
    });

    test('fallbackTitle 仅覆盖默认标题', () {
      final gen = TitleGenerator(
        providerService: ProviderService(),
        chatService: ChatService(),
        settings: () => const AppSettings(),
        defaultTitle: () => '新对话',
        persist: () async {},
      );
      final session = makeSession('s1', title: '新对话')
        ..messages.add(ChatMessage(role: 'user', content: '用户自定义消息标题'));
      gen.fallbackTitle(session, '新对话');
      expect(session.title, isNot('新对话'));
      session.title = '用户手改标题';
      gen.fallbackTitle(session, '新对话');
      expect(session.title, '用户手改标题', reason: '用户已手动重命名时不可覆盖');
    });
  });

  group('ChatRunOrchestrator 工具函数', () {
    test('decodeArguments 解析合法 JSON', () {
      expect(
        ChatRunOrchestrator.decodeArguments('{"a": 1}'),
        {'a': 1},
      );
    });

    test('decodeArguments 非法/空 JSON 返回空对象', () {
      expect(ChatRunOrchestrator.decodeArguments(''), isEmpty);
      expect(ChatRunOrchestrator.decodeArguments('not-json'), isEmpty);
      expect(ChatRunOrchestrator.decodeArguments('[1,2]'), isEmpty);
    });

    test('localizeChatError 映射错误码', () {
      final l10n = lookupAppLocalizations(const Locale('zh'));
      expect(
        ChatRunOrchestrator.localizeChatError(
          l10n,
          const ChatException('', code: ChatException.emptyResponse),
        ),
        '接口没有返回任何内容，请重试',
      );
      expect(
        ChatRunOrchestrator.localizeChatError(
          l10n,
          const ChatException('原始信息', code: ChatException.httpError),
        ),
        '原始信息',
        reason: '未知/HTTP 错误码保留原始描述',
      );
    });
  });
}
