import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../services/theme_controller.dart';

/// 主题配置页：跟随系统 / 浅色 / 深色（OLED 纯黑）。
class ThemeSettingsScreen extends StatefulWidget {
  final String initialThemeMode;

  const ThemeSettingsScreen({super.key, required this.initialThemeMode});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialThemeMode;
  }

  Future<void> _select(String value) async {
    setState(() => _selected = value);
    final service = SettingsService();
    final current = await service.load();
    await service.save(current.copyWith(themeMode: value));
    themeModeNotifier.value = themeModeFromStr(value);
    if (!mounted) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('主题配置')),
      body: SafeArea(
        top: false,
        child: RadioGroup<String>(
          groupValue: _selected,
          onChanged: (v) {
            if (v != null) _select(v);
          },
          child: ListView(
            children: [
              for (final option in const ['system', 'light', 'dark'])
                RadioListTile<String>(
                  value: option,
                  title: Text(themeModeLabel(option)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
