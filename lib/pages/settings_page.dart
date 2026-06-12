import 'package:flutter/material.dart';

import 'about_page.dart';
import 'api_config_page.dart';
import 'character_content_page.dart';
import 'companion_tools_page.dart';
import 'data_management_page.dart';
import 'general_settings_page.dart';
import 'memory_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _openPage(BuildContext context, _SettingsItem item) async {
    final navigator = Navigator.of(context);
    switch (item.type) {
      case _SettingsItemType.general:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const GeneralSettingsPage()),
        );
      case _SettingsItemType.characterContent:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const CharacterContentPage()),
        );
      case _SettingsItemType.memory:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const MemorySettingsPage()),
        );
      case _SettingsItemType.api:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const OpenAICompatibleConfigPage()),
        );
      case _SettingsItemType.data:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const DataManagementPage()),
        );
      case _SettingsItemType.about:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const AboutPage()),
        );
      case _SettingsItemType.companionTools:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const CompanionToolsPage()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = <_SettingsItem>[
      const _SettingsItem(
        title: '通用设置',
        subtitle: '颜色模式、主题与基础偏好',
        icon: Icons.tune_rounded,
        type: _SettingsItemType.general,
      ),
      const _SettingsItem(
        title: '角色与设定',
        subtitle: '角色、用户设定、世界书、预设',
        icon: Icons.people_alt_outlined,
        type: _SettingsItemType.characterContent,
      ),
      const _SettingsItem(
        title: '长期记忆',
        subtitle: '配置记忆提取参数与管理记忆',
        icon: Icons.psychology_outlined,
        type: _SettingsItemType.memory,
      ),
      const _SettingsItem(
        title: '配套工具',
        subtitle: 'Prompt 版本管理、角色卡生成器等',
        icon: Icons.extension_outlined,
        type: _SettingsItemType.companionTools,
      ),
      const _SettingsItem(
        title: 'API 配置',
        subtitle: '配置模型服务与接口参数',
        icon: Icons.hub_outlined,
        type: _SettingsItemType.api,
      ),
      const _SettingsItem(
        title: '数据管理',
        subtitle: '备份、恢复与清除本地数据',
        icon: Icons.storage_rounded,
        type: _SettingsItemType.data,
      ),
      const _SettingsItem(
        title: '关于',
        subtitle: '版本信息与应用说明',
        icon: Icons.info_outline_rounded,
        type: _SettingsItemType.about,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
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
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _openPage(context, item),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final _SettingsItemType type;
}

enum _SettingsItemType {
  general,
  companionTools,
  characterContent,
  memory,
  api,
  data,
  about,
}