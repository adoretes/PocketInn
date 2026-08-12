import 'package:flutter/material.dart';

import '../models/regex_rule_group.dart';
import '../services/regex_rule_group_service.dart';
import 'regex_rule_group_edit_page.dart';

class RegexRuleGroupPage extends StatefulWidget {
  const RegexRuleGroupPage({super.key});

  @override
  State<RegexRuleGroupPage> createState() => _RegexRuleGroupPageState();
}

class _RegexRuleGroupPageState extends State<RegexRuleGroupPage> {
  late Future<List<RegexRuleGroupSummary>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _groupsFuture = _loadGroups();
  }

  Future<List<RegexRuleGroupSummary>> _loadGroups() {
    return RegexRuleGroupService.instance.loadAllSummaries();
  }

  Future<void> _refresh() async {
    final future = _loadGroups();
    setState(() {
      _groupsFuture = future;
    });
    await future;
  }

  Future<void> _onCreate() async {
    final group = RegexRuleGroup(
      id: 'group-${DateTime.now().millisecondsSinceEpoch}',
      name: '新规则组',
      rules: [],
      updatedAt: DateTime.now(),
    );

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RegexRuleGroupEditPage(group: group, isNewGroup: true),
      ),
    );

    if (saved == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _onImport() async {
    try {
      final group = await RegexRuleGroupService.instance.importFromFile();
      if (group == null || !mounted) return;

      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已导入规则组：${group.name}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败：$e')));
    }
  }

  Future<void> _onGroupTap(RegexRuleGroupSummary summary) async {
    final group = await RegexRuleGroupService.instance.loadById(summary.id);
    if (group == null || !mounted) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RegexRuleGroupEditPage(group: group),
      ),
    );

    if (saved == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _onExport(RegexRuleGroupSummary summary) async {
    final group = await RegexRuleGroupService.instance.loadById(summary.id);
    if (group == null || !mounted) return;

    final path = await RegexRuleGroupService.instance.exportToFile(group);
    if (path == null || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('导出成功：$path')));
  }

  Future<void> _onDuplicate(RegexRuleGroupSummary summary) async {
    final group = await RegexRuleGroupService.instance.duplicate(summary.id);
    if (group == null || !mounted) return;

    await _refresh();
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已复制规则组：${group.name}')));
  }

  Future<void> _onDelete(RegexRuleGroupSummary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除规则组'),
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

    await RegexRuleGroupService.instance.delete(summary.id);
    await _refresh();
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已删除规则组：${summary.name}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('正则替换'),
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
      body: FutureBuilder<List<RegexRuleGroupSummary>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data ?? const <RegexRuleGroupSummary>[];
          if (groups.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('还没有规则组')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GroupCard(
                    group: group,
                    onTap: () => _onGroupTap(group),
                    onExport: () => _onExport(group),
                    onDuplicate: () => _onDuplicate(group),
                    onDelete: () => _onDelete(group),
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

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onTap,
    required this.onExport,
    required this.onDuplicate,
    required this.onDelete,
  });

  final RegexRuleGroupSummary group;
  final VoidCallback onTap;
  final VoidCallback onExport;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: colorScheme.brightness == Brightness.dark ? 0.18 : 0.05,
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
                    color: colorScheme.primary.withValues(
                      alpha: colorScheme.brightness == Brightness.dark
                          ? 0.22
                          : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.find_replace_outlined,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
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
                        '${group.ruleCount} 条规则'
                        '${group.enabledRuleCount > 0 ? '，启用 ${group.enabledRuleCount} 条' : ''}'
                        ' · ${_formatTime(group.updatedAt)}',
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
                    _GroupActionButton(
                      icon: Icons.file_upload_outlined,
                      tooltip: '导出',
                      onPressed: onExport,
                    ),
                    const SizedBox(width: 8),
                    _GroupActionButton(
                      icon: Icons.copy_outlined,
                      tooltip: '复制',
                      onPressed: onDuplicate,
                    ),
                    const SizedBox(width: 8),
                    _GroupActionButton(
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

  String _formatTime(DateTime time) {
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _GroupActionButton extends StatelessWidget {
  const _GroupActionButton({
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
        ),
      ),
    );
  }
}
