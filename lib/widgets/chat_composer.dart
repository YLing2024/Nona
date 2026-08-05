import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/chat_options.dart';
import '../models/chat_provider.dart';
import '../utils/token_counter.dart';

/// 聊天输入区：工具条（模型/思考强度/流式）+ 输入框 + 发送↔停止。
class ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final List<ChatProvider> providers;
  final String? providerId;
  final String? modelId;
  final ChatOptions options;
  final bool isLoading;

  /// 会话估算 token 数（用于上下文用量提示）。
  final int estimatedTokens;

  /// 会话累计上行（发送）token 数。
  final int usagePrompt;

  /// 会话累计下行（生成）token 数。
  final int usageCompletion;

  final void Function(String providerId, String modelId) onModelChanged;
  final void Function(String? reasoningEffort) onEffortChanged;
  final void Function(bool stream) onStreamChanged;
  final VoidCallback onSend;
  final VoidCallback onStop;

  /// 偏好：Enter 是否发送消息（否则 Enter 换行、Ctrl+Enter 发送）。
  final bool sendOnEnter;

  /// 当 [modelId] 为 null 时是否自动选择第一个模型。
  /// 为 false 时返回 null，显示「未选择模型」。
  final bool autoSelectModel;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.providers,
    required this.providerId,
    required this.modelId,
    required this.options,
    required this.isLoading,
    required this.estimatedTokens,
    required this.onModelChanged,
    required this.onEffortChanged,
    required this.onStreamChanged,
    required this.onSend,
    required this.onStop,
    required this.sendOnEnter,
    required this.usagePrompt,
    required this.usageCompletion,
    this.autoSelectModel = true,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  static const _effortOptions = [
    (null, '自动'),
    ('low', '低'),
    ('medium', '中'),
    ('high', '高'),
  ];

  ChatProvider? get _provider {
    for (final p in widget.providers) {
      if (p.id == widget.providerId) return p;
    }
    // 默认选择第一个已配置模型的服务商（跳过空的 OpenAI 占位）
    for (final p in widget.providers) {
      if (p.modelIds.isNotEmpty) return p;
    }
    return widget.providers.firstOrNull;
  }

  String? get _resolvedModel {
    final provider = _provider;
    if (provider == null || provider.modelIds.isEmpty) return null;
    final model = widget.modelId;
    if (model != null && provider.modelIds.contains(model)) return model;
    if (!widget.autoSelectModel) return null;
    return provider.modelIds.first;
  }

  /// 当前模型是否为推理模型；未标记为推理（或未配置）时思考不可用。
  bool get _reasoningEnabled {
    final model = _resolvedModel;
    final provider = _provider;
    if (model == null || provider == null) return true;
    return provider.modelConfigs[model]?.reasoning ?? false;
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final model = _resolvedModel;
    final provider = _provider;
    final options = widget.options;
    final overLimit = widget.options.maxContextTokens != null &&
        widget.estimatedTokens > widget.options.maxContextTokens!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: _buildToolbar(
              theme,
              scheme,
              model,
              provider,
              options,
              overLimit,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  enabled: !widget.isLoading,
                  minLines: 1,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  style: const TextStyle(fontSize: 14.5, height: 1.5),
                  inputFormatters: [
                    _EnterSendFormatter(
                      sendOnEnter: widget.sendOnEnter,
                      onEnterSend: () => widget.onSend(),
                    ),
                  ],
                  decoration: InputDecoration(
                    hintText: widget.sendOnEnter
                        ? '输入消息，Enter 发送，Shift+Enter 换行'
                        : '输入消息，Enter 换行，Ctrl+Enter 发送',
                    hintStyle: TextStyle(color: scheme.outline, fontSize: 14),
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.controller.text.isNotEmpty)
                _ComposerIconButton(
                  icon: Icons.backspace_outlined,
                  tooltip: '清空',
                  onTap: () => widget.controller.clear(),
                ),
              const SizedBox(width: 4),
              if (widget.isLoading)
                _StopButton(onTap: widget.onStop)
              else
                _SendButton(onTap: widget.onSend, enabled: model != null),
            ],
          ),
          // 输入框下方的 token 统计信息（横向可滚动、靠左对齐）
          if (widget.estimatedTokens > 0 ||
              widget.usagePrompt > 0 ||
              widget.usageCompletion > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Icon(
                        Icons.data_usage_rounded,
                        size: 12,
                        color: overLimit ? scheme.error : scheme.outline,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '上下文 ${TokenCounter.format(widget.estimatedTokens)}'
                        '${options.maxContextTokens != null ? ' / ${TokenCounter.format(options.maxContextTokens!)}' : ''}',
                        style: _statStyle(context, overLimit: overLimit),
                      ),
                      const SizedBox(width: 12),
                      Tooltip(
                        message: '上行 Token（累计发送）',
                        child: _statItem(
                          context,
                          Icons.arrow_upward_rounded,
                          TokenCounter.format(widget.usagePrompt),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Tooltip(
                        message: '下行 Token（累计生成）',
                        child: _statItem(
                          context,
                          Icons.arrow_downward_rounded,
                          TokenCounter.format(widget.usageCompletion),
                        ),
                      ),
                      if (overLimit) ...[
                        const SizedBox(width: 12),
                        Text(
                          '超出上限，发送时将裁剪',
                          style: _statStyle(
                            context,
                            overLimit: true,
                            bold: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: scheme.outline),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: scheme.outline,
          ),
        ),
      ],
    );
  }

  TextStyle _statStyle(
    BuildContext context, {
    required bool overLimit,
    bool bold = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 11,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
      color: overLimit ? scheme.error : scheme.outline,
    );
  }

  Widget _buildToolbar(
    ThemeData theme,
    ColorScheme scheme,
    String? model,
    ChatProvider? provider,
    ChatOptions options,
    bool overLimit,
  ) {
    // 窄屏下工具条横向滚动，避免溢出
    final hasModels = widget.providers.any((p) => p.modelIds.isNotEmpty);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
        // 模型选择
        if (!hasModels)
          _ToolbarChip(
            icon: Icons.model_training,
            label: '未配置模型',
            onTap: null,
          )
        else
          MenuAnchor(
            alignmentOffset: const Offset(0, 6),
            menuChildren: [
              for (final p in widget.providers) ...[
                if (p.modelIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Text(
                      p.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.outline,
                      ),
                    ),
                  ),
                for (final m in p.modelIds)
                  MenuItemButton(
                    leadingIcon: Icon(
                      p.id == provider?.id && m == model
                          ? Icons.check_rounded
                          : Icons.circle_outlined,
                      size: 16,
                      color: p.id == provider?.id && m == model
                          ? scheme.primary
                          : scheme.outline,
                    ),
                    child: Text(m, style: const TextStyle(fontSize: 13)),
                    onPressed: () => widget.onModelChanged(p.id, m),
                  ),
              ],
            ],
            builder: (context, controller, child) => _ModelChip(
              modelName: model ?? '选择模型',
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            ),
          ),
        const SizedBox(width: 6),
        // 思考强度（仅推理模型显示）
        if (_reasoningEnabled)
          MenuAnchor(
            alignmentOffset: const Offset(0, 6),
            menuChildren: [
              for (final (value, label) in _effortOptions)
                MenuItemButton(
                  leadingIcon: Icon(
                    options.reasoningEffort == value
                        ? Icons.check_rounded
                        : Icons.circle_outlined,
                    size: 16,
                    color: options.reasoningEffort == value
                        ? scheme.primary
                        : scheme.outline,
                  ),
                  child: Text(label, style: const TextStyle(fontSize: 13)),
                  onPressed: () => widget.onEffortChanged(value),
                ),
            ],
            builder: (context, controller, child) => _ToolbarChip(
              icon: Icons.psychology_outlined,
              label: _effortLabel(options.reasoningEffort),
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            ),
          ),
        const SizedBox(width: 8),
        // 流式开关
        _ToolbarChip(
          icon: Icons.bolt_rounded,
          label: '流式',
          active: options.stream,
          showExpand: false,
          onTap: widget.isLoading
              ? null
              : () => widget.onStreamChanged(!options.stream),
        ),
        ],
      ),
    );
  }

  String _effortLabel(String? value) => switch (value) {
    'low' => '思考：低',
    'medium' => '思考：中',
    'high' => '思考：高',
    _ => '思考：自动',
  };
}

