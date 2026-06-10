import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api_configs.dart';
import '../models/api_config.dart';
import '../models/chat_memory.dart';
import '../models/chat_message.dart';
import 'chat_database_service.dart';
import 'openai_compatible_api_service.dart';
import 'storage_service.dart';

class ChatMemoryService {
  ChatMemoryService._();

  static final ChatMemoryService instance = ChatMemoryService._();

  static const String memoryExtractionPrompt = '''
从对话记录中提取重要信息作为长期记忆。
只提取对后续对话有帮助的事实性信息，如：
- 用户偏好和性格特征
- 重要的事件和情节进展
- 角色之间的关系状态
- 关键决定和承诺
- 世界观设定和背景信息

请以简洁的中文输出记忆点，每条记忆点用 `- ` 开头。不要添加编号。
如果对话中没有值得记忆的信息，输出空字符串。
''';

  String _resolveExtractionPrompt() {
    final custom = memoryExtractionNotifier.value.customExtractionPrompt.trim();
    return custom.isNotEmpty ? custom : memoryExtractionPrompt;
  }

  ApiConfig? get _extractionConfig {
    final configs = apiConfigsNotifier.value;
    final modelId = memoryExtractionNotifier.value.extractionModelId;
    if (modelId != null && modelId.isNotEmpty) {
      for (final config in configs) {
        if (config.id == modelId) return config;
      }
    }
    for (final config in configs) {
      if (config.enabled) return config;
    }
    return null;
  }

  Future<String?> extractMemories({
    required List<ChatMessage> messages,
    required String characterName,
    required String userName,
  }) async {
    if (messages.isEmpty) return null;

    final config = _extractionConfig?.copyWith();
    if (config == null) return null;

    final extractionPrompt = _resolveExtractionPrompt();

    final chatLog = messages
        .map((m) => '${m.isMe ? userName : characterName}: ${m.text}')
        .join('\n');

    final requestMessages = [
      {'role': 'system', 'content': extractionPrompt},
      {'role': 'user', 'content': chatLog},
    ];

    try {
      final result = await OpenAICompatibleApiService.instance
          .createChatCompletion(config, messages: requestMessages);
      return result.text.trim();
    } catch (_) {
      return null;
    }
  }

  Future<List<MemoryNode>> getBranchMemories({
    required String sessionId,
    required List<String> pathMessageIds,
  }) async {
    if (pathMessageIds.isEmpty) return const [];
    return ChatDatabaseService.instance.loadBranchMemories(
      sessionId,
      pathMessageIds,
    );
  }

  Future<List<MemoryNode>> getRecentBranchMemories({
    required String sessionId,
    required List<String> pathMessageIds,
    required int count,
  }) async {
    final all = await getBranchMemories(
      sessionId: sessionId,
      pathMessageIds: pathMessageIds,
    );
    if (all.length <= count) return all;
    return all.sublist(0, count);
  }

  Future<bool> tryExtractAndSave({
    required String sessionId,
    required String branchLeafId,
    required List<ChatMessage> messages,
    required String characterName,
    required String userName,
  }) async {
    final extracted = await extractMemories(
      messages: messages,
      characterName: characterName,
      userName: userName,
    );
    if (extracted == null || extracted.isEmpty) return false;

    final memoryLines = _parseMemoryPoints(extracted);
    if (memoryLines.isEmpty) return false;

    final existingContents = await _loadBranchMemoryContents(
      sessionId: sessionId,
      branchLeafId: branchLeafId,
    );

    final now = DateTime.now();
    final sourceIds = messages
        .where((m) => m.id != null)
        .map((m) => m.id!)
        .toList();

    for (final line in memoryLines) {
      if (_isDuplicate(line, existingContents)) continue;
      final memory = MemoryNode(
        id: _generateMemoryId(),
        sessionId: sessionId,
        branchLeafId: branchLeafId,
        content: line,
        sourceMessageIds: sourceIds,
        createdAt: now,
        updatedAt: now,
      );
      await ChatDatabaseService.instance.insertMemory(memory);
    }
    return true;
  }

  Future<Set<String>> _loadBranchMemoryContents({
    required String sessionId,
    required String branchLeafId,
  }) async {
    final rows = await ChatDatabaseService.instance.loadAllSessionMemories(
      sessionId,
    );
    return rows
        .where((m) => m.branchLeafId == branchLeafId)
        .map((m) => m.content)
        .toSet();
  }

