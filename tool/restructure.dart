// A-02 目录重构工具：按映射移动 lib/ 文件并全量重写 import/export 路径。
//
// 用法：dart run tool/restructure.dart apply
// 校验：dart run tool/restructure.dart check（只报告不移动）
import 'dart:io';

/// 映射表：旧相对 lib/ 路径 → 新相对 lib/ 路径（正斜杠）。
const List<List<String>> kMoves = [
  // ---------------- core/models ----------------
  ['models/agent.dart', 'core/models/agent.dart'],
  ['models/chat_message.dart', 'core/models/chat_message.dart'],
  ['models/chat_options.dart', 'core/models/chat_options.dart'],
  ['models/chat_provider.dart', 'core/models/chat_provider.dart'],
  ['models/chat_session.dart', 'core/models/chat_session.dart'],
  ['models/citation_source.dart', 'core/models/citation_source.dart'],
  ['models/network_log.dart', 'core/models/network_log.dart'],
  // ---------------- core/theme / di / network / platform / utils ----------------
  ['theme/app_theme.dart', 'core/theme/app_theme.dart'],
  ['di/app_scope.dart', 'core/di/app_scope.dart'],
  ['services/app_http_client.dart', 'core/network/app_http_client.dart'],
  ['db/env.dart', 'core/platform/env.dart'],
  ['db/env_io.dart', 'core/platform/env_io.dart'],
  ['db/env_web.dart', 'core/platform/env_web.dart'],
  ['db/fs.dart', 'core/platform/fs.dart'],
  ['db/fs_io.dart', 'core/platform/fs_io.dart'],
  ['db/fs_web.dart', 'core/platform/fs_web.dart'],
  ['utils/app_snackbar.dart', 'core/utils/app_snackbar.dart'],
  ['utils/enter_send.dart', 'core/utils/enter_send.dart'],
  ['utils/focus_utils.dart', 'core/utils/focus_utils.dart'],
  ['utils/format_bytes.dart', 'core/utils/format_bytes.dart'],
  ['utils/format_time.dart', 'core/utils/format_time.dart'],
  ['utils/l10n_ext.dart', 'core/utils/l10n_ext.dart'],
  ['utils/load_guarded.dart', 'core/utils/load_guarded.dart'],
  ['utils/logger.dart', 'core/utils/logger.dart'],
  ['utils/prompt_variables.dart', 'core/utils/prompt_variables.dart'],
  ['utils/stream_flusher.dart', 'core/utils/stream_flusher.dart'],
  ['utils/token_counter.dart', 'core/utils/token_counter.dart'],
  ['utils/token_estimator.dart', 'core/utils/token_estimator.dart'],
  // ---------------- core/services（跨域基础服务） ----------------
  ['services/settings_service.dart', 'core/services/settings_service.dart'],
  ['services/session_service.dart', 'core/services/session_service.dart'],
  ['services/session_persistence.dart', 'core/services/session_persistence.dart'],
  [
    'services/session_persistence_factory.dart',
    'core/services/session_persistence_factory.dart',
  ],
  [
    'services/session_persistence_io.dart',
    'core/services/session_persistence_io.dart',
  ],
  [
    'services/session_persistence_web.dart',
    'core/services/session_persistence_web.dart',
  ],
  [
    'services/session_persistence_sqlite.dart',
    'core/services/session_persistence_sqlite.dart',
  ],
  ['services/search_service.dart', 'core/services/search_service.dart'],
  ['services/agent_service.dart', 'core/services/agent_service.dart'],
  ['services/provider_service.dart', 'core/services/provider_service.dart'],
  [
    'services/model_capability_service.dart',
    'core/services/model_capability_service.dart',
  ],
  ['services/network_log_service.dart', 'core/services/network_log_service.dart'],
  [
    'services/network_log_store_io.dart',
    'core/services/network_log_store_io.dart',
  ],
  [
    'services/network_log_store_stub.dart',
    'core/services/network_log_store_stub.dart',
  ],
  [
    'services/secure_credentials_service.dart',
    'core/services/secure_credentials_service.dart',
  ],
  ['services/chat_service.dart', 'core/services/chat_service.dart'],
  ['services/chat_protocol.dart', 'core/services/chat_protocol.dart'],
  ['services/title_generator.dart', 'core/services/title_generator.dart'],
  ['services/theme_controller.dart', 'core/services/theme_controller.dart'],
  ['services/document_extractor.dart', 'core/services/document_extractor.dart'],
  ['services/ocr_service.dart', 'core/services/ocr_service.dart'],
  ['services/tts_service.dart', 'core/services/tts_service.dart'],
  ['services/world_book_service.dart', 'core/services/world_book_service.dart'],
  ['services/storage_io_io.dart', 'core/services/storage_io_io.dart'],
  ['services/storage_io_stub.dart', 'core/services/storage_io_stub.dart'],
  ['services/export_service.dart', 'core/services/export_service.dart'],
  ['services/provider_share_codec.dart', 'core/services/provider_share_codec.dart'],
  ['services/chat/chat_exceptions.dart', 'core/services/chat/chat_exceptions.dart'],
  [
    'services/chat/chat_request_handle.dart',
    'core/services/chat/chat_request_handle.dart',
  ],
  ['services/chat/request_runner.dart', 'core/services/chat/request_runner.dart'],
  ['services/chat/sse_parser.dart', 'core/services/chat/sse_parser.dart'],
  ['services/roulette/key_roulette.dart', 'core/services/roulette/key_roulette.dart'],
  ['services/export/backup_archive.dart', 'core/services/export/backup_archive.dart'],
  ['services/export/import_service.dart', 'core/services/export/import_service.dart'],
  [
    'services/export/session_exporter.dart',
    'core/services/export/session_exporter.dart',
  ],
  ['services/export/pdf_exporter.dart', 'core/services/export/pdf_exporter.dart'],
  [
    'services/export/importers/chatbox_importer.dart',
    'core/services/export/importers/chatbox_importer.dart',
  ],
  [
    'services/export/importers/cherry_importer.dart',
    'core/services/export/importers/cherry_importer.dart',
  ],
  [
    'services/export/importers/importer_factory.dart',
    'core/services/export/importers/importer_factory.dart',
  ],
  [
    'services/export/importers/importer_utils.dart',
    'core/services/export/importers/importer_utils.dart',
  ],
  [
    'services/export/importers/kelivo_importer.dart',
    'core/services/export/importers/kelivo_importer.dart',
  ],
  [
    'services/export/importers/nextchat_importer.dart',
    'core/services/export/importers/nextchat_importer.dart',
  ],
  [
    'services/export/importers/nona_importer.dart',
    'core/services/export/importers/nona_importer.dart',
  ],
  [
    'services/export/importers/openai_importer.dart',
    'core/services/export/importers/openai_importer.dart',
  ],
  [
    'services/export/importers/rikkahub_importer.dart',
    'core/services/export/importers/rikkahub_importer.dart',
  ],
  [
    'services/export/importers/sqlite_importers.dart',
    'core/services/export/importers/sqlite_importers.dart',
  ],
  [
    'services/export/importers/sqlite_importers_io.dart',
    'core/services/export/importers/sqlite_importers_io.dart',
  ],
  [
    'services/export/importers/sqlite_importers_web.dart',
    'core/services/export/importers/sqlite_importers_web.dart',
  ],
  ['services/usage/price_service.dart', 'core/services/usage/price_service.dart'],
  [
    'services/usage/usage_stats_service.dart',
    'core/services/usage/usage_stats_service.dart',
  ],
  ['services/usage/balance_service.dart', 'core/services/usage/balance_service.dart'],
  [
    'services/knowledge/embedding_provider.dart',
    'core/services/knowledge/embedding_provider.dart',
  ],
  ['services/knowledge/kb_retriever.dart', 'core/services/knowledge/kb_retriever.dart'],
  [
    'services/knowledge_base_service.dart',
    'core/services/knowledge_base_service.dart',
  ],
  ['services/memory/memory_service.dart', 'core/services/memory/memory_service.dart'],
  ['services/mcp/approval_policy.dart', 'core/services/mcp/approval_policy.dart'],
  ['services/mcp/local_tools.dart', 'core/services/mcp/local_tools.dart'],
  ['services/mcp/mcp_client.dart', 'core/services/mcp/mcp_client.dart'],
  ['services/mcp/mcp_service.dart', 'core/services/mcp/mcp_service.dart'],
  ['services/mcp/tool_loop.dart', 'core/services/mcp/tool_loop.dart'],
  [
    'services/protocol/protocol_adapter.dart',
    'core/services/protocol/protocol_adapter.dart',
  ],
  [
    'services/protocol/protocol_factory.dart',
    'core/services/protocol/protocol_factory.dart',
  ],
  [
    'services/protocol/openai_adapter.dart',
    'core/services/protocol/openai_adapter.dart',
  ],
  [
    'services/protocol/anthropic_adapter.dart',
    'core/services/protocol/anthropic_adapter.dart',
  ],
  [
    'services/protocol/gemini_adapter.dart',
    'core/services/protocol/gemini_adapter.dart',
  ],
  ['services/sync/sync_clients.dart', 'core/services/sync/sync_clients.dart'],
  ['services/sync/sync_exception.dart', 'core/services/sync/sync_exception.dart'],
  ['services/sync/sync_service.dart', 'core/services/sync/sync_service.dart'],
  ['services/web_search/engines.dart', 'core/services/web_search/engines.dart'],
  [
    'services/web_search/search_engine.dart',
    'core/services/web_search/search_engine.dart',
  ],
  [
    'services/web_search/web_search_service.dart',
    'core/services/web_search/web_search_service.dart',
  ],
  // ---------------- shared ----------------
  ['routes/app_routes.dart', 'shared/app_routes.dart'],
  ['widgets/avatar.dart', 'shared/widgets/avatar.dart'],
  ['widgets/confirm_dialog.dart', 'shared/widgets/confirm_dialog.dart'],
  ['widgets/markdown_view.dart', 'shared/widgets/markdown_view.dart'],
  ['widgets/markdown_math.dart', 'shared/widgets/markdown_math.dart'],
  ['widgets/settings_tiles.dart', 'shared/widgets/settings_tiles.dart'],
  // ---------------- features/chat ----------------
  ['controllers/chat_controller.dart', 'features/chat/controllers/chat_controller.dart'],
  [
    'controllers/chat_run_orchestrator.dart',
    'features/chat/controllers/chat_run_orchestrator.dart',
  ],
  ['controllers/context_builder.dart', 'features/chat/controllers/context_builder.dart'],
  ['controllers/message_ops.dart', 'features/chat/controllers/message_ops.dart'],
  [
    'controllers/attachment_manager.dart',
    'features/chat/controllers/attachment_manager.dart',
  ],
  ['widgets/chat_composer.dart', 'features/chat/widgets/chat_composer.dart'],
  ['widgets/chat_view.dart', 'features/chat/widgets/chat_view.dart'],
  ['widgets/chat_options_form.dart', 'features/chat/widgets/chat_options_form.dart'],
  [
    'widgets/composer_attachment_preview.dart',
    'features/chat/widgets/composer_attachment_preview.dart',
  ],
  ['widgets/composer_buttons.dart', 'features/chat/widgets/composer_buttons.dart'],
  [
    'widgets/composer_input_field.dart',
    'features/chat/widgets/composer_input_field.dart',
  ],
  ['widgets/composer_toolbar.dart', 'features/chat/widgets/composer_toolbar.dart'],
  ['widgets/message_actions.dart', 'features/chat/widgets/message_actions.dart'],
  ['widgets/message_bubble.dart', 'features/chat/widgets/message_bubble.dart'],
  ['widgets/message_content.dart', 'features/chat/widgets/message_content.dart'],
  ['widgets/message_list.dart', 'features/chat/widgets/message_list.dart'],
  ['widgets/message_usage_badge.dart', 'features/chat/widgets/message_usage_badge.dart'],
  ['widgets/summary_card.dart', 'features/chat/widgets/summary_card.dart'],
  ['widgets/load_failed_banner.dart', 'features/chat/widgets/load_failed_banner.dart'],
  ['widgets/tool_approval_dialog.dart', 'features/chat/widgets/tool_approval_dialog.dart'],
  ['widgets/chat_image_view.dart', 'features/chat/widgets/chat_image_view.dart'],
  ['screens/home_screen.dart', 'features/chat/screens/home_screen.dart'],
  ['screens/message_edit_screen.dart', 'features/chat/screens/message_edit_screen.dart'],
  [
    'screens/message_document_screen.dart',
    'features/chat/screens/message_document_screen.dart',
  ],
  ['screens/compare_screen.dart', 'features/chat/screens/compare_screen.dart'],
  // ---------------- features/session ----------------
  ['controllers/session_manager.dart', 'features/session/controllers/session_manager.dart'],
  ['widgets/session_grouper.dart', 'features/session/widgets/session_grouper.dart'],
  ['widgets/session_list_item.dart', 'features/session/widgets/session_list_item.dart'],
  ['widgets/session_sidebar.dart', 'features/session/widgets/session_sidebar.dart'],
  // ---------------- features/provider ----------------
  [
    'screens/provider_edit_screen.dart',
    'features/provider/screens/provider_edit_screen.dart',
  ],
  [
    'screens/provider_list_screen.dart',
    'features/provider/screens/provider_list_screen.dart',
  ],
  ['widgets/provider_form_fields.dart', 'features/provider/widgets/provider_form_fields.dart'],
  ['widgets/provider_share_dialog.dart', 'features/provider/widgets/provider_share_dialog.dart'],
  // ---------------- features/model ----------------
  ['screens/model_config_screen.dart', 'features/model/screens/model_config_screen.dart'],
  ['widgets/add_model_dialog.dart', 'features/model/widgets/add_model_dialog.dart'],
  ['widgets/model_settings_dialog.dart', 'features/model/widgets/model_settings_dialog.dart'],
  ['services/model_resolver.dart', 'features/model/services/model_resolver.dart'],
  // ---------------- features/agent ----------------
  ['screens/agent_edit_screen.dart', 'features/agent/screens/agent_edit_screen.dart'],
  ['screens/agent_list_screen.dart', 'features/agent/screens/agent_list_screen.dart'],
  // ---------------- features/mcp ----------------
  ['screens/mcp_servers_screen.dart', 'features/mcp/screens/mcp_servers_screen.dart'],
  // ---------------- features/search ----------------
  ['screens/search_screen.dart', 'features/search/screens/search_screen.dart'],
  // ---------------- features/knowledge ----------------
  [
    'screens/knowledge_base_screen.dart',
    'features/knowledge/screens/knowledge_base_screen.dart',
  ],
  // ---------------- features/memory ----------------
  ['screens/memory_screen.dart', 'features/memory/screens/memory_screen.dart'],
  // ---------------- features/world_book ----------------
  ['screens/world_book_screen.dart', 'features/world_book/screens/world_book_screen.dart'],
  // ---------------- features/sync ----------------
  ['screens/sync_screen.dart', 'features/sync/screens/sync_screen.dart'],
  // ---------------- features/export ----------------
  [
    'screens/import_wizard_screen.dart',
    'features/export/screens/import_wizard_screen.dart',
  ],
  // ---------------- features/stats ----------------
  ['screens/stats_screen.dart', 'features/stats/screens/stats_screen.dart'],
  // ---------------- features/imggen ----------------
  ['screens/imggen_screen.dart', 'features/imggen/screens/imggen_screen.dart'],
  ['services/images_adapter.dart', 'features/imggen/services/images_adapter.dart'],
  // ---------------- features/translator ----------------
  ['screens/translator_screen.dart', 'features/translator/screens/translator_screen.dart'],
  // ---------------- features/settings ----------------
  ['screens/settings_screen.dart', 'features/settings/screens/settings_screen.dart'],
  ['screens/preferences_screen.dart', 'features/settings/screens/preferences_screen.dart'],
  [
    'screens/theme_settings_screen.dart',
    'features/settings/screens/theme_settings_screen.dart',
  ],
  [
    'screens/context_settings_screen.dart',
    'features/settings/screens/context_settings_screen.dart',
  ],
  [
    'screens/developer_options_screen.dart',
    'features/settings/screens/developer_options_screen.dart',
  ],
  ['screens/about_screen.dart', 'features/settings/screens/about_screen.dart'],
  [
    'screens/network_log_screen.dart',
    'features/settings/screens/network_log_screen.dart',
  ],
  [
    'screens/network_log_body_screen.dart',
    'features/settings/screens/network_log_body_screen.dart',
  ],
  [
    'screens/network_log_detail_screen.dart',
    'features/settings/screens/network_log_detail_screen.dart',
  ],
];

