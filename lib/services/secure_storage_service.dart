import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  static const String _apiKeyPrefix = 'api_key_';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveApiKey(String configId, String apiKey) async {
    if (apiKey.trim().isEmpty) {
      await _storage.delete(key: '$_apiKeyPrefix$configId');
      return;
    }
    await _storage.write(key: '$_apiKeyPrefix$configId', value: apiKey.trim());
  }

  Future<String> readApiKey(String configId) async {
    return await _storage.read(key: '$_apiKeyPrefix$configId') ?? '';
  }

  Future<void> deleteApiKey(String configId) async {
    await _storage.delete(key: '$_apiKeyPrefix$configId');
  }

  Future<void> saveSecret(String key, String value) async {
    if (value.trim().isEmpty) {
      await _storage.delete(key: key);
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<String> readSecret(String key) async {
    return await _storage.read(key: key) ?? '';
  }

  Future<void> deleteSecret(String key) async {
    await _storage.delete(key: key);
  }
}
