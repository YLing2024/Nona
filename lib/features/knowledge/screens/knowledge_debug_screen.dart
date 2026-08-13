import 'package:flutter/material.dart';

import '../../../core/database/nona_db_factory.dart' show openNonaDatabase;
import '../../../core/services/knowledge/kb_retriever.dart';
import '../../../core/services/knowledge_base_service.dart';
import '../../../core/services/search_service.dart' show bigrams;
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/load_failed_banner.dart';

/// D-04：知识库检索测试台——查询 + 参数滑杆 + 命中列表（分数/来源/双路贡献）。
class KnowledgeDebugScreen extends StatefulWidget {
  const KnowledgeDebugScreen({super.key});

  @override
  State<KnowledgeDebugScreen> createState() => _KnowledgeDebugScreenState();
}

class _KnowledgeDebugScreenState extends State<KnowledgeDebugScreen> {
  final _queryController = TextEditingController();
  int _topK = 8;
  double _similarity = 0.3;
  bool _searching = false;
  List<RetrievalDebugHit> _hits = [];
  String? _error;
  final KnowledgeBaseService _kb = KnowledgeBaseService();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final db = await openNonaDatabase();
      if (db == null) return;
      var queryVector = const <double>[];
      try {
        await _kb.loadEmbeddingIfNeeded();
        queryVector = await _kb.embedQueryIfPossible(query);
      } catch (_) {}
      if (!mounted) return;
      final hits = await KbRetriever(
        db: db,
        queryVector: queryVector,
      ).searchDebug(
        queryBigrams: bigrams(query.toLowerCase()).toSet(),
        topK: _topK,
        similarityThreshold: _similarity,
      );
      if (!mounted) return;
      setState(() => _hits = hits);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.kbDebugTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _queryController,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      labelText: l10n.kbDebugQuery,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded),
                        onPressed: _searching ? null : _search,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.kbDebugTopK}: $_topK',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Slider(
                              value: _topK.toDouble(),
                              min: 1,
                              max: 20,
                              divisions: 19,
                              label: '$_topK',
                              onChanged: (v) =>
                                  setState(() => _topK = v.round()),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.kbDebugSimilarity}: '
                              '${_similarity.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            Slider(
                              value: _similarity,
                              min: 0,
                              max: 0.9,
                              divisions: 18,
                              label: _similarity.toStringAsFixed(2),
                              onChanged: (v) =>
                                  setState(() => _similarity = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_error != null)
                    LoadFailedBanner(onRetry: _search),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _hits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.travel_explore_rounded,
                            size: 40,
                            color: scheme.outlineVariant,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _searching
                                ? l10n.searchServiceTesting
                                : l10n.kbDebugNoHits,
                            style: TextStyle(color: scheme.outline),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _hits.length,
                      itemBuilder: (context, index) =>
                          _HitCard(hit: _hits[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HitCard extends StatelessWidget {
  final RetrievalDebugHit hit;

  const _HitCard({required this.hit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chunk = hit.chunk;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.l10n.kbDebugRank(''),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.kbDebugSource(chunk.docName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  context.l10n.kbDebugScore(hit.score.toStringAsFixed(3)),
                  style: TextStyle(fontSize: 11, color: scheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 双路贡献
            Wrap(
              spacing: 6,
              children: [
                _RouteTag(
                  label: context.l10n.kbDebugBigramHits(
                    hit.fromKeyword ? '1' : '0',
                  ),
                  color: hit.fromKeyword ? scheme.primary : scheme.outlineVariant,
                ),
                _RouteTag(
                  label: context.l10n.kbDebugVectorHits(
                    hit.fromVector ? '1' : '0',
                  ),
                  color: hit.fromVector ? scheme.tertiary : scheme.outlineVariant,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              chunk.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteTag extends StatelessWidget {
  final String label;
  final Color color;

  const _RouteTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, color: color),
      ),
    );
  }
}
