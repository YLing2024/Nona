import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/agent_service.dart';
import '../services/chat_service.dart';
import '../services/knowledge_base_service.dart';
import '../services/mcp/mcp_service.dart';
import '../services/model_capability_service.dart';
import '../services/network_log_service.dart';
import '../services/provider_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../services/web_search/web_search_service.dart';

/// 应用级依赖注入根：统一提供门面服务单例。
///
/// - 门面服务（无状态/内部持 prefs）注册为 [Provider]（默认单例语义）；
/// - 真 ChangeNotifier（[NetworkLogService]）注册为
///   [ChangeNotifierProvider.value]（保持既有单例）；
/// - 测试可在外部再套一层 `Provider<X>.value` 覆盖（Provider 就近解析，
///   树深处的覆盖优先于本根）。
///
/// 屏幕/组件一律通过 `context.read<X>()` 获取服务，不再自行 new。
class AppScope extends StatelessWidget {
  final Widget child;

  const AppScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SettingsService>(create: (_) => SettingsService()),
        Provider<SessionService>(create: (_) => SessionService()),
        Provider<AgentService>(create: (_) => AgentService()),
        Provider<ProviderService>(create: (_) => ProviderService()),
        Provider<ModelCapabilityService>(
          create: (_) => ModelCapabilityService(),
        ),
        Provider<WebSearchService>(create: (_) => WebSearchService()),
        Provider<McpService>(create: (_) => McpService()),
        Provider<KnowledgeBaseService>(
          create: (_) => KnowledgeBaseService(),
        ),
        Provider<ChatService>(create: (_) => ChatService()),
        ChangeNotifierProvider<NetworkLogService>.value(
          value: NetworkLogService.instance,
        ),
      ],
      child: child,
    );
  }
}
