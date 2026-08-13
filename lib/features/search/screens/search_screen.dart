import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/services/search_service.dart';
import '../../../core/utils/l10n_ext.dart';

/// 搜索结果点击后的跳转目标。
class SearchTarget {
  final String sessionId;
  final int messageIndex;

  const SearchTarget({required this.sessionId, required this.messageIndex});
}

/// 会话全文搜索页：跨全部会话搜索标题与消息内容。
///
/// [indexedSearch] 非空时使用底层索引异步搜索（SQLite bigram 索引，
/// 大数据量下远快于内存全量扫描）；为空时回退同步全量扫描 [sessions]。
/// 点击结果后通过 [Navigator.pop] 返回 [SearchTarget]，由调用方切换会话并定位。
class SearchScreen extends StatefulWidget {
  final List<ChatSession> sessions;

  /// 可选：底层索引搜索回调（会话服务提供）。
  final Future<List<MessageSearchHit>> Function(String query)? indexedSearch;

  const SearchScreen({
    super.key,
    required this.sessions,
    this.indexedSearch,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<MessageSearchHit> _results = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      final query = value.trim();
      if (query.isEmpty) {
        setState(() => _results = const []);
        return;
      }
      List<MessageSearchHit> hits;
      try {
        if (widget.indexedSearch != null) {
          hits = await widget.indexedSearch!(query);
        } else {
          hits = SearchService.search(widget.sessions, query);
        }
      } catch (_) {
        // 索引搜索异常（如数据库不可用）回退内存扫描，避免未捕获异步错误
        hits = SearchService.search(widget.sessions, query);
      }
      if (!mounted || _controller.text.trim() != query) return;
      setState(() => _results = hits);
    });
  }

  void _clear() {
    _controller.clear();
    setState(() => _results = const []);
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          onChanged: _onQueryChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchTitle,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: _clear,
                  ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: query.isEmpty
            ? _buildHint(context)
            : _results.isEmpty
                ? _buildNoResult(context, query)
                : _buildResults(context),
      ),
    );
  }

  Widget _buildHint(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.manage_search_rounded, size: 44, color: scheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            context.l10n.searchHint,
            style: TextStyle(fontSize: 13, color: scheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResult(BuildContext context, String query) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 44, color: scheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            context.l10n.searchNoResult(query),
            style: TextStyle(fontSize: 13, color: scheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = _controller.text.trim();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final hit = _results[index];
        final isUser = hit.message.role == 'user';
        return ListTile(
          onTap: () => Navigator.of(context).pop(
            SearchTarget(
              sessionId: hit.session.id,
              messageIndex: hit.messageIndex,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isUser
                  ? scheme.primary.withValues(alpha: 0.12)
                  : scheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              isUser ? Icons.person_outline : Icons.auto_awesome_rounded,
              size: 16,
              color: isUser ? scheme.primary : scheme.secondary,
            ),
          ),
          title: _HighlightText(
            spans: SearchService.highlight(hit.snippet(), q),
            style: const TextStyle(fontSize: 13.5, height: 1.5),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    hit.session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: scheme.outline),
                  ),
                ),
                if (SearchService.titleMatches(hit.session, q)) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.l10n.searchTitleHit,
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 关键词高亮文本（命中段高亮 + 加粗）。
class _HighlightText extends StatelessWidget {
  final List<SearchSpan> spans;
  final TextStyle? style;

  const _HighlightText({required this.spans, this.style});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          for (final span in spans)
            TextSpan(
              text: span.text,
              style: span.isMatch
                  ? (style ?? const TextStyle()).copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.45),
                    )
                  : style,
            ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
