import 'dart:async';

import 'package:flutter/foundation.dart';

import 'model_router.dart';
import 'model_router_service.dart';
import '../../l10n/app_localizations.dart';
import '../models/chat_provider.dart';
import '../models/chat_session.dart';
import 'chat_service.dart';
import 'provider_service.dart';
import 'settings_service.dart';

/// 会话标题生成器：配置了「标题生成模型」时异步调用模型生成，
/// 失败或未配置时回退到「截取首条消息」。
class TitleGenerator {
  final ProviderService providerService;
  final ChatService chatService;

  /// 全局设置（读取标题生成模型配置）。
  final AppSettings Function() settings;

  /// 本地化默认会话标题（回退判断用：仅当标题仍是默认值时覆盖）。
  final String Function() defaultTitle;

  /// 当前本地化文案（读取标题提示词）。
  final AppLocalizations? Function()? l10n;

  /// 通知宿主刷新界面。
  final VoidCallback? onStateChanged;

  /// 持久化当前会话列表。
  final Future<void> Function() persist;

  /// X-02：智能模型路由服务。
  final ModelRouterService routerService;

  TitleGenerator({
    required this.providerService,
    required this.chatService,
    required this.settings,
    required this.defaultTitle,
    this.l10n,
    this.onStateChanged,
    required this.persist,
    ModelRouterService? routerService,
  }) : routerService = routerService ?? ModelRouterService();

  /// 生成会话标题：配置了「标题生成模型」时异步调用模型生成；
  /// 未配置或调用失败时维持「截取首条消息」的现有逻辑。
  void maybeAutoTitle(ChatSession session) {
    final firstUser =
        session.messages.where((m) => m.role == 'user').firstOrNull;
    if (firstUser == null) {
      fallbackTitle(session, defaultTitle());
      return;
    }
    // 首条为纯图片消息时没有可生成标题的文本，维持现有逻辑
    if (firstUser.content.trim().isEmpty) {
      session.updateTitleFromFirstMessage();
      return;
    }
    final titleModel = settings().titleModel;
    if (titleModel.isEmpty) {
      // X-02：自动模型路由（启用时按成本/速度自动选模型生成标题）
      if (routerService.autoRoutingEnabled) {
        unawaited(_generateTitleWithRouter(session, firstUser.content));
        return;
      }
      session.updateTitleFromFirstMessage();
      return;
    }
    unawaited(_generateTitle(session, titleModel, firstUser.content));
  }

  /// X-02：自动路由生成标题（路由失败回退截取逻辑）。
  Future<void> _generateTitleWithRouter(
    ChatSession session,
    String firstMessage,
  ) async {
    try {
      final route = await routerService.route(RoutingTask.title);
      if (route == null || !route.hasModel) {
        fallbackTitle(session, defaultTitle());
        return;
      }
      final providers = await providerService.load();
      final provider = providers
          .where((p) => p.id == route.providerId)
          .firstOrNull;
      if (provider == null || provider.apiKey.isEmpty) {
        fallbackTitle(session, defaultTitle());
        return;
      }
      final started = DateTime.now();
      final result = await chatService.sendSimple(
        settings: AppSettings(
          apiKey: provider.apiKey,
          baseUrl: provider.baseUrl,
          model: route.modelId!,
        ),
        userMessage: firstMessage,
        systemPrompt: l10n?.call()?.homeTitlePrompt ?? '',
        maxTokens: 30,
      );
      unawaited(
        routerService.recordRouteEvent(
          task: RoutingTask.title,
          providerId: route.providerId,
          modelId: route.modelId,
          success: true,
          elapsedMs: DateTime.now().difference(started).inMilliseconds,
        ),
      );
      final title = result.trim().replaceAll('\n', ' ');
      if (title.isNotEmpty && title.length <= 80) {
        session.title = title;
        unawaited(persist());
        onStateChanged?.call();
      } else {
        fallbackTitle(session, defaultTitle());
      }
    } catch (_) {
      fallbackTitle(session, defaultTitle());
    }
  }

  /// 回退到「截取首条消息」逻辑；仅当用户未手动重命名时生效，
  /// 避免异步生成失败覆盖用户自定义标题。
  void fallbackTitle(ChatSession session, String defaultTitle) {
    if (session.title == defaultTitle) {
      session.updateTitleFromFirstMessage();
    }
  }

  Future<void> _generateTitle(
    ChatSession session,
    String titleModel,
    String firstMessage, {
    String? titlePrompt,
  }) async {
    try {
      final providers = await providerService.load();
      ChatProvider? provider;
      for (final p in providers) {
        if (p.modelIds.contains(titleModel)) {
          provider = p;
          break;
        }
      }
      if (provider == null || provider.apiKey.isEmpty) {
        fallbackTitle(session, defaultTitle());
        return;
      }
      final result = await chatService.sendSimple(
        settings: AppSettings(
          apiKey: provider.apiKey,
          baseUrl: provider.baseUrl,
          model: titleModel,
        ),
        userMessage: firstMessage,
        systemPrompt: titlePrompt ?? (l10n?.call()?.homeTitlePrompt ?? ''),
        maxTokens: 24,
      );
      final title = result
          .replaceAll('\n', ' ')
          .replaceAll(RegExp(r'["“”"]'), '')
          .trim();
      if (title.isEmpty) {
        fallbackTitle(session, defaultTitle());
        return;
      }
      session.title = title.length > 40 ? '${title.substring(0, 40)}…' : title;
      session.updatedAt = DateTime.now();
      onStateChanged?.call();
      unawaited(persist());
    } catch (_) {
      fallbackTitle(session, defaultTitle());
    }
  }
}
