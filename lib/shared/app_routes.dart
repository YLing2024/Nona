import 'package:flutter/material.dart';

import '../core/models/agent.dart';
import '../core/models/chat_message.dart';
import '../core/models/chat_options.dart';
import '../core/models/chat_provider.dart';
import '../core/models/chat_session.dart';
import '../core/models/network_log.dart';
import '../features/settings/screens/about_screen.dart';
import '../features/agent/screens/agent_edit_screen.dart';
import '../features/agent/screens/agent_list_screen.dart';
import '../features/chat/screens/compare_screen.dart';
import '../features/settings/screens/context_settings_screen.dart';
import '../features/settings/screens/developer_options_screen.dart';
import '../features/export/screens/import_wizard_screen.dart';
import '../features/imggen/screens/imggen_screen.dart';
import '../features/knowledge/screens/knowledge_base_screen.dart';
import '../features/mcp/screens/mcp_servers_screen.dart';
import '../features/memory/screens/memory_screen.dart';
import '../features/chat/screens/message_document_screen.dart';
import '../features/chat/screens/message_edit_screen.dart';
import '../features/model/screens/model_config_screen.dart';
import '../features/settings/screens/network_log_body_screen.dart';
import '../features/settings/screens/network_log_detail_screen.dart';
import '../features/settings/screens/network_log_screen.dart';
import '../features/settings/screens/preferences_screen.dart';
import '../features/settings/screens/quick_phrases_screen.dart';
import '../features/settings/screens/instruction_injections_screen.dart';
import '../features/automation/workflows_screen.dart';
import '../features/provider/screens/provider_edit_screen.dart';
import '../features/provider/screens/provider_list_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/stats/screens/stats_screen.dart';
import '../features/sync/screens/sync_screen.dart';
import '../features/settings/screens/theme_settings_screen.dart';
import '../features/translator/screens/translator_screen.dart';
import '../features/world_book/screens/world_book_screen.dart';
import '../core/services/search_service.dart';

/// 应用路由集中表：全部 `MaterialPageRoute` 的唯一变更点。
///
/// 后续 REQ-027（内嵌服务器导航）、deep-link / 恢复导航只需改这里；
/// 参数经工厂方法类型化（编译期兜底），转场动画保持现状。
abstract final class AppRoutes {
  // ---- 设置页系 ----

  static Route<T> settings<T>() =>
      MaterialPageRoute<T>(builder: (_) => const SettingsScreen());

  static Route<T> about<T>() =>
      MaterialPageRoute<T>(builder: (_) => const AboutScreen());

  static Route<T> preferences<T>() =>
      MaterialPageRoute<T>(builder: (_) => const PreferencesScreen());

  static Route<T> quickPhrases<T>() =>
      MaterialPageRoute<T>(builder: (_) => const QuickPhrasesScreen());

  static Route<T> instructionInjections<T>() =>
      MaterialPageRoute<T>(builder: (_) => const InstructionInjectionsScreen());

  static Route<T> workflows<T>() =>
      MaterialPageRoute<T>(builder: (_) => const WorkflowsScreen());

  static Route<T> themeSettings<T>({required String initialThemeMode}) =>
      MaterialPageRoute<T>(
        builder: (_) => ThemeSettingsScreen(initialThemeMode: initialThemeMode),
      );

  static Route<T> modelConfig<T>() =>
      MaterialPageRoute<T>(builder: (_) => const ModelConfigScreen());

  static Route<T> developerOptions<T>() =>
      MaterialPageRoute<T>(builder: (_) => const DeveloperOptionsScreen());

  static Route<T> networkLogs<T>() =>
      MaterialPageRoute<T>(builder: (_) => const NetworkLogScreen());

  static Route<T> networkLogDetail<T>({required NetworkLog log}) =>
      MaterialPageRoute<T>(
        builder: (_) => NetworkLogDetailScreen(log: log),
      );

  static Route<T> networkLogBody<T>({
    required String title,
    required String body,
    required int bytes,
  }) =>
      MaterialPageRoute<T>(
        builder: (_) =>
            NetworkLogBodyScreen(title: title, body: body, bytes: bytes),
      );

  // ---- 服务商 / Agent ----

  static Route<T> providerList<T>() =>
      MaterialPageRoute<T>(builder: (_) => const ProviderListScreen());

  static Route<T> providerEdit<T>({ChatProvider? provider}) =>
      MaterialPageRoute<T>(
        builder: (_) => ProviderEditScreen(provider: provider),
      );

  static Route<T> agentList<T>() =>
      MaterialPageRoute<T>(builder: (_) => const AgentListScreen());

  static Route<T> agentEdit<T>({Agent? agent}) =>
      MaterialPageRoute<T>(builder: (_) => AgentEditScreen(agent: agent));

  // ---- 会话 / 消息 ----

  static Route<T> messageEdit<T>({required ChatMessage message}) =>
      MaterialPageRoute<T>(builder: (_) => MessageEditScreen(message: message));

  static Route<T> messageDocument<T>({
    required ChatMessage message,
    required bool speaking,
    required Future<void> Function() onCopy,
    required Future<void> Function() onSpeak,
    required Future<void> Function() onEdit,
    required Future<void> Function() onRollback,
    required Future<void> Function() onRegenerate,
    required Future<void> Function() onDelete,
  }) =>
      MaterialPageRoute<T>(
        builder: (_) => MessageDocumentScreen(
          message: message,
          speaking: speaking,
          onCopy: onCopy,
          onSpeak: onSpeak,
          onEdit: onEdit,
          onRollback: onRollback,
          onRegenerate: onRegenerate,
          onDelete: onDelete,
        ),
      );

  static Route<T> contextSettings<T>({
    required ChatOptions initial,
    String? initialAgentId,
  }) =>
      MaterialPageRoute<T>(
        builder: (_) => ContextSettingsScreen(
          initial: initial,
          initialAgentId: initialAgentId,
        ),
      );

  static Route<T> search<T>({
    required List<ChatSession> sessions,
    required Future<List<MessageSearchHit>> Function(
      String query, {
      int limit,
    })
    indexedSearch,
  }) =>
      MaterialPageRoute<T>(
        builder: (_) => SearchScreen(
          sessions: sessions,
          indexedSearch: indexedSearch,
        ),
      );

  // ---- 内容工具 ----

  static Route<T> mcpServers<T>() =>
      MaterialPageRoute<T>(builder: (_) => const McpServersScreen());

  static Route<T> sync<T>() =>
      MaterialPageRoute<T>(builder: (_) => const SyncScreen());

  static Route<T> compare<T>() =>
      MaterialPageRoute<T>(builder: (_) => const CompareScreen());

  static Route<T> knowledgeBase<T>() =>
      MaterialPageRoute<T>(builder: (_) => const KnowledgeBaseScreen());

  static Route<T> stats<T>() =>
      MaterialPageRoute<T>(builder: (_) => const StatsScreen());

  static Route<T> memory<T>() =>
      MaterialPageRoute<T>(builder: (_) => const MemoryScreen());

  static Route<T> worldBook<T>() =>
      MaterialPageRoute<T>(builder: (_) => const WorldBookScreen());

  static Route<T> importWizard<T>() =>
      MaterialPageRoute<T>(builder: (_) => const ImportWizardScreen());

  static Route<T> imgGen<T>() =>
      MaterialPageRoute<T>(builder: (_) => const ImgGenScreen());

  static Route<T> translator<T>() =>
      MaterialPageRoute<T>(builder: (_) => const TranslatorScreen());
}
