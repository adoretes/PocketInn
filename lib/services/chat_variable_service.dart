class ChatVariableService {
  ChatVariableService._();

  static String replacePlaceholders(
    String input, {
    required String characterName,
    required String userName,
  }) {
    return input
        .replaceAll('{{char}}', characterName)
        .replaceAll('{{user}}', userName);
  }
}
