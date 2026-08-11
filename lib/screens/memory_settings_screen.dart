import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// 记忆设置页：全局开关 + 预算配置。
class MemorySettingsScreen extends StatefulWidget {
  const MemorySettingsScreen({super.key});

  @override
  State<MemorySettingsScreen> createState() => _MemorySettingsScreenState();
}

class _MemorySettingsScreenState extends State<MemorySettingsScreen> {
  late final SettingsService _settings = SettingsService();
  bool _enabled = true;
  int _maxItems = 200;
  int _maxInjectTokens = 800;
  int _maxItemChars = 100;
  int _extractionInterval = 10;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _settings.load();
    if (!mounted) return;
    setState(() {
      _enabled = s.memoryEnabled ?? true;
      _maxItems = s.memoryMaxItems ?? 200;
      _maxInjectTokens = s.memoryMaxInjectTokens ?? 800;
      _maxItemChars = s.memoryMaxItemChars ?? 100;
      _extractionInterval = s.memoryExtractionInterval ?? 10;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final s = await _settings.load();
    s.memoryEnabled = _enabled;
    s.memoryMaxItems = _maxItems;
    s.memoryMaxInjectTokens = _maxInjectTokens;
    s.memoryMaxItemChars = _maxItemChars;
    s.memoryExtractionInterval = _extractionInterval;
    await _settings.save(s);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记忆设置已保存')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('记忆设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('启用记忆功能'),
            subtitle: const Text('关闭后不再自动提取与注入记忆'),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const Divider(),
          _budgetTile(
            '记忆库总容量（条）',
            _maxItems,
            (v) => setState(() => _maxItems = v),
            min: 50,
            max: 1000,
          ),
          _budgetTile(
            '注入 token 预算',
            _maxInjectTokens,
            (v) => setState(() => _maxInjectTokens = v),
            min: 100,
            max: 4000,
            step: 100,
          ),
          _budgetTile(
            '单条记忆最大字数',
            _maxItemChars,
            (v) => setState(() => _maxItemChars = v),
            min: 30,
            max: 300,
          ),
          _budgetTile(
            '自动提取间隔（轮）',
            _extractionInterval,
            (v) => setState(() => _extractionInterval = v),
            min: 2,
            max: 50,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('保存设置'),
          ),
        ],
      ),
    );
  }

  Widget _budgetTile(
    String label,
    int value,
    ValueChanged<int> onChange, {
    required int min,
    required int max,
    int step = 10,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: value > min
                ? () => onChange((value - step).clamp(min, max))
                : null,
          ),
          Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: value < max
                ? () => onChange((value + step).clamp(min, max))
                : null,
          ),
        ],
      ),
    );
  }
}
