import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/chat_memory.dart';
import '../../../models/chat_session.dart';
import '../../../services/chat_database_service.dart';
import '../../../services/chat_memory_service.dart';
import '../../memory_settings_page.dart';

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
  int subtreeWidth = 1;

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
  static const double _colSpacing = 56;
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
    final memories = await db.loadAllSessionMemories(widget.sessionId);

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
    void sortChildren(_TreeNode n) {
      n.children.sort((a, b) =>
          (orderIndex[a.id] ?? 0).compareTo(orderIndex[b.id] ?? 0));
      for (final c in n.children) {
        sortChildren(c);
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
    while (cur != null) {
      activeIds.add(cur);
      final n = treeNodes[cur];
      if (n == null) break;
      cur = n.parentId;
    }

    // 计算布局
    int assignWidth(_TreeNode n, int depth) {
      n.depth = depth;
      if (n.children.isEmpty) {
        n.subtreeWidth = 1;
        return 1;
      }
      var sum = 0;
      for (final c in n.children) {
        sum += assignWidth(c, depth + 1);
      }
      n.subtreeWidth = math.max(1, sum);
      return n.subtreeWidth;
    }

    void assignX(_TreeNode n, double xStart) {
      final centerCol = xStart + n.subtreeWidth / 2.0;
      n.x = _padding + centerCol * _colSpacing;
      n.y = _padding + n.depth * _rowSpacing;
      var cursor = xStart;
      for (final c in n.children) {
        assignX(c, cursor);
        cursor += c.subtreeWidth;
      }
    }

    int maxDepthOf(_TreeNode n) {
      var max = n.depth;
      for (final c in n.children) {
        final d = maxDepthOf(c);
        if (d > max) max = d;
      }
      return max;
    }

    final canvasSizes = <Size>[];
    for (final r in roots) {
      assignWidth(r, 0);
      assignX(r, 0);
      final depth = maxDepthOf(r);
      final width = _padding * 2 + r.subtreeWidth * _colSpacing;
      final height = _padding * 2 + (depth + 1) * _rowSpacing;
      canvasSizes.add(Size(width, height));
    }

    // 选择默认 tab：包含 activeLeafMessageId 的根；否则 0。
    var defaultIndex = 0;
    if (widget.activeLeafMessageId != null) {
      bool contains(_TreeNode n, String id) {
        if (n.id == id) return true;
        for (final c in n.children) {
          if (contains(c, id)) return true;
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
      _selectedRootIndex = defaultIndex.clamp(
        0,
        roots.isEmpty ? 0 : roots.length - 1,
      );
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
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
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
                          style: Theme.of(sheetCtx)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: Theme.of(sheetCtx)
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
                              color: _kMemoryActive.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '记忆点 · ${n.memoryEntries.length} 条',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _kMemoryActive,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview.isEmpty ? '（无内容）' : preview,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(sheetCtx).textTheme.bodyMedium,
                    ),
                    if (hasMemory) ...[
                      const SizedBox(height: 8),
                      Text(
                        n.memoryEntries
                            .map((m) => '• ${m.content}')
                            .join('\n'),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(sheetCtx)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(sheetCtx)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.my_location),
                title: const Text('切换到该分支'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _jumpTo(n.id);
                },
              ),
              if (hasMemory)
                ListTile(
                  leading: const Icon(Icons.edit_note_outlined),
                  title: const Text('编辑该节点的记忆'),
                  subtitle: const Text('每行一条，可在此添加或删除'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _editMemoriesAt(n.id, n.memoryEntries);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.bookmark_add_outlined),
                  title: const Text('在此处添加记忆'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _addMemoryAt(n.id);
                  },
                ),
            ],
          ),
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
    // 通过沿 parent 回溯，逐层把分支状态切到包含 messageId 的链路。
    final allNodes = await db.loadAllSessionNodes(widget.sessionId);
    final byId = {for (final n in allNodes) n.id: n};
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
    // 再从 messageId 走到叶子，让 current_leaf 指向 leafId
    await db.switchActiveBranch(
      sessionId: widget.sessionId,
      parentMessageId: byId[leafId]?.parentId,
      childMessageId: leafId,
    );

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  builder: (_) => const MemorySettingsPage(),
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
                    Expanded(child: _buildTreeArea(context)),
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

  Widget _buildTreeArea(BuildContext context) {
    final root = _roots[_selectedRootIndex];
    final canvas = _rootCanvasSizes[_selectedRootIndex];
    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            constrained: false,
            minScale: 0.4,
            maxScale: 2.5,
            boundaryMargin: const EdgeInsets.all(200),
            child: SizedBox(
              width: math.max(
                canvas.width,
                MediaQuery.of(context).size.width,
              ),
              height: math.max(canvas.height, 200),
              child: _MemoryTreeStack(
                root: root,
                nodeRadius: _nodeRadius,
                ringRadius: _ringRadius,
                onTapNode: _onTapNode,
                isEdgeActive: _isEdgeActive,
                isNodeActive: _isNodeActive,
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
            dot(_kUserActive, '用户'),
            dot(_kAssistantActive, '角色'),
            dot(_kMemoryActive, '记忆'),
          ],
        ),
      ),
    );
  }
}

