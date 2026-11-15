import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/chat_memory.dart';
import '../../../models/chat_session.dart';
import '../../../services/chat_database_service.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../services/chat_memory_service.dart';
import '../../subtask_settings_page.dart';

enum _NodeKind { user, assistant }

class _TreeNode {
  _TreeNode({
    required this.id,
    required this.kind,
    required this.parentId,
    required this.text,
    this.memoryEntries = const <MemoryNode>[],
    this.ownDiffCount = 0,
    this.extractionRun,
  });

  final String id;
  final _NodeKind kind;
  final String? parentId;
  final String text;

  /// 该节点自身产生的原始记忆（不代表整条可见记忆列表）。
  final List<MemoryNode> memoryEntries;

  /// 该节点自身写入的记忆差量数量（update / invalidate）。
  final int ownDiffCount;

  /// 该节点上的提取运行记录（可能为 failed / empty / applied）。
  final MemoryExtractionRun? extractionRun;
  final List<_TreeNode> children = <_TreeNode>[];

  // 布局结果
  double x = 0;
  double y = 0;
  int depth = 0;
  int lane = 0;
  bool isMainLine = false;
  _TreeNode? primaryChild;

  bool get hasMemory =>
      memoryEntries.isNotEmpty ||
      ownDiffCount > 0 ||
      (extractionRun?.status == MemoryExtractionStatus.applied);
}

class MemoryTreePage extends StatefulWidget {
  const MemoryTreePage({
    super.key,
    required this.sessionId,
    required this.activeLeafMessageId,
    this.onJumpToMessage,
  });

  final String sessionId;
  final String? activeLeafMessageId;

  /// 跳转到某条消息（已切换为活跃分支）后的回调，
  /// 调用方应自行刷新聊天界面。
  final ValueChanged<String>? onJumpToMessage;

  @override
  State<MemoryTreePage> createState() => _MemoryTreePageState();
}

class _MemoryTreePageState extends State<MemoryTreePage> {
  static const double _laneSpacing = 56;
  static const double _rowSpacing = 64;
  static const double _nodeRadius = 9;
  static const double _ringRadius = 14;
  static const double _padding = 32;

  bool _isLoading = true;
  List<_TreeNode> _roots = const [];
  Set<String> _activePathIds = const {};
  final List<Size> _rootCanvasSizes = <Size>[];
  int _selectedRootIndex = 0;

  /// 记忆数据变化时的防抖刷新句柄，避免后台提取连续落库触发多次重载。
  Timer? _memoryReloadDebounce;

  @override
  void initState() {
    super.initState();
    // 后台记忆提取/编辑落库只广播 memoryChangeNotifier，页面打开期间监听它，
    // 保证新提取结果无需重开页面即可显示。
    ChatDatabaseService.instance.memoryChangeNotifier.addListener(
      _handleMemoryChanged,
    );
    _reload();
  }

  @override
  void dispose() {
    ChatDatabaseService.instance.memoryChangeNotifier.removeListener(
      _handleMemoryChanged,
    );
    _memoryReloadDebounce?.cancel();
    super.dispose();
  }

