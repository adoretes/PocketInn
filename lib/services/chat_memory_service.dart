import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/api_configs.dart';
import '../models/api_config.dart';
import '../models/chat_memory.dart';
import '../models/chat_message.dart';
import 'api_request_log_service.dart';
import 'chat_database_service.dart';
import 'chat_variable_service.dart';
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

以下是已存在的记忆，请勿提取与之语义重复或高度相近的内容：
{{memory}}
''';

  String _resolveExtractionPrompt() {
    final custom = memoryExtractionNotifier.value.customExtractionPrompt.trim();
    return custom.isNotEmpty ? custom : memoryExtractionPrompt;
  }

  /// 将记忆列表格式化为注入到 Prompt 中的字符串。
  ///
  /// 同时服务于段标识 `longTermMemory` 与宏 `{{memory}}`，避免两处实现重复。
  static String formatMemoryContext(List<String> memories) {
    if (memories.isEmpty) return '';
    final config = memoryExtractionNotifier.value;
    final header = config.hasCustomInjectionPrompt
        ? config.customInjectionPrompt.trim()
        : '以下是角色记得的关于过去事件的信息：';
    return '$header\n${memories.map((m) => '- $m').join('\n')}';
  }

  /// 按 `recentRounds` 截断消息列表，保留最后 N 轮对话（1 个用户消息 + 1 个助手回复）。
  ///
  /// 从末尾向前数 `recentRounds` 个助手消息，包含其前导用户消息。
  /// `recentRounds <= 0` 视为不截断。
  static List<ChatMessage> truncateToRecentRounds(
    List<ChatMessage> messages,
    int recentRounds,
  ) {
    if (recentRounds <= 0) return messages;
    int assistantCount = 0;
    for (int i = messages.length - 1; i >= 0; i--) {
      if (!messages[i].isMe) {
        assistantCount++;
        if (assistantCount == recentRounds) {
          // 包含此助手回复前导的用户消息（如果有）
          final cutIndex = (i > 0 && messages[i - 1].isMe) ? i - 1 : i;
          return cutIndex == 0 ? messages : messages.sublist(cutIndex);
        }
      }
    }
    return messages;
  }

  ResolvedApiConfig? get _extractionConfig {
    final configs = apiConfigsNotifier.value;
    final extractionModelId = memoryExtractionNotifier.value.extractionModelId;
    ApiConfig? provider;
    ApiModel? model;
    if (extractionModelId != null && extractionModelId.isNotEmpty) {
      outer:
      for (final c in configs) {
        for (final m in c.models) {
          if (m.id == extractionModelId) {
            provider = c;
            model = m;
            break outer;
          }
        }
      }
    }
    // 未显式指定时，回退到当前选中的模型（及其 provider）。
    if (provider == null || model == null) {
      final tuple = selectedApiModelTuple;
      if (tuple == null) return null;
      provider = tuple.provider;
      model = tuple.model;
    }
    return provider.resolve(model);
  }

  Future<String?> extractMemories({
    required List<ChatMessage> messages,
    required String characterName,
    required String userName,
    List<String> existingMemories = const [],
    String currentInput = '',
    Map<String, String> cardData = const {},
  }) async {
    if (messages.isEmpty) return null;

    final config = _extractionConfig?.copyWith();
    if (config == null) return null;

    final rawPrompt = _resolveExtractionPrompt();
    final lastUser = messages.reversed.cast<ChatMessage?>().firstWhere(
      (m) => m?.isMe == true,
      orElse: () => null,
    );
    final lastChar = messages.reversed.cast<ChatMessage?>().firstWhere(
      (m) => m?.isMe == false,
      orElse: () => null,
    );
    final macroState = PromptMacroState(
      characterName: characterName,
      userName: userName,
      currentInput: currentInput,
      lastUserMessage: lastUser?.text ?? '',
      lastCharMessage: lastChar?.text ?? '',
      memoryContext: existingMemories,
      extraVariables: cardData,
    );
    final extractionPrompt = ChatVariableService.resolveMacros(
      rawPrompt,
      state: macroState,
    );

    final truncated = truncateToRecentRounds(
      messages,
      memoryExtractionNotifier.value.interval,
    );
    final chatLog = truncated
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
    } catch (error, stack) {
      debugPrint('extractMemories failed: $error\n$stack');
      unawaited(
        ApiRequestLogService.instance.append(
          configName: config.name,
          model: config.model,
          method: 'POST',
          endpoint: config.baseUrl,
          success: false,
          durationMs: 0,
          errorMessage: error.toString(),
        ),
      );
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
    if (all.isEmpty) return [];

    // 按 branchLeafId 分组
    final grouped = <String, List<MemoryNode>>{};
    for (final m in all) {
      grouped.putIfAbsent(m.branchLeafId, () => []).add(m);
    }

    // 每个节点内按时间升序排列
    for (final list in grouped.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    // 按节点内最新记忆的创建时间升序排列（最早的节点在前）
    final sortedNodes = grouped.values.toList()
      ..sort((a, b) => a.last.createdAt.compareTo(b.last.createdAt));

    // count <= 0 表示无限制，合并所有节点
    if (count <= 0) {
      return sortedNodes.expand((e) => e).toList();
    }

    // 节点数不足 count 时直接合并返回
    if (sortedNodes.length <= count) {
      return sortedNodes.expand((e) => e).toList();
    }

    return sortedNodes.take(count).expand((e) => e).toList();
  }

  Future<bool> tryExtractAndSave({
    required String sessionId,
    required String branchLeafId,
    required List<ChatMessage> messages,
    required String characterName,
    required String userName,
    String currentInput = '',
    Map<String, String> cardData = const {},
  }) async {
    final pathIds = messages
        .where((m) => m.id != null)
        .map((m) => m.id!)
        .toList();
    final existingMemories = await getBranchMemories(
      sessionId: sessionId,
      pathMessageIds: pathIds,
    );
    final injectionMemories = existingMemories
        .map((m) => m.content)
        .toList();

    final extracted = await extractMemories(
      messages: messages,
      characterName: characterName,
      userName: userName,
      existingMemories: injectionMemories,
      currentInput: currentInput,
      cardData: cardData,
    );
    if (extracted == null || extracted.isEmpty) return false;

    final memoryLines = parseMemoryPoints(extracted);
    if (memoryLines.isEmpty) return false;

    final now = DateTime.now();
    final sourceIds = messages
        .where((m) => m.id != null)
        .map((m) => m.id!)
        .toList();

    final toInsert = <MemoryNode>[];
    for (final line in memoryLines) {
      toInsert.add(
        MemoryNode(
          id: _generateMemoryId(),
          sessionId: sessionId,
          branchLeafId: branchLeafId,
          content: line,
          sourceMessageIds: sourceIds,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    if (toInsert.isEmpty) return false;
    await ChatDatabaseService.instance.insertMemoriesInTx(toInsert);
    return true;
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

  Future<MemoryNode> addMemory({
    required String sessionId,
    required String branchLeafId,
    required String content,
    List<String> sourceMessageIds = const [],
  }) async {
    final now = DateTime.now();
    final memory = MemoryNode(
      id: _generateMemoryId(),
      sessionId: sessionId,
      branchLeafId: branchLeafId,
      content: content,
      sourceMessageIds: sourceMessageIds,
      isUserEdited: true,
      createdAt: now,
      updatedAt: now,
    );
    await ChatDatabaseService.instance.insertMemory(memory);
    return memory;
  }

  Future<void> replaceBranchMemories({
    required String sessionId,
    required String branchLeafId,
    required List<String> contents,
  }) async {
    final now = DateTime.now();
    final toInsert = <MemoryNode>[];
    for (final content in contents) {
      final trimmed = content.trim();
      if (trimmed.isEmpty) continue;
      toInsert.add(
        MemoryNode(
          id: _generateMemoryId(),
          sessionId: sessionId,
          branchLeafId: branchLeafId,
          content: trimmed,
          isUserEdited: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    await ChatDatabaseService.instance.replaceBranchMemoriesInTx(
      sessionId: sessionId,
      branchLeafId: branchLeafId,
      memories: toInsert,
    );
  }

  Future<void> deleteMemory(String memoryId) async {
    await ChatDatabaseService.instance.deleteMemory(memoryId);
  }

  Future<List<MemoryNode>> loadAllSessionMemories(String sessionId) async {
    return ChatDatabaseService.instance.loadAllSessionMemories(sessionId);
  }

  @visibleForTesting
  static List<String> parseMemoryPoints(String text) {
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
    final seq = _idSequence++;
    final rand = _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return 'memory-$micros-$seq-$rand';
  }

  static int _idSequence = 0;
  static final Random _random = Random();
}

ValueNotifier<MemoryExtractionConfig> memoryExtractionNotifier = ValueNotifier(
  const MemoryExtractionConfig(),
);

const Object _unset = Object();

void updateMemoryExtractionConfig({
  bool? enabled,
  int? interval,
  int? recentRounds,
  int? recallCount,
  Object? extractionModelId = _unset,
  String? customExtractionPrompt,
  String? customInjectionPrompt,
}) {
  final current = memoryExtractionNotifier.value;
  final next = current.copyWith(
    enabled: enabled ?? current.enabled,
    interval: interval ?? current.interval,
    recentRounds: recentRounds ?? current.recentRounds,
    recallCount: recallCount ?? current.recallCount,
    extractionModelId: extractionModelId == _unset
        ? current.extractionModelId
        : extractionModelId as String?,
    customExtractionPrompt:
        customExtractionPrompt ?? current.customExtractionPrompt,
    customInjectionPrompt:
        customInjectionPrompt ?? current.customInjectionPrompt,
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
  final customInjectionPrompt = storage.getString(
    'memory_custom_injection_prompt',
  );
  memoryExtractionNotifier.value = MemoryExtractionConfig(
    enabled: enabled ?? false,
    interval: interval ?? 5,
    recentRounds: recentRounds ?? 10,
    recallCount: recallCount ?? 3,
    extractionModelId: extractionModelId,
    customExtractionPrompt: customExtractionPrompt ?? '',
    customInjectionPrompt: customInjectionPrompt ?? '',
  );
}

void _persistMemoryConfig(MemoryExtractionConfig config) {
  final storage = StorageService.instance;
  unawaited(storage.setBool('memory_enabled', config.enabled));
  unawaited(storage.setInt('memory_interval', config.interval));
  unawaited(storage.setInt('memory_recent_rounds', config.recentRounds));
  unawaited(storage.setInt('memory_recall_count', config.recallCount));
  if (config.extractionModelId != null &&
      config.extractionModelId!.isNotEmpty) {
    unawaited(
      storage.setString(
        'memory_extraction_model_id',
        config.extractionModelId!,
      ),
    );
  } else {
    unawaited(storage.remove('memory_extraction_model_id'));
  }
  if (config.customExtractionPrompt.trim().isNotEmpty) {
    unawaited(
      storage.setString(
        'memory_custom_extraction_prompt',
        config.customExtractionPrompt,
      ),
    );
  } else {
    unawaited(storage.remove('memory_custom_extraction_prompt'));
  }
  if (config.customInjectionPrompt.trim().isNotEmpty) {
    unawaited(
      storage.setString(
        'memory_custom_injection_prompt',
        config.customInjectionPrompt,
      ),
    );
  } else {
    unawaited(storage.remove('memory_custom_injection_prompt'));
  }
}
