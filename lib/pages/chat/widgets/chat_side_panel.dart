import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/chat_variables.dart';
import '../../../services/chat_database_service.dart';
import '../../../services/variable_state_service.dart';
import 'chat_variable_list.dart';

/// 聊天页侧边栏：长期记忆入口 + 状态变量实时显示。
///
/// 由 [ChatPage] 挂在 `Scaffold.endDrawer` 上，只负责取数与刷新；
/// 具体呈现交给 [ChatSidePanelContent]，便于单独做 widget 测试。
///
/// 抽屉关闭时不查库：状态变量求值要沿消息链回溯，抽屉在 Scaffold 里
/// 即使收起也会构建，没这个开关就会在每条消息落库时白跑一遍。
class ChatSidePanel extends StatefulWidget {
  const ChatSidePanel({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
    required this.isDraftSession,
    required this.leafMessageId,
    required this.isOpened,
    required this.draftState,
    required this.onOpenMemoryManager,
    required this.onOpenVariablePage,
  });

  /// 当前会话 id；null 表示没有可用会话。
  final String? sessionId;
  final String? sessionTitle;

  /// 草稿会话：会话尚未落库，只展示角色卡声明的初始变量。
  final bool isDraftSession;

  /// 当前分支叶子消息 id（消息列表最后一条），用于求值到该时刻的状态。
  final String? leafMessageId;

  /// 侧边栏是否已展开（来自 `Scaffold.onEndDrawerChanged`）。
  final bool isOpened;

  /// 草稿会话下角色卡声明的初始变量（正式开始时才会写入会话）。
  final VariableState draftState;

  /// 打开长期记忆整页。
  final VoidCallback onOpenMemoryManager;

  /// 打开状态变量整页（初始变量声明说明、提取配置、宏用法）。
  final VoidCallback onOpenVariablePage;

  @override
  State<ChatSidePanel> createState() => _ChatSidePanelState();
}

class _ChatSidePanelState extends State<ChatSidePanel> {
  VariableState? _initState;
  VariableState? _leafState;
  int _memoryCount = 0;
  bool _isLoading = false;
  String? _errorText;
  int _loadGeneration = 0;

  /// 已成功加载数据的会话 / 分支叶子；与此不符时重查前先清空显示。
  String? _loadedSessionId;
  String? _loadedLeafMessageId;

  /// 是否有数据可显示（true 时刷新不显示加载态，避免闪一下）。
  bool get _hasLoadedData => _initState != null || _leafState != null;

  /// 显示的数据是否已不属于当前会话 / 分支。
  bool get _isStaleContext =>
      _loadedSessionId != widget.sessionId ||
      _loadedLeafMessageId != widget.leafMessageId;

  @override
  void initState() {
    super.initState();
    // 变量写入不广播 ChatDatabaseService 变化（那会触发会话重载），
    // 状态提取又可能在消息落库后才写入差量；记忆写入则只广播 DB 变化。
    // 两个信号都监听，才能保证这里的显示始终是最新值。
    ChatDatabaseService.instance.changeNotifier.addListener(
      _handleDataChanged,
    );
    VariableStateService.instance.changeNotifier.addListener(
      _handleDataChanged,
    );
    if (widget.isOpened) {
      unawaited(_reload());
    }
  }

  @override
  void dispose() {
    ChatDatabaseService.instance.changeNotifier.removeListener(
      _handleDataChanged,
    );
    VariableStateService.instance.changeNotifier.removeListener(
      _handleDataChanged,
    );
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatSidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只在会话 / 分支叶子 / 草稿态真正变化时重查，避免流式输出期间反复查库。
    final contextChanged =
        oldWidget.sessionId != widget.sessionId ||
        oldWidget.leafMessageId != widget.leafMessageId ||
        oldWidget.isDraftSession != widget.isDraftSession;
    if (widget.isOpened) {
      if (contextChanged || !oldWidget.isOpened) {
        unawaited(_reload());
      }
    }
  }

  void _handleDataChanged() {
    // 抽屉收起时不查库：下次展开（isOpened 变化）会重新求值。
    if (widget.isOpened) {
      unawaited(_reload());
    }
  }

