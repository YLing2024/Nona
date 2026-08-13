/// 引用标签（B-03：来源面板的 tag 横向列表）。
class CitationTag {
  final String text;

  const CitationTag(this.text);

  factory CitationTag.fromJson(dynamic json) => CitationTag(
    json is Map<String, dynamic>
        ? (json['text'] as String? ?? '')
        : json.toString(),
  );

  Map<String, dynamic> toJson() => {'text': text};
}

/// 引用出处（B-03：搜索结果/知识库来源，随消息落库 citations_json）。
///
/// 与 kelivo `CitationSourceItem` 对齐：index/title/url/text/sourceName/
/// publishedText/tags 全字段，`fromJson` 兼容多键名。
class CitationSource {
  /// 引用编号（正文 `[n]` 标记）。
  final int index;

  final String title;
  final String url;

  /// 命中片段。
  final String? snippet;

  /// 来源名（搜索=引擎名；知识库=文档名）。
  final String? sourceName;

  /// 发布时间（原始字符串）。
  final String? publishedAt;

  final List<CitationTag> tags;

  const CitationSource({
    required this.index,
    required this.title,
    required this.url,
    this.snippet,
    this.sourceName,
    this.publishedAt,
    this.tags = const [],
  });

  factory CitationSource.fromJson(Map<String, dynamic> json) {
    String str(String k1, [String? k2]) {
      final v = json[k1] ?? (k2 != null ? json[k2] : null);
      return v?.toString() ?? '';
    }

    return CitationSource(
      index: (json['index'] as num?)?.toInt() ?? 0,
      title: str('title', 'name'),
      url: str('url', 'link'),
      snippet: (json['snippet'] ?? json['text'] ?? json['summary'])?.toString(),
      sourceName: (json['sourceName'] ?? json['source'] ?? json['website'])
          ?.toString(),
      publishedAt:
          (json['publishedAt'] ?? json['publishedText'] ?? json['date'])
              ?.toString(),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map(CitationTag.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'title': title,
    'url': url,
    if (snippet != null) 'snippet': snippet,
    if (sourceName != null) 'sourceName': sourceName,
    if (publishedAt != null) 'publishedAt': publishedAt,
    'tags': tags.map((t) => t.toJson()).toList(),
  };
}
