import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/features/chat/controllers/chat_controller.dart';
import 'package:nona_chat/l10n/app_localizations.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_options.dart';
import 'package:nona_chat/core/models/chat_provider.dart';
import 'package:nona_chat/core/models/chat_session.dart';
import 'package:nona_chat/core/services/agent_service.dart';
import 'package:nona_chat/core/services/chat_service.dart';
import 'package:nona_chat/core/services/knowledge_base_service.dart';
import 'package:nona_chat/core/services/mcp/mcp_service.dart';
import 'package:nona_chat/core/services/model_capability_service.dart';
import 'package:nona_chat/core/services/provider_service.dart';
import 'package:nona_chat/core/services/session_service.dart';
import 'package:nona_chat/core/services/settings_service.dart';
import 'package:nona_chat/core/services/web_search/web_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatController controller;
  int notifyCount = 0;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controller = ChatController(
      chatService: ChatService(),
      sessionService: SessionService(),
      agentService: AgentService(),
      providerService: ProviderService(),
      capabilityService: ModelCapabilityService(),
      webSearchService: WebSearchService(),
      mcpService: McpService(),
      knowledgeBase: KnowledgeBaseService(),
      callbacks: ChatUiCallbacks(onStateChanged: () => notifyCount++),
    );
    notifyCount = 0;
  });

  tearDown(() {
    controller.dispose();
  });

  ChatSession makeSession(String id, {String title = '会话', int messages = 2}) {
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

  group('ChatController 会话管理', () {
    test('newSession 创建并切换', () async {
      await controller.newSession();
      expect(controller.sessions, hasLength(1));
      expect(controller.currentSessionId, controller.sessions.first.id);
      expect(controller.isLoading, isFalse);
    });

    test('switchSession 切换当前会话', () async {
      await controller.newSession();
      final first = controller.sessions.first.id;
      await controller.newSession();
      final second = controller.sessions.first.id;
      controller.switchSession(first);
      expect(controller.currentSessionId, first);
      controller.switchSession(second);
      expect(controller.currentSessionId, second);
    });

    test('deleteSession 删除后切换剩余会话', () async {
      await controller.newSession();
      await controller.newSession();
      final sessions = List.of(controller.sessions);
      await controller.deleteSession(sessions.first);
      expect(controller.sessions, hasLength(1));
      expect(controller.currentSessionId, controller.sessions.first.id);
    });

    test('deleteSession 删除最后一个会重新创建空会话', () async {
      await controller.newSession();
      await controller.deleteSession(controller.sessions.first);
      expect(controller.sessions, hasLength(1));
      expect(controller.sessions.first.messages, isEmpty);
    });

    test('pinSession 切换置顶', () async {
      await controller.newSession();
      final s = controller.sessions.first;
      controller.pinSession(s);
      expect(s.pinned, isTrue);
    });

    test('toggleAnonymous 匿名会话不持久化', () async {
      await controller.newSession();
      controller.toggleAnonymous();
      expect(controller.isAnonymous, isTrue);
      expect(controller.currentSession, isNotNull);
      controller.toggleAnonymous();
      expect(controller.isAnonymous, isFalse);
    });

    test('duplicateSession 复制会话', () async {
      await controller.newSession();
      final original = controller.sessions.first;
      await controller.duplicateSession(original);
      expect(controller.sessions, hasLength(2));
      expect(controller.sessions.first.title, contains(' (copy)'));
    });

    test('状态变化通知 UI', () async {
      await controller.newSession();
      expect(notifyCount, greaterThan(0));
    });
  });

  group('ChatController 消息操作', () {
    test('deleteMessage 截断其后所有消息', () async {
      await controller.newSession();
      final session = controller.currentSession!;
      session.messages.addAll([
        ChatMessage(role: 'user', content: 'a'),
        ChatMessage(role: 'assistant', content: 'b'),
        ChatMessage(role: 'user', content: 'c'),
      ]);
      await controller.deleteMessage(session.messages[1]);
      expect(session.messages, hasLength(1));
      expect(session.messages.first.content, 'a');
    });

    test('rollbackToMessage 回填输入', () async {
      String? restored;
      final ctrl = ChatController(
        chatService: ChatService(),
        sessionService: SessionService(),
        agentService: AgentService(),
        providerService: ProviderService(),
        capabilityService: ModelCapabilityService(),
        webSearchService: WebSearchService(),
        mcpService: McpService(),
        knowledgeBase: KnowledgeBaseService(),
        callbacks: ChatUiCallbacks(
          onStateChanged: () {},
          onRestoreInput: (text) => restored = text,
        ),
      );
      await ctrl.newSession();
      final session = ctrl.currentSession!;
      session.messages.addAll([
        ChatMessage(role: 'user', content: '问题'),
        ChatMessage(role: 'assistant', content: '回答'),
      ]);
      await ctrl.rollbackToMessage(session.messages[0]);
      expect(session.messages, isEmpty);
      expect(restored, '问题');
      ctrl.dispose();
    });

    test('rollbackVersion 交换历史版本', () async {
      await controller.newSession();
      final session = controller.currentSession!;
      final msg = ChatMessage(
        role: 'assistant',
        content: '新版',
        alternatives: [ChatMessage(role: 'assistant', content: '旧版')],
      );
      session.messages.add(msg);
      controller.rollbackVersion(msg);
      expect(msg.content, '旧版');
      expect(msg.alternatives, hasLength(1));
      expect(msg.alternatives.last.content, '新版');
    });

    test('editMessage 就地修改', () async {
      await controller.newSession();
      final session = controller.currentSession!;
      final msg = ChatMessage(role: 'user', content: '原始');
      session.messages.add(msg);
      controller.editMessage(msg, session, content: '修改后');
      expect(msg.content, '修改后');
    });

    test('onModelChanged 更新会话模型', () async {
      await controller.newSession();
      controller.providers = [
        ChatProvider(
          id: 'p1',
          name: 'P',
          baseUrl: 'https://x',
          apiKey: 'k',
          modelIds: ['m1'],
        ),
      ];
      final session = controller.currentSession!;
      controller.onModelChanged('p1', 'm1');
      expect(session.providerId, 'p1');
      expect(session.modelId, 'm1');
    });
  });

  group('ChatController 上下文窗口', () {
    test('estimateTokens 计算消息 token', () async {
      await controller.newSession();
      final session = controller.currentSession!;
      session.messages.add(ChatMessage(role: 'user', content: '你好'));
      final tokens = controller.estimateTokens(session);
      expect(tokens, greaterThan(0));
      // 缓存命中：同一版本号返回相同值
      expect(controller.estimateTokens(session), tokens);
    });

    test('contextLimitFor 显式配置优先', () async {
      final session = makeSession('s1')
        ..options = const ChatOptions(maxContextTokens: 4096);
      expect(controller.contextLimitFor(session), 4096);
    });

    test('trimContext 超限裁剪', () async {
      final session = makeSession('s1', messages: 5)
        ..options = const ChatOptions(maxContextTokens: 25, autoTrim: true);
      final removed = controller.trimContext(session);
      expect(removed, greaterThan(0));
    });
  });

  group('ChatController 附件', () {
    test('addImageUrl/removePendingImage', () async {
      controller.addImageUrl(
        const ChatImage(url: 'data:image/png;base64,x', mimeType: 'image/png'),
      );
      expect(controller.pendingImages, hasLength(1));
      controller.removePendingImage(0);
      expect(controller.pendingImages, isEmpty);
    });

    test('removePendingDocument 越界安全', () async {
      controller.removePendingDocument(0);
      controller.removePendingDocument(-1);
      expect(controller.pendingDocuments, isEmpty);
    });
  });

  group('ChatController 注入与配置', () {
    test('cleanupSessions 清理悬空服务商引用', () async {
      final session = makeSession('s1');
      session.providerId = 'gone';
      session.modelId = 'm';
      final changed = controller.cleanupSessions([session], []);
      expect(changed, isTrue);
      expect(session.providerId, isNull);
    });

    test('applyDefaultModel 应用全局默认模型', () async {
      final session = makeSession('s1');
      controller.applyDefaultModel(
        session,
        const AppSettings(chatModel: 'gpt-4o'),
        [
          ChatProvider(
            id: 'p1',
            name: 'P',
            modelIds: ['gpt-4o'],
          ),
        ],
      );
      expect(session.modelId, 'gpt-4o');
      expect(session.providerId, 'p1');
    });

    test('本地化错误映射', () {
      final l10n = lookupAppLocalizations(const Locale('zh'));
      expect(
        ChatController.localizeChatError(
          l10n,
          const ChatException('', code: ChatException.emptyResponse),
        ),
        '接口没有返回任何内容，请重试',
      );
    });
  });
}
