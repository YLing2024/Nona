import 'package:flutter_test/flutter_test.dart';

import 'package:nona_chat/core/utils/prompt_variables.dart';

void main() {
  group('PromptVariables', () {
    test('注入固定时间后各变量精确展开', () {
      final now = DateTime(2026, 8, 9, 12, 5);
      final text = PromptVariables.resolve(
        '{cur_date} {cur_time} {cur_datetime} {timezone} {model_id} {locale}',
        modelId: 'gpt-4o',
        locale: 'zh',
        now: now,
      );
      expect(text, '2026-08-09 12:05 2026-08-09 12:05 ${now.timeZoneName} gpt-4o zh');
    });

    test('user_name 按语言取默认称谓', () {
      expect(
        PromptVariables.resolve('{user_name}', locale: 'zh', now: DateTime(2026)),
        '用户',
      );
      expect(
        PromptVariables.resolve('{user_name}', locale: 'en', now: DateTime(2026)),
        'User',
      );
    });

    test('未知变量保留原样', () {
      expect(
        PromptVariables.resolve('{unknown_var}', now: DateTime(2026)),
        '{unknown_var}',
      );
    });

    test('空文本直接返回', () {
      expect(PromptVariables.resolve('', now: DateTime(2026)), '');
    });

    test('formatDateTime 格式化时间戳', () {
      expect(
        formatDateTime(DateTime(2026, 8, 9, 12, 5)),
        '2026-08-09 12:05',
      );
    });
  });
}
