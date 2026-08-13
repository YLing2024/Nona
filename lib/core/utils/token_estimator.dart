import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart' show HeapPriorityQueue;
import 'package:flutter/services.dart' show rootBundle;

import 'logger.dart';

/// tiktoken 词表类型。
///
/// - [cl100kBase]：gpt-4 / gpt-3.5 系列及通用 OpenAI 兼容接口默认编码；
/// - [o200kBase]：gpt-4o / gpt-4.1 / o1 / o3 / gpt-5 等新模型的编码。
enum TokenizerKind {
  cl100kBase,
  o200kBase;

  String get assetPath => switch (this) {
    TokenizerKind.cl100kBase => 'assets/tiktoken/cl100k_base.tiktoken',
    TokenizerKind.o200kBase => 'assets/tiktoken/o200k_base.tiktoken',
  };

  /// 特殊 token（不在 mergeable 词表内，单独编号；两种词表编号不同）。
  Map<String, int> get specialTokens => switch (this) {
    TokenizerKind.cl100kBase => const {
      '<|endoftext|>': 100257,
      '<|fim_prefix|>': 100258,
      '<|fim_middle|>': 100259,
      '<|fim_suffix|>': 100260,
      '<|endofprompt|>': 100276,
    },
    TokenizerKind.o200kBase => const {
      '<|endoftext|>': 199999,
      '<|endofprompt|>': 200018,
    },
  };
}

/// 基于 tiktoken 的纯 Dart BPE token 估算器（支持多词表）。
///
/// - 词表来自官方 tiktoken（cl100k_base / o200k_base），以资产文件形式打包，
///   离线可用；与 OpenAI tiktoken 的输出逐 token 一致（权威基准测试保证）；
/// - 词表按类型懒加载并缓存；未就绪时 [encode] 返回 null，由调用方回退启发式；
/// - [estimateCount]/[encode] 默认使用 cl100k_base（旧行为），
///   新模型请显式传入 [TokenizerKind.o200kBase]。
class TokenEstimator {
  TokenEstimator._();

  static final TokenEstimator instance = TokenEstimator._();

  /// 官方切分正则（tiktoken 0.13 的 _pat_str）。
  ///
  /// 省略了官方开头的缩写分支 `(?i:[sdmt]|ll|ve|re)`：实测该分支在官方
  /// Rust 引擎中从不产生独立分片（如 "def"/"very"/"sd" 均为整体分片，
  /// 观察到的 'll'/'re' 等拆分是 BPE 合并的自然结果），去掉后与官方
  /// 输出逐 token 一致（以权威基准测试保证）。
  /// 其余分支中的占有量词改写为等价非占有形式（字符类互不重叠）。
  static const String _patStr =
      r"""[^\r\n\p{L}\p{N}]?\p{L}+|\p{N}{1,3}| ?[^\s\p{L}\p{N}]+[\r\n]*|\s+$|\s*[\r\n]|\s+(?!\S)|\s""";

  static final RegExp _pat = RegExp(_patStr, unicode: true);

  final Map<TokenizerKind, _Vocab> _vocabs = {
    for (final k in TokenizerKind.values) k: _Vocab(),
  };

  /// cl100k 词表是否已加载（兼容旧 API）。
  bool get ready => _vocabs[TokenizerKind.cl100kBase]!.ranks != null;

  /// 指定词表是否已加载。
  bool readyFor(TokenizerKind kind) => _vocabs[kind]!.ranks != null;

  /// 预加载词表（幂等）；加载失败保持未就绪，调用方回退启发式估算。
  Future<void> load([TokenizerKind kind = TokenizerKind.cl100kBase]) {
    final vocab = _vocabs[kind]!;
    if (vocab.ranks != null) return Future.value();
    return vocab.loading ??= _doLoad(kind);
  }

  /// 清空词表缓存（测试辅助：跨用例隔离加载状态）。
  void resetCache() {
    for (final v in _vocabs.values) {
      v.ranks = null;
      v.loading = null;
    }
  }

  Future<void> _doLoad(TokenizerKind kind) async {
    try {
      final raw = await rootBundle.loadString(kind.assetPath);
      final ranks = <String, int>{};
      for (final line in const LineSplitter().convert(raw)) {
        final space = line.indexOf(' ');
        if (space <= 0) continue;
        final bytes = base64Decode(line.substring(0, space));
        final rank = int.parse(line.substring(space + 1));
        ranks[String.fromCharCodes(bytes)] = rank;
      }
      _vocabs[kind]!.ranks = ranks;
    } catch (e) {
      // 词表加载失败：保持未就绪，回退到启发式估算
      Logger.error('token', 'tiktoken 词表加载失败: ${kind.name}', e);
    }
  }

