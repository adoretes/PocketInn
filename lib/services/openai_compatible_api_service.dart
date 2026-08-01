import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/api/openai_chat_completion_chunk.dart';
import '../models/api/openai_chat_completion_response.dart';
import '../models/api/openai_models_response.dart';
import '../models/api_config.dart';
import 'api_request_log_service.dart';
import 'i_openai_api_service.dart';

class ChatCompletionResult {
  const ChatCompletionResult({required this.text, this.thinkingChain});

  final String text;
  final String? thinkingChain;
}

class ChatCompletionProgress {
  const ChatCompletionProgress({
    this.textDelta = '',
    this.thinkingDelta = '',
    this.done = false,
  });

  final String textDelta;
  final String thinkingDelta;
  final bool done;
}

class ChatCompletionCancelToken {
  HttpClient? _client;
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) {
      return;
    }
    _isCancelled = true;
    _client?.close(force: true);
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const ChatCompletionCancelledException();
    }
  }

  void _attach(HttpClient client) {
    _client = client;
    if (_isCancelled) {
      client.close(force: true);
    }
  }

  void _detach(HttpClient client) {
    if (identical(_client, client)) {
      _client = null;
    }
  }
}

class ChatCompletionCancelledException implements Exception {
  const ChatCompletionCancelledException();

  @override
  String toString() => '请求已终止';
}

class ApiConnectionTestResult {
  const ApiConnectionTestResult({
    required this.success,
    required this.message,
    this.isPartial = false,
    this.modelCount,
  });

  final bool success;
  final String message;
  final bool isPartial;
  final int? modelCount;
}

class FetchedModelInfo {
  const FetchedModelInfo({
    required this.modelId,
    this.ownedBy,
    this.object,
  });

  final String modelId;
  final String? ownedBy;
  final String? object;
}

class _CachedFetchedModels {
  final List<FetchedModelInfo> models;
  final DateTime fetchedAt;

  _CachedFetchedModels({required this.models, required this.fetchedAt});

  bool isExpiredFor(Duration cacheDuration) =>
      DateTime.now().difference(fetchedAt) > cacheDuration;
}

class OpenAICompatibleApiService implements IOpenAiApiService {
  OpenAICompatibleApiService._();

  static final OpenAICompatibleApiService instance =
      OpenAICompatibleApiService._();

  // 建立连接 / 短请求（models、连通性测试）的超时。
  static const Duration _connectionTimeout = Duration(seconds: 12);
  // 聊天补全请求等待响应头的超时，推理类模型首字节可能需要较长时间。
  static const Duration _chatCompletionTimeout = Duration(seconds: 120);
  // 流式响应中相邻两次数据之间的空闲超时，超过则视为卡住。
  static const Duration _streamIdleTimeout = Duration(seconds: 60);

  // 拉取模型列表缓存时长
  static const Duration _modelsCacheDuration = Duration(minutes: 5);

  // 拉取模型列表缓存，key 为 baseUrl|apiKey
  final Map<String, _CachedFetchedModels> _modelsFetchCache = {};

  @override
  Future<List<FetchedModelInfo>> fetchModels(ResolvedApiConfig config) async {
    _validateConfig(config);
    final cacheKey = '${config.baseUrl.trim()}|${config.apiKey.trim()}';
    final cached = _modelsFetchCache[cacheKey];
    if (cached != null && !cached.isExpiredFor(_modelsCacheDuration)) {
      return cached.models;
    }

    final uri = _buildUri(config.baseUrl, 'models');

    final response = await _sendJson(
      'GET',
      uri,
      headers: _buildHeaders(config),
    );

    final statusCode = response.statusCode;
    final bodyText = response.body;
    if (statusCode < 200 || statusCode >= 300) {
      throw HttpException(
        '拉取模型失败，HTTP $statusCode${bodyText.trim().isEmpty ? '' : ': ${_truncate(bodyText.trim())}'}',
      );
    }

    final OpenAIModelsResponse modelsResponse;
    try {
      final decoded = jsonDecode(bodyText);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('模型接口返回不是合法 JSON 对象');
      }
      modelsResponse = OpenAIModelsResponse.fromJson(decoded);
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('模型接口返回解析失败: $error');
    }

