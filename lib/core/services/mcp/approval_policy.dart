import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mcp_service.dart' show McpServerConfig;

/// 一次工具调用的审批决定。
class ApprovalDecision {
  final bool allowed;

  /// 记住该决定（同服务同工具后续自动放行）。
  final bool remember;

  const ApprovalDecision({required this.allowed, this.remember = false});

  static const allow = ApprovalDecision(allowed: true);
  static const allowAndRemember = ApprovalDecision(allowed: true, remember: true);
  static const deny = ApprovalDecision(allowed: false);
}

/// MCP 工具审批策略。
///
/// 策略持久化于 prefs `mcp_approval_policy_<serverId>`：
/// `{"mode": "always|on_approval|auto", "remembered": {"toolName": ts}}`。
///
/// - mode `auto`：全部工具免审批（用户显式选择）
/// - mode `on_approval`（默认，未显式配置时等同 `needsApproval ?? true`）：
///   每次调用弹窗确认
/// - mode `always`：服务端配置 needsApproval 时强制弹窗，但仍可「记住并允许」
/// - 已被记住的工具直接放行
class ApprovalPolicy {
  static const String modeAlways = 'always';
  static const String modeOnApproval = 'on_approval';
  static const String modeAuto = 'auto';

  static const String _kPrefix = 'mcp_approval_policy_';

  static Future<Map<String, dynamic>> _load(String serverId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_kPrefix$serverId');
    if (raw == null || raw.isEmpty) return const {};
    try {
      final data = jsonDecode(raw);
      return data is Map<String, dynamic> ? data : const {};
    } catch (_) {
      return const {};
    }
  }

  static Future<void> _save(String serverId, Map<String, dynamic> policy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kPrefix$serverId', jsonEncode(policy));
  }

  /// 当前策略模式；未配置时按服务端 needsApproval 推导。
  static Future<String> modeFor(McpServerConfig server) async {
    final policy = await _load(server.id);
    final explicit = policy['mode'] as String?;
    if (explicit != null) return explicit;
    return server.needsApproval ? modeAlways : modeOnApproval;
  }

  /// 设置策略模式（null 清除自定义模式，回退服务端配置）。
  static Future<void> setMode(String serverId, String? mode) async {
    final policy = Map<String, dynamic>.from(await _load(serverId));
    if (mode == null) {
      policy.remove('mode');
    } else {
      policy['mode'] = mode;
    }
    await _save(serverId, policy);
  }

  /// 记住「允许」决定。
  static Future<void> remember(String serverId, String toolName) async {
    final policy = Map<String, dynamic>.from(await _load(serverId));
    final remembered = Map<String, dynamic>.from(
      policy['remembered'] as Map<String, dynamic>? ?? const {},
    );
    remembered[toolName] = DateTime.now().millisecondsSinceEpoch;
    policy['remembered'] = remembered;
    await _save(serverId, policy);
  }

  /// 撤销对某个工具的记住。
  static Future<void> forget(String serverId, String toolName) async {
    final policy = Map<String, dynamic>.from(await _load(serverId));
    final remembered = Map<String, dynamic>.from(
      policy['remembered'] as Map<String, dynamic>? ?? const {},
    );
    remembered.remove(toolName);
    policy['remembered'] = remembered;
    await _save(serverId, policy);
  }

  /// 已记住的工具名列表。
  static Future<List<String>> rememberedTools(String serverId) async {
    final policy = await _load(serverId);
    final remembered = policy['remembered'] as Map<String, dynamic>? ?? {};
    return remembered.keys.toList();
  }

  /// 该服务该工具是否需要人工审批。
  ///
  /// 默认语义：未显式配置策略时按 `needsApproval ?? true` 决定
  /// （竞品默认均需审批，避免外部工具无感知执行）。
  static Future<bool> needsApproval(
    McpServerConfig server,
    String toolName,
  ) async {
    final policy = await _load(server.id);
    final mode = policy['mode'] as String? ??
        (server.needsApproval ? modeAlways : modeOnApproval);
    if (mode == modeAuto) return false;
    final remembered = policy['remembered'] as Map<String, dynamic>? ?? {};
    if (remembered.containsKey(toolName)) return false;
    return true;
  }
}
