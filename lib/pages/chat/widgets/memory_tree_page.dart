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
  });

  final String id;
  final _NodeKind kind;
  final String? parentId;
  final String text;
  final List<MemoryNode> memoryEntries;
  final List<_TreeNode> children = <_TreeNode>[];

  // 布局结果
  double x = 0;
  double y = 0;
  int depth = 0;
  int lane = 0;
  bool isMainLine = false;
  _TreeNode? primaryChild;

  bool get hasMemory => memoryEntries.isNotEmpty;
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

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final db = ChatDatabaseService.instance;
    final nodes = await db.loadAllSessionNodes(widget.sessionId);
    if (!mounted) return;
    final memories = await db.loadAllSessionMemories(widget.sessionId);
    if (!mounted) return;

    final byMessageId = <String, List<MemoryNode>>{};
    for (final m in memories) {
      byMessageId.putIfAbsent(m.branchLeafId, () => <MemoryNode>[]).add(m);
    }
    for (final list in byMessageId.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

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
    final hasMemory = n.hasMemory;
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
                      (hasMemory ? 108.0 : 0.0); // 记忆列表
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
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tc.memoryActive
                                          .withValues(alpha: 0.16),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '记忆点 · ${n.memoryEntries.length} 条',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: tc.memoryActive,
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
                                n.memoryEntries
                                    .map((m) => '• ${m.content}')
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
                                icon: hasMemory
                                    ? Icons.edit_note_outlined
                                    : Icons.bookmark_add_outlined,
                                label:
                                    hasMemory ? '编辑记忆' : '添加记忆',
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  if (hasMemory) {
                                    _editMemoriesAt(
                                      n.id,
                                      n.memoryEntries,
                                    );
                                  } else {
                                    _addMemoryAt(n.id);
                                  }
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

  Future<void> _addMemoryAt(String messageId) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加记忆'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 6,
          minLines: 3,
          decoration: const InputDecoration(
            hintText: '输入要记忆的内容（可多行，每行一条）',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final lines = _splitLines(result);
    if (lines.isEmpty) return;
    for (final line in lines) {
      await ChatMemoryService.instance.addMemory(
        sessionId: widget.sessionId,
        branchLeafId: messageId,
        content: line,
        sourceMessageIds: [messageId],
      );
    }
    if (!mounted) return;
    await _reload();
  }

  Future<void> _editMemoriesAt(
    String messageId,
    List<MemoryNode> entries,
  ) async {
    final initial = entries.map((m) => m.content).join('\n');
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑记忆'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 12,
            minLines: 4,
            decoration: const InputDecoration(
              hintText: '每行一条记忆，留空将清除该节点的所有记忆',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final lines = _splitLines(result);
    await ChatMemoryService.instance.replaceBranchMemories(
      sessionId: widget.sessionId,
      branchLeafId: messageId,
      contents: lines,
    );
    if (!mounted) return;
    await _reload();
  }

  List<String> _splitLines(String text) {
    return text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);
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
