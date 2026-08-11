import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// 单模型价格（美元 / 每百万 token）。
class ModelPrice {
  final double promptPerM;
  final double completionPerM;

  const ModelPrice({required this.promptPerM, required this.completionPerM});
}

/// 模型价格服务（F3-2）：离线价格表 + 用户自定义价格。
///
/// - 内置价格表 `assets/model_prices.json`（60+ 模型，$/1M in/out）；
/// - 用户可在 prefs 手动添加自定义模型价格（覆盖内置）；
/// - 匹配用最长前缀（复用 model_resolver 的匹配思路），
///   未知模型返回 null（不计成本或按 0 计）。
class PriceService {
  static const String _kCustomPrices = 'custom_model_prices';
  static const String _kAssetPath = 'assets/model_prices.json';

  Map<String, ModelPrice> _builtin = {};
  Map<String, ModelPrice> _custom = {};
  bool _loaded = false;
  Future<void>? _loading;

  static final PriceService instance = PriceService._();

  PriceService._();

  /// 加载价格表（内置 + 自定义，幂等）。
  Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= _loadOnce();
  }

  Future<void> _loadOnce() async {
    _custom = await _loadCustom();
    try {
      final raw = await rootBundle.loadString(_kAssetPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _builtin = data.map(
        (k, v) => MapEntry(
          k.toLowerCase(),
          ModelPrice(
            promptPerM: ((v as Map<String, dynamic>)['in'] as num).toDouble(),
            completionPerM: (v['out'] as num).toDouble(),
          ),
        ),
      );
    } catch (_) {
      _builtin = {};
    }
    _loaded = true;
  }

  Future<Map<String, ModelPrice>> _loadCustom() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCustomPrices);
    if (raw == null || raw.isEmpty) return {};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return data.map(
        (k, v) => MapEntry(
          k.toLowerCase(),
          ModelPrice(
            promptPerM: ((v as Map<String, dynamic>)['in'] as num).toDouble(),
            completionPerM: (v['out'] as num).toDouble(),
          ),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  /// 按模型 id 查价格：精确 → 自定义最长前缀 → 内置最长前缀。
  ///
  /// 未知模型返回 null。
  Future<ModelPrice?> priceFor(String modelId) async {
    await load();
    final id = modelId.toLowerCase();
    // 精确匹配优先
    final exact = _custom[id] ?? _builtin[id];
    if (exact != null) return exact;
    // 前缀匹配：按 key 长度降序
    ModelPrice? prefixMatch(Map<String, ModelPrice> table) {
      final keys = table.keys
          .where((k) => k.isNotEmpty && id.startsWith(k))
          .toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      return keys.isEmpty ? null : table[keys.first];
    }

    return prefixMatch(_custom) ?? prefixMatch(_builtin);
  }

  /// 估算一次调用的成本（美元）。
  ///
  /// [inTokens]/[outTokens] 为 prompt/completion token 数；
  /// 未知模型返回 0。
  Future<double> costFor(
    String modelId,
    int inTokens,
    int outTokens,
  ) async {
    if (inTokens <= 0 && outTokens <= 0) return 0;
    final price = await priceFor(modelId);
    if (price == null) return 0;
    return inTokens / 1000000 * price.promptPerM +
        outTokens / 1000000 * price.completionPerM;
  }

  /// 设置自定义价格（modelId 为空则删除）。
  Future<void> setCustomPrice(String modelId, ModelPrice? price) async {
    await load();
    final prefs = await SharedPreferences.getInstance();
    if (price == null) {
      _custom.remove(modelId.toLowerCase());
    } else {
      _custom[modelId.toLowerCase()] = price;
    }
    await prefs.setString(
      _kCustomPrices,
      jsonEncode(_custom.map(
        (k, v) => MapEntry(k, {'in': v.promptPerM, 'out': v.completionPerM}),
      )),
    );
  }

  /// 用户自定义价格列表。
  Future<Map<String, ModelPrice>> customPrices() async {
    await load();
    return Map.unmodifiable(_custom);
  }
}
