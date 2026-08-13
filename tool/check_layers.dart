// A-02 层检查：校验依赖方向，CI 中执行。
//
// 规则：
//   1. core/ 禁止 import features/（core 是地基，不依赖任何 UI 域）；
//   2. features/<x>/ 禁止 import features/<y>/（y != x，跨域 UI 耦合）；
//   3. 例外：shared/app_routes.dart 为全局路由表，允许引用全部 features。
//
// 用法：dart run tool/check_layers.dart
import 'dart:io';

void main() {
  final root = Directory.current.path;
  final libDir = Directory('$root/lib');
  if (!libDir.existsSync()) {
    stderr.writeln('lib/ 不存在');
    exitCode = 1;
    return;
  }

  final violations = <String>[];
  void walk(Directory dir) {
    for (final e in dir.listSync()) {
      if (e is Directory) {
        walk(e);
      } else if (e.path.endsWith('.dart')) {
        _checkFile(File(e.path), violations);
      }
    }
  }

  walk(libDir);

  if (violations.isEmpty) {
    stdout.writeln('层检查通过：无依赖方向违规');
  } else {
    stdout.writeln('层检查失败（${violations.length} 处违规）：');
    for (final v in violations) {
      stdout.writeln('  $v');
    }
    exitCode = 1;
  }
}

void _checkFile(File file, List<String> violations) {
  final rel = file.path.replaceAll(r'\', '/').split('/lib/').last;
  final inCore = rel.startsWith('core/');
  final featureMatch = RegExp(r'^features/([^/]+)/').firstMatch(rel);
  final isAppRoutes = rel == 'shared/app_routes.dart';
  final uriRe = RegExp(r"""['"]((?:\.\./)+[^'"]+)['"]""");
  final lines = file.readAsStringSync().split('\n');
  for (final line in lines) {
    for (final m in uriRe.allMatches(line)) {
      final uri = m.group(1)!;
      final resolved = _resolve(rel, uri);
      if (resolved == null) continue;
      // core → features 违规
      if (inCore && resolved.startsWith('features/')) {
        violations.add('core→features: $rel → $resolved');
        continue;
      }
      // feature → 其他 feature 违规
      if (featureMatch != null) {
        final targetFeature =
            RegExp(r'^features/([^/]+)/').firstMatch(resolved)?.group(1);
        if (targetFeature != null &&
            targetFeature != featureMatch.group(1) &&
            !isAppRoutes) {
          // 放行：导航到其他 feature 的 screen（页面跳转耦合允许）；
          // 其余（widgets/controllers/services）一律禁止。
          final targetIsScreen =
              RegExp(r'^features/[^/]+/screens/').hasMatch(resolved);
          if (!targetIsScreen) {
            violations.add(
              'feature→feature: $rel → $resolved',
            );
          }
        }
      }
    }
  }
}

/// 相对 URI 解析（POSIX）。
String? _resolve(String fromRel, String uri) {
  if (uri.startsWith('package:') ||
      uri.startsWith('dart:') ||
      uri.startsWith('asset:')) {
    return null;
  }
  final base = fromRel.split('/').sublist(0, fromRel.split('/').length - 1);
  final parts = uri.split('/');
  for (final p in parts) {
    if (p == '..') {
      if (base.isNotEmpty) base.removeLast();
    } else if (p == '.') {
      continue;
    } else {
      base.add(p);
    }
  }
  return base.join('/');
}
