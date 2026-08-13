import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/models/chat_provider.dart' show ChatProvider;
import '../../../core/network/app_http_client.dart';
import '../../../core/services/network_log_service.dart';

/// 图片生成结果。
class ImageGenResult {
  final String url;
  final String? b64;

  const ImageGenResult({required this.url, this.b64});
}

/// 图片生成适配器（F1-4）：OpenAI 兼容 `/images/generations` / `/images/edits`。
class ImagesAdapter {
  /// 生成图片；[size] 如 1024x1024；[n] 1-4。
  Future<List<ImageGenResult>> generateImage(
    ChatProvider provider, {
    required String prompt,
    String size = '1024x1024',
    int n = 1,
  }) async {
    final base = provider.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/images/generations');
    final response = await AppHttpClient.instance.send(
      method: 'POST',
      uri: uri,
      headers: AppHttpClient.jsonHeaders(bearer: provider.apiKey),
      body: jsonEncode({
        'model': _modelFor(provider),
        'prompt': prompt,
        'size': size,
        'n': n.clamp(1, 4),
      }),
      type: NetworkLogType.other,
      timeout: const Duration(seconds: 120),
      retry: false,
    );
    if (response.statusCode != 200) {
      throw http.ClientException(
        'image generation failed (HTTP ${response.statusCode}): '
        '${AppHttpClient.extractApiError(response.body)}',
      );
    }
    return _parse(response.body);
  }

  /// 图片编辑（多部分表单）。
  Future<List<ImageGenResult>> editImage(
    ChatProvider provider, {
    required String prompt,
    required List<int> imageBytes,
    required String imageName,
    String size = '1024x1024',
  }) async {
    final base = provider.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/images/edits');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${provider.apiKey}'
      ..fields['model'] = _modelFor(provider)
      ..fields['prompt'] = prompt
      ..fields['size'] = size
      ..files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: imageName),
      );
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw http.ClientException(
        'image edit failed (HTTP ${streamed.statusCode}): '
        '${AppHttpClient.extractApiError(body)}',
      );
    }
    return _parse(body);
  }

  /// 图片生成模型：优先自定义，否则取服务商第一个模型。
  static String _modelFor(ChatProvider provider) {
    if (provider.modelIds.isNotEmpty) return provider.modelIds.first;
    return 'dall-e-3';
  }

  static List<ImageGenResult> _parse(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>)
          ImageGenResult(
            url: e['url'] as String? ?? '',
            b64: e['b64_json'] as String?,
          ),
    ];
  }

  /// 服务商是否具备图片生成能力（能力表 imageGen 或模型名启发式）。
  static bool supportsImageGen(ChatProvider provider) {
    if (provider.modelConfigs.values.any((c) => c.imageGen)) return true;
    return provider.modelIds.any(_heuristicImageGen);
  }

  static bool _heuristicImageGen(String modelId) {
    final m = modelId.toLowerCase();
    return m.contains('dall-e') ||
        m.contains('image') ||
        m.contains('flux') ||
        m.contains('sdxl') ||
        m.contains('stable-diffusion');
  }
}
