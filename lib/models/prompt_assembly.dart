import 'chat_message.dart';
import 'preset.dart';
import 'world_book.dart';

class PromptAssemblyContext {
  const PromptAssemblyContext({
    required this.characterName,
    required this.characterCardData,
    required this.userName,
    required this.userSettingPrompt,
    required this.preset,
    required this.selectedWorldBooks,
    required this.chatMessages,
    required this.currentInput,
    this.memoryContext = const [],
  });

  final String characterName;
  final Map<String, dynamic> characterCardData;
  final String userName;
  final String userSettingPrompt;
  final Preset preset;
  final List<WorldBook> selectedWorldBooks;
  final List<ChatMessage> chatMessages;
  final String currentInput;
  final List<String> memoryContext;
}

class PromptSegment {
  const PromptSegment({
    required this.role,
    required this.content,
    required this.source,
    this.identifier,
  });

  final String role;
  final String content;
  final String source;
  final String? identifier;
}

class PromptMessage {
  const PromptMessage({
    required this.role,
    required this.content,
    required this.sources,
  });

  final String role;
  final String content;
  final List<String> sources;
}

class UnusedCharacterOverride {
  const UnusedCharacterOverride({
    required this.field,
    required this.content,
    required this.reason,
  });

  final String field;
  final String content;
  final String reason;
}

class ActivatedWorldBookEntry {
  const ActivatedWorldBookEntry({
    required this.bookId,
    required this.bookName,
    required this.entry,
    required this.triggeredByConstant,
  });

  final String bookId;
  final String bookName;
  final WorldBookEntry entry;
  final bool triggeredByConstant;
}

class PromptAssemblyResult {
  const PromptAssemblyResult({
    required this.messages,
    required this.mergedText,
    required this.activatedWorldBookEntries,
    required this.segments,
    required this.unusedCharacterOverrides,
  });

  final List<PromptMessage> messages;
  final String mergedText;
  final List<ActivatedWorldBookEntry> activatedWorldBookEntries;
  final List<PromptSegment> segments;
  final List<UnusedCharacterOverride> unusedCharacterOverrides;
}
