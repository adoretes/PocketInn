import 'package:flutter/material.dart';

import '../models/preset.dart';
import '../services/preset_service.dart';
import 'preset_edit_page.dart';

class PresetPage extends StatefulWidget {
  const PresetPage({super.key});

  @override
  State<PresetPage> createState() => _PresetPageState();
}

class _PresetPageState extends State<PresetPage> {
  late Future<List<PresetSummary>> _presetsFuture;

  @override
  void initState() {
    super.initState();
    _presetsFuture = _loadPresets();
  }

  Future<List<PresetSummary>> _loadPresets() {
    return PresetService.instance.loadAllSummaries();
  }

  Future<void> _refresh() async {
    final future = _loadPresets();
    setState(() {
      _presetsFuture = future;
    });
    await future;
  }

  Future<void> _onCreate() async {
    final preset = await PresetService.instance.buildEditableTemplate();
    if (!mounted) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PresetEditPage(preset: preset, isNewPreset: true),
      ),
    );

    if (saved == true) {
      await _refresh();
    }
  }

  Future<void> _onImport() async {
    try {
      final preset = await PresetService.instance.importFromFile();
      if (preset == null || !mounted) return;

      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已导入预设：${preset.name}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败：$e')));
    }
  }

  Future<void> _onPresetTap(PresetSummary summary) async {
    if (summary.isBuiltin) {
      final create = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('默认预设'),
            content: const Text('默认预设不可编辑，是否新建一个预设？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('新建'),
              ),
            ],
          );
        },
      );
      if (create == true) {
        await _onCreate();
      }
      return;
    }

    final preset = await PresetService.instance.loadById(summary.id);
    if (preset == null || !mounted) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => PresetEditPage(preset: preset)),
    );

    if (saved == true) {
      await _refresh();
    }
  }

  Future<void> _onExport(PresetSummary summary) async {
    final preset = await PresetService.instance.loadById(summary.id);
    if (preset == null || !mounted) return;

    final path = await PresetService.instance.exportToFile(preset);
    if (path == null || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('导出成功：$path')));
  }

  Future<void> _onDuplicate(PresetSummary summary) async {
    final preset = await PresetService.instance.duplicate(summary.id);
    if (preset == null || !mounted) return;

    await _refresh();
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已复制预设：${preset.name}')));
  }

  Future<void> _onDelete(PresetSummary summary) async {
    if (summary.isBuiltin) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('默认预设不可删除')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除预设'),
          content: Text('确定删除 ${summary.name} 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await PresetService.instance.delete(summary.id);
    await _refresh();
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已删除预设：${summary.name}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('预设管理'),
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
      body: FutureBuilder<List<PresetSummary>>(
        future: _presetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final presets = snapshot.data ?? const <PresetSummary>[];
          if (presets.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('还没有预设')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final preset = presets[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PresetCard(
                    preset: preset,
                    onTap: () => _onPresetTap(preset),
                    onExport: () => _onExport(preset),
                    onDuplicate: () => _onDuplicate(preset),
                    onDelete: () => _onDelete(preset),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.onTap,
    required this.onExport,
    required this.onDuplicate,
    required this.onDelete,
  });

  final PresetSummary preset;
  final VoidCallback onTap;
  final VoidCallback onExport;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = preset.isBuiltin ? Colors.orange : Colors.blue;
    final accentForeground = colorScheme.brightness == Brightness.dark
        ? accent.shade300
        : accent.shade600;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(
                  alpha: colorScheme.brightness == Brightness.dark
                      ? 0.18
                      : 0.08,
                ),
                colorScheme.surfaceContainerLow,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: colorScheme.brightness == Brightness.dark
                      ? 0.18
                      : 0.05,
                ),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: colorScheme.brightness == Brightness.dark
                          ? 0.22
                          : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    preset.isBuiltin ? Icons.star_outline : Icons.tune_outlined,
                    color: accentForeground,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset.isBuiltin
                            ? '内置默认预设'
                            : '上次更新：${_formatTime(preset.updatedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PresetActionButton(
                      icon: Icons.file_upload_outlined,
                      tooltip: '导出',
                      onPressed: onExport,
                    ),
                    const SizedBox(width: 8),
                    _PresetActionButton(
                      icon: Icons.copy_outlined,
                      tooltip: '复制',
                      onPressed: onDuplicate,
                    ),
                    const SizedBox(width: 8),
                    _PresetActionButton(
                      icon: Icons.delete_outline,
                      tooltip: preset.isBuiltin ? '默认预设不可删除' : '删除',
                      onPressed: onDelete,
                      enabled: !preset.isBuiltin,
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

  String _formatTime(DateTime time) {
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _PresetActionButton extends StatelessWidget {
  const _PresetActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Ink(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: IconButton(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon, size: 18),
        ),
      ),
    );
  }
}
