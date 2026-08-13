import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/mcp/mcp_client.dart';
import '../../../core/services/mcp/mcp_service.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/load_guarded.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/load_failed_banner.dart';

/// MCP 服务管理页：列表 / 添加 / 编辑 / 启停。
class McpServersScreen extends StatefulWidget {
  const McpServersScreen({super.key});

  @override
  State<McpServersScreen> createState() => _McpServersScreenState();
}

class _McpServersScreenState extends State<McpServersScreen> {
  late final McpService _service = context.read<McpService>();
  List<McpServerConfig> _servers = [];
  bool _loaded = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final servers = await loadGuarded<List<McpServerConfig>>(
      _service.load,
      label: 'mcp_servers',
    );
    if (!mounted) return;
    setState(() {
      if (servers != null) _servers = servers;
      _loaded = true;
      _loadFailed = servers == null;
    });
  }

  Future<void> _save() => _service.save(_servers);

  /// 保存并上浮失败提示（启停开关等高频入口使用）。
  Future<void> _saveWithFeedback() async {
    try {
      await _save();
    } catch (e) {
      Logger.error('mcp', '保存失败', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.commonSaveFailed)),
        );
      }
    }
  }

  Future<void> _add() async {
    final config = await _editDialog(null);
    if (config == null || !mounted) return;
    setState(() => _servers = [..._servers, config]);
    await _save();
  }

  Future<void> _edit(McpServerConfig server) async {
    final config = await _editDialog(server);
    if (config == null || !mounted) return;
    setState(() {
      final index = _servers.indexWhere((s) => s.id == server.id);
      if (index >= 0) _servers[index] = config;
    });
    await _save();
  }

  Future<void> _delete(McpServerConfig server) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.commonDelete,
      message: context.l10n.mcpDeleteConfirm(server.name),
      confirmText: context.l10n.commonDelete,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _servers.removeWhere((s) => s.id == server.id));
    await _save();
  }

  /// 添加/编辑对话框；返回 null 表示取消。
  Future<McpServerConfig?> _editDialog(McpServerConfig? existing) {
    return showDialog<McpServerConfig>(
      context: context,
      builder: (ctx) => _McpServerEditDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.mcpTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: context.l10n.mcpAdd,
            onPressed: _add,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_loadFailed) LoadFailedBanner(onRetry: _load),
            Expanded(
              child: !_loaded
                  ? const Center(child: CircularProgressIndicator())
                  : _servers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.extension_outlined,
                            size: 42,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.mcpEmpty,
                            style: TextStyle(color: theme.colorScheme.outline),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.mcpEmptyHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        for (final server in _servers)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 2,
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      server.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                            if (!server.enabled) ...[
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.commonOff,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          server.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: server.enabled,
                              onChanged: (v) {
                                setState(() => server.enabled = v);
                                unawaited(_saveWithFeedback());
                              },
                            ),
                            PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _edit(server);
                                } else if (action == 'delete') {
                                  _delete(server);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(context.l10n.commonEdit),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(context.l10n.commonDelete),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.mcpHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 添加/编辑对话框内容：持有输入控制器，随路由生命周期创建/销毁。
class _McpServerEditDialog extends StatefulWidget {
  const _McpServerEditDialog({this.existing});

  final McpServerConfig? existing;

  @override
  State<_McpServerEditDialog> createState() => _McpServerEditDialogState();
}

class _McpServerEditDialogState extends State<_McpServerEditDialog> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _urlController =
      TextEditingController(text: widget.existing?.url ?? '');
  late final TextEditingController _headersController = TextEditingController(
    text: widget.existing == null
        ? ''
        : widget.existing!.headers.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n'),
  );
  late bool _needsApproval = widget.existing?.needsApproval ?? false;

  // F-01：传输类型与 stdio 配置
  late String _transport = widget.existing?.transport ?? 'http';
  late final TextEditingController _commandController =
      TextEditingController(text: widget.existing?.stdio?.command ?? '');
  late final TextEditingController _argsController = TextEditingController(
    text: (widget.existing?.stdio?.args ?? const []).join('\n'),
  );
  late final TextEditingController _envController = TextEditingController(
    text: (widget.existing?.stdio?.env ?? const {})
        .entries
        .map((e) => '${e.key}=${e.value}')
        .join('\n'),
  );
  late final TextEditingController _cwdController =
      TextEditingController(text: widget.existing?.stdio?.cwd ?? '');

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _headersController.dispose();
    _commandController.dispose();
    _argsController.dispose();
    _envController.dispose();
    _cwdController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty ||
        _urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.mcpFieldsRequired)),
      );
      return;
    }
    if (_transport == 'stdio' && _commandController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.mcpCommandNotFound(''))),
      );
      return;
    }
    final headers = <String, String>{};
    for (final line in _headersController.text.split('\n')) {
      final colon = line.indexOf(':');
      if (colon > 0) {
        headers[line.substring(0, colon).trim()] =
            line.substring(colon + 1).trim();
      }
    }
    final env = <String, String>{};
    for (final line in _envController.text.split('\n')) {
      final eq = line.indexOf('=');
      if (eq > 0) {
        env[line.substring(0, eq).trim()] = line.substring(eq + 1).trim();
      }
    }
    Navigator.of(context).pop(
      McpServerConfig(
        id: widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        url: _urlController.text.trim(),
        headers: headers,
        enabled: widget.existing?.enabled ?? true,
        needsApproval: _needsApproval,
        transport: _transport,
        stdio: _transport == 'stdio'
            ? StdioConfig(
                command: _commandController.text.trim(),
                args: [
                  for (final a in _argsController.text.split('\n'))
                    if (a.trim().isNotEmpty) a.trim(),
                ],
                env: env,
                cwd: _cwdController.text.trim().isEmpty
                    ? null
                    : _cwdController.text.trim(),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isWeb = const bool.fromEnvironment('dart.library.js_interop');
    return AlertDialog(
      title: Text(
        widget.existing == null ? l10n.mcpAdd : l10n.mcpEdit,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.mcpName,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              // F-01：传输类型（Web 隐藏 stdio）
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.mcpTransport,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _transport,
                    onChanged: (v) {
                      if (v != null) setState(() => _transport = v);
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'http',
                        child: Text(l10n.mcpTransportHttp),
                      ),
                      if (!isWeb)
                        DropdownMenuItem(
                          value: 'stdio',
                          child: Text(l10n.mcpTransportStdio),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: _transport == 'stdio'
                      ? l10n.mcpUrl
                      : l10n.mcpUrl,
                  hintText: _transport == 'stdio'
                      ? 'stdio://server-id'
                      : 'https://example.com/mcp',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              if (_transport == 'stdio') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _commandController,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.mcpStdioCommand,
                    hintText: 'npx / node / python',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _argsController,
                  maxLines: 3,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.mcpStdioArgs,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _envController,
                  maxLines: 3,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.mcpStdioEnv,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cwdController,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.mcpStdioCwd,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _headersController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.mcpHeaders,
                    hintText: 'Authorization: Bearer xxx',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  l10n.mcpNeedsApproval,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  l10n.mcpNeedsApprovalHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                value: _needsApproval,
                onChanged: (v) => setState(() => _needsApproval = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
