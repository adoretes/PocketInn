import 'chat_memory_service.dart';

class PromptMacroState {
  PromptMacroState({
    required this.characterName,
    required this.userName,
    this.currentInput = '',
    this.lastUserMessage = '',
    this.lastCharMessage = '',
    this.memoryContext = const [],
    Map<String, String>? localVariables,
  }) : localVariables = localVariables == null
           ? <String, String>{}
           : Map<String, String>.from(localVariables);

  final String characterName;
  final String userName;
  final String currentInput;
  final String lastUserMessage;
  final String lastCharMessage;
  final List<String> memoryContext;
  final Map<String, String> localVariables;

  PromptMacroState copy() {
    return PromptMacroState(
      characterName: characterName,
      userName: userName,
      currentInput: currentInput,
      lastUserMessage: lastUserMessage,
      lastCharMessage: lastCharMessage,
      memoryContext: memoryContext,
      localVariables: localVariables,
    );
  }
}

class ChatVariableService {
  ChatVariableService._();

  static final RegExp _macroPattern = RegExp(r'\{\{([\s\S]*?)\}\}');
  static final RegExp _userAliasPattern = RegExp(
    r'<\s*USER\s*>',
    caseSensitive: false,
  );
  static final RegExp _charAliasPattern = RegExp(
    r'<\s*BOT\s*>',
    caseSensitive: false,
  );
  static final RegExp _userPlaceholderPattern = RegExp(
    r'\{\{\s*user\s*\}\}',
    caseSensitive: false,
  );
  static final RegExp _charPlaceholderPattern = RegExp(
    r'\{\{\s*char\s*\}\}',
    caseSensitive: false,
  );
  static const String _trimMarker = '\u0000POCKET_INN_TRIM\u0000';

  static String replacePlaceholders(
    String input, {
    required String characterName,
    required String userName,
  }) {
    return _replaceBasicPlaceholders(
      input,
      characterName: characterName,
      userName: userName,
    );
  }

  static String resolveMacros(String input, {required PromptMacroState state}) {
    if (input.isEmpty) {
      return input;
    }

    final prepared = _replaceBasicPlaceholders(
      input,
      characterName: state.characterName,
      userName: state.userName,
    );
    final replaced = prepared.replaceAllMapped(_macroPattern, (match) {
      final body = match.group(1) ?? '';
      return _resolveMacro(
        fullMatch: match.group(0) ?? '',
        body: body,
        state: state,
      );
    });

    return _applyTrimMarkers(replaced);
  }

  static String _resolveMacro({
    required String fullMatch,
    required String body,
    required PromptMacroState state,
  }) {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      return fullMatch;
    }
    if (trimmedBody.startsWith('//')) {
      return '';
    }

    final separatorIndex = body.indexOf('::');
    final macroName =
        (separatorIndex == -1
                ? trimmedBody
                : body.substring(0, separatorIndex).trim())
            .toLowerCase();

    switch (macroName) {
      case 'char':
        return state.characterName;
      case 'user':
        return state.userName;
      case 'input':
        return state.currentInput;
      case 'lastusermessage':
        return state.lastUserMessage;
      case 'lastcharmessage':
        return state.lastCharMessage;
      case 'memory':
        return ChatMemoryService.formatMemoryContext(state.memoryContext);
      case 'trim':
        return _trimMarker;
      case 'noop':
        return '';
      case 'newline':
        return '\n';
      case 'getvar':
        final variableName = _parseSingleArgument(body);
        if (variableName.isEmpty) {
          return '';
        }
        return state.localVariables[variableName] ?? '';
      case 'setvar':
        final parsed = _parseVariableAssignment(body);
        if (parsed.name.isNotEmpty) {
          state.localVariables[parsed.name] = parsed.value;
        }
        return '';
      default:
        return fullMatch;
    }
  }

  static String _replaceBasicPlaceholders(
    String input, {
    required String characterName,
    required String userName,
  }) {
    return input
        .replaceAllMapped(_userPlaceholderPattern, (_) => userName)
        .replaceAllMapped(_charPlaceholderPattern, (_) => characterName)
        .replaceAllMapped(_userAliasPattern, (_) => userName)
        .replaceAllMapped(_charAliasPattern, (_) => characterName);
  }

  static String _applyTrimMarkers(String input) {
    if (!input.contains(_trimMarker)) {
      return input;
    }

    final buffer = StringBuffer();
    var index = 0;
    while (index < input.length) {
      final markerIndex = input.indexOf(_trimMarker, index);
      if (markerIndex == -1) {
        buffer.write(input.substring(index));
        break;
      }

      var left = markerIndex;
      while (left > index) {
        final char = input[left - 1];
        if (char != '\n' && char != '\r') {
          break;
        }
        left -= 1;
      }
      buffer.write(input.substring(index, left));

      index = markerIndex + _trimMarker.length;
      while (index < input.length) {
        final char = input[index];
        if (char != '\n' && char != '\r') {
          break;
        }
        index += 1;
      }
    }
    return buffer.toString();
  }

  static String _parseSingleArgument(String body) {
    final separatorIndex = body.indexOf('::');
    if (separatorIndex == -1) {
      return '';
    }
    return body.substring(separatorIndex + 2).trim();
  }

  static _VariableAssignment _parseVariableAssignment(String body) {
    final firstSeparatorIndex = body.indexOf('::');
    if (firstSeparatorIndex == -1) {
      return const _VariableAssignment.empty();
    }

    final remainder = body.substring(firstSeparatorIndex + 2);
    final secondSeparatorIndex = remainder.indexOf('::');
    if (secondSeparatorIndex == -1) {
      return _VariableAssignment(name: remainder.trim(), value: '');
    }

    return _VariableAssignment(
      name: remainder.substring(0, secondSeparatorIndex).trim(),
      value: remainder.substring(secondSeparatorIndex + 2),
    );
  }
}

class _VariableAssignment {
  const _VariableAssignment({required this.name, required this.value});

  const _VariableAssignment.empty() : name = '', value = '';

  final String name;
  final String value;
}
