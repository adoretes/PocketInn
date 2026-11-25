import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/prompt_context_entry.dart';
import 'package:pocket_inn/models/regex_rule_group.dart';
import 'package:pocket_inn/services/regex_replacement_service.dart';

void main() {
  const service = RegexReplacementService();

  List<RegexRuleGroup> groupsFor(RegexRule rule) => [
    RegexRuleGroup(
      id: 'group',
      name: '测试规则',
      updatedAt: DateTime(2026),
      rules: [rule],
    ),
  ];

  const original = [
    PromptContextEntry(
      source: PromptContextSource.preset,
      role: 'system',
      name: 'Main Prompt',
      content: '保持原样',
    ),
    PromptContextEntry(
      source: PromptContextSource.history,
      role: 'user',
      name: '用户',
      content: 'foo',
    ),
  ];
  const messages = [
    {'role': 'system', 'content': '保持原样'},
    {'role': 'user', 'content': 'foo'},
  ];

  test('发送正则同步正文并保留未修改片段及原来源名称', () {
    final result = service.applyToRequestWithContext(
      messages: messages,
      contextEntries: original,
      groups: groupsFor(
        const RegexRule(
          id: 'send',
          name: '发送',
          findRegex: 'foo',
          replaceString: 'bar',
          applyOnWrite: false,
          applyOnSend: true,
        ),
      ),
    );

    expect(result.messages.last['content'], 'bar');
    expect(result.contextEntries.last.content, 'bar');
    expect(result.contextEntries.last.source, PromptContextSource.history);
    expect(result.contextEntries.last.name, '用户');
    expect(result.contextEntries.first, same(original.first));
    expect(original.last.content, 'foo');
  });

  test('跨来源匹配按合并消息执行且不额外标记正则处理', () {
    const fragments = [
      PromptContextEntry(
        source: PromptContextSource.preset,
        role: 'system',
        name: 'Main',
        content: 'foo',
      ),
      PromptContextEntry(
        source: PromptContextSource.worldBook,
        role: 'system',
        name: '世界书条目',
        content: 'bar',
      ),
      PromptContextEntry(
        source: PromptContextSource.history,
        role: 'user',
        name: '用户',
        content: '你好',
      ),
      PromptContextEntry(
        source: PromptContextSource.preset,
        role: 'system',
        name: '追加提示',
        content: 'tail',
      ),
    ];
    final result = service.applyToRequestWithContext(
      messages: const [
        {'role': 'system', 'content': 'foo\n\nbar'},
        {'role': 'user', 'content': '你好'},
        {'role': 'system', 'content': 'tail'},
      ],
      contextEntries: fragments,
      groups: groupsFor(
        const RegexRule(
          id: 'cross',
          name: '跨来源',
          findRegex: r'foo\s+bar',
          replaceString: 'combined',
          applyToUser: false,
          applyOnWrite: false,
          applyOnSend: true,
        ),
      ),
    );

    expect(result.messages.first['content'], 'combined');
    expect(result.contextEntries, hasLength(3));
    expect(result.contextEntries.first.content, 'combined');
    expect(result.contextEntries.first.name, 'Main / 世界书条目');
    expect(result.contextEntries[1], same(fragments[2]));
    expect(result.contextEntries[2], same(fragments[3]));
  });

  test('深度与角色限制沿用合并后的实际消息序列', () {
    const fragments = [
      PromptContextEntry(
        source: PromptContextSource.history,
        role: 'user',
        name: '用户',
        content: 'foo',
      ),
      PromptContextEntry(
        source: PromptContextSource.history,
        role: 'user',
        name: '用户',
        content: 'foo',
      ),
      PromptContextEntry(
        source: PromptContextSource.history,
        role: 'assistant',
        name: '角色',
        content: 'foo',
      ),
    ];
    final result = service.applyToRequestWithContext(
      messages: const [
        {'role': 'user', 'content': 'foo\n\nfoo'},
        {'role': 'assistant', 'content': 'foo'},
      ],
      contextEntries: fragments,
      groups: groupsFor(
        const RegexRule(
          id: 'depth',
          name: '深度',
          findRegex: 'foo',
          replaceString: 'bar',
          applyToAssistant: false,
          minDepth: 1,
          maxDepth: 1,
          applyOnWrite: false,
          applyOnSend: true,
        ),
      ),
    );

    expect(result.messages.first['content'], 'bar\n\nbar');
    expect(result.contextEntries.first.content, 'bar\n\nbar');
    expect(result.contextEntries.last, same(fragments.last));
    expect(result.messages.last['content'], 'foo');
  });

  test('没有实际发送替换时保留全部来源片段', () {
    final result = service.applyToRequestWithContext(
      messages: messages,
      contextEntries: original,
      groups: groupsFor(
        const RegexRule(
          id: 'display',
          name: '仅显示',
          findRegex: 'foo',
          replaceString: 'bar',
          applyOnWrite: false,
          applyOnDisplay: true,
        ),
      ),
    );
    expect(result.contextEntries, same(original));
    expect(result.messages.last['content'], 'foo');
  });

  test('缺少上下文时保留空列表供完整请求体回退展示', () {
    final result = service.applyToRequestWithContext(
      messages: messages,
      contextEntries: const [],
      groups: groupsFor(
        const RegexRule(
          id: 'send',
          name: '发送',
          findRegex: 'foo',
          replaceString: 'bar',
          applyOnWrite: false,
          applyOnSend: true,
        ),
      ),
    );
    expect(result.contextEntries, isEmpty);
    expect(result.messages.last['content'], 'bar');
  });

  test('来源无法对应实际消息时完整记录最终消息且不保留旧正文', () {
    final result = service.applyToRequestWithContext(
      messages: messages,
      contextEntries: [original.first],
      groups: groupsFor(
        const RegexRule(
          id: 'send',
          name: '发送',
          findRegex: 'foo',
          replaceString: 'bar',
          applyOnWrite: false,
          applyOnSend: true,
        ),
      ),
    );
    expect(result.contextEntries.map((entry) => entry.content), [
      '保持原样',
      'bar',
    ]);
    expect(result.contextEntries.every((entry) => entry.name.isEmpty), isTrue);
    expect(
      result.contextEntries.every(
        (entry) => entry.source == PromptContextSource.request,
      ),
      isTrue,
    );
  });

  test('正文被规则删除时记录空正文而非原始内容', () {
    final result = service.applyToRequestWithContext(
      messages: messages,
      contextEntries: original,
      groups: groupsFor(
        const RegexRule(
          id: 'remove',
          name: '删除',
          findRegex: 'foo',
          replaceString: '',
          applyOnWrite: false,
          applyOnSend: true,
        ),
      ),
    );
    expect(result.messages.last['content'], '');
    expect(result.contextEntries.last.content, '');
  });
}