/// 测试文件映射（镜像 lib 移动；无映射的测试文件原地保留）。
const List<List<String>> kTestMoves = [
  ['db/session_persistence_sqlite_test.dart', 'core/database/session_persistence_sqlite_test.dart'],
  ['db/session_service_test.dart', 'core/services/session_service_test.dart'],
  ['controllers/chat_controller_test.dart', 'features/chat/controllers/chat_controller_test.dart'],
  ['controllers/chat_controller_parts_test.dart', 'features/chat/controllers/chat_controller_parts_test.dart'],
  ['controllers/chat_message_images_test.dart', 'features/chat/controllers/chat_message_images_test.dart'],
  ['controllers/context_builder_compaction_test.dart', 'features/chat/controllers/context_builder_compaction_test.dart'],
  ['models/models_roundtrip_test.dart', 'core/models/models_roundtrip_test.dart'],
  ['routes/app_routes_test.dart', 'shared/app_routes_test.dart'],
  ['screens/add_model_dialog_test.dart', 'features/model/widgets/add_model_dialog_test.dart'],
  ['screens/agent_edit_screen_test.dart', 'features/agent/screens/agent_edit_screen_test.dart'],
  ['screens/agent_list_screen_test.dart', 'features/agent/screens/agent_list_screen_test.dart'],
  ['screens/context_settings_screen_test.dart', 'features/settings/screens/context_settings_screen_test.dart'],
  ['screens/message_edit_screen_test.dart', 'features/chat/screens/message_edit_screen_test.dart'],
  ['screens/overflow_test.dart', 'features/chat/screens/overflow_test.dart'],
  ['screens/settings_cleanup_test.dart', 'features/settings/screens/settings_cleanup_test.dart'],
  ['screens/widget_test.dart', 'features/chat/screens/widget_test.dart'],
  ['services/agent_memory_test.dart', 'core/services/agent_memory_test.dart'],
  ['services/agent_service_test.dart', 'core/services/agent_service_test.dart'],
  ['services/capability_service_test.dart', 'core/services/capability_service_test.dart'],
  ['services/document_extractor_test.dart', 'core/services/document_extractor_test.dart'],
  ['services/knowledge_base_test.dart', 'core/services/knowledge_base_test.dart'],
  ['services/network_log_service_test.dart', 'core/services/network_log_service_test.dart'],
  ['services/network_log_store_io_test.dart', 'core/services/network_log_store_io_test.dart'],
  ['services/prompt_variables_test.dart', 'core/utils/prompt_variables_test.dart'],
  ['services/provider_debug_test.dart', 'core/services/provider_debug_test.dart'],
  ['services/provider_service_test.dart', 'core/services/provider_service_test.dart'],
  ['services/provider_share_codec_test.dart', 'core/services/provider_share_codec_test.dart'],
  ['services/search_service_test.dart', 'core/services/search_service_test.dart'],
  ['services/settings_service_test.dart', 'core/services/settings_service_test.dart'],
  ['services/storage_io_test.dart', 'core/services/storage_io_test.dart'],
  ['services/theme_controller_test.dart', 'core/services/theme_controller_test.dart'],
  ['services/tts_service_test.dart', 'core/services/tts_service_test.dart'],
  ['services/world_book_service_test.dart', 'core/services/world_book_service_test.dart'],
  ['services/chat/chat_service_test.dart', 'core/services/chat/chat_service_test.dart'],
  ['services/export/export_service_test.dart', 'core/services/export/export_service_test.dart'],
  ['services/export/importer_new_formats_test.dart', 'core/services/export/importer_new_formats_test.dart'],
  ['services/knowledge/knowledge_multi_library_test.dart', 'core/services/knowledge/knowledge_multi_library_test.dart'],
  ['services/mcp/approval_tool_loop_test.dart', 'core/services/mcp/approval_tool_loop_test.dart'],
  ['services/mcp/mcp_test.dart', 'core/services/mcp/mcp_test.dart'],
  ['services/memory/memory_service_test.dart', 'core/services/memory/memory_service_test.dart'],
  ['services/protocol/chat_protocol_test.dart', 'core/services/protocol/chat_protocol_test.dart'],
  ['services/protocol/tool_loop_protocol_test.dart', 'core/services/protocol/tool_loop_protocol_test.dart'],
  ['services/roulette/key_roulette_test.dart', 'core/services/roulette/key_roulette_test.dart'],
  ['services/sync/sync_test.dart', 'core/services/sync/sync_test.dart'],
  ['services/usage/balance_service_test.dart', 'core/services/usage/balance_service_test.dart'],
  ['services/usage/price_service_test.dart', 'core/services/usage/price_service_test.dart'],
  ['services/web_search/web_search_test.dart', 'core/services/web_search/web_search_test.dart'],
  ['theme/theme_test.dart', 'core/theme/theme_test.dart'],
  ['utils/enter_send_test.dart', 'core/utils/enter_send_test.dart'],
  ['utils/stream_flusher_test.dart', 'core/utils/stream_flusher_test.dart'],
  ['utils/token_counter_test.dart', 'core/utils/token_counter_test.dart'],
  ['utils/token_estimator_test.dart', 'core/utils/token_estimator_test.dart'],
  ['utils/token_o200k_test.dart', 'core/utils/token_o200k_test.dart'],
  ['widgets/l10n_test.dart', 'shared/widgets/l10n_test.dart'],
  ['widgets/markdown_math_test.dart', 'shared/widgets/markdown_math_test.dart'],
  ['widgets/markdown_math_widget_test.dart', 'shared/widgets/markdown_math_widget_test.dart'],
  ['widgets/widgets_test.dart', 'features/chat/widgets/widgets_test.dart'],
];

