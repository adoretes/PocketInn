import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_inn/pages/api_request_log_detail_page.dart';
import 'package:pocket_inn/pages/api_request_log_page.dart';
import 'package:pocket_inn/services/api_request_log_service.dart';

void main() {
  ApiRequestLogEntry buildEntry({bool success = true}) {
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
    expect(find.text('请求成功'), findsOneWidget);
    expect(find.text('方法'), findsNothing);
    expect(find.text('请求体'), findsOneWidget);
    expect(find.text('响应'), findsOneWidget);
    expect(find.textContaining('1 条消息', findRichText: true), findsOneWidget);
  });

  testWidgets('失败请求在详情页展示错误信息', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ApiRequestLogDetailPage(entry: buildEntry(success: false)),
      ),
    );

    expect(find.text('请求失败'), findsOneWidget);
    expect(find.text('错误'), findsOneWidget);
    expect(find.text('连接超时'), findsOneWidget);
  });
}
