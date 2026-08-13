import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/core/models/chat_message.dart';
import 'package:nona_chat/core/models/chat_session.dart';
import 'package:nona_chat/core/services/session_service.dart';
import 'package:nona_chat/core/services/settings_service.dart';

import '../../support/reset_globals.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetGlobalState();
  });

  group('SettingsService', () {
    test('save 后 load 完整读回', () async {
      final service = SettingsService();
      await service.save(const AppSettings(
        apiKey: 'sk-x',
        baseUrl: 'https://example.com/v1',
        model: 'gpt-4o',
        themeMode: 'dark',
        accentColor: 0xFF10B981,
        oledDark: true,
        sendOnEnter: true,
        testPrompt: '你好',
        defaultAgentModel: 'gpt-4o',
        chatModel: 'gpt-4o-mini',
        titleModel: 'gpt-4o',
        developerMode: true,
        autoUpdateModelCapabilities: true,
        networkLogEnabled: true,
        networkLogMaxLogs: 100,
      ));
      final loaded = await service.load();
      expect(loaded.apiKey, 'sk-x');
      expect(loaded.baseUrl, 'https://example.com/v1');
      expect(loaded.model, 'gpt-4o');
      expect(loaded.themeMode, 'dark');
      expect(loaded.accentColor, 0xFF10B981);
      expect(loaded.oledDark, isTrue);
      expect(loaded.sendOnEnter, isTrue);
      expect(loaded.testPrompt, '你好');
      expect(loaded.defaultAgentModel, 'gpt-4o');
      expect(loaded.chatModel, 'gpt-4o-mini');
      expect(loaded.titleModel, 'gpt-4o');
      expect(loaded.developerMode, isTrue);
      expect(loaded.autoUpdateModelCapabilities, isTrue);
      expect(loaded.networkLogEnabled, isTrue);
      expect(loaded.networkLogMaxLogs, 100);
    });

    test('空配置回退默认值', () async {
      final loaded = await SettingsService().load();
      expect(loaded.apiKey, '');
      expect(loaded.baseUrl, 'https://api.openai.com/v1');
      expect(loaded.model, 'gpt-4o-mini');
      expect(loaded.themeMode, 'system');
      expect(loaded.sendOnEnter, isFalse);
      expect(loaded.networkLogMaxLogs, 0);
    });
  });

  group('SessionService', () {
    test('save 后 load 完整读回', () async {
      final service = SessionService();
      final sessions = [
        ChatSession(
          id: 's1',
          title: '会话一',
          messages: [
            ChatMessage(role: 'user', content: '你好'),
            ChatMessage(
              role: 'assistant',
              content: '嗨',
              reasoningContent: 'r',
              providerName: 'P',
              modelId: 'm',
            ),
          ],
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
          pinned: true,
        ),
      ];
      await service.saveAll(sessions);
      final loaded = await service.load();
      expect(loaded, hasLength(1));
      expect(loaded.first.title, '会话一');
      expect(loaded.first.pinned, isTrue);
      expect(loaded.first.messages, hasLength(2));
      expect(loaded.first.messages[1].reasoningContent, 'r');
      expect(loaded.first.createdAt, DateTime(2024, 1, 1));
    });

    test('无数据返回空列表', () async {
      expect(await SessionService().load(), isEmpty);
    });
  });
}
