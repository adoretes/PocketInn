import 'dart:convert';

import '../models/remote_backup_config.dart';
import 'secure_storage_service.dart';
import 'storage_service.dart';

class RemoteBackupSettingsService {
  RemoteBackupSettingsService._();

  static final RemoteBackupSettingsService instance =
      RemoteBackupSettingsService._();

  static const String settingsKey = 'remote_backup_settings';
  static const String _webDavUsernameKey = 'remote_backup_webdav_username';
  static const String _webDavPasswordKey = 'remote_backup_webdav_password';
  static const String _s3AccessKeyKey = 'remote_backup_s3_access_key';
  static const String _s3SecretKeyKey = 'remote_backup_s3_secret_key';

  Future<RemoteBackupSettings> load() async {
    final raw = StorageService.instance.getString(settingsKey);
    Map<String, dynamic>? json;
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          json = Map<String, dynamic>.from(decoded);
        }
      } on Object {
        json = null;
      }
    }

    final webdavUsername = await SecureStorageService.instance.readSecret(
      _webDavUsernameKey,
    );
    final webdavPassword = await SecureStorageService.instance.readSecret(
      _webDavPasswordKey,
    );
    final legacyS3AccessKey = await SecureStorageService.instance.readSecret(
      _s3AccessKeyKey,
    );
    final s3SecretKey = await SecureStorageService.instance.readSecret(
      _s3SecretKeyKey,
    );

    final settings = RemoteBackupSettings.fromJson(json);
    return RemoteBackupSettings(
      webdav: settings.webdav.copyWith(
        username: webdavUsername,
        password: webdavPassword,
      ),
      s3: settings.s3.copyWith(
        accessKey: settings.s3.accessKey.isNotEmpty
            ? settings.s3.accessKey
            : legacyS3AccessKey,
        secretKey: s3SecretKey,
      ),
      selectedType: settings.selectedType,
      isExpanded: settings.isExpanded,
    );
  }

  Future<void> save(RemoteBackupSettings settings) async {
    final data = settings.toJson();
    final s3 = Map<String, dynamic>.from(data['s3'] as Map);
    // Access Key 是标识符而不是密钥，放在普通配置中可跨平台稳定持久化。
    // Secret Key 仍只写入 flutter_secure_storage。
    s3['accessKey'] = settings.s3.accessKey;
    data['s3'] = s3;
    await StorageService.instance.setString(
      settingsKey,
      const JsonEncoder.withIndent('  ').convert(data),
    );

    await Future.wait([
      SecureStorageService.instance.saveSecret(
        _webDavUsernameKey,
        settings.webdav.username,
      ),
      SecureStorageService.instance.saveSecret(
        _webDavPasswordKey,
        settings.webdav.password,
      ),
      SecureStorageService.instance.saveSecret(
        _s3AccessKeyKey,
        settings.s3.accessKey,
      ),
      SecureStorageService.instance.saveSecret(
        _s3SecretKeyKey,
        settings.s3.secretKey,
      ),
    ]);
  }

  Future<void> clear() async {
    await StorageService.instance.remove(settingsKey);
    await Future.wait([
      SecureStorageService.instance.deleteSecret(_webDavUsernameKey),
      SecureStorageService.instance.deleteSecret(_webDavPasswordKey),
      SecureStorageService.instance.deleteSecret(_s3AccessKeyKey),
      SecureStorageService.instance.deleteSecret(_s3SecretKeyKey),
    ]);
  }
}
