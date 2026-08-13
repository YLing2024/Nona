import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models/agent.dart';
import '../models/chat_provider.dart';
import '../models/chat_session.dart';

export 'export/backup_archive.dart' show BackupImportResult;

import 'export/backup_archive.dart';
import 'export/import_service.dart';
import 'export/pdf_exporter.dart';
import 'export/session_exporter.dart';

/// 会话导出 / 导入服务门面。
///
/// 实现按域拆分并委托：
/// - [SessionExporter]：单会话 Markdown / HTML / JSON 导出与剪贴板
/// - [PdfExporter]：单会话 PDF 导出
/// - [BackupArchive]：全量 ZIP 备份打包 / 解包
/// - [ImportService]：导入嗅探分发（Nona / Chatbox / Cherry Studio）
class ExportService {
  /// 将会话渲染为 Markdown 文本（含系统提示词与思考内容说明）。
  static String sessionToMarkdown(ChatSession session) =>
      SessionExporter.sessionToMarkdown(session);

  /// 导出为 .md 文件（桌面端弹出保存对话框）。
  ///
  /// [messageIndices] 非空时只导出指定消息（B-01 多选导出）。
  static Future<String?> exportToFile(
    ChatSession session, {
    Set<int>? messageIndices,
  }) =>
      SessionExporter.exportToFile(session, messageIndices: messageIndices);

  /// 渲染为自包含 HTML 文件内容（内嵌样式；代码块 pre 保留格式；思考内容折叠）。
  static String sessionToHtml(ChatSession session) =>
      SessionExporter.sessionToHtml(session);

  /// 导出为 HTML 文件（桌面端弹出保存对话框）。
  static Future<String?> exportHtmlToFile(ChatSession session) =>
      SessionExporter.exportHtmlToFile(session);

  /// 导出为 PDF 文件（桌面端弹出保存对话框 / 移动端回退写入目录）。
  static Future<String?> exportPdfToFile(ChatSession session) =>
      PdfExporter.exportPdfToFile(session);

  /// 构建会话 PDF 字节（内置 Noto Sans SC 子集字体，中文可正确渲染）。
  static Future<Uint8List> buildSessionPdf(ChatSession session) =>
      PdfExporter.buildSessionPdf(session);

  /// 导出为 JSON 文件（可被 [importFromFile] 恢复）。
  static Future<String?> exportJsonToFile(ChatSession session) =>
      SessionExporter.exportJsonToFile(session);

  /// G-03：导出 JSONL（OpenAI fine-tune 格式）。
  static String sessionToJsonl(ChatSession session) =>
      SessionExporter.sessionToJsonl(session);

  static Future<String?> exportJsonlToFile(ChatSession session) =>
      SessionExporter.exportJsonlToFile(session);

  /// 从 JSON 文件恢复会话；解析失败返回 null。
  static Future<ChatSession?> importFromFile() =>
      ImportService.importFromFile();

  /// 生成全部数据的 ZIP 备份字节（不落盘）。
  static Uint8List buildAllZipBytes({
    required List<ChatSession> sessions,
    List<ChatProvider> providers = const [],
    List<Agent> agents = const [],
  }) =>
      BackupArchive.buildAllZipBytes(
        sessions: sessions,
        providers: providers,
        agents: agents,
      );

  /// 导出全部数据为 ZIP 备份（manifest + 会话 + 服务商 + Agent）。
  ///
  /// 结构：
  /// ```
  /// manifest.json        # {app, format: "nona-backup", version, exportedAt, 数量}
  /// providers.json       # 服务商配置（可选）
  /// agents.json          # Agent 配置（可选）
  /// sessions/<id>.json   # 每个会话独立文件
  /// ```
  static Future<String?> exportAllZipToFile({
    required List<ChatSession> sessions,
    List<ChatProvider> providers = const [],
    List<Agent> agents = const [],
  }) =>
      BackupArchive.exportAllZipToFile(
        sessions: sessions,
        providers: providers,
        agents: agents,
      );

  /// 兼容旧版：导出全部会话为 JSON 备份文件。
  static Future<String?> exportAllToFile(List<ChatSession> sessions) =>
      BackupArchive.exportAllToFile(sessions);

  /// 从文件导入：自动识别 ZIP 备份 / Nona JSON / Chatbox / Cherry Studio 格式。
  ///
  /// 返回 [BackupImportResult]；无法解析时返回 null。
  static Future<BackupImportResult?> importAllFromFile() =>
      ImportService.importAllFromFile();

  /// 解析 ZIP 备份字节。
  static BackupImportResult? importFromZipBytes(List<int> bytes) =>
      BackupArchive.importFromZipBytes(bytes);

  /// 解析 JSON 备份/导出：Nona（新版/旧版）→ Chatbox → Cherry Studio。
  static BackupImportResult? importFromJsonData(Object? data) =>
      ImportService.importFromJsonData(data);

  /// 将会话复制为 Markdown 到剪贴板。
  static Future<void> copyAsMarkdown(ChatSession session) =>
      SessionExporter.copyAsMarkdown(session);
}
