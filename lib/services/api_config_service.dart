import '../models/api_config.dart';
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
      // v1 → v2 迁移：旧 ApiConfig { model:String, customBody:String, enabled:bool }
      // 转换为新 ApiConfig（provider）下挂一个 ApiModel。
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
      // 迁移后立刻以新版本落盘，避免下次重复迁移。
      await saveAll(migrated, selectedModelId);
      return (configs: migrated, selectedModelId: selectedModelId);
    }

    // v2 直接反序列化
    final configs = items
        .map(
          (item) =>
              ApiConfig.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    final selectedModelId = data['selectedApiModelId'] as String?;
    return (
      configs: configs,
      selectedModelId:
          (selectedModelId != null && selectedModelId.isNotEmpty)
          ? selectedModelId
          : null,
    );
  }

  Future<void> saveAll(List<ApiConfig> configs, String? selectedModelId) async {
    _checkInitialized();
    await StorageService.instance.writeJsonMap(_filename, {
      'version': _dataVersion,
      'items': configs.map((item) => item.toJson()).toList(),
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
