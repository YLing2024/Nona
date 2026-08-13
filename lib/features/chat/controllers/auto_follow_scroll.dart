import 'package:flutter/widgets.dart';

/// B-02：零延迟贴底滚动控制器（端口 kelivo `applyContentDimensions` 思路）。
///
/// 流式生成期间内容逐帧增长：默认实现要等 post-frame 再 jumpTo，
/// 会产生「旧位置渲染一帧再跳底」的闪烁。本控制器在**布局期**
/// （`applyContentDimensions`，paint 前）直接矫正像素到新底部，
/// 消灭 post-frame 一帧闪烁。
class AutoFollowScrollController extends ScrollController {
  AutoFollowScrollController({super.initialScrollOffset});

  /// 贴底跟随开关：流式生成中且用户停在底部时置 true。
  /// 置 true 后每次内容增长都会在布局期自动矫正像素；
  /// 用户上滑离开底部时应置 false（由列表组件在滚动监听中维护）。
  bool stickToBottom = false;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return AutoFollowScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      stickToBottom: () => stickToBottom,
    );
  }
}

/// 布局期贴底位置：内容变长且贴底模式激活时，在
/// [applyContentDimensions]（paint 前）内 `correctPixels` 到底部。
class AutoFollowScrollPosition extends ScrollPositionWithSingleContext {
  AutoFollowScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    required bool Function() stickToBottom,
  }) : _stickToBottom = stickToBottom;

  final bool Function() _stickToBottom;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    final prevMax = hasContentDimensions ? this.maxScrollExtent : 0.0;
    final applied = super.applyContentDimensions(minScrollExtent, maxScrollExtent);
    if (_stickToBottom() && maxScrollExtent > prevMax) {
      // 布局期矫正像素：paint 前完成，无闪烁；
      // correctPixels 不触发通知，但矫正后像素即等于新底部，
      // 贴底判定（pixels >= max - tolerance）保持成立。
      correctPixels(maxScrollExtent);
    }
    return applied;
  }
}
