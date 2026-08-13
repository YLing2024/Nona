import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/models/chat_provider.dart';
import '../../../core/services/provider_service.dart';
import '../../../core/services/roulette/key_roulette.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/app_localizations.dart';

/// C-04：多 Key 管理页——列表（掩码/复制/删除/启用开关）+ 批量粘贴添加 +
/// 逐 key 状态（在用/冷却中/失败次数）+ 测活。
class ProviderKeysScreen extends StatefulWidget {
  final ChatProvider provider;

  const ProviderKeysScreen({super.key, required this.provider});

  @override
  State<ProviderKeysScreen> createState() => _ProviderKeysScreenState();
}

class _ProviderKeysScreenState extends State<ProviderKeysScreen> {
  final KeyRoulette _roulette = KeyRoulette('');
  List<KeyStatus> _status = [];
  bool _obscure = true;
  final Set<String> _testing = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _roulette.addListener(_onRouletteChanged);
    _load();
  }

  @override
  void dispose() {
    _roulette.removeListener(_onRouletteChanged);
    _roulette.dispose();
    super.dispose();
  }

  void _onRouletteChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    final keys = widget.provider.apiKeys.isEmpty
        ? (widget.provider.apiKey.isEmpty
            ? const <String>[]
            : [widget.provider.apiKey])
        : widget.provider.apiKeys;
    await _roulette.setKeys(keys);
    final status = await _roulette.status();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<void> _saveKeys(List<String> keys) async {
    final providerService = context.read<ProviderService>();
    final providers = await providerService.load();
    final index = providers.indexWhere((p) => p.id == widget.provider.id);
    if (index < 0) return;
    providers[index].apiKeys = keys;
    await providerService.save(providers);
    widget.provider.apiKeys = keys;
    await _load();
  }

  Future<void> _batchAdd() async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.providerKeysBatchAdd),
        content: TextField(
          controller: controller,
          maxLines: 8,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'sk-xxx\nsk-yyy',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || raw.trim().isEmpty || !mounted) return;
    final parsed = KeyRoulette.parseKeys(raw);
    if (parsed.isEmpty) return;
    final existing = {for (final s in _status) s.key};
    final merged = [
      ..._status.map((s) => s.key),
      for (final k in parsed)
        if (!existing.contains(k)) k,
    ];
    await _saveKeys(merged);
  }

  Future<void> _remove(String key) async {
    final keys = _status.map((s) => s.key).where((k) => k != key).toList();
    await _saveKeys(keys);
    if (!mounted) return;
    showAppSnack(context, context.l10n.providerKeysRemoved);
  }

  Future<void> _copy(String key) async {
    await Clipboard.setData(ClipboardData(text: key));
    if (!mounted) return;
    showAppSnack(context, context.l10n.providerKeysCopied);
  }

  /// 测活：轻量 1-token 请求验证 key 有效性。
  Future<void> _test(String key) async {
    if (_testing.contains(key)) return;
    final providerService = context.read<ProviderService>();
    final l10n = AppLocalizations.of(context);
    setState(() => _testing.add(key));
    try {
      final providers = await providerService.load();
      final p = providers
          .where((p) => p.id == widget.provider.id)
          .firstOrNull;
      if (p == null) return;
      final result = await providerService.testModel(
        ChatProvider(
          id: p.id,
          name: p.name,
          baseUrl: p.baseUrl,
          apiKey: key,
          kind: p.kind,
          modelIds: p.modelIds,
        ),
        p.modelIds.isEmpty ? 'gpt-4o-mini' : p.modelIds.first,
        prompt: 'ping',
      );
      if (result.success) {
        await _roulette.markSuccess(key);
        if (!mounted) return;
        showAppSnack(context, l10n.providerKeysTestOk);
      } else {
        await _roulette.markFailed(key);
        if (!mounted) return;
        showAppSnack(
          context,
          l10n.providerKeysTestFail(result.error ?? 'unknown'),
        );
      }
    } catch (e) {
      await _roulette.markFailed(key);
      if (!mounted) return;
      showAppSnack(context, l10n.providerKeysTestFail(e.toString()));
    } finally {
      if (mounted) setState(() => _testing.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.providerKeysTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: l10n.providerAuthApiKey,
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          IconButton(
            icon: const Icon(Icons.library_add_outlined),
            tooltip: l10n.providerKeysBatchAdd,
            onPressed: _batchAdd,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _status.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.key_off_outlined,
                          size: 40,
                          color: scheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.providerKeysNone,
                          style: TextStyle(color: scheme.outline),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: _batchAdd,
                          icon: const Icon(Icons.library_add_outlined, size: 18),
                          label: Text(l10n.providerKeysBatchAdd),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _status.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final s = _status[index];
                      return _KeyCard(
                        status: s,
                        obscure: _obscure,
                        testing: _testing.contains(s.key),
                        onToggle: (enabled) =>
                            _roulette.setKeyEnabled(s.key, enabled: enabled),
                        onCopy: () => _copy(s.key),
                        onTest: () => _test(s.key),
                        onRemove: () => _remove(s.key),
                      );
                    },
                  ),
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  final KeyStatus status;
  final bool obscure;
  final bool testing;
  final ValueChanged<bool> onToggle;
  final VoidCallback onCopy;
  final VoidCallback onTest;
  final VoidCallback onRemove;

  const _KeyCard({
    required this.status,
    required this.obscure,
    required this.testing,
    required this.onToggle,
    required this.onCopy,
    required this.onTest,
    required this.onRemove,
  });

  String _statusLabel(BuildContext context, KeyStatus s) {
    final l10n = context.l10n;
    if (s.disabled) return l10n.providerKeysStatusDisabled;
    if (s.cooling) return l10n.providerKeysStatusCooling;
    if (s.failCount > 0) {
      return l10n.providerKeysStatusError('');
    }
    return l10n.providerKeysStatusActive;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final masked = status.key.length <= 8
        ? '••••${status.key.substring(status.key.length ~/ 2)}'
        : '${status.key.substring(0, 4)}••••${status.key.substring(status.key.length - 4)}';
    final display = obscure ? masked : status.key;
    return Card(
      elevation: 0,
      color: status.disabled
          ? scheme.surfaceContainerLow
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: status.disabled ? scheme.outlineVariant : scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.disabled ? Icons.key_off_outlined : Icons.key_rounded,
                  size: 18,
                  color: status.disabled ? scheme.outline : scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: !status.disabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: status.disabled
                        ? scheme.errorContainer
                        : status.cooling
                            ? scheme.tertiaryContainer
                            : scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(context, status),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: status.disabled
                          ? scheme.onErrorContainer
                          : status.cooling
                              ? scheme.onTertiaryContainer
                              : scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  tooltip: context.l10n.commonCopy,
                  onPressed: onCopy,
                ),
                IconButton(
                  icon: testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.health_and_safety_outlined, size: 17),
                  tooltip: context.l10n.providerKeysTest,
                  onPressed: testing ? null : onTest,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  tooltip: context.l10n.commonDelete,
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
