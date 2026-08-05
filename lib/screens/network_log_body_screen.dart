import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 字节数格式化：B / KB / MB。
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

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

  String get _displayText =>
      _jsonFormatted ? (_formattedJson ?? widget.body) : widget.body;

  Future<void> _copyAll(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _displayText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制全文')),
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
          const SnackBar(content: Text('内容不是有效的 JSON，无法格式化')),
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
    final lines = _displayText.split('\n');
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
            tooltip: _jsonFormatted ? '显示原文' : '格式化 JSON',
            onPressed: _toggleJsonFormat,
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: '复制全文',
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
                '${lines.length} 行 · ${formatBytes(widget.bytes)}'
                '${_jsonFormatted ? ' · 已格式化' : ''}',
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
