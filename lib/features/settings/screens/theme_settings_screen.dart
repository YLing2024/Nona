import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/theme_controller.dart';

/// 主题配置页：模式（跟随系统/浅色/深色）+ 强调色预设/自定义 + OLED 纯黑。
class ThemeSettingsScreen extends StatefulWidget {
  final String initialThemeMode;

  const ThemeSettingsScreen({super.key, required this.initialThemeMode});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  late String _selected;
  late Color _accent;
  late bool _oled;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialThemeMode;
    _accent = accentColorNotifier.value;
    _oled = oledDarkNotifier.value;
  }

  Future<void> _select(String value) async {
    setState(() => _selected = value);
    final service = context.read<SettingsService>();
    final current = await service.load();
    await service.save(current.copyWith(themeMode: value));
    themeModeNotifier.value = themeModeFromStr(value);
    if (!mounted) return;
    Navigator.of(context).pop(value);
  }

  Future<void> _applyAccent(Color color) async {
    setState(() => _accent = color);
    final service = context.read<SettingsService>();
    final current = await service.load();
    await service.save(current.copyWith(accentColor: color.toARGB32()));
    accentColorNotifier.value = color;
  }

  Future<void> _pickCustomColor() async {
    var picked = _accent;
    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.themeCustomTitle),
        content: _CustomColorPicker(
          initial: _accent,
          onChanged: (c) => picked = c,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(picked),
            child: Text(ctx.l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (result != null) await _applyAccent(result);
  }

  Future<void> _toggleOled(bool value) async {
    setState(() => _oled = value);
    final service = context.read<SettingsService>();
    final current = await service.load();
    await service.save(current.copyWith(oledDark: value));
    oledDarkNotifier.value = value;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.themeTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              l10n.themeModeSection,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: scheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: RadioGroup<String>(
                groupValue: _selected,
                onChanged: (v) {
                  if (v != null) _select(v);
                },
                child: Column(
                  children: [
                    for (final option in const ['system', 'light', 'dark'])
                      RadioListTile<String>(
                        value: option,
                        title: Text(themeModeLabel(option, l10n)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.themeAccentSection,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: scheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final (name, color) in AppAccentPreset.presets)
                        _ColorSwatch(
                          color: color,
                          label: AppAccentPreset.presetLabel(name, l10n),
                          selected: _accent.toARGB32() == color.toARGB32(),
                          onTap: () => _applyAccent(color),
                        ),
                      _ColorSwatch(
                        color: _accent,
                        label: l10n.themeCustom,
                        selected:
                            AppAccentPreset.presetName(_accent) == null,
                        onTap: _pickCustomColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppAccentPreset.presetName(_accent) != null
                            ? AppAccentPreset.presetLabel(
                                AppAccentPreset.presetName(_accent)!, l10n)
                            : l10n.themeCustomColor,
                        style: TextStyle(fontSize: 12.5, color: scheme.outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.themeDarkSection,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: scheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Text(
                  l10n.themeOledTitle,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  l10n.themeOledSubtitle,
                  style: TextStyle(fontSize: 12),
                ),
                value: _oled,
                onChanged: _toggleOled,
              ),
            ),
            const SizedBox(height: 8),
            // H-02/H-03：显示设置（密度 / 聊天字号 / 字体）
            Text(
              l10n.displayUiDensity,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.outline,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'compact',
                  label: Text(l10n.densityCompact),
                ),
                ButtonSegment(
                  value: 'standard',
                  label: Text(l10n.densityStandard),
                ),
                ButtonSegment(
                  value: 'comfortable',
                  label: Text(l10n.densityComfortable),
                ),
              ],
              selected: {_density},
              onSelectionChanged: (s) => _setDensity(s.first),
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n.displayChatFontScale}: ${_fontScale.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.outline,
                letterSpacing: 0.8,
              ),
            ),
            Slider(
              value: _fontScale,
              min: 1.0,
              max: 1.2,
              divisions: 2,
              label: _fontScale.toStringAsFixed(1),
              onChanged: (v) => setState(() => _fontScale = v),
              onChangeEnd: (v) => _setFontScale(v),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.displayFontFamily,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.outline,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: '',
                  label: Text(l10n.displayFontSystem),
                ),
                ButtonSegment(
                  value: 'Noto Sans SC',
                  label: const Text('Noto Sans SC'),
                ),
              ],
              selected: {_fontFamily},
              onSelectionChanged: (s) => _setFontFamily(s.first),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- H-02/H-03：显示设置 ----------------

  late String _density = 'standard';
  late double _fontScale = 1.0;
  late String _fontFamily = '';

  Future<void> _setDensity(String value) async {
    setState(() => _density = value);
    final service = context.read<SettingsService>();
    final current = await service.load();
    await service.save(current.copyWith(uiDensity: value));
  }

  Future<void> _setFontScale(double value) async {
    setState(() => _fontScale = value);
    final service = context.read<SettingsService>();
    final current = await service.load();
    await service.save(current.copyWith(chatFontScale: value));
  }

  Future<void> _setFontFamily(String value) async {
    setState(() => _fontFamily = value);
    final service = context.read<SettingsService>();
    final current = await service.load();
    await service.save(current.copyWith(fontFamily: value));
  }
}

/// 自定义取色器选中的临时颜色（确定按钮读取）。

/// 简化取色器：HSB 滑杆（色相 + 饱和度/明度滑杆）。
/// 颜色变化经 [onChanged] 实时上报（由宿主持有，避免模块级全局状态）。
class _CustomColorPicker extends StatefulWidget {
  final Color initial;
  final ValueChanged<Color> onChanged;

  const _CustomColorPicker({required this.initial, required this.onChanged});

  @override
  State<_CustomColorPicker> createState() => _CustomColorPickerState();
}

class _CustomColorPickerState extends State<_CustomColorPicker> {
  late double _hue;
  late double _saturation;
  late double _value;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initial);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  Color get _color => HSVColor.fromAHSV(1, _hue, _saturation, _value).toColor();

  void _update() {
    setState(() {});
    widget.onChanged(_color);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SliderRow(
            label: context.l10n.themeHue,
            value: _hue,
            max: 360,
            onChanged: (v) {
              _hue = v;
              _update();
            },
          ),
          _SliderRow(
            label: context.l10n.themeSaturation,
            value: _saturation,
            max: 1,
            onChanged: (v) {
              _saturation = v;
              _update();
            },
          ),
          _SliderRow(
            label: context.l10n.themeValue,
            value: _value,
            max: 1,
            onChanged: (v) {
              _value = v;
              _update();
            },
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(label, style: TextStyle(fontSize: 12.5, color: scheme.outline)),
        ),
        Expanded(
          child: Slider(value: value, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

/// 色板圆点：选中时带外圈高亮。
class _ColorSwatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: selected ? scheme.primary : scheme.outline,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
