import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nona_chat/core/models/agent.dart';
import 'package:nona_chat/core/models/chat_options.dart';
import 'package:nona_chat/core/services/agent_service.dart';

import '../../support/reset_globals.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetGlobalState();
  });

  group('AgentService', () {
    test('首次使用注入默认 Agent', () async {
      final service = AgentService();
      final agents = await service.load();
      expect(agents, hasLength(1));
      expect(agents.first.id, 'agent-default');
      expect(agents.first.isDefault, isTrue);
      expect(agents.first.options.systemPrompt, isNotEmpty);
    });

    test('save 后 load 读回用户自定义 Agent', () async {
      final service = AgentService();
      await service.load(); // 触发首次初始化
      await service.save([
        Agent(id: 'a1', name: '翻译官', options: const ChatOptions(systemPrompt: '你是翻译')),
        Agent(id: 'a2', name: '程序员'),
      ]);
      final loaded = await service.load();
      expect(loaded, hasLength(2));
      expect(loaded.first.name, '翻译官');
      expect(loaded.first.options.systemPrompt, '你是翻译');
    });

    test('老数据无默认 Agent 时迁移内置 Nona 为默认', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('agents_initialized', true);
      await prefs.setString(
        'agents',
        jsonEncode([
          Agent(id: 'agent-default', name: 'Nona', isDefault: false).toJson(),
          Agent(id: 'a1', name: '自定义', isDefault: false).toJson(),
        ]),
      );

      final loaded = await AgentService().load();
      final defaultAgent = loaded.where((a) => a.isDefault).toList();
      expect(defaultAgent, hasLength(1));
      expect(defaultAgent.single.id, 'agent-default');
      // 迁移标记已写入，二次 load 不再重复处理
      expect(prefs.getBool('agents_default_migrated'), isTrue);
    });
  });
}
