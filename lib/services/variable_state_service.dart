import 'dart:convert';

import '../models/chat_variables.dart';
import 'chat_database_service.dart';

/// 状态变量的事件溯源求值服务。
///
/// 变量差量（diff）挂在产生它的助手消息上，随消息树分支各归各路；
/// 「某条消息时刻的变量状态」= 会话初始变量 + 从根到该消息路径上
/// 所有 diff 按序折叠。切换版本、gal 回复历史、记忆树跳转等操作
/// 改变激活路径后，只需重新求值即可得到分支正确的状态，无需回滚。
class VariableStateService {
  VariableStateService._();

  static final VariableStateService instance = VariableStateService._();

  /// 读取会话初始变量；未设置过时返回空状态。
  Future<VariableState> loadInitState(String sessionId) async {
    final raw = await ChatDatabaseService.instance.loadVariableInit(sessionId);
    if (raw == null || raw.isEmpty) {
      return VariableState.empty();
    }
    return VariableState.decodeJson(raw);
  }

  /// 写入（或覆盖）会话初始变量。
  Future<void> saveInitState(String sessionId, VariableState state) async {
    await ChatDatabaseService.instance.saveVariableInit(
      sessionId: sessionId,
      valuesJson: state.encodeJson(),
    );
  }

  /// 读取挂在某条消息上的变量差量；无差量返回空列表。
  Future<List<VariableOp>> readDiff(String messageId) async {
    final raw = await ChatDatabaseService.instance.loadVariableDiff(messageId);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    return _decodeOps(raw);
  }

  /// 写入（或覆盖）消息的变量差量。
  Future<void> writeDiff({
    required String messageId,
    required List<VariableOp> ops,
  }) async {
    if (ops.isEmpty) {
      await ChatDatabaseService.instance.deleteVariableDiff(messageId);
      return;
    }
    await ChatDatabaseService.instance.saveVariableDiff(
      messageId: messageId,
      opsJson: jsonEncode([for (final op in ops) op.toJson()]),
    );
  }

  /// 删除消息的变量差量。
  Future<void> clearDiff(String messageId) async {
    await ChatDatabaseService.instance.deleteVariableDiff(messageId);
  }

  /// 求值「[messageId] 时刻」的变量状态。
  ///
  /// 沿 parent 链回溯到根，取路径上（含 [messageId] 自身，除非
  /// [includeSelf] 为 false）全部 diff 按时间序折叠到初始变量上。
  /// [messageId] 为 null 时只返回初始变量；消息不存在（如草稿会话）
  /// 时同样优雅回落到初始变量。
  Future<VariableState> resolveState({
    required String sessionId,
    String? messageId,
    bool includeSelf = true,
  }) async {
    var state = await loadInitState(sessionId);
    final targetId = messageId;
    if (targetId == null) {
      return state;
    }

    // loadMessageAncestorIds 返回 [messageId, parent, ..., root]，
    // 反转为从根到目标消息的时间序。
    final ancestorIds = await ChatDatabaseService.instance
        .loadMessageAncestorIds(targetId);
    if (ancestorIds.isEmpty) {
      return state;
    }
    final pathIds = ancestorIds.reversed.toList();
    if (!includeSelf) {
      pathIds.removeLast();
    }
    if (pathIds.isEmpty) {
      return state;
    }

    final diffsById = await ChatDatabaseService.instance
        .loadVariableDiffBatch(pathIds);
    for (final id in pathIds) {
      final raw = diffsById[id];
      if (raw == null || raw.isEmpty) {
        continue;
      }
      state = state.applyOps(_decodeOps(raw));
    }
    return state;
  }

  static List<VariableOp> _decodeOps(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return [for (final item in decoded) ?VariableOp.fromJson(item)];
    } catch (_) {
      return const [];
    }
  }
}