  Future<void> _reload() async {
    final sessionId = widget.sessionId;
    if (sessionId == null || widget.isDraftSession) {
      // 草稿会话没有落库记录，直接展示角色卡声明的初始变量。
      _loadGeneration++;
      setState(() {
        _initState = null;
        _leafState = null;
        _memoryCount = 0;
        _loadedSessionId = null;
        _loadedLeafMessageId = null;
        _isLoading = false;
        _errorText = null;
      });
      return;
    }

    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _errorText = null;
      // 会话 / 分支变了：先清掉旧值，避免短暂显示串台数据。
      if (_isStaleContext) {
        _initState = null;
        _leafState = null;
        _memoryCount = 0;
      }
    });

    try {
      final service = VariableStateService.instance;
      final init = await service.loadInitState(sessionId);
      final leaf = await service.resolveState(
        sessionId: sessionId,
        messageId: widget.leafMessageId,
      );
      final memories = await ChatDatabaseService.instance
          .loadAllSessionMemories(sessionId);
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _initState = init;
        _leafState = leaf;
        _memoryCount = memories.length;
        _loadedSessionId = sessionId;
        _loadedLeafMessageId = widget.leafMessageId;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorText = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatSidePanelContent(
      sessionTitle: widget.sessionTitle,
      hasSession: widget.sessionId != null,
      isDraftSession: widget.isDraftSession,
      // 已经有数据时静默刷新（新回复、提取写入），只在首次加载显示加载态。
      isLoading: _isLoading && !_hasLoadedData,
      errorText: _errorText,
      currentState: _leafState ?? VariableState.empty(),
      initDeclared: _initState?.isEmpty == false,
      draftState: widget.draftState,
      memoryCount: _memoryCount,
      onRefresh: _reload,
      onOpenMemoryManager: widget.onOpenMemoryManager,
      onOpenVariablePage: widget.onOpenVariablePage,
    );
  }
}

/// 侧边栏的纯展示层：所有数据已就绪，只做排版与状态文案。
class ChatSidePanelContent extends StatelessWidget {
  const ChatSidePanelContent({
    super.key,
    required this.sessionTitle,
    required this.hasSession,
    required this.isDraftSession,
    required this.isLoading,
    required this.errorText,
    required this.currentState,
    required this.initDeclared,
    required this.draftState,
    required this.memoryCount,
    required this.onRefresh,
    required this.onOpenMemoryManager,
    required this.onOpenVariablePage,
  });

  final String? sessionTitle;
  final bool hasSession;
  final bool isDraftSession;
  final bool isLoading;
  final String? errorText;

  /// 当前分支叶子时刻的状态变量。
  final VariableState currentState;

  /// 会话是否已写入角色卡声明的初始变量（决定空状态文案）。
  final bool initDeclared;
  final VariableState draftState;
  final int memoryCount;

  final Future<void> Function() onRefresh;
  final VoidCallback onOpenMemoryManager;
  final VoidCallback onOpenVariablePage;

  /// 记忆/变量都是会话级内容，草稿会话尚未落库，相关入口统一禁用。
  bool get _sessionContentAvailable => hasSession && !isDraftSession;

  String get _memorySubtitle {
    if (!hasSession) {
      return '暂无会话';
    }
    if (isDraftSession) {
      return '正式开始聊天后可用';
    }
    return memoryCount > 0 ? '$memoryCount 条记忆' : '暂无记忆';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = sessionTitle?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '记忆与状态',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: '刷新',
                icon: const Icon(Icons.refresh),
                onPressed: _sessionContentAvailable ? onRefresh : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: Icon(Icons.auto_awesome, color: colorScheme.primary),
              title: const Text('长期记忆'),
              subtitle: Text(_memorySubtitle),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: _sessionContentAvailable ? onOpenMemoryManager : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Row(
                children: [
                  Icon(Icons.insights_outlined, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '状态变量',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '完整页 / 提取配置',
                    icon: const Icon(Icons.open_in_new),
                    onPressed: _sessionContentAvailable
                        ? onOpenVariablePage
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._buildVariableBody(context, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildVariableBody(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    if (isLoading && !isDraftSession) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ];
    }

    final error = errorText;
    if (error != null) {
      return [
        Text(
          '状态加载失败：$error',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
          ),
        ),
      ];
    }

    if (!hasSession) {
      return [
        _hint(context, '暂无会话：选择或新建一个聊天后显示状态变量。'),
      ];
    }

    if (isDraftSession) {
      return [
        _hint(context, '草稿会话：以下为角色卡声明的初始变量，正式开始聊天后生效。'),
        const SizedBox(height: 4),
        ChatVariableList(
          state: draftState,
          emptyHint: '角色卡未声明初始状态变量，状态系统未启用。',
        ),
      ];
    }

    return [
      ChatVariableList(
        state: currentState,
        emptyHint: initDeclared
            ? '暂无变量（初始变量尚未发生任何变化）。'
            : '角色卡未声明初始状态变量，状态系统未启用。'
                  '请在角色卡编辑页的「初始状态变量」中声明。',
      ),
    ];
  }

  Widget _hint(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
