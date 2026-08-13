import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/asr/asr_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/app_localizations.dart';

/// E-03：语音输入浮层——录音态 + 振幅柱 + 实时转写；结果经 [onResult] 回传。
Future<void> showVoiceInputSheet(
  BuildContext context, {
  required ValueChanged<String> onResult,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _VoiceInputSheet(onResult: onResult),
  );
}

class _VoiceInputSheet extends StatefulWidget {
  final ValueChanged<String> onResult;

  const _VoiceInputSheet({required this.onResult});

  @override
  State<_VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<_VoiceInputSheet> {
  AsrService? _asr;
  AsrAudioCapture? _capture;
  final List<double> _levels = List.filled(32, 0.02);
  StreamSubscription<AsrPartial>? _partialSub;
  StreamSubscription<double>? _levelSub;
  String _partial = '';
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    final capture = AsrAudioCapture();
    // E-04：本地 sherpa 模型已装 → 离线识别；否则系统识别
    final prefs = await SharedPreferences.getInstance();
    final sherpaId = prefs.getString('asr_sherpa_model_id');
    final asr = await AsrServiceRegistry.effective(defaultLocalModelId: sherpaId);
    _capture = capture;
    _asr = asr;
    try {
      await capture.start();
      await asr.start();
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, l10n.voiceAsrError(e.toString()));
      Navigator.of(context).pop();
      return;
    }
    if (!mounted) return;
    _partialSub = asr.partials.listen((p) {
      if (!mounted) return;
      setState(() => _partial = p.text);
    });
    _levelSub = capture.amplitudes.listen((level) {
      if (!mounted) return;
      setState(() {
        _levels.removeAt(0);
        _levels.add(level.clamp(0.02, 1.0));
      });
    });
  }

  Future<void> _finish({required bool cancel}) async {
    if (_finishing) return;
    _finishing = true;
    final asr = _asr;
    final capture = _capture;
    String text = '';
    if (asr != null) {
      try {
        final result = cancel ? const AsrResult(text: '', cancelled: true) : await asr.stop();
        text = result.text;
      } catch (_) {}
      if (!cancel) asr.cancel();
    }
    await capture?.stop();
    if (!mounted) return;
    Navigator.of(context).pop();
    if (!cancel && text.trim().isNotEmpty) {
      widget.onResult(text.trim());
    }
  }

  @override
  void dispose() {
    _partialSub?.cancel();
    _levelSub?.cancel();
    _capture?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.voiceAsrListening,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              // 振幅柱状图（环形 32 柱）
              SizedBox(
                height: 48,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final level in _levels)
                      Container(
                        width: 4,
                        height: 8 + level * 40,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _partial.isEmpty ? l10n.voiceAsrTapToSpeak : _partial,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: _partial.isEmpty ? scheme.outline : scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _finish(cancel: true),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: 24),
                  FilledButton.icon(
                    onPressed: () => _finish(cancel: false),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(l10n.commonSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
