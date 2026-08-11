import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/chat_options.dart';
import '../utils/focus_utils.dart';
import '../utils/l10n_ext.dart';

/// 可复用的会话上下文参数表单（含全部 OpenAI 生成参数 + 上下文窗口管理）。
class ChatOptionsForm extends StatefulWidget {
  final ChatOptions initial;

  const ChatOptionsForm({super.key, required this.initial});

  @override
  State<ChatOptionsForm> createState() => ChatOptionsFormState();
}

class ChatOptionsFormState extends State<ChatOptionsForm> {
  late final TextEditingController _systemPromptController;
  late final TextEditingController _maxTokensController;
  late final TextEditingController _nController;
  late final TextEditingController _stopController;
  late final TextEditingController _seedController;
  late final TextEditingController _maxContextTokensController;
  late double _temperature;
  late double _topP;
  late double _presencePenalty;
  late double _frequencyPenalty;

  /// 'auto' / 'text' / 'json_object'，'auto' 表示不指定。
  late String _responseFormat;

  /// 思考强度与流式开关由聊天工具条维护，表单原样保留。
  late String? _reasoningEffort;
  late bool _stream;
  late bool _autoTrim;

  /// 快捷配置（Agent）模式为只读，仅自定义模式可编辑。
  bool _readOnly = false;

  bool _controllersReady = false;

  /// 设置表单是否只读（快捷配置时禁止编辑）。
  void setReadOnly(bool value) => setState(() => _readOnly = value);

  @override
  void initState() {
    super.initState();
    fill(widget.initial);
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    _maxTokensController.dispose();
    _nController.dispose();
    _stopController.dispose();
    _seedController.dispose();
    _maxContextTokensController.dispose();
    super.dispose();
  }

  /// 用一组配置快速填充表单。
  void fill(ChatOptions o) {
    if (!_controllersReady) {
      _systemPromptController = TextEditingController(text: o.systemPrompt);
      _maxTokensController = TextEditingController(
        text: o.maxTokens?.toString() ?? '',
      );
      _nController = TextEditingController(text: o.n?.toString() ?? '');
      _stopController = TextEditingController(text: o.stop.join(','));
      _seedController = TextEditingController(text: o.seed?.toString() ?? '');
      _maxContextTokensController = TextEditingController(
        text: o.maxContextTokens?.toString() ?? '',
      );
      _controllersReady = true;
    } else {
      _systemPromptController.text = o.systemPrompt;
      _maxTokensController.text = o.maxTokens?.toString() ?? '';
      _nController.text = o.n?.toString() ?? '';
      _stopController.text = o.stop.join(',');
      _seedController.text = o.seed?.toString() ?? '';
      _maxContextTokensController.text = o.maxContextTokens?.toString() ?? '';
    }
    setState(() {
      _temperature = o.temperature;
      _topP = o.topP;
      _presencePenalty = o.presencePenalty;
      _frequencyPenalty = o.frequencyPenalty;
      _responseFormat = o.responseFormat ?? 'auto';
      _reasoningEffort = o.reasoningEffort;
      _stream = o.stream;
      _autoTrim = o.autoTrim;
    });
  }

