import 'chat_variable_service.dart';

class ChatOpeningMessageBuilder {
  ChatOpeningMessageBuilder._();

  static List<String> build({
    required Map<String, dynamic> characterCardData,
    required String characterName,
    required String userName,
  }) {
    final data = characterCardData['data'];
    if (data is! Map) {
      return const [];
    }

    final messages = <String>[];
    final seen = <String>{};

    final firstMessage = (data['first_mes'] as String? ?? '').trim();
    if (firstMessage.isNotEmpty) {
      final replaced = ChatVariableService.replacePlaceholders(
        firstMessage,
        characterName: characterName,
        userName: userName,
      ).trim();
      if (replaced.isNotEmpty && seen.add(replaced)) {
        messages.add(replaced);
      }
    }

    final alternates = data['alternate_greetings'];
    if (alternates is List) {
      for (final item in alternates) {
        final text = item.toString().trim();
        if (text.isEmpty) {
          continue;
        }
        final replaced = ChatVariableService.replacePlaceholders(
          text,
          characterName: characterName,
          userName: userName,
        ).trim();
        if (replaced.isNotEmpty && seen.add(replaced)) {
          messages.add(replaced);
        }
      }
    }

    return messages;
  }
}
