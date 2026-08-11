import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/format_bytes.dart';
import '../utils/l10n_ext.dart';
/// 全文查看页：虚拟化逐行渲染大段日志正文，支持跨行选择、复制与 JSON 格式化。
class NetworkLogBodyScreen extends StatefulWidget {
  final String title;
  final String body;
  final int bytes;

  const NetworkLogBodyScreen({
    super.key,
    required this.title,
    required this.body,
    required this.bytes,
  });

  @override
  State<NetworkLogBodyScreen> createState() => _NetworkLogBodyScreenState();
}

class _NetworkLogBodyScreenState extends State<NetworkLogBodyScreen> {
  /// 是否已切换到格式化后的 JSON。
  bool _jsonFormatted = false;

  /// 格式化后的 JSON 文本；null 表示尚未格式化（或内容非 JSON）。
  String? _formattedJson;

  /// 已按当前展示文本拆分的行缓存（避免每次 build 重拆超大正文）。
  List<String>? _cachedLines;
  String? _cachedText;

  String get _displayText =>
      _jsonFormatted ? (_formattedJson ?? widget.body) : widget.body;

  /// 拆分展示文本为行；仅在文本变化时重算。
  List<String> get _lines {
    final text = _displayText;
    if (_cachedText != text) {
      _cachedText = text;
      _cachedLines = text.split('\n');
    }
    return _cachedLines!;
  }

  Future<void> _copyAll(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _displayText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.networkLogCopiedFull)),
    );
  }

  /// 尝试将正文解析并格式化为易读的 JSON；非 JSON 时提示并保持原文。
  void _toggleJsonFormat() {
    if (_formattedJson == null) {
      try {
        final decoded = jsonDecode(widget.body);
        _formattedJson = const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.networkLogInvalidJson)),
        );
        return;
      }
    }
    setState(() => _jsonFormatted = !_jsonFormatted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 预拆分为行，交给 ListView.builder 虚拟化渲染，避免一次性构建全部文本
    final lines = _lines;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(
              _jsonFormatted
                  ? Icons.data_object_rounded
                  : Icons.format_indent_increase_rounded,
            ),
            tooltip: _jsonFormatted
                ? context.l10n.networkLogShowRaw
                : context.l10n.networkLogFormatJson,
            onPressed: _toggleJsonFormat,
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: context.l10n.networkLogCopyFull,
            onPressed: () => _copyAll(context),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 信息栏：行数 + 大小
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: theme.colorScheme.surfaceContainerLow,
              child: Text(
                context.l10n.networkLogBodyMeta(
                  formatBytes(widget.bytes),
                  lines.length,
                ) + (_jsonFormatted ? context.l10n.networkLogFormatted : ''),
                style: TextStyle(
                  fontSize: 11.5,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            Expanded(
              child: SelectionArea(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: lines.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 1,
                    ),
                    child: Text(
                      lines[i],
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
