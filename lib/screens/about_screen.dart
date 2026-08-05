import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// 项目 GitHub 仓库地址（HTTPS 形式）。
const String kProjectGithubUrl = 'https://github.com/YLing2024/nona';

/// 应用版本号，需与 pubspec.yaml 中的 version 保持一致。
const String kAppVersion = '1.1.0+1';

/// 开源许可名称。
const String kAppLicense = 'MIT License';

/// 关于页：展示项目信息（GitHub 地址 / 版本 / 系统 / 开源许可）+ 开发者模式开关。
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _developerMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await SettingsService().load();
    if (!mounted) return;
    setState(() => _developerMode = settings.developerMode);
  }

  Future<void> _toggleDeveloperMode(bool value) async {
    setState(() => _developerMode = value);
    final settings = await SettingsService().load();
    await SettingsService().save(settings.copyWith(developerMode: value));
  }

  String _platformLabel() {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  Future<void> _openGithub() async {
    final uri = Uri.parse(kProjectGithubUrl);
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            // 应用标识
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: kBrandGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: kSoftShadow,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Nona',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                '一款简洁高效的 AI 聊天客户端，兼容 OpenAI 格式接口',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // 项目信息
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.code_rounded,
                    iconColor: theme.colorScheme.primary,
                    label: 'GitHub 仓库',
                    value: 'YLing2024/nona',
                    onTap: _openGithub,
                  ),
                  const _TileDivider(),
                  const _InfoTile(
                    icon: Icons.tag_rounded,
                    iconColor: AppColors.secondary,
                    label: '版本',
                    value: kAppVersion,
                  ),
                  const _TileDivider(),
                  _InfoTile(
                    icon: Icons.computer_rounded,
                    iconColor: theme.colorScheme.tertiary,
                    label: '系统',
                    value: _platformLabel(),
                  ),
                  const _TileDivider(),
                  const _InfoTile(
                    icon: Icons.gavel_rounded,
                    iconColor: AppColors.success,
                    label: '开源许可',
                    value: kAppLicense,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('开发者'),
            // 开发者模式开关
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                secondary: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.developer_mode_rounded,
                    size: 19,
                    color: AppColors.tertiary,
                  ),
                ),
                title: const Text(
                  '开发者模式',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  '启用后，设置页将显示「开发者选项」高级设置',
                  style: TextStyle(fontSize: 12),
                ),
                value: _developerMode,
                onChanged: _toggleDeveloperMode,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Copyright © 2026 Yunling Zhang · 本地优先，所有数据仅保存在本机',
                style: TextStyle(
                  fontSize: 11.5,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: iconColor),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(value, style: const TextStyle(fontSize: 12)),
      trailing: onTap == null
          ? null
          : Icon(Icons.open_in_new_rounded, size: 18, color: scheme.outline),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 70,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