/// 目录内的相对路径解析（POSIX 风格）。
String _join(String a, String b) {
  final p = '$a/$b';
  final parts = <String>[];
  for (final seg in p.split('/')) {
    if (seg == '' || seg == '.') continue;
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
      continue;
    }
    parts.add(seg);
  }
  return parts.join('/');
}

/// 从 from 目录到 to 文件的相对路径。
String _relative(String from, String to) {
  final fromParts = from.split('/').where((s) => s.isNotEmpty).toList();
  final toParts = to.split('/');
  var common = 0;
  while (common < fromParts.length &&
      common < toParts.length - 1 &&
      fromParts[common] == toParts[common]) {
    common++;
  }
  final ups = List.filled(fromParts.length - common, '..');
  final downs = toParts.sublist(common);
  return [...ups, ...downs].join('/');
}

/// 重写单个文件里的 import/export/part URI（全量收敛）。
/// [oldDir]：该文件移动前的目录（当前 import URI 的解析基准）；
/// [newDir]：该文件移动后的目录（重写相对路径的基准）；
/// [resolve]：lib/test 根相对路径 → 最终目标路径（moves ∪ 恒等）。
void _rewriteFileWithDirs(
  File file,
  String oldDir,
  String newDir,
  Map<String, String> resolve,
) {
  final content = file.readAsStringSync();
  // 匹配整条指令（含条件导入跨行），然后对指令内所有引号 URI 逐一重写
  final directiveRe = RegExp(
    r"""\b(import|export|part)\s+(?:deferred\s+as\s+\w+\s+)?(['"])([^'"]+)\2.*?;""",
    dotAll: true,
  );
  final uriRe = RegExp(r"""(['"])([^'"]+)\1""");
  var rewritten = false;
  final buffer = StringBuffer();
  var last = 0;
  for (final m in directiveRe.allMatches(content)) {
    buffer.write(content.substring(last, m.start));
    final directive = m.group(0)!;
    var newDirective = directive;
    for (final u in uriRe.allMatches(directive).toList().reversed) {
      final quote = u.group(1)!;
      final uri = u.group(2)!;
      if (uri.startsWith('dart:') || uri.startsWith('asset:')) continue;
      final newUri = uri.startsWith('package:')
          ? _rewritePackageUri(uri, resolve)
          : _rewriteRelativeUri(uri, oldDir, newDir, resolve);
      if (newUri != uri) {
        newDirective = newDirective.replaceRange(
          u.start,
          u.end,
          '$quote$newUri$quote',
        );
        rewritten = true;
      }
    }
    buffer.write(newDirective);
    last = m.end;
  }
  buffer.write(content.substring(last));
  if (rewritten) {
    file.writeAsStringSync(buffer.toString());
  }
}

