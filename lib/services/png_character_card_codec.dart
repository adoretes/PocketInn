import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class PngCharacterCardCodec {
  static const Set<String> _supportedKeywords = {'chara', 'ccv3'};
  static final Uint8List _signature = Uint8List.fromList(const [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ]);

  static Map<String, dynamic>? decodeCard(Uint8List bytes) {
    if (!_looksLikePng(bytes)) {
      return null;
    }

    for (final chunk in _readChunks(bytes)) {
      if (chunk.type == 'tEXt') {
        final textValue = _decodeTextChunk(chunk.data);
        if (textValue != null) {
          final decoded = _decodeCharaPayload(
            textValue.keyword,
            textValue.text,
          );
          if (decoded != null) {
            return decoded;
          }
        }
      } else if (chunk.type == 'zTXt') {
        final textValue = _decodeCompressedTextChunk(chunk.data);
        if (textValue != null) {
          final decoded = _decodeCharaPayload(
            textValue.keyword,
            textValue.text,
          );
          if (decoded != null) {
            return decoded;
          }
        }
      } else if (chunk.type == 'iTXt') {
        final textValue = _decodeInternationalTextChunk(chunk.data);
        if (textValue != null) {
          final decoded = _decodeCharaPayload(
            textValue.keyword,
            textValue.text,
          );
          if (decoded != null) {
            return decoded;
          }
        }
      }
    }

    return null;
  }

  static Uint8List embedCard(Uint8List pngBytes, String cardJson) {
    if (!_looksLikePng(pngBytes)) {
      throw const FormatException('不是有效的 PNG 文件');
    }

    final payload = base64.encode(utf8.encode(cardJson));
    final output = BytesBuilder();
    output.add(_signature);

    final chunks = _readChunks(pngBytes);
    for (final chunk in chunks) {
      if (_isCharacterCardChunk(chunk)) {
        continue;
      }

      if (chunk.type == 'IEND') {
        output.add(_createTextChunk('chara', payload));
        output.add(_createInternationalTextChunk('ccv3', cardJson));
      }

      output.add(_encodeChunk(chunk.type, chunk.data));
    }

    return output.toBytes();
  }

  static bool _looksLikePng(Uint8List bytes) {
    if (bytes.length < _signature.length) {
      return false;
    }
    for (var i = 0; i < _signature.length; i++) {
      if (bytes[i] != _signature[i]) {
        return false;
      }
    }
    return true;
  }

  static List<_PngChunk> _readChunks(Uint8List bytes) {
    final chunks = <_PngChunk>[];
    final byteData = ByteData.sublistView(bytes);
    var offset = _signature.length;

    while (offset + 12 <= bytes.length) {
      final length = byteData.getUint32(offset);
      final typeStart = offset + 4;
      final dataStart = typeStart + 4;
      final dataEnd = dataStart + length;
      final crcEnd = dataEnd + 4;
      if (crcEnd > bytes.length) {
        break;
      }

      final type = ascii.decode(bytes.sublist(typeStart, dataStart));
      final data = Uint8List.fromList(bytes.sublist(dataStart, dataEnd));
      chunks.add(_PngChunk(type: type, data: data));
      offset = crcEnd;

      if (type == 'IEND') {
        break;
      }
    }

    return chunks;
  }

  static ({String keyword, String text})? _decodeTextChunk(Uint8List data) {
    final separator = data.indexOf(0);
    if (separator <= 0 || separator >= data.length - 1) {
      return null;
    }
    final keyword = latin1.decode(data.sublist(0, separator));
    final text = latin1.decode(data.sublist(separator + 1));
    return (keyword: keyword, text: text);
  }

  static ({String keyword, String text})? _decodeCompressedTextChunk(
    Uint8List data,
  ) {
    final separator = data.indexOf(0);
    if (separator <= 0 || separator + 2 >= data.length) {
      return null;
    }
    final keyword = latin1.decode(data.sublist(0, separator));
    final compressionMethod = data[separator + 1];
    if (compressionMethod != 0) {
      return null;
    }
    final compressed = data.sublist(separator + 2);
    final textBytes = ZLibCodec().decode(compressed);
    return (keyword: keyword, text: latin1.decode(textBytes));
  }

  static ({String keyword, String text})? _decodeInternationalTextChunk(
    Uint8List data,
  ) {
    final keywordEnd = data.indexOf(0);
    if (keywordEnd <= 0 || keywordEnd + 5 >= data.length) {
      return null;
    }

    final keyword = latin1.decode(data.sublist(0, keywordEnd));
    final compressionFlag = data[keywordEnd + 1];
    final compressionMethod = data[keywordEnd + 2];

    var offset = keywordEnd + 3;
    final languageEnd = data.indexOf(0, offset);
    if (languageEnd < 0) {
      return null;
    }
    offset = languageEnd + 1;

    final translatedEnd = data.indexOf(0, offset);
    if (translatedEnd < 0) {
      return null;
    }
    offset = translatedEnd + 1;

    final textBytes = data.sublist(offset);
    final decodedBytes = compressionFlag == 1 && compressionMethod == 0
        ? ZLibCodec().decode(textBytes)
        : textBytes;
    return (
      keyword: keyword,
      text: utf8.decode(decodedBytes, allowMalformed: true),
    );
  }

  static Map<String, dynamic>? _decodeCharaPayload(
    String keyword, [
    String? text,
  ]) {
    if (!_supportedKeywords.contains(keyword.trim().toLowerCase())) {
      return null;
    }

    final payload = _normalizePayloadText(text ?? '');
    if (payload.isEmpty) {
      return null;
    }

    final directJson = _tryDecodeJsonMap(payload);
    if (directJson != null) {
      return directJson;
    }

    for (final candidate in _decodeBase64Candidates(payload)) {
      final decoded = _tryDecodeJsonMap(candidate);
      if (decoded != null) {
        return decoded;
      }
    }

    return null;
  }

  static bool _isCharacterCardChunk(_PngChunk chunk) {
    if (chunk.type == 'tEXt') {
      final text = _decodeTextChunk(chunk.data);
      return text != null &&
          _supportedKeywords.contains(text.keyword.trim().toLowerCase());
    }
    if (chunk.type == 'zTXt') {
      final text = _decodeCompressedTextChunk(chunk.data);
      return text != null &&
          _supportedKeywords.contains(text.keyword.trim().toLowerCase());
    }
    if (chunk.type == 'iTXt') {
      final text = _decodeInternationalTextChunk(chunk.data);
      return text != null &&
          _supportedKeywords.contains(text.keyword.trim().toLowerCase());
    }
    return false;
  }

  static Uint8List _createTextChunk(String keyword, String text) {
    final data = BytesBuilder()
      ..add(latin1.encode(keyword))
      ..addByte(0)
      ..add(latin1.encode(text));
    return _encodeChunk('tEXt', data.toBytes());
  }

  static Uint8List _createInternationalTextChunk(String keyword, String text) {
    final data = BytesBuilder()
      ..add(latin1.encode(keyword))
      ..addByte(0)
      ..addByte(0)
      ..addByte(0)
      ..addByte(0)
      ..addByte(0)
      ..add(utf8.encode(text));
    return _encodeChunk('iTXt', data.toBytes());
  }

  static String _normalizePayloadText(String value) {
    return value.trim().replaceFirst('\uFEFF', '');
  }

  static Map<String, dynamic>? _tryDecodeJsonMap(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Iterable<String> _decodeBase64Candidates(String payload) sync* {
    final normalized = payload.replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) {
      return;
    }

    final candidates = <String>{normalized};
    try {
      candidates.add(base64.normalize(normalized));
    } catch (_) {
      // Keep trying the original payload.
    }

    for (final candidate in candidates) {
      final decoded =
          _tryDecodeBase64(candidate, urlSafe: false) ??
          _tryDecodeBase64(candidate, urlSafe: true);
      if (decoded != null) {
        yield decoded;
      }
    }
  }

  static String? _tryDecodeBase64(String payload, {required bool urlSafe}) {
    try {
      final bytes = urlSafe
          ? base64Url.decode(payload)
          : base64.decode(payload);
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  static Uint8List _encodeChunk(String type, Uint8List data) {
    final typeBytes = ascii.encode(type);
    final builder = BytesBuilder();
    final header = ByteData(4)..setUint32(0, data.length);
    builder.add(header.buffer.asUint8List());
    builder.add(typeBytes);
    builder.add(data);
    final crcInput = Uint8List.fromList([...typeBytes, ...data]);
    final crc = ByteData(4)..setUint32(0, _crc32(crcInput));
    builder.add(crc.buffer.asUint8List());
    return builder.toBytes();
  }

  static int _crc32(Uint8List bytes) {
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
}

class _PngChunk {
  const _PngChunk({required this.type, required this.data});

  final String type;
  final Uint8List data;
}
