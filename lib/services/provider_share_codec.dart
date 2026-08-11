import 'dart:convert';

import '../models/chat_provider.dart';
import 'chat_protocol.dart' show ProviderKind;

/// 服务商配置分享：编码为可粘贴/二维码传输的文本。
///
/// 格式：`ai-provider:v1:base64url(JSON)`，JSON 含名称/地址/Key/协议/自定义头。
class ProviderShareCodec {
  static const prefix = 'ai-provider:v1:';

  /// 编码单个服务商为分享文本（不含密钥字段时 [includeKey] 置 false）。
  static String encode(ChatProvider provider, {bool includeKey = true}) {
    final data = {
      'name': provider.name,
      'baseUrl': provider.baseUrl,
      if (includeKey && provider.apiKey.isNotEmpty) 'apiKey': provider.apiKey,
      'kind': provider.kind.name,
      if (provider.customHeaders.isNotEmpty) 'customHeaders': provider.customHeaders,
      if (provider.customBody != null) 'customBody': provider.customBody,
      'modelIds': provider.modelIds,
      if (provider.modelConfigs.isNotEmpty)
        'modelConfigs': provider.modelConfigs
            .map((k, v) => MapEntry(k, v.toJson())),
    };
    return '$prefix${base64Url.encode(utf8.encode(jsonEncode(data)))}';
  }

  /// 解析分享文本为服务商配置；无法解析返回 null。
  static ChatProvider? decode(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith(prefix)) return null;
    try {
      final payload = base64Url.decode(trimmed.substring(prefix.length));
      final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
      final baseUrl = json['baseUrl'] as String? ?? '';
      if (baseUrl.isEmpty) return null;
      return ChatProvider(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: json['name'] as String? ?? '导入的服务商',
        baseUrl: baseUrl,
        apiKey: json['apiKey'] as String? ?? '',
        kind: ProviderKind.fromName(json['kind'] as String?),
        customHeaders: (json['customHeaders'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            const {},
        customBody: json['customBody'] as Map<String, dynamic>?,
        modelIds: (json['modelIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        modelConfigs: (json['modelConfigs'] as Map<String, dynamic>?)
                ?.map(
                  (k, v) => MapEntry(
                    k,
                    ModelConfig.fromJson(v as Map<String, dynamic>),
                  ),
                ) ??
            const {},
      );
    } catch (_) {
      return null;
    }
  }
}
