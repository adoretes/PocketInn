import '../models/character_card.dart';
import '../models/chat_message.dart';
import '../models/prompt_assembly.dart';
import '../models/preset.dart';
import '../models/world_book.dart';
import 'chat_variable_service.dart';

class PromptAssembler {
  const PromptAssembler._();

  static PromptAssemblyResult build(PromptAssemblyContext context) {
    final normalizedCard = normalizeToV2Card(context.characterCardData);
    final cardData = Map<String, dynamic>.from(
      normalizedCard['data'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );
    final activatedEntries = _activateWorldBookEntries(
      worldBooks: context.selectedWorldBooks,
      chatMessages: context.chatMessages,
      currentInput: context.currentInput,
    );
    final worldInfoBefore = _joinWorldBookContent(
      activatedEntries.where((item) => item.entry.position == 0).toList(),
      context,
    );
    final worldInfoAfter = _joinWorldBookContent(
      activatedEntries.where((item) => item.entry.position != 0).toList(),
      context,
    );
    final unusedOverrides = _buildUnusedOverrides(cardData, context);

    final rawSegments = <PromptSegment>[];
    for (final prompt in context.preset.prompts) {
      if (!prompt.enabled) {
        continue;
      }

      final content = _resolvePromptContent(
        prompt: prompt,
        cardData: cardData,
        context: context,
        worldInfoBefore: worldInfoBefore,
        worldInfoAfter: worldInfoAfter,
      );
      if (content.trim().isEmpty) {
        continue;
      }

      rawSegments.add(
        PromptSegment(
          role: prompt.role.trim().isEmpty ? 'system' : prompt.role.trim(),
          content: content.trim(),
          source: _sourceLabel(prompt),
          identifier: prompt.identifier,
        ),
      );
    }

    final messages = _buildOpenAiMessages(
      segments: rawSegments,
      context: context,
    );
    return PromptAssemblyResult(
      messages: messages,
      mergedText: _buildMergedText(_mergeAdjacentMessages(rawSegments)),
      activatedWorldBookEntries: activatedEntries,
      segments: rawSegments,
      unusedCharacterOverrides: unusedOverrides,
    );
  }

  static List<ActivatedWorldBookEntry> _activateWorldBookEntries({
    required List<WorldBook> worldBooks,
    required List<ChatMessage> chatMessages,
    required String currentInput,
  }) {
    final scanCorpus = [
      for (final message in chatMessages) message.text,
      currentInput,
    ].join('\n').toLowerCase();
    final activated = <ActivatedWorldBookEntry>[];
    final seen = <String>{};

    for (final book in worldBooks) {
      final sortedEntries = [...book.entries]
        ..sort((a, b) {
          final positionCompare = a.position.compareTo(b.position);
          if (positionCompare != 0) {
            return positionCompare;
          }
          return a.order.compareTo(b.order);
        });

      for (final entry in sortedEntries) {
        if (!entry.isEnabled) {
          continue;
        }
        final triggeredByConstant = entry.constant;
        final matchesKeywords = _matchesWorldBookEntry(entry, scanCorpus);
        if (!triggeredByConstant && !matchesKeywords) {
          continue;
        }

        final dedupeKey = '${entry.position}|${entry.content.trim()}';
        if (!seen.add(dedupeKey)) {
          continue;
        }

        activated.add(
          ActivatedWorldBookEntry(
            bookId: book.id,
            bookName: book.name,
            entry: entry,
            triggeredByConstant: triggeredByConstant,
          ),
        );
      }
    }

    activated.sort((a, b) {
      final positionCompare = a.entry.position.compareTo(b.entry.position);
      if (positionCompare != 0) {
        return positionCompare;
      }
      return a.entry.order.compareTo(b.entry.order);
    });
    return activated;
  }

  static bool _matchesWorldBookEntry(WorldBookEntry entry, String scanCorpus) {
    if (scanCorpus.trim().isEmpty) {
      return false;
    }

    final keywords = [
      ...entry.key,
      ...entry.keysecondary,
    ].map((item) => item.trim().toLowerCase()).where((item) => item.isNotEmpty);

    for (final keyword in keywords) {
      if (scanCorpus.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  static String _joinWorldBookContent(
    List<ActivatedWorldBookEntry> entries,
    PromptAssemblyContext context,
  ) {
    return entries
        .map((item) => _replaceVariables(item.entry.content, context))
        .where((item) => item.trim().isNotEmpty)
        .join('\n\n');
  }

  static List<UnusedCharacterOverride> _buildUnusedOverrides(
    Map<String, dynamic> cardData,
    PromptAssemblyContext context,
  ) {
    final overrides = <UnusedCharacterOverride>[];
    final systemPrompt = _replaceVariables(
      cardData['system_prompt'] as String? ?? '',
      context,
    ).trim();
    if (systemPrompt.isNotEmpty) {
      overrides.add(
        const UnusedCharacterOverride(
          field: 'system_prompt',
          content: '',
          reason: '角色卡字段已保留，本期不覆盖预设 main。',
        ),
      );
      overrides[overrides.length - 1] = UnusedCharacterOverride(
        field: 'system_prompt',
        content: systemPrompt,
        reason: '角色卡字段已保留，本期不覆盖预设 main。',
      );
    }

    final postHistoryInstructions = _replaceVariables(
      cardData['post_history_instructions'] as String? ?? '',
      context,
    ).trim();
    if (postHistoryInstructions.isNotEmpty) {
      overrides.add(
        UnusedCharacterOverride(
          field: 'post_history_instructions',
          content: postHistoryInstructions,
          reason: '角色卡字段已保留，本期不覆盖预设 jailbreak/post_history_instructions。',
        ),
      );
    }
    return overrides;
  }

  static String _resolvePromptContent({
    required PresetPrompt prompt,
    required Map<String, dynamic> cardData,
    required PromptAssemblyContext context,
    required String worldInfoBefore,
    required String worldInfoAfter,
  }) {
    final identifier = prompt.identifier;
    switch (identifier) {
      case 'personaDescription':
        return _replaceVariables(context.userSettingPrompt, context);
      case 'charDescription':
        return _replaceVariables(
          cardData['description'] as String? ?? '',
          context,
        );
      case 'charPersonality':
        return _replaceVariables(
          cardData['personality'] as String? ?? '',
          context,
        );
      case 'scenario':
        return _replaceVariables(
          cardData['scenario'] as String? ?? '',
          context,
        );
      case 'dialogueExamples':
        return _replaceExampleChat(
          cardData['mes_example'] as String? ?? '',
          context,
        );
      case 'chatHistory':
        return _replaceVariables(
          _formatChatHistory(context, context.preset),
          context,
        );
      case 'worldInfoBefore':
        return worldInfoBefore;
      case 'worldInfoAfter':
        return worldInfoAfter;
      case 'main':
      case 'jailbreak':
      case 'post_history_instructions':
      default:
        return _replaceVariables(prompt.content, context);
    }
  }

  static String _formatChatHistory(
    PromptAssemblyContext context,
    Preset preset,
  ) {
    final lines = <String>[];
    final newChatPrompt = preset.extra['new_chat_prompt'] as String? ?? '';
    final resolvedNewChatPrompt = _replaceVariables(
      newChatPrompt,
      context,
    ).trim();
    if (resolvedNewChatPrompt.isNotEmpty) {
      lines.add(resolvedNewChatPrompt);
    }
    for (final message in context.chatMessages) {
      final role = message.isMe ? 'user' : 'assistant';
      lines.add('$role: ${message.text}');
    }
    final currentInput = context.currentInput.trim();
    if (currentInput.isNotEmpty) {
      lines.add('user: $currentInput');
    }
    return lines.join('\n');
  }

  static String _replaceExampleChat(
    String input,
    PromptAssemblyContext context,
  ) {
    final exampleChatPrompt =
        context.preset.extra['new_example_chat_prompt'] as String? ??
        '[Example Chat]';
    return _replaceVariables(
      input.replaceAll('<START>', exampleChatPrompt),
      context,
    );
  }

  static List<PromptMessage> _buildOpenAiMessages({
    required List<PromptSegment> segments,
    required PromptAssemblyContext context,
  }) {
    final expanded = <PromptMessage>[];
    for (final segment in segments) {
      if (segment.identifier != 'chatHistory') {
        expanded.add(
          PromptMessage(
            role: segment.role,
            content: segment.content,
            sources: [segment.source],
          ),
        );
        continue;
      }

      final newChatPrompt =
          context.preset.extra['new_chat_prompt'] as String? ?? '';
      final resolvedNewChatPrompt = _replaceVariables(
        newChatPrompt,
        context,
      ).trim();
      if (resolvedNewChatPrompt.isNotEmpty) {
        expanded.add(
          PromptMessage(
            role: 'system',
            content: resolvedNewChatPrompt,
            sources: [segment.source],
          ),
        );
      }

      for (final chatMessage in context.chatMessages) {
        expanded.add(
          PromptMessage(
            role: chatMessage.isMe ? 'user' : 'assistant',
            content: _replaceVariables(chatMessage.text, context).trim(),
            sources: [segment.source],
          ),
        );
      }

      final currentInput = _replaceVariables(
        context.currentInput,
        context,
      ).trim();
      if (currentInput.isNotEmpty) {
        expanded.add(
          PromptMessage(
            role: 'user',
            content: currentInput,
            sources: [segment.source],
          ),
        );
      }
    }

    return _mergePromptMessages(expanded);
  }

  static String _replaceVariables(String input, PromptAssemblyContext context) {
    return ChatVariableService.replacePlaceholders(
      input,
      characterName: context.characterName,
      userName: context.userName,
    );
  }

  static String _sourceLabel(PresetPrompt prompt) {
    switch (prompt.identifier) {
      case 'personaDescription':
        return '用户设定';
      case 'charDescription':
        return '角色卡: description';
      case 'charPersonality':
        return '角色卡: personality';
      case 'scenario':
        return '角色卡: scenario';
      case 'dialogueExamples':
        return '角色卡: mes_example';
      case 'chatHistory':
        return '虚拟聊天记录';
      case 'worldInfoBefore':
        return '世界书: before';
      case 'worldInfoAfter':
        return '世界书: after';
      case 'main':
        return '预设: main';
      case 'jailbreak':
      case 'post_history_instructions':
        return '预设: jailbreak';
      default:
        return '预设: ${prompt.name}';
    }
  }

  static List<PromptMessage> _mergeAdjacentMessages(
    List<PromptSegment> segments,
  ) {
    if (segments.isEmpty) {
      return const [];
    }

    final merged = <PromptMessage>[];
    for (final segment in segments) {
      if (merged.isNotEmpty && merged.last.role == segment.role) {
        final previous = merged.removeLast();
        merged.add(
          PromptMessage(
            role: previous.role,
            content: '${previous.content}\n\n${segment.content}',
            sources: [...previous.sources, segment.source],
          ),
        );
        continue;
      }

      merged.add(
        PromptMessage(
          role: segment.role,
          content: segment.content,
          sources: [segment.source],
        ),
      );
    }
    return merged;
  }

  static List<PromptMessage> _mergePromptMessages(
    List<PromptMessage> messages,
  ) {
    if (messages.isEmpty) {
      return const [];
    }

    final merged = <PromptMessage>[];
    for (final message in messages) {
      if (merged.isNotEmpty && merged.last.role == message.role) {
        final previous = merged.removeLast();
        merged.add(
          PromptMessage(
            role: previous.role,
            content: '${previous.content}\n\n${message.content}',
            sources: [...previous.sources, ...message.sources],
          ),
        );
        continue;
      }

      merged.add(message);
    }
    return merged;
  }

  static String _buildMergedText(List<PromptMessage> messages) {
    return messages
        .map((message) => '[${message.role}]\n${message.content}')
        .join('\n\n');
  }
}