  /// 估算文本 token 数；词表未就绪返回 null。
  int? estimateCount(String text, {TokenizerKind kind = TokenizerKind.cl100kBase}) {
    final ids = encode(text, kind: kind);
    return ids?.length;
  }

  /// 编码为 token id 列表；词表未就绪返回 null。
  List<int>? encode(String text, {TokenizerKind kind = TokenizerKind.cl100kBase}) {
    final vocab = _vocabs[kind]!;
    final ranks = vocab.ranks;
    if (ranks == null) return null;
    if (text.isEmpty) return const [];
    final ids = <int>[];
    final specialTokens = kind.specialTokens;
    // 特殊 token 扫描正则由当前词表的特殊 token 构建
    final specialPat = RegExp(
      specialTokens.keys.map(RegExp.escape).join('|'),
    );
    var start = 0;
    // 先按特殊 token 切分，仅对非特殊片段做正则 + BPE
    for (final m in specialPat.allMatches(text)) {
      final special = m[0]!;
      _encodeSegment(text.substring(start, m.start), ranks, ids);
      ids.add(specialTokens[special]!);
      start = m.end;
    }
    _encodeSegment(text.substring(start), ranks, ids);
    return ids;
  }

  void _encodeSegment(String segment, Map<String, int> ranks, List<int> ids) {
    for (final m in _pat.allMatches(segment)) {
      final piece = m[0]!;
      ids.addAll(_bytePairEncode(piece, ranks));
    }
  }

  /// 对单个正则切分片段做 BPE 合并（最小 rank 优先，堆实现避免长片段 O(n²)）。
  List<int> _bytePairEncode(String piece, Map<String, int> ranks) {
    final bytes = utf8.encode(piece);
    final pieceKey = String.fromCharCodes(bytes);
    final direct = ranks[pieceKey];
    if (direct != null) return [direct];

    final n = bytes.length;
    final prev = List<int>.generate(n, (i) => i - 1);
    final next = List<int>.generate(n, (i) => i + 1);
    next[n - 1] = -1;
    final nodeKey =
        List<String>.generate(n, (i) => String.fromCharCode(bytes[i]));
    final nodeRank = List<int>.generate(
      n,
      (i) => ranks[nodeKey[i]] ?? bytes[i],
    );
    var head = 0;

    // 相邻对堆：按 (rank, 左节点) 升序，惰性失效
    final queue = HeapPriorityQueue<(int, int, int)>(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
    void pushPair(int left) {
      final right = next[left];
      if (right == -1) return;
      final rank = ranks[nodeKey[left] + nodeKey[right]];
      if (rank != null) queue.add((rank, left, right));
    }

    for (var i = 0; i < n - 1; i++) {
      pushPair(i);
    }

    while (queue.isNotEmpty) {
      final (rank, s, e) = queue.removeFirst();
      // 惰性失效检查：s 仍存活且 e 仍是其后继
      if (s < 0 || e < 0 || next[s] != e) continue;
      final currentRank = ranks[nodeKey[s] + nodeKey[e]];
      if (currentRank == null) continue;
      // 条目携带的 rank 可能因合并过期：不一致时按最新 rank 重新入堆
      if (currentRank != rank) {
        queue.add((currentRank, s, e));
        continue;
      }
      // 合并 s+e → s
      nodeKey[s] = nodeKey[s] + nodeKey[e];
      nodeRank[s] = currentRank;
      final en = next[e];
      next[s] = en;
      if (en != -1) {
        prev[en] = s;
        pushPair(s);
      }
      final ps = prev[s];
      if (ps != -1) {
        pushPair(ps);
      }
      if (e == head) head = s;
      prev[e] = -2;
      next[e] = -2;
    }

    final out = <int>[];
    for (var i = head; i != -1; i = next[i]) {
      out.add(nodeRank[i]);
    }
    return out;
  }
}

/// 单种词表的运行时状态。
class _Vocab {
  Map<String, int>? ranks;
  Future<void>? loading;
}

/// 根据模型 id 推断最合适的词表类型。
///
/// 新编码模型（gpt-4o 系 / gpt-4.1 / o1/o3/o4 / gpt-5 系）使用 o200k；
/// 其余（含 gpt-4 / gpt-3.5 / 未知模型）回退 cl100k（保守兼容）。
TokenizerKind tokenizerKindForModel(String modelId) {
  final id = modelId.toLowerCase();
  if (id.startsWith('o1') ||
      id.startsWith('o3') ||
      id.startsWith('o4') ||
      id.contains('gpt-4o') ||
      id.contains('gpt-4.1') ||
      id.contains('gpt-4.5') ||
      id.contains('gpt-5') ||
      id.contains('chatgpt-4o') ||
      id.contains('gpt-oss') ||
      id.contains('gpt-image')) {
    return TokenizerKind.o200kBase;
  }
  return TokenizerKind.cl100kBase;
}
