import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/api_config.dart';

void main() {
  group('parseCustomBodyText', () {
    test('空文本返回空对象', () {
      expect(parseCustomBodyText('   '), isEmpty);
    });

    test('拒绝所有保留字段', () {
      for (final key in kReservedCustomBodyKeys) {
        expect(
          () => parseCustomBodyText('{"$key":true}'),
          throwsFormatException,
          reason: '$key 应被拒绝',
        );
      }
    });

    test('非 JSON 对象抛错', () {
      expect(() => parseCustomBodyText('[1,2,3]'), throwsFormatException);
    });

    test('messages 必须是数组', () {
      expect(() => parseCustomBodyText('{"messages":{}}'), throwsFormatException);
    });

    test('允许普通请求参数', () {
      expect(parseCustomBodyText('{"temperature":0.7,"top_p":0.9}'), {
        'temperature': 0.7,
        'top_p': 0.9,
      });
    });
  });

  group('ResolvedApiConfig.buildRequestBody', () {
    ResolvedApiConfig config(String customBody) => ResolvedApiConfig(
      id: 'provider',
      name: 'provider',
      baseUrl: 'https://example.com/v1',
      apiKey: 'key',
      model: 'demo-model',
      customBody: customBody,
    );

    test('自定义 body 中的 stream 无法覆盖系统设定', () {
      expect(
        () => config('{"stream":true}').buildRequestBody(messages: const []),
        throwsFormatException,
      );
    });

    test('普通自定义参数被合并且系统字段保持生效', () {
      final body = config('{"temperature":0.5}').buildRequestBody(
        messages: const [
          {'role': 'user', 'content': 'hi'},
        ],
        defaults: const {'stream': true},
      );
      expect(body['temperature'], 0.5);
      expect(body['model'], 'demo-model');
      expect(body['stream'], isTrue);
      expect(body['include_usage'], isTrue);
    });

    test('自定义 messages 追加到系统消息之后', () {
      final body = config('{"messages":[{"role":"assistant","content":"a"}]}')
          .buildRequestBody(
            messages: const [
              {'role': 'user', 'content': 'hi'},
            ],
          );
      expect(body['messages'], [
        {'role': 'user', 'content': 'hi'},
        {'role': 'assistant', 'content': 'a'},
      ]);
    });
  });
}
