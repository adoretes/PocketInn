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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入：${book.name}')),
        );
        await _loadWorldBooks();
      }
    } on ImportException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _onCreate() async {
    final nameController = TextEditingController(text: '新世界书');
    final color = ValueNotifier<Color>(const Color(0xFF4B6CB7));

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
              const SizedBox(height: 16),
              ValueListenableBuilder<Color>(
                valueListenable: color,
                builder: (context, value, child) {
                  return Row(
                    children: [
                      const Text('颜色：'),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final newColor = await showDialog<Color>(
                            context: context,
                            builder: (context) {
                              return _ColorPickerDialog(initialColor: value);
                            },
                          );
                          if (newColor != null) {
                            color.value = newColor;
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: value,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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

    nameController.dispose();
    color.dispose();

    if (result == true && mounted) {
      try {
        await WorldBookService.instance.create(
          name: nameController.text.trim().isEmpty 
              ? '新世界书' 
              : nameController.text.trim(),
          colorValue: color.value.toARGB32(),
        );
        await _loadWorldBooks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _onExport(WorldBook worldBook) async {
    try {
      final path = await WorldBookService.instance.exportToFile(worldBook);
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出到: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
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
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已删除：${worldBook.name}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
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
            FilledButton(
              onPressed: _loadWorldBooks,
              child: const Text('重试'),
            ),
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角「+」创建或「↓」导入',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                worldBook.color.withValues(alpha: 0.16),
                Colors.white,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: worldBook.color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
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
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${worldBook.entries.length} 个条目',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: worldBook.color,
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
    return Tooltip(
      message: tooltip,
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

/// 颜色选择对话框
class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  static const List<Color> _presetColors = [
    Color(0xFF4B6CB7),
    Color(0xFF2A9D8F),
    Color(0xFFB56576),
    Color(0xFFE76F51),
    Color(0xFFF4A261),
    Color(0xFFE9C46A),
    Color(0xFF264653),
    Color(0xFF1D3557),
    Color(0xFF457B9D),
    Color(0xFFA8DADC),
    Color(0xFF6D597A),
    Color(0xFFB56576),
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: SizedBox(
        width: 240,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _presetColors.map((color) {
            final isSelected = color.toARGB32() == _selectedColor.toARGB32();
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedColor),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
