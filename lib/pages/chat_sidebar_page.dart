import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../data/mock_user_settings.dart';
import '../models/character_card.dart';
import '../models/chat_session.dart';
import '../services/chat_database_service.dart';
import '../services/chat_sidebar_service.dart';
import '../services/character_service.dart';
import '../widgets/role_avatar.dart';
import 'char_edit_page.dart';
import 'char_list_page.dart';
import 'chat/widgets/role_filter_menu.dart';
import 'chat_page.dart';
import 'settings_page.dart';
import 'user_settings_page.dart';

class ChatSidebarPage extends StatefulWidget {
  const ChatSidebarPage({super.key, this.activeSessionId, this.onChatSelected});

  final String? activeSessionId;
  final ValueChanged<ChatSessionSummary>? onChatSelected;

  @override
  State<ChatSidebarPage> createState() => _ChatSidebarPageState();
}

class _ChatSidebarPageState extends State<ChatSidebarPage> {
  String? _selectedCharacterId;

  ChatSidebarService get _sidebarService => ChatSidebarService.instance;

  @override
  void initState() {
    super.initState();
    // 抽屉每次打开都会重建本 State（Flutter 关闭抽屉时会把内容移出 widget 树），
    // 因此数据快照缓存在 ChatSidebarService：命中快照即可即时渲染，不再每次转圈。
    _sidebarService.ensureFresh();
    // 抽屉打开期间数据变化即时刷新；关闭后由 service 的过期标记负责，避免白跑。
    ChatDatabaseService.instance.changeNotifier.addListener(
      _handleDatabaseChanged,
    );
  }

  @override
  void dispose() {
    ChatDatabaseService.instance.changeNotifier.removeListener(
      _handleDatabaseChanged,
    );
    super.dispose();
  }

  void _handleDatabaseChanged() {
    if (!mounted) {
      return;
    }
    _sidebarService.refresh();
  }

