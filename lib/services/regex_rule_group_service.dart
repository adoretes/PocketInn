import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/regex_rule_group.dart';
import 'storage_service.dart';

class RegexRuleGroupSummary {
  const RegexRuleGroupSummary({
    required this.id,
    required this.name,
    required this.ruleCount,
    required this.enabledRuleCount,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int ruleCount;
  final int enabledRuleCount;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rule_count': ruleCount,
      'enabled_rule_count': enabledRuleCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RegexRuleGroupSummary.fromJson(Map<String, dynamic> json) {
    return RegexRuleGroupSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '未命名规则组',
      ruleCount: json['rule_count'] as int? ?? 0,
      enabledRuleCount: json['enabled_rule_count'] as int? ?? 0,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}

class RegexRuleGroupService {
  RegexRuleGroupService._();

  static final RegexRuleGroupService instance = RegexRuleGroupService._();

  static const String _indexFilename = 'regex_rule_groups_index.json';
  static const String _groupsDir = 'regex_rule_groups';
  static const int _dataVersion = 1;

  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  late final String _groupsPath;
  bool _initialized = false;
  List<RegexRuleGroup>? _cachedGroups;

  Future<void> initialize() async {
    if (_initialized) return;

    final dataDir = StorageService.instance.dataDir;
    _groupsPath = '$dataDir/$_groupsDir';
    final dir = Directory(_groupsPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _initialized = true;
  }

  /// 使内存缓存失效，下次 [loadAll] 重新读盘。
  void invalidateCache() {
    _cachedGroups = null;
  }

  Future<List<RegexRuleGroupSummary>> loadAllSummaries() async {
    _checkInitialized();

    final data = await StorageService.instance.readJsonMap(_indexFilename);
    if (data == null) {
      return [];
    }

    final version = data['version'] as int? ?? _dataVersion;
    if (version != _dataVersion) {
      return [];
    }

    final items = data['groups'] as List<dynamic>? ?? const [];
    return items
        .map(
          (item) => RegexRuleGroupSummary.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<RegexRuleGroup>> loadAll() async {
    _checkInitialized();

    final cached = _cachedGroups;
    if (cached != null) {
      return cached;
    }

    final summaries = await loadAllSummaries();
    final groups = <RegexRuleGroup>[];
    for (final summary in summaries) {
      final group = await loadById(summary.id);
      if (group != null) {
        groups.add(group);
      }
    }
    _cachedGroups = groups;
    return groups;
  }

  Future<RegexRuleGroup?> loadById(String id) async {
    _checkInitialized();

    final file = File('$_groupsPath/$id.json');
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      return RegexRuleGroup.fromStorageJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(RegexRuleGroup group) async {
    _checkInitialized();

    final normalized = group.copyWith(
      name: group.name.trim().isEmpty ? '未命名规则组' : group.name.trim(),
      updatedAt: DateTime.now(),
    );

    final file = File('$_groupsPath/${normalized.id}.json');
    final content = const JsonEncoder.withIndent(
      '  ',
    ).convert(normalized.toStorageJson());
    await file.writeAsString(content);

    final summaries = await loadAllSummaries();
    final summary = RegexRuleGroupSummary(
      id: normalized.id,
      name: normalized.name,
      ruleCount: normalized.rules.length,
      enabledRuleCount: normalized.enabledRuleCount,
      updatedAt: normalized.updatedAt,
    );
    final index = summaries.indexWhere((item) => item.id == normalized.id);
    if (index >= 0) {
      summaries[index] = summary;
    } else {
      summaries.add(summary);
    }
    await _saveSummaries(summaries);

    _cachedGroups = null;
    _notify();
  }

  Future<RegexRuleGroup?> duplicate(String id) async {
    _checkInitialized();

    final source = await loadById(id);
    if (source == null) {
      return null;
    }

    final summaries = await loadAllSummaries();
    final duplicate = RegexRuleGroup(
      id: _generateId(),
      name: _buildDuplicateName(source.name, summaries),
      rules: source.rules,
      updatedAt: DateTime.now(),
      extra: source.extra,
    );

    await save(duplicate);
    return duplicate;
  }

  Future<void> delete(String id) async {
    _checkInitialized();

    final file = File('$_groupsPath/$id.json');
    if (await file.exists()) {
      await file.delete();
    }

    final summaries = await loadAllSummaries();
    summaries.removeWhere((item) => item.id == id);
    await _saveSummaries(summaries);

    _cachedGroups = null;
    _notify();
  }

  Future<String?> exportToFile(RegexRuleGroup group) async {
    _checkInitialized();

    final defaultName = '${group.name}.json';
    final content = group.exportJsonString();
    String? outputPath;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出规则组',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (outputPath == null) {
        return null;
      }

      await File(outputPath).writeAsString(content);
    } else {
      outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出规则组',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(utf8.encode(content)),
      );
    }

    return outputPath;
  }

  /// 导入 PocketInn 原生规则组文件。
  Future<RegexRuleGroup?> importFromFile() async {
    _checkInitialized();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: '导入规则组',
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final picked = result.files.first;
    final path = picked.path;
    if (path == null || path.isEmpty) {
      return null;
    }

    final file = File(path);
    final content = await file.readAsString();

    try {
      return await importFromJson(
        content,
        fallbackName: _basenameWithoutJson(picked.name),
      );
    } catch (e) {
      throw RegexRuleGroupImportException('导入失败: $e');
    }
  }

  Future<RegexRuleGroup> importFromJson(
    String jsonContent, {
    String? fallbackName,
  }) async {
    _checkInitialized();

    final decoded = jsonDecode(jsonContent);
    if (decoded is! Map<String, dynamic>) {
      throw const RegexRuleGroupImportException('所选文件不是有效的规则组 JSON');
    }
    if (!RegexRuleGroup.looksLikeExportJson(decoded)) {
      throw const RegexRuleGroupImportException('所选文件不是有效的规则组 JSON');
    }

    final now = DateTime.now();
    final group = RegexRuleGroup.fromExportJson(
      decoded,
      id: _generateId(),
      now: now,
    );
    if (group == null) {
      throw const RegexRuleGroupImportException('规则组文件格式不正确');
    }

    await save(group.copyWith(updatedAt: now));
    return group;
  }

  /// 从文件导入 ST 正则脚本（单条规则或规则数组），供规则组编辑页追加规则使用。
  Future<StRulesImportResult> importStRulesFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: '导入 ST 正则脚本',
    );

    if (result == null || result.files.isEmpty) {
      return const StRulesImportResult(rules: [], warnings: []);
    }

    final picked = result.files.first;
    final path = picked.path;
    if (path == null || path.isEmpty) {
      return const StRulesImportResult(rules: [], warnings: []);
    }

    final file = File(path);
    final content = await file.readAsString();

    try {
      return parseStRulesFromJson(content);
    } catch (e) {
      throw RegexRuleGroupImportException('导入失败: $e');
    }
  }

  /// 解析 ST 正则脚本 JSON（单对象或对象数组）为规则列表。
  ///
  /// 无法执行的 ST 字段保留在规则 [RegexRule.extra] 中，
  /// 并在 [StRulesImportResult.warnings] 中提示；
  /// 正则无法编译的规则保留原文，运行时将被跳过。
  static StRulesImportResult parseStRulesFromJson(String jsonContent) {
    final decoded = jsonDecode(jsonContent);
    final rawRules = <dynamic>[];
    if (decoded is Map<String, dynamic>) {
      rawRules.add(decoded);
    } else if (decoded is List) {
      rawRules.addAll(decoded.whereType<Map>());
    }
    if (rawRules.isEmpty) {
      throw const RegexRuleGroupImportException('所选文件不是有效的 ST 正则 JSON');
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final rules = <RegexRule>[];
    final warnings = <String>[];
    for (var i = 0; i < rawRules.length; i++) {
      final ruleJson = Map<String, dynamic>.from(rawRules[i] as Map);
      if (!(ruleJson.containsKey('scriptName') ||
          ruleJson.containsKey('findRegex'))) {
        throw const RegexRuleGroupImportException(
          '所选文件不是有效的 ST 正则 JSON',
        );
      }
      final rule = RegexRule.fromSillyTavernJson(
        ruleJson,
        id: 'rule-$nowMs-$i',
      );
      rules.add(rule);

      if (rule.extra.isNotEmpty) {
        warnings.add(
          '规则「${rule.name}」已保留但暂不执行的字段：'
          '${rule.extra.keys.join('、')}',
        );
      }
      final error = rule.validateRegex();
      if (error != null) {
        warnings.add('规则「${rule.name}」正则有误，运行时将被跳过：$error');
      }
    }

    return StRulesImportResult(rules: rules, warnings: warnings);
  }

  Future<void> resetToDefaults() async {
    _checkInitialized();

    await StorageService.instance.deleteJsonFile(_indexFilename);

    final dir = Directory(_groupsPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    _cachedGroups = null;
    _notify();
  }

  String _generateId() => 'group-${DateTime.now().millisecondsSinceEpoch}';

  String _basenameWithoutJson(String filename) {
    return filename.toLowerCase().endsWith('.json')
        ? filename.substring(0, filename.length - 5)
        : filename;
  }

  String _buildDuplicateName(
    String sourceName,
    List<RegexRuleGroupSummary> summaries,
  ) {
    final normalizedSourceName = sourceName.trim().isEmpty
        ? '未命名规则组'
        : sourceName.trim();
    final existingNames = summaries.map((item) => item.name).toSet();
    final baseName = '$normalizedSourceName 副本';
    if (!existingNames.contains(baseName)) {
      return baseName;
    }

    var index = 2;
    while (existingNames.contains('$baseName $index')) {
      index += 1;
    }
    return '$baseName $index';
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError('RegexRuleGroupService 未初始化，请先调用 initialize()');
    }
  }

  void _notify() {
    changeNotifier.value++;
  }

  Future<void> _saveSummaries(List<RegexRuleGroupSummary> summaries) async {
    final data = {
      'version': _dataVersion,
      'groups': summaries.map((item) => item.toJson()).toList(),
    };
    await StorageService.instance.writeJsonMap(_indexFilename, data);
  }
}

class RegexRuleGroupImportException implements Exception {
  const RegexRuleGroupImportException(this.message);

  final String message;

  @override
  String toString() => 'RegexRuleGroupImportException: $message';
}

/// ST 正则脚本导入结果报告。
class StRulesImportResult {
  const StRulesImportResult({
    required this.rules,
    required this.warnings,
  });

  final List<RegexRule> rules;
  final List<String> warnings;

  String get warningText => warnings.join('；');
}