/// 模型选择器：单行显示当前模型名，不省略（工具条可横向滚动兜底）。
class _ModelChip extends StatelessWidget {  final String modelName;
  final VoidCallback onTap;

  const _ModelChip({
    required this.modelName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.model_training, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              modelName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

class _ToolbarChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// 激活态（如流式开启）：高亮背景与主色。
  final bool active;

  /// 是否显示右侧展开箭头（菜单类显示，开关类隐藏）。
  final bool showExpand;

  const _ToolbarChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.showExpand = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (showExpand) ...[
              const SizedBox(width: 2),
              Icon(Icons.expand_more, size: 14, color: scheme.outline),
            ],
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const _SendButton({required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: enabled ? scheme.primary : scheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(
            Icons.arrow_upward_rounded,
            size: 20,
            color: enabled ? scheme.onPrimary : scheme.outline,
          ),
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StopButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.error,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(11),
          child: Icon(Icons.stop_rounded, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ComposerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 17, color: scheme.outline),
        ),
      ),
    );
  }
}

/// 发送键行为拦截：
/// [sendOnEnter] 为 true 时，裸 Enter 触发发送（Shift+Enter 换行）；
/// 为 false 时，Enter 正常换行，Ctrl+Enter 触发发送。
class _EnterSendFormatter extends TextInputFormatter {
  final bool sendOnEnter;
  final VoidCallback onEnterSend;

  _EnterSendFormatter({
    required this.sendOnEnter,
    required this.onEnterSend,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final inserted = newValue.text != oldValue.text &&
        newValue.text.length == oldValue.text.length + 1 &&
        newValue.text.endsWith('\n');
    if (inserted) {
      final keyboard = HardwareKeyboard.instance;
      final plainEnter = !keyboard.isShiftPressed &&
          !keyboard.isControlPressed &&
          !keyboard.isAltPressed;
      final shouldSend = sendOnEnter
          ? plainEnter
          : keyboard.isControlPressed;
      if (shouldSend) {
        // 帧后触发发送，避免在 formatEditUpdate 中做副作用
        WidgetsBinding.instance.addPostFrameCallback((_) => onEnterSend());
        return oldValue;
      }
    }
    return newValue;
  }
}
