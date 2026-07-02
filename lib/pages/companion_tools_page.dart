import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/error_handler.dart';

class CompanionToolsPage extends StatelessWidget {
  const CompanionToolsPage({super.key});

  Future<void> _openTool(BuildContext context, _ToolItem item) async {
    var launched = false;
    try {
      launched = await launchUrl(Uri.parse(item.url), mode: item.launchMode);
    } on Object catch (error) {
      debugPrint('companion_tools_page: launchUrl failed: $error');
      launched = false;
    }
    if (!launched && context.mounted) {
      handleAppException(
        context,
        toAppException(
          StateError('launchUrl returned false'),
          fallbackMessage: '无法打开 ${item.title}',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = <_ToolItem>[
      const _ToolItem(
        title: 'Prompt 版本管理',
        subtitle: 'PromptVault - 版本控制与 Arena 盲测对比',
        icon: Icons.account_tree_outlined,
        url: 'http://127.0.0.1:7432',
        launchMode: LaunchMode.platformDefault,
      ),
      const _ToolItem(
        title: '角色卡生成器',
        subtitle: 'CarFrog - 在线生成与编辑角色卡',
        icon: Icons.badge_outlined,
        url: 'https://adoretes.github.io/CarFrog/',
        launchMode: LaunchMode.externalApplication,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('配套工具')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, color: colorScheme.primary),
              ),
              title: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(item.subtitle),
              ),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => _openTool(context, item),
            ),
          );
        },
      ),
    );
  }
}

class _ToolItem {
  const _ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.url,
    required this.launchMode,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final String url;
  final LaunchMode launchMode;
}
