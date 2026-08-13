import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/chat_message.dart' show ChatImage;
import '../../../core/models/chat_provider.dart';
import '../services/images_adapter.dart';
import '../services/imggen_share.dart';
import '../../../core/services/provider_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/load_guarded.dart';
import '../../../shared/widgets/chat_image_view.dart';

/// 图片生成页（F1-4）：提示词 / 尺寸 / 数量 / 历史列表。
class ImgGenScreen extends StatefulWidget {
  const ImgGenScreen({super.key});

  @override
  State<ImgGenScreen> createState() => _ImgGenScreenState();
}

class _ImgGenScreenState extends State<ImgGenScreen> {
  late final ProviderService _providers = context.read<ProviderService>();
  final _promptController = TextEditingController();
  String _size = '1024x1024';
  String? _quality;
  int _n = 1;
  bool _busy = false;
  List<ChatProvider> _providerList = [];
  ChatProvider? _selected;
  final List<_GenHistoryItem> _history = [];
  final ImagesAdapter _adapter = ImagesAdapter();

  static const _kHistoryPrefs = 'imggen_history_v1';

  @override
  void initState() {
    super.initState();
    _load();
    _loadHistory();
  }

  /// C-05：历史回看（prefs JSON，最多 50 条，仅存元数据与 URL）。
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kHistoryPrefs);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _history.addAll([
          for (final e in decoded)
            if (e is Map<String, dynamic>)
              _GenHistoryItem.fromJson(e),
        ]);
      });
    } catch (_) {
      // 历史损坏：忽略
    }
  }

  Future<void> _persistHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kHistoryPrefs,
        jsonEncode(_history.take(50).map((h) => h.toJson()).toList()),
      );
    } catch (_) {
      // 忽略
    }
  }

  Future<void> _load() async {
    final providers = await loadGuarded<List<ChatProvider>>(
      _providers.load,
      label: 'providers',
    );
    if (!mounted) return;
    setState(() {
      _providerList = providers ?? [];
      _selected = _providerList.where(ImagesAdapter.supportsImageGen).firstOrNull;
    });
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    final provider = _selected;
    if (prompt.isEmpty || provider == null || _busy) return;
    setState(() => _busy = true);
    try {
      final results = await _adapter.generateImage(
        provider,
        prompt: prompt,
        size: _size,
        n: _n,
        quality: _quality,
      );
      if (!mounted) return;
      setState(() {
        _history.insertAll(
          0,
          [
            for (final r in results)
              _GenHistoryItem(
                prompt: prompt,
                url: r.url,
                b64: r.b64,
                model: provider.modelIds.isEmpty
                    ? 'dall-e-3'
                    : provider.modelIds.first,
                createdAt: DateTime.now(),
              ),
          ],
        );
        _busy = false;
      });
      await _persistHistory();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppSnack(context, '$e');
    }
  }

  /// C-05：发送到对话（经 ImggenShare 通道投递到首页输入区）。
  void _sendToChat(_GenHistoryItem item) {
    final image = ChatImage(
      url: item.b64 != null ? 'data:image/png;base64,${item.b64}' : item.url,
      mimeType: item.b64 != null ? 'image/png' : 'image/*',
    );
    ImggenShare.sendToChat(image);
    showAppSnack(context, context.l10n.imggenSendToChat);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.imgGenTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<ChatProvider>(
                  initialValue: _selected,
                  decoration: InputDecoration(
                    labelText: l10n.imgGenProvider,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final p in _providerList)
                      if (ImagesAdapter.supportsImageGen(p))
                        DropdownMenuItem(
                          value: p,
                          child: Text(
                            p.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ],
                  onChanged: (v) => setState(() => _selected = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _promptController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.imgGenPrompt,
                    hintText: l10n.imgGenPromptHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _size,
                        decoration: InputDecoration(
                          labelText: l10n.imgGenSize,
                          border: const OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '256x256', child: Text('256×256')),
                          DropdownMenuItem(value: '512x512', child: Text('512×512')),
                          DropdownMenuItem(value: '1024x1024', child: Text('1024×1024')),
                        ],
                        onChanged: (v) => setState(() => _size = v ?? _size),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // C-05：质量参数（standard/hd）
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _quality,
                        decoration: InputDecoration(
                          labelText: l10n.imggenQuality,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.commonAuto),
                          ),
                          const DropdownMenuItem(value: 'standard', child: Text('Standard')),
                          const DropdownMenuItem(value: 'hd', child: Text('HD')),
                        ],
                        onChanged: (v) => setState(() => _quality = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _n,
                        decoration: InputDecoration(
                          labelText: l10n.imgGenCount,
                          border: const OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1')),
                          DropdownMenuItem(value: 2, child: Text('2')),
                          DropdownMenuItem(value: 3, child: Text('3')),
                          DropdownMenuItem(value: 4, child: Text('4')),
                        ],
                        onChanged: (v) => setState(() => _n = v ?? _n),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _generate,
                        icon: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text(
                          _busy ? l10n.imgGenGenerating : l10n.imgGenGenerate,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _history.isEmpty
                ? Center(
                    child: Text(
                      l10n.imgGenEmpty,
                      style: TextStyle(color: scheme.outline),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.prompt,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ChatImageView(
                                  image: ChatImage(
                                    url: item.b64 != null
                                        ? 'data:image/png;base64,${item.b64}'
                                        : item.url,
                                    mimeType: item.b64 != null
                                        ? 'image/png'
                                        : 'image/*',
                                  ),
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.model} · ${item.createdAt.toLocal()}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: scheme.outline,
                                      ),
                                    ),
                                  ),
                                  // C-05：发送到对话
                                  IconButton(
                                    icon: const Icon(
                                      Icons.send_rounded,
                                      size: 17,
                                    ),
                                    tooltip: l10n.imggenSendToChat,
                                    onPressed: () => _sendToChat(item),
                                  ),
                                ],
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
    );
  }
}

class _GenHistoryItem {
  final String prompt;
  final String url;
  final String? b64;
  final String model;
  final DateTime createdAt;

  const _GenHistoryItem({
    required this.prompt,
    required this.url,
    this.b64,
    required this.model,
    required this.createdAt,
  });

  factory _GenHistoryItem.fromJson(Map<String, dynamic> json) =>
      _GenHistoryItem(
        prompt: json['prompt'] as String? ?? '',
        url: json['url'] as String? ?? '',
        b64: json['b64'] as String?,
        model: json['model'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'url': url,
    if (b64 != null) 'b64': b64,
    'model': model,
    'createdAt': createdAt.toIso8601String(),
  };
}
