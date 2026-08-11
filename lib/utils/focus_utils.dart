import 'package:flutter/widgets.dart';

/// 点击外部收起键盘的通用回调（TextField.onTapOutside 等）。
///
/// 用法：`onTapOutside: unfocusOnTap`
void unfocusOnTap(PointerDownEvent _) {
  FocusManager.instance.primaryFocus?.unfocus();
}
