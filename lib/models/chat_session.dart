import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_message.dart';

part 'chat_session.freezed.dart';

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

@freezed
abstract class ChatSession with _$ChatSession {
  const factory ChatSession({
    required String id,
    required String title,
    required String characterId,
    String? selectedUserSettingId,
    required List<String> selectedWorldBookIds,
    String? selectedPresetId,
    String? currentLeafMessageId,
    @Default('') String lastMessagePreview,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ChatSession;
}

@freezed
abstract class ChatNode with _$ChatNode {
  const factory ChatNode({
    required String id,
    required String sessionId,
    String? parentId,
    required ChatNodeRole role,
    required String text,
    String? thinkingChain,
    required DateTime createdAt,
    required int siblingOrder,
  }) = _ChatNode;
}

@freezed
abstract class ChatSessionSummary with _$ChatSessionSummary {
  const factory ChatSessionSummary({
    required String id,
    required String title,
    required String characterId,
    required String lastMessagePreview,
    required DateTime updatedAt,
  }) = _ChatSessionSummary;
}

@freezed
abstract class ChatSessionBundle with _$ChatSessionBundle {
  const factory ChatSessionBundle({
    required ChatSession session,
    required List<ChatMessage> activeMessages,
  }) = _ChatSessionBundle;
}
