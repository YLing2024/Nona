import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/stream_flusher.dart';

import '../models/chat_message.dart';
import '../models/chat_options.dart';
import '../models/chat_provider.dart';
import '../services/chat_service.dart';
import '../services/provider_service.dart';
import '../services/settings_service.dart';
import '../utils/l10n_ext.dart';

/// 单个模型的对比结果卡片状态。
class _CompareResult {
  final String providerName;
  final String modelId;
  ChatRequestHandle? handle;
  String content = '';
  bool failed = false;

  _CompareResult({
    required this.providerName,
    required this.modelId,
  });
}

/// 多模型同题对比页：同一问题并行发送给多个模型，并排流式对比。
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final _questionController = TextEditingController();
  final List<ChatProvider> _providers = [];
  final Set<String> _selected = {}; // 'providerId/modelId'
  bool _loaded = false;
  bool _running = false;
  List<_CompareResult> _results = [];

  /// 多路并发流式共用帧级批处理：逐 chunk 只累积，每帧最多一次 setState。
  late final StreamFlusher _flusher = StreamFlusher(
    onFlush: (_) {
      if (mounted) setState(() {});
    },
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final providers = await context.read<ProviderService>().load();
    if (!mounted) return;
    setState(() {
      _providers.addAll(providers);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    for (final r in _results) {
      r.handle?.cancel();
    }
    _questionController.dispose();
    super.dispose();
  }

  /// 收集全部可选模型（服务商 × 模型）。
  List<(ChatProvider, String)> get _allModels => [
    for (final p in _providers)
      for (final m in p.modelIds) (p, m),
  ];

  Future<void> _start() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _selected.isEmpty || _running) return;
    setState(() {
      _running = true;
    });
    // 先挂载结果列表再逐模型发起请求：_stop() 在请求创建窗口内
    // 也能取消已创建的句柄，而不是静默失效
    final results = <_CompareResult>[];
    setState(() => _results = results);
    final futures = <Future<void>>[];
    for (final (provider, modelId) in _allModels) {
      if (!_selected.contains('${provider.id}/$modelId')) continue;
      final result = _CompareResult(
        providerName: provider.name,
        modelId: modelId,
      );
      result.handle = context.read<ChatService>().sendChat(
        settings: AppSettings(
          apiKey: provider.apiKey,
          baseUrl: provider.baseUrl,
          model: modelId,
          providerKind: provider.kind.name,
        ),
        messages: [
          ChatMessage(role: 'user', content: question),
        ],
        options: const ChatOptions(stream: true),
        // 与聊天一致：需要自定义头/请求体的服务商也能对比
        customHeaders: provider.customHeaders.isEmpty
            ? null
            : provider.customHeaders,
        customBody: provider.customBody,
        onPartial: (delta) {
          // 内容直接累积（Dart 字符串追加为摊销 O(1)），
          // 刷新交给帧级批处理（每帧最多一次 setState）
          result.content += delta;
          _flusher.add(delta);
        },
      );
      results.add(result);
      futures.add(
        result.handle!.result.then((_) {
          if (mounted) setState(() {});
        }).catchError((Object e) {
          // 用户主动停止不算失败
          if (e is! ChatCancelledException) {
            result.failed = true;
          }
          if (mounted) setState(() {});
        }),
      );
    }
    await Future.wait(futures);
    if (mounted) setState(() => _running = false);
  }

  void _stop() {
    for (final r in _results) {
      r.handle?.cancel();
    }
    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.compareTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _questionController,
                maxLines: 3,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  hintText: l10n.compareHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (!_loaded)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (_allModels.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final (provider, modelId) in _allModels)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            '${provider.name} · $modelId',
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: _selected.contains(
                            '${provider.id}/$modelId',
                          ),
                          onSelected: _running
                              ? null
                              : (v) => setState(() {
                                    v
                                        ? _selected.add('${provider.id}/$modelId')
                                        : _selected.remove('${provider.id}/$modelId');
                                  }),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: _running
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.compare_rounded, size: 18),
                      label: Text(
                        _running ? l10n.compareRunning : l10n.compareStart,
                      ),
                      onPressed: _running ? null : _start,
                    ),
                  ),
                  if (_running) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _stop,
                      child: Text(l10n.commonStop),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        l10n.compareEmpty,
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final r = _results[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${r.providerName} · ${r.modelId}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (r.failed) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.error_outline,
                                        size: 14,
                                        color: theme.colorScheme.error,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  r.content.isEmpty
                                      ? (r.failed
                                            ? l10n.compareFailed
                                            : l10n.compareWaiting)
                                      : r.content,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
