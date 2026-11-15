import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_memory.freezed.dart';

/// 记忆点类型，用于分类展示与召回提示。
enum MemoryType {
  fact('事实'),
  preference('偏好'),
  event('剧情'),
  relationship('关系'),
  commitment('承诺'),
  setting('设定'),
  other('其他');

  const MemoryType(this.label);

  final String label;

  static MemoryType fromName(String? name) {
    if (name == null) return MemoryType.other;
    final normalized = name.trim();
    return MemoryType.values.firstWhere(
      (type) => type.name == normalized || type.label == normalized,
      orElse: () => MemoryType.other,
    );
  }
}

/// 一条长期记忆（原始记忆）。
///
/// 原始记忆创建于产生它的消息节点 [branchLeafId]；只有该节点允许真正改写
/// 或物理删除它，其它后代节点只能通过 [MemoryDiff] 追加 update / invalidate。
@freezed
abstract class MemoryNode with _$MemoryNode {
  const factory MemoryNode({
    required String id,
    required String sessionId,
    required String branchLeafId,
    required String content,
    @Default([]) List<String> sourceMessageIds,
    @Default(false) bool isUserEdited,

    /// 重要度 1~5，越大越优先召回；旧数据默认 3。
    @Default(3) int importance,

    /// 记忆点类型。
    @Default(MemoryType.other) MemoryType type,

    /// 常驻记忆：跳过按条数/相关性竞争，优先注入提示词。
    @Default(false) bool isPinned,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MemoryNode;
}

/// 记忆差量类型。
///
/// - [update]：改写内容或重要度；
/// - [invalidate]：使该记忆在当前分支失效（不物理删除原始记录）；
/// - [restore]：在当前分支撤销失效，使记忆重新可见可召回。
enum MemoryDiffKind { update, invalidate, restore }

/// 挂在消息节点上的记忆差量。
///
/// 与状态变量的事件溯源同构：差量随消息分支各归各路，求值「某节点时刻的
/// 记忆」= 路径上全部原始记忆 + 路径上全部差量按序折叠。
@freezed
abstract class MemoryDiff with _$MemoryDiff {
  const factory MemoryDiff({
    required String id,
    required String sessionId,

    /// 产生该差量的消息节点。
    required String branchLeafId,
    required String targetMemoryId,
    required MemoryDiffKind kind,
    String? content,
    int? importance,
    MemoryType? type,
    bool? isPinned,
    @Default(false) bool isUserEdited,
    required DateTime createdAt,
  }) = _MemoryDiff;
}

/// 一次自动记忆提取的处理结果状态。
///
/// [empty] 表示模型确认「没有值得记忆的内容」，与 [applied] 一样推进水位；
/// [failed] 表示请求异常 / 输出无法解析，同样占据本批处理记录以避免每轮
/// 重复调用，并可在界面上手动重试。
enum MemoryExtractionStatus { applied, empty, failed }

/// 自动记忆提取的运行记录（按锚点助手消息唯一）。
@freezed
abstract class MemoryExtractionRun with _$MemoryExtractionRun {
  const factory MemoryExtractionRun({
    required String id,
    required String sessionId,

    /// 锚点助手消息（提取发生时分支的最末消息）。
    required String branchLeafId,

    /// 本次实际送入模型的消息 id（按时间序），用于水位推进与失败重试。
    @Default([]) List<String> processedMessageIds,
    required MemoryExtractionStatus status,
    @Default(0) int addedCount,
    @Default(0) int updatedCount,
    @Default(0) int invalidatedCount,
    @Default('') String errorMessage,
    @Default('') String characterName,
    @Default('') String userName,
    @Default('') String currentInput,
    required DateTime createdAt,
  }) = _MemoryExtractionRun;
}

@freezed
abstract class MemoryExtractionConfig with _$MemoryExtractionConfig {
  const MemoryExtractionConfig._();

  const factory MemoryExtractionConfig({
    @Default(false) bool enabled,
    @Default(5) int interval,
    @Default(10) int recentRounds,
    @Default(3) int recallCount,
    String? extractionModelId,
    @Default('') String customExtractionPrompt,
    @Default('') String customInjectionPrompt,
  }) = _MemoryExtractionConfig;

  bool get hasCustomExtractionPrompt =>
      customExtractionPrompt.trim().isNotEmpty;

  bool get hasCustomInjectionPrompt => customInjectionPrompt.trim().isNotEmpty;
}
