/// 回车发送键位的判定逻辑（纯函数，便于单元测试）。
///
/// - [sendOnEnter] 为 true（PC 默认）：裸 Enter 发送，Shift+Enter 换行；
/// - [sendOnEnter] 为 false（移动端默认）：Enter 换行，Ctrl+Enter 发送。
/// [plainEnter] 表示未按下任何修饰键（Shift / Ctrl / Alt）。
class EnterSendLogic {
  /// 是否应触发发送。
  ///
  /// 规则：`sendOnEnter ? plainEnter : controlPressed`，
  /// 即开启时裸回车发送；关闭时仅 Ctrl+Enter 发送。
  static bool shouldSend({
    required bool sendOnEnter,
    required bool plainEnter,
    required bool controlPressed,
  }) {
    return sendOnEnter ? plainEnter : controlPressed;
  }
}
