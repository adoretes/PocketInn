import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/preset.dart';
import 'storage_service.dart';

class PresetService {
  PresetService._();

  static final PresetService instance = PresetService._();

  static const String _indexFilename = 'presets_index.json';
  static const String _presetsDir = 'presets';
  static const String _selectedPresetKey = 'selected_preset_id';
  static const int _dataVersion = 1;
  static const String builtinDefaultId = 'preset-default';

  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  late final String _presetsPath;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    final dataDir = StorageService.instance.dataDir;
    _presetsPath = '$dataDir/$_presetsDir';
    final dir = Directory(_presetsPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _initialized = true;
    await _bootstrapBuiltinDefaultIfNeeded();
  }

  String? get selectedPresetId {
    _checkInitialized();
    return StorageService.instance.getString(_selectedPresetKey);
  }

  Future<void> setSelectedPresetId(String id) async {
    _checkInitialized();

    final preset = await loadById(id);
    if (preset == null) {
      final fallback = await loadDefaultPreset();
      if (fallback != null) {
        await StorageService.instance.setString(
          _selectedPresetKey,
          fallback.id,
        );
      } else {
        await StorageService.instance.remove(_selectedPresetKey);
      }
      return;
    }

    await StorageService.instance.setString(_selectedPresetKey, preset.id);
  }