  void _handleMemoryChanged() {
    _memoryReloadDebounce?.cancel();
    _memoryReloadDebounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        _reload();
      }
    });
  }

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final db = ChatDatabaseService.instance;
    final nodes = await db.loadAllSessionNodes(widget.sessionId);
    if (!mounted) return;
    final memories = await db.loadAllSessionMemories(widget.sessionId);
    if (!mounted) return;
    final diffs = await db.loadAllSessionMemoryDiffs(widget.sessionId);
    if (!mounted) return;
    final runs = await db.loadAllSessionExtractionRuns(widget.sessionId);
    if (!mounted) return;

    final byMessageId = <String, List<MemoryNode>>{};
    for (final m in memories) {
      byMessageId.putIfAbsent(m.branchLeafId, () => <MemoryNode>[]).add(m);
    }
    for (final list in byMessageId.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    final diffCountByMessage = <String, int>{};
    for (final diff in diffs) {
      diffCountByMessage[diff.branchLeafId] =
          (diffCountByMessage[diff.branchLeafId] ?? 0) + 1;
    }
    final runByMessage = <String, MemoryExtractionRun>{
      for (final run in runs) run.branchLeafId: run,
    };

    final treeNodes = <String, _TreeNode>{};
    for (final node in nodes) {
      treeNodes[node.id] = _TreeNode(
        id: node.id,
        kind: node.role == ChatNodeRole.user
            ? _NodeKind.user
            : _NodeKind.assistant,
        parentId: node.parentId,
        text: node.text,
        memoryEntries: byMessageId[node.id] ?? const <MemoryNode>[],
        ownDiffCount: diffCountByMessage[node.id] ?? 0,
        extractionRun: runByMessage[node.id],
      );
    }

    final roots = <_TreeNode>[];
    for (final node in nodes) {
      final tn = treeNodes[node.id]!;
      final pid = node.parentId;
      if (pid == null || !treeNodes.containsKey(pid)) {
        roots.add(tn);
      } else {
        treeNodes[pid]!.children.add(tn);
      }
    }

    // 排序子节点：按消息 createdAt（用 nodes 顺序保证）
    final orderIndex = <String, int>{};
    for (var i = 0; i < nodes.length; i++) {
      orderIndex[nodes[i].id] = i;
    }
    // 迭代遍历（显式栈）：超长分支下避免递归栈溢出。
    void sortChildren(_TreeNode root) {
      final stack = <_TreeNode>[root];
      while (stack.isNotEmpty) {
        final n = stack.removeLast();
        n.children.sort((a, b) =>
            (orderIndex[a.id] ?? 0).compareTo(orderIndex[b.id] ?? 0));
        stack.addAll(n.children);
      }
    }

    for (final r in roots) {
      sortChildren(r);
    }

    // 记忆点不再作为独立子节点存在，
    // 它会以"持有记忆"的特殊样式呈现在消息节点本身上。

    // 计算活跃路径：从 activeLeafMessageId 沿 parentId 回溯到根。
    final activeIds = <String>{};
    String? cur = widget.activeLeafMessageId;
    while (cur != null && treeNodes.containsKey(cur)) {
      activeIds.add(cur);
      cur = treeNodes[cur]!.parentId;
    }

    // 计算布局：采用类似 Git 提交历史的「轨道分配算法」（Lane Allocation）。
    // 主线（活动线）锚定在最左侧的 Lane 0，分支只能向右申请空闲轨道，
    // 上方分支在 Y 轴结束后释放该轨道，供下方分支复用（Skyline 轮廓压缩）。
    final isMain = <String, bool>{for (final id in activeIds) id: true};

    void assignDepth(_TreeNode root, int depth) {
      final stack = <(int, _TreeNode)>[(depth, root)];
      while (stack.isNotEmpty) {
        final (d, n) = stack.removeLast();
        n.depth = d;
        for (final c in n.children) {
          stack.add((d + 1, c));
        }
      }
    }

    int maxDepthOf(_TreeNode root) {
      var max = root.depth;
      final stack = <_TreeNode>[root];
      while (stack.isNotEmpty) {
        final n = stack.removeLast();
        if (n.depth > max) max = n.depth;
        stack.addAll(n.children);
      }
      return max;
    }

    // 标记主线节点，并确定每个节点沿同一条轨道继续下行的「主子节点」。
    for (final node in treeNodes.values) {
      node.isMainLine = isMain[node.id] ?? false;
    }

    for (final node in treeNodes.values) {
      if (node.children.isEmpty) {
        node.primaryChild = null;
        continue;
      }
      if (node.isMainLine) {
        _TreeNode? onPath;
        for (final c in node.children) {
          if (c.isMainLine) {
            onPath = c;
            break;
          }
        }
        node.primaryChild = onPath ?? node.children.first;
      } else {
        node.primaryChild = node.children.first;
      }
    }

    final canvasSizes = <Size>[];
    for (final r in roots) {
      assignDepth(r, 0);

      // 链分解：主线链 + 若干侧链。每条链占据一条独立轨道。
      final chains = <List<_TreeNode>>[];

      final mainChain = <_TreeNode>[];
      var head = r;
      while (true) {
        mainChain.add(head);
        final pc = head.primaryChild;
        if (pc == null) break;
        head = pc;
      }
      chains.add(mainChain);

      final sideStarts = <_TreeNode>[];
      final sideStartParent = <_TreeNode, _TreeNode>{};
      void collectSideStarts(_TreeNode root) {
        final stack = <_TreeNode>[root];
        while (stack.isNotEmpty) {
          final n = stack.removeLast();
          for (final c in n.children) {
            if (c != n.primaryChild) {
              sideStarts.add(c);
              sideStartParent[c] = n;
            }
            stack.add(c);
          }
        }
      }

      collectSideStarts(r);
      sideStarts.sort((a, b) {
        final d = a.depth.compareTo(b.depth);
        if (d != 0) return d;
        return (orderIndex[a.id] ?? 0).compareTo(orderIndex[b.id] ?? 0);
      });

      for (final s in sideStarts) {
        final chain = <_TreeNode>[];
        var c = s;
        while (true) {
          chain.add(c);
          final pc = c.primaryChild;
          if (pc == null) break;
          c = pc;
        }
        chains.add(chain);
      }

      // 轨道分配（Skyline 轮廓）：laneEnd[lane] 记录该轨道当前占用的最大行号。
      final laneEnd = <int>[mainChain.last.depth];
      for (final n in mainChain) {
        n.lane = 0;
      }

      for (final chain in chains.skip(1)) {
        final s = chain.first.depth;
        final e = chain.last.depth;
        // 分支只能申请父节点所在轨道右侧的空闲轨道，避免向左折回。
        final parent = sideStartParent[chain.first];
        var lane = (parent?.lane ?? 0) + 1;
        while (lane < laneEnd.length && laneEnd[lane] >= s) {
          lane++;
        }
        if (lane == laneEnd.length) {
          laneEnd.add(e);
        } else {
          laneEnd[lane] = e;
        }
        for (final n in chain) {
          n.lane = lane;
        }
      }

      final maxLane = laneEnd.length - 1;

      void assignPos(_TreeNode root) {
        final stack = <_TreeNode>[root];
        while (stack.isNotEmpty) {
          final n = stack.removeLast();
          n.x = _padding + n.lane * _laneSpacing;
          n.y = _padding + n.depth * _rowSpacing;
          stack.addAll(n.children);
        }
      }

      assignPos(r);

      final maxDepth = maxDepthOf(r);
      final width = _padding * 2 + (maxLane + 1) * _laneSpacing;
      final height = _padding * 2 + (maxDepth + 1) * _rowSpacing;
      canvasSizes.add(Size(width, height));
    }

    // 选择默认 tab：包含 activeLeafMessageId 的根；否则 0。
    var defaultIndex = 0;
    if (widget.activeLeafMessageId != null) {
      bool contains(_TreeNode root, String id) {
        final stack = <_TreeNode>[root];
        while (stack.isNotEmpty) {
          final n = stack.removeLast();
          if (n.id == id) return true;
          stack.addAll(n.children);
        }
        return false;
      }

      for (var i = 0; i < roots.length; i++) {
        if (contains(roots[i], widget.activeLeafMessageId!)) {
          defaultIndex = i;
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _roots = roots;
      _activePathIds = activeIds;
      _rootCanvasSizes
        ..clear()
        ..addAll(canvasSizes);
      _selectedRootIndex = roots.isEmpty
          ? 0
          : defaultIndex.clamp(0, roots.length - 1);
      _isLoading = false;
    });
  }

  bool _isNodeActive(_TreeNode n) {
    return _activePathIds.contains(n.id);
  }

  bool _isEdgeActive(_TreeNode parent, _TreeNode child) {
    return _isNodeActive(parent) && _isNodeActive(child);
  }

  void _onTapNode(_TreeNode n) {
    _showMessageActions(n);
  }

  Future<void> _showMessageActions(_TreeNode n) async {
    final isUser = n.kind == _NodeKind.user;
    final preview = n.text.trim();
    final resolved = await ChatMemoryService.instance.resolveMemoriesAtMessage(
      sessionId: widget.sessionId,
      messageId: n.id,
      includeInvalidated: true,
    );
    if (!mounted) return;
    final validResolved = resolved
        .where((memory) => !memory.invalidated)
        .toList(growable: false);
    final invalidCount = resolved.length - validResolved.length;
    final run = n.extractionRun;
    final hasMemory = validResolved.isNotEmpty;
    final hasAnyMemory = resolved.isNotEmpty;
    final hasRun = run != null;
    final isDark =
        Theme.of(context).colorScheme.brightness == Brightness.dark;
    final tc = isDark ? _TreeColors.dark : _TreeColors.light;

    final lines = preview.split('\n');
    final needsExpand = lines.length > 4 || preview.length > 200;

    var isExpanded = false;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return SafeArea(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  // 预留底部按钮区域的高度
                  const buttonAreaHeight = 64.0;
                  final maxContentHeight =
                      (constraints.maxHeight - buttonAreaHeight)
                          .clamp(80.0, 600.0);

                  // 估算消息文本之外固定部分的高度
                  final fixedH = 26.0 + // 标题行 + SizedBox(6)
                      (preview.isNotEmpty && needsExpand ? 36.0 : 0.0) + // 展开按钮
                      (hasMemory ? 120.0 : 0.0) + // 记忆列表
                      (hasRun ? 64.0 : 0.0); // 提取状态
                  final messageMaxHeight =
                      (maxContentHeight - fixedH).clamp(60.0, 600.0);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isUser ? '用户消息' : '角色消息',
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                if (hasMemory) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tc.memoryActive
                                          .withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      invalidCount > 0
                                          ? '可见记忆 · ${validResolved.length} 条 · 失效 $invalidCount'
                                          : '可见记忆 · ${validResolved.length} 条',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: tc.memoryActive,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                if (n.ownDiffCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '本节点改动 +${n.ownDiffCount}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (preview.isEmpty)
                              Text(
                                '（无内容）',
                                style:
                                    Theme.of(ctx).textTheme.bodyMedium,
                              )
                            else
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: messageMaxHeight,
                                ),
                                child: SingleChildScrollView(
                                  child: !isExpanded
                                      ? Text(
                                          preview,
                                          maxLines: 4,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: Theme.of(ctx)
                                              .textTheme
                                              .bodyMedium,
                                        )
                                      : MarkdownBody(
                                          data: preview,
                                          selectable: true,
                                          styleSheet:
                                              MarkdownStyleSheet(
                                            p: Theme.of(ctx)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    height: 1.5),
                                            blockSpacing: 4,
                                            code: TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'monospace',
                                              color: Theme.of(ctx)
                                                  .colorScheme
                                                  .primary,
                                              backgroundColor:
                                                  Theme.of(ctx)
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                            ),
                                            codeblockDecoration:
                                                BoxDecoration(
                                              color: Theme.of(ctx)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      6),
                                            ),
                                            horizontalRuleDecoration:
                                                BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color: Theme.of(ctx)
                                                      .colorScheme
                                                      .outlineVariant,
                                                  width: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            if (preview.isNotEmpty && needsExpand)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 4),
                                child: SizedBox(
                                  height: 32,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(
                                        () =>
                                            isExpanded = !isExpanded,
                                      );
                                    },
                                    icon: Icon(
                                      isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      size: 18,
                                    ),
                                    label: Text(
                                      isExpanded
                                          ? '收起'
                                          : '展开完整消息',
                                      style: const TextStyle(
                                          fontSize: 13),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      visualDensity:
                                          VisualDensity.compact,
                                      foregroundColor: Theme.of(ctx)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ),
                              ),
                            if (hasMemory) ...[
                              const SizedBox(height: 8),
                              Text(
                                validResolved
                                    .map(
                                      (m) => '• [${m.type.label}'
                                          '${m.isPinned ? '·常驻' : ''}] ${m.content}'
                                          '${m.importance >= 4 ? '  ★${m.importance}' : ''}',
                                    )
                                    .join('\n'),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                            if (hasRun) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    _runIcon(run),
                                    size: 16,
                                    color: _runColor(ctx, run),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _runLabel(run),
                                      style: Theme.of(ctx)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: _runColor(ctx, run),
                                          ),
                                    ),
                                  ),
                                  if (run.status ==
                                      MemoryExtractionStatus.failed)
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        _retryExtraction(n.id);
                                      },
                                      child: const Text('重试'),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                ctx,
                                icon: Icons.my_location,
                                label: '切换',
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  _jumpTo(n.id);
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildActionButton(
                                ctx,
                                icon: hasAnyMemory
                                    ? Icons.edit_note_outlined
                                    : Icons.bookmark_add_outlined,
                                label:
                                    hasAnyMemory ? '编辑记忆' : '添加记忆',
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  _openMemoryEditor(n.id);
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildActionButton(
                                ctx,
                                icon: Icons.delete_outline,
                                label: '删除',
                                destructive: true,
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  _confirmDeleteMessage(n);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _jumpTo(String messageId) async {
    final db = ChatDatabaseService.instance;
    final leafId = await db.resolveLeafFromMessage(
      sessionId: widget.sessionId,
      messageId: messageId,
    );
    if (leafId.isEmpty) return;

    final allNodes = await db.loadAllSessionNodes(widget.sessionId);
    final byId = {for (final n in allNodes) n.id: n};
    if (byId[leafId] == null) return;

    // 从 messageId 沿 parentId 回溯到根，逐层切换分支状态
    final chain = <ChatNode>[];
    String? cur = messageId;
    while (cur != null) {
      final n = byId[cur];
      if (n == null) break;
      chain.add(n);
      cur = n.parentId;
    }
    for (final n in chain) {
      await db.switchActiveBranch(
        sessionId: widget.sessionId,
        parentMessageId: n.parentId,
        childMessageId: n.id,
      );
    }

    // leafId != messageId 时才额外激活叶子节点，避免冗余写入
    if (leafId != messageId) {
      await db.switchActiveBranch(
        sessionId: widget.sessionId,
        parentMessageId: byId[leafId]?.parentId,
        childMessageId: leafId,
      );
    }

    if (!mounted) return;
    widget.onJumpToMessage?.call(messageId);
    Navigator.of(context).pop(messageId);
  }

  Future<void> _openMemoryEditor(String messageId) async {
    final db = ChatDatabaseService.instance;
    final service = ChatMemoryService.instance;
    final ancestors = await db.loadMessageAncestorIds(messageId);
    if (!mounted) return;
    final path = ancestors.reversed.toList(growable: false);
    // 必须包含已失效的记忆，否则用户停用后将无法再看到或恢复它。
    final resolved = await service.resolveMemories(
      sessionId: widget.sessionId,
      pathMessageIds: path,
      includeInvalidated: true,
    );
    if (!mounted) return;
    // 祖先时刻的状态：用于“还原本节点改动”时显示应回退到的内容。
    final parentPath = path.length > 1
        ? path.sublist(0, path.length - 1)
        : const <String>[];
    final inherited = parentPath.isEmpty
        ? const <ResolvedMemory>[]
        : await service.resolveMemories(
            sessionId: widget.sessionId,
            pathMessageIds: parentPath,
            includeInvalidated: true,
          );
    if (!mounted) return;
    final localEditIds = await db.loadMemoryDiffTargetsAtNode(
      sessionId: widget.sessionId,
      branchLeafId: messageId,
    );
    if (!mounted) return;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _MemoryEditorDialog(
        sessionId: widget.sessionId,
        messageId: messageId,
        initial: resolved,
        inheritedById: {for (final memory in inherited) memory.id: memory},
        localEditIds: localEditIds,
      ),
    );
    if (changed == true && mounted) {
      await _reload();
    }
  }

  Future<void> _retryExtraction(String messageId) async {
    final ok = await ChatMemoryService.instance.retryExtraction(
      sessionId: widget.sessionId,
      anchorMessageId: messageId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '记忆提取已重试并更新' : '重试未产生新的记忆'),
      ),
    );
    await _reload();
  }

  IconData _runIcon(MemoryExtractionRun run) {
    switch (run.status) {
      case MemoryExtractionStatus.applied:
        return Icons.check_circle_outline;
      case MemoryExtractionStatus.empty:
        return Icons.remove_circle_outline;
      case MemoryExtractionStatus.failed:
        return Icons.error_outline;
    }
  }

  Color _runColor(BuildContext ctx, MemoryExtractionRun run) {
    final scheme = Theme.of(ctx).colorScheme;
    switch (run.status) {
      case MemoryExtractionStatus.applied:
        return scheme.primary;
      case MemoryExtractionStatus.empty:
        return scheme.onSurfaceVariant;
      case MemoryExtractionStatus.failed:
        return scheme.error;
    }
  }

  String _runLabel(MemoryExtractionRun run) {
    switch (run.status) {
      case MemoryExtractionStatus.applied:
        return '已提取：新增 ${run.addedCount} · 更新 ${run.updatedCount} · 失效 ${run.invalidatedCount}';
      case MemoryExtractionStatus.empty:
        return '本批无需记忆（已记录，不重复调用）';
      case MemoryExtractionStatus.failed:
        final message = run.errorMessage.trim();
        return '提取失败：${message.isEmpty ? '未知错误' : message}';
    }
  }

  Widget _buildActionButton(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final colorScheme = Theme.of(ctx).colorScheme;
    final color = destructive ? colorScheme.error : colorScheme.primary;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteMessage(_TreeNode n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除消息'),
        content: const Text('确定删除该消息及其分支吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ChatDatabaseService.instance.deleteMessageBranch(
      sessionId: widget.sessionId,
      messageId: n.id,
    );
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final treeColors = isDark ? _TreeColors.dark : _TreeColors.light;
    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆树'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _reload,
          ),
          IconButton(
            tooltip: '记忆配置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubTaskSettingsPage(
                    initialSection: SubTaskSettingsSection.memory,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _roots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_tree_outlined,
                        size: 64,
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '当前会话还没有消息',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_roots.length > 1) _buildTabBar(context),
                    Expanded(child: _buildTreeArea(context, treeColors)),
                  ],
                ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 0.6,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: _roots.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == _selectedRootIndex;
          final root = _roots[index];
          final onPath = _activePathIds.contains(root.id);
          final label = _summaryLabel(root.text, index);
          final dotColor = onPath
              ? primary
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.45);

          final Color bgColor = selected
              ? primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
          final Color borderColor = selected
              ? primary.withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.5);
          final Color textColor = selected
              ? primary
              : colorScheme.onSurface.withValues(alpha: 0.78);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() => _selectedRootIndex = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : const [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        boxShadow: onPath
                            ? [
                                BoxShadow(
                                  color: primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.1,
                          letterSpacing: 0.2,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _summaryLabel(String text, int index) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return '开场 ${index + 1}';
    return cleaned.length > 14 ? '${cleaned.substring(0, 14)}…' : cleaned;
  }

  Widget _buildTreeArea(BuildContext context, _TreeColors treeColors) {
    final root = _roots[_selectedRootIndex];
    final canvas = _rootCanvasSizes[_selectedRootIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final hPadding = screenWidth > canvas.width
        ? (screenWidth - canvas.width) / 2
        : 0.0;
    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            constrained: false,
            minScale: 0.4,
            maxScale: 2.5,
            boundaryMargin: const EdgeInsets.all(200),
            child: SizedBox(
              width: math.max(canvas.width, screenWidth),
              height: math.max(canvas.height, 200),
              child: Transform.translate(
                offset: Offset(hPadding, 0),
                child: _MemoryTreeStack(
                  root: root,
                  treeColors: treeColors,
                  nodeRadius: _nodeRadius,
                  ringRadius: _ringRadius,
                  onTapNode: _onTapNode,
                  isEdgeActive: _isEdgeActive,
                  isNodeActive: _isNodeActive,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: _buildLegend(context),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final tc = isDark ? _TreeColors.dark : _TreeColors.light;
    Widget dot(Color c, String label) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: colorScheme.surface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(tc.userActive, '用户'),
            dot(tc.assistantActive, '角色'),
            dot(tc.memoryActive, '记忆'),
          ],
        ),
      ),
    );
  }
}

class _TreeColors {
  const _TreeColors({
    required this.userActive,
    required this.assistantActive,
    required this.memoryActive,
    required this.userInactive,
    required this.assistantInactive,
    required this.memoryInactive,
    required this.edgeActive,
    required this.branchPalette,
  });

  final Color userActive;
  final Color assistantActive;
  final Color memoryActive;
  final Color userInactive;
  final Color assistantInactive;
  final Color memoryInactive;
  final Color edgeActive;

  /// 分支轨道的独立配色表，按轨道索引循环取色。
  final List<Color> branchPalette;

  static const _TreeColors light = _TreeColors(
    userActive: Color(0xFF2F80ED),
    assistantActive: Color(0xFF27AE60),
    memoryActive: Color(0xFFF2994A),
    userInactive: Color(0xFFB7CDEC),
    assistantInactive: Color(0xFFBFE3CC),
    memoryInactive: Color(0xFFF6D6B7),
    edgeActive: Color(0xFF3D2A6B),
    branchPalette: [
      Color(0xFFE53935), // 红
      Color(0xFFF57C00), // 橙
      Color(0xFFF9A825), // 琥珀
      Color(0xFF43A047), // 绿
      Color(0xFF00ACC1), // 青
      Color(0xFF1E88E5), // 蓝
      Color(0xFF8E24AA), // 紫
      Color(0xFFD81B60), // 品红
    ],
  );

  static const _TreeColors dark = _TreeColors(
    userActive: Color(0xFF4A90D9),
    assistantActive: Color(0xFF3DBD73),
    memoryActive: Color(0xFFE8A84A),
    userInactive: Color(0xFF3A567A),
    assistantInactive: Color(0xFF2D5E3E),
    memoryInactive: Color(0xFF6B4D24),
    edgeActive: Color(0xFFB392E0),
    branchPalette: [
      Color(0xFFEF5350), // 红
      Color(0xFFFFA726), // 橙
      Color(0xFFFFCA28), // 琥珀
      Color(0xFF66BB6A), // 绿
      Color(0xFF26C6DA), // 青
      Color(0xFF42A5F5), // 蓝
      Color(0xFFAB47BC), // 紫
      Color(0xFFEC407A), // 品红
    ],
  );

  Color get edgeActivePaint => edgeActive;

  /// 返回指定轨道（Lane）的连线颜色：主线为高亮色，分支按轨道取色。
  Color branchColor(int lane) {
    if (lane <= 0) return edgeActivePaint;
    return branchPalette[(lane - 1) % branchPalette.length];
  }
}

class _MemoryTreeStack extends StatelessWidget {
  const _MemoryTreeStack({
    required this.root,
    required this.treeColors,
    required this.nodeRadius,
    required this.ringRadius,
    required this.onTapNode,
    required this.isEdgeActive,
    required this.isNodeActive,
  });

  final _TreeNode root;
  final _TreeColors treeColors;
  final double nodeRadius;
  final double ringRadius;
  final void Function(_TreeNode) onTapNode;
  final bool Function(_TreeNode parent, _TreeNode child) isEdgeActive;
  final bool Function(_TreeNode) isNodeActive;

  void _flatten(_TreeNode root, List<_TreeNode> out) {
    // 迭代前序遍历（子节点逆序入栈，出栈即按原顺序），保持与递归一致的顺序。
    final stack = <_TreeNode>[root];
    while (stack.isNotEmpty) {
      final n = stack.removeLast();
      out.add(n);
      for (var i = n.children.length - 1; i >= 0; i--) {
        stack.add(n.children[i]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flat = <_TreeNode>[];
    _flatten(root, flat);

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _TreeEdgePainter(
              root: root,
              treeColors: treeColors,
              isEdgeActive: isEdgeActive,
              isNodeActive: isNodeActive,
              nodeRadius: nodeRadius,
              ringRadius: ringRadius,
            ),
          ),
        ),
        for (final n in flat)
          Positioned(
            left: n.x - ringRadius,
            top: n.y - ringRadius,
            width: ringRadius * 2,
            height: ringRadius * 2,
            child: _NodeDot(
              node: n,
              treeColors: treeColors,
              isActive: isNodeActive(n),
              nodeRadius: nodeRadius,
              ringRadius: ringRadius,
              onTap: () => onTapNode(n),
            ),
          ),
      ],
    );
  }
}

