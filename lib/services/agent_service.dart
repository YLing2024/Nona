import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/agent.dart';
import '../models/chat_options.dart';

/// Agent 配置持久化服务。
class AgentService {
  static const _kAgents = 'agents';
  static const _kInitialized = 'agents_initialized';

  /// 内置默认 Agent。
  static Agent get defaultAgent => Agent(
    id: 'agent-default',
    name: 'Nona',
    options: const ChatOptions(
      systemPrompt:
          '你是 Nona，一款简洁高效的 AI 聊天助手。请用简体中文、以清晰友好的语气回应用户，回答问题力求准确、有条理；当需求不明确时可以适当追问，但不要过度。除非用户特别要求，否则默认使用中文回答。',
    ),
  );

  Future<List<Agent>> load() async {
    final prefs = await SharedPreferences.getInstance();

    // 首次使用时内置默认 Agent，之后由用户自由增删。
    if (!(prefs.getBool(_kInitialized) ?? false)) {
      final defaults = [defaultAgent];
      await prefs.setString(
        _kAgents,
        jsonEncode(defaults.map((a) => a.toJson()).toList()),
      );
      await prefs.setBool(_kInitialized, true);
      return defaults;
    }

    final raw = prefs.getString(_kAgents);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Agent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<Agent> agents) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kAgents,
      jsonEncode(agents.map((a) => a.toJson()).toList()),
    );
    await prefs.setBool(_kInitialized, true);
  }
}
