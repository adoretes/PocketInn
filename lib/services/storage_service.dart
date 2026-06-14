import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 基础储存服务
///
/// 提供统一的储存接口，封装 SharedPreferences 和文件操作
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  late final SharedPreferences _prefs;
  late final String _dataDir;

  bool _initialized = false;

  /// 初始化储存服务
  ///
  /// 必须在使用前调用此方法
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    final appDir = await getApplicationSupportDirectory();
    _dataDir = '${appDir.path}/pocket_inn_data';

    // 确保数据目录存在
    final dir = Directory(_dataDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _initialized = true;
  }

  // ==================== SharedPreferences 操作 ====================

  /// 获取字符串
  String? getString(String key) {
    _checkInitialized();
    return _prefs.getString(key);
  }

  /// 设置字符串
  Future<void> setString(String key, String value) async {
    _checkInitialized();
    await _prefs.setString(key, value);
  }

  /// 获取整数
  int? getInt(String key) {
    _checkInitialized();
    return _prefs.getInt(key);
  }

  /// 设置整数
  Future<void> setInt(String key, int value) async {
    _checkInitialized();
    await _prefs.setInt(key, value);
  }

  /// 获取浮点数
  double? getDouble(String key) {
    _checkInitialized();
    return _prefs.getDouble(key);
  }

  /// 设置浮点数
  Future<void> setDouble(String key, double value) async {
    _checkInitialized();
    await _prefs.setDouble(key, value);
  }

  /// 获取布尔值
  bool? getBool(String key) {
    _checkInitialized();
    return _prefs.getBool(key);
  }

  /// 设置布尔值
  Future<void> setBool(String key, bool value) async {
    _checkInitialized();
    await _prefs.setBool(key, value);
  }

  /// 删除键
  Future<void> remove(String key) async {
    _checkInitialized();
    await _prefs.remove(key);
  }

  /// 清空 SharedPreferences 和应用数据目录
  Future<void> clearAllData() async {
    _checkInitialized();

    await _prefs.clear();

    final dir = Directory(_dataDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  }

  Map<String, dynamic> exportPreferences() {
    _checkInitialized();

    final data = <String, dynamic>{};
    for (final key in _prefs.getKeys()) {
      data[key] = _prefs.get(key);
    }
    return data;
  }

  Future<void> importPreferences(Map<String, dynamic> data) async {
    _checkInitialized();

    await _prefs.clear();
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is String) {
        await _prefs.setString(entry.key, value);
      } else if (value is int) {
        await _prefs.setInt(entry.key, value);
      } else if (value is double) {
        await _prefs.setDouble(entry.key, value);
      } else if (value is bool) {
        await _prefs.setBool(entry.key, value);
      } else if (value is List) {
        await _prefs.setStringList(
          entry.key,
          value.map((item) => item.toString()).toList(growable: false),
        );
      }
    }
  }

  // ==================== JSON 文件操作 ====================

  /// 读取 JSON 文件
  ///
  /// [filename] 文件名（不含路径）
  /// 返回文件内容字符串，如果文件不存在则返回 null
  Future<String?> readJsonFile(String filename) async {
    _checkInitialized();

    final file = File('$_dataDir/$filename');
    if (!await file.exists()) {
      return null;
    }

    return await file.readAsString();
  }

  /// 写入 JSON 文件
  ///
  /// [filename] 文件名（不含路径）
  /// [content] 文件内容字符串
  Future<void> writeJsonFile(String filename, String content) async {
    _checkInitialized();

    final file = File('$_dataDir/$filename');
    await file.writeAsString(content);
  }

  /// 读取 JSON 文件并解析为 Map
  Future<Map<String, dynamic>?> readJsonMap(String filename) async {
    final content = await readJsonFile(filename);
    if (content == null) return null;

    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 写入 Map 到 JSON 文件
  Future<void> writeJsonMap(String filename, Map<String, dynamic> data) async {
    final content = const JsonEncoder.withIndent('  ').convert(data);
    await writeJsonFile(filename, content);
  }

  /// 删除 JSON 文件
  Future<void> deleteJsonFile(String filename) async {
    _checkInitialized();

    final file = File('$_dataDir/$filename');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 检查 JSON 文件是否存在
  Future<bool> jsonFileExists(String filename) async {
    _checkInitialized();

    final file = File('$_dataDir/$filename');
    return await file.exists();
  }

  // ==================== 辅助方法 ====================

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'StorageService 未初始化，请先调用 StorageService.instance.initialize()',
      );
    }
  }

  /// 获取数据目录路径
  String get dataDir => _dataDir;
}