class _NodeDot extends StatelessWidget {
  const _NodeDot({
    required this.node,
    required this.treeColors,
    required this.isActive,
    required this.nodeRadius,
    required this.ringRadius,
    required this.onTap,
  });

  final _TreeNode node;
  final _TreeColors treeColors;
  final bool isActive;
  final double nodeRadius;
  final double ringRadius;
  final VoidCallback onTap;

  Color get _color {
    if (node.hasMemory) {
      return isActive ? treeColors.memoryActive : treeColors.memoryInactive;
    }
    switch (node.kind) {
      case _NodeKind.user:
        return isActive ? treeColors.userActive : treeColors.userInactive;
      case _NodeKind.assistant:
        return isActive ? treeColors.assistantActive : treeColors.assistantInactive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: ringRadius + 4,
      child: CustomPaint(
        painter: _NodePainter(
          color: _color,
          showRing: isActive,
          nodeRadius: nodeRadius,
          ringRadius: ringRadius,
        ),
      ),
    );
  }
}

class _NodePainter extends CustomPainter {
  _NodePainter({
    required this.color,
    required this.showRing,
    required this.nodeRadius,
    required this.ringRadius,
  });

  final Color color;
  final bool showRing;
  final double nodeRadius;
  final double ringRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (showRing) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color;
      canvas.drawCircle(center, ringRadius - 1, ringPaint);
    }

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(center, nodeRadius, fill);
  }

  @override
  bool shouldRepaint(covariant _NodePainter old) {
    return old.color != color ||
        old.showRing != showRing ||
        old.nodeRadius != nodeRadius ||
        old.ringRadius != ringRadius;
  }
}