  Future<void> _onSettingsTap() async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await navigator.push(
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  Future<void> _onUserSettingsTap() async {
    final navigator = Navigator.of(context);
    navigator.pop();

    final result = await navigator.push<UserSettingsPageResult>(
      MaterialPageRoute(
        builder: (context) => UserSettingsPage(
          initialSettings: userSettingsNotifier.value,
          initialSelectedId: selectedUserSettingIdNotifier.value,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    await updateUserSettings(
      settings: result.settings,
      selectedId: result.selectedId,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onChatItemTap(ChatSessionSummary item) async {
    final navigator = Navigator.of(context);
    navigator.pop();

    final onChatSelected = widget.onChatSelected;
    if (onChatSelected != null) {
      onChatSelected(item);
      return;
    }

    await navigator.pushReplacement(
      MaterialPageRoute(builder: (context) => ChatPage(sessionId: item.id)),
    );
  }

  Future<void> _onDeleteChat(ChatSessionSummary item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除聊天'),
          content: Text('确定删除 ${item.title} 吗？'),
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

    if (confirmed != true) {
      return;
    }

    await ChatDatabaseService.instance.deleteSession(item.id);
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已删除聊天：${item.title}')));
  }

  Future<void> _openCharacterEditor(String characterId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _CharacterEditorLoader(characterId: characterId),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _onChatAvatarTap(String characterId) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await navigator.push(
      MaterialPageRoute(
        builder: (context) => _CharacterEditorLoader(characterId: characterId),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _onAvatarTap(ChatSidebarRole selectedRole) async {
    final navigator = Navigator.of(context);
    navigator.pop();

    if (selectedRole.id == null) {
      await navigator.push(
        MaterialPageRoute(builder: (context) => const CharListPage()),
      );
      return;
    }

    if (!selectedRole.isRealCharacter) {
      await navigator.push(
        MaterialPageRoute(builder: (context) => const CharListPage()),
      );
      return;
    }

    await _openCharacterEditor(selectedRole.id!);
  }

  Future<void> _showRoleMenu(
    BuildContext anchorContext,
    List<ChatSidebarRole> roles,
  ) async {
    if (roles.isEmpty) {
      return;
    }

    final selected = await showRoleFilterMenu(
      anchorContext: anchorContext,
      roles: roles,
      selectedId: _selectedCharacterId,
    );

    if (!mounted || selected == null) {
      return;
    }
    setState(() {
      _selectedCharacterId = selected.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<ChatSidebarData?>(
        valueListenable: _sidebarService.dataNotifier,
        builder: (context, data, _) {
          if (data == null) {
            // 只有首次打开、快照还没取到时才短暂出现。
            return const Center(child: CircularProgressIndicator());
          }

          final selectedRole = data.roles.firstWhere(
            (role) => role.id == _selectedCharacterId,
            orElse: () => data.roles.first,
          );
          final filteredChats = _selectedCharacterId == null
              ? data.chats
              : data.chats
                    .where(
                      (item) =>
                          item.summary.characterId == _selectedCharacterId,
                    )
                    .toList();

          return Column(
            children: [
              ValueListenableBuilder<List<UserSetting>>(
                valueListenable: userSettingsNotifier,
                builder: (context, settings, _) {
                  if (settings.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return ValueListenableBuilder<String?>(
                    valueListenable: selectedUserSettingIdNotifier,
                    builder: (context, selectedId, _) {
                      final selectedUserSetting = settings.firstWhere(
                        (item) => item.id == selectedId,
                        orElse: () => settings.first,
                      );

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: InkWell(
                          onTap: _onUserSettingsTap,
                          borderRadius: BorderRadius.circular(18),
                          child: Ink(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selectedUserSetting.color.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: selectedUserSetting.color,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    selectedUserSetting.avatarText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedUserSetting.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selectedUserSetting.prompt,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              Expanded(
                child: filteredChats.isEmpty
                    ? Center(
                        child: Text(
                          '暂无聊天记录',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final item = filteredChats[index];
                          final isActive =
                              item.summary.id == widget.activeSessionId;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Slidable(
                                key: ValueKey(item.summary.id),
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  extentRatio: 0.18,
                                  children: [
                                    CustomSlidableAction(
                                      onPressed: (_) =>
                                          _onDeleteChat(item.summary),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onError,
                                      child: const Center(
                                        child: Icon(Icons.delete_outline),
                                      ),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: isActive
                                      ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(alpha: 0.55)
                                      : Colors.transparent,
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    selected: isActive,
                                    leading: GestureDetector(
                                      onTap: () => _onChatAvatarTap(item.characterId),
                                      child: RoleAvatar(
                                        imagePath: item.imagePath,
                                        fallbackText: item.avatarText,
                                        radius: 20,
                                      ),
                                    ),
                                    title: Text(item.summary.title),
                                    subtitle: Text(
                                      item.summary.lastMessagePreview.isNotEmpty
                                          ? item.summary.lastMessagePreview
                                          : '暂无消息',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(
                                      _formatTime(item.summary.updatedAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    onTap: () => _onChatItemTap(item.summary),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (anchorContext) => _RoleFilterTrigger(
                          role: selectedRole,
                          onTap: () =>
                              _showRoleMenu(anchorContext, data.roles),
                          onAvatarTap: () => _onAvatarTap(selectedRole),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.people_alt_outlined),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CharListPage(),
                          ),
                        );
                      },
                      tooltip: '角色列表',
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: _onSettingsTap,
                      tooltip: '设置',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(time.year, time.month, time.day);
    final difference = today.difference(targetDay).inDays;

    if (difference == 0) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    if (difference == 1) {
      return '昨天';
    }
    if (difference < 7) {
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[time.weekday - 1];
    }
    return '${time.month}/${time.day}';
  }
}

/// 抽屉底部的角色筛选触发卡片，视觉与设置页的「颜色模式 / 预设主题」一致。
class _RoleFilterTrigger extends StatelessWidget {
  const _RoleFilterTrigger({
    required this.role,
    required this.onTap,
    required this.onAvatarTap,
  });

  final ChatSidebarRole role;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      // 与抽屉上方的卡片一致：用底色区分层次，不描边。
      color: colorScheme.primaryContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
          child: Row(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: RoleAvatar(
                  imagePath: role.imagePath,
                  fallbackText: role.avatarText,
                  radius: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  role.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterEditorLoader extends StatelessWidget {
  const _CharacterEditorLoader({required this.characterId});

  final String characterId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CharacterCardRecord?>(
      future: CharacterService.instance.loadById(characterId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final record = snapshot.data;
        if (record == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('角色不存在或加载失败')),
          );
        }

        return RoleEditPage(
          characterData: record.cardJson,
          imagePath: record.originalImagePath,
          initialWorldBookId: record.worldBookId,
          onSave: (payload) => CharacterService.instance.updateCard(
            id: record.id,
            cardJson: payload.cardJson,
            imageSourcePath: payload.imageSourcePath,
            removeImage: payload.removeImage,
            selectedWorldBookId: payload.selectedWorldBookId,
          ),
        );
      },
    );
  }
}
