import 'package:flutter/foundation.dart';

import '../models/api_config.dart';
import '../services/api_config_service.dart';

final ValueNotifier<List<ApiConfig>> apiConfigsNotifier =
    ValueNotifier<List<ApiConfig>>([]);

/// 当前选中的模型 id（唯一选择状态）。不存"配置激活"，也不存"模型激活"——
/// 只存"选了哪个模型"。空表示未选择任何模型。
final ValueNotifier<String?> selectedApiModelIdNotifier =
    ValueNotifier<String?>(null);

/// 当前选中的 (provider, model) 元组。给 UI 层显示用。
({ApiConfig provider, ApiModel model})? get selectedApiModelTuple {
  final id = selectedApiModelIdNotifier.value;
  if (id == null || id.isEmpty) return null;
  return findModelEntryById(id);
}

/// 当前生效的 ResolvedApiConfig（provider + 选中 model 的组合），供 service 调用。
ResolvedApiConfig? get resolvedSelectedApi {
  final t = selectedApiModelTuple;
  return t?.provider.resolve(t.model);
}

/// 列出所有 (provider, model) 对，供选择器 UI 展示用。
/// [configs] 缺省时取当前 [apiConfigsNotifier] 的值。
List<({ApiConfig provider, ApiModel model})> flattenModelEntries([
  List<ApiConfig>? configs,
]) {
  final list = configs ?? apiConfigsNotifier.value;
  return [
    for (final c in list)
      for (final m in c.models) (provider: c, model: m),
  ];
}

/// 按全局唯一的模型 id 查找 (provider, model) 对；找不到返回 null。
/// 供选中态展示、失效 id 判定等 UI 逻辑与 [resolveApiByModelId] 复用。
({ApiConfig provider, ApiModel model})? findModelEntryById(
  String? modelId, [
  List<ApiConfig>? configs,
]) {
  if (modelId == null || modelId.isEmpty) return null;
  for (final entry in flattenModelEntries(configs)) {
    if (entry.model.id == modelId) return entry;
  }
  return null;
}

/// 按全局唯一的模型 id 解析 API 配置（如 Gal 模式选项生成专用模型）。
/// 找不到（未设置、已被删除等）返回 null，由调用方回退到 [resolvedSelectedApi]。
ResolvedApiConfig? resolveApiByModelId(String? modelId) {
  final entry = findModelEntryById(modelId);
  return entry?.provider.resolve(entry.model);
}

Future<void> initializeApiConfigs() async {
  final result = await ApiConfigService.instance.loadAllWithSelection();
  apiConfigsNotifier.value = List<ApiConfig>.unmodifiable(result.configs);
  selectedApiModelIdNotifier.value = _validateSelectedId(
    result.configs,
    result.selectedModelId,
  );
}

Future<void> updateApiConfigs(List<ApiConfig> configs) async {
  final nextConfigs = List<ApiConfig>.unmodifiable(
    configs.map((item) => item.copyWith()).toList(),
  );
  apiConfigsNotifier.value = nextConfigs;

  // 若当前选中 model 已不存在于新列表（被删除等情况），自动清空选择。
  final currentSelected = selectedApiModelIdNotifier.value;
  final stillExists = _modelExists(nextConfigs, currentSelected);
  final newSelected = stillExists ? currentSelected : null;
  if (!stillExists) {
    selectedApiModelIdNotifier.value = null;
  }
  await ApiConfigService.instance.saveAll(nextConfigs, newSelected);
}

/// 选择某个模型。这是修改选择状态的唯一入口。
Future<void> selectApiModel(String modelId) async {
  selectedApiModelIdNotifier.value = modelId;
  await ApiConfigService.instance.saveSelectedModelId(modelId);
}

/// 清空选择。
Future<void> clearSelectedApiModel() async {
  selectedApiModelIdNotifier.value = null;
  await ApiConfigService.instance.saveSelectedModelId(null);
}

String? _validateSelectedId(List<ApiConfig> configs, String? selectedId) {
  if (selectedId == null || selectedId.isEmpty) return null;
  if (_modelExists(configs, selectedId)) return selectedId;
  return null;
}

bool _modelExists(List<ApiConfig> configs, String? modelId) {
  return findModelEntryById(modelId, configs) != null;
}
