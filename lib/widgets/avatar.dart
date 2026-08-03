import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 消息头像：助手为品牌渐变圆形 + Nona 图标，用户为首字母。
class MessageAvatar extends StatelessWidget {
  final bool isUser;
  final String userName;
  final double size;

  const MessageAvatar({
    super.key,
    required this.isUser,
    this.userName = '我',
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (isUser) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant),
        ),
        alignment: Alignment.center,
        child: Text(
          userName.isEmpty ? '我' : userName.characters.first,
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: kBrandGradient,
        boxShadow: const [
          BoxShadow(
            color: Color(0x334F46E5),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.auto_awesome_rounded,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }
}
