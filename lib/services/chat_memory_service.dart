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

  /// 将记忆列表格式化为注入到 Prompt 中的字符串（含引导语表头）。
  ///
  /// 同时服务于段标识 `longTermMemory` 与宏 `{{memory}}`，避免两处实现重复。
  static String formatMemoryContext(List<String> memories) {
    if (memories.isEmpty) return '';
    final config = memoryExtractionNotifier.value;
    final header = config.hasCustomInjectionPrompt
        ? config.customInjectionPrompt.trim()
        : '以下是角色记得的关于过去事件的信息：';
    return '$header\n${formatMemoryList(memories)}';
  }

  /// 仅渲染 `- 条目` 的纯列表（不含引导语表头）。
  ///
  /// 用于提取提示词中回填"已存在记忆"，避免把注入用的引导语表头带进提取任务。
  static String formatMemoryList(List<String> memories) {
    if (memories.isEmpty) return '';
    return memories.map((m) => '- $m').join('\n');
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
      // 提取任务只回填"已存在记忆"列表，不注入引导语表头。
      memoryContextWithHeader: false,
      extraVariables: cardData,
    );
    final extractionPrompt = ChatVariableService.resolveMacros(
      rawPrompt,
      state: macroState,
    );

    // 提取窗口刻意使用 interval（提取频率）：每次触发时送给提取模型的
    // 就是这一批新增对话。recentRounds 仅服务主聊天提示词的历史窗口，
    // 与提取无关，勿混用。
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

    final stopwatch = Stopwatch()..start();
    try {
      final result = await OpenAICompatibleApiService.instance
          .createChatCompletion(config, messages: requestMessages);
      stopwatch.stop();
      return result.text.trim();
    } catch (error, stack) {
      debugPrint('extractMemories failed: $error\n$stack');
      unawaited(
        ApiRequestLogService.appendExtractionFailure(
          label: '记忆提取失败',
          configName: config.name,
          model: config.model,
          baseUrl: config.baseUrl,
          error: error,
          durationMs: stopwatch.elapsedMilliseconds,
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
    return selectBranchMemories(
      all: all,
      pathMessageIds: pathMessageIds,
      count: count,
    );
  }

  /// 从 [all] 中按「分支位置」回溯选取最靠近当前叶子的 [count] 个记忆节点。
  ///
  /// 选取键是节点 id 在 [pathMessageIds]（根→叶有序）中的位置索引，而**不是**
  /// 记忆的创建时间：后者会被"在早期节点手动新增/编辑记忆"扰动，使该节点组因
  /// `last.createdAt` 变最新而被挤出注入集合（记忆点不被注入）。
  ///
  /// 规则：
  /// - `count <= 0` 或记忆节点数 `<= count` 时返回全部节点（0 视为无限制）；
  /// - 否则取索引最大（最靠近当前叶）的 [count] 个节点；
  /// - 节点间按分支顺序（根→叶）升序、节点内按 `createdAt` 升序展开，
  ///   保证注入文本的时间顺序自然。
  /// - 手动新增/编辑的记忆与自动提取的记忆同等对待。
  @visibleForTesting
  static List<MemoryNode> selectBranchMemories({
    required List<MemoryNode> all,
    required List<String> pathMessageIds,
    required int count,
  }) {
    if (all.isEmpty) return const [];

    // 节点 id -> 其在当前分支路径中的位置（首次出现优先）。
    final orderIndex = <String, int>{};
    for (var i = 0; i < pathMessageIds.length; i++) {
      orderIndex.putIfAbsent(pathMessageIds[i], () => i);
    }

    // 按 branchLeafId 分组，组内按 createdAt 升序排列。
    final grouped = <String, List<MemoryNode>>{};
    for (final m in all) {
      grouped.putIfAbsent(m.branchLeafId, () => <MemoryNode>[]).add(m);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    // 节点按分支位置升序（不在路径中的节点索引按 -1 处理，置于最前）。
    final sortedNodes = grouped.values.toList()
      ..sort(
        (a, b) => (orderIndex[a.first.branchLeafId] ?? -1)
            .compareTo(orderIndex[b.first.branchLeafId] ?? -1),
      );

    // count <= 0 或节点数不足 count 时取全部。
    if (count <= 0 || sortedNodes.length <= count) {
      return sortedNodes.expand((e) => e).toList();
    }

    // 取最靠近当前叶（索引最大）的 count 个节点，仍按分支顺序输出。
    final selected = sortedNodes.sublist(sortedNodes.length - count);
    return selected.expand((e) => e).toList();
  }

  Future<bool> tryExtractAndSave({
    required String sessionId,
    required String branchLeafId,
    required List<ChatMessage> messages,
    required String characterName,
    required String userName,
    String currentInput = '',
    Map<String, String> cardData = const {},
    Future<void> Function()? beforeCommit,
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
    await beforeCommit?.call();
    await ChatDatabaseService.instance.insertMemoriesInTx(toInsert);
    return true;
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
    // 编辑不改变"已处理消息水位"：继承该节点既有记忆的 sourceMessageIds 并集，
    // 避免手动编辑写出的空来源记录使提取计数回退、误触发多余提取。
    final existing = await ChatDatabaseService.instance.loadBranchMemories(
      sessionId,
      [branchLeafId],
    );
    final preservedSourceIds = <String>{
      for (final m in existing) ...m.sourceMessageIds,
    }.toList();

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
          sourceMessageIds: preservedSourceIds,
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

  Future<List<MemoryNode>> loadAllSessionMemories(String sessionId) async {
    return ChatDatabaseService.instance.loadAllSessionMemories(sessionId);
  }

  /// 从记忆集合还原"已处理消息"水位：所有记忆 `sourceMessageIds` 的并集。
  ///
  /// 不能用单条（最新）记忆的来源集合：手动新增/编辑记忆会写出空或单条的
  /// 来源记录，若以最新一条为准会使水位回退，导致提取计数虚高、误触发提取。
  @visibleForTesting
  static Set<String> processedMessageIds(List<MemoryNode> memories) {
    return <String>{
      for (final m in memories) ...m.sourceMessageIds,
    };
  }

  /// 统计 [allMessages] 中尚未被已处理水位覆盖的角色消息数量。
  ///
  /// [branchMemories] 为空时水位为空（全部角色消息都算新增）；否则水位取
  /// [processedMessageIds] 的并集结果。
  static int countNewAssistantMessages({
    required List<ChatMessage> allMessages,
    required List<MemoryNode> branchMemories,
  }) {
    if (branchMemories.isEmpty) {
      return allMessages.where((m) => !m.isMe).length;
    }
    final processedIds = processedMessageIds(branchMemories);
    return allMessages
        .where((m) => !m.isMe && m.id != null && !processedIds.contains(m.id))
        .length;
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
