import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/services/search_service.dart';
import '../../../core/services/storage_io_io.dart'
    if (dart.library.js_interop) '../../../core/services/storage_io_stub.dart'
    as storage_io;
import '../../../core/utils/app_snackbar.dart';
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

  /// D-03：时间范围筛选（null = 全部）。
  DateTime? _since;

  /// D-03：服务商筛选（null = 全部）。
  String? _providerFilter;

  List<MessageSearchHit> get _filteredResults {
    final since = _since;
    if (since == null && _providerFilter == null) return _results;
    return [
      for (final h in _results)
        if ((since == null ||
                (h.message.sentAt ?? h.session.updatedAt)
                    .isAfter(since)) &&
            (_providerFilter == null ||
                h.message.providerName == _providerFilter ||
                h.session.providerId == _providerFilter))
          h,
    ];
  }

  /// D-03：结果中的服务商列表（筛选条用）。
  List<String> get _availableProviders {
    final set = <String>{
      for (final h in _results)
        if ((h.message.providerName ?? '').isNotEmpty)
          h.message.providerName!,
    };
    return set.toList()..sort();
  }

  /// D-03：导出当前筛选结果（Markdown）。
  Future<void> _exportResults() async {
    final hits = _filteredResults;
    if (hits.isEmpty) return;
    final sb = StringBuffer();
    sb.writeln('# Search Results: ${_controller.text.trim()}');
    sb.writeln();
    for (final h in hits) {
      final time = h.message.sentAt ?? h.session.updatedAt;
      sb.writeln(
        '## [${h.session.title}] ${time.toLocal()} '
        '(${h.message.role})',
      );
      sb.writeln();
      sb.writeln(h.message.content);
      sb.writeln();
    }
    final path = await storage_io.saveTextFile(
      suggestedName: 'search-results-${DateTime.now().millisecondsSinceEpoch}.md',
      data: sb.toString(),
      extension: 'md',
      mimeType: 'text/markdown',
    );
    if (!mounted) return;
    if (path != null) {
      showAppSnack(context, context.l10n.searchExported(''));
    }
  }

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
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              tooltip: l10n.searchExportResults,
              onPressed: _exportResults,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // D-03：筛选条（时间范围 + 服务商）
            if (query.isNotEmpty && _results.isNotEmpty) _buildFilters(l10n),
            Expanded(
              child: query.isEmpty
                  ? _buildHint(context)
                  : _filteredResults.isEmpty
                      ? _buildNoResult(context, query)
                      : _buildResults(context),
            ),
          ],
        ),
      ),
    );
  }

  /// D-03：筛选条。
  Widget _buildFilters(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final providers = _availableProviders;
    DateTime? rangeFor(int value) {
      final now = DateTime.now();
      return switch (value) {
        0 => DateTime(now.year, now.month, now.day),
        1 => now.subtract(const Duration(days: 7)),
        2 => now.subtract(const Duration(days: 30)),
        3 => DateTime(now.year - 1, now.month, now.day),
        _ => null,
      };
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _FilterChip(
            label: l10n.searchFilterAll,
            selected: _since == null,
            onSelected: () => setState(() => _since = null),
          ),
          for (final (value, label) in [
            (0, l10n.searchFilterToday),
            (1, l10n.searchFilterWeek),
            (2, l10n.searchFilterMonth),
            (3, l10n.searchFilterYear),
          ])
            _FilterChip(
              label: label,
              selected: _since == rangeFor(value),
              onSelected: () => setState(() => _since = rangeFor(value)),
            ),
          if (providers.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(width: 1, height: 18, color: scheme.outlineVariant),
            const SizedBox(width: 8),
            for (final p in providers)
              _FilterChip(
                label: p,
                selected: _providerFilter == p,
                onSelected: () => setState(
                  () => _providerFilter = _providerFilter == p ? null : p,
                ),
              ),
          ],
        ],
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

/// D-03：筛选小胶囊。
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
