import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// B-07/G-03：消息导出图片工具。
///
/// [captureWidgetPng]：单 widget 截图（RepaintBoundary）。
/// [captureLongListPng]：多段截图纵向拼接（逐段截取，规避单帧渲染上限）。
class CaptureExport {
  CaptureExport._();

  /// 截取单个 [GlobalKey] 对应的 RepaintBoundary 为 PNG。
  static Future<Uint8List> captureWidgetPng(GlobalKey key) async {
    final boundary = key.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('RepaintBoundary not found for key');
    }
    final image = await boundary.toImage(pixelRatio: 2.0);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('PNG encode failed');
      }
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// 截取多个 RepaintBoundary 并纵向拼接为一张长图。
  ///
  /// [segmentPx] 为每段的逻辑高度上限（渲染时按段切分，避免超大图像）。
  static Future<Uint8List> captureLongListPng(
    List<GlobalKey> keys, {
    double segmentPx = 4000,
  }) async {
    final segments = <ui.Image>[];
    try {
      for (final key in keys) {
        final boundary = key.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) continue;
        final raw = await boundary.toImage(pixelRatio: 2.0);
        final pixelSeg = (segmentPx * 2.0).round();
        if (raw.height <= pixelSeg) {
          segments.add(raw);
        } else {
          // 超出渲染上限：用 canvas 裁切成多段
          for (var off = 0; off < raw.height; off += pixelSeg) {
            final h = (raw.height - off).clamp(0, pixelSeg);
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);
            canvas.drawImageRect(
              raw,
              Rect.fromLTWH(0, off.toDouble(), raw.width.toDouble(), h.toDouble()),
              Rect.fromLTWH(0, 0, raw.width.toDouble(), h.toDouble()),
              Paint(),
            );
            final picture = recorder.endRecording();
            final cropped = await picture.toImage(raw.width, h);
            segments.add(cropped);
            picture.dispose();
          }
          raw.dispose();
        }
      }
      if (segments.isEmpty) {
        throw StateError('No boundaries captured');
      }
      // 拼接
      final totalH = segments.fold<int>(0, (sum, img) => sum + img.height);
      final width = segments.map((img) => img.width).reduce(
            (a, b) => a > b ? a : b,
          );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      var dy = 0.0;
      for (final img in segments) {
        canvas.drawImage(
          img,
          Offset((width - img.width) / 2, dy),
          Paint(),
        );
        dy += img.height.toDouble();
      }
      final picture = recorder.endRecording();
      final stitched = await picture.toImage(width, totalH);
      picture.dispose();
      try {
        final data = await stitched.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('PNG encode failed');
        return data.buffer.asUint8List();
      } finally {
        stitched.dispose();
      }
    } finally {
      for (final img in segments) {
        img.dispose();
      }
    }
  }
}
