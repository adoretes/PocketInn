import 'package:flutter/material.dart';

import '../../../data/mock_user_settings.dart';
import '../../../data/preset_selection.dart';
import '../../../models/character_card.dart';
import '../../../services/character_service.dart';
import '../../../services/chat_opening_message_builder.dart';
import '../../../widgets/role_avatar.dart';
import '../../chat_page.dart';

/// 「新建聊天」的共享流程：选角色 → 构建草稿会话 → 进入聊天页。
///
/// 聊天页（AppBar）与左侧边栏（用户设定入口旁）都从这里进入，
/// 与角色管理页里「新建聊天」按钮构建出的草稿保持一致。

/// 读取角色卡，为指定角色构建一个草稿聊天页。
///
/// 与角色管理页原「新建聊天」逻辑一致：按当前用户设定生成开场白，
/// 并带出角色绑定的世界书与角色卡正则规则组。
/// 角色不存在或读取失败时返回 null。
Future<ChatPage?> buildNewChatDraftPage(CharacterSummary summary) async {
  final record = await CharacterService.instance.loadById(summary.id);
  if (record == null) {
    return null;
  }

  final openingMessages = ChatOpeningMessageBuilder.build(
    characterCardData: record.cardJson,
    characterName: summary.name,
    userName: _selectedUserName(),
  );
  final worldBookIds = record.worldBookId != null
      ? <String>[record.worldBookId!]
      : const <String>[];
  final regexSync = await CharacterService.instance.syncCardRegexRules(record);
  final regexRuleGroupIds = regexSync.group == null
      ? const <String>[]
      : <String>[regexSync.group!.id];

  return ChatPage.draft(
    characterId: summary.id,
    title: summary.name,
    selectedUserSettingId: selectedUserSettingIdNotifier.value,
    selectedPresetId: selectedPresetIdNotifier.value,
    selectedWorldBookIds: worldBookIds,
    selectedRegexRuleGroupIds: regexRuleGroupIds,
    openingAssistantMessages: openingMessages,
  );
}

/// 当前选中的用户名（未选中时回退到列表首项）。
String _selectedUserName() {
  final settings = userSettingsNotifier.value;
  if (settings.isEmpty) {
    return '默认用户';
  }
  final targetId = selectedUserSettingIdNotifier.value;
  if (targetId != null) {
    for (final item in settings) {
      if (item.id == targetId) {
        return item.name;
      }
    }
  }
  return settings.first.name;
}

/// 弹出角色选择面板，返回用户选中的角色；无角色或取消时返回 null。
Future<CharacterSummary?> pickCharacterForNewChat(BuildContext context) async {
  List<CharacterSummary> characters;
  try {
    characters = await CharacterService.instance.loadAllSummaries();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('读取角色失败：$error')));
    }
    return null;
  }
  if (!context.mounted) {
    return null;
  }
  if (characters.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('还没有角色，请先在角色列表中导入角色卡')));
    return null;
  }

  final theme = Theme.of(context);
  final maxHeight = MediaQuery.sizeOf(context).height * 0.6;
  return showModalBottomSheet<CharacterSummary>(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  '新建聊天',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    final avatarText = character.name.isNotEmpty
                        ? character.name[0]
                        : '?';
                    final description = character.description.trim();
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: RoleAvatar(
                        imagePath: character.thumbnailPath.isEmpty
                            ? null
                            : character.thumbnailPath,
                        fallbackText: avatarText,
                        radius: 20,
                      ),
                      title: Text(
                        character.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: description.isEmpty
                          ? null
                          : Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      onTap: () => Navigator.of(sheetContext).pop(character),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 弹出角色选择，选定后以草稿会话进入聊天页。
///
/// 以替换当前页的方式切换，避免聊天页反复叠加。
Future<void> startNewChatFlow(BuildContext context) async {
  final summary = await pickCharacterForNewChat(context);
  if (summary == null || !context.mounted) {
    return;
  }

  final page = await buildNewChatDraftPage(summary);
  if (page == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('角色不存在或加载失败')));
    }
    return;
  }
  if (!context.mounted) {
    return;
  }

  await Navigator.of(
    context,
  ).pushReplacement<void, void>(MaterialPageRoute<void>(builder: (_) => page));
}