class _TreeEdgePainter extends CustomPainter {
  _TreeEdgePainter({
    required this.root,
    required this.treeColors,
    required this.isEdgeActive,
    required this.isNodeActive,
    required this.nodeRadius,
    required this.ringRadius,
  });

  final _TreeNode root;
  final _TreeColors treeColors;
  final bool Function(_TreeNode parent, _TreeNode child) isEdgeActive;
  final bool Function(_TreeNode) isNodeActive;
  final double nodeRadius;
  final double ringRadius;

  double _outerRadius(_TreeNode n) {
    return isNodeActive(n) ? ringRadius : nodeRadius + 1.5;
  }

  @override
  void paint(Canvas canvas, Size size) {
    void drawEdge(_TreeNode parent, _TreeNode child) {
      final active = isEdgeActive(parent, child);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = active ? 2.6 : 2.0
        ..color = active
            ? treeColors.edgeActivePaint
            : treeColors.branchColor(child.lane);

      // 端点固定在节点的正下方/正上方，保证连接点居中。
      final start = Offset(parent.x, parent.y + _outerRadius(parent));
      final end = Offset(child.x, child.y - _outerRadius(child));

      if (child.lane == parent.lane) {
        // 同轨道：严格竖直向下（主线或分支的延续）。
        canvas.drawLine(start, end, paint);
      } else {
        // 异轨道（分支引出）：从父节点水平向右拐出，
        // 再严格在自己的 Lane 竖直向下。使用单侧圆角直角折线。
        final dir = end.dx >= start.dx ? 1.0 : -1.0;
        final dy = end.dy - start.dy;
        final stub = math.min(dy.abs() * 0.4, 20.0);
        final cornerR = 8.0;
        final branchY = start.dy + stub;

        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(start.dx, branchY - cornerR)
          ..quadraticBezierTo(start.dx, branchY, start.dx + dir * cornerR, branchY)
          ..lineTo(end.dx - dir * cornerR, branchY)
          ..quadraticBezierTo(end.dx, branchY, end.dx, branchY + cornerR)
          ..lineTo(end.dx, end.dy);
        canvas.drawPath(path, paint);
      }
    }

    // 迭代前序遍历：出栈即画到父节点的连线，保持与递归一致的绘制顺序。
    void walk(_TreeNode root) {
      final stack = <(_TreeNode?, _TreeNode)>[(null, root)];
      while (stack.isNotEmpty) {
        final (parent, n) = stack.removeLast();
        if (parent != null) {
          drawEdge(parent, n);
        }
        for (var i = n.children.length - 1; i >= 0; i--) {
          stack.add((n, n.children[i]));
        }
      }
    }

    walk(root);
  }

