import 'dart:async';

import 'package:flutter/foundation.dart';

/// 回复落库后的后台子任务类型。
enum PostTaskKind { statusExtraction, memoryExtraction, galChoices }

/// 任务已过期或被同锚点新任务替代时抛出；由调度器拦截并静默跳过。
class PostTaskStaleException implements Exception {
  const PostTaskStaleException();

  @override
  String toString() => 'PostTaskStaleException';
}

/// 后台子任务调度器：把「状态提取 / 记忆提取 / gal 选项生成」集中排队执行。
///
/// - 每个类型一个 FIFO 队列且同一类型串行执行（后到排队），全局并发执行数
///   不超过 [maxConcurrent]，避免连续发送消息时多个后台 LLM 请求叠加；
/// - 以 [anchorKey] 去重：同锚点的新任务会替代仍在排队中的旧任务（旧任务
///   不再执行并回调 onSkipped），运行中的旧任务被标记 superseded，在写库前
///   被 [ensureFresh] 拦截，防止过期结果落库；
/// - 任务执行前由 isStale 检查，执行中/写库前由 ensureFresh 检查；过期或被
///   替代的任务静默丢弃，绝不阻断聊天主流程。
class PostTaskScheduler {
  PostTaskScheduler._();

  static final PostTaskScheduler instance = PostTaskScheduler._();

  /// 后台 LLM 任务全局并发上限（主聊天请求不受此限制）。
  static const int maxConcurrent = 2;

  final Map<PostTaskKind, _KindQueue> _queues = {};
  int _inflightCount = 0;
  int _kindCursor = 0;
  bool _draining = false;

  /// 注册一个后台子任务。
  ///
  /// [run] 接收调度器生成的 [ensureFresh] 闭包：业务逻辑应在写库（或写回
  /// 界面状态）前调用它；任务被同锚点新任务替代、或 [isStale] 返回 true 时
  /// 会抛出 [PostTaskStaleException]。
  ///
  /// [isStale] 在任务执行前与写库前各检查一次；返回 true 表示任务已过期，
  /// 将被丢弃。[onSkipped] 在任务被丢弃（替代/过期）时回调一次。
  void schedule({
    required PostTaskKind kind,
    required String sessionId,
    required String anchorKey,
    required Future<void> Function(Future<void> Function() ensureFresh) run,
    Future<bool> Function()? isStale,
    void Function()? onSkipped,
  }) {
    final queue = _queues.putIfAbsent(kind, _KindQueue.new);
    final task = _PostTask(
      kind: kind,
      sessionId: sessionId,
      anchorKey: anchorKey,
      run: run,
      isStale: isStale,
      onSkipped: onSkipped,
    );

    // 同锚点：排队中的旧任务直接作废；运行中的旧任务标记 superseded，
    // 等其结束前经 ensureFresh 阻止写库。
    final pendingIndex = queue.pending.indexWhere(
      (t) => t.anchorKey == anchorKey,
    );
    if (pendingIndex >= 0) {
      final old = queue.pending.removeAt(pendingIndex);
      _markSkipped(old);
    }
    final running = queue.running;
    if (running != null && running.anchorKey == anchorKey) {
      running.superseded = true;
    }

    queue.pending.add(task);
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_draining) {
      return;
    }
    _draining = true;
    try {
      while (_inflightCount < maxConcurrent) {
        // 同一类型串行：正在运行的类型跳过，避免同类任务互相覆盖状态。
        final entry = _nextPending();
        if (entry == null) {
          return;
        }
        final queue = entry.$1;
        final task = entry.$2;
        if (await _isStale(task)) {
          _markSkipped(task);
          continue;
        }
        _inflightCount++;
        queue.running = task;
        unawaited(_runTask(queue, task));
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _runTask(_KindQueue queue, _PostTask task) async {
    try {
      await task.run(_ensureFreshFor(task));
    } on PostTaskStaleException {
      _markSkipped(task);
    } catch (error, stack) {
      debugPrint(
        'PostTask(${task.kind.name}) 执行失败: '
        '$error\n$stack',
      );
    } finally {
      _inflightCount--;
      if (identical(queue.running, task)) {
        queue.running = null;
      }
      unawaited(_drain());
    }
  }

  Future<void> Function() _ensureFreshFor(_PostTask task) {
    return () async {
      if (task.superseded) {
        throw const PostTaskStaleException();
      }
      if (await _isStale(task)) {
        throw const PostTaskStaleException();
      }
    };
  }

  /// 轮询各类型队列，返回下一个可执行任务（同类型内保持 FIFO）。
  (_KindQueue, _PostTask)? _nextPending() {
    final kinds = PostTaskKind.values;
    for (var i = 0; i < kinds.length; i++) {
      final kind = kinds[(_kindCursor + i) % kinds.length];
      final queue = _queues[kind];
      if (queue == null || queue.running != null || queue.pending.isEmpty) {
        continue;
      }
      _kindCursor = (kind.index + 1) % kinds.length;
      return (queue, queue.pending.removeAt(0));
    }
    return null;
  }

  Future<bool> _isStale(_PostTask task) async {
    if (task.isStale == null) {
      return false;
    }
    try {
      final stale = await task.isStale!();
      if (stale) {
        debugPrint(
          'PostTask(${task.kind.name}) 已过期，跳过 '
          '(session: ${task.sessionId}, anchor: ${task.anchorKey})',
        );
      }
      return stale;
    } catch (error, stack) {
      debugPrint(
        'PostTask(${task.kind.name}) 过期检查失败: '
        '$error\n$stack',
      );
      return true;
    }
  }

  void _markSkipped(_PostTask task) {
    if (task.skipped) {
      return;
    }
    task.skipped = true;
    try {
      task.onSkipped?.call();
    } catch (error, stack) {
      debugPrint('PostTask(${task.kind.name}) onSkipped 回调失败: $error\n$stack');
    }
  }

  /// 清空队列与在途状态，仅供测试使用。
  @visibleForTesting
  void resetForTest() {
    _queues.clear();
    _inflightCount = 0;
    _kindCursor = 0;
    _draining = false;
  }
}

class _PostTask {
  _PostTask({
    required this.kind,
    required this.sessionId,
    required this.anchorKey,
    required this.run,
    required this.isStale,
    required this.onSkipped,
  });

  final PostTaskKind kind;
  final String sessionId;
  final String anchorKey;
  final Future<void> Function(Future<void> Function() ensureFresh) run;
  final Future<bool> Function()? isStale;
  final void Function()? onSkipped;
  bool superseded = false;
  bool skipped = false;
}

class _KindQueue {
  final List<_PostTask> pending = <_PostTask>[];
  _PostTask? running;
}
