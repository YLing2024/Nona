import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_provider.dart';
import '../models/chat_message.dart';
import '../models/chat_options.dart';
import 'chat_service.dart';
import 'settings_service.dart';

/// OCR 服务（F1-5）：图片附件「转为文字」→ vision 模型提取 →
/// 结果替换图片入消息；失败回退原图。
///
/// 提示词可编辑：prefs `ocr_prompt_override`，默认 assets/prompts/ocr.txt。
class OcrService {
  final ChatService chatService;
  final SettingsService settingsService;

  static const String kPromptOverride = 'ocr_prompt_override';

  OcrService({
    ChatService? chatService,
    SettingsService? settingsService,
  }) : chatService = chatService ?? ChatService(),
       settingsService = settingsService ?? SettingsService();

  /// 读取提示词（prefs 覆盖优先）。
  Future<String> loadPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final override = prefs.getString(kPromptOverride);
      if (override != null && override.trim().isNotEmpty) {
        return override;
      }
    } catch (_) {}
    try {
      return await rootBundle.loadString('assets/prompts/ocr.txt');
    } catch (_) {
      return '请识别图片中的文字并完整输出，保留原有格式。';
    }
  }

  /// 保存自定义提示词（空则恢复默认）。
  Future<void> savePrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(kPromptOverride);
    } else {
      await prefs.setString(kPromptOverride, trimmed);
    }
  }

  /// 对单张图片执行 OCR。
  ///
  /// [settings] 为 vision 模型的服务商设置（能力表校验 multimodal 由调用方做）。
  /// 成功返回识别文本；失败抛异常。
  Future<String> extract(
    ChatImage image,
    AppSettings settings, {
    String? prompt,
  }) async {
    final p = prompt ?? await loadPrompt();
    final handle = chatService.sendChat(
      settings: settings,
      messages: [
        ChatMessage(role: 'user', content: p, images: [image]),
      ],
      options: ChatOptions(
        stream: false,
        maxTokens: 800,
        temperature: 0.0,
        systemPrompt: p,
      ),
    );
    final result = await handle.result;
    final text = result.content.trim();
    if (text.isEmpty) {
      throw const ChatException('', code: ChatException.emptyResponse);
    }
    return text;
  }

  /// 检查服务商是否有可用的多模态模型（OCR 前置校验）。
  static bool hasVisionModel(ChatProvider provider) {
    if (provider.modelIds.isEmpty) return false;
    for (final id in provider.modelIds) {
      final config = provider.modelConfigs[id];
      if (config?.multimodal ?? false) return true;
      final m = id.toLowerCase();
      if (m.contains('vision') ||
          m.contains('gpt-4o') ||
          m.contains('gemini') ||
          m.contains('claude') ||
          m.contains('qwen-vl') ||
          m.contains('glm-4v')) {
        return true;
      }
    }
    return false;
  }
}