  @override
  bool shouldRepaint(covariant _TreeEdgePainter old) {
    return old.root != root ||
        old.treeColors != treeColors ||
        old.isEdgeActive != isEdgeActive ||
        old.isNodeActive != isNodeActive ||
        old.nodeRadius != nodeRadius ||
        old.ringRadius != ringRadius;
  }
}

/// 编辑弹窗中的一条记忆。
class _MemoryEditItem {
  _MemoryEditItem({
    required this.memoryId,
    required this.isOrigin,
    required String content,
    required this.importance,
    this.invalidated = false,
    this.inherited,
    this.hasLocalEdits = false,
    this.type = MemoryType.other,
    this.isPinned = false,
  })  : controller = TextEditingController(text: content),
        initialContent = content,
        initialImportance = importance,
        _initiallyInvalidated = invalidated,
        initialType = type,
        initialPinned = isPinned;

  /// null 表示本次新增的条目。
  final String? memoryId;

  /// 来源节点即当前节点时允许物理删除；否则只能失效。
  final bool isOrigin;
  final TextEditingController controller;

  /// 变更检测基线：默认是打开弹窗时的值；点「还原」后会对齐到祖先状态，
  /// 之后若再编辑即视为相对祖先的新改动。
  String initialContent;
  int initialImportance;
  int importance;
  MemoryType type;
  MemoryType initialType;
  bool isPinned;
  bool initialPinned;

