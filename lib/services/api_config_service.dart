import '../models/api_config.dart';
import 'secure_storage_service.dart';
import 'storage_service.dart';

class ApiConfigService {
  ApiConfigService._();

  static final ApiConfigService instance = ApiConfigService._();

  static const String _filename = 'api_configs.json';
  static const int _dataVersion = 2;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _bootstrapDefaultsIfNeeded();
  }

  Future<({List<ApiConfig> configs, String? selectedModelId})>
      loadAllWithSelection() async {
    _checkInitialized();

    final data = await StorageService.instance.readJsonMap(_filename);
    if (data == null) {
      return (configs: <ApiConfig>[], selectedModelId: null);
    }

    final version = data['version'] as int? ?? _dataVersion;
    final items = data['items'] as List<dynamic>? ?? const [];

    if (version == 1) {
      final migrated = <ApiConfig>[];
      String? selectedModelId;
      final now = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < items.length; i++) {
        final raw = Map<String, dynamic>.from(items[i] as Map);
        final oldModel = (raw['model'] as String?) ?? '';
        final oldCustomBody = (raw['customBody'] as String?) ?? '';
        final oldEnabled = (raw['enabled'] as bool?) ?? false;
        final modelId = 'api_model_${now}_${i}_m${raw['id']?.hashCode ?? 0}';
        if (oldEnabled && selectedModelId == null) {
          selectedModelId = modelId;
        }
        migrated.add(
          ApiConfig(
            id: (raw['id'] as String?) ?? 'api_config_${now}_$i',
            name: (raw['name'] as String?) ?? '未命名配置',
            baseUrl: (raw['baseUrl'] as String?) ?? '',
            apiKey: (raw['apiKey'] as String?) ?? '',
            models: [
              ApiModel(
                id: modelId,
                modelId: oldModel,
                customBody: oldCustomBody,
              ),
            ],
          ),
        );
      }
      // v1 → v2 迁移后立即保存（apiKey 会同步到安全存储）
      await saveAll(migrated, selectedModelId);
      return (configs: migrated, selectedModelId: selectedModelId);
    }

    // v2 反序列化后从安全存储填充 apiKey
    final configs = items
        .map(
          (item) =>
              ApiConfig.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    final enriched = <ApiConfig>[];
    for (final config in configs) {
      if (config.apiKey.isNotEmpty) {
        // 旧数据迁移：apiKey 仍明文在 JSON 中，写入安全存储
        await SecureStorageService.instance.saveApiKey(
          config.id,
          config.apiKey,
        );
        enriched.add(config);
      } else {
        final storedKey = await SecureStorageService.instance.readApiKey(
          config.id,
        );
        enriched.add(config.copyWith(apiKey: storedKey));
      }
    }
    final selectedModelId = data['selectedApiModelId'] as String?;
    return (
      configs: enriched,
      selectedModelId:
          (selectedModelId != null && selectedModelId.isNotEmpty)
          ? selectedModelId
          : null,
    );
  }

  Future<void> saveAll(List<ApiConfig> configs, String? selectedModelId) async {
    _checkInitialized();
    // 先同步 apiKey 到安全存储
    for (final config in configs) {
      await SecureStorageService.instance.saveApiKey(
        config.id,
        config.apiKey,
      );
    }
    // 写入 JSON 时清空 apiKey，避免明文落盘
    final sanitized = configs.map((c) => c.copyWith(apiKey: '')).toList();
    await StorageService.instance.writeJsonMap(_filename, {
      'version': _dataVersion,
      'items': sanitized.map((item) => item.toJson()).toList(),
      'selectedApiModelId': selectedModelId,
    });
  }

  Future<void> saveSelectedModelId(String? modelId) async {
    _checkInitialized();
    // 读出当前文件，仅替换 selectedApiModelId 字段。
    final data = await StorageService.instance.readJsonMap(_filename);
    if (data == null) {
      // 没有文件，直接写入一个仅含 selection 的最小结构（极少出现）。
      await StorageService.instance.writeJsonMap(_filename, {
        'version': _dataVersion,
        'items': <Map<String, dynamic>>[],
        'selectedApiModelId': modelId,
      });
      return;
    }
    data['version'] = _dataVersion;
    data['selectedApiModelId'] = modelId;
    await StorageService.instance.writeJsonMap(_filename, data);
  }

  Future<void> resetToDefaults() async {
    _checkInitialized();
    await StorageService.instance.deleteJsonFile(_filename);
    await _bootstrapDefaultsIfNeeded();
  }

  String generateId() => 'api_config_${DateTime.now().millisecondsSinceEpoch}';

  String generateModelId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'api_model_${ts}_${ts.hashCode.abs()}';
  }

  Future<void> _bootstrapDefaultsIfNeeded() async {
    final exists = await StorageService.instance.jsonFileExists(_filename);
    if (exists) return;

    const defaultModelId = 'deepseek_001_model';
    await saveAll(
      [
        ApiConfig(
          id: 'deepseek_001',
          name: 'DeepSeek',
          baseUrl: 'https://api.deepseek.com/v1',
          apiKey: '',
          models: const [
            ApiModel(
              id: defaultModelId,
              modelId: 'deepseek-chat',
              customBody: '',
            ),
          ],
        ),
      ],
      defaultModelId,
    );
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'ApiConfigService 未初始化，请先调用 ApiConfigService.instance.initialize()',
      );
    }
  }
}
