import 'package:flutter/material.dart';

import '../../../models/chat_memory.dart';
import '../../../services/chat_memory_service.dart';
import '../../memory_settings_page.dart';

class MemoryEditDialog extends StatefulWidget {
  final String sessionId;
  final List<String> pathMessageIds;

  const MemoryEditDialog({
    super.key,
    required this.sessionId,
    required this.pathMessageIds,
  });

  @override
  State<MemoryEditDialog> createState() => _MemoryEditDialogState();
}

class _MemoryEditDialogState extends State<MemoryEditDialog> {
  List<MemoryNode>? _memories;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    setState(() => _isLoading = true);
    final memories = widget.pathMessageIds.isEmpty
        ? await ChatMemoryService.instance.loadAllSessionMemories(
            widget.sessionId,
          )
        : await ChatMemoryService.instance.getBranchMemories(
            sessionId: widget.sessionId,
            pathMessageIds: widget.pathMessageIds,
          );
    if (!mounted) return;
    setState(() {
      _memories = memories;
      _isLoading = false;
    });
  }

  Future<void> _editMemory(MemoryNode memory) async {
    final controller = TextEditingController(text: memory.content);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑记忆'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '修改记忆内容...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    await ChatMemoryService.instance.updateMemory(
      memoryId: memory.id,
      content: result,
    );
    await _loadMemories();
  }

  Future<void> _deleteMemory(MemoryNode memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记忆'),
        content: const Text('确定删除这条记忆吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ChatMemoryService.instance.deleteMemory(memory.id);
    await _loadMemories();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('长期记忆'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '记忆配置',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MemorySettingsPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _memories == null || _memories!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '当前分支暂无记忆',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _memories!.length,
                  itemBuilder: (context, index) {
                    final memory = _memories![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    memory.content,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _editMemory(memory);
                                      case 'delete':
                                        _deleteMemory(memory);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('编辑'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('删除'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (memory.isUserEdited)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '已编辑',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.tertiary,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  _formatDate(memory.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)} '
        '${_pad(date.hour)}:${_pad(date.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
