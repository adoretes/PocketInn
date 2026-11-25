import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/chat_message.dart';
import 'package:pocket_inn/models/preset.dart';
import 'package:pocket_inn/models/prompt_assembly.dart';
import 'package:pocket_inn/models/prompt_context_entry.dart';
import 'package:pocket_inn/models/world_book.dart';
import 'package:pocket_inn/services/prompt_assembler.dart';

void main() {
  group('PromptAssembler', () {
    test('replaces variables across prompt and world book content', () {
      final result = PromptAssembler.build(
        PromptAssemblyContext(
          characterName: '艾琳',
          characterCardData: _cardData(),
          userName: '林澈',
          userSettingPrompt: '我是{{user}}。',
          preset: Preset(
            id: 'preset-1',
            name: '测试预设',
            updatedAt: DateTime(2026),
            prompts: [
              PresetPrompt(
                identifier: 'main',
                name: 'Main',
                content: 'Write for {{char}} with {{user}}.',
              ),
              PresetPrompt(
                identifier: 'worldInfoBefore',
                name: 'World Before',
                marker: true,
              ),
            ],
          ),
          selectedWorldBooks: [
            WorldBook(
              id: 'wb-1',
              name: '世界书',
              description: '',
              colorValue: 0xFF000000,
              entries: [
                const WorldBookEntry(
                  id: 'entry-1',
                  key: ['溪桥'],
                  keysecondary: [],
                  content: '{{char}}正在与{{user}}交谈。',
                  comment: '桥',
                  constant: false,
                  selective: false,
                  selectiveLogic: 0,
                  order: 10,
                  position: 0,
                  depth: 4,
                  sticky: 0,
                  cooldown: 0,
                  delay: 0,
                  isEnabled: true,
                  extensions: {},
                ),
              ],
            ),
          ],
          chatMessages: [ChatMessage(text: '我们去溪桥吧', isMe: true)],
          currentInput: '',
        ),
      );

      expect(result.mergedText, contains('Write for 艾琳 with 林澈.'));
      expect(result.mergedText, contains('艾琳正在与林澈交谈。'));
    });

    test('角色卡 system_prompt 与 post_history_instructions 覆盖对应预设提示词', () {
      final result = PromptAssembler.build(
        PromptAssemblyContext(
          characterName: '艾琳',
          characterCardData: _cardData(
            systemPrompt: '角色卡 main',
            postHistoryInstructions: '角色卡 history',
          ),
          userName: '林澈',
          userSettingPrompt: '',
          preset: Preset(
            id: 'preset-1',
            name: '测试预设',
            updatedAt: DateTime(2026),
            prompts: [
              PresetPrompt(
                identifier: 'main',
                name: 'Main',
                content: '预设 main',
              ),
              PresetPrompt(
                identifier: 'jailbreak',
                name: 'Jailbreak',
                content: '预设 jailbreak',
              ),
            ],
          ),
          selectedWorldBooks: const [],
          chatMessages: const [],
          currentInput: '',
        ),
      );

      expect(result.mergedText, contains('角色卡 main'));
      expect(result.mergedText, contains('角色卡 history'));
      expect(result.mergedText, isNot(contains('预设 main')));
      expect(result.mergedText, isNot(contains('预设 jailbreak')));
      expect(result.unusedCharacterOverrides, isEmpty);
    });

    test('覆盖字段可用 {{preset}} 引用被覆盖的预设原文', () {
      final result = PromptAssembler.build(
        PromptAssemblyContext(
          characterName: '艾琳',
          characterCardData: _cardData(
            systemPrompt: '{{preset}}\n追加要求：更短。',
            postHistoryInstructions: '{{preset}} / 结尾补一句环境描写。',
          ),
          userName: '林澈',
          userSettingPrompt: '',
          preset: Preset(
            id: 'preset-1',
            name: '测试预设',
            updatedAt: DateTime(2026),
            prompts: [
              PresetPrompt(
                identifier: 'main',
                name: 'Main',
                content: '{{char}} 的预设 main',
              ),
              PresetPrompt(
                identifier: 'jailbreak',
                name: 'Jailbreak',
                content: '预设 jailbreak',
              ),
            ],
          ),
          selectedWorldBooks: const [],
          chatMessages: const [],
          currentInput: '',
        ),
      );

      expect(result.mergedText, contains('艾琳 的预设 main'));
      expect(result.mergedText, contains('追加要求：更短。'));
      expect(result.mergedText, contains('预设 jailbreak / 结尾补一句环境描写。'));
      expect(result.mergedText, isNot(contains('{{preset}}')));
      expect(result.unusedCharacterOverrides, isEmpty);
    });

    test('jailbreak 与 post_history_instructions 同时存在时只覆盖第一条', () {
      final result = PromptAssembler.build(
        PromptAssemblyContext(
          characterName: '艾琳',
          characterCardData: _cardData(postHistoryInstructions: '角色卡 history'),
          userName: '林澈',
          userSettingPrompt: '',
          preset: Preset(
            id: 'preset-1',
            name: '测试预设',
            updatedAt: DateTime(2026),
            prompts: [
              PresetPrompt(
                identifier: 'jailbreak',
                name: 'Jailbreak',
                content: '预设 jailbreak',
              ),
              PresetPrompt(
                identifier: 'post_history_instructions',
                name: 'Post-History Instructions',
                content: '预设 PHI',
              ),
            ],
          ),
          selectedWorldBooks: const [],
          chatMessages: const [],
          currentInput: '',
        ),
      );

      expect(result.mergedText, contains('角色卡 history'));
      expect(result.mergedText, isNot(contains('预设 jailbreak')));
      expect(result.mergedText, contains('预设 PHI'));
      expect('角色卡 history'.allMatches(result.mergedText).length, 1);
    });

    test('预设中缺少对应提示词时记录为未生效', () {
      final result = PromptAssembler.build(
        PromptAssemblyContext(
          characterName: '艾琳',
          characterCardData: _cardData(
            systemPrompt: '角色卡 main',
            postHistoryInstructions: '角色卡 history',
          ),
          userName: '林澈',
          userSettingPrompt: '',
          preset: Preset(
            id: 'preset-1',
            name: '测试预设',
            updatedAt: DateTime(2026),
            prompts: [
              PresetPrompt(
                identifier: 'main',
                name: 'Main',
                content: '预设 main',
                enabled: false,
              ),
            ],
          ),
          selectedWorldBooks: const [],
          chatMessages: const [],
          currentInput: '',
        ),
      );

      expect(result.mergedText, isEmpty);
      expect(
        result.unusedCharacterOverrides.map((item) => item.field),
        containsAll(['system_prompt', 'post_history_instructions']),
      );
      expect(
        result.unusedCharacterOverrides.map((item) => item.reason).join(),
        contains('未生效'),
      );
    });

    test('resolves setvar getvar comment and trim macros in prompt order', () {
      final result = PromptAssembler.build(
        PromptAssemblyContext(
          characterName: '艾琳',
          characterCardData: _cardData(),
          userName: '林澈',
          userSettingPrompt: '',
          preset: Preset(
            id: 'preset-1',
            name: '测试预设',
            updatedAt: DateTime(2026),
            prompts: [
              PresetPrompt(
                identifier: 'setter',
                name: 'Setter',
                content: '{{setvar::wordsCloud::不少于1000}}{{// 备注不会发送}}{{trim}}',
              ),
              PresetPrompt(
                identifier: 'reader',
                name: 'Reader',
                content: '长度要求：{{getvar::wordsCloud}}',
              ),
            ],
          ),
          selectedWorldBooks: const [],
          chatMessages: const [],
          currentInput: '',
        ),
      );

      expect(result.segments, hasLength(1));
      expect(result.segments.single.identifier, 'reader');
      expect(result.mergedText, contains('长度要求：不少于1000'));
      expect(result.mergedText, isNot(contains('setvar')));
      expect(result.mergedText, isNot(contains('备注不会发送')));
    });

    test('getstate 展开全部注入的状态变量，无变量时为空', () {
      Preset buildPreset() => Preset(
        id: 'preset-1',
        name: '测试预设',
        updatedAt: DateTime(2026),
        prompts: [
          PresetPrompt(
            identifier: 'main',
            name: 'Main',
            content: '当前状态：\n{{getstate}}',
          ),
        ],
      );

      final withVars = PromptAssembler.build(
        PromptAssemblyContext(
          characterName: '艾琳',
          characterCardData: _cardData(),
          userName: '林澈',
          userSettingPrompt: '',
          preset: buildPreset(),
          selectedWorldBooks: const [],
          chatMessages: const [],
          currentInput: '',
          chatVariables: const {'好感度': '85', '心情': '心动'},
        ),
      );
      expect(withVars.mergedText, contains('好感度: 85'));
      expect(withVars.mergedText, contains('心情: 心动'));

      final withoutVars = PromptAssembler.build(
        PromptAssemblyContext(
          characterName: '艾琳',
          characterCardData: _cardData(),
          userName: '林澈',
          userSettingPrompt: '',
          preset: buildPreset(),
          selectedWorldBooks: const [],
          chatMessages: const [],
          currentInput: '',
        ),
      );
      expect(withoutVars.mergedText, isNot(contains('好感度')));
      expect(withoutVars.mergedText, contains('当前状态：'));
    });

    test('getvar 按 trim + 忽略大小写解析变量名', () {
      final result = PromptAssembler.build(
        PromptAssemblyContext(
          characterName: '艾琳',
          characterCardData: _cardData(),
          userName: '林澈',
          userSettingPrompt: '',
          preset: Preset(
            id: 'preset-1',
            name: '测试预设',
            updatedAt: DateTime(2026),
            prompts: [
              PresetPrompt(
                identifier: 'main',
                name: 'Main',
                content: 'HP={{getvar::hp}} | 心情={{getvar:: 心情 }}',
              ),
            ],
          ),
          selectedWorldBooks: const [],
          chatMessages: const [],
          currentInput: '',
          chatVariables: const {'HP': '80', '心情': '平静'},
        ),
      );

      expect(result.mergedText, contains('HP=80'));
      expect(result.mergedText, contains('心情=平静'));
    });

    test('resolves input lastusermessage and lastcharmessage macros', () {
      final result = PromptAssembler.build(
        PromptAssemblyContext(
          characterName: '艾琳',
          characterCardData: _cardData(),
          userName: '林澈',
          userSettingPrompt: '',
          preset: Preset(
            id: 'preset-1',
            name: '测试预设',
            updatedAt: DateTime(2026),
            prompts: [
              PresetPrompt(
                identifier: 'main',
                name: 'Main',
                content:
                    'I={{input}} | LU={{lastusermessage}} | LC={{lastcharmessage}}',
              ),
            ],
          ),
          selectedWorldBooks: const [],
          chatMessages: [
            ChatMessage(text: '第一句', isMe: true),
            ChatMessage(text: '第二句', isMe: false),
            ChatMessage(text: '第三句', isMe: true),
          ],
          currentInput: '当前输入',
        ),
      );

      expect(result.mergedText, contains('I=当前输入 | LU=当前输入 | LC=第二句'));
    });

    test(
      'scans world book triggers only from chat history and current input',
      () {
        final result = PromptAssembler.build(
          PromptAssemblyContext(
            characterName: '艾琳',
            characterCardData: _cardData(description: '这里提到禁书库'),
            userName: '林澈',
            userSettingPrompt: '用户设定中提到禁书库',
            preset: Preset(
              id: 'preset-1',
              name: '测试预设',
              updatedAt: DateTime(2026),
              prompts: [
                PresetPrompt(
                  identifier: 'worldInfoBefore',
                  name: 'World Before',
                  marker: true,
                ),
              ],
            ),
            selectedWorldBooks: [
              WorldBook(
                id: 'wb-1',
                name: '世界书',
                description: '',
                colorValue: 0xFF000000,
                entries: [
                  const WorldBookEntry(
                    id: 'entry-1',
                    key: ['禁书库'],
                    keysecondary: [],
                    content: '命中禁书库',
                    comment: '禁书库',
                    constant: false,
                    selective: false,
                    selectiveLogic: 0,
                    order: 10,
                    position: 0,
                    depth: 4,
                    sticky: 0,
                    cooldown: 0,
                    delay: 0,
                    isEnabled: true,
                    extensions: {},
                  ),
                ],
              ),
            ],
            chatMessages: [ChatMessage(text: '这里只有普通对话', isMe: true)],
            currentInput: '',
          ),
        );

        expect(result.activatedWorldBookEntries, isEmpty);

        final triggered = PromptAssembler.build(
          PromptAssemblyContext(
            characterName: '艾琳',
            characterCardData: _cardData(),
            userName: '林澈',
            userSettingPrompt: '',
            preset: Preset(
              id: 'preset-1',
              name: '测试预设',
              updatedAt: DateTime(2026),
              prompts: [
                PresetPrompt(
                  identifier: 'worldInfoBefore',
                  name: 'World Before',
                  marker: true,
                ),
              ],
            ),
            selectedWorldBooks: result.activatedWorldBookEntries.isEmpty
                ? [
                    WorldBook(
                      id: 'wb-1',
                      name: '世界书',
                      description: '',
                      colorValue: 0xFF000000,
                      entries: [
                        const WorldBookEntry(
                          id: 'entry-1',
                          key: ['禁书库'],
                          keysecondary: [],
                          content: '命中禁书库',
                          comment: '禁书库',
                          constant: false,
                          selective: false,
                          selectiveLogic: 0,
                          order: 10,
                          position: 0,
                          depth: 4,
                          sticky: 0,
                          cooldown: 0,
                          delay: 0,
                          isEnabled: true,
                          extensions: {},
                        ),
                      ],
                    ),
                  ]
                : const [],
            chatMessages: [ChatMessage(text: '我们去禁书库', isMe: true)],
            currentInput: '',
          ),
        );

        expect(triggered.activatedWorldBookEntries, hasLength(1));
      },
    );

    test('次要关键词按 selectiveLogic 门控而不是额外的触发词', () {
      bool activated(WorldBookEntry entry, String message) {
        final result = PromptAssembler.build(
          PromptAssemblyContext(
            characterName: '艾琳',
            characterCardData: _cardData(),
            userName: '林澈',
            userSettingPrompt: '',
            preset: _worldInfoPreset(),
            selectedWorldBooks: [
              WorldBook(
                id: 'wb-1',
                name: '世界书',
                description: '',
                colorValue: 0xFF000000,
                entries: [entry],
              ),
            ],
            chatMessages: [ChatMessage(text: message, isMe: true)],
            currentInput: '',
          ),
        );
        return result.activatedWorldBookEntries.isNotEmpty;
      }

      WorldBookEntry buildEntry(int logic, List<String> secondary) {
        return WorldBookEntry(
          id: 'entry-1',
          key: const ['龙'],
          keysecondary: secondary,
          content: '龙的设定',
          comment: '龙',
          selective: true,
          selectiveLogic: logic,
          order: 10,
          position: 0,
          depth: 4,
        );
      }

      // 0 = AND ANY：命中任一次要关键词
      final andAny = buildEntry(0, ['剑']);
      expect(activated(andAny, '龙'), isFalse);
      expect(activated(andAny, '龙与剑'), isTrue);

      // 1 = NOT ALL：未命中全部次要关键词
      final notAll = buildEntry(1, ['剑', '盾']);
      expect(activated(notAll, '龙与剑'), isTrue);
      expect(activated(notAll, '龙与剑与盾'), isFalse);

      // 2 = NOT ANY：未命中任何次要关键词
      final notAny = buildEntry(2, ['剑']);
      expect(activated(notAny, '龙与剑'), isFalse);
      expect(activated(notAny, '龙与盾'), isTrue);

      // 3 = AND ALL：命中全部次要关键词
      final andAll = buildEntry(3, ['剑', '盾']);
      expect(activated(andAll, '龙与剑'), isFalse);
      expect(activated(andAll, '龙与剑与盾'), isTrue);
    });

    test('扫描深度只扫描最近若干条消息', () {
      bool activated({required int depth}) {
        final result = PromptAssembler.build(
          PromptAssemblyContext(
            characterName: '艾琳',
            characterCardData: _cardData(),
            userName: '林澈',
            userSettingPrompt: '',
            preset: _worldInfoPreset(),
            selectedWorldBooks: [
              WorldBook(
                id: 'wb-1',
                name: '世界书',
                description: '',
                colorValue: 0xFF000000,
                entries: [
                  WorldBookEntry(
                    id: 'entry-1',
                    key: const ['禁书库'],
                    content: '禁书库的设定',
                    comment: '禁书库',
                    depth: depth,
                    position: 0,
                  ),
                ],
              ),
            ],
            chatMessages: [
              ChatMessage(text: '第一句提到禁书库', isMe: true),
              ChatMessage(text: '第二句闲聊', isMe: false),
            ],
            currentInput: '',
          ),
        );
        return result.activatedWorldBookEntries.isNotEmpty;
      }

      expect(activated(depth: 1), isFalse);
      expect(activated(depth: 2), isTrue);
      expect(activated(depth: 0), isFalse);
    });

    test('merges adjacent messages with the same role', () {
      final result = PromptAssembler.build(
        PromptAssemblyContext(
          characterName: '艾琳',
          characterCardData: _cardData(
            description: '角色描述',
            personality: '角色性格',
          ),
          userName: '林澈',
          userSettingPrompt: '',
          preset: Preset(
            id: 'preset-1',
            name: '测试预设',
            updatedAt: DateTime(2026),
            prompts: [
              PresetPrompt(
                identifier: 'charDescription',
                name: 'Description',
                role: 'system',
                marker: true,
              ),
              PresetPrompt(
                identifier: 'charPersonality',
                name: 'Personality',
                role: 'system',
                marker: true,
              ),
              PresetPrompt(
                identifier: 'chatHistory',
                name: 'History',
                role: 'user',
                marker: true,
              ),
            ],
          ),
          selectedWorldBooks: const [],
          chatMessages: [ChatMessage(text: '你好', isMe: true)],
          currentInput: '继续',
        ),
      );

      expect(result.segments, hasLength(3));
      expect(result.messages, hasLength(2));
      expect(result.messages.first.role, 'system');
      expect(result.messages.first.content, contains('角色描述'));
      expect(result.messages.first.content, contains('角色性格'));
      expect(result.messages.first.sources, hasLength(2));
    });

    test(
      'uses new chat prompt, replaces example start token, and formats history with roles',
      () {
        final result = PromptAssembler.build(
          PromptAssemblyContext(
            characterName: '艾琳',
            characterCardData: _cardData(
              mesExample: '<START>\n{{user}}: 你好\n{{char}}: 你好。',
            ),
            userName: '林澈',
            userSettingPrompt: '',
            preset: Preset(
              id: 'preset-1',
              name: '测试预设',
              updatedAt: DateTime(2026),
              prompts: [
                PresetPrompt(
                  identifier: 'dialogueExamples',
                  name: 'Examples',
                  role: 'system',
                  marker: true,
                ),
                PresetPrompt(
                  identifier: 'chatHistory',
                  name: 'History',
                  role: 'system',
                  marker: true,
                ),
              ],
              extra: const {
                'new_chat_prompt': '[Start a new Chat]',
                'new_example_chat_prompt': '[Example Chat]',
              },
            ),
            selectedWorldBooks: const [],
            chatMessages: [
              ChatMessage(text: '第一句', isMe: true),
              ChatMessage(text: '第二句', isMe: false),
            ],
            currentInput: '第三句',
          ),
        );

        expect(result.mergedText, contains('[Example Chat]'));
        expect(result.mergedText, isNot(contains('<START>')));
        expect(
          result.mergedText,
          contains('[Start a new Chat]\nuser: 第一句\nassistant: 第二句\nuser: 第三句'),
        );
        expect(result.mergedText, isNot(contains('林澈: 第一句')));
        expect(result.mergedText, isNot(contains('艾琳: 第二句')));

        expect(result.messages, hasLength(4));
        expect(result.messages[0].role, 'system');
        expect(result.messages[0].content, contains('[Example Chat]'));
        expect(result.messages[0].content, contains('[Start a new Chat]'));
        expect(result.messages[1].role, 'user');
        expect(result.messages[1].content, '第一句');
        expect(result.messages[2].role, 'assistant');
        expect(result.messages[2].content, '第二句');
        expect(result.messages[3].role, 'user');
        expect(result.messages[3].content, '第三句');
      },
    );

    test(
      'inserts in-chat prompts by depth and orders same-depth prompts by role then injection order',
      () {
        final result = PromptAssembler.build(
          PromptAssemblyContext(
            characterName: '艾琳',
            characterCardData: _cardData(),
            userName: '林澈',
            userSettingPrompt: '',
            preset: Preset(
              id: 'preset-1',
              name: '测试预设',
              updatedAt: DateTime(2026),
              prompts: [
                PresetPrompt(
                  identifier: 'chatHistory',
                  name: 'History',
                  role: 'system',
                  marker: true,
                ),
                PresetPrompt(
                  identifier: 'tail_system',
                  name: 'Tail System',
                  content: 'System tail',
                  role: 'system',
                  systemPrompt: true,
                  injectionPosition: PresetInjectionPosition.inChat,
                  injectionDepth: 0,
                ),
                PresetPrompt(
                  identifier: 'depth_user_late',
                  name: 'Depth User Late',
                  content: 'User note 20',
                  role: 'user',
                  systemPrompt: false,
                  injectionPosition: PresetInjectionPosition.inChat,
                  injectionDepth: 1,
                  injectionOrder: 20,
                ),
                PresetPrompt(
                  identifier: 'depth_assistant',
                  name: 'Depth Assistant',
                  content: 'Assistant note',
                  role: 'assistant',
                  systemPrompt: false,
                  injectionPosition: PresetInjectionPosition.inChat,
                  injectionDepth: 1,
                  injectionOrder: 10,
                ),
                PresetPrompt(
                  identifier: 'depth_user_early',
                  name: 'Depth User Early',
                  content: 'User note 10',
                  role: 'user',
                  systemPrompt: false,
                  injectionPosition: PresetInjectionPosition.inChat,
                  injectionDepth: 1,
                  injectionOrder: 10,
                ),
              ],
            ),
            selectedWorldBooks: const [],
            chatMessages: [
              ChatMessage(text: '第一句', isMe: true),
              ChatMessage(text: '第二句', isMe: false),
            ],
            currentInput: '第三句',
          ),
        );

        expect(
          result.mergedText,
          contains(
            'assistant: 第二句\nuser: User note 10\n\nUser note 20\nassistant: Assistant note\nuser: 第三句\nsystem: System tail',
          ),
        );
        expect(result.messages.map((item) => item.role).toList(), [
          'user',
          'assistant',
          'user',
          'assistant',
          'user',
          'system',
        ]);
        expect(result.messages[2].content, 'User note 10\n\nUser note 20');
        expect(result.messages[3].content, 'Assistant note');
        expect(result.messages[4].content, '第三句');
        expect(result.messages[5].content, 'System tail');
      },
    );

    test('places deep in-chat prompts before the first chat message', () {
      final result = PromptAssembler.build(
        PromptAssemblyContext(
          characterName: '艾琳',
          characterCardData: _cardData(),
          userName: '林澈',
          userSettingPrompt: '',
          preset: Preset(
            id: 'preset-1',
            name: '测试预设',
            updatedAt: DateTime(2026),
            prompts: [
              PresetPrompt(
                identifier: 'chatHistory',
                name: 'History',
                role: 'system',
                marker: true,
              ),
              PresetPrompt(
                identifier: 'deep_system',
                name: 'Deep System',
                content: 'Before all history',
                role: 'system',
                injectionPosition: PresetInjectionPosition.inChat,
                injectionDepth: 99,
              ),
            ],
          ),
          selectedWorldBooks: const [],
          chatMessages: [ChatMessage(text: '第一句', isMe: true)],
          currentInput: '',
        ),
      );

      expect(result.messages, hasLength(2));
      expect(result.messages.first.role, 'system');
      expect(result.messages.first.content, 'Before all history');
      expect(result.messages.last.role, 'user');
      expect(result.messages.last.content, '第一句');
    });

    test('contextEntries 按来源、role 与聊天记录顺序展开', () {
      final result = PromptAssembler.build(
        PromptAssemblyContext(
          characterName: '艾琳',
          characterCardData: _cardData(systemPrompt: '角色卡 main'),
          userName: '林澈',
          userSettingPrompt: '用户设定内容',
          preset: Preset(
            id: 'preset-1',
            name: '测试预设',
            updatedAt: DateTime(2026),
            prompts: [
              PresetPrompt(
                identifier: 'personaDescription',
                name: 'Persona',
                marker: true,
              ),
              PresetPrompt(
                identifier: 'main',
                name: 'Main Prompt',
                content: '预设 main',
              ),
              PresetPrompt(
                identifier: 'worldInfoBefore',
                name: 'World Before',
                marker: true,
              ),
              PresetPrompt(
                identifier: 'longTermMemory',
                name: 'Memory',
                marker: true,
              ),
              PresetPrompt(
                identifier: 'chatHistory',
                name: 'Chat History',
                marker: true,
              ),
              PresetPrompt(
                identifier: 'jailbreak',
                name: 'Post-History Instructions',
                content: '禁止 Markdown',
              ),
            ],
          ),
          selectedWorldBooks: [
            WorldBook(
              id: 'wb-1',
              name: '世界书',
              description: '',
              colorValue: 0xFF000000,
              entries: const [
                WorldBookEntry(
                  id: 'entry-1',
                  key: ['溪桥'],
                  keysecondary: [],
                  content: '世界书内容',
                  comment: '桥',
                  constant: true,
                  selective: false,
                  selectiveLogic: 0,
                  order: 10,
                  position: 0,
                  depth: 4,
                  sticky: 0,
                  cooldown: 0,
                  delay: 0,
                  isEnabled: true,
                  extensions: {},
                ),
              ],
            ),
          ],
          chatMessages: [
            ChatMessage(text: '第一句', isMe: true),
            ChatMessage(text: '第二句', isMe: false),
          ],
          currentInput: '第三句',
          memoryContext: const ['记忆内容'],
        ),
      );

      expect(result.contextEntries.map((entry) => entry.source).toList(), [
        PromptContextSource.userSetting,
        PromptContextSource.characterCard,
        PromptContextSource.worldBook,
        PromptContextSource.memory,
        PromptContextSource.history,
        PromptContextSource.history,
        PromptContextSource.history,
        PromptContextSource.postInstruction,
      ]);
      expect(result.contextEntries.map((entry) => entry.role).toList(), [
        'system',
        'system',
        'system',
        'system',
        'user',
        'assistant',
        'user',
        'system',
      ]);
      expect(result.contextEntries[1].name, '角色卡 · system_prompt');
      expect(result.contextEntries[1].content, '角色卡 main');
      expect(result.contextEntries[2].name, '世界书 · 桥');
      expect(result.contextEntries[4].content, '第一句');
      expect(result.contextEntries[5].content, '第二句');
      expect(result.contextEntries[6].content, '第三句');
    });
  });

  group('世界书上下文与实际请求一致', () {
    PromptAssemblyResult buildWorldContext({
      required List<WorldBookEntry> entries,
      required List<PresetPrompt> prompts,
      Map<String, String> variables = const {},
    }) => PromptAssembler.build(
      PromptAssemblyContext(
        characterName: '艾琳',
        characterCardData: _cardData(),
        userName: '林澈',
        userSettingPrompt: '',
        preset: Preset(
          id: 'world-context',
          name: '测试预设',
          updatedAt: DateTime(2026),
          prompts: prompts,
        ),
        selectedWorldBooks: [
          WorldBook(
            id: 'book',
            name: '世界书',
            description: '',
            colorValue: 0,
            entries: entries,
          ),
        ],
        chatMessages: const [],
        currentInput: '你好',
        chatVariables: variables,
      ),
    );

    test('后续 setvar 不改变已经组装的世界书日志正文', () {
      final result = buildWorldContext(
        entries: const [
          WorldBookEntry(
            id: 'entry',
            content: 'phase={{getvar::phase}}',
            comment: '状态',
            constant: true,
          ),
        ],
        prompts: [
          PresetPrompt(
            identifier: 'worldInfoBefore',
            name: 'Before',
            marker: true,
          ),
          PresetPrompt(
            identifier: 'later',
            name: 'Later',
            content: '{{setvar::phase::after}}tail',
          ),
          PresetPrompt(
            identifier: 'worldInfoBefore',
            name: 'Before Again',
            marker: true,
          ),
        ],
        variables: const {'phase': 'before'},
      );

      final worlds = result.contextEntries
          .where((entry) => entry.source == PromptContextSource.worldBook)
          .toList();
      expect(worlds.map((entry) => entry.content), [
        'phase=before',
        'phase=after',
      ]);
      expect(
        result.messages.single.content,
        'phase=before\n\ntail\n\nphase=after',
      );
    });

    test('条目间 setvar/getvar 按原顺序求值且忽略无正文的赋值条目', () {
      final result = buildWorldContext(
        entries: const [
          WorldBookEntry(
            id: 'set',
            content: '{{setvar::phase::book}}',
            comment: '赋值',
            constant: true,
            order: 1,
          ),
          WorldBookEntry(
            id: 'get',
            content: 'phase={{getvar::phase}}',
            comment: '读取',
            constant: true,
            order: 2,
          ),
        ],
        prompts: [
          PresetPrompt(
            identifier: 'worldInfoBefore',
            name: 'Before',
            marker: true,
          ),
          PresetPrompt(
            identifier: 'later',
            name: 'Later',
            content: '{{setvar::phase::after}}tail',
          ),
        ],
      );

      final world = result.contextEntries.first;
      expect(world.name, '世界书 · 读取');
      expect(world.content, 'phase=book');
      expect(result.messages.single.content, 'phase=book\n\ntail');
    });

    test('跨条目 trim 宏使用实际解析后的整段正文', () {
      final result = buildWorldContext(
        entries: const [
          WorldBookEntry(
            id: 'a',
            content: 'alpha\n\n{{trim}}',
            comment: 'A',
            constant: true,
            order: 1,
          ),
          WorldBookEntry(
            id: 'b',
            content: 'beta',
            comment: 'B',
            constant: true,
            order: 2,
          ),
        ],
        prompts: [
          PresetPrompt(
            identifier: 'worldInfoBefore',
            name: 'Before',
            marker: true,
          ),
        ],
      );

      expect(result.messages.single.content, 'alphabeta');
      expect(
        result.contextEntries.single.content,
        result.messages.single.content,
      );
      expect(
        result.contextEntries.single.source,
        PromptContextSource.worldBook,
      );
    });

    test('后置世界书日志沿用所有非零位置的请求语义', () {
      final result = buildWorldContext(
        entries: const [
          WorldBookEntry(
            id: 'after',
            content: '后置条目',
            comment: 'After',
            constant: true,
            position: 2,
          ),
        ],
        prompts: [
          PresetPrompt(
            identifier: 'worldInfoAfter',
            name: 'After',
            marker: true,
          ),
        ],
      );

      expect(result.messages.single.content, '后置条目');
      expect(result.contextEntries.single.name, '世界书 · After');
      expect(result.contextEntries.single.content, '后置条目');
    });
  });
}

Preset _worldInfoPreset() {
  return Preset(
    id: 'preset-1',
    name: '测试预设',
    updatedAt: DateTime(2026),
    prompts: [
      PresetPrompt(
        identifier: 'worldInfoBefore',
        name: 'World Before',
        marker: true,
      ),
    ],
  );
}

Map<String, dynamic> _cardData({
  String description = '角色描述',
  String personality = '角色性格',
  String scenario = '角色场景',
  String mesExample = '示例对话',
  String systemPrompt = '',
  String postHistoryInstructions = '',
}) {
  return {
    'spec': 'chara_card_v2',
    'spec_version': '2.0',
    'data': {
      'name': '艾琳',
      'description': description,
      'personality': personality,
      'scenario': scenario,
      'first_mes': '',
      'mes_example': mesExample,
      'creator_notes': '',
      'system_prompt': systemPrompt,
      'post_history_instructions': postHistoryInstructions,
      'alternate_greetings': <String>[],
      'tags': <String>[],
      'character_book': {
        'entries': <String, dynamic>{},
        'extensions': <String, dynamic>{},
      },
      'extensions': <String, dynamic>{},
    },
  };
}
