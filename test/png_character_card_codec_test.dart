import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_inn/services/png_character_card_codec.dart';

void main() {
  const card = <String, dynamic>{
    'spec': 'chara_card_v2',
    'spec_version': '2.0',
    'data': {
      'name': 'Test Character',
      'description': 'desc',
      'personality': 'calm',
      'scenario': 'scene',
      'first_mes': 'hello',
      'mes_example': '',
      'creator_notes': '',
      'system_prompt': '',
      'post_history_instructions': '',
      'alternate_greetings': <String>[],
      'tags': <String>[],
      'character_book': {
        'entries': <String, dynamic>{},
        'extensions': <String, dynamic>{},
      },
      'extensions': <String, dynamic>{},
    },
  };

  test('decodeCard reads chara tEXt base64 payload', () {
    final png = PngCharacterCardCodec.embedCard(_basePng(), jsonEncode(card));

    final decoded = PngCharacterCardCodec.decodeCard(png);

    expect(decoded, isNotNull);
    expect(decoded!['data']['name'], 'Test Character');
  });

  test('decodeCard reads ccv3 iTXt raw json payload', () {
    final png = _pngWithRawCcv3Chunk(jsonEncode(card));

    final decoded = PngCharacterCardCodec.decodeCard(png);

    expect(decoded, isNotNull);
    expect(decoded!['data']['name'], 'Test Character');
  });

  test(
    'embedCard replaces prior character card chunks and keeps card readable',
    () {
      final seeded = _pngWithRawCcv3Chunk(
        jsonEncode({
          ...card,
          'data': {
            ...(card['data'] as Map<String, dynamic>),
            'name': 'Old Character',
          },
        }),
      );

      final png = PngCharacterCardCodec.embedCard(seeded, jsonEncode(card));
      final decoded = PngCharacterCardCodec.decodeCard(png);

      expect(decoded, isNotNull);
      expect(decoded!['data']['name'], 'Test Character');
    },
  );

  test('decodeCard skips invalid character card chunks and keeps scanning', () {
    final source = _basePng();
    final output = BytesBuilder()..add(source.sublist(0, source.length - 12));
    output.add(_buildChunk('tEXt', _buildTextData('chara', 'not-base64')));
    output.add(
      _buildChunk(
        'iTXt',
        _buildInternationalTextData('ccv3', jsonEncode(card)),
      ),
    );
    output.add(source.sublist(source.length - 12));

    final decoded = PngCharacterCardCodec.decodeCard(output.toBytes());

    expect(decoded, isNotNull);
    expect(decoded!['data']['name'], 'Test Character');
  });
}

Uint8List _basePng() => Uint8List.fromList(base64Decode(_basePngBase64));

Uint8List _pngWithRawCcv3Chunk(String cardJson) {
  final source = _basePng();
  final output = BytesBuilder()..add(source.sublist(0, source.length - 12));
  output.add(
    _buildChunk('iTXt', _buildInternationalTextData('ccv3', cardJson)),
  );
  output.add(source.sublist(source.length - 12));
  return output.toBytes();
}

Uint8List _buildInternationalTextData(String keyword, String text) {
  final builder = BytesBuilder()
    ..add(latin1.encode(keyword))
    ..addByte(0)
    ..addByte(0)
    ..addByte(0)
    ..addByte(0)
    ..addByte(0)
    ..add(utf8.encode(text));
  return builder.toBytes();
}

Uint8List _buildTextData(String keyword, String text) {
  final builder = BytesBuilder()
    ..add(latin1.encode(keyword))
    ..addByte(0)
    ..add(latin1.encode(text));
  return builder.toBytes();
}

Uint8List _buildChunk(String type, Uint8List data) {
  final builder = BytesBuilder();
  final typeBytes = ascii.encode(type);
  final header = ByteData(4)..setUint32(0, data.length);
  builder.add(header.buffer.asUint8List());
  builder.add(typeBytes);
  builder.add(data);
  final crcInput = Uint8List.fromList([...typeBytes, ...data]);
  final crc = ByteData(4)..setUint32(0, _crc32(crcInput));
  builder.add(crc.buffer.asUint8List());
  return builder.toBytes();
}

int _crc32(Uint8List bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      final mask = -(crc & 1);
      crc = (crc >> 1) ^ (0xEDB88320 & mask);
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

const _basePngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a6t8AAAAASUVORK5CYII=';
