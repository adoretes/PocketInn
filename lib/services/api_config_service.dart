import '../models/api_config.dart';
import 'storage_service.dart';

class ApiConfigService {
  ApiConfigService._();

  static final ApiConfigService instance = ApiConfigService._();

  static const String _filename = 'api_configs.json';
  static const int _dataVersion = 1;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _bootstrapDefaultsIfNeeded();
  }

  Future<List<ApiConfig>> loadAll() async {
    _checkInitialized();

    final data = await StorageService.instance.readJsonMap(_filename);
    if (data == null) {
      return [];
    }

    final version = data['version'] as int? ?? _dataVersion;
    if (version != _dataVersion) {
      return [];
    }

    final items = data['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => ApiConfig.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveAll(List<ApiConfig> configs) async {
    _checkInitialized();
    await StorageService.instance.writeJsonMap(_filename, {
      'version': _dataVersion,
      'items': configs.map((item) => item.toJson()).toList(),
    });
  }

  Future<void> resetToDefaults() async {
    _checkInitialized();
    await StorageService.instance.deleteJsonFile(_filename);
    await _bootstrapDefaultsIfNeeded();
  }

  String generateId() => 'api_config_${DateTime.now().millisecondsSinceEpoch}';

  Future<void> _bootstrapDefaultsIfNeeded() async {
    final exists = await StorageService.instance.jsonFileExists(_filename);
    if (exists) {
      return;
    }

    await saveAll([
      ApiConfig(
        id: 'deepseek_001',
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        apiKey: '',
        model: 'deepseek-chat',
        enabled: true,
      ),
    ]);
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'ApiConfigService 未初始化，请先调用 ApiConfigService.instance.initialize()',
      );
    }
  }
}