  /// 当前分支上是否已失效（仍可恢复）。
  bool invalidated;

  /// 打开弹层时是否已失效，用于区分「本次停用」与「恢复」。
  final bool _initiallyInvalidated;
  bool get initiallyInvalidated => _initiallyInvalidated;

  /// 祖先时刻的记忆状态；用于“还原本节点改动”。
  final ResolvedMemory? inherited;

  /// 本节点是否已有针对该记忆的差量（存在即可还原）。
  final bool hasLocalEdits;
  bool removed = false;

  /// 用户点击「恢复」后需要写入 restore 差量。
  bool needsRestore = false;

  /// 用户点击「还原」后，保存时删除本节点的全部改动。
  bool revertRequested = false;

  bool get isNew => memoryId == null;

  bool get hasChanges =>
      !removed &&
      (isNew ||
          controller.text.trim() != initialContent ||
          importance != initialImportance ||
          type != initialType ||
          isPinned != initialPinned);

  void dispose() => controller.dispose();
}

/// 结构化记忆编辑弹窗：逐条编辑内容与重要度，支持新增、失效、彻底删除。
class _MemoryEditorDialog extends StatefulWidget {
  const _MemoryEditorDialog({
    required this.sessionId,
    required this.messageId,
    required this.initial,
    this.inheritedById = const {},
    this.localEditIds = const {},
  });

  final String sessionId;
  final String messageId;
  final List<ResolvedMemory> initial;

  /// 祖先时刻状态，供“还原本节点改动”显示回退值。
  final Map<String, ResolvedMemory> inheritedById;

  /// 本节点上已有差量的目标记忆 id。
  final Set<String> localEditIds;

  @override
  State<_MemoryEditorDialog> createState() => _MemoryEditorDialogState();
}

