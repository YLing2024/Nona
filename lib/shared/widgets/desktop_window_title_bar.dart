import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// A-03：Windows 无边框窗口自绘标题栏。
///
/// 中部 [DragToMoveArea] 拖拽移动；右侧最小化/最大化/关闭按钮
/// （bitsdojo WindowCaptionButton 等价物，纯 Flutter 实现）。
/// 仅 Windows 无边框模式显示；全屏/最大化时隐藏（系统按钮由标题栏接管）。
class DesktopWindowTitleBar extends StatefulWidget {
  final Widget? leading;
  final Widget? title;

  const DesktopWindowTitleBar({super.key, this.leading, this.title});

  @override
  State<DesktopWindowTitleBar> createState() => _DesktopWindowTitleBarState();
}

class _DesktopWindowTitleBarState extends State<DesktopWindowTitleBar> {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    _syncState();
  }

  Future<void> _syncState() async {
    try {
      final max = await windowManager.isMaximized();
      if (mounted && max != _maximized) {
        setState(() => _maximized = max);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // 仅 Windows 无边框模式渲染
    if (defaultTargetPlatform != TargetPlatform.windows) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const SizedBox(width: 8),
          if (widget.leading != null) widget.leading!,
          Expanded(
            child: DragToMoveArea(
              child: SizedBox(
                height: 40,
                child: Center(
                  child: widget.title ??
                      Text(
                        'Nona',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                ),
              ),
            ),
          ),
          if (widget.leading == null) const Spacer(),
          _CaptionButton(
            icon: Icons.remove_rounded,
            tooltip: 'Minimize',
            onTap: () async {
              await windowManager.minimize();
              await _syncState();
            },
          ),
          _CaptionButton(
            icon: _maximized
                ? Icons.filter_none_rounded
                : Icons.crop_square_rounded,
            tooltip: _maximized ? 'Restore' : 'Maximize',
            onTap: () async {
              if (_maximized) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
              await _syncState();
            },
          ),
          _CaptionButton(
            icon: Icons.close_rounded,
            tooltip: 'Close',
            hoverColor: Colors.redAccent,
            onTap: () async {
              await windowManager.close();
            },
          ),
        ],
      ),
    );
  }
}

/// 标题栏窗口控制按钮（悬停高亮）。
class _CaptionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? hoverColor;

  const _CaptionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.hoverColor,
  });

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip,
          child: Container(
            width: 46,
            height: 40,
            color: _hover
                ? (widget.hoverColor ?? scheme.surfaceContainerHighest)
                : Colors.transparent,
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: 16,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
