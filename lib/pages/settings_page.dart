import 'package:flutter/material.dart';

import '../data/mock_user_settings.dart';
import 'about_page.dart';
import 'api_config_page.dart';
import 'char_list_page.dart';
import 'data_management_page.dart';
import 'general_settings_page.dart';
import 'preset_page.dart';
import 'user_settings_page.dart';
import 'world_book_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _openPage(BuildContext context, _SettingsItem item) async {
    final navigator = Navigator.of(context);

    switch (item.type) {
      case _SettingsItemType.general:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const GeneralSettingsPage()),
        );
      case _SettingsItemType.characters:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const CharListPage()),
        );
      case _SettingsItemType.userSettings:
        final result = await navigator.push<UserSettingsPageResult>(
          MaterialPageRoute(
            builder: (_) => UserSettingsPage(
              initialSettings: userSettingsNotifier.value,
              initialSelectedId: selectedUserSettingIdNotifier.value,
            ),
          ),
        );

        if (result != null) {
          updateUserSettings(
            settings: result.settings,
            selectedId: result.selectedId,
          );
        }
      case _SettingsItemType.worldBook:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const WorldBookPage()),
        );
      case _SettingsItemType.presets:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const PresetPage()),
        );
      case _SettingsItemType.api:
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => const OpenAICompatibleConfigPage(),
          ),
        );
      case _SettingsItemType.data:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const DataManagementPage()),
        );
      case _SettingsItemType.about:
        await navigator.push(
          MaterialPageRoute(builder: (_) => const AboutPage()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = <_SettingsItem>[
      const _SettingsItem(
        title: '通用设置',
        subtitle: '主题、通知与基础偏好',
        icon: Icons.tune_rounded,
        type: _SettingsItemType.general,
      ),
      const _SettingsItem(
        title: '角色列表',
        subtitle: '查看和管理当前角色',
        icon: Icons.people_alt_outlined,
        type: _SettingsItemType.characters,
      ),
      const _SettingsItem(
        title: '用户设定',
        subtitle: '管理你的身份与提示设定',
        icon: Icons.person_outline_rounded,
        type: _SettingsItemType.userSettings,
      ),
      const _SettingsItem(
        title: '世界书管理',
        subtitle: '管理世界书与知识条目',
        icon: Icons.menu_book_outlined,
        type: _SettingsItemType.worldBook,
      ),
      const _SettingsItem(
        title: '预设管理',
        subtitle: '管理聊天预设与参数组合',
        icon: Icons.tune_outlined,
        type: _SettingsItemType.presets,
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
      appBar: AppBar(
        title: const Text('设置'),
      ),
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
                child: Icon(
                  item.icon,
                  color: colorScheme.primary,
                ),
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
  characters,
  userSettings,
  worldBook,
  presets,
  api,
  data,
  about,
}
