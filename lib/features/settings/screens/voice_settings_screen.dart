import 'package:flutter/material.dart';

import '../../../core/services/tts/tts_config.dart';
import '../../../core/services/tts/tts_provider.dart';
import '../../../core/services/tts_service.dart' show FlutterTtsEngine;
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// E-01：语音服务设置——网络 TTS 服务商 CRUD + 试听 + 选中。
class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  List<TtsServiceConfig> _services = [];
  String? _selectedId;
  String? _previewingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final services = await TtsConfigStore.load();
    final selected = await TtsConfigStore.selectedId();
    if (!mounted) return;
    setState(() {
      _services = services;
      _selectedId = selected;
    });
  }

  Future<void> _addOrEdit([TtsServiceConfig? existing]) async {
    final result = await _editDialog(existing);
    if (result == null || !mounted) return;
    final services = [..._services];
    final index = services.indexWhere((s) => s.id == result.id);
    if (index >= 0) {
      services[index] = result;
    } else {
      services.add(result);
    }
    await TtsConfigStore.save(services);
    if (_selectedId == null) {
      await TtsConfigStore.setSelected(result.id);
    }
    await _load();
  }

  Future<void> _delete(TtsServiceConfig service) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.commonDelete,
      message: service.name,
      confirmText: context.l10n.commonDelete,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    final services = _services.where((s) => s.id != service.id).toList();
    await TtsConfigStore.save(services);
    if (_selectedId == service.id) {
      await TtsConfigStore.setSelected(null);
    }
    await _load();
  }

  Future<void> _preview(TtsServiceConfig service) async {
    if (_previewingId != null) return;
    setState(() => _previewingId = service.id);
    try {
      final provider = TtsProviderRegistry.forConfig(
        service,
        systemEngine: _dummySystem(),
      );
      await provider.speak(
        '你好，这是一条语音预览。Hello, this is a voice preview.',
        onDone: () {},
      );
      if (!mounted) return;
      showAppSnack(context, context.l10n.voiceTtsTestOk);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, context.l10n.voiceTtsTestFail(e.toString()));
    } finally {
      if (mounted) setState(() => _previewingId = null);
    }
  }

  // 试听用的系统引擎（不可达路径：试听只走网络 provider）
  FlutterTtsEngine _dummySystem() => FlutterTtsEngine();

  Future<TtsServiceConfig?> _editDialog([TtsServiceConfig? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final baseCtrl = TextEditingController(
      text: existing?.baseUrl ?? 'https://api.openai.com/v1',
    );
    final keyCtrl = TextEditingController(text: existing?.apiKey ?? '');
    final voiceCtrl = TextEditingController(text: existing?.voice ?? 'alloy');
    final modelCtrl = TextEditingController(text: existing?.model ?? 'tts-1');
    final kindCtrl = TextEditingController(
      text: existing?.kind ?? 'openai',
    );
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<TtsServiceConfig>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null ? l10n.voiceTtsAddProvider : l10n.commonEdit,
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.voiceTtsProviderName,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: kindCtrl,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Kind (openai/groq/xai/elevenlabs/minimax/qwen/mimo/gemini)',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: baseCtrl,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Base URL',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: keyCtrl,
                  autocorrect: false,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: voiceCtrl,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.voiceTtsVoice,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: modelCtrl,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.voiceTtsModel,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty ||
                  baseCtrl.text.trim().isEmpty ||
                  keyCtrl.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(
                ctx,
                TtsServiceConfig(
                  id: existing?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  kind: kindCtrl.text.trim().isEmpty
                      ? 'openai'
                      : kindCtrl.text.trim(),
                  baseUrl: baseCtrl.text.trim(),
                  apiKey: keyCtrl.text.trim(),
                  voice: voiceCtrl.text.trim(),
                  model: modelCtrl.text.trim(),
                ),
              );
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    baseCtrl.dispose();
    keyCtrl.dispose();
    voiceCtrl.dispose();
    modelCtrl.dispose();
    kindCtrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.voiceServicesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.voiceTtsAddProvider,
            onPressed: () => _addOrEdit(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // 系统 TTS 提示卡
            Card(
              elevation: 0,
              color: scheme.surfaceContainerLow,
              child: ListTile(
                leading: Icon(Icons.record_voice_over_rounded, color: scheme.primary),
                title: Text(l10n.voiceTtsSystem),
                subtitle: Text(l10n.voiceTtsFallbackSystem),
              ),
            ),
            const SizedBox(height: 8),
            if (_services.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.voiceTtsAddProvider,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.outline),
                ),
              )
            else
              for (final service in _services)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: scheme.surfaceContainerLow,
                  child: ListTile(
                    leading: Icon(
                      _selectedId == service.id
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: _selectedId == service.id
                          ? scheme.primary
                          : scheme.outline,
                    ),
                    title: Text(service.name, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${service.kind} · ${service.baseUrl}\n'
                      '${service.voice.isEmpty ? '-' : service.voice}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    onTap: () async {
                      await TtsConfigStore.setSelected(service.id);
                      await _load();
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: _previewingId == service.id
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.play_arrow_rounded, size: 18),
                          tooltip: l10n.voiceTtsPreview,
                          onPressed: _previewingId == service.id
                              ? null
                              : () => _preview(service),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: l10n.commonEdit,
                          onPressed: () => _addOrEdit(service),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          tooltip: l10n.commonDelete,
                          onPressed: () => _delete(service),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
