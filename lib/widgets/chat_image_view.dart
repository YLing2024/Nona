import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';

/// 渲染一条 [ChatImage]：Data URL 用内存解码，http(s) 用网络加载。
class ChatImageView extends StatelessWidget {
  final ChatImage image;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ChatImageView({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (image.isDataUrl) {
      return Image.memory(
        _decodeDataUrl(image.url),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _broken(context),
      );
    }
    if (image.isNetwork) {
      return Image.network(
        image.url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            color: scheme.surfaceContainerHighest,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _broken(context),
      );
    }
    return _broken(context);
  }

  Widget _broken(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: scheme.outline),
    );
  }

  static Uint8List _decodeDataUrl(String url) {
    final comma = url.indexOf(',');
    if (comma <= 0) return Uint8List(0);
    final base64 = url.substring(comma + 1);
    try {
      return base64Decode(base64);
    } catch (_) {
      return Uint8List(0);
    }
  }
}
