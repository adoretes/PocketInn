import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../data/mock_user_settings.dart';
import '../models/character_card.dart';
import '../models/chat_session.dart';
import '../services/chat_character_resolver.dart';
import '../services/chat_database_service.dart';
import '../services/character_service.dart';
import 'char_edit_page.dart';
import 'char_list_page.dart';
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
  late Future<_SidebarData> _sidebarDataFuture;
  _SidebarData? _lastSidebarData;

  @override
  void initState() {
    super.initState();
    _sidebarDataFuture = _loadSidebarData();
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
    setState(() {
      _sidebarDataFuture = _loadSidebarData();
    });
  }

  Future<_SidebarData> _loadSidebarData() async {
    final summaries = await ChatDatabaseService.instance.loadSessionSummaries();
    final entries = <_ChatListEntry>[];
    final roleMap = <String, _RoleFilter>{};

    final realCharacters = await CharacterService.instance.loadAllSummaries();
    for (final character in realCharacters) {
      final name = character.name.isNotEmpty ? character.name : '未命名角色';
      roleMap[character.id] = _RoleFilter(
        id: character.id,
        name: name,
        avatarText: name.isNotEmpty ? name[0] : '?',
        imagePath: character.thumbnailPath,
        isRealCharacter: true,
      );
    }

    for (final summary in summaries) {
      final character = await ChatCharacterResolver.instance.resolveById(
        summary.characterId,
      );
      final roleName = character?.name ?? summary.characterId;
      final avatarText = roleName.isNotEmpty ? roleName[0] : '?';
      entries.add(
        _ChatListEntry(
          summary: summary,
          roleName: roleName,
          avatarText: avatarText,
          imagePath: character?.thumbnailPath ?? character?.imagePath,
        ),
      );
      roleMap.putIfAbsent(
        summary.characterId,
        () => _RoleFilter(
          id: summary.characterId,
          name: roleName,
          avatarText: avatarText,
          imagePath: character?.thumbnailPath ?? character?.imagePath,
          isRealCharacter: character?.sourceLabel == '真实角色',
        ),
      );
    }

    final roles = [
      const _RoleFilter(id: null, name: '全部角色', avatarText: '全'),
      ...roleMap.values.toList()..sort((a, b) => a.name.compareTo(b.name)),
    ];

    return _SidebarData(roles: roles, chats: entries);
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

  Future<void> _onAvatarTap(_RoleFilter selectedRole) async {
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
    BuildContext targetContext,
    List<_RoleFilter> roles,
  ) async {
    final RenderBox button = targetContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(targetContext).context.findRenderObject() as RenderBox;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<_RoleFilter>(
      context: targetContext,
      position: position,
      items: roles
          .map(
            (role) =>
                PopupMenuItem<_RoleFilter>(value: role, child: Text(role.name)),
          )
          .toList(),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedCharacterId = selected.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_SidebarData>(
        future: _sidebarDataFuture,
        builder: (context, snapshot) {
          final loadedData = snapshot.data;
          if (loadedData != null) {
            _lastSidebarData = loadedData;
          }

          if (snapshot.connectionState != ConnectionState.done &&
              _lastSidebarData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
              loadedData ??
              _lastSidebarData ??
              const _SidebarData(
                roles: [_RoleFilter(id: null, name: '全部角色', avatarText: '全')],
                chats: [],
              );

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
              const Divider(height: 1),
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
                                    leading: _RoleAvatar(
                                      imagePath: item.imagePath,
                                      fallbackText: item.avatarText,
                                      radius: 20,
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
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _onAvatarTap(selectedRole),
                      child: _RoleAvatar(
                        imagePath: selectedRole.imagePath,
                        fallbackText: selectedRole.avatarText,
                        radius: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Builder(
                        builder: (menuContext) => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showRoleMenu(menuContext, data.roles),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  selectedRole.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _SidebarData {
  const _SidebarData({required this.roles, required this.chats});

  final List<_RoleFilter> roles;
  final List<_ChatListEntry> chats;
}

class _ChatListEntry {
  const _ChatListEntry({
    required this.summary,
    required this.roleName,
    required this.avatarText,
    this.imagePath,
  });

  final ChatSessionSummary summary;
  final String roleName;
  final String avatarText;
  final String? imagePath;
}

class _RoleFilter {
  const _RoleFilter({
    required this.id,
    required this.name,
    required this.avatarText,
    this.imagePath,
    this.isRealCharacter = false,
  });

  final String? id;
  final String name;
  final String avatarText;
  final String? imagePath;
  final bool isRealCharacter;
}

class _RoleAvatar extends StatelessWidget {
  const _RoleAvatar({
    required this.fallbackText,
    required this.radius,
    this.imagePath,
  });

  final String fallbackText;
  final double radius;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null || path.isEmpty) {
      return CircleAvatar(radius: radius, child: Text(fallbackText));
    }

    final imageProvider = path.startsWith('assets/')
        ? AssetImage(path) as ImageProvider
        : FileImage(File(path));

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: Image(
          image: imageProvider,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Text(fallbackText));
          },
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
