import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_inn/models/character_card.dart';

void main() {
  group('decodeCharacterCardJson', () {
    test('accepts SillyTavern v2 character cards', () {
      final decoded = decodeCharacterCardJson(
        jsonEncode({
          'spec': 'chara_card_v2',
          'spec_version': '2.0',
          'data': {
            'name': 'Test Character',
            'description': 'desc',
            'first_mes': 'hello',
          },
        }),
      );

      expect(decoded, isNotNull);
      expect(decoded!['data']['name'], 'Test Character');
    });

    test('accepts legacy root-level character cards', () {
      final decoded = decodeCharacterCardJson(
        jsonEncode({
          'name': 'Legacy Character',
          'description': 'desc',
          'first_mes': 'hello',
        }),
      );

      expect(decoded, isNotNull);
      expect(decoded!['data']['name'], 'Legacy Character');
    });

    test('rejects preset json instead of creating an empty character', () {
      final decoded = decodeCharacterCardJson(
        jsonEncode({
          'name': 'Preset',
          'temperature': 0.8,
          'top_p': 1,
          'prompts': [
            {
              'identifier': 'main',
              'name': 'Main Prompt',
              'role': 'system',
              'content': 'You are {{char}}.',
            },
          ],
          'prompt_order': [
            {
              'character_id': 100001,
              'order': [
                {'identifier': 'main', 'enabled': true},
              ],
            },
          ],
        }),
      );

      expect(decoded, isNull);
    });
  });
}
