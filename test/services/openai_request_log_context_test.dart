import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/api_config.dart';
import 'package:pocket_inn/models/prompt_context_entry.dart';
import 'package:pocket_inn/services/api_request_log_service.dart';
import 'package:pocket_inn/services/openai_compatible_api_service.dart';
import 'package:pocket_inn/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_env.dart';

class _CompletionServer {
  _CompletionServer._(this.server) {
    server.listen(_handle);
  }

  final HttpServer server;
  final requests = <Map<String, dynamic>>[];
  int nextStatusCode = HttpStatus.ok;

  static Future<_CompletionServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _CompletionServer._(server);
  }

  String get baseUrl => 'http://127.0.0.1:${server.port}/v1';

  Future<void> _handle(HttpRequest request) async {
    final decoded = jsonDecode(await utf8.decoder.bind(request).join());
    final body = Map<String, dynamic>.from(decoded as Map);
    requests.add(body);

    final statusCode = nextStatusCode;
    nextStatusCode = HttpStatus.ok;
    request.response.statusCode = statusCode;
    if (statusCode < 200 || statusCode >= 300) {
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"error":"fixture failure"}');
      await request.response.close();
      return;
    }

    if (body['stream'] == true) {
      request.response.headers.set('Content-Type', 'text/event-stream');
      request.response.write(
        'data: {"choices":[{"delta":{"content":"ok"},"finish_reason":"stop"}]}\n\n',
      );
    } else {
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'ok'},
              'finish_reason': 'stop',
            },
          ],
        }),
      );
    }
    await request.response.close();
  }

  Future<void> close() => server.close(force: true);
}

void main() {
  final apiService = OpenAICompatibleApiService.instance;
  final logService = ApiRequestLogService.instance;
  late Directory dataDirectory;
  late _CompletionServer server;
  late HttpOverrides? originalHttpOverrides;

  final mainMessages = <Map<String, dynamic>>[
    {'role': 'system', 'content': 'main system'},
    {'role': 'user', 'name': 'Alice', 'content': 'main user'},
  ];
  final customMessages = <Map<String, dynamic>>[
    {'role': 'assistant', 'name': 'tool', 'content': 'custom text'},
    {
      'role': 'tool',
      'name': 'array result',
      'content': [
        {'type': 'text', 'text': 'custom array'},
      ],
    },
    {'role': 'user', 'name': 'null value', 'content': null},
  ];
  final mainContext = <PromptContextEntry>[
    const PromptContextEntry(
      source: PromptContextSource.request,
      role: 'system',
      name: '',
      content: 'main system',
    ),
    const PromptContextEntry(
      source: PromptContextSource.request,
      role: 'user',
      name: 'Alice',
      content: 'main user',
    ),
  ];

  ResolvedApiConfig config() => ResolvedApiConfig(
    id: 'fixture',
    name: '本地 API 测试',
    baseUrl: server.baseUrl,
    apiKey: '',
    model: 'fixture-model',
    customBody: jsonEncode({'messages': customMessages}),
  );

  Future<void> sendRequest({
    required bool streaming,
    required bool succeeds,
    required List<PromptContextEntry> contextEntries,
  }) async {
    await logService.clear();
    server.nextStatusCode = succeeds
        ? HttpStatus.ok
        : HttpStatus.internalServerError;
    final resolvedConfig = config();
    if (streaming) {
      final stream = apiService.createStreamingChatCompletion(
        resolvedConfig,
        messages: mainMessages,
        contextEntries: contextEntries,
      );
      if (succeeds) {
        await stream.drain<void>();
      } else {
        await expectLater(stream.drain<void>(), throwsA(isA<HttpException>()));
      }
    } else if (succeeds) {
      await apiService.createChatCompletion(
        resolvedConfig,
        messages: mainMessages,
        contextEntries: contextEntries,
      );
    } else {
      await expectLater(
        apiService.createChatCompletion(
          resolvedConfig,
          messages: mainMessages,
          contextEntries: contextEntries,
        ),
        throwsA(isA<HttpException>()),
      );
    }
  }

  List<PromptContextEntry> expectedContext() => [
    ...mainContext,
    const PromptContextEntry(
      source: PromptContextSource.request,
      role: 'assistant',
      name: 'tool',
      content: 'custom text',
    ),
    PromptContextEntry(
      source: PromptContextSource.request,
      role: 'tool',
      name: 'array result',
      content: jsonEncode(customMessages[1]['content']),
    ),
    const PromptContextEntry(
      source: PromptContextSource.request,
      role: 'user',
      name: 'null value',
      content: 'null',
    ),
  ];

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    originalHttpOverrides = HttpOverrides.current;
    // Flutter test 默认拦截 HttpClient；本用例需访问 loopback HttpServer。
    HttpOverrides.global = null;
    dataDirectory = setUpPathProviderMocks();
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.initialize();
    await logService.initialize();
    server = await _CompletionServer.start();
  });

  tearDownAll(() async {
    await server.close();
    tearDownPathProviderMocks(dataDirectory);
    HttpOverrides.global = originalHttpOverrides;
  });

  for (final streaming in [false, true]) {
    for (final succeeds in [true, false]) {
      final mode = streaming ? '流式' : '非流式';
      final outcome = succeeds ? '成功' : '失败';
      test('$mode $outcome 日志按请求顺序记录自定义消息上下文', () async {
        await sendRequest(
          streaming: streaming,
          succeeds: succeeds,
          contextEntries: mainContext,
        );

        final log = logService.logsNotifier.value.single;
        expect(log.success, succeeds);
        expect(
          log.context.map((entry) => entry.toJson()).toList(),
          expectedContext().map((entry) => entry.toJson()).toList(),
        );

        final loggedBody = jsonDecode(log.requestBody) as Map<String, dynamic>;
        final sentBody = server.requests.last;
        expect(loggedBody['messages'], sentBody['messages']);
        expect(
          (loggedBody['messages'] as List).length,
          mainMessages.length + customMessages.length,
        );
      });
    }
  }

  for (final streaming in [false, true]) {
    test('${streaming ? '流式' : '非流式'} 空上下文仍保留完整原始请求体回退', () async {
      await sendRequest(
        streaming: streaming,
        succeeds: true,
        contextEntries: const <PromptContextEntry>[],
      );

      final log = logService.logsNotifier.value.single;
      final loggedBody = jsonDecode(log.requestBody) as Map<String, dynamic>;
      expect(log.context, isEmpty);
      expect(loggedBody['messages'], [...mainMessages, ...customMessages]);
    });
  }
}