  bool _isDuplicate(String newContent, Set<String> existingContents) {
    final normalized = newContent.trim().toLowerCase();
    if (existingContents.any((e) => e.trim().toLowerCase() == normalized)) {
      return true;
    }
    final newWords = normalized.split(RegExp(r'\s+')).toSet();
    for (final existing in existingContents) {
      final existingWords = existing.trim().toLowerCase().split(
        RegExp(r'\s+'),
      ).toSet();
      final intersection = newWords.intersection(existingWords).length;
      final union = newWords.union(existingWords).length;
      if (union > 0 && intersection / union > 0.7) return true;
    }
    return false;
  }

  Future<void> updateMemory({
    required String memoryId,
    required String content,
  }) async {
    await ChatDatabaseService.instance.updateMemoryContent(
      memoryId: memoryId,
      content: content,
    );
  }

  Future<void> deleteMemory(String memoryId) async {
    await ChatDatabaseService.instance.deleteMemory(memoryId);
  }

  Future<List<MemoryNode>> loadAllSessionMemories(String sessionId) async {
    return ChatDatabaseService.instance.loadAllSessionMemories(sessionId);
  }

  List<String> _parseMemoryPoints(String text) {
    final lines = text.split('\n');
    final memories = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('- ')) {
        final content = trimmed.substring(2).trim();
        if (content.isNotEmpty) memories.add(content);
      } else if (trimmed.startsWith('* ') || trimmed.startsWith('• ')) {
        final content = trimmed.substring(2).trim();
        if (content.isNotEmpty) memories.add(content);
      }
    }
    return memories;
  }

  String _generateMemoryId() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    return 'memory-$micros-${_idSequence++}';
  }

  static int _idSequence = 0;
}

ValueNotifier<MemoryExtractionConfig> memoryExtractionNotifier =
    ValueNotifier(const MemoryExtractionConfig());

void updateMemoryExtractionConfig({
  bool? enabled,
  int? interval,
  int? recentRounds,
  int? recallCount,
  String? extractionModelId,
  bool clearExtractionModel = false,
  String? customExtractionPrompt,
  bool clearCustomExtractionPrompt = false,
}) {
  final current = memoryExtractionNotifier.value;
  final next = MemoryExtractionConfig(
    enabled: enabled ?? current.enabled,
    interval: interval ?? current.interval,
    recentRounds: recentRounds ?? current.recentRounds,
    recallCount: recallCount ?? current.recallCount,
    extractionModelId: clearExtractionModel
        ? null
        : (extractionModelId ?? current.extractionModelId),
    customExtractionPrompt: clearCustomExtractionPrompt
        ? ''
        : (customExtractionPrompt ?? current.customExtractionPrompt),
  );
  memoryExtractionNotifier.value = next;
  _persistMemoryConfig(next);
}

Future<void> initializeMemoryConfig() async {
  final storage = StorageService.instance;
  final enabled = storage.getBool('memory_enabled');
  final interval = storage.getInt('memory_interval');
  final recentRounds = storage.getInt('memory_recent_rounds');
  final recallCount = storage.getInt('memory_recall_count');
  final extractionModelId = storage.getString('memory_extraction_model_id');
  final customExtractionPrompt = storage.getString(
    'memory_custom_extraction_prompt',
  );
  memoryExtractionNotifier.value = MemoryExtractionConfig(
    enabled: enabled ?? false,
    interval: interval ?? 5,
    recentRounds: recentRounds ?? 10,
    recallCount: recallCount ?? 3,
    extractionModelId: extractionModelId,
    customExtractionPrompt: customExtractionPrompt ?? '',
  );
}

void _persistMemoryConfig(MemoryExtractionConfig config) {
  final storage = StorageService.instance;
  unawaited(storage.setBool('memory_enabled', config.enabled));
  unawaited(storage.setInt('memory_interval', config.interval));
  unawaited(storage.setInt('memory_recent_rounds', config.recentRounds));
  unawaited(storage.setInt('memory_recall_count', config.recallCount));
  if (config.extractionModelId != null && config.extractionModelId!.isNotEmpty) {
    unawaited(storage.setString('memory_extraction_model_id', config.extractionModelId!));
  } else {
    unawaited(storage.remove('memory_extraction_model_id'));
  }
  if (config.customExtractionPrompt.trim().isNotEmpty) {
    unawaited(storage.setString('memory_custom_extraction_prompt', config.customExtractionPrompt));
  } else {
    unawaited(storage.remove('memory_custom_extraction_prompt'));
  }
}
