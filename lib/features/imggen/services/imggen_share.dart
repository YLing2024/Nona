import 'package:flutter/foundation.dart';

import '../../../core/models/chat_message.dart' show ChatImage;

/// C-05：图片生成 → 聊天通道。
///
/// 设置页内的图片生成页与聊天首页无共享路由，经此静态通道把
/// 生成的图片投递给首页（首页初始化时订阅）。
class ImggenShare {
  ImggenShare._();

  static final ValueNotifier<ChatImage?> channel = ValueNotifier(null);

  /// 把生成的图片投递到当前聊天输入区（首页订阅后生效）。
  static void sendToChat(ChatImage image) {
    channel.value = image;
  }
}
