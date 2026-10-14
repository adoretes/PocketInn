import 'package:flutter/foundation.dart';

import '../models/chat_session.dart';
import 'character_service.dart';
import 'chat_database_service.dart';

/// 左抽屉（会话列表）的数据快照。
class ChatSidebarData {
  const ChatSidebarData({required this.roles, required this.chats});

  /// 角色下拉筛选项，首项固定为“全部角色”（[ChatSidebarRole.id] 为 null）。
  final List<ChatSidebarRole> roles;

  /// 全部会话摘要（未按角色过滤，过滤由界面完成）。
  final List<ChatSidebarEntry> chats;
}

/// 左抽屉列表中的一条会话。
class ChatSidebarEntry {
  const ChatSidebarEntry({
    required this.summary,
    required this.roleName,
    required this.avatarText,
    required this.characterId,
    this.imagePath,
  });

  final ChatSessionSummary summary;
  final String roleName;
  final String avatarText;
  final String characterId;
  final String? imagePath;
}

/// 角色下拉筛选项。
class ChatSidebarRole {
  const ChatSidebarRole({
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

/// 左抽屉数据的内存缓存。
///
/// 抽屉挂在 `Scaffold.drawer` 上，而 Flutter 的 `DrawerController` 在抽屉关闭时会
/// 把内容整棵移出 widget 树，`ChatSidebarPage` 的 State 随之销毁。若把数据留在
/// State 里，每次打开抽屉都要重新查库、读角色索引文件，表现为“每次打开都转圈”。
/// 这里把快照提到 service 层跨抽屉开关复用：命中未过期快照即时渲染，仅在数据源
/// 变化且抽屉重新打开时才重读，且重读期间保留旧快照。
class ChatSidebarService {
  ChatSidebarService._() {
    ChatDatabaseService.instance.changeNotifier.addListener(
      _handleSourceChanged,
    );
  }

  static final ChatSidebarService instance = ChatSidebarService._();

  /// 当前数据快照；为 null 表示尚未取到任何数据（用于首次加载占位）。
  final ValueNotifier<ChatSidebarData?> dataNotifier =
      ValueNotifier<ChatSidebarData?>(null);

  /// 数据源（会话库或角色索引）在上次读取后是否已变化。
  bool _stale = true;
  Future<void>? _inFlight;

  void _handleSourceChanged() {
    // 只打过期标记，不立即重读：抽屉关闭时不做无用功。
    _stale = true;
  }

  /// 抽屉打开时调用：有未过期的快照就直接复用，否则重读。
  Future<void> ensureFresh() async {
    if (dataNotifier.value != null && !_stale) {
      return;
    }
    await refresh();
  }

  /// 重读数据源并刷新快照；旧快照保留到新数据就绪，避免闪进度圈。
  ///
  /// 并发调用会复用同一次读取。
  Future<void> refresh() async {
    final inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _reload();
    _inFlight = future;
    try {
      await future;
    } finally {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    }
  }

  Future<void> _reload() async {
    try {
      final data = await _load();
      dataNotifier.value = data;
      _stale = false;
    } catch (error, stackTrace) {
      // 失败时保留旧快照，标记过期以便下次再试。
      _stale = true;
      debugPrint('ChatSidebarService 加载失败: $error\n$stackTrace');
    }
  }

  Future<ChatSidebarData> _load() async {
    // 会话摘要一次 SQL 查询、角色摘要一次索引文件读取；之后按 id 在内存里补齐
    // 每个会话的角色信息，不再逐会话读取角色卡文件（旧实现“转圈”的主要耗时）。
    final summaries = await ChatDatabaseService.instance.loadSessionSummaries();
    final characters = await CharacterService.instance.loadAllSummaries();
    final characterById = {
      for (final character in characters) character.id: character,
    };

    final roleMap = <String, ChatSidebarRole>{};
    for (final character in characters) {
      final name = character.name.isNotEmpty ? character.name : '未命名角色';
      final thumbnail = character.thumbnailPath;
      roleMap[character.id] = ChatSidebarRole(
        id: character.id,
        name: name,
        avatarText: name.isNotEmpty ? name[0] : '?',
        imagePath: thumbnail.isNotEmpty ? thumbnail : null,
        isRealCharacter: true,
      );
    }

    final entries = <ChatSidebarEntry>[];
    for (final summary in summaries) {
      final character = characterById[summary.characterId];
      final roleName = character?.name ?? summary.characterId;
      final avatarText = roleName.isNotEmpty ? roleName[0] : '?';
      final thumbnail = character?.thumbnailPath;
      final imagePath = (thumbnail != null && thumbnail.isNotEmpty)
          ? thumbnail
          : null;
      entries.add(
        ChatSidebarEntry(
          summary: summary,
          roleName: roleName,
          avatarText: avatarText,
          characterId: summary.characterId,
          imagePath: imagePath,
        ),
      );
      roleMap.putIfAbsent(
        summary.characterId,
        () => ChatSidebarRole(
          id: summary.characterId,
          name: roleName,
          avatarText: avatarText,
          imagePath: imagePath,
          isRealCharacter: character != null,
        ),
      );
    }

    final roles = [
      const ChatSidebarRole(id: null, name: '全部角色', avatarText: '全'),
      ...roleMap.values.toList()..sort((a, b) => a.name.compareTo(b.name)),
    ];

    return ChatSidebarData(roles: roles, chats: entries);
  }
}
