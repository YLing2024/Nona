import 'package:flutter/material.dart';

/// 设置页通用分组标签（settings / developer_options / about 三屏共用）。
class SettingsSectionLabel extends StatelessWidget {
  final String label;

  const SettingsSectionLabel(this.label, {super.key});

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

/// 设置卡片容器（白底圆角 + 细边框）。
class SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

/// 设置条目（图标 + 标题 + 副标题 + 可点击）。
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  /// 危险项（删除/清空）：标题使用错误色。
  final bool danger;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? scheme.error : null;
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
        title,
        style: TextStyle(
            fontSize: 14.5, fontWeight: FontWeight.w600, color: color),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: onTap == null
          ? null
          : Icon(Icons.chevron_right_rounded, size: 20, color: scheme.outline),
    );
  }
}

/// 设置条目分隔线。
class TileDivider extends StatelessWidget {
  const TileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 70,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