class _MemoryEditorDialogState extends State<_MemoryEditorDialog> {
  late final List<_MemoryEditItem> _items;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = [
      for (final memory in widget.initial)
        _MemoryEditItem(
          memoryId: memory.id,
          isOrigin: memory.origin.branchLeafId == widget.messageId,
          content: memory.content,
          importance: memory.importance,
          invalidated: memory.invalidated,
          inherited: widget.inheritedById[memory.id],
          hasLocalEdits: widget.localEditIds.contains(memory.id),
          type: memory.type,
          isPinned: memory.isPinned,
        ),
    ];
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addBlank() {
    setState(() {
      _items.add(
        _MemoryEditItem(
          memoryId: null,
          isOrigin: true,
          content: '',
          importance: 3,
        ),
      );
    });
  }

  /// 编辑弹窗的集中说明：归总到右上角 ⓘ，避免每条记忆都挂提示。
  Future<void> _showEditorHelp(BuildContext context) async {
    final items = <(String, String)>[
      ('重要度 / 类型', '用于分类展示与召回排序。'),
      ('常驻', '设为常驻后每次对话都会注入，不占用召回条数。'),
      ('原始记忆', '来源即当前消息；改动或删除会影响所有后代分支。'),
      ('删除（垃圾桶）', '彻底删除原始记忆，仅原始记忆可用，影响所有后代。'),
      ('禁止 / 停用', '仅使该记忆在本分支失效，保存后可随时恢复。'),
      ('还原', '清除本节点对该记忆的全部改动，回到祖先状态。'),
    ];
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('记忆编辑说明'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, desc) in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(ctx).style,
                      children: [
                        TextSpan(
                          text: '$label：',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: desc),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestRemove(_MemoryEditItem item) async {
    if (item.isOrigin && !item.isNew) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('彻底删除原始记忆'),
          content: const Text('该记忆创建于当前消息节点。彻底删除会影响所有后代分支，且不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('删除'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => item.removed = true);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final service = ChatMemoryService.instance;
    try {
      final commands = <MemoryEditCommand>[];
      for (final item in _items) {
        if (item.removed) {
          final memoryId = item.memoryId;
          if (memoryId == null) continue;
          commands.add(
            MemoryEditCommand(
              kind: item.isOrigin
                  ? MemoryEditKind.deleteOrigin
                  : MemoryEditKind.invalidate,
              targetMemoryId: memoryId,
            ),
          );
          continue;
        }
        final content = item.controller.text.trim();
        if (item.isNew) {
          if (content.isEmpty) continue;
          commands.add(
            MemoryEditCommand(
              kind: MemoryEditKind.add,
              content: content,
              importance: item.importance,
              type: item.type,
              isPinned: item.isPinned,
            ),
          );
          continue;
        }
        final memoryId = item.memoryId!;
        if (item.revertRequested) {
          // 先清除本节点对该记忆的旧差量，回到祖先状态；若还原后又编辑过，
          // 再按「祖先状态 + 本次编辑」补一条 update / 失效恢复，避免被丢弃。
          commands.add(
            MemoryEditCommand(
              kind: MemoryEditKind.clearEdits,
              targetMemoryId: memoryId,
            ),
          );
          final inherited = item.inherited;
          final content = item.controller.text.trim();
          final fieldsDiffer = inherited == null
              ? item.hasChanges
              : (content != inherited.content ||
                  item.importance != inherited.importance ||
                  item.type != inherited.type ||
                  item.isPinned != inherited.isPinned);
          if (fieldsDiffer) {
            if (content.isEmpty) {
              throw StateError('记忆内容不能为空');
            }
            commands.add(
              MemoryEditCommand(
                kind: MemoryEditKind.update,
                targetMemoryId: memoryId,
                content: content,
                importance: item.importance,
                type: item.type,
                isPinned: item.isPinned,
                isOrigin: item.isOrigin,
              ),
            );
          }
          final baseInvalidated =
              inherited?.invalidated ?? item.initiallyInvalidated;
          if (item.invalidated != baseInvalidated) {
            commands.add(
              MemoryEditCommand(
                kind: item.invalidated
                    ? MemoryEditKind.invalidate
                    : MemoryEditKind.restore,
                targetMemoryId: memoryId,
                isOrigin: item.isOrigin,
              ),
            );
          }
          continue;
        }
        final changedFields = item.hasChanges;
        if (changedFields) {
          commands.add(
            MemoryEditCommand(
              kind: MemoryEditKind.update,
              targetMemoryId: memoryId,
              content: content,
              importance: item.importance,
              type: item.type,
              isPinned: item.isPinned,
              isOrigin: item.isOrigin,
            ),
          );
        }
        // 点过「恢复」，或原本失效但修改了内容/重要度，都视为恢复该记忆；
        // 原本有效、本次被停用的，则写入失效差量。
        if (item.needsRestore || (item.initiallyInvalidated && changedFields)) {
          commands.add(
            MemoryEditCommand(
              kind: MemoryEditKind.restore,
              targetMemoryId: memoryId,
              isOrigin: item.isOrigin,
            ),
          );
        } else if (!item.initiallyInvalidated && item.invalidated) {
          commands.add(
            MemoryEditCommand(
              kind: MemoryEditKind.invalidate,
              targetMemoryId: memoryId,
              isOrigin: item.isOrigin,
            ),
          );
        }
      }
      // 一次性在事务内提交全部改动，失败整体回滚，避免半提交与重复新增。
      await service.applyMemoryEdits(
        sessionId: widget.sessionId,
        atMessageId: widget.messageId,
        commands: commands,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存记忆失败：$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = _items.where((item) => !item.removed).length;
    final maxHeight =
        (MediaQuery.of(context).size.height * 0.85).clamp(320.0, 760.0);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
              child: Row(
                children: [
                  Text(
                    '编辑记忆',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (_items.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count 条',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    tooltip: '说明',
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.surfaceContainerHighest,
                      foregroundColor: scheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      _showEditorHelp(context);
                    },
                    icon: const Icon(Icons.info_outline),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _items.isEmpty
                    ? Center(
                        child: Text(
                          '当前分支还没有可见记忆',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _buildItem(context, _items[index]),
                      ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _saving ? null : _addBlank,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('添加记忆'),
                    ),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? '保存中…' : '保存'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 还原本节点改动：把行内容回填为祖先状态，并在保存时清除本节点差量。
  ///
  /// 这里同时把「变更检测基线」对齐到祖先状态：还原后再编辑，会以祖先状态
  /// 为基准重新提交，不会像以前那样被 `revertRequested` 分支静默丢弃。
  void _revertItem(_MemoryEditItem item) {
    final inherited = item.inherited;
    setState(() {
      item.revertRequested = true;
      item.removed = false;
      item.needsRestore = false;
      if (inherited == null) {
        item.invalidated = false;
        return;
      }
      item.invalidated = inherited.invalidated;
      item.controller.text = inherited.content;
      item.importance = inherited.importance;
      item.type = inherited.type;
      item.isPinned = inherited.isPinned;
      item.initialContent = inherited.content;
      item.initialImportance = inherited.importance;
      item.initialType = inherited.type;
      item.initialPinned = inherited.isPinned;
    });
  }

  Widget _buildPrimaryAction(BuildContext context, _MemoryEditItem item) {
    final scheme = Theme.of(context).colorScheme;
    if (item.isNew) {
      return IconButton(
        style: IconButton.styleFrom(
          fixedSize: const Size(28, 28),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        tooltip: '移除（不保存）',
        onPressed: _saving ? null : () => setState(() => item.removed = true),
        icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
      );
    }
    if (item.invalidated) {
      return IconButton(
        style: IconButton.styleFrom(
          fixedSize: const Size(28, 28),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        tooltip: '恢复（撤销失效）',
        onPressed: _saving
            ? null
            : () => setState(() {
                  item.invalidated = false;
                  // 只有原本就失效的才需要写 restore；本次停用又取消的只是
                  // 回到原状态，无需额外差量。
                  item.needsRestore = item.initiallyInvalidated;
                }),
        icon: Icon(Icons.restore, size: 18, color: scheme.primary),
      );
    }
    if (item.isOrigin) {
      return IconButton(
        style: IconButton.styleFrom(
          fixedSize: const Size(28, 28),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        tooltip: '彻底删除（影响所有后代）',
        onPressed: _saving ? null : () => _requestRemove(item),
        icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
      );
    }
    return IconButton(
      style: IconButton.styleFrom(
        fixedSize: const Size(28, 28),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      tooltip: '停用（保存后可恢复）',
      onPressed: _saving ? null : () => setState(() => item.invalidated = true),
      icon: Icon(Icons.block, size: 18, color: scheme.error),
    );
  }

  Widget _buildItem(BuildContext context, _MemoryEditItem item) {
    final scheme = Theme.of(context).colorScheme;
    if (item.removed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.block, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.controller.text.trim().isEmpty
                    ? '（空白记忆）'
                    : item.controller.text.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            IconButton(
              style: IconButton.styleFrom(
                fixedSize: const Size(28, 28),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: '取消删除',
              onPressed:
                  _saving ? null : () => setState(() => item.removed = false),
              icon: Icon(Icons.restore, size: 18, color: scheme.primary),
            ),
          ],
        ),
      );
    }
    // 每个记忆一张紧凑卡片：内容与属性控件同属一个容器，边界清晰；
    // 卡片内边距统一 10（上下左右一致），卡与卡之间也统一 10。
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: item.controller,
              enabled: !_saving,
              maxLines: 4,
              minLines: 1,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.3,
                    color: item.invalidated ? scheme.onSurfaceVariant : null,
                  ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(6),
                hintText: item.isNew ? '新记忆内容' : '记忆内容',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左侧属性用 Wrap 承载：超窄屏或大字号时自动换行，避免溢出。
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildMetaChip<int>(
                        context,
                        label: '重要度',
                        value: item.importance.clamp(1, 5),
                        options: [
                          for (var value = 1; value <= 5; value++)
                            (value: value, label: '$value'),
                        ],
                        onChanged: (value) =>
                            setState(() => item.importance = value),
                      ),
                      _buildMetaChip<MemoryType>(
                        context,
                        label: '类型',
                        value: item.type,
                        options: [
                          for (final type in MemoryType.values)
                            (value: type, label: type.label),
                        ],
                        onChanged: (value) =>
                            setState(() => item.type = value),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        fixedSize: const Size(28, 28),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: item.isPinned ? '取消常驻' : '设为常驻（每次都注入）',
                      onPressed: _saving
                          ? null
                          : () => setState(() => item.isPinned = !item.isPinned),
                      icon: Icon(
                        item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 18,
                        color: item.isPinned
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    if (!item.isNew &&
                        item.hasLocalEdits &&
                        !item.revertRequested)
                      IconButton(
                        style: IconButton.styleFrom(
                          fixedSize: const Size(28, 28),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        tooltip: '还原本节点改动（消除这次编辑）',
                        onPressed: _saving ? null : () => _revertItem(item),
                        icon: Icon(
                          Icons.undo,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    _buildPrimaryAction(context, item),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 紧凑的 M3 描边 Chip 触发器：左侧小标签 + 右侧当前值 + 下拉箭头，
  /// 高度固定 28，避免 DropdownButton 的 48dp 最小高度撑开行距。
  Widget _buildMetaChip<T>(
    BuildContext context, {
    required String label,
    required T value,
    required List<({T value, String label})> options,
    required ValueChanged<T> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final valueLabel = options.firstWhere(
      (option) => option.value == value,
      orElse: () => options.first,
    ).label;
    return PopupMenuButton<T>(
      initialValue: value,
      enabled: !_saving,
      tooltip: '',
      padding: EdgeInsets.zero,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<T>(
            value: option.value,
            height: 40,
            child: Text(option.label),
          ),
      ],
      child: Container(
        height: 28,
        padding: const EdgeInsets.only(left: 10, right: 4),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              valueLabel,
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
