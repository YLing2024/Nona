import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/focus_utils.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/utils/enter_send.dart';

/// 输入框：多行 TextField + Enter 发送拦截 + 剪贴板图片粘贴识别。
///
/// 粘贴到 Data URL / 图片链接时作为附件回调 [onAddImageUrl]，
/// 并清除误粘贴进输入框的 base64 文本。
class ComposerInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool sendOnEnter;
  final VoidCallback onSend;

  /// 通过剪贴板粘贴/外部链接添加单张图片。
  final void Function(ChatImage image) onAddImageUrl;

  /// G-04：输入框首字符为 `/` 时触发快捷短语菜单。
  final VoidCallback? onQuickPhraseTriggered;

  const ComposerInputField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.sendOnEnter,
    required this.onSend,
    required this.onAddImageUrl,
    this.onQuickPhraseTriggered,
  });

  @override
  State<ComposerInputField> createState() => _ComposerInputFieldState();
}

class _ComposerInputFieldState extends State<ComposerInputField> {
  /// 检测 Ctrl+V / Cmd+V：若剪贴板内容是图片（Data URL 或图片链接）则作为附件添加，
  /// 并清除误粘贴进输入框的 base64 文本；普通文本粘贴不受影响。
  KeyEventResult _onPasteKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.keyV) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (!keyboard.isControlPressed && !keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    _handleClipboardImage();
    return KeyEventResult.ignored;
  }

  Future<void> _handleClipboardImage() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;
    final ChatImage? image;
    if (_isImageDataUrl(text)) {
      // 超过 8MB 的 base64 图片拒绝（内存保护，与文件选择逻辑一致）
      if (text.length > 8 * 1024 * 1024 * 4 ~/ 3 + 64) return;
      image = ChatImage.fromDataUrl(text);
    } else if (_isImageUrl(text)) {
      image = ChatImage(url: text, mimeType: 'image/*');
    } else {
      image = null;
    }
    if (image == null || !mounted) return;
    widget.onAddImageUrl(image);
    // 粘贴进来的 base64 文本已作为附件，从输入框清除
    if (widget.controller.text.contains(text)) {
      final next = widget.controller.text.replaceFirst(text, '').trim();
      widget.controller.text = next;
    }
  }

  static bool _isImageDataUrl(String text) =>
      text.startsWith('data:image/') && text.contains(',');

  static bool _isImageUrl(String text) {
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    final path = uri.path.toLowerCase();
    return path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp') ||
        path.endsWith('.bmp');
  }

  /// G-04：输入「/」时触发快捷短语菜单（菜单显示期间不重复触发）。
  bool _quickMenuOpen = false;

  void _onChanged(String text) {
    if (text == '/' && !_quickMenuOpen) {
      _quickMenuOpen = true;
      widget.onQuickPhraseTriggered?.call();
    } else if (text != '/') {
      // 输入变化（选中短语/继续输入）后复位，允许再次触发
      _quickMenuOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Focus(
      onKeyEvent: _onPasteKey,
      child: TextField(
        controller: widget.controller,
        enabled: widget.enabled,
        minLines: 1,
        maxLines: 6,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        onTapOutside: unfocusOnTap,
        onChanged: _onChanged,
        style: const TextStyle(fontSize: 14.5, height: 1.5),
        inputFormatters: [
          _EnterSendFormatter(
            sendOnEnter: widget.sendOnEnter,
            onEnterSend: () => widget.onSend(),
          ),
        ],
        decoration: InputDecoration(
          hintText: widget.sendOnEnter
              ? context.l10n.chatInputHintEnterSend
              : context.l10n.chatInputHintEnterNewline,
          hintStyle: TextStyle(color: scheme.outline, fontSize: 14),
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 10,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

/// 发送键行为拦截：
/// [sendOnEnter] 为 true 时，裸 Enter 触发发送（Shift+Enter 换行）；
/// 为 false 时，Enter 正常换行，Ctrl+Enter 触发发送。
class _EnterSendFormatter extends TextInputFormatter {
  final bool sendOnEnter;
  final VoidCallback onEnterSend;

  _EnterSendFormatter({
    required this.sendOnEnter,
    required this.onEnterSend,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final inserted = newValue.text != oldValue.text &&
        newValue.text.length == oldValue.text.length + 1 &&
        newValue.text.endsWith('\n');
    if (inserted) {
      // 输入法组合态（拼音/假名候选确认等）下不应触发发送：
      // 组合态确认会被部分 IME 以「文本提交 + \n 插入」的形式送达，
      // 与真实 Enter 无法仅凭文本区分。编辑前或编辑后处于组合态
      // 都视为组合流程（候选确认），跳过发送。
      final composing = newValue.composing;
      if (composing.isValid || oldValue.composing.isValid) {
        return newValue;
      }
      final keyboard = HardwareKeyboard.instance;
      final plainEnter = !keyboard.isShiftPressed &&
          !keyboard.isControlPressed &&
          !keyboard.isAltPressed;
      final shouldSend = EnterSendLogic.shouldSend(
        sendOnEnter: sendOnEnter,
        plainEnter: plainEnter,
        controlPressed: keyboard.isControlPressed,
      );
      if (shouldSend) {
        // 帧后触发发送，避免在 formatEditUpdate 中做副作用
        WidgetsBinding.instance.addPostFrameCallback((_) => onEnterSend());
        return oldValue;
      }
    }
    return newValue;
  }
}
