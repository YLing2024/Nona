// A-05 覆盖率门槛：解析 `flutter test --coverage` 生成的 lcov.info，
// 按域检查最低覆盖率，低于即失败（CI 中执行）。
//
// 用法：
//   flutter test --coverage
//   dart run tool/coverage_gate.dart [--report]
import 'dart:io';

/// 域 → 最低行覆盖率（%）。
///
/// chat/protocol/export/database 为核心域（严格门槛）；sync/knowledge 以
/// embedding/WebDAV 等网络密集代码为主，门槛反映当前测试达成值。
const Map<String, double> kDomainThresholds = {
  'core/database': 40,
  'core/services/chat': 70,
  'core/services/protocol': 70,
  'core/services/mcp': 60,
  'core/services/export': 70,
  'core/services/sync': 42,
  'core/services/usage': 45,
  'core/services/knowledge': 45,
  'core/services/web_search': 50,
  'core/models': 60,
};

/// 整体最低覆盖率（%）。
const double kOverallThreshold = 45;

void main(List<String> args) {
  final report = args.contains('--report');
  final root = Directory.current.path;
  final lcov = File('$root/coverage/lcov.info');
  if (!lcov.existsSync()) {
    stderr.writeln('缺少 coverage/lcov.info，请先运行 flutter test --coverage');
    exitCode = 1;
    return;
  }

  // 解析 lcov：SF: <path> / LF: 可执行行数 / LH: 命中行数
  final domains = <String, (int, int)>{};
  var totalLf = 0;
  var totalLh = 0;
  String? current;
  int? lf;
  int? lh;
  void flush() {
    if (current != null && lf != null && lh != null) {
      final rel = current!.replaceAll(r'\', '/');
      // 生成代码不参与覆盖率统计：drift 生成（.g.dart）与
      // gen-l10n 生成（lib/l10n/app_localizations*.dart，模板化产物）
      if (!rel.endsWith('.g.dart') && !rel.startsWith('lib/l10n/')) {
        final domain = _domainOf(rel);
        if (domain != null) {
          final (lf0, lh0) = domains[domain] ?? (0, 0);
          domains[domain] = (lf0 + lf!, lh0 + lh!);
        }
        if (rel.startsWith('lib/')) {
          totalLf += lf!;
          totalLh += lh!;
        }
      }
    }
    current = null;
    lf = null;
    lh = null;
  }

  for (final line in lcov.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      flush();
      current = line.substring(3).trim();
    } else if (line.startsWith('LF:')) {
      lf = int.tryParse(line.substring(3).trim());
    } else if (line.startsWith('LH:')) {
      lh = int.tryParse(line.substring(3).trim());
    }
  }
  flush();

  if (report) {
    stdout.writeln('=== 覆盖率报告 ===');
    final sorted = domains.entries.toList()
      ..sort((a, b) => _rate(b.value).compareTo(_rate(a.value)));
    for (final e in sorted) {
      stdout.writeln(
        '  ${_pad(e.key, 42)} ${(_rate(e.value) * 100).toStringAsFixed(1)}%',
      );
    }
    stdout.writeln(
      '  整体                                    '
      '${totalLf == 0 ? 0 : (totalLh / totalLf * 100).toStringAsFixed(1)}%',
    );
  }

  final failures = <String>[];
  for (final e in kDomainThresholds.entries) {
    final (lf0, lh0) = domains[e.key] ?? (0, 0);
    if (lf0 == 0) {
      // 无该域测试：不判失败（避免新目录直接红灯），仅提示
      stdout.writeln('  提示：域 ${e.key} 无覆盖数据');
      continue;
    }
    final rate = lh0 / lf0 * 100;
    if (rate < e.value) {
      failures.add('${e.key}: ${rate.toStringAsFixed(1)}% < ${e.value}%');
    }
  }
  final overall = totalLf == 0 ? 0.0 : totalLh / totalLf * 100;
  if (overall < kOverallThreshold) {
    failures.add('整体: ${overall.toStringAsFixed(1)}% < $kOverallThreshold%');
  }

  if (failures.isEmpty) {
    stdout.writeln('覆盖率门槛通过（整体 ${overall.toStringAsFixed(1)}%）');
  } else {
    stderr.writeln('覆盖率门槛未通过：');
    for (final f in failures) {
      stderr.writeln('  $f');
    }
    exitCode = 1;
  }
}

String? _domainOf(String rel) {
  final inner = rel.startsWith('lib/') ? rel.substring(4) : rel;
  for (final d in kDomainThresholds.keys) {
    if (inner.startsWith('$d/')) return d;
  }
  return null;
}

double _rate((int, int) v) => v.$1 == 0 ? 0 : v.$2 / v.$1;

String _pad(String s, int n) =>
    s.length >= n ? s : '$s${List.filled(n - s.length, ' ').join()}';
