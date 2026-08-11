import 'package:intl/intl.dart';

/// Prompt 变量替换：发送前将系统提示词/首条消息中的变量展开。
///
/// 支持变量：
/// - {cur_date} / {cur_time} / {cur_datetime}：当前日期时间
/// - {model_id} / {model_name}：当前模型
/// - {locale}：界面语言
/// - {timezone}：时区
/// - {user_name}：用户名（暂无设置，默认「用户」）
class PromptVariables {
  /// 展开文本中的全部变量。
  ///
  /// [now] 可注入固定时间（测试用）；默认取当前时间。
  static String resolve(
    String text, {
    String modelId = '',
    String locale = '',
    DateTime? now,
  }) {
    if (text.isEmpty) return text;
    final nowTime = now ?? DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final date =
        '${nowTime.year}-${two(nowTime.month)}-${two(nowTime.day)}';
    final time = '${two(nowTime.hour)}:${two(nowTime.minute)}';
    final datetime = '$date $time';
    final tz = nowTime.timeZoneName;

    String resolveVar(String name) => switch (name) {
      'cur_date' => date,
      'cur_time' => time,
      'cur_datetime' => datetime,
      'model_id' => modelId,
      'model_name' => modelId,
      'locale' => locale,
      'timezone' => tz,
      // 用户名暂无设置项；按界面语言给出默认称谓
      'user_name' => locale == 'zh' ? '用户' : 'User',
      _ => '{$name}',
    };

    return text.replaceAllMapped(
      RegExp(r'\{([a-z_]+)\}'),
      (m) => resolveVar(m.group(1)!),
    );
  }

  /// 变量说明（设置页提示用）。
  static const List<String> available = [
    '{cur_date} 当前日期',
    '{cur_time} 当前时间',
    '{cur_datetime} 日期+时间',
    '{model_id} 模型 ID',
    '{locale} 界面语言',
    '{timezone} 时区',
  ];
}

/// 格式化时间戳（导出/日志用）。
String formatDateTime(DateTime t) => DateFormat('yyyy-MM-dd HH:mm').format(t);
