import 'nona_app_database.dart';

/// Web 平台：drift 数据库暂不可用（WasmDatabase 接入前），返回 null，
/// 服务层走既有 SharedPreferences / 文件回退链（与旧 NonaDatabase 一致）。
Future<NonaAppDatabase?> openNonaDatabase({bool forceMemory = false}) async =>
    null;

/// Web 端无单例可重置。
void resetNonaDatabaseForTest() {}
