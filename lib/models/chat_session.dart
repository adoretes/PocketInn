import 'chat_message.dart';

enum ChatNodeRole {
  user,
  assistant;

  String get value => name;

  static ChatNodeRole fromValue(String value) {
    return ChatNodeRole.values.firstWhere(
      (item) => item.value == value,
      orElse: () => ChatNodeRole.assistant,
    );
  }
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.characterId,
    required this.selectedWorldBookIds,
    this.selectedUserSettingId,
    this.selectedPresetId,
    this.currentLeafMessageId,
    this.lastMessagePreview = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String characterId;
  final String? selectedUserSettingId;
  final List<String> selectedWorldBookIds;
  final String? selectedPresetId;
  final String? currentLeafMessageId;
  final String lastMessagePreview;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession copyWith({
    String? id,
    String? title,
    String? characterId,
    String? selectedUserSettingId,
    bool clearSelectedUserSettingId = false,
    List<String>? selectedWorldBookIds,
    String? selectedPresetId,
    bool clearSelectedPresetId = false,
    String? currentLeafMessageId,
    bool clearCurrentLeafMessageId = false,
    String? lastMessagePreview,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      characterId: characterId ?? this.characterId,
      selectedUserSettingId: clearSelectedUserSettingId
          ? null
          : (selectedUserSettingId ?? this.selectedUserSettingId),
      selectedWorldBookIds: selectedWorldBookIds ?? this.selectedWorldBookIds,
      selectedPresetId: clearSelectedPresetId
          ? null
          : (selectedPresetId ?? this.selectedPresetId),
      currentLeafMessageId: clearCurrentLeafMessageId
          ? null
          : (currentLeafMessageId ?? this.currentLeafMessageId),
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ChatNode {
  const ChatNode({
    required this.id,
    required this.sessionId,
    required this.parentId,
    required this.role,
    required this.text,
    this.thinkingChain,
    required this.createdAt,
    required this.siblingOrder,
  });

  final String id;
  final String sessionId;
  final String? parentId;
  final ChatNodeRole role;
  final String text;
  final String? thinkingChain;
  final DateTime createdAt;
  final int siblingOrder;
}

class ChatSessionSummary {
  const ChatSessionSummary({
    required this.id,
    required this.title,
    required this.characterId,
    required this.lastMessagePreview,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String characterId;
  final String lastMessagePreview;
  final DateTime updatedAt;
}

class ChatSessionBundle {
  const ChatSessionBundle({
    required this.session,
    required this.activeMessages,
  });

  final ChatSession session;
  final List<ChatMessage> activeMessages;
}
