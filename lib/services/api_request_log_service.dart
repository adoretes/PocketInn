import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'storage_service.dart';

@immutable
class ApiRequestLogEntry {
  const ApiRequestLogEntry({
    required this.id,
    required this.timestamp,
    required this.configName,
    required this.model,
    required this.method,
    required this.endpoint,
    required this.requestBody,
    required this.responseBody,
    required this.success,
    required this.durationMs,
    this.statusCode,
    this.errorMessage,
  });

  final String id;
  final DateTime timestamp;
  final String configName;
  final String model;
  final String method;
  final String endpoint;
  final String requestBody;
  final String responseBody;
  final bool success;
  final int durationMs;
  final int? statusCode;
  final String? errorMessage;

  factory ApiRequestLogEntry.fromJson(Map<String, dynamic> json) {
    return ApiRequestLogEntry(
      id: json['id']?.toString() ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      configName: json['configName']?.toString() ?? '未命名配置',
      model: json['model']?.toString() ?? '',
      method: json['method']?.toString() ?? 'POST',
      endpoint: json['endpoint']?.toString() ?? '',
      requestBody: json['requestBody']?.toString() ?? '',
      responseBody: json['responseBody']?.toString() ?? '',
      success: json['success'] as bool? ?? false,
      durationMs: json['durationMs'] as int? ?? 0,
      statusCode: json['statusCode'] as int?,
      errorMessage: json['errorMessage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'configName': configName,
      'model': model,
      'method': method,
      'endpoint': endpoint,
      'requestBody': requestBody,
      'responseBody': responseBody,
      'success': success,
      'durationMs': durationMs,
      'statusCode': statusCode,
      'errorMessage': errorMessage,
    };
  }
}

class ApiRequestLogService {
  ApiRequestLogService._();

  static final ApiRequestLogService instance = ApiRequestLogService._();

  static const String _fileName = 'api_request_logs.json';
  static const int _maxEntries = 10;

  final ValueNotifier<List<ApiRequestLogEntry>> logsNotifier = ValueNotifier(
    const <ApiRequestLogEntry>[],
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    final storage = StorageService.instance;
    final raw = await storage.readJsonFile(_fileName);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          logsNotifier.value = decoded
              .whereType<Map>()
              .map(
                (item) => ApiRequestLogEntry.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false);
        }
      } on Object catch (error, stack) {
        debugPrint(
          'api_request_log_service: initialize parse failed: '
          '$error\n$stack',
        );
        logsNotifier.value = const <ApiRequestLogEntry>[];
      }
    }
    _initialized = true;
  }

  Future<void> append({
    required String configName,
    required String model,
    required String method,
    required String endpoint,
    required bool success,
    required int durationMs,
    int? statusCode,
    Object? requestBody,
    String? responseBody,
    String? errorMessage,
  }) async {
    await initialize();
    final nextEntry = ApiRequestLogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      configName: configName.trim().isEmpty ? '未命名配置' : configName.trim(),
      model: model.trim(),
      method: method.trim().isEmpty ? 'POST' : method.trim().toUpperCase(),
      endpoint: endpoint.trim(),
      requestBody: _normalizeText(requestBody),
      responseBody: _normalizeText(responseBody),
      success: success,
      durationMs: durationMs,
      statusCode: statusCode,
      errorMessage: _normalizeText(errorMessage),
    );
    final nextLogs = [
      nextEntry,
      ...logsNotifier.value,
    ].take(_maxEntries).toList(growable: false);
    logsNotifier.value = nextLogs;
    await _persist(nextLogs);
  }

  Future<void> clear() async {
    await initialize();
    logsNotifier.value = const <ApiRequestLogEntry>[];
    await StorageService.instance.deleteJsonFile(_fileName);
  }

  Future<void> reload() async {
    final storage = StorageService.instance;
    final raw = await storage.readJsonFile(_fileName);
    if (raw == null || raw.trim().isEmpty) {
      logsNotifier.value = const <ApiRequestLogEntry>[];
      _initialized = true;
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        logsNotifier.value = decoded
            .whereType<Map>()
            .map(
              (item) =>
                  ApiRequestLogEntry.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false);
      } else {
        logsNotifier.value = const <ApiRequestLogEntry>[];
      }
    } on Object catch (error, stack) {
      debugPrint(
        'api_request_log_service: reload parse failed: '
        '$error\n$stack',
      );
      logsNotifier.value = const <ApiRequestLogEntry>[];
    }
    _initialized = true;
  }

  Future<void> _persist(List<ApiRequestLogEntry> logs) async {
    final encoded = jsonEncode(logs.map((item) => item.toJson()).toList());
    await StorageService.instance.writeJsonFile(_fileName, encoded);
  }

  String _normalizeText(Object? value) {
    if (value == null) {
      return '';
    }
    final rawText = value is String
        ? value
        : const JsonEncoder.withIndent('  ').convert(value);
    return rawText.trim();
  }
}
