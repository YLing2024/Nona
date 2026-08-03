import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/chat_options.dart';

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
          title: '系统提示词',
          tipsTitle: '系统提示词',
          tips: '设定助手的角色、风格与行为准则，会作为 system 消息放在对话最前面，影响整个会话的回复基调。',
          child: TextField(
            controller: _systemPromptController,
            maxLines: 4,
            minLines: 3,
            readOnly: _readOnly,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              hintText: '可选，设定助手的角色与行为…',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        _ConfigCard(
          icon: Icons.thermostat_outlined,
          title: 'Temperature',
          valueText: _temperature.toStringAsFixed(2),
          tipsTitle: 'Temperature 采样温度',
          tips:
              '控制输出的随机程度，取值范围 0~2。\n\n值越高，输出越发散、更有创造力；值越低，输出越稳定、保守、可预测。需要稳定的回答建议调低。',
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
          title: 'Top P',
          valueText: _topP.toStringAsFixed(2),
          tipsTitle: 'Top P 核采样',
          tips:
              '只从累计概率达到该值的 token 集合中采样，取值范围 0~1。\n\n与 Temperature 二选一调整即可，一般不建议同时大幅调整两者。',
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
          title: 'Max Tokens',
          tipsTitle: 'Max Tokens 最大输出长度',
          tips: '单次回复最多生成的 token 数，超出部分会被截断。\n\n留空表示由服务端按模型上限决定。',
          child: TextField(
            controller: _maxTokensController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            readOnly: _readOnly,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              hintText: '留空由服务端决定',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        _ConfigCard(
          icon: Icons.explore_outlined,
          title: 'Presence Penalty',
          valueText: _presencePenalty.toStringAsFixed(2),
          tipsTitle: 'Presence Penalty 话题新鲜度惩罚',
          tips: '对已出现过的 token 施加惩罚，取值范围 -2~2。\n\n值越大，越鼓励模型讨论新话题、避免简单重复已有内容。',
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
          title: 'Frequency Penalty',
          valueText: _frequencyPenalty.toStringAsFixed(2),
          tipsTitle: 'Frequency Penalty 频率惩罚',
          tips: '按 token 在文本中出现频率施加惩罚，取值范围 -2~2。\n\n值越大，越能抑制整段重复与套话。',
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
          title: 'N',
          tipsTitle: 'N 候选数量',
          tips: '一次请求生成几条候选回复，默认 1。\n\n大于 1 时接口会返回多条，由你自行选择使用哪一条，会增加 token 消耗。',
          child: TextField(
            controller: _nController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            readOnly: _readOnly,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              hintText: '留空使用默认值 1',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        _ConfigCard(
          icon: Icons.stop_circle_outlined,
          title: 'Stop',
          tipsTitle: 'Stop 停止序列',
          tips: '模型生成到该字符串时会立即停止输出。\n\n多个序列用英文逗号分隔，例如：\n\n,。！？\n\n留空表示不使用停止序列。',
          child: TextField(
            controller: _stopController,
            readOnly: _readOnly,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              hintText: '多个用英文逗号分隔',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        _ConfigCard(
          icon: Icons.eco_outlined,
          title: 'Seed',
          tipsTitle: 'Seed 随机种子',
          tips: '设置随机种子后，相同种子与相同输入在多数服务端可复现出相似的结果，方便调试与对比。\n\n留空表示随机。',
          child: TextField(
            controller: _seedController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            readOnly: _readOnly,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              hintText: '留空表示随机',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        _ConfigCard(
          icon: Icons.code_outlined,
          title: 'Response Format',
          valueText: _responseFormatLabel(_responseFormat),
          tipsTitle: 'Response Format 响应格式',
          tips:
              '期望模型输出的格式：\n\n• 不指定：默认文本\n• 文本 (text)：普通文本\n• JSON (json_object)：模型只输出合法 JSON，方便程序解析\n\n部分模型不支持 JSON 模式，请以服务商文档为准。',
          child: DropdownButtonFormField<String>(
            initialValue: _responseFormat,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'auto', child: Text('不指定')),
              DropdownMenuItem(value: 'text', child: Text('文本 (text)')),
              DropdownMenuItem(
                value: 'json_object',
                child: Text('JSON (json_object)'),
              ),
            ],
            onChanged: _readOnly
                ? null
                : (v) => setState(() => _responseFormat = v!),
          ),
        ),
        _ConfigCard(
          icon: Icons.view_agenda_outlined,
          title: '上下文窗口管理',
          valueText: _maxContextTokensController.text.isEmpty
              ? '不限制'
              : '${_maxContextTokensController.text} tokens',
          tipsTitle: '上下文窗口管理',
          tips:
              '控制发送给模型的对话历史长度：\n\n• 最大上下文：超出该 token 数时按策略处理，留空表示不限制\n• 自动裁剪：发送前估算对话长度，超限时自动移除最早的消息\n\n可避免长对话超出发送方的上下文窗口上限，节省费用并防止报错。',
          child: Column(
            children: [
              TextField(
                controller: _maxContextTokensController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                readOnly: _readOnly,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: const InputDecoration(
                  hintText: '如 32000，留空表示不限制',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('自动裁剪早期消息'),
                subtitle: const Text('超出上限时自动移除最早的对话记录'),
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

  String _responseFormatLabel(String value) => switch (value) {
    'text' => '文本',
    'json_object' => 'JSON',
    _ => '不指定',
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
            child: const Text('知道了'),
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
                tooltip: '说明',
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
