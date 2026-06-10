import 'package:flutter/material.dart';

import '../data/mock_user_settings.dart';
import 'char_list_page.dart';
import 'preset_page.dart';
import 'user_settings_page.dart';
import 'world_book_page.dart';

class CharacterContentPage extends StatelessWidget {
  const CharacterContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('角色与设定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EntryCard(
            title: '角色列表',
            subtitle: '查看和管理当前角色',
            icon: Icons.people_alt_outlined,
            colorScheme: colorScheme,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CharListPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _EntryCard(
            title: '用户设定',
            subtitle: '管理你的身份与提示设定',
            icon: Icons.person_outline_rounded,
            colorScheme: colorScheme,
            onTap: () async {
              final result = await Navigator.of(context).push<UserSettingsPageResult>(
                MaterialPageRoute(
                  builder: (_) => UserSettingsPage(
                    initialSettings: userSettingsNotifier.value,
                    initialSelectedId: selectedUserSettingIdNotifier.value,
                  ),
                ),
              );
              if (result != null && context.mounted) {
                updateUserSettings(
                  settings: result.settings,
                  selectedId: result.selectedId,
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _EntryCard(
            title: '世界书管理',
            subtitle: '管理世界书与知识条目',
            icon: Icons.menu_book_outlined,
            colorScheme: colorScheme,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorldBookPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _EntryCard(
            title: '预设管理',
            subtitle: '管理聊天预设与参数组合',
            icon: Icons.tune_outlined,
            colorScheme: colorScheme,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PresetPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorScheme,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
