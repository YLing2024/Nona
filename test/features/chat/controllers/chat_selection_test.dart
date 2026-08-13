import 'package:flutter_test/flutter_test.dart';
import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_session.dart';
import 'package:nona_chat/core/services/agent_service.dart';
import 'package:nona_chat/core/services/chat_service.dart';
import 'package:nona_chat/core/services/knowledge_base_service.dart';
import 'package:nona_chat/core/services/mcp/mcp_service.dart';
import 'package:nona_chat/core/services/model_capability_service.dart';
import 'package:nona_chat/core/services/provider_service.dart';
import 'package:nona_chat/core/services/session_service.dart';
import 'package:nona_chat/core/services/web_search/web_search_service.dart';
import 'package:nona_chat/features/chat/controllers/chat_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatController controller;

  setUp(() {
    controller = ChatController(
      chatService: ChatService(),
      sessionService: SessionService(),
      agentService: AgentService(),
      providerService: ProviderService(),
      capabilityService: ModelCapabilityService(),
      webSearchService: WebSearchService(),
      mcpService: McpService(),
      knowledgeBase: KnowledgeBaseService(),
      callbacks: ChatUiCallbacks(),
    );
  });

  Future<void> setupSession(int messageCount) async {
    await controller.newSession();
    final s = controller.sessions.first;
    s.messages.addAll(
      List.generate(
        messageCount,
        (i) => ChatMessage(
          role: i.isEven ? 'user' : 'assistant',
          content: '消息 $i',
        ),
      ),
    );
  }

  ChatSession makeSession(int messageCount) {
    final now = DateTime(2024, 1, 1);
    return ChatSession(
      id: 's1',
      title: '会话',
      messages: List.generate(
        messageCount,
        (i) => ChatMessage(
          role: i.isEven ? 'user' : 'assistant',
          content: '消息 $i',
        ),
      ),
      createdAt: now,
      updatedAt: now,
    );
  }

  group('ChatController 多选模式（B-01）', () {
    test('enterSelection/exitSelection 状态切换', () {
      expect(controller.selectionActive, isFalse);
      controller.enterSelection();
      expect(controller.selectionActive, isTrue);
      expect(controller.selectedCount, 0);
      controller.exitSelection();
      expect(controller.selectionActive, isFalse);
    });

    test('toggleSelect 单选与取消', () {
      controller.enterSelection();
      controller.toggleSelect(1);
      expect(controller.selectedMessageIndices, {1});
      controller.toggleSelect(1);
      expect(controller.selectedMessageIndices, isEmpty);
      controller.toggleSelect(0);
      controller.toggleSelect(2);
      expect(controller.selectedMessageIndices, {0, 2});
    });

    test('selectRangeTo 连续选择（锚点 → index）', () {
      controller.enterSelection();
      controller.toggleSelect(2); // 锚点 2
      controller.selectRangeTo(5);
      expect(controller.selectedMessageIndices, {2, 3, 4, 5});
    });

    test('selectAllMessages / invertSelection', () {
      controller.sessions = [makeSession(6)];
      controller.currentSessionId = 's1';
      controller.enterSelection();
      controller.selectAllMessages();
      expect(controller.selectedCount, 6);
      controller.invertSelection();
      expect(controller.selectedCount, 0);
      controller.toggleSelect(1);
      controller.invertSelection();
      expect(controller.selectedCount, 5);
      expect(controller.selectedMessageIndices, isNot(contains(1)));
    });

    test('deleteSelectedMessages 截断语义（选最小索引及其后全删）', () async {
      controller.sessions = [makeSession(6)];
      controller.currentSessionId = 's1';
      controller.enterSelection();
      controller.toggleSelect(3);
      controller.toggleSelect(5);
      expect(controller.selectedCount, 2);
      final deleted = await controller.deleteSelectedMessages();
      expect(deleted, 3, reason: '索引 3 起 3 条被删除');
      expect(controller.currentSession!.messages, hasLength(3));
      expect(controller.selectionActive, isFalse, reason: '删除后退出多选');
    });

    test('多选操作不改动选择外的会话状态', () async {
      final session = makeSession(4);
      controller.sessions = [session];
      controller.currentSessionId = 's1';
      controller.enterSelection();
      controller.toggleSelect(1);
      await controller.deleteSelectedMessages();
      expect(controller.currentSession!.messages, hasLength(1));
      expect(controller.currentSession!.messages.single.content, '消息 0');
    });
  });
}
