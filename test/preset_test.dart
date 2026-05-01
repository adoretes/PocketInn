import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_inn/models/preset.dart';

void main() {
  group('Preset prompt_order', () {
    test('prefers the richer prompt_order group when importing ST preset', () {
      final preset = Preset.fromSillyTavernJson({
        'name': '测试预设',
        'temperature': 1,
        'prompts': [
          {
            'identifier': 'main',
            'name': 'Main',
            'role': 'system',
            'content': 'main',
          },
          {
            'identifier': 'chatHistory',
            'name': 'History',
            'role': 'user',
            'content': '',
            'marker': true,
          },
          {
            'identifier': 'customA',
            'name': 'Custom A',
            'role': 'system',
            'content': 'A',
          },
          {
            'identifier': 'customB',
            'name': 'Custom B',
            'role': 'user',
            'content': 'B',
          },
        ],
        'prompt_order': [
          {
            'character_id': 100000,
            'order': [
              {'identifier': 'main', 'enabled': true},
              {'identifier': 'chatHistory', 'enabled': true},
            ],
          },
          {
            'character_id': 100001,
            'order': [
              {'identifier': 'customA', 'enabled': true},
              {'identifier': 'main', 'enabled': false},
              {'identifier': 'customB', 'enabled': true},
              {'identifier': 'chatHistory', 'enabled': true},
            ],
          },
        ],
      }, id: 'preset-1');

      expect(preset.promptOrderGroups, hasLength(2));
      expect(preset.activePromptOrderCharacterId, '100001');
      expect(preset.prompts.map((item) => item.identifier).take(4).toList(), [
        'customA',
        'main',
        'customB',
        'chatHistory',
      ]);
      expect(preset.prompts[0].enabled, isTrue);
      expect(preset.prompts[1].enabled, isFalse);
    });

    test('preserves prompt_order groups across storage and export', () {
      final preset = Preset(
        id: 'preset-1',
        name: '测试预设',
        updatedAt: DateTime(2026),
        prompts: [
          PresetPrompt(
            identifier: 'customA',
            name: 'Custom A',
            content: 'A',
            enabled: false,
          ),
          PresetPrompt(
            identifier: 'main',
            name: 'Main',
            content: 'main',
            enabled: true,
          ),
        ],
        promptOrderGroups: [
          PresetPromptOrderGroup(
            characterId: '100000',
            order: [PresetPromptOrderEntry(identifier: 'main', enabled: false)],
          ),
          PresetPromptOrderGroup(
            characterId: '100001',
            order: [
              PresetPromptOrderEntry(identifier: 'main', enabled: false),
              PresetPromptOrderEntry(identifier: 'customA', enabled: true),
            ],
          ),
        ],
        activePromptOrderCharacterId: '100001',
      );

      final restored = Preset.fromStorageJson(preset.toStorageJson());
      expect(restored.promptOrderGroups, hasLength(2));
      expect(restored.activePromptOrderCharacterId, '100001');

      final exported = restored.toSillyTavernJson();
      final groups = (exported['prompt_order'] as List<dynamic>)
          .whereType<Map>()
          .map(
            (item) => PresetPromptOrderGroup.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      expect(groups, hasLength(2));

      final defaultGroup = groups.firstWhere(
        (item) => item.characterId == '100000',
      );
      expect(defaultGroup.order, hasLength(1));
      expect(defaultGroup.order.first.identifier, 'main');
      expect(defaultGroup.order.first.enabled, isFalse);

      final activeGroup = groups.firstWhere(
        (item) => item.characterId == '100001',
      );
      expect(activeGroup.order.map((item) => item.identifier).toList(), [
        'customA',
        'main',
      ]);
      expect(activeGroup.order.map((item) => item.enabled).toList(), [
        false,
        true,
      ]);
    });
  });
}
