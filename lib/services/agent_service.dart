import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/agent.dart';
import '../models/chat_options.dart';
import '../utils/logger.dart';

/// Agent 配置持久化服务。
class AgentService {
  static const _kAgents = 'agents';
  static const _kInitialized = 'agents_initialized';
  static const _kDefaultMigrated = 'agents_default_migrated';

  /// 内置默认 Agent，首次使用即为默认。
  ///
  /// [defaultSystemPrompt] 为本地化默认系统提示词（英文界面不应显示中文提示词）；
  /// 未提供时使用内置中文默认值（旧数据兼容）。
  static Agent defaultAgent({String? defaultSystemPrompt}) => Agent(
    id: 'agent-default',
    name: 'Nona',
    isDefault: true,
    options: ChatOptions(
      systemPrompt: defaultSystemPrompt ??
          'You are Nona, an efficient and friendly AI chat assistant. Respond in clear, accurate and well-organized language; ask clarifying questions when the request is ambiguous, but do not overdo it. Answer in the user''s language by default.',
    ),
  );

  /// 加载 Agent 列表；首次使用时以 [defaultSystemPrompt] 初始化默认 Agent。
  Future<List<Agent>> load({String? defaultSystemPrompt}) async {
    final prefs = await SharedPreferences.getInstance();

    // 首次使用时内置默认 Agent，之后由用户自由增删。
    if (!(prefs.getBool(_kInitialized) ?? false)) {
      final defaults = [defaultAgent(defaultSystemPrompt: defaultSystemPrompt)];
      await prefs.setString(
        _kAgents,
        jsonEncode(defaults.map((a) => a.toJson()).toList()),
      );
      await prefs.setBool(_kInitialized, true);
      return defaults;
    }

    final raw = prefs.getString(_kAgents);
    if (raw == null || raw.isEmpty) return [];
    List<Agent> agents;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      agents = [];
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        try {
          agents.add(Agent.fromJson(e));
        } catch (_) {
          // 单条损坏跳过
        }
      }
    } catch (e) {
      // 配置损坏时自愈为空列表，避免应用启动即崩溃
      Logger.warn('agent', 'Agent config corrupt, reset');
      Logger.error('agent', 'load parse failed', e);
      agents = [];
      try {
        await prefs.setString(_kAgents, '[]');
        await prefs.setBool(_kInitialized, true);
        await prefs.setBool(_kDefaultMigrated, true);
      } catch (_) {}
    }

    // 一次性迁移：老数据中内置 Nona 自动成为默认（仅在没有默认 Agent 时）。
    if (!(prefs.getBool(_kDefaultMigrated) ?? false)) {
      if (!agents.any((a) => a.isDefault)) {
        final idx = agents.indexWhere((a) => a.id == 'agent-default');
        if (idx >= 0) {
          agents[idx].isDefault = true;
          await prefs.setString(
            _kAgents,
            jsonEncode(agents.map((a) => a.toJson()).toList()),
          );
        }
      }
      await prefs.setBool(_kDefaultMigrated, true);
    }

    return agents;
  }

  Future<void> save(List<Agent> agents) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kAgents,
      jsonEncode(agents.map((a) => a.toJson()).toList()),
    );
    await prefs.setBool(_kInitialized, true);
    await prefs.setBool(_kDefaultMigrated, true);
  }
}
