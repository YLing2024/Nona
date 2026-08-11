import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_provider.dart';
import '../services/provider_service.dart';
import '../utils/l10n_ext.dart';

/// 弹出「添加模型」对话框，返回本次新增的模型 id 及能力配置
/// （可能包含已有，由调用方去重；列表模式保留 API 返回顺序）。
Future<List<(String, ModelConfig)>?> showAddModelDialog(
  BuildContext context, {
  required String baseUrl,
  required String apiKey,
  required Set<String> existing,
}) {
  return showDialog<List<(String, ModelConfig)>>(
    context: context,
    builder: (_) => AddModelDialog(
      baseUrl: baseUrl,
      apiKey: apiKey,
      existing: existing,
    ),
  );
}

/// 「添加模型」对话框：手动输入模型 ID，或拉取 /models 列表后勾选添加。
class AddModelDialog extends StatefulWidget {
  final String baseUrl;
  final String apiKey;

  /// 服务商已添加的模型，用于在列表模式中预先标记。
  final Set<String> existing;

  const AddModelDialog({
    super.key,
    required this.baseUrl,
    required this.apiKey,
    required this.existing,
  });

  @override
  State<AddModelDialog> createState() => _AddModelDialogState();
}

class _AddModelDialogState extends State<AddModelDialog> {
  final _manualController = TextEditingController();
  bool _fetchMode = false;
  List<(String, ModelConfig)>? _fetched;
  final Set<String> _checked = {};
  bool _loading = false;

  /// 手动添加时勾选的模型能力配置。
  bool _manualMultimodal = false;
  bool _manualReasoning = false;

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  void _toggleMode(bool fetchMode) {
    setState(() => _fetchMode = fetchMode);
    if (fetchMode && _fetched == null && !_loading) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    if (widget.apiKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.addModelApiKeyRequired)));
      return;
    }
    setState(() => _loading = true);
    try {
      final models = await context.read<ProviderService>().fetchModels(
        ChatProvider(
          id: 'temp',
          name: '',
          baseUrl: widget.baseUrl,
          apiKey: widget.apiKey,
        ),
      );
      if (!mounted) return;
      setState(() {
        _fetched = models;
        _checked
          ..clear()
          ..addAll(widget.existing.where((id) => models.any((m) => m.$1 == id)));
      });
      if (models.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.addModelNoModels)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.addModelFetchFailed(e.toString()))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _canAdd {
    if (_fetchMode) return _checked.isNotEmpty;
    return _manualController.text.trim().isNotEmpty;
  }

  void _submit() {
    final List<(String, ModelConfig)> result;
    if (_fetchMode) {
      result = _fetched!
          .where((m) => _checked.contains(m.$1))
          .toList();
    } else {
      final model = _manualController.text.trim();
      if (model.isEmpty) return;
      result = [
        (
          model,
          ModelConfig(
            multimodal: _manualMultimodal,
            reasoning: _manualReasoning,
          ),
        ),
      ];
    }
    if (result.isEmpty) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(context.l10n.addModelTitle),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(context.l10n.addModelManual),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(context.l10n.addModelFetchFromList),
                  icon: const Icon(Icons.cloud_download_outlined, size: 16),
                ),
              ],
              selected: {_fetchMode},
              showSelectedIcon: false,
              onSelectionChanged: (s) => _toggleMode(s.first),
            ),
            const SizedBox(height: 16),
            if (!_fetchMode)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _manualController,
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => _submit(),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: context.l10n.addModelExample,
                      helperText: context.l10n.addModelManualHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(context.l10n.providerMultimodal, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      context.l10n.providerMultimodalHint,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    value: _manualMultimodal,
                    onChanged: (v) =>
                        setState(() => _manualMultimodal = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(context.l10n.providerReasoning, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      context.l10n.addModelReasoningHint,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    value: _manualReasoning,
                    onChanged: (v) => setState(() => _manualReasoning = v),
                  ),
                ],
              )
            else
              _buildFetchSection(theme),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _canAdd ? _submit : null,
          child: Text(context.l10n.commonAdd),
        ),
      ],
    );
  }

  Widget _buildFetchSection(ThemeData theme) {
    final Widget body;
    if (_loading) {
      body = const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_fetched == null) {
      body = SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.addModelFetchHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: _fetch,
                child: Text(context.l10n.addModelFetch),
              ),
            ],
          ),
        ),
      );
    } else {
      body = ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final m in _fetched!)
              CheckboxListTile(
                value: _checked.contains(m.$1),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(m.$1, style: const TextStyle(fontSize: 13)),
                    ),
                    if (m.$2.multimodal)
                      _CapabilityTag(
                        label: context.l10n.providerMultimodal,
                        color: theme.colorScheme.tertiary,
                      ),
                    if (m.$2.reasoning)
                      _CapabilityTag(
                        label: context.l10n.providerReasoning,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _checked.add(m.$1);
                    } else {
                      _checked.remove(m.$1);
                    }
                  });
                },
              ),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_fetched != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _loading ? null : _fetch,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(context.l10n.commonRefresh),
            ),
          ),
        body,
      ],
    );
  }
}

/// 模型能力小标签（多模态 / 推理）。
class _CapabilityTag extends StatelessWidget {
  final String label;
  final Color color;

  const _CapabilityTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