    final seen = <String>{};
    final models = modelsResponse.data
        .where((item) => item.id.trim().isNotEmpty && seen.add(item.id.trim()))
        .map((item) => FetchedModelInfo(
              modelId: item.id.trim(),
              ownedBy: item.ownedBy,
              object: item.object,
            ))
        .toList()
      ..sort((a, b) => a.modelId.compareTo(b.modelId));

    _modelsFetchCache[cacheKey] = _CachedFetchedModels(
      models: models,
      fetchedAt: DateTime.now(),
    );
    return models;
  }

  @override
  Future<ApiConnectionTestResult> testConnection(ResolvedApiConfig config) async {
    try {
      _validateConfig(config);
      if (config.model.trim().isNotEmpty) {
        await _probeChatCompletion(config);
        return const ApiConnectionTestResult(
          success: true,
          message: '测试成功，当前模型可完成最小请求',
        );
      }

      final reachability = await _probeReachability(config);
      return ApiConnectionTestResult(
        success: reachability.success,
        isPartial: reachability.success,
        message: reachability.success
            ? '基础连通正常，但未填写 Model，尚未验证实际推理可用性'
            : reachability.message,
      );
    } on FormatException catch (error) {
      return ApiConnectionTestResult(success: false, message: error.message);
    } on TimeoutException {
      return const ApiConnectionTestResult(
        success: false,
        message: '请求超时，请检查 Base URL 或网络连接',
      );
    } on SocketException catch (error) {
      return ApiConnectionTestResult(
        success: false,
        message: '网络异常: ${error.message}',
      );
    } on HandshakeException {
      return const ApiConnectionTestResult(
        success: false,
        message: 'TLS 握手失败，请检查 HTTPS 证书或代理设置',
      );
    } on HttpException catch (error) {
      return ApiConnectionTestResult(success: false, message: error.message);
    } on Object catch (error) {
      return ApiConnectionTestResult(success: false, message: '联通失败: $error');
    }
  }

  @override
  Future<ChatCompletionResult> createChatCompletion(
    ResolvedApiConfig config, {
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? defaults,
    ChatCompletionCancelToken? cancellationToken,
  }) async {
    _validateConfig(config);
    if (config.model.trim().isEmpty) {
      throw const FormatException('Model 不能为空');
    }
    cancellationToken?.throwIfCancelled();

    final endpoint = _buildUri(config.baseUrl, 'chat/completions');
    final requestBody = config.buildRequestBody(
      messages: messages,
      defaults: defaults,
    );
    final stopwatch = Stopwatch()..start();
    _HttpTextResponse response;
    try {
      response = await _sendJson(
        'POST',
        endpoint,
        headers: _buildHeaders(config),
        body: requestBody,
        cancellationToken: cancellationToken,
        responseTimeout: _chatCompletionTimeout,
      );
    } on ChatCompletionCancelledException {
      rethrow;
    } on Object catch (error) {
      await ApiRequestLogService.instance.append(
        configName: config.name,
        model: config.model,
        method: 'POST',
        endpoint: endpoint.toString(),
        success: false,
        durationMs: stopwatch.elapsedMilliseconds,
        requestBody: _sanitizeJsonValue(requestBody),
        errorMessage: error.toString(),
      );
      rethrow;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await ApiRequestLogService.instance.append(
        configName: config.name,
        model: config.model,
        method: 'POST',
        endpoint: endpoint.toString(),
        success: false,
        durationMs: stopwatch.elapsedMilliseconds,
        statusCode: response.statusCode,
        requestBody: _sanitizeJsonValue(requestBody),
        responseBody: response.body,
        errorMessage:
            '请求失败，HTTP ${response.statusCode}${response.body.trim().isEmpty ? '' : ': ${_truncate(response.body.trim())}'}',
      );
      throw HttpException(
        '请求失败，HTTP ${response.statusCode}${response.body.trim().isEmpty ? '' : ': ${_truncate(response.body.trim())}'}',
      );
    }

    final OpenAIChatCompletionResponse completionResponse;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('聊天接口返回不是合法 JSON 对象');
      }
      completionResponse = OpenAIChatCompletionResponse.fromJson(decoded);
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('聊天接口返回解析失败: $error');
    }

    if (completionResponse.choices.isEmpty) {
      throw const FormatException('聊天接口返回缺少 choices');
    }

    final firstChoice = completionResponse.choices.first;
    final text = firstChoice.resolvedText.trim();
    if (text.isEmpty) {
      throw const FormatException('聊天接口返回了空回复');
    }

    final thinkingChain = firstChoice.resolvedReasoning.trim();
    await ApiRequestLogService.instance.append(
      configName: config.name,
      model: config.model,
      method: 'POST',
      endpoint: endpoint.toString(),
      success: true,
      durationMs: stopwatch.elapsedMilliseconds,
      statusCode: response.statusCode,
      requestBody: _sanitizeJsonValue(requestBody),
      responseBody: response.body,
      usage: completionResponse.usage,
    );
    return ChatCompletionResult(
      text: text,
      thinkingChain: thinkingChain.isEmpty ? null : thinkingChain,
    );
  }

  @override
  Stream<ChatCompletionProgress> createStreamingChatCompletion(
    ResolvedApiConfig config, {
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? defaults,
    ChatCompletionCancelToken? cancellationToken,
  }) async* {
    _validateConfig(config);
    if (config.model.trim().isEmpty) {
      throw const FormatException('Model 不能为空');
    }
    cancellationToken?.throwIfCancelled();

    final client = HttpClient();
    cancellationToken?._attach(client);
    final stopwatch = Stopwatch()..start();
    final responseTextBuffer = StringBuffer();
    final reasoningBuffer = StringBuffer();
    final endpoint = _buildUri(config.baseUrl, 'chat/completions');
    final body = config.buildRequestBody(
      messages: messages,
      defaults: {if (defaults != null) ...defaults, 'stream': true},
    );
    final sanitizedBody = _sanitizeJsonValue(body) as Map<String, dynamic>;
    int? statusCode;
    var failureLogged = false;
    final usage = <String, dynamic>{};
    try {
      cancellationToken?.throwIfCancelled();
      final request = await client
          .openUrl('POST', endpoint)
          .timeout(_connectionTimeout);
      _buildHeaders(config).forEach(request.headers.set);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.add(utf8.encode(jsonEncode(sanitizedBody)));

      cancellationToken?.throwIfCancelled();
      final response = await request.close().timeout(_chatCompletionTimeout);
      statusCode = response.statusCode;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final responseBody = await response.transform(utf8.decoder).join();
        await ApiRequestLogService.instance.append(
          configName: config.name,
          model: config.model,
          method: 'POST',
          endpoint: endpoint.toString(),
          success: false,
          durationMs: stopwatch.elapsedMilliseconds,
          statusCode: response.statusCode,
          requestBody: sanitizedBody,
          responseBody: responseBody,
          errorMessage:
              '请求失败，HTTP ${response.statusCode}${responseBody.trim().isEmpty ? '' : ': ${_truncate(responseBody.trim())}'}',
        );
        failureLogged = true;
        throw HttpException(
          '请求失败，HTTP ${response.statusCode}${responseBody.trim().isEmpty ? '' : ': ${_truncate(responseBody.trim())}'}',
        );
      }

      final lineStream = response
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      final dataLines = <String>[];
      await for (final line in lineStream.timeout(_streamIdleTimeout)) {
        cancellationToken?.throwIfCancelled();
        final trimmedLine = line.trimRight();
        if (trimmedLine.isEmpty) {
          final eventPayload = dataLines.join('\n').trim();
          dataLines.clear();
          if (eventPayload.isEmpty) {
            continue;
          }
          final progress = _parseStreamingEvent(
            eventPayload,
            usageSink: usage,
          );
          if (progress == null) {
            continue;
          }
          if (progress.textDelta.isNotEmpty) {
            responseTextBuffer.write(progress.textDelta);
          }
          if (progress.thinkingDelta.isNotEmpty) {
            reasoningBuffer.write(progress.thinkingDelta);
          }
          yield progress;
          if (progress.done) {
            await ApiRequestLogService.instance.append(
              configName: config.name,
              model: config.model,
              method: 'POST',
              endpoint: endpoint.toString(),
              success: true,
              durationMs: stopwatch.elapsedMilliseconds,
              statusCode: statusCode,
              requestBody: sanitizedBody,
              responseBody: _buildStreamingLogResponse(
                responseTextBuffer.toString(),
                reasoningBuffer.toString(),
              ),
              usage: usage.isEmpty ? null : Map<String, dynamic>.from(usage),
            );
            return;
          }
          continue;
        }

        if (trimmedLine.startsWith('data:')) {
          dataLines.add(trimmedLine.substring(5).trimLeft());
        }
      }

      if (dataLines.isNotEmpty) {
        final progress = _parseStreamingEvent(
          dataLines.join('\n').trim(),
          usageSink: usage,
        );
        if (progress != null) {
          if (progress.textDelta.isNotEmpty) {
            responseTextBuffer.write(progress.textDelta);
          }
          if (progress.thinkingDelta.isNotEmpty) {
            reasoningBuffer.write(progress.thinkingDelta);
          }
          yield progress;
        }
      }
      await ApiRequestLogService.instance.append(
        configName: config.name,
        model: config.model,
        method: 'POST',
        endpoint: endpoint.toString(),
        success: true,
        durationMs: stopwatch.elapsedMilliseconds,
        statusCode: statusCode,
        requestBody: sanitizedBody,
        responseBody: _buildStreamingLogResponse(
          responseTextBuffer.toString(),
          reasoningBuffer.toString(),
        ),
        usage: usage.isEmpty ? null : Map<String, dynamic>.from(usage),
      );
      yield const ChatCompletionProgress(done: true);
    } on ChatCompletionCancelledException {
      rethrow;
    } on Object catch (error) {
      if (cancellationToken?.isCancelled == true) {
        throw const ChatCompletionCancelledException();
      }
      if (!failureLogged) {
        await ApiRequestLogService.instance.append(
          configName: config.name,
          model: config.model,
          method: 'POST',
          endpoint: endpoint.toString(),
          success: false,
          durationMs: stopwatch.elapsedMilliseconds,
          statusCode: statusCode,
          requestBody: sanitizedBody,
          responseBody: _buildStreamingLogResponse(
            responseTextBuffer.toString(),
            reasoningBuffer.toString(),
          ),
          errorMessage: error.toString(),
        );
      }
      rethrow;
    } finally {
      cancellationToken?._detach(client);
      client.close();
    }
  }

  Future<void> _probeChatCompletion(ResolvedApiConfig config) async {
    final body = config.buildRequestBody(
      messages: const [
        {'role': 'user', 'content': 'ping'},
      ],
      defaults: const {'stream': false, 'max_tokens': 1},
    );

    final response = await _sendJson(
      'POST',
      _buildUri(config.baseUrl, 'chat/completions'),
      headers: _buildHeaders(config),
      body: body,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw HttpException(
      '测试失败，HTTP ${response.statusCode}${response.body.trim().isEmpty ? '' : ': ${_truncate(response.body.trim())}'}',
    );
  }

  Future<ApiConnectionTestResult> _probeReachability(ResolvedApiConfig config) async {
    try {
      final response = await _sendJson(
        'GET',
        _buildUri(config.baseUrl, 'models'),
        headers: _buildHeaders(config),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const ApiConnectionTestResult(
          success: true,
          isPartial: true,
          message: '基础连通正常，模型列表接口可访问',
        );
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return ApiConnectionTestResult(
          success: false,
          message: '鉴权失败，HTTP ${response.statusCode}',
        );
      }
      if (response.statusCode == 404 || response.statusCode == 405) {
        return ApiConnectionTestResult(
          success: true,
          isPartial: true,
          message: '基础连通正常，但模型列表接口不可用；未填写 Model，无法继续验证推理可用性',
        );
      }
      return ApiConnectionTestResult(
        success: false,
        message:
            '基础连通检测失败，HTTP ${response.statusCode}${response.body.trim().isEmpty ? '' : ': ${_truncate(response.body.trim())}'}',
      );
    } on HttpException catch (error) {
      return ApiConnectionTestResult(success: false, message: error.message);
    }
  }

  Future<_HttpTextResponse> _sendJson(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
    ChatCompletionCancelToken? cancellationToken,
    Duration responseTimeout = _connectionTimeout,
  }) async {
    final client = HttpClient();
    cancellationToken?._attach(client);
    try {
      cancellationToken?.throwIfCancelled();
      final request = await client
          .openUrl(method, uri)
          .timeout(_connectionTimeout);
      headers.forEach(request.headers.set);
      if (body != null) {
        final sanitizedBody = _sanitizeJsonValue(body) as Map<String, dynamic>;
        request.headers.set('Content-Type', 'application/json; charset=utf-8');
        request.add(utf8.encode(jsonEncode(sanitizedBody)));
      }
      cancellationToken?.throwIfCancelled();
      final response = await request.close().timeout(responseTimeout);
      final responseBody = await response.transform(utf8.decoder).join();
      return _HttpTextResponse(
        statusCode: response.statusCode,
        body: responseBody,
      );
    } on ChatCompletionCancelledException {
      rethrow;
    } on Object {
      if (cancellationToken?.isCancelled == true) {
        throw const ChatCompletionCancelledException();
      }
      rethrow;
    } finally {
      cancellationToken?._detach(client);
      client.close();
    }
  }

  Map<String, String> _buildHeaders(ResolvedApiConfig config) {
    return {
      'Accept': 'application/json',
      if (config.apiKey.trim().isNotEmpty)
        'Authorization': 'Bearer ${config.apiKey.trim()}',
    };
  }

  Uri _buildUri(String baseUrl, String path) {
    final normalized = baseUrl.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Base URL 不能为空');
    }
    final base = normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
    return Uri.parse('$base/$path');
  }

  void _validateConfig(ResolvedApiConfig config) {
    if (config.baseUrl.trim().isEmpty) {
      throw const FormatException('Base URL 不能为空');
    }
    config.parseCustomBody();
  }

  String _truncate(String value, {int maxLength = 120}) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...';
  }

  ChatCompletionProgress? _parseStreamingEvent(
    String data, {
    Map<String, dynamic>? usageSink,
  }) {
    if (data.isEmpty) {
      return null;
    }
    if (data == '[DONE]') {
      return const ChatCompletionProgress(done: true);
    }

    final OpenAIChatCompletionChunk chunk;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final usageRaw = decoded['usage'];
      if (usageRaw is Map) {
        usageSink
          ?..clear()
          ..addAll(Map<String, dynamic>.from(usageRaw));
      }
      chunk = OpenAIChatCompletionChunk.fromJson(decoded);
    } on Object {
      return null;
    }

    if (chunk.choices.isEmpty) {
      return null;
    }

    final choice = chunk.choices.first;
    final textDelta = choice.textDelta;
    final thinkingDelta = choice.reasoningDelta;
    final isDone = choice.isDone;

    if (textDelta.isEmpty && thinkingDelta.isEmpty && !isDone) {
      return null;
    }

    return ChatCompletionProgress(
      textDelta: textDelta,
      thinkingDelta: thinkingDelta,
      done: isDone,
    );
  }

  Object? _sanitizeJsonValue(Object? value) {
    if (value == null || value is num || value is bool) {
      return value;
    }
    if (value is String) {
      return _sanitizeString(value);
    }
    if (value is List) {
      return value.map(_sanitizeJsonValue).toList(growable: false);
    }
    if (value is Map) {
      final sanitized = <String, dynamic>{};
      value.forEach((key, entryValue) {
        sanitized[_sanitizeString(key.toString())] = _sanitizeJsonValue(
          entryValue,
        );
      });
      return sanitized;
    }
    return _sanitizeString(value.toString());
  }

  String _sanitizeString(String input) {
    if (input.isEmpty) {
      return input;
    }

    final buffer = StringBuffer();
    final units = input.codeUnits;
    for (var i = 0; i < units.length; i++) {
      final unit = units[i];
      if (unit >= 0xD800 && unit <= 0xDBFF) {
        if (i + 1 < units.length) {
          final next = units[i + 1];
          if (next >= 0xDC00 && next <= 0xDFFF) {
            buffer.writeCharCode(unit);
            buffer.writeCharCode(next);
            i++;
          }
        }
        continue;
      }
      if (unit >= 0xDC00 && unit <= 0xDFFF) {
        continue;
      }
      buffer.writeCharCode(unit);
    }
    return buffer.toString();
  }

  String _buildStreamingLogResponse(String text, String reasoning) {
    final sections = <String>[];
    final normalizedText = text.trim();
    final normalizedReasoning = reasoning.trim();
    if (normalizedReasoning.isNotEmpty) {
      sections.add('[reasoning]\n$normalizedReasoning');
    }
    if (normalizedText.isNotEmpty) {
      sections.add('[text]\n$normalizedText');
    }
    return sections.join('\n\n');
  }
}

class _HttpTextResponse {
  const _HttpTextResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}
