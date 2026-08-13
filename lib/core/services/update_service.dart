import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../version.dart';
import 'network_log_service.dart';
import 'settings_service.dart';
import '../network/app_http_client.dart';

/// 版本信息（J-02）。
class ReleaseInfo {
  final String tagName;
  final String name;
  final String body;
  final String htmlUrl;

  const ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
  });

  /// 从 GitHub Releases API 项解析。
  factory ReleaseInfo.fromJson(Map<String, dynamic> json) => ReleaseInfo(
    tagName: json['tag_name']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    htmlUrl: json['html_url']?.toString() ?? '',
  );
}

/// 版本更新检查（J-02）。
///
/// - [checkForUpdate]：请求 GitHub Releases `/releases/latest`（或
///   [AppSettings.updateSource] 自定义源），semver 比较当前版本；
/// - 无新版/网络失败返回 null（不打扰用户）。
class UpdateService {
  /// 默认检查源（GitHub 仓库的 releases/latest）。
  static const String kDefaultSource =
      'https://api.github.com/repos/{owner}/{repo}/releases/latest';

  /// 实际仓库地址（由调用方注入；默认 Nona 占位）。
  String repository = '';

  Future<ReleaseInfo?> checkForUpdate({AppSettings? settings}) async {
    final source = (settings?.updateSource.isNotEmpty ?? false)
        ? settings!.updateSource
        : _repoUrl();
    if (source.isEmpty) return null;
    try {
      final response = await AppHttpClient.instance.send(
        method: 'GET',
        uri: Uri.parse(source),
        type: NetworkLogType.other,
        timeout: const Duration(seconds: 15),
        retry: false,
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;
      final release = ReleaseInfo.fromJson(data);
      final remote = _versionOfTag(release.tagName);
      if (remote == null || _isNewer(remote, _versionOf(kAppVersion))) {
        return null;
      }
      return release;
    } catch (_) {
      // 网络失败静默（用户可在设置页手动检查）
      return null;
    }
  }

  String _repoUrl() {
    if (repository.isEmpty) return '';
    final parts = repository.split('/');
    if (parts.length < 2) return '';
    return kDefaultSource
        .replaceAll('{owner}', parts[parts.length - 2])
        .replaceAll('{repo}', parts.last);
  }

  /// 从 tag 提取版本（v1.2.3 → 1.2.3）。
  static (int, int, int)? _versionOfTag(String tag) {
    final cleaned = tag.startsWith('v') ? tag.substring(1) : tag;
    return _versionOf(cleaned);
  }

  /// 解析 semver（主.次.补丁），失败返回 null。
  static (int, int, int)? _versionOf(String raw) {
    final m = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(raw.trim());
    if (m == null) return null;
    return (
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  /// remote > current 时返回 true（有新版本）。
  static bool _isNewer((int, int, int) remote, (int, int, int)? current) {
    if (current == null) return false;
    if (remote.$1 != current.$1) return remote.$1 > current.$1;
    if (remote.$2 != current.$2) return remote.$2 > current.$2;
    return remote.$3 > current.$3;
  }

  /// 测试辅助：判断 remote 是否更新。
  @visibleForTesting
  static bool isNewerVersion(String remoteTag, String currentVersion) =>
      _isNewer(
        _versionOfTag(remoteTag) ?? (0, 0, 0),
        _versionOf(currentVersion),
      );
}