const Color _kUserActive = Color(0xFF2F80ED);
const Color _kAssistantActive = Color(0xFF27AE60);
const Color _kMemoryActive = Color(0xFFF2994A);

const Color _kUserInactive = Color(0xFFB7CDEC);
const Color _kAssistantInactive = Color(0xFFBFE3CC);
const Color _kMemoryInactive = Color(0xFFF6D6B7);

const Color _kEdgeActive = Color(0xFF3D2A6B);
final Color _kEdgeInactive = const Color(0xFF3D2A6B).withValues(alpha: 0.18);

class _MemoryTreeStack extends StatelessWidget {
  const _MemoryTreeStack({
    required this.root,
    required this.nodeRadius,
    required this.ringRadius,
    required this.onTapNode,
    required this.isEdgeActive,
    required this.isNodeActive,
  });

  final _TreeNode root;
  final double nodeRadius;
  final double ringRadius;
  final void Function(_TreeNode) onTapNode;
  final bool Function(_TreeNode parent, _TreeNode child) isEdgeActive;
  final bool Function(_TreeNode) isNodeActive;

  void _flatten(_TreeNode n, List<_TreeNode> out) {
    out.add(n);
    for (final c in n.children) {
      _flatten(c, out);
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
    required this.isActive,
    required this.nodeRadius,
    required this.ringRadius,
    required this.onTap,
  });

  final _TreeNode node;
  final bool isActive;
  final double nodeRadius;
  final double ringRadius;
  final VoidCallback onTap;

  Color get _color {
    if (node.hasMemory) {
      return isActive ? _kMemoryActive : _kMemoryInactive;
    }
    switch (node.kind) {
      case _NodeKind.user:
        return isActive ? _kUserActive : _kUserInactive;
      case _NodeKind.assistant:
        return isActive ? _kAssistantActive : _kAssistantInactive;
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
    required this.isEdgeActive,
    required this.isNodeActive,
    required this.nodeRadius,
    required this.ringRadius,
  });

  final _TreeNode root;
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
        ..strokeWidth = active ? 2.6 : 1.2
        ..color = active ? _kEdgeActive : _kEdgeInactive;

      // 端点固定在节点的正下方/正上方，保证连接点居中。
      final start = Offset(parent.x, parent.y + _outerRadius(parent));
      final end = Offset(child.x, child.y - _outerRadius(child));

      // 让线先垂直延伸一段再弯曲：将贝塞尔的两个控制点放在端点正下/正上。
      final dy = end.dy - start.dy;
      // 垂直延伸量：取行距的 1/3 与 18 之间的较小值，并不超过总距离一半。
      final stub = math.min(18.0, dy.abs() / 2);
      final c1 = Offset(start.dx, start.dy + stub);
      final c2 = Offset(end.dx, end.dy - stub);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);
    }

    void walk(_TreeNode n) {
      for (final c in n.children) {
        drawEdge(n, c);
        walk(c);
      }
    }

    walk(root);
  }

  @override
  bool shouldRepaint(covariant _TreeEdgePainter old) {
    return old.root != root ||
        old.isEdgeActive != isEdgeActive ||
        old.isNodeActive != isNodeActive ||
        old.nodeRadius != nodeRadius ||
        old.ringRadius != ringRadius;
  }
}