  ChatOptions get value => ChatOptions(
    systemPrompt: _systemPromptController.text.trim(),
    temperature: _temperature,
    topP: _topP,
    maxTokens: int.tryParse(_maxTokensController.text.trim()),
    presencePenalty: _presencePenalty,
    frequencyPenalty: _frequencyPenalty,
    n: int.tryParse(_nController.text.trim()),
    stop: _stopController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(),
    seed: int.tryParse(_seedController.text.trim()),
    responseFormat: _responseFormat == 'auto' ? null : _responseFormat,
    reasoningEffort: _reasoningEffort,
    stream: _stream,
    maxContextTokens: int.tryParse(_maxContextTokensController.text.trim()),
    autoTrim: _autoTrim,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ConfigCard(
          icon: Icons.assignment_outlined,
          title: context.l10n.contextSystemPrompt,
          tipsTitle: context.l10n.contextSystemPrompt,
          tips: context.l10n.contextSystemPromptTip,
          child: TextField(
            controller: _systemPromptController,
            maxLines: 4,
            minLines: 3,
            readOnly: _readOnly,
            onTapOutside: unfocusOnTap,
            decoration: InputDecoration(
              hintText: context.l10n.contextSystemPromptHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        _ConfigCard(
          icon: Icons.thermostat_outlined,
          title: context.l10n.contextTemperature,
          valueText: _temperature.toStringAsFixed(2),
          tipsTitle: context.l10n.contextTemperature,
          tips: context.l10n.contextTemperatureTip,
          child: Slider(
            value: _temperature,
            min: 0,
            max: 2,
            divisions: 40,
            label: _temperature.toStringAsFixed(2),
            onChanged: _readOnly
                ? null
                : (v) => setState(() => _temperature = v),
          ),
        ),
        _ConfigCard(
          icon: Icons.layers_outlined,
          title: context.l10n.contextTopP,
          valueText: _topP.toStringAsFixed(2),
          tipsTitle: context.l10n.contextTopP,
          tips: context.l10n.contextTopPTip,
          child: Slider(
            value: _topP,
            min: 0,
            max: 1,
            divisions: 20,
            label: _topP.toStringAsFixed(2),
            onChanged: _readOnly ? null : (v) => setState(() => _topP = v),
          ),
        ),
        _ConfigCard(
          icon: Icons.data_usage,
          title: context.l10n.contextMaxTokens,
          tipsTitle: context.l10n.contextMaxTokens,
          tips: context.l10n.contextMaxTokensTip,
          child: TextField(
            controller: _maxTokensController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            readOnly: _readOnly,
            onTapOutside: unfocusOnTap,
            decoration: InputDecoration(
              hintText: context.l10n.contextMaxTokensHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        _ConfigCard(
          icon: Icons.explore_outlined,
          title: context.l10n.contextPresencePenalty,
          valueText: _presencePenalty.toStringAsFixed(2),
          tipsTitle: context.l10n.contextPresencePenalty,
          tips: context.l10n.contextPresencePenaltyTip,
          child: Slider(
            value: _presencePenalty,
            min: -2,
            max: 2,
            divisions: 40,
            label: _presencePenalty.toStringAsFixed(2),
            onChanged: _readOnly
                ? null
                : (v) => setState(() => _presencePenalty = v),
          ),
        ),
        _ConfigCard(
          icon: Icons.repeat,
          title: context.l10n.contextFrequencyPenalty,
          valueText: _frequencyPenalty.toStringAsFixed(2),
          tipsTitle: context.l10n.contextFrequencyPenalty,
          tips: context.l10n.contextFrequencyPenaltyTip,
          child: Slider(
            value: _frequencyPenalty,
            min: -2,
            max: 2,
            divisions: 40,
            label: _frequencyPenalty.toStringAsFixed(2),
            onChanged: _readOnly
                ? null
                : (v) => setState(() => _frequencyPenalty = v),
          ),
        ),
        _ConfigCard(
          icon: Icons.copy_all_outlined,
          title: context.l10n.contextN,
          tipsTitle: context.l10n.contextN,
          tips: context.l10n.contextNTip,
          child: TextField(
            controller: _nController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            readOnly: _readOnly,
            onTapOutside: unfocusOnTap,
            decoration: InputDecoration(
              hintText: context.l10n.contextNHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        _ConfigCard(
          icon: Icons.stop_circle_outlined,
          title: context.l10n.contextStop,
          tipsTitle: context.l10n.contextStop,
          tips: context.l10n.contextStopTip,
          child: TextField(
            controller: _stopController,
            readOnly: _readOnly,
            onTapOutside: unfocusOnTap,
            decoration: InputDecoration(
              hintText: context.l10n.contextCommaSeparated,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        _ConfigCard(
          icon: Icons.eco_outlined,
          title: context.l10n.contextSeed,
          tipsTitle: context.l10n.contextSeed,
          tips: context.l10n.contextSeedTip,
          child: TextField(
            controller: _seedController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            readOnly: _readOnly,
            onTapOutside: unfocusOnTap,
            decoration: InputDecoration(
              hintText: context.l10n.contextSeedHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        _ConfigCard(
          icon: Icons.code_outlined,
          title: context.l10n.contextResponseFormat,
          valueText: _responseFormatLabel(context.l10n, _responseFormat),
          tipsTitle: context.l10n.contextResponseFormat,
          tips: context.l10n.contextResponseFormatTip,
          child: DropdownButtonFormField<String>(
            initialValue: _responseFormat,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              DropdownMenuItem(
                value: 'auto',
                child: Text(context.l10n.commonNotSpecified),
              ),
              DropdownMenuItem(
                value: 'text',
                child: Text(context.l10n.contextResponseFormatText),
              ),
              DropdownMenuItem(
                value: 'json_object',
                child: Text(context.l10n.contextResponseFormatJson),
              ),
            ],
            onChanged: _readOnly
                ? null
                : (v) => setState(() => _responseFormat = v!),
          ),
        ),
        _ConfigCard(
          icon: Icons.view_agenda_outlined,
          title: context.l10n.contextMaxContext,
          valueText: _maxContextTokensController.text.isEmpty
              ? context.l10n.commonUnlimited
              : '${_maxContextTokensController.text} tokens',
          tipsTitle: context.l10n.contextMaxContext,
          tips: context.l10n.contextMaxContextTip,
          child: Column(
            children: [
              TextField(
                controller: _maxContextTokensController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                readOnly: _readOnly,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  hintText: context.l10n.contextMaxContextHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.contextAutoTrim),
                subtitle: Text(context.l10n.contextAutoTrimHint),
                value: _autoTrim,
                onChanged: _readOnly
                    ? null
                    : (v) => setState(() => _autoTrim = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _responseFormatLabel(AppLocalizations l10n, String value) =>
      switch (value) {
        'text' => l10n.contextResponseFormatTextShort,
        'json_object' => l10n.contextResponseFormatJsonShort,
        _ => l10n.commonNotSpecified,
      };
}

/// 单个配置项的卡片，右侧带 tips 感叹号按钮。
class _ConfigCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? valueText;
  final String tipsTitle;
  final String tips;
  final Widget child;

  const _ConfigCard({
    required this.icon,
    required this.title,
    this.valueText,
    required this.tipsTitle,
    required this.tips,
    required this.child,
  });

  void _showTips(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tipsTitle),
        content: Text(tips),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.contextInfoGotIt),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: theme.textTheme.titleSmall),
              ),
              if (valueText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    valueText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.help_outline, size: 18),
                tooltip: context.l10n.contextInfoTitle,
                visualDensity: VisualDensity.compact,
                onPressed: () => _showTips(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
