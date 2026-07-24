import 'package:flutter/foundation.dart';

enum RemoteBackupType {
  webdav,
  s3;

  String get label {
    return switch (this) {
      RemoteBackupType.webdav => 'WebDAV',
      RemoteBackupType.s3 => 'S3',
    };
  }
}

@immutable
class WebDavBackupConfig {
  const WebDavBackupConfig({
    this.url = '',
    this.remotePath = 'PocketInn',
    this.username = '',
    this.password = '',
  });

  final String url;
  final String remotePath;
  final String username;
  final String password;

  WebDavBackupConfig copyWith({
    String? url,
    String? remotePath,
    String? username,
    String? password,
  }) {
    return WebDavBackupConfig(
      url: url ?? this.url,
      remotePath: remotePath ?? this.remotePath,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'remotePath': remotePath};
  }

  factory WebDavBackupConfig.fromJson(Map<String, dynamic>? json) {
    return WebDavBackupConfig(
      url: json?['url']?.toString() ?? '',
      remotePath: json?['remotePath']?.toString() ?? 'PocketInn',
    );
  }
}

@immutable
class S3BackupConfig {
  const S3BackupConfig({
    this.endpoint = '',
    this.region = 'us-east-1',
    this.bucket = '',
    this.remotePath = 'PocketInn',
    this.accessKey = '',
    this.secretKey = '',
    this.usePathStyle = false,
  });

  final String endpoint;
  final String region;
  final String bucket;
  final String remotePath;
  final String accessKey;
  final String secretKey;
  final bool usePathStyle;

  S3BackupConfig copyWith({
    String? endpoint,
    String? region,
    String? bucket,
    String? remotePath,
    String? accessKey,
    String? secretKey,
    bool? usePathStyle,
  }) {
    return S3BackupConfig(
      endpoint: endpoint ?? this.endpoint,
      region: region ?? this.region,
      bucket: bucket ?? this.bucket,
      remotePath: remotePath ?? this.remotePath,
      accessKey: accessKey ?? this.accessKey,
      secretKey: secretKey ?? this.secretKey,
      usePathStyle: usePathStyle ?? this.usePathStyle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'endpoint': endpoint,
      'region': region,
      'bucket': bucket,
      'remotePath': remotePath,
      'usePathStyle': usePathStyle,
    };
  }

  factory S3BackupConfig.fromJson(Map<String, dynamic>? json) {
    return S3BackupConfig(
      endpoint: json?['endpoint']?.toString() ?? '',
      region: json?['region']?.toString() ?? 'us-east-1',
      bucket: json?['bucket']?.toString() ?? '',
      remotePath: json?['remotePath']?.toString() ?? 'PocketInn',
      accessKey: json?['accessKey']?.toString() ?? '',
      usePathStyle: json?['usePathStyle'] as bool? ?? false,
    );
  }
}

@immutable
class RemoteBackupSettings {
  const RemoteBackupSettings({
    this.webdav = const WebDavBackupConfig(),
    this.s3 = const S3BackupConfig(),
    this.selectedType = RemoteBackupType.webdav,
    this.isExpanded = false,
  });

  final WebDavBackupConfig webdav;
  final S3BackupConfig s3;
  final RemoteBackupType selectedType;
  final bool isExpanded;

  Map<String, dynamic> toJson() {
    return {
      'webdav': webdav.toJson(),
      's3': s3.toJson(),
      'selectedType': selectedType.name,
      'isExpanded': isExpanded,
    };
  }

  factory RemoteBackupSettings.fromJson(Map<String, dynamic>? json) {
    final webdav = WebDavBackupConfig.fromJson(_asMap(json?['webdav']));
    final s3 = S3BackupConfig.fromJson(_asMap(json?['s3']));
    return RemoteBackupSettings(
      webdav: webdav,
      s3: s3,
      selectedType: _selectedTypeFromJson(json, webdav: webdav, s3: s3),
      isExpanded: json?['isExpanded'] as bool? ?? false,
    );
  }

  static RemoteBackupType _selectedTypeFromJson(
    Map<String, dynamic>? json, {
    required WebDavBackupConfig webdav,
    required S3BackupConfig s3,
  }) {
    return switch (json?['selectedType']) {
      'webdav' => RemoteBackupType.webdav,
      's3' => RemoteBackupType.s3,
      _
          when webdav.url.trim().isEmpty &&
              (s3.endpoint.trim().isNotEmpty || s3.bucket.trim().isNotEmpty) =>
        RemoteBackupType.s3,
      _ => RemoteBackupType.webdav,
    };
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
