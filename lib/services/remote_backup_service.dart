import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/remote_backup_config.dart';

class RemoteBackupService {
  RemoteBackupService._();

  static final RemoteBackupService instance = RemoteBackupService._();

  static const Duration _requestTimeout = Duration(seconds: 30);
  static const int maxDownloadSizeBytes = 1024 * 1024 * 1024;

  @visibleForTesting
  static int? maximumDownloadSizeForTesting;

  @visibleForTesting
  String buildS3AuthorizationForTesting({
    required S3BackupConfig config,
    required String method,
    required Uri uri,
    required DateTime timestamp,
    List<int> body = const [],
    Map<String, String> headers = const {},
  }) {
    _validateS3(config);
    return _buildS3Authorization(
      config: config,
      method: method,
      uri: uri,
      timestamp: timestamp,
      body: body,
      headers: headers,
    );
  }

  @visibleForTesting
  String canonicalUriForTesting(Uri uri) => _canonicalUri(uri);

  @visibleForTesting
  Uri s3ObjectUriForTesting(S3BackupConfig config, String fileName) =>
      _s3ObjectUri(config, fileName);

  Future<void> testWebDav(WebDavBackupConfig config) async {
    _validateWebDav(config);
    final directoryUri = _webDavDirectoryUri(config);
    final response = await _webDavRequest(
      config,
      'PROPFIND',
      directoryUri,
      headers: {'Depth': '0'},
    );
    _ensureStatus(
      response,
      accepted: const {200, 207},
      operation: 'WebDAV 连接测试',
      uri: directoryUri,
    );
  }

