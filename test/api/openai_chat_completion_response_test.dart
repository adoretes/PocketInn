import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/api/openai_chat_completion_chunk.dart';
import 'package:pocket_inn/models/api/openai_chat_completion_response.dart';
import 'package:pocket_inn/models/api/openai_models_response.dart';

void main() {
  group('OpenAIChatCompletionResponse', () {
    test('解析 OpenAI 官方响应', () {
      const json = <String, dynamic>{
        'id': 'chatcmpl-abc123',
        'object': 'chat.completion',
        'model': 'gpt-4o-mini',
        'choices': [
          {
            'index': 0,
            'message': {'role': 'assistant', 'content': 'Hello, world!'},
            'finish_reason': 'stop',
          },
        ],
        'usage': {
          'prompt_tokens': 10,
          'completion_tokens': 5,
          'total_tokens': 15,
        },
      };

      final response = OpenAIChatCompletionResponse.fromJson(json);
      expect(response.id, 'chatcmpl-abc123');
      expect(response.model, 'gpt-4o-mini');
      expect(response.choices, hasLength(1));

      final choice = response.choices.first;
      expect(choice.index, 0);
      expect(choice.finishReason, 'stop');
      expect(choice.message?.role, 'assistant');
      expect(choice.resolvedText, 'Hello, world!');
      expect(choice.resolvedReasoning, isEmpty);
    });

    test('解析 DeepSeek/兼容网关的 reasoning_content 字段', () {
      const json = <String, dynamic>{
        'id': 'chatcmpl-deepseek',
        'model': 'deepseek-chat',
        'choices': [
          {
            'index': 0,
            'message': {
              'role': 'assistant',
              'content': '最终答案',
              'reasoning_content': '我先思考一下',
            },
            'finish_reason': 'stop',
          },
        ],
      };

      final response = OpenAIChatCompletionResponse.fromJson(json);
      final choice = response.choices.first;
      expect(choice.resolvedText, '最终答案');
      expect(choice.resolvedReasoning, '我先思考一下');
    });

    test('兼容 reasoning/thinking 多字段名', () {
      const json = <String, dynamic>{
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': '回复',
              'thinking': '思考链',
            },
          },
        ],
      };

      final response = OpenAIChatCompletionResponse.fromJson(json);
      final choice = response.choices.first;
      expect(choice.resolvedReasoning, '思考链');
    });

    test('兼容数组形态的 content', () {
      const json = <String, dynamic>{
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': [
                {'type': 'text', 'text': '分段一'},
                {'type': 'text', 'text': '分段二'},
              ],
            },
          },
        ],
      };

      final response = OpenAIChatCompletionResponse.fromJson(json);
      final choice = response.choices.first;
      expect(choice.resolvedText, '分段一\n分段二');
    });

    test('空 choices 时仍能解析（由调用方校验）', () {
      const json = <String, dynamic>{
        'id': 'chatcmpl-empty',
        'choices': <Map<String, dynamic>>[],
      };

      final response = OpenAIChatCompletionResponse.fromJson(json);
      expect(response.choices, isEmpty);
    });

    test('refusal 字段作为内容回退', () {
      const json = <String, dynamic>{
        'choices': [
          {
            'message': {'role': 'assistant', 'refusal': '我无法回答'},
          },
        ],
      };

      final response = OpenAIChatCompletionResponse.fromJson(json);
      final choice = response.choices.first;
      expect(choice.resolvedText, '我无法回答');
    });

    test('choice.text 字段兼容（无 message 时）', () {
      const json = <String, dynamic>{
        'choices': [
          {'index': 0, 'text': '兼容文本'},
        ],
      };

      final response = OpenAIChatCompletionResponse.fromJson(json);
      final choice = response.choices.first;
      expect(choice.resolvedText, '兼容文本');
    });
  });

  group('OpenAIChatCompletionChunk', () {
    test('解析标准流式 chunk', () {
      const json = <String, dynamic>{
        'id': 'chatcmpl-stream',
        'choices': [
          {
            'index': 0,
            'delta': {'role': 'assistant', 'content': '你好'},
          },
        ],
      };

      final chunk = OpenAIChatCompletionChunk.fromJson(json);
      final choice = chunk.choices.first;
      expect(choice.textDelta, '你好');
      expect(choice.reasoningDelta, isEmpty);
      expect(choice.isDone, isFalse);
    });

    test('解析流式 reasoning 增量', () {
      const json = <String, dynamic>{
        'choices': [
          {
            'delta': {'reasoning': '思考增量'},
          },
        ],
      };

      final chunk = OpenAIChatCompletionChunk.fromJson(json);
      final choice = chunk.choices.first;
      expect(choice.reasoningDelta, '思考增量');
    });

    test('finish_reason 标记结束', () {
      final json = <String, dynamic>{
        'choices': [
          <String, dynamic>{
            'delta': <String, dynamic>{},
            'finish_reason': 'stop',
          },
        ],
      };

      final chunk = OpenAIChatCompletionChunk.fromJson(json);
      final choice = chunk.choices.first;
      expect(choice.isDone, isTrue);
      expect(choice.textDelta, isEmpty);
      expect(choice.reasoningDelta, isEmpty);
    });
  });

  group('OpenAIModelsResponse', () {
    test('解析模型列表', () {
      const json = <String, dynamic>{
        'object': 'list',
        'data': [
          {'id': 'gpt-4o', 'object': 'model', 'owned_by': 'openai'},
          {'id': 'gpt-4o-mini', 'object': 'model', 'owned_by': 'openai'},
        ],
      };

      final response = OpenAIModelsResponse.fromJson(json);
      expect(response.data, hasLength(2));
      expect(response.data.first.id, 'gpt-4o');
      expect(response.data.first.ownedBy, 'openai');
      expect(response.data.last.id, 'gpt-4o-mini');
    });

    test('空 data 字段解析为空列表', () {
      const json = <String, dynamic>{'object': 'list'};

      final response = OpenAIModelsResponse.fromJson(json);
      expect(response.data, isEmpty);
    });
  });
}
