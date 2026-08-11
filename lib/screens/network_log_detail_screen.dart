import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/network_log_service.dart';
import '../services/storage_io_io.dart'
    if (dart.library.js_interop) '../services/storage_io_stub.dart'
    as storage_io;
import '../utils/l10n_ext.dart';
import '../utils/format_bytes.dart';
import '../routes/app_routes.dart';
import '../utils/format_time.dart';

/// 网络日志详情页：展示单条请求的完整信息（基本/请求/响应）。
class NetworkLogDetailScreen extends StatelessWidget {
  final NetworkLog log;

  const NetworkLogDetailScreen({super.key, required this.log});

  /// 外部编辑器仅在桌面端可用；移动端/Web 使用内置全文查看页。
  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  String _fullTime(DateTime t) => formatFullTime(t);

  /// 根据正文内容猜测文件扩展名（JSON 用 .json 便于编辑器高亮）。
  String _guessExtension(String body) {
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) return 'json';
    return 'txt';
  }

  /// 在外部编辑器中打开完整正文。
  void _openInEditor(BuildContext context, String label, String body) {
    final ok = storage_io.openInEditor(
      'nona-log-$label-${log.id}.${_guessExtension(body)}',
      body,
    );
    ok.then((success) {
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.networkLogEditorUnsupported)),
        );
      }
    });
  }

  /// 正文卡片标题行右侧操作：内置「查看全文」+ 桌面端「外部编辑器」。
  Widget? _bodyActions(BuildContext context, String label, String body, int bytes) {
    if (body.isEmpty) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            AppRoutes.networkLogBody(
              title: context.l10n.networkLogFullTitle(label),
              body: body,
              bytes: bytes,
            ),
          ),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.open_in_full, size: 14),
          label: Text(context.l10n.networkLogViewFull, style: const TextStyle(fontSize: 12)),
        ),
        if (_isDesktop)
          TextButton.icon(
            onPressed: () => _openInEditor(context, label, body),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.open_in_new, size: 14),
            label: Text(context.l10n.networkLogExternalEditor, style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.networkLogDetailTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _DetailCard(
              title: context.l10n.networkLogBasic,
              child: Column(
                children: [
                  _kv(theme, context.l10n.networkLogType, log.type.labelOf(context.l10n)),
                  _kv(theme, context.l10n.networkLogMethod, log.method),
                  _kv(theme, context.l10n.networkLogStatus, log.statusCode?.toString() ?? '—'),
                  _kv(theme, context.l10n.networkLogDuration, '${log.durationMs} ms'),
                  _kv(theme, context.l10n.networkLogRequestSize, formatBytes(log.requestBytes)),
                  _kv(theme, context.l10n.networkLogResponseSize, formatBytes(log.responseBytes)),
                  _kv(theme, context.l10n.networkLogTime, _fullTime(log.time)),
                  _kv(theme, context.l10n.networkLogUrl, log.url, isLast: true),
                ],
              ),
            ),
            if (log.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 20, color: theme.colorScheme.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableText(
                        context.l10n.networkLogFailed(log.error ?? ''),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _DetailCard(
              title: context.l10n.networkLogRequestHeaders,
              child: log.requestHeaders.isEmpty
                  ? _empty(theme)
                  : Column(
                      children: [
                        for (final e in log.requestHeaders.entries)
                          _kv(theme, e.key, e.value, isLast: e.key == log.requestHeaders.keys.last),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _DetailCard(
              title: context.l10n.networkLogRequestBody,
              action: _bodyActions(context, context.l10n.networkLogRequest, log.requestBody, log.requestBytes),
              child: _bodyView(theme, log.requestBody),
            ),
            const SizedBox(height: 16),
            _DetailCard(
              title: context.l10n.networkLogResponseHeaders,
              child: log.responseHeaders.isEmpty
                  ? _empty(theme)
                  : Column(
                      children: [
                        for (final e in log.responseHeaders.entries)
                          _kv(theme, e.key, e.value, isLast: e.key == log.responseHeaders.keys.last),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            _DetailCard(
              title: context.l10n.networkLogResponseBody,
              action: _bodyActions(context, context.l10n.networkLogResponse, log.responseBody, log.responseBytes),
              child: _bodyView(theme, log.responseBody),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '—',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
        ),
      );

  /// 详情页展示时截断的长正文（保留完整内容用于外部编辑器）。
  Widget _bodyView(ThemeData theme, String body) {
    if (body.isEmpty) return _empty(theme);
    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          NetworkLogService.truncate(body, max: 3000),
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _kv(ThemeData theme, String key, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              key,
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _DetailCard({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