  Future<void> uploadWebDav(
    WebDavBackupConfig config,
    Uint8List bytes,
    String fileName, {
    void Function(int sent, int total)? onProgress,
  }) async {
    _validateWebDav(config);
    await _ensureWebDavDirectory(config);
    final fileUri = _webDavFileUri(config, fileName);
    final client = HttpClient()..connectionTimeout = _requestTimeout;
    try {
      final request = await client
          .openUrl('PUT', fileUri)
          .timeout(_requestTimeout);
      request.followRedirects = false;
      final username = config.username.trim();
      if (username.isNotEmpty || config.password.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Basic ${base64Encode(utf8.encode('$username:${config.password}'))}',
        );
      }
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/zip',
      );
      request.headers.set(
        HttpHeaders.contentLengthHeader,
        bytes.length.toString(),
      );
      await _writeChunked(request, bytes, onProgress: onProgress);
      final response = await request.close().timeout(_requestTimeout);
      _ensureStatus(
        _RemoteResponse(response.statusCode, Uint8List(0)),
        accepted: const {200, 201, 204},
        operation: 'WebDAV 上传备份',
        uri: fileUri,
      );
    } on SocketException catch (error) {
      throw RemoteBackupException('无法连接 WebDAV：${error.message}', error);
    } on TimeoutException catch (error) {
      throw RemoteBackupException('WebDAV 请求超时', error);
    } on HttpException catch (error) {
      throw RemoteBackupException('WebDAV 接收数据失败：${error.message}', error);
    } finally {
      client.close(force: true);
    }
  }

  Future<Uint8List> downloadWebDav(
    WebDavBackupConfig config,
    String fileName,
  ) async {
    _validateWebDav(config);
    final fileUri = _webDavFileUri(config, fileName);
    final response = await _webDavRequest(config, 'GET', fileUri);
    _ensureStatus(
      response,
      accepted: const {200},
      operation: 'WebDAV 下载备份',
      uri: fileUri,
    );
    return response.body;
  }

  Future<File> downloadWebDavToFile(
    WebDavBackupConfig config,
    String fileName, {
    void Function(int received, int total)? onProgress,
  }) async {
    _validateWebDav(config);
    final fileUri = _webDavFileUri(config, fileName);
    final file = await _newTemporaryBackupFile();
    final client = HttpClient()..connectionTimeout = _requestTimeout;
    try {
      final request = await client
          .openUrl('GET', fileUri)
          .timeout(_requestTimeout);
      request.followRedirects = false;
      final username = config.username.trim();
      if (username.isNotEmpty || config.password.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Basic ${base64Encode(utf8.encode('$username:${config.password}'))}',
        );
      }
      final response = await request.close().timeout(_requestTimeout);
      _ensureStatus(
        _RemoteResponse(response.statusCode, Uint8List(0)),
        accepted: const {200},
        operation: 'WebDAV 下载备份',
        uri: fileUri,
      );
      await _readResponseToFile(response, file, onProgress: onProgress);
      return file;
    } on Object {
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> testS3(S3BackupConfig config) async {
    _validateS3(config);
    final uri = _s3BucketUri(config);
    final response = await _s3Request(config, 'HEAD', uri);
    _ensureStatus(
      response,
      accepted: const {200},
      operation: 'S3 连接测试',
      uri: uri,
    );
  }

  Future<void> uploadS3(
    S3BackupConfig config,
    Uint8List bytes,
    String fileName, {
    void Function(int sent, int total)? onProgress,
  }) async {
    _validateS3(config);
    final uri = _s3ObjectUri(config, fileName);
    final response = await _s3Request(
      config,
      'PUT',
      uri,
      body: bytes,
      headers: {HttpHeaders.contentTypeHeader: 'application/zip'},
      onProgress: onProgress,
    );
    _ensureStatus(
      response,
      accepted: const {200, 201},
      operation: 'S3 上传备份',
      uri: uri,
    );
  }

  Future<Uint8List> downloadS3(S3BackupConfig config, String fileName) async {
    _validateS3(config);
    final uri = _s3ObjectUri(config, fileName);
    final response = await _s3Request(config, 'GET', uri);
    _ensureStatus(
      response,
      accepted: const {200},
      operation: 'S3 下载备份',
      uri: uri,
    );
    return response.body;
  }

  Future<File> downloadS3ToFile(
    S3BackupConfig config,
    String fileName, {
    void Function(int received, int total)? onProgress,
  }) async {
    _validateS3(config);
    final uri = _s3ObjectUri(config, fileName);
    final file = await _newTemporaryBackupFile();
    final now = DateTime.now().toUtc();
    final authorization = _buildS3Authorization(
      config: config,
      method: 'GET',
      uri: uri,
      timestamp: now,
      body: const [],
      headers: const {},
    );
    final client = HttpClient()..connectionTimeout = _requestTimeout;
    try {
      final request = await client.openUrl('GET', uri).timeout(_requestTimeout);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.hostHeader, _hostHeader(uri));
      request.headers.set('x-amz-content-sha256', _sha256Hex(const []));
      request.headers.set('x-amz-date', _formatAmzDate(now));
      request.headers.set(HttpHeaders.authorizationHeader, authorization);
      final response = await request.close().timeout(_requestTimeout);
      _ensureStatus(
        _RemoteResponse(response.statusCode, Uint8List(0)),
        accepted: const {200},
        operation: 'S3 下载备份',
        uri: uri,
      );
      await _readResponseToFile(response, file, onProgress: onProgress);
      return file;
    } on Object {
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<_RemoteResponse> _webDavRequest(
    WebDavBackupConfig config,
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    List<int>? body,
  }) async {
    final client = HttpClient()..connectionTimeout = _requestTimeout;
    try {
      final request = await client
          .openUrl(method, uri)
          .timeout(_requestTimeout);
      request.followRedirects = false;
      final username = config.username.trim();
      final password = config.password;
      if (username.isNotEmpty || password.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Basic ${base64Encode(utf8.encode('$username:$password'))}',
        );
      }
      headers.forEach(request.headers.set);
      if (body != null) {
        request.add(body);
      }
      final response = await request.close().timeout(_requestTimeout);
      return await _readResponse(response);
    } on SocketException catch (error) {
      throw RemoteBackupException('无法连接 WebDAV：${error.message}', error);
    } on TimeoutException catch (error) {
      throw RemoteBackupException('WebDAV 请求超时', error);
    } on HttpException catch (error) {
      throw RemoteBackupException('WebDAV 接收数据失败：${error.message}', error);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _ensureWebDavDirectory(WebDavBackupConfig config) async {
    final baseUri = _parseEndpoint(config.url, 'WebDAV 地址');
    final remotePathParts = _pathParts(config.remotePath);
    final directoryUri = _appendPath(baseUri, remotePathParts);
    final response = await _webDavRequest(
      config,
      'PROPFIND',
      directoryUri,
      headers: {'Depth': '0'},
    );
    if (response.statusCode == 200 || response.statusCode == 207) {
      return;
    }
    if (response.statusCode != 404) {
      _ensureStatus(
        response,
        accepted: const {200, 207},
        operation: 'WebDAV 检查目录',
        uri: directoryUri,
      );
    }

    for (var index = 1; index <= remotePathParts.length; index++) {
      final currentUri = _appendPath(baseUri, remotePathParts.take(index));
      final current = await _webDavRequest(
        config,
        'PROPFIND',
        currentUri,
        headers: {'Depth': '0'},
      );
      if (current.statusCode == 200 || current.statusCode == 207) {
        continue;
      }
      if (current.statusCode != 404) {
        _ensureStatus(
          current,
          accepted: const {200, 207},
          operation: 'WebDAV 检查目录',
          uri: currentUri,
        );
      }
      final created = await _webDavRequest(config, 'MKCOL', currentUri);
      _ensureStatus(
        created,
        accepted: const {201, 405},
        operation: 'WebDAV 创建目录',
        uri: currentUri,
      );
    }
  }

  Future<_RemoteResponse> _s3Request(
    S3BackupConfig config,
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    List<int> body = const [],
    void Function(int sent, int total)? onProgress,
  }) async {
    final requestHeaders = <String, String>{...headers};
    if (method == 'PUT') {
      requestHeaders[HttpHeaders.contentLengthHeader] = body.length.toString();
    }
    final now = DateTime.now().toUtc();
    final authorization = _buildS3Authorization(
      config: config,
      method: method,
      uri: uri,
      timestamp: now,
      body: body,
      headers: requestHeaders,
    );
    final payloadHash = _sha256Hex(body);
    final amzDate = _formatAmzDate(now);
    final host = _hostHeader(uri);

    final client = HttpClient()..connectionTimeout = _requestTimeout;
    try {
      final request = await client
          .openUrl(method, uri)
          .timeout(_requestTimeout);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.hostHeader, host);
      request.headers.set('x-amz-content-sha256', payloadHash);
      request.headers.set('x-amz-date', amzDate);
      request.headers.set(HttpHeaders.authorizationHeader, authorization);
      requestHeaders.forEach(request.headers.set);
      if (body.isNotEmpty) {
        if (onProgress != null) {
          await _writeChunked(request, body, onProgress: onProgress);
        } else {
          request.add(body);
        }
      }
      final response = await request.close().timeout(_requestTimeout);
      return await _readResponse(response);
    } on SocketException catch (error) {
      throw RemoteBackupException('无法连接 S3：${error.message}', error);
    } on TimeoutException catch (error) {
      throw RemoteBackupException('S3 请求超时', error);
    } on HttpException catch (error) {
      throw RemoteBackupException('S3 接收数据失败：${error.message}', error);
    } finally {
      client.close(force: true);
    }
  }

  String _buildS3Authorization({
    required S3BackupConfig config,
    required String method,
    required Uri uri,
    required DateTime timestamp,
    required List<int> body,
    required Map<String, String> headers,
  }) {
    final payloadHash = _sha256Hex(body);
    final now = timestamp.toUtc();
    final amzDate = _formatAmzDate(now);
    final shortDate = _formatShortDate(now);
    final host = _hostHeader(uri);
    final signedHeaders = <String, String>{
      'host': host,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      ...headers.map((key, value) => MapEntry(key.toLowerCase(), value.trim())),
    };
    final canonicalHeaders = signedHeaders.keys.toList()..sort();
    final canonicalHeadersValue = canonicalHeaders
        .map((key) => '$key:${_normalizeHeaderValue(signedHeaders[key]!)}\n')
        .join();
    final signedHeadersValue = canonicalHeaders.join(';');
    final canonicalRequest = [
      method,
      _canonicalUri(uri),
      _canonicalQuery(uri),
      canonicalHeadersValue,
      signedHeadersValue,
      payloadHash,
    ].join('\n');
    final scope = '$shortDate/${config.region.trim()}/s3/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      scope,
      _sha256Hex(utf8.encode(canonicalRequest)),
    ].join('\n');
    final signingKey = _deriveSigningKey(
      config.secretKey,
      shortDate,
      config.region.trim(),
    );
    final signature = _hmacHex(signingKey, stringToSign);
    return 'AWS4-HMAC-SHA256 Credential=${config.accessKey.trim()}/$scope, '
        'SignedHeaders=$signedHeadersValue, Signature=$signature';
  }

  Future<_RemoteResponse> _readResponse(HttpClientResponse response) async {
    final maxDownloadSize =
        maximumDownloadSizeForTesting ?? maxDownloadSizeBytes;
    if (response.contentLength > maxDownloadSize) {
      throw const RemoteBackupException('远端响应过大，最大支持 100 MB', null);
    }
    final body = <int>[];
    await for (final chunk in response.timeout(_requestTimeout)) {
      if (body.length + chunk.length > maxDownloadSize) {
        throw const RemoteBackupException('远端响应过大，最大支持 100 MB', null);
      }
      body.addAll(chunk);
    }
    return _RemoteResponse(response.statusCode, Uint8List.fromList(body));
  }

  Future<void> _readResponseToFile(
    HttpClientResponse response,
    File file, {
    void Function(int received, int total)? onProgress,
  }) async {
    final maxDownloadSize =
        maximumDownloadSizeForTesting ?? maxDownloadSizeBytes;
    if (response.contentLength > maxDownloadSize) {
      throw const RemoteBackupException('远端响应过大，最大支持 1 GB', null);
    }
    var received = 0;
    final total = response.contentLength;
    final sink = file.openWrite();
    try {
      await for (final chunk in response.timeout(_requestTimeout)) {
        received += chunk.length;
        if (received > maxDownloadSize) {
          throw const RemoteBackupException('远端响应过大，最大支持 1 GB', null);
        }
        sink.add(chunk);
        onProgress?.call(received, total);
      }
      await sink.close();
    } catch (_) {
      await sink.close();
      rethrow;
    }
  }

  Future<void> _writeChunked(
    HttpClientRequest request,
    List<int> data, {
    void Function(int sent, int total)? onProgress,
    int chunkSize = 65536,
  }) async {
    var sent = 0;
    final total = data.length;
    for (var offset = 0; offset < total; offset += chunkSize) {
      final end = (offset + chunkSize > total) ? total : offset + chunkSize;
      request.add(data.sublist(offset, end));
      sent = end;
      onProgress?.call(sent, total);
    }
  }

  Future<File> _newTemporaryBackupFile() async {
    final suffix = DateTime.now().microsecondsSinceEpoch;
    return File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'pocketinn-remote-backup-$suffix.zip',
    );
  }

  Uri _webDavDirectoryUri(WebDavBackupConfig config) {
    final base = _parseEndpoint(config.url, 'WebDAV 地址');
    return _appendPath(base, _pathParts(config.remotePath));
  }

  Uri _webDavFileUri(WebDavBackupConfig config, String fileName) {
    return _appendPath(_webDavDirectoryUri(config), <String>[fileName]);
  }

  Uri _s3Endpoint(S3BackupConfig config) {
    final endpoint = config.endpoint.trim().isEmpty
        ? (config.region.trim() == 'us-east-1'
              ? 'https://s3.amazonaws.com'
              : 'https://s3.${config.region.trim()}.amazonaws.com')
        : config.endpoint.trim();
    return _parseEndpoint(endpoint, 'S3 endpoint');
  }

  Uri _s3BucketUri(S3BackupConfig config) {
    final endpoint = _s3Endpoint(config);
    return _s3ResourceUri(config, endpoint, const <String>[]);
  }

  Uri _s3ObjectUri(S3BackupConfig config, String fileName) {
    final endpoint = _s3Endpoint(config);
    return _s3ResourceUri(config, endpoint, <String>[
      ..._pathParts(config.remotePath),
      fileName,
    ]);
  }

  Uri _s3ResourceUri(
    S3BackupConfig config,
    Uri endpoint,
    List<String> objectParts,
  ) {
    final bucket = config.bucket.trim();
    final parts = <String>[];
    final usePathStyle =
        config.usePathStyle ||
        (endpoint.scheme == 'https' && bucket.contains('.'));
    if (usePathStyle) {
      parts.add(bucket);
    }
    parts.addAll(objectParts);
    if (usePathStyle) {
      return _appendPath(endpoint, parts);
    }
    return _appendPath(
      endpoint.replace(host: '$bucket.${endpoint.host}'),
      parts,
    );
  }

  Uri _parseEndpoint(String value, String label) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError('$label必须是完整的 http(s) 地址');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ArgumentError('$label只支持 http 或 https');
    }
    return uri;
  }

  Uri _appendPath(Uri base, Iterable<String> parts) {
    final pathParts = <String>[
      ...base.pathSegments.where((part) => part.isNotEmpty),
      ...parts.expand(_pathParts),
    ];
    return base.replace(pathSegments: pathParts);
  }

  List<String> _pathParts(String path) {
    return path
        .replaceAll('\\', '/')
        .split('/')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && part != '.' && part != '..')
        .toList(growable: false);
  }

  void _validateWebDav(WebDavBackupConfig config) {
    _parseEndpoint(config.url, 'WebDAV 地址');
    if (_pathParts(config.remotePath).isEmpty) {
      throw ArgumentError('WebDAV 远端目录不能为空');
    }
  }

  void _validateS3(S3BackupConfig config) {
    _s3Endpoint(config);
    if (config.region.trim().isEmpty) {
      throw ArgumentError('S3 Region 不能为空');
    }
    if (config.bucket.trim().isEmpty) {
      throw ArgumentError('S3 Bucket 不能为空');
    }
    if (config.accessKey.trim().isEmpty || config.secretKey.isEmpty) {
      throw ArgumentError('S3 Access Key 和 Secret Key 不能为空');
    }
  }

  void _ensureStatus(
    _RemoteResponse response, {
    required Set<int> accepted,
    required String operation,
    required Uri uri,
  }) {
    if (accepted.contains(response.statusCode)) {
      return;
    }
    var detail = '';
    if (response.body.isNotEmpty) {
      detail = '：${_responseMessage(response.body)}';
    }
    throw RemoteBackupException(
      '$operation失败（HTTP ${response.statusCode}$detail）',
      null,
      statusCode: response.statusCode,
      endpoint: uri.toString(),
    );
  }

  String _responseMessage(Uint8List body) {
    final text = utf8.decode(body, allowMalformed: true).trim();
    if (text.isEmpty) {
      return '服务器未返回错误详情';
    }
    return text.length > 240 ? '${text.substring(0, 240)}…' : text;
  }

  String _hostHeader(Uri uri) {
    if (uri.hasPort && uri.port != 80 && uri.port != 443) {
      return '${uri.host}:${uri.port}';
    }
    return uri.host;
  }

  String _canonicalUri(Uri uri) {
    if (uri.path.isEmpty) {
      return '/';
    }
    return uri.pathSegments
        .map(_awsUriEncode)
        .join('/')
        .replaceFirst(RegExp(r'^'), uri.path.startsWith('/') ? '/' : '');
  }

  String _awsUriEncode(String value) {
    const unreserved =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final result = StringBuffer();
    for (final byte in utf8.encode(value)) {
      if (unreserved.codeUnits.contains(byte)) {
        result.writeCharCode(byte);
      } else {
        result.write(
          '%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}',
        );
      }
    }
    return result.toString();
  }

  String _canonicalQuery(Uri uri) {
    final query =
        uri.queryParametersAll.entries
            .expand(
              (entry) => entry.value.map(
                (value) => MapEntry(
                  Uri.encodeQueryComponent(entry.key),
                  Uri.encodeQueryComponent(value),
                ),
              ),
            )
            .toList()
          ..sort((a, b) {
            final keyResult = a.key.compareTo(b.key);
            return keyResult == 0 ? a.value.compareTo(b.value) : keyResult;
          });
    return query.map((entry) => '${entry.key}=${entry.value}').join('&');
  }

  String _normalizeHeaderValue(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _sha256Hex(List<int> data) {
    return sha256.convert(data).toString();
  }

  List<int> _hmac(List<int> key, String value) {
    return Hmac(sha256, key).convert(utf8.encode(value)).bytes;
  }

  String _hmacHex(List<int> key, String value) {
    return _hmac(
      key,
      value,
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  List<int> _deriveSigningKey(String secret, String date, String region) {
    final dateKey = _hmac(utf8.encode('AWS4$secret'), date);
    final regionKey = _hmac(dateKey, region);
    final serviceKey = _hmac(regionKey, 's3');
    return _hmac(serviceKey, 'aws4_request');
  }

  String _formatAmzDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}'
        '${value.month.toString().padLeft(2, '0')}'
        '${value.day.toString().padLeft(2, '0')}T'
        '${value.hour.toString().padLeft(2, '0')}'
        '${value.minute.toString().padLeft(2, '0')}'
        '${value.second.toString().padLeft(2, '0')}Z';
  }

  String _formatShortDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}'
        '${value.month.toString().padLeft(2, '0')}'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

class RemoteBackupException implements Exception {
  const RemoteBackupException(
    this.message,
    this.originalError, {
    this.statusCode,
    this.endpoint,
  });

  final String message;
  final Object? originalError;
  final int? statusCode;
  final String? endpoint;

  @override
  String toString() => message;
}

class _RemoteResponse {
  const _RemoteResponse(this.statusCode, this.body);

  final int statusCode;
  final Uint8List body;
}
