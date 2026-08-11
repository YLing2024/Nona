import 'dart:io';

/// 从 pubspec.yaml 读取 version，生成 lib/version.dart（单一事实源）。
///
/// 用法：`dart run tool/gen_version.dart`
/// 升级版本号流程：改 pubspec.yaml → 运行本脚本 → 提交生成文件。
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*(.+)$',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) {
    stderr.writeln('pubspec.yaml 缺少 version 字段');
    exitCode = 1;
    return;
  }
  final version = match.group(1)!.trim();
  final out = '''
/// 由 tool/gen_version.dart 自动生成，勿手改。
///
/// 与 pubspec.yaml 的 version 字段保持一致的唯一来源；
/// 升级版本号后请重新运行 `dart run tool/gen_version.dart`。
const String kAppVersion = '$version';
''';
  File('lib/version.dart').writeAsStringSync(out, flush: true);
  stdout.writeln('lib/version.dart 已生成: $version');
}
