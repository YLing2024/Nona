import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nona_chat/models/agent.dart';
import 'package:nona_chat/models/chat_message.dart';
import 'package:nona_chat/models/chat_options.dart';
import 'package:nona_chat/models/chat_provider.dart';
import 'package:nona_chat/models/chat_session.dart';
import 'package:nona_chat/models/network_log.dart';
import 'package:nona_chat/routes/app_routes.dart';
import 'package:nona_chat/screens/agent_edit_screen.dart';
import 'package:nona_chat/screens/context_settings_screen.dart';
import 'package:nona_chat/screens/message_edit_screen.dart';
import 'package:nona_chat/screens/network_log_detail_screen.dart';
import 'package:nona_chat/screens/provider_edit_screen.dart';
import 'package:nona_chat/screens/search_screen.dart';
import 'package:nona_chat/screens/theme_settings_screen.dart';
import 'package:nona_chat/services/search_service.dart';

import '../support/app_test_wrapper.dart';

void main() {
  group('AppRoutes 工厂', () {
    test('无参工厂全部返回 MaterialPageRoute（统一转场）', () {
      for (final route in <Route<dynamic>>[
        AppRoutes.settings(),
        AppRoutes.about(),
        AppRoutes.preferences(),
        AppRoutes.modelConfig(),
        AppRoutes.developerOptions(),
        AppRoutes.networkLogs(),
        AppRoutes.providerList(),
        AppRoutes.agentList(),
        AppRoutes.mcpServers(),
        AppRoutes.sync(),
        AppRoutes.compare(),
        AppRoutes.knowledgeBase(),
        AppRoutes.translator(),
      ]) {
        expect(route, isA<MaterialPageRoute<dynamic>>());
      }
    });

    Future<void> pushAndSettle(WidgetTester tester, Route<dynamic> route) async {
      await tester.pumpWidget(
        wrapApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(route),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('带参工厂：参数正确透传到目标页面', (tester) async {
      final provider = ChatProvider(id: 'p1', name: 'T', modelIds: const []);
      await pushAndSettle(tester, AppRoutes.providerEdit(provider: provider));
      expect(
        tester.widget<ProviderEditScreen>(find.byType(ProviderEditScreen)).provider,
        same(provider),
      );
      Navigator.of(tester.element(find.byType(ProviderEditScreen))).pop();
      await tester.pumpAndSettle();

      final agent = Agent(id: 'a1', name: '助手');
      await pushAndSettle(tester, AppRoutes.agentEdit(agent: agent));
      expect(
        tester.widget<AgentEditScreen>(find.byType(AgentEditScreen)).agent,
        same(agent),
      );
      Navigator.of(tester.element(find.byType(AgentEditScreen))).pop();
      await tester.pumpAndSettle();

      final msg = ChatMessage(role: 'user', content: 'hi');
      await pushAndSettle(tester, AppRoutes.messageEdit(message: msg));
      expect(
        tester.widget<MessageEditScreen>(find.byType(MessageEditScreen)).message,
        same(msg),
      );
      Navigator.of(tester.element(find.byType(MessageEditScreen))).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('带参工厂：初始值/会话参数正确透传', (tester) async {
      await pushAndSettle(
        tester,
        AppRoutes.themeSettings(initialThemeMode: 'dark'),
      );
      expect(
        tester
            .widget<ThemeSettingsScreen>(find.byType(ThemeSettingsScreen))
            .initialThemeMode,
        'dark',
      );
      Navigator.of(tester.element(find.byType(ThemeSettingsScreen))).pop();
      await tester.pumpAndSettle();

      await pushAndSettle(
        tester,
        AppRoutes.contextSettings(initial: const ChatOptions()),
      );
      expect(
        tester
            .widget<ContextSettingsScreen>(find.byType(ContextSettingsScreen))
            .initial,
        isA<ChatOptions>(),
      );
      Navigator.of(tester.element(find.byType(ContextSettingsScreen))).pop();
      await tester.pumpAndSettle();

      final log = NetworkLog(
        id: '1',
        time: DateTime(2026),
        method: 'GET',
        url: 'https://x',
        statusCode: 200,
        durationMs: 1,
        requestBytes: 0,
        responseBytes: 0,
        requestHeaders: const {},
        requestBody: '',
        responseHeaders: const {},
        responseBody: '',
        type: NetworkLogType.other,
      );
      await pushAndSettle(tester, AppRoutes.networkLogDetail(log: log));
      expect(
        tester
            .widget<NetworkLogDetailScreen>(find.byType(NetworkLogDetailScreen))
            .log,
        same(log),
      );
      Navigator.of(tester.element(find.byType(NetworkLogDetailScreen))).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('search 工厂：会话列表与索引函数透传', (tester) async {
      final sessions = [
        ChatSession(
          id: 's1',
          title: 'Flutter',
          messages: [ChatMessage(role: 'user', content: 'x')],
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ];
      await pushAndSettle(
        tester,
        AppRoutes.search(sessions: sessions, indexedSearch: _noopSearch),
      );
      final screen =
          tester.widget<SearchScreen>(find.byType(SearchScreen));
      expect(screen.sessions, same(sessions));
      expect(screen.indexedSearch, same(_noopSearch));
    });
  });
}

Future<List<MessageSearchHit>> _noopSearch(
  String query, {
  int limit = 50,
}) async =>
    const [];
