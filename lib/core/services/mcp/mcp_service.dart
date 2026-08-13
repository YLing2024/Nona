import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/logger.dart';
import 'mcp_client.dart';

/// 一个 MCP 服务配置。
class McpServerConfig {
  final String id;
  String name;

  /// 服务地址（Streamable HTTP endpoint）。
  String url;

  /// 自定义请求头（如 Authorization）。
  Map<String, String> headers;

  /// 启用状态。
  bool enabled;

  /// 工具是否需要人工确认（默认 false 自动执行）。
  bool needsApproval;

  McpServerConfig({
    required this.id,
    required this.name,
    required this.url,
    this.headers = const {},
    this.enabled = true,
    this.needsApproval = false,
  });

  factory McpServerConfig.fromJson(Map<String, dynamic> json) =>
      McpServerConfig(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
        headers: _stringMap(json['headers']),
        enabled: json['enabled'] as bool? ?? true,
        needsApproval: json['needsApproval'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'headers': headers,
    'enabled': enabled,
    'needsApproval': needsApproval,
  };

  static Map<String, String> _stringMap(Object? v) {
    if (v is! Map) return const {};
    return {
      for (final e in v.entries) e.key.toString(): e.value.toString(),
    };
  }
}

/// MCP 服务管理与工具聚合。
class McpService {
  static const _kServers = 'mcp_servers';

  Future<List<McpServerConfig>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kServers);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          if (e is Map<String, dynamic>)
            McpServerConfig.fromJson(e),
      ];
    } catch (e) {
      Logger.error('mcp', 'MCP config corrupt', e);
      return [];
    }
  }

  Future<void> save(List<McpServerConfig> servers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kServers,
      jsonEncode(servers.map((s) => s.toJson()).toList()),
    );
  }

  /// 收集全部启用服务的工具（跳过失败的服务器）。
  Future<Map<String, McpToolDefinition>> collectTools(
    List<McpServerConfig> servers,
  ) async {
    final tools = <String, McpToolDefinition>{};
    for (final server in servers) {
      if (!server.enabled) continue;
      try {
        final client = McpClient(
          baseUrl: server.url,
          headers: server.headers,
        );
        final list = await client.listTools();
        for (final tool in list) {
          if (tool.name.isEmpty) continue;
          tools['${server.id}__${tool.name}'] = tool;
        }
      } catch (e) {
        Logger.warn('mcp', 'failed to fetch tools: $e');
        Logger.error('mcp', 'tools/list failed', e);
      }
    }
    return tools;
  }

  /// 按工具原始名定位所属服务并调用。
  ///
  /// [tools] 为 [collectTools] 的完整结果（key 为 `serverId__toolName`，
  /// value 保留原始工具名）；模型返回的是原始名，这里反查命名空间 key
  /// 定位服务，避免把 `serverId__` 前缀暴露给模型。
  Future<McpToolResult> callTool(
    List<McpServerConfig> servers,
    Map<String, McpToolDefinition> tools,
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    for (final entry in tools.entries) {
      if (entry.value.name != toolName) continue;
      final separator = entry.key.indexOf('__');
      if (separator <= 0) {
        throw McpException('invalid tool name format: ${entry.key}');
      }
      final serverId = entry.key.substring(0, separator);
      final server = servers.where((s) => s.id == serverId).firstOrNull;
      if (server == null) throw McpException('server not found: $serverId');
      final client = McpClient(baseUrl: server.url, headers: server.headers);
      return client.callTool(toolName, arguments);
    }
    throw McpException('tool not found: $toolName');
  }
}

/// 内置本地工具：URL 抓取（HTML → 纯文本）。
class BuiltinFetchTool {
  static const name = 'fetch';

  static const description = 'Fetch the content of a URL and convert it to plain text, '
      'For scenarios that need to fetch and read web pages.';

  static const Map<String, dynamic> inputSchema = {
    'type': 'object',
    'properties': {
      'url': {'type': 'string', 'description': 'The URL of the web page to fetch'},
      'maxLength': {
        'type': 'integer',
        'description': 'Maximum characters to return (default 20000)',
      },
    },
    'required': ['url'],
  };
}
