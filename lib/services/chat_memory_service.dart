import 'dart:async';
import 'dart:convert';
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

/// 记忆操作类型（提取协议里 AI 可表达的动作）。
enum MemoryOpKind { add, update, invalidate }

/// AI 提取出的单条记忆操作。
class MemoryOp {
  const MemoryOp({
    required this.kind,
    this.id,
    this.content,
    this.importance,
    this.type,
    this.isPinned,
  });

  final MemoryOpKind kind;

  /// update / invalidate 的目标原始记忆 id。
  final String? id;
  final String? content;
  final int? importance;
  final MemoryType? type;
  final bool? isPinned;
}

/// 求值后的记忆视图：把原始记忆与路径上的差量折叠后的结果。
class ResolvedMemory {
  const ResolvedMemory({
    required this.origin,
    required this.content,
    required this.importance,
    required this.invalidated,
    this.type = MemoryType.other,
    this.isPinned = false,
  });

  final MemoryNode origin;
  final String content;
  final int importance;

  /// 当前分支上是否已失效。
  final bool invalidated;
  final MemoryType type;
  final bool isPinned;

  String get id => origin.id;
  String get branchLeafId => origin.branchLeafId;
}

/// 可变求值中间态。
class _MutableResolved {
  _MutableResolved(this.origin)
      : content = origin.content,
        importance = origin.importance,
        type = origin.type,
        isPinned = origin.isPinned,
        invalidated = false;

  final MemoryNode origin;
  String content;
  int importance;
  MemoryType type;
  bool isPinned;
  bool invalidated;
}

/// 一次提取落库的结果摘要。
class _ExtractionOutcome {
  const _ExtractionOutcome(this.status, {this.added = 0, this.updated = 0, this.invalidated = 0});

  final MemoryExtractionStatus status;
  final int added;
  final int updated;
  final int invalidated;
}

/// 用户在记忆编辑弹窗里提交的编辑意图类型。
enum MemoryEditKind { add, update, invalidate, restore, clearEdits, deleteOrigin }

/// 编辑弹窗的单条编辑意图。
///
/// 由界面层收集为一批后交给 [ChatMemoryService.applyMemoryEdits] 统一在事务内
/// 落库，保证要么全部生效、要么全部回滚。
class MemoryEditCommand {
  const MemoryEditCommand({
    required this.kind,
    this.targetMemoryId,
    this.content = '',
    this.importance = 3,
    this.type = MemoryType.other,
    this.isPinned = false,
    this.isOrigin = false,
  });

  final MemoryEditKind kind;

  /// update / invalidate / restore / clearEdits / deleteOrigin 的目标记忆 id。
  final String? targetMemoryId;
  final String content;
  final int importance;
  final MemoryType type;
  final bool isPinned;

  /// 该记忆来源节点是否就是当前节点：仅 update 用来区分「直接改原始行」与
  /// 「写分支差量」（与 [ChatMemoryService.updateMemory] 的语义一致）。
  final bool isOrigin;
}

class ChatMemoryService {
  ChatMemoryService._();

  static final ChatMemoryService instance = ChatMemoryService._();

  /// 求值结果缓存：key 为「会话 + 路径末端消息 + 是否含失效 + 记忆数据版本」。
  ///
  /// 同一路径在无记忆写入时可重复命中（侧栏刷新、打开编辑弹窗的两次求值等），
  /// 避免每次都全量读库 + 折叠。任何记忆写入都会让
  /// `ChatDatabaseService.memoryChangeNotifier` 自增，从而整体失效。
  final Map<String, List<ResolvedMemory>> _resolveCache =
      <String, List<ResolvedMemory>>{};
  static const int _resolveCacheLimit = 64;

  /// 清空求值缓存（数据整体重置时调用）。
  void clearResolveCache() => _resolveCache.clear();

  void _putResolveCache(String key, List<ResolvedMemory> value) {
    if (_resolveCache.length >= _resolveCacheLimit) {
      // 简单淘汰：移除最早插入的一项（Dart Map 保持插入顺序）。
      _resolveCache.remove(_resolveCache.keys.first);
    }
    _resolveCache[key] = value;
  }

  /// 内置默认提取提示词。`{{memory}}` 会被替换为带 id 的现有记忆列表。
  static const String memoryExtractionPrompt = '''
你是长期记忆管理器。请阅读对话与「现有记忆」，决定需要新增、修正或失效哪些记忆。

现有记忆（格式：- [id] [类型·常驻?] 内容（重要度N））：
{{memory}}

可执行操作：
- add：新增一条记忆，给出 content、importance(1-5)、type 与 isPinned；
- update：修正已有记忆，给出 id 以及新的 content / importance / type / isPinned；
- invalidate：当旧记忆被剧情推翻或不再成立时使其失效，给出 id。

type 取值：fact(事实)、preference(偏好)、event(剧情)、relationship(关系)、commitment(承诺)、setting(设定)、other(其他)。
isPinned=true 表示“常驻记忆”：每次对话都注入，除非用户明确要求，否则只对长期稳定、必须一直生效的设定或承诺使用。

要求：
- 只提取对后续对话有帮助的事实：用户偏好、重要事件与剧情进展、角色关系状态、关键决定与承诺、世界观设定。
- 语义重复的内容不要 add，应 update 已有条目。
- 新信息明确推翻旧信息时，update 或 invalidate 旧条目，不要新增相互矛盾的记忆。
- 没有值得记忆或修改的内容时，输出 {"ops": []}。
- 只输出严格 JSON，不要输出任何解释或 Markdown 代码块：
{"ops": [{"op": "add", "content": "...", "importance": 4, "type": "fact", "isPinned": false}, {"op": "update", "id": "memory-...", "content": "...", "importance": 5, "type": "relationship", "isPinned": true}, {"op": "invalidate", "id": "memory-..."}]}
''';

