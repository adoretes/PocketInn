import 'package:flutter/material.dart';

import '../models/world_book.dart';
import '../services/world_book_service.dart';
import 'world_book_edit_page.dart';

class WorldBookPage extends StatefulWidget {
  const WorldBookPage({super.key});

  @override
  State<WorldBookPage> createState() => _WorldBookPageState();
}

class _WorldBookPageState extends State<WorldBookPage> {
  List<WorldBook> _worldBooks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorldBooks();
  }

  Future<void> _loadWorldBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final books = await WorldBookService.instance.loadAll();
      if (mounted) {
        setState(() {
          _worldBooks = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onBack() async {
    await Navigator.maybePop(context);
  }

  Future<void> _onImport() async {
    try {
      final book = await WorldBookService.instance.importFromFile();
      if (book != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已导入：${book.name}')));
        await _loadWorldBooks();
      }
    } on ImportException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    }
  }

  Future<void> _onCreate() async {
    final nameController = TextEditingController(text: '新世界书');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新建世界书'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('创建'),
            ),
          ],
        );
      },
    );

    final normalizedName = nameController.text.trim();
    nameController.dispose();

    if (result == true && mounted) {
      try {
        await WorldBookService.instance.create(
          name: normalizedName.isEmpty ? '新世界书' : normalizedName,
        );
        await _loadWorldBooks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('创建失败: $e')));
        }
      }
    }
  }

  Future<void> _onExport(WorldBook worldBook) async {
    try {
      final path = await WorldBookService.instance.exportToFile(worldBook);
      if (path != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已导出到: $path')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  Future<void> _onDelete(WorldBook worldBook) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除「${worldBook.name}」吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await WorldBookService.instance.delete(worldBook.id);
        await _loadWorldBooks();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('已删除：${worldBook.name}')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
        }
      }
    }
  }

  Future<void> _onWorldBookTap(WorldBook worldBook) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorldBookEditPage(worldBook: worldBook),
      ),
    );
    // 返回后刷新列表
    await _loadWorldBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
        ),
        title: const Text('世界书管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _onImport,
            tooltip: '导入',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _onCreate,
            tooltip: '新建',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: $_error'),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadWorldBooks, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_worldBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无世界书',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角「+」创建或「↓」导入',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _worldBooks.length,
      itemBuilder: (context, index) {
        final worldBook = _worldBooks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _WorldBookCard(
            worldBook: worldBook,
            onTap: () => _onWorldBookTap(worldBook),
            onExport: () => _onExport(worldBook),
            onDelete: () => _onDelete(worldBook),
          ),
        );
      },
    );
  }
}

class _WorldBookCard extends StatelessWidget {
  const _WorldBookCard({
    required this.worldBook,
    required this.onTap,
    required this.onExport,
    required this.onDelete,
  });

  final WorldBook worldBook;
  final VoidCallback onTap;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.12), colorScheme.surface],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worldBook.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        worldBook.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${worldBook.entries.length} 个条目',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    _ListActionButton(
                      icon: Icons.file_upload_outlined,
                      tooltip: '导出',
                      onPressed: onExport,
                    ),
                    const SizedBox(height: 8),
                    _ListActionButton(
                      icon: Icons.delete_outline,
                      tooltip: '删除',
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListActionButton extends StatelessWidget {
  const _ListActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: IconButton(onPressed: onPressed, icon: Icon(icon, size: 18)),
      ),
    );
  }
}
