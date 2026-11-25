import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_inn/models/prompt_context_entry.dart';
import 'package:pocket_inn/pages/api_request_log_detail_page.dart';
import 'package:pocket_inn/pages/api_request_log_page.dart';
import 'package:pocket_inn/services/api_request_log_service.dart';

void main() {
  ApiRequestLogEntry buildEntry({
    bool success = true,
    bool withContext = true,
  }) {
    return ApiRequestLogEntry(
      id: 'log-1',
      timestamp: DateTime(2026, 11, 24, 20, 30, 15),
      configName: '测试配置',
      model: 'deepseek-chat',
      method: 'POST',
      endpoint: 'https://api.example.com/v1/chat/completions',
      requestBody:
          '{\n'
          '  "model": "deepseek-chat",\n'
          '  "messages": [\n'
          '    {\n'
          '      "role": "user",\n'
          '      "content": "你好"\n'
          '    }\n'
          '  ]\n'
          '}',
      responseBody: '{"id":"chatcmpl-1"}',
      success: success,
      durationMs: 1234,
      statusCode: success ? 200 : 500,
      errorMessage: success ? null : '连接超时',
      usage: const {
        'prompt_tokens': 10,
        'completion_tokens': 20,
        'total_tokens': 30,
      },
      context: withContext
          ? const [
              PromptContextEntry(
                source: PromptContextSource.preset,
                role: 'system',
                name: 'Main Prompt',
                content: '你是一个测试助手。',
              ),
              PromptContextEntry(
                source: PromptContextSource.history,
                role: 'user',
                name: '测试用户',
                content: '你好',
              ),
            ]
          : const [],
    );
  }

  tearDown(() {
    ApiRequestLogService.instance.logsNotifier.value =
        const <ApiRequestLogEntry>[];
  });

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  test('日志条目序列化保留上下文', () {
    final restored = ApiRequestLogEntry.fromJson(buildEntry().toJson());

    expect(restored.context, hasLength(2));
    expect(restored.context.first.source, PromptContextSource.preset);
    expect(restored.context.first.role, 'system');
    expect(restored.context.first.name, 'Main Prompt');
    expect(restored.context.first.content, '你是一个测试助手。');
  });

  testWidgets('列表只展示摘要，点击后进入单独的详情页', (tester) async {
    useTallSurface(tester);
    ApiRequestLogService.instance.logsNotifier.value = [buildEntry()];

    await tester.pumpWidget(const MaterialApp(home: ApiRequestLogPage()));

    expect(find.text('测试配置'), findsOneWidget);
    expect(find.textContaining('HTTP 200'), findsOneWidget);
    // 暂只支持 POST chat/completions，列表不再展示方法与路径。
    expect(find.textContaining('POST'), findsNothing);
    expect(find.textContaining('/v1/chat/completions'), findsNothing);
    // 列表页不应再展开请求体等详情内容。
    expect(find.text('请求详情'), findsNothing);
    expect(find.text('请求体'), findsNothing);

    await tester.tap(find.text('测试配置'));
    await tester.pumpAndSettle();

    expect(find.text('请求详情'), findsOneWidget);
    expect(find.text('上下文'), findsOneWidget);
    expect(find.text('原始请求'), findsOneWidget);
    // 默认展示上下文流：来源、role 与正文直接可见。
    expect(find.text('预设'), findsOneWidget);
    expect(find.text('system'), findsOneWidget);
    expect(find.text('Main Prompt'), findsOneWidget);
    expect(find.text('你是一个测试助手。'), findsOneWidget);
    // 请求体等原始内容收进「原始请求」页。
    expect(find.text('请求体'), findsNothing);

    await tester.tap(find.text('原始请求'));
    await tester.pumpAndSettle();

    expect(find.textContaining('HTTP 200'), findsOneWidget);
    expect(find.textContaining('耗时'), findsOneWidget);
    expect(find.text('方法'), findsNothing);
    expect(find.text('请求体'), findsOneWidget);
    expect(find.text('响应'), findsOneWidget);
    expect(find.textContaining('1 条消息', findRichText: true), findsOneWidget);
  });

  testWidgets('旧日志没有上下文时按请求体消息展示', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ApiRequestLogDetailPage(entry: buildEntry(withContext: false)),
      ),
    );

    expect(find.text('请求消息'), findsNWidgets(1));
    expect(find.text('user'), findsOneWidget);
    expect(find.text('你好'), findsOneWidget);
    expect(find.textContaining('未记录来源信息'), findsOneWidget);
  });

  testWidgets('失败请求在详情页展示错误信息', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ApiRequestLogDetailPage(entry: buildEntry(success: false)),
      ),
    );

    expect(find.text('上下文'), findsOneWidget);
    expect(find.text('请求失败'), findsNothing);

    await tester.tap(find.text('原始请求'));
    await tester.pumpAndSettle();

    expect(find.textContaining('HTTP 500'), findsOneWidget);
    expect(find.text('错误'), findsOneWidget);
    expect(find.text('连接超时'), findsOneWidget);
  });
}