/// 重写相对 URI：按旧目录解析（映射命中则换成新目标路径），
/// 再按新目录重算相对路径。目标未移动也重算（文件本身移动了）。
String _rewriteRelativeUri(
  String uri,
  String oldDir,
  String newDir,
  Map<String, String> resolve,
) {
  final resolved = resolve[_join(oldDir, uri)] ?? _join(oldDir, uri);
  return _relative(newDir, resolved);
}

/// 重写 package:nona_chat/... URI（lib 根相对路径映射；未移动目标原样保留）。
String _rewritePackageUri(String uri, Map<String, String> resolve) {
  if (!uri.startsWith('package:nona_chat/')) return uri;
  final rel = uri.substring('package:nona_chat/'.length);
  final resolved = resolve[rel] ?? rel;
  return 'package:nona_chat/$resolved';
}

void main(List<String> args) {
  final root = Directory.current.path;
  final apply = args.contains('apply');
  final rewriteOnly = args.contains('rewrite');

  final libMoves = <String, String>{for (final m in kMoves) m[0]: m[1]};
  final testMoves = <String, String>{for (final m in kTestMoves) m[0]: m[1]};

  // 1. 移动文件
  var moved = 0;
  if (apply && !rewriteOnly) {
    for (final e in libMoves.entries) {
      final src = File('$root/lib/${e.key}');
      if (!src.existsSync()) {
        stderr.writeln('MISSING lib/${e.key}');
        continue;
      }
      final dst = File('$root/lib/${e.value}');
      dst.parent.createSync(recursive: true);
      src.renameSync(dst.path);
      moved++;
    }
    for (final e in testMoves.entries) {
      final src = File('$root/test/${e.key}');
      if (!src.existsSync()) {
        stderr.writeln('MISSING test/${e.key}');
        continue;
      }
      final dst = File('$root/test/${e.value}');
      dst.parent.createSync(recursive: true);
      src.renameSync(dst.path);
      moved++;
    }
  } else if (!rewriteOnly) {
    moved = libMoves.length + testMoves.length;
    final missing = <String>[];
    for (final e in libMoves.entries) {
      if (!File('$root/lib/${e.key}').existsSync()) missing.add('lib/${e.key}');
    }
    for (final e in testMoves.entries) {
      if (!File('$root/test/${e.key}').existsSync()) missing.add('test/${e.key}');
    }
    if (missing.isNotEmpty) {
      stderr.writeln('缺失 ${missing.length} 个源文件：');
      for (final m in missing) {
        stderr.writeln('  $m');
      }
      exitCode = 1;
      return;
    }
    // 未映射的 lib 文件检查（防遗漏）
    final unmapped = <String>[];
    void walk(Directory dir) {
      for (final e in dir.listSync()) {
        if (e is Directory) {
          if (e.path.endsWith(r'\core') ||
              e.path.endsWith(r'\l10n') ||
              e.path.endsWith(r'\database')) {
            continue;
          }
          walk(e);
        } else if (e.path.endsWith('.dart')) {
          final rel = e.path.replaceAll(r'\', '/').split('/lib/').last;
          if (!libMoves.containsKey(rel) &&
              rel != 'main.dart' &&
              rel != 'version.dart' &&
              !rel.startsWith('core/') &&
              !rel.startsWith('l10n/')) {
            unmapped.add(rel);
          }
        }
      }
    }
    walk(Directory('$root/lib'));
    if (unmapped.isNotEmpty) {
      stderr.writeln('未映射的 lib 文件（需加入 kMoves）：');
      for (final u in unmapped) {
        stderr.writeln('  $u');
      }
    }
  }
  stdout.writeln('移动 ${apply ? moved : '（校验模式，未执行）'} 个文件');

  // 2. 重写 import（全量收敛）
  // 文件已移动后，其 import URI 按「旧目录」书写——用反向映射找到旧目录
  // 解析 URI，再按「新目录」重算目标相对路径；resolve 为 moves ∪ 恒等。
  var rewritten = 0;
  final allMoves = {...libMoves, ...testMoves};
  final reverse = <String, String>{for (final e in allMoves.entries) e.value: e.key};
  final resolve = <String, String>{
    for (final e in allMoves.entries) e.key: e.value,
    for (final e in allMoves.entries) e.value: e.value,
  };
  void walk(Directory dir) {
    for (final e in dir.listSync()) {
      if (e is Directory) {
        walk(e);
      } else if (e.path.endsWith('.dart')) {
        final abs = e.path.replaceAll(r'\', '/');
        final rel = abs.contains('/lib/')
            ? abs.split('/lib/').last
            : abs.split('/test/').last;
        final oldRel = reverse[rel] ?? rel;
        String dirOf(String p) =>
            p.lastIndexOf('/') == -1 ? '' : p.substring(0, p.lastIndexOf('/'));
        final newDir = dirOf(rel);
        final oldDir = dirOf(oldRel);
        final before = File(e.path).readAsStringSync();
        _rewriteFileWithDirs(File(e.path), oldDir, newDir, resolve);
        if (File(e.path).readAsStringSync() != before) rewritten++;
      }
    }
  }
  walk(Directory('$root/lib'));
  walk(Directory('$root/test'));
  stdout.writeln('重写 $rewritten 个文件的 import');

  // 3. 清理空目录
  if (apply) {
    void prune(Directory dir) {
      for (final e in dir.listSync(followLinks: false)) {
        if (e is Directory) prune(e);
      }
      if (dir.listSync().isEmpty) {
        try {
          dir.deleteSync();
        } catch (_) {}
      }
    }
    prune(Directory('$root/lib'));
    prune(Directory('$root/test'));
  }
}