  /// 自定义提取提示词缺失输出协议时追加的固定段落。
  static const String memoryOutputProtocol = '''
请只输出严格 JSON，格式：
{"ops": [{"op": "add", "content": "...", "importance": 4, "type": "fact", "isPinned": false}, {"op": "update", "id": "memory-...", "content": "...", "importance": 5, "type": "relationship", "isPinned": true}, {"op": "invalidate", "id": "memory-..."}]}
type 可选：fact/preference/event/relationship/commitment/setting/other；isPinned=true 表示常驻记忆。
没有需要记录或修改的内容时输出 {"ops": []}。''';

  String _resolveExtractionPrompt() {
    final custom = memoryExtractionNotifier.value.customExtractionPrompt.trim();
    if (custom.isEmpty) return memoryExtractionPrompt;
    var prompt = custom;
    if (!prompt.contains('{{memory}}')) {
      prompt = '$prompt\n\n现有记忆（格式：- [id] 内容（重要度N））：\n{{memory}}';
    }
    return '$prompt\n\n$memoryOutputProtocol';
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

  /// 将求值后的记忆渲染为带 id 与重要度的提取上下文行。
  static String formatMemoryLinesForExtraction(List<ResolvedMemory> memories) {
    if (memories.isEmpty) return '';
    return memories
        .map(
          (m) => '- [${m.id}] [${m.type.label}${m.isPinned ? '·常驻' : ''}] '
              '${m.content}（重要度${m.importance}）',
        )
        .join('\n');
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

  /// 返回被 `recentRounds` 窗口裁掉、位于窗口之前的消息（保持原顺序）。
  ///
  /// 长期记忆召回只覆盖已滑出主对话窗口的历史，与提示词中的「最近 N 轮对话」
  /// 互补而不重复；窗口包含全部历史（`recentRounds <= 0` 或历史不足）时返回空表。
  static List<ChatMessage> messagesBeforeWindow(
    List<ChatMessage> messages,
    int recentRounds,
  ) {
    final window = truncateToRecentRounds(messages, recentRounds);
    final cut = messages.length - window.length;
    return cut <= 0 ? const <ChatMessage>[] : messages.sublist(0, cut);
  }

  ResolvedApiConfig? get _extractionConfig {
    final configs = apiConfigsNotifier.value;
    final extractionModelId = memoryExtractionNotifier.value.extractionModelId;
    ApiConfig? provider;
    ApiModel? model;
    if (extractionModelId != null && extractionModelId.isNotEmpty) {
      outer:
      for (final c in configs) {
        if (!c.enabled) continue;
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
    List<ResolvedMemory> existingMemories = const [],
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
      memoryContext: [formatMemoryLinesForExtraction(existingMemories)]
          .where((line) => line.isNotEmpty)
          .toList(),
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

  // ==================== 分支求值 ====================

  /// 求值某条路径上的记忆状态。
  ///
  /// [pathMessageIds] 必须是从根到叶的消息 id（有序）。返回的列表默认只含
  /// 仍有效（未被 invalidate）的记忆，并按分支位置、创建时间升序排列。
  Future<List<ResolvedMemory>> resolveMemories({
    required String sessionId,
    required List<String> pathMessageIds,
    bool includeInvalidated = false,
  }) async {
    if (pathMessageIds.isEmpty) return const [];

    // 同一叶节点唯一确定一条祖先链，故可用「叶子 + 是否含失效 + 数据版本」
    // 作为缓存键；记忆数据一旦写入，版本自增即整体失效，避免读到旧结果。
    final version = ChatDatabaseService.instance.memoryChangeNotifier.value;
    final cacheKey =
        '$sessionId\u0000${pathMessageIds.last}\u0000${pathMessageIds.length}'
        '\u0000$includeInvalidated\u0000$version';
    final cached = _resolveCache[cacheKey];
    if (cached != null) return cached;

    // 按路径裁剪：只查这条路径上的记忆与差量，不拉取兄弟分支的整表数据。
    final memories = await ChatDatabaseService.instance.loadBranchMemories(
      sessionId,
      pathMessageIds,
    );
    final diffs = await ChatDatabaseService.instance.loadBranchMemoryDiffs(
      sessionId,
      pathMessageIds,
    );
    final resolved = List<ResolvedMemory>.unmodifiable(
      resolveFromData(
        memories: memories,
        diffs: diffs,
        pathMessageIds: pathMessageIds,
        includeInvalidated: includeInvalidated,
      ),
    );
    _putResolveCache(cacheKey, resolved);
    return resolved;
  }

  /// 求值到某条消息时刻的记忆状态（自动补全祖先路径）。
  Future<List<ResolvedMemory>> resolveMemoriesAtMessage({
    required String sessionId,
    required String messageId,
    bool includeInvalidated = false,
  }) async {
    final ancestors = await ChatDatabaseService.instance.loadMessageAncestorIds(
      messageId,
    );
    if (ancestors.isEmpty) return const [];
    return resolveMemories(
      sessionId: sessionId,
      pathMessageIds: ancestors.reversed.toList(growable: false),
      includeInvalidated: includeInvalidated,
    );
  }

  /// 纯函数求值，便于单测。
  @visibleForTesting
  static List<ResolvedMemory> resolveFromData({
    required List<MemoryNode> memories,
    required List<MemoryDiff> diffs,
    required List<String> pathMessageIds,
    bool includeInvalidated = false,
  }) {
    final index = <String, int>{};
    for (var i = 0; i < pathMessageIds.length; i++) {
      index.putIfAbsent(pathMessageIds[i], () => i);
    }
    final pathSet = index.keys.toSet();

    final origins = memories
        .where((m) => pathSet.contains(m.branchLeafId))
        .toList(growable: false);
    final states = <String, _MutableResolved>{};
    for (final memory in origins) {
      states[memory.id] = _MutableResolved(memory);
    }
    if (states.isEmpty) return const [];

    int positionOf(String branchLeafId) => index[branchLeafId] ?? -1;

    final pathDiffs = diffs
        .where(
          (d) =>
              pathSet.contains(d.branchLeafId) &&
              states.containsKey(d.targetMemoryId),
        )
        .toList()
      ..sort((a, b) {
        final byPosition = positionOf(a.branchLeafId).compareTo(
          positionOf(b.branchLeafId),
        );
        if (byPosition != 0) return byPosition;
        final byCreated = a.createdAt.compareTo(b.createdAt);
        if (byCreated != 0) return byCreated;
        return a.id.compareTo(b.id);
      });

    for (final diff in pathDiffs) {
      final state = states[diff.targetMemoryId]!;
      switch (diff.kind) {
        case MemoryDiffKind.update:
          final content = diff.content;
          if (content != null && content.trim().isNotEmpty) {
            state.content = content;
          }
          final importance = diff.importance;
          if (importance != null) {
            state.importance = importance.clamp(1, 5);
          }
          final type = diff.type;
          if (type != null) {
            state.type = type;
          }
          final isPinned = diff.isPinned;
          if (isPinned != null) {
            state.isPinned = isPinned;
          }
        case MemoryDiffKind.invalidate:
          state.invalidated = true;
        case MemoryDiffKind.restore:
          state.invalidated = false;
      }
    }

    final result = <ResolvedMemory>[
      for (final state in states.values)
        if (includeInvalidated || !state.invalidated)
          ResolvedMemory(
            origin: state.origin,
            content: state.content,
            importance: state.importance,
            invalidated: state.invalidated,
            type: state.type,
            isPinned: state.isPinned,
          ),
    ];
    result.sort((a, b) {
      final byPosition = positionOf(a.branchLeafId).compareTo(
        positionOf(b.branchLeafId),
      );
      if (byPosition != 0) return byPosition;
      final byCreated = a.origin.createdAt.compareTo(b.origin.createdAt);
      if (byCreated != 0) return byCreated;
      return a.id.compareTo(b.id);
    });
    return result;
  }

  // ==================== 召回排序 ====================

  /// 从候选记忆里按「相关性 + 重要度 + 新近度」选出 [count] 条，并按时间顺序输出。
  ///
  /// - 相关性：查询与记忆内容的轻量词项重合度（0~1），空查询为 0；
  /// - 重要度：1~5 归一化到 0~1；
  /// - 新近度：记忆来源节点在路径中的相对位置（0~1）。
  /// 综合分 = 0.65*相关性 + 0.25*重要度 + 0.10*新近度。
  @visibleForTesting
  static List<ResolvedMemory> rankMemories({
    required List<ResolvedMemory> all,
    required List<String> pathMessageIds,
    required String query,
    required int count,
  }) {
    if (all.isEmpty) return const [];
    final index = <String, int>{};
    for (var i = 0; i < pathMessageIds.length; i++) {
      index.putIfAbsent(pathMessageIds[i], () => i);
    }
    final maxPosition = pathMessageIds.isEmpty
        ? 1
        : (pathMessageIds.length - 1).clamp(1, 1 << 30);

    double recencyOf(ResolvedMemory memory) {
      final position = index[memory.branchLeafId] ?? 0;
      return maxPosition == 0 ? 0 : (position / maxPosition).clamp(0.0, 1.0);
    }

    double importanceOf(ResolvedMemory memory) {
      return ((memory.importance.clamp(1, 5) - 1) / 4).toDouble();
    }

    final pinned = all.where((memory) => memory.isPinned).toList();
    final normal = all.where((memory) => !memory.isPinned).toList();

    final scored = <({ResolvedMemory memory, double score})>[
      for (final memory in normal)
        (
          memory: memory,
          score: 0.65 * _relevance(query, memory.content) +
              0.25 * importanceOf(memory) +
              0.10 * recencyOf(memory),
        ),
    ]..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        final byPosition = (index[b.memory.branchLeafId] ?? -1).compareTo(
          index[a.memory.branchLeafId] ?? -1,
        );
        if (byPosition != 0) return byPosition;
        final byCreated = b.memory.origin.createdAt.compareTo(
          a.memory.origin.createdAt,
        );
        if (byCreated != 0) return byCreated;
        return a.memory.id.compareTo(b.memory.id);
      });

    // 常驻记忆无条件入选（不占用召回条数额度）；其余按综合分取前 count 条。
    final selected = <ResolvedMemory>[
      ...pinned,
      if (count <= 0)
        ...scored.map((e) => e.memory)
      else
        ...scored.take(count).map((e) => e.memory),
    ];

    selected.sort((a, b) {
      final byPosition = (index[a.branchLeafId] ?? -1).compareTo(
        index[b.branchLeafId] ?? -1,
      );
      if (byPosition != 0) return byPosition;
      final byCreated = a.origin.createdAt.compareTo(b.origin.createdAt);
      if (byCreated != 0) return byCreated;
      return a.id.compareTo(b.id);
    });
    return selected;
  }

  static Set<String> _tokenize(String text) {
    final lower = text.toLowerCase();
    final tokens = <String>{};
    for (final match in RegExp(r'[a-z0-9]+').allMatches(lower)) {
      final value = match.group(0);
      if (value != null && value.isNotEmpty) tokens.add(value);
    }
    for (final run in RegExp(r'[\u4e00-\u9fff]+').allMatches(lower)) {
      final chars = run.group(0)!.split('');
      for (var i = 0; i < chars.length; i++) {
        tokens.add(chars[i]);
        if (i + 1 < chars.length) tokens.add(chars[i] + chars[i + 1]);
      }
    }
    return tokens;
  }

  static double _relevance(String query, String content) {
    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return 0;
    final contentTokens = _tokenize(content);
    if (contentTokens.isEmpty) return 0;
    var hits = 0;
    for (final token in queryTokens) {
      if (contentTokens.contains(token)) hits++;
    }
    return hits / queryTokens.length;
  }

  /// 召回：在完整路径上求值（让窗口内的 update/invalidate 也修正旧记忆），
  /// 但只召回来源位于最近窗口之前的记忆，避免与最近对话重复注入。
  Future<List<ResolvedMemory>> getRecallMemories({
    required String sessionId,
    required List<String> allPathIds,
    required List<String> windowPathIds,
    required String query,
    required int count,
  }) async {
    if (allPathIds.isEmpty || windowPathIds.isEmpty) return const [];
    final resolved = await resolveMemories(
      sessionId: sessionId,
      pathMessageIds: allPathIds,
    );
    final windowSet = windowPathIds.toSet();
    final candidates = resolved
        .where((m) => windowSet.contains(m.branchLeafId))
        .toList(growable: false);
    return rankMemories(
      all: candidates,
      pathMessageIds: allPathIds,
      query: query,
      count: count,
    );
  }

  // ==================== 维护 API ====================

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

  /// 当前路径上的提取运行记录（只保留锚点在路径中的）。
  Future<List<MemoryExtractionRun>> getExtractionRuns({
    required String sessionId,
    required List<String> pathMessageIds,
  }) async {
    if (pathMessageIds.isEmpty) return const [];
    final all = await ChatDatabaseService.instance
        .loadAllSessionExtractionRuns(sessionId);
    final pathSet = pathMessageIds.toSet();
    return all
        .where((run) => pathSet.contains(run.branchLeafId))
        .toList(growable: false);
  }

  Future<MemoryNode> addMemory({
    required String sessionId,
    required String branchLeafId,
    required String content,
    int importance = 3,
    MemoryType type = MemoryType.other,
    bool isPinned = false,
    List<String> sourceMessageIds = const [],
  }) async {
    final now = DateTime.now();
    final memory = MemoryNode(
      id: _generateId('memory'),
      sessionId: sessionId,
      branchLeafId: branchLeafId,
      content: content.trim(),
      sourceMessageIds: sourceMessageIds,
      isUserEdited: true,
      importance: importance.clamp(1, 5),
      type: type,
      isPinned: isPinned,
      createdAt: now,
      updatedAt: now,
    );
    await ChatDatabaseService.instance.insertMemory(memory);
    return memory;
  }

  /// 修改一条可见记忆。
  ///
  /// 当前节点即来源节点时直接更新原始记忆；否则写 update 差量，
  /// 只影响当前分支及其后代，不污染兄弟分支。
  Future<void> updateMemory({
    required String sessionId,
    required String atMessageId,
    required String memoryId,
    required String content,
    required int importance,
    MemoryType? type,
    bool? isPinned,
  }) async {
    final origin = await ChatDatabaseService.instance.loadMemoryById(memoryId);
    if (origin == null) {
      throw StateError('记忆不存在：$memoryId');
    }
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw StateError('记忆内容不能为空');
    }
    if (origin.branchLeafId == atMessageId) {
      await ChatDatabaseService.instance.updateMemoryRow(
        memoryId: memoryId,
        content: trimmed,
        importance: importance.clamp(1, 5),
        type: type,
        isPinned: isPinned,
      );
      return;
    }
    final now = DateTime.now();
    await ChatDatabaseService.instance.insertMemoryDiff(
      MemoryDiff(
        id: _generateId('memdiff'),
        sessionId: sessionId,
        branchLeafId: atMessageId,
        targetMemoryId: memoryId,
        kind: MemoryDiffKind.update,
        content: trimmed,
        importance: importance.clamp(1, 5),
        type: type,
        isPinned: isPinned,
        isUserEdited: true,
        createdAt: now,
      ),
    );
  }

  /// 使一条记忆在当前分支失效（后续召回与提取均不再包含）。
  Future<void> invalidateMemory({
    required String sessionId,
    required String atMessageId,
    required String memoryId,
  }) async {
    final now = DateTime.now();
    await ChatDatabaseService.instance.insertMemoryDiff(
      MemoryDiff(
        id: _generateId('memdiff'),
        sessionId: sessionId,
        branchLeafId: atMessageId,
        targetMemoryId: memoryId,
        kind: MemoryDiffKind.invalidate,
        isUserEdited: true,
        createdAt: now,
      ),
    );
  }

  /// 在当前分支撤销失效（恢复记忆）。写入 restore 差量，可被后续无效化覆盖。
  Future<void> restoreMemory({
    required String sessionId,
    required String atMessageId,
    required String memoryId,
  }) async {
    final now = DateTime.now();
    await ChatDatabaseService.instance.insertMemoryDiff(
      MemoryDiff(
        id: _generateId('memdiff'),
        sessionId: sessionId,
        branchLeafId: atMessageId,
        targetMemoryId: memoryId,
        kind: MemoryDiffKind.restore,
        isUserEdited: true,
        createdAt: now,
      ),
    );
  }

  /// 清除当前节点对该记忆的所有改动（update / invalidate / restore 差量），
  /// 使其回退到祖先节点状态。用于“消除这次编辑”，不触碰原始记忆。
  Future<void> clearMemoryEditsAtNode({
    required String sessionId,
    required String atMessageId,
    required String memoryId,
  }) async {
    await ChatDatabaseService.instance.deleteMemoryDiffsAtNode(
      sessionId: sessionId,
      branchLeafId: atMessageId,
      targetMemoryId: memoryId,
    );
  }

  /// 物理删除原始记忆（仅来源节点允许）。其差量随外键级联清理，
  /// 所有后代分支都将不再看到这条记忆。
  Future<void> deleteMemoryAtOrigin({
    required String sessionId,
    required String memoryId,
  }) async {
    await ChatDatabaseService.instance.deleteMemoryById(memoryId);
  }

  /// 批量应用一次编辑弹窗的全部改动（原子）。
  ///
  /// 先整体校验（内容为空等）再交给数据库事务落库，任一步失败都不会留下
  /// 半提交状态；调用方可在失败后安全重试而不会重复插入。
  Future<void> applyMemoryEdits({
    required String sessionId,
    required String atMessageId,
    required List<MemoryEditCommand> commands,
  }) async {
    final now = DateTime.now();
    final newMemories = <MemoryNode>[];
    final newDiffs = <MemoryDiff>[];
    final deleteIds = <String>[];
    final rowUpdates = <MemoryRowUpdate>[];
    final clearTargets = <DiffClearTarget>[];

    for (final command in commands) {
      switch (command.kind) {
        case MemoryEditKind.add:
          final content = command.content.trim();
          if (content.isEmpty) continue; // 空的新增条目直接跳过
          newMemories.add(
            MemoryNode(
              id: _generateId('memory'),
              sessionId: sessionId,
              branchLeafId: atMessageId,
              content: content,
              sourceMessageIds: [atMessageId],
              isUserEdited: true,
              importance: command.importance.clamp(1, 5),
              type: command.type,
              isPinned: command.isPinned,
              createdAt: now,
              updatedAt: now,
            ),
          );
        case MemoryEditKind.update:
          final id = _requireTarget(command);
          final content = command.content.trim();
          if (content.isEmpty) {
            throw StateError('记忆内容不能为空');
          }
          if (command.isOrigin) {
            rowUpdates.add((
              memoryId: id,
              content: content,
              importance: command.importance.clamp(1, 5),
              type: command.type,
              isPinned: command.isPinned,
            ));
          } else {
            newDiffs.add(
              MemoryDiff(
                id: _generateId('memdiff'),
                sessionId: sessionId,
                branchLeafId: atMessageId,
                targetMemoryId: id,
                kind: MemoryDiffKind.update,
                content: content,
                importance: command.importance.clamp(1, 5),
                type: command.type,
                isPinned: command.isPinned,
                isUserEdited: true,
                createdAt: now,
              ),
            );
          }
        case MemoryEditKind.invalidate:
          final id = _requireTarget(command);
          newDiffs.add(
            MemoryDiff(
              id: _generateId('memdiff'),
              sessionId: sessionId,
              branchLeafId: atMessageId,
              targetMemoryId: id,
              kind: MemoryDiffKind.invalidate,
              isUserEdited: true,
              createdAt: now,
            ),
          );
        case MemoryEditKind.restore:
          final id = _requireTarget(command);
          newDiffs.add(
            MemoryDiff(
              id: _generateId('memdiff'),
              sessionId: sessionId,
              branchLeafId: atMessageId,
              targetMemoryId: id,
              kind: MemoryDiffKind.restore,
              isUserEdited: true,
              createdAt: now,
            ),
          );
        case MemoryEditKind.clearEdits:
          final id = _requireTarget(command);
          clearTargets.add((branchLeafId: atMessageId, targetMemoryId: id));
        case MemoryEditKind.deleteOrigin:
          final id = _requireTarget(command);
          deleteIds.add(id);
      }
    }

    await ChatDatabaseService.instance.applyMemoryEditsTx(
      sessionId: sessionId,
      newMemories: newMemories,
      newDiffs: newDiffs,
      deleteMemoryIds: deleteIds,
      rowUpdates: rowUpdates,
      clearDiffTargets: clearTargets,
    );
  }

  static String _requireTarget(MemoryEditCommand command) {
    final id = command.targetMemoryId;
    if (id == null || id.isEmpty) {
      throw StateError('编辑目标记忆不能为空');
    }
    return id;
  }

  Future<List<MemoryNode>> loadAllSessionMemories(String sessionId) async {
    return ChatDatabaseService.instance.loadAllSessionMemories(sessionId);
  }

  // ==================== 水位与提取闭环 ====================

  /// 提取水位：所有运行记录实际处理过的消息 id 并集。
  @visibleForTesting
  static Set<String> processedMessageIds(List<MemoryExtractionRun> runs) {
    return <String>{
      for (final run in runs) ...run.processedMessageIds,
    };
  }

  /// 旧数据（v7 之前无运行记录）的水位回退：记忆来源并集。
  @visibleForTesting
  static Set<String> legacyProcessedMessageIds(List<MemoryNode> memories) {
    return <String>{
      for (final memory in memories) ...memory.sourceMessageIds,
    };
  }

  /// 统计 [allMessages] 中尚未被提取水位覆盖的角色消息数量。
  ///
  /// 优先使用运行记录水位；尚无任何运行记录时回退到旧记忆来源并集，
  /// 保证升级后不会把历史消息全部当作新增。
  static int countNewAssistantMessages({
    required List<ChatMessage> allMessages,
    required List<MemoryExtractionRun> runs,
    List<MemoryNode> memories = const [],
  }) {
    final processed = runs.isEmpty
        ? legacyProcessedMessageIds(memories)
        : processedMessageIds(runs);
    return allMessages
        .where((m) => !m.isMe && m.id != null && !processed.contains(m.id))
        .length;
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
        .toList(growable: false);
    if (pathIds.isEmpty) return false;

    final resolved = await resolveMemories(
      sessionId: sessionId,
      pathMessageIds: pathIds,
    );

    final extracted = await extractMemories(
      messages: messages,
      characterName: characterName,
      userName: userName,
      existingMemories: resolved,
      currentInput: currentInput,
      cardData: cardData,
    );

    final windowMessages = truncateToRecentRounds(
      messages,
      memoryExtractionNotifier.value.interval,
    );
    final processedIds = windowMessages
        .where((m) => m.id != null)
        .map((m) => m.id!)
        .toList(growable: false);

    // 首次运行（该分支尚无运行记录）时，把旧记忆来源并集并入水位，
    // 避免升级后把历史消息全部重提一遍。
    final existingRuns = await getExtractionRuns(
      sessionId: sessionId,
      pathMessageIds: pathIds,
    );
    if (existingRuns.isEmpty) {
      final pathSet = pathIds.toSet();
      final legacy = legacyProcessedMessageIds(
        resolved.map((m) => m.origin).toList(growable: false),
      );
      for (final id in legacy) {
        if (pathSet.contains(id) && !processedIds.contains(id)) {
          processedIds.add(id);
        }
      }
    }

    await beforeCommit?.call();
    final outcome = await _applyExtracted(
      sessionId: sessionId,
      branchLeafId: branchLeafId,
      extracted: extracted,
      resolved: resolved,
      processedIds: processedIds,
      characterName: characterName,
      userName: userName,
      currentInput: currentInput,
      allowEmptyAsNone: memoryExtractionNotifier
          .value
          .hasCustomExtractionPrompt,
    );
    return outcome.status == MemoryExtractionStatus.applied;
  }

  /// 重试一次失败的提取：使用运行记录保存的原消息集合与锚点重新请求。
  Future<bool> retryExtraction({
    required String sessionId,
    required String anchorMessageId,
  }) async {
    final runs = await ChatDatabaseService.instance
        .loadAllSessionExtractionRuns(sessionId);
    MemoryExtractionRun? run;
    for (final item in runs) {
      if (item.branchLeafId == anchorMessageId) {
        run = item;
        break;
      }
    }
    if (run == null) return false;

    final messages = await ChatDatabaseService.instance.loadMessagesByIds(
      run.processedMessageIds,
    );
    if (messages.isEmpty) {
      await ChatDatabaseService.instance.upsertExtractionRun(
        run.copyWith(
          status: MemoryExtractionStatus.failed,
          errorMessage: '原消息已不存在，无法重试',
          createdAt: DateTime.now(),
        ),
      );
      return false;
    }

    final ancestors = await ChatDatabaseService.instance.loadMessageAncestorIds(
      anchorMessageId,
    );
    final pathIds = ancestors.reversed.toList(growable: false);
    final resolved = await resolveMemories(
      sessionId: sessionId,
      pathMessageIds: pathIds,
    );

    final extracted = await extractMemories(
      messages: messages,
      characterName: run.characterName.isEmpty ? '角色' : run.characterName,
      userName: run.userName.isEmpty ? '用户' : run.userName,
      existingMemories: resolved,
      currentInput: run.currentInput,
    );

    final outcome = await _applyExtracted(
      sessionId: sessionId,
      branchLeafId: anchorMessageId,
      extracted: extracted,
      resolved: resolved,
      processedIds: run.processedMessageIds,
      characterName: run.characterName,
      userName: run.userName,
      currentInput: run.currentInput,
      allowEmptyAsNone: true,
    );
    return outcome.status == MemoryExtractionStatus.applied;
  }

  /// 目标记忆在「提取开始时」的原始快照。
  ///
  /// 必须取 [ResolvedMemory.origin] 的原始行内容/重要度/类型/常驻，而不是折叠了
  /// 分支差量后的 `content` 等：`applyMemoryExtractionTx` 校验的是
  /// `chat_memories` 原始行是否被并发修改，两者口径必须一致，否则一条曾在
  /// 分支上被 update 过的记忆会永远与原始行不一致而被误判为冲突。
  @visibleForTesting
  static MemorySnapshotEntry originSnapshotOf(ResolvedMemory memory) => (
        content: memory.origin.content,
        importance: memory.origin.importance,
        type: memory.origin.type,
        isPinned: memory.origin.isPinned,
      );

  /// 解析提取结果并落库；失败/无变化时也会写入运行记录以推进水位。
  Future<_ExtractionOutcome> _applyExtracted({
    required String sessionId,
    required String branchLeafId,
    required String? extracted,
    required List<ResolvedMemory> resolved,
    required List<String> processedIds,
    required String characterName,
    required String userName,
    required String currentInput,
    required bool allowEmptyAsNone,
  }) async {
    Future<void> writeFailed(String message) async {
      await ChatDatabaseService.instance.upsertExtractionRun(
        MemoryExtractionRun(
          id: _generateId('memrun'),
          sessionId: sessionId,
          branchLeafId: branchLeafId,
          processedMessageIds: processedIds,
          status: MemoryExtractionStatus.failed,
          errorMessage: message,
          characterName: characterName,
          userName: userName,
          currentInput: currentInput,
          createdAt: DateTime.now(),
        ),
      );
    }

    if (extracted == null) {
      await writeFailed('提取请求失败');
      return const _ExtractionOutcome(MemoryExtractionStatus.failed);
    }
    final text = extracted.trim();
    if (text.isEmpty) {
      if (allowEmptyAsNone) {
        await _writeRun(
          sessionId: sessionId,
          branchLeafId: branchLeafId,
          processedIds: processedIds,
          status: MemoryExtractionStatus.empty,
          characterName: characterName,
          userName: userName,
          currentInput: currentInput,
        );
        return const _ExtractionOutcome(MemoryExtractionStatus.empty);
      }
      await writeFailed('模型返回空内容');
      return const _ExtractionOutcome(MemoryExtractionStatus.failed);
    }

    final ops = parseMemoryOps(text);
    if (ops == null) {
      await writeFailed('无法解析提取结果');
      return const _ExtractionOutcome(MemoryExtractionStatus.failed);
    }

    final byId = {for (final memory in resolved) memory.id: memory};
    final now = DateTime.now();
    final newMemories = <MemoryNode>[];
    final diffs = <MemoryDiff>[];
    final expectedSnapshot = <String, MemorySnapshotEntry>{};

    for (final op in ops) {
      switch (op.kind) {
        case MemoryOpKind.add:
          final content = op.content?.trim() ?? '';
          if (content.isEmpty) {
            await writeFailed('add 操作缺少内容');
            return const _ExtractionOutcome(MemoryExtractionStatus.failed);
          }
          newMemories.add(
            MemoryNode(
              id: _generateId('memory'),
              sessionId: sessionId,
              branchLeafId: branchLeafId,
              content: content,
              sourceMessageIds: processedIds,
              importance: (op.importance ?? 3).clamp(1, 5),
              type: op.type ?? MemoryType.other,
              isPinned: op.isPinned ?? false,
              createdAt: now,
              updatedAt: now,
            ),
          );
        case MemoryOpKind.update:
          final target = byId[op.id];
          if (target == null) {
            await writeFailed('update 目标不存在：${op.id ?? '(空)'}');
            return const _ExtractionOutcome(MemoryExtractionStatus.failed);
          }
          final content = op.content?.trim();
          if (content != null && content.isEmpty) {
            await writeFailed('update 内容不能为空');
            return const _ExtractionOutcome(MemoryExtractionStatus.failed);
          }
          expectedSnapshot[target.id] = originSnapshotOf(target);
          diffs.add(
            MemoryDiff(
              id: _generateId('memdiff'),
              sessionId: sessionId,
              branchLeafId: branchLeafId,
              targetMemoryId: target.id,
              kind: MemoryDiffKind.update,
              content: content ?? target.content,
              importance: (op.importance ?? target.importance).clamp(1, 5),
              type: op.type ?? target.type,
              isPinned: op.isPinned ?? target.isPinned,
              createdAt: now,
            ),
          );
        case MemoryOpKind.invalidate:
          final target = byId[op.id];
          if (target == null) {
            await writeFailed('invalidate 目标不存在：${op.id ?? '(空)'}');
            return const _ExtractionOutcome(MemoryExtractionStatus.failed);
          }
          expectedSnapshot[target.id] = originSnapshotOf(target);
          diffs.add(
            MemoryDiff(
              id: _generateId('memdiff'),
              sessionId: sessionId,
              branchLeafId: branchLeafId,
              targetMemoryId: target.id,
              kind: MemoryDiffKind.invalidate,
              createdAt: now,
            ),
          );
      }
    }

    if (newMemories.isEmpty && diffs.isEmpty) {
      await _writeRun(
        sessionId: sessionId,
        branchLeafId: branchLeafId,
        processedIds: processedIds,
        status: MemoryExtractionStatus.empty,
        characterName: characterName,
        userName: userName,
        currentInput: currentInput,
      );
      return const _ExtractionOutcome(MemoryExtractionStatus.empty);
    }

    try {
      await ChatDatabaseService.instance.applyMemoryExtractionTx(
        newMemories: newMemories,
        diffs: diffs,
        run: MemoryExtractionRun(
          id: _generateId('memrun'),
          sessionId: sessionId,
          branchLeafId: branchLeafId,
          processedMessageIds: processedIds,
          status: MemoryExtractionStatus.applied,
          addedCount: newMemories.length,
          updatedCount: diffs
              .where((d) => d.kind == MemoryDiffKind.update)
              .length,
          invalidatedCount: diffs
              .where((d) => d.kind == MemoryDiffKind.invalidate)
              .length,
          characterName: characterName,
          userName: userName,
          currentInput: currentInput,
          createdAt: now,
        ),
        expectedSnapshot: expectedSnapshot,
      );
    } on MemoryExtractionConflict catch (error) {
      await writeFailed(error.message);
      return const _ExtractionOutcome(MemoryExtractionStatus.failed);
    }
    return _ExtractionOutcome(
      MemoryExtractionStatus.applied,
      added: newMemories.length,
      updated: diffs
          .where((d) => d.kind == MemoryDiffKind.update)
          .length,
      invalidated: diffs
          .where((d) => d.kind == MemoryDiffKind.invalidate)
          .length,
    );
  }

  Future<void> _writeRun({
    required String sessionId,
    required String branchLeafId,
    required List<String> processedIds,
    required MemoryExtractionStatus status,
    required String characterName,
    required String userName,
    required String currentInput,
    String errorMessage = '',
  }) async {
    await ChatDatabaseService.instance.upsertExtractionRun(
      MemoryExtractionRun(
        id: _generateId('memrun'),
        sessionId: sessionId,
        branchLeafId: branchLeafId,
        processedMessageIds: processedIds,
        status: status,
        errorMessage: errorMessage,
        characterName: characterName,
        userName: userName,
        currentInput: currentInput,
        createdAt: DateTime.now(),
      ),
    );
  }

  // ==================== 解析 ====================

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

  /// 解析提取结果。
  ///
  /// 返回 null 表示无法解析（应记为失败）；返回空列表表示明确无变化。
  /// 兼容两种输出：新协议 JSON `{"ops":[...]}`，以及旧的 `- 记忆点` 列表。
  @visibleForTesting
  static List<MemoryOp>? parseMemoryOps(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    var candidateText = text;
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false);
    final fenceMatch = fence.firstMatch(candidateText);
    if (fenceMatch != null) {
      candidateText = fenceMatch.group(1)!.trim();
    }

    for (final jsonText in _extractJsonCandidates(candidateText)) {
      dynamic decoded;
      try {
        decoded = jsonDecode(jsonText);
      } catch (_) {
        continue;
      }
      final ops = _opsFromDecoded(decoded);
      if (ops != null) return ops;
    }

    // 旧协议回退：逐行 `- 记忆点`。
    final legacy = parseMemoryPoints(text);
    if (legacy.isNotEmpty) {
      return [
        for (final line in legacy)
          MemoryOp(kind: MemoryOpKind.add, content: line),
      ];
    }
    return null;
  }

  static List<MemoryOp>? _opsFromDecoded(dynamic decoded) {
    List<dynamic>? items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      final value = decoded['ops'] ?? decoded['operations'] ?? decoded['操作'];
      if (value is List) {
        items = value;
      }
    }
    if (items == null) return null;

    final ops = <MemoryOp>[];
    for (final item in items) {
      if (item is! Map) continue;
      final rawKind = (item['op'] ?? item['action'])?.toString().toLowerCase();
      final id = (item['id'] ?? item['target'] ?? item['memory_id'])
          ?.toString()
          .trim();
      final content = item['content'] ?? item['text'] ?? item['value'];
      final rawImportance = item['importance'] ?? item['weight'] ?? item['score'];
      int? importance;
      if (rawImportance is num) {
        importance = rawImportance.toInt();
      } else if (rawImportance is String) {
        importance = int.tryParse(rawImportance.trim());
      }
      final normalizedContent = content?.toString().trim();

      final rawType =
          item['memory_type'] ?? item['category'] ?? item['type'];
      MemoryType? type;
      if (rawType != null && rawType.toString().trim().isNotEmpty) {
        type = MemoryType.fromName(rawType.toString());
      }
      final rawPinned = item['isPinned'] ?? item['pinned'] ?? item['常驻'];
      bool? isPinned;
      if (rawPinned is bool) {
        isPinned = rawPinned;
      } else if (rawPinned is String) {
        final normalized = rawPinned.trim().toLowerCase();
        if (normalized == 'true' || normalized == '是') isPinned = true;
        if (normalized == 'false' || normalized == '否') isPinned = false;
      }

      MemoryOpKind? kind;
      switch (rawKind) {
        case 'add':
        case 'create':
        case 'append':
          kind = MemoryOpKind.add;
        case 'update':
        case 'modify':
        case 'edit':
        case 'set':
          kind = MemoryOpKind.update;
        case 'invalidate':
        case 'delete':
        case 'remove':
        case 'forget':
          kind = MemoryOpKind.invalidate;
      }
      if (kind == null) continue;
      if (kind != MemoryOpKind.add && (id == null || id.isEmpty)) continue;
      ops.add(
        MemoryOp(
          kind: kind,
          id: id,
          content: normalizedContent,
          importance: importance,
          type: type,
          isPinned: isPinned,
        ),
      );
    }
    return ops;
  }

  static Iterable<String> _extractJsonCandidates(
    String text, {
    int maxCandidates = 4,
  }) sync* {
    var produced = 0;
    var attempts = 0;
    var i = 0;
    while (i < text.length && produced < maxCandidates) {
      final open = text[i];
      if (open != '{' && open != '[') {
        i++;
        continue;
      }
      attempts++;
      if (attempts > maxCandidates * 2) return;
      final end = _balancedEnd(text, i);
      if (end == null) {
        i++;
        continue;
      }
      yield text.substring(i, end + 1);
      produced++;
      i = end + 1;
    }
  }

  static int? _balancedEnd(String text, int start) {
    final open = text[start];
    final close = open == '{' ? '}' : ']';
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var j = start; j < text.length; j++) {
      final ch = text[j];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == r'\') {
          escaped = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
      } else if (ch == open) {
        depth++;
      } else if (ch == close) {
        depth--;
        if (depth == 0) return j;
      }
    }
    return null;
  }

  String _generateId(String prefix) {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final seq = _idSequence++;
    final rand = _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return '$prefix-$micros-$seq-$rand';
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