  Future<List<PresetSummary>> loadAllSummaries() async {
    _checkInitialized();

    final data = await StorageService.instance.readJsonMap(_indexFilename);
    if (data == null) {
      return [];
    }

    final version = data['version'] as int? ?? _dataVersion;
    if (version != _dataVersion) {
      return [];
    }

    final items = data['presets'] as List<dynamic>? ?? const [];
    return items
        .map(
          (item) =>
              PresetSummary.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<Preset>> loadAll() async {
    _checkInitialized();

    final summaries = await loadAllSummaries();
    final presets = <Preset>[];
    for (final summary in summaries) {
      final preset = await loadById(summary.id);
      if (preset != null) {
        presets.add(preset);
      }
    }
    return presets;
  }

  Future<Preset?> loadById(String id) async {
    _checkInitialized();

    final file = File('$_presetsPath/$id.json');
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      return Preset.fromStorageJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<Preset?> loadDefaultPreset() async {
    _checkInitialized();

    final builtin = await loadById(builtinDefaultId);
    if (builtin != null) {
      return builtin;
    }

    final presets = await loadAll();
    if (presets.isEmpty) {
      return null;
    }
    return presets.first;
  }

  Future<Preset> buildEditableTemplate() async {
    _checkInitialized();

    final defaultJson = await rootBundle.loadString('assets/Default.json');
    final decoded = jsonDecode(defaultJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Default.json 不是有效的预设对象');
    }

    return Preset.fromSillyTavernJson(
      decoded,
      id: generateId(),
      fallbackName: '新预设',
      isBuiltin: false,
    ).copyWith(
      name: '新预设',
      isBuiltin: false,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> save(Preset preset) async {
    _checkInitialized();

    final normalized = preset.copyWith(
      name: preset.name.trim().isEmpty ? '未命名预设' : preset.name.trim(),
      updatedAt: DateTime.now(),
    );

    final file = File('$_presetsPath/${normalized.id}.json');
    final content = const JsonEncoder.withIndent(
      '  ',
    ).convert(normalized.toStorageJson());
    await file.writeAsString(content);

    final summaries = await loadAllSummaries();
    final summary = PresetSummary(
      id: normalized.id,
      name: normalized.name,
      isBuiltin: normalized.isBuiltin,
      updatedAt: normalized.updatedAt,
    );
    final index = summaries.indexWhere((item) => item.id == normalized.id);
    if (index >= 0) {
      summaries[index] = summary;
    } else {
      summaries.add(summary);
    }
    await _saveSummaries(summaries);

    final currentSelectedId = selectedPresetId;
    if (currentSelectedId == null || currentSelectedId.isEmpty) {
      await setSelectedPresetId(normalized.id);
    }

    _notify();
  }

  Future<Preset?> duplicate(String id) async {
    _checkInitialized();

    final source = await loadById(id);
    if (source == null) {
      return null;
    }

    final summaries = await loadAllSummaries();
    final duplicate = source.copyWith(
      id: generateId(),
      name: _buildDuplicateName(source.name, summaries),
      isBuiltin: false,
      updatedAt: DateTime.now(),
    );

    await save(duplicate);
    return duplicate;
  }

  Future<void> delete(String id) async {
    _checkInitialized();

    final preset = await loadById(id);
    if (preset == null) {
      return;
    }
    if (preset.isBuiltin) {
      throw StateError('内置默认预设不可删除');
    }

    final file = File('$_presetsPath/$id.json');
    if (await file.exists()) {
      await file.delete();
    }

    final summaries = await loadAllSummaries();
    summaries.removeWhere((item) => item.id == id);
    await _saveSummaries(summaries);

    if (selectedPresetId == id) {
      final fallback = await loadDefaultPreset();
      if (fallback != null && fallback.id != id) {
        await StorageService.instance.setString(
          _selectedPresetKey,
          fallback.id,
        );
      } else {
        await StorageService.instance.remove(_selectedPresetKey);
      }
    }

    _notify();
  }

  Future<String?> exportToFile(Preset preset) async {
    _checkInitialized();

    final defaultName = '${preset.name}.json';
    final content = preset.exportJsonString();
    String? outputPath;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出预设',
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
        dialogTitle: '导出预设',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(utf8.encode(content)),
      );
    }

    return outputPath;
  }

  Future<Preset?> importFromFile() async {
    _checkInitialized();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: '导入预设',
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
      return importFromJson(
        content,
        fallbackName: _basenameWithoutJson(picked.name),
      );
    } on FormatException catch (e) {
      throw PresetImportException('解析失败: ${e.message}');
    } catch (e) {
      if (e is PresetImportException) {
        rethrow;
      }
      throw PresetImportException('导入失败: $e');
    }
  }

  Future<Preset> importFromJson(
    String jsonContent, {
    String? fallbackName,
  }) async {
    _checkInitialized();

    final decoded = jsonDecode(jsonContent);
    if (decoded is! Map<String, dynamic>) {
      throw const PresetImportException('预设文件格式不正确');
    }
    if (!Preset.looksLikePresetJson(decoded)) {
      throw const PresetImportException('所选文件不是有效的预设 JSON');
    }

    final imported = Preset.fromSillyTavernJson(
      decoded,
      id: generateId(),
      fallbackName: fallbackName,
      isBuiltin: false,
    ).copyWith(isBuiltin: false, updatedAt: DateTime.now());

    await save(imported);
    return imported;
  }

  Future<void> resetToDefaults() async {
    _checkInitialized();

    await StorageService.instance.deleteJsonFile(_indexFilename);
    await StorageService.instance.remove(_selectedPresetKey);

    final dir = Directory(_presetsPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    await _bootstrapBuiltinDefaultIfNeeded();
  }

  String generateId() => 'preset-${DateTime.now().millisecondsSinceEpoch}';

  String _basenameWithoutJson(String filename) {
    return filename.toLowerCase().endsWith('.json')
        ? filename.substring(0, filename.length - 5)
        : filename;
  }

  String _buildDuplicateName(String sourceName, List<PresetSummary> summaries) {
    final normalizedSourceName = sourceName.trim().isEmpty
        ? '未命名预设'
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
      throw StateError('PresetService 未初始化，请先调用 initialize()');
    }
  }

  void _notify() {
    changeNotifier.value++;
  }

  Future<void> _saveSummaries(List<PresetSummary> summaries) async {
    final data = {
      'version': _dataVersion,
      'presets': summaries.map((item) => item.toJson()).toList(),
    };
    await StorageService.instance.writeJsonMap(_indexFilename, data);
  }

  Future<void> _bootstrapBuiltinDefaultIfNeeded() async {
    final summaries = await loadAllSummaries();
    if (summaries.isNotEmpty) {
      final selected = selectedPresetId;
      if (selected == null || selected.isEmpty) {
        final defaultPreset = await loadDefaultPreset();
        if (defaultPreset != null) {
          await StorageService.instance.setString(
            _selectedPresetKey,
            defaultPreset.id,
          );
        }
      }
      return;
    }

    final defaultJson = await rootBundle.loadString('assets/Default.json');
    final decoded = jsonDecode(defaultJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Default.json 不是有效的预设对象');
    }

    final builtinPreset = Preset.fromSillyTavernJson(
      decoded,
      id: builtinDefaultId,
      fallbackName: '默认预设',
      isBuiltin: true,
    ).copyWith(updatedAt: DateTime.now());
    await save(builtinPreset);
    await StorageService.instance.setString(
      _selectedPresetKey,
      builtinPreset.id,
    );
  }
}

class PresetImportException implements Exception {
  const PresetImportException(this.message);

  final String message;

  @override
  String toString() => 'PresetImportException: $message';
}
