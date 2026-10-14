import 'dart:convert';

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

  group('resolveCustomHeaders', () {
    test('空列表与全空占位行返回空对象', () {
      expect(resolveCustomHeaders(const []), isEmpty);
      expect(
        resolveCustomHeaders(const [
          ApiCustomHeader(name: '  ', value: ''),
          ApiCustomHeader(),
        ]),
        isEmpty,
      );
    });

    test('拒绝所有保留头（大小写不敏感）', () {
      for (final reserved in kReservedCustomHeaderNames) {
        for (final name in [reserved, reserved.toUpperCase()]) {
          expect(
            () => resolveCustomHeaders([
              ApiCustomHeader(name: name, value: 'x'),
            ]),
            throwsFormatException,
            reason: '$name 应被拒绝',
          );
        }
      }
    });

    test('名称非法时抛错', () {
      expect(
        () => resolveCustomHeaders(const [
          ApiCustomHeader(name: 'X Bad Header', value: 'x'),
        ]),
        throwsFormatException,
      );
    });

    test('名称重复（忽略大小写）时抛错', () {
      expect(
        () => resolveCustomHeaders(const [
          ApiCustomHeader(name: 'X-Trace', value: 'a'),
          ApiCustomHeader(name: 'x-trace', value: 'b'),
        ]),
        throwsFormatException,
      );
    });

    test('值为空或含换行时抛错', () {
      expect(
        () => resolveCustomHeaders(const [
          ApiCustomHeader(name: 'X-Trace', value: '  '),
        ]),
        throwsFormatException,
      );
      expect(
        () => resolveCustomHeaders(const [
          ApiCustomHeader(name: 'X-Trace', value: 'a\nb'),
        ]),
        throwsFormatException,
      );
    });

    test('只填值未填名称时抛错', () {
      expect(
        () => resolveCustomHeaders(const [ApiCustomHeader(value: 'x')]),
        throwsFormatException,
      );
    });

    test('保留原始大小写并维持输入顺序', () {
      final headers = resolveCustomHeaders(const [
        ApiCustomHeader(name: 'X-Api-Version', value: ' 2024-01 '),
        ApiCustomHeader(name: 'X-Org-Id', value: 'org-1'),
      ]);
      expect(headers.keys.toList(), ['X-Api-Version', 'X-Org-Id']);
      expect(headers['X-Api-Version'], '2024-01');
    });
  });

  group('ResolvedApiConfig.customHeadersMap', () {
    test('透传 provider 自定义头并归一化', () {
      final config = ResolvedApiConfig(
        id: 'provider',
        name: 'provider',
        baseUrl: 'https://example.com/v1',
        apiKey: 'key',
        model: 'demo-model',
        customHeaders: const [
          ApiCustomHeader(name: 'X-Trace', value: 'abc'),
        ],
      );
      expect(config.customHeadersMap(), {'X-Trace': 'abc'});
    });
  });

  group('ApiConfig 序列化', () {
    test('customHeaders 可往返序列化', () {
      const config = ApiConfig(
        id: 'provider',
        name: 'provider',
        baseUrl: 'https://example.com/v1',
        apiKey: '',
        customHeaders: [
          ApiCustomHeader(name: 'X-Trace', value: 'abc'),
        ],
      );
      // 经 jsonEncode / jsonDecode 还原，模拟真实落盘再读取的路径。
      final restored = ApiConfig.fromJson(
        jsonDecode(jsonEncode(config.toJson())) as Map<String, dynamic>,
      );
      expect(restored.customHeaders, config.customHeaders);
    });

    test('缺少 customHeaders 字段时按空列表处理', () {
      final restored = ApiConfig.fromJson({
        'id': 'provider',
        'name': 'provider',
        'baseUrl': 'https://example.com/v1',
        'apiKey': '',
        'models': <dynamic>[],
      });
      expect(restored.customHeaders, isEmpty);
    });

    test('resolve 把 customHeaders 透传到 ResolvedApiConfig', () {
      const config = ApiConfig(
        id: 'provider',
        name: 'provider',
        baseUrl: 'https://example.com/v1',
        apiKey: '',
        customHeaders: [
          ApiCustomHeader(name: 'X-Trace', value: 'abc'),
        ],
      );
      final resolved = config.resolve(
        const ApiModel(id: 'm1', modelId: 'demo-model'),
      );
      expect(resolved.customHeaders, config.customHeaders);
    });
  });
}
