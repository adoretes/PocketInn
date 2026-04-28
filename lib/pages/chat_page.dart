import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../data/api_configs.dart';
import '../data/app_settings.dart';
import '../data/mock_user_settings.dart';
import '../models/api_config.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/preset.dart';
import '../models/world_book.dart';
import '../pages/api_request_log_page.dart';
import '../pages/api_config_page.dart';
import '../services/chat_character_resolver.dart';
import '../services/chat_database_service.dart';
import '../services/chat_service.dart';
import '../services/chat_variable_service.dart';
import '../services/openai_compatible_api_service.dart';
import '../services/preset_service.dart';
import '../services/world_book_service.dart';
import '../widgets/expanded_text_editor_field.dart';
import 'chat_sidebar_page.dart';
import 'world_book_edit_page.dart';

enum _MessageEditAction { save, saveAndSend }

/// 聊天页面
class ChatPage extends StatefulWidget {
  final String? sessionId;

  const ChatPage({super.key, this.sessionId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatSession? _activeSession;
  ResolvedChatCharacter? _activeCharacter;
  List<ChatMessage> _messages = [];
  List<WorldBook> _worldBooks = [];
  List<PresetSummary> _presets = [];

  String _inputText = '';
  final Set<String> _selectedWorldBookIds = {};
  String? _selectedPresetId;
  String? _selectedUserSettingId;
  bool _isLoading = true;
  bool _isSending = false;
  bool _useStreaming = true;
  bool _isCheckingApiStatus = false;
  String? _apiStatusConfigId;
  ApiConnectionTestResult? _apiStatusResult;
  ChatMessage? _pendingUserMessage;
  String? _regeneratingUserMessageId;
  String _streamingAssistantText = '';
  String _streamingThinkingChain = '';
  bool _scrollToBottomScheduled = false;

  @override
  void initState() {
    super.initState();
    apiConfigsNotifier.addListener(_handleApiConfigsChanged);
    ChatDatabaseService.instance.changeNotifier.addListener(
      _handleChatDatabaseChanged,
    );
    _textController.addListener(() {
      setState(() {
        _inputText = _textController.text;
      });
    });
    _initializePage();
    _refreshEnabledApiStatus();
  }

  Future<void> _initializePage() async {
    setState(() {
      _isLoading = true;
    });

    final books = await WorldBookService.instance.loadAll();
    final presets = await PresetService.instance.loadAllSummaries();

    if (!mounted) {
      return;
    }

    setState(() {
      _worldBooks = books;
      _presets = presets;
    });

    await _loadSession(preferredSessionId: widget.sessionId);
  }

  Future<void> _loadWorldBooks() async {
    final books = await WorldBookService.instance.loadAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _worldBooks = books;
    });
  }

  Future<void> _loadSession({String? preferredSessionId}) async {
    final summaries = await ChatDatabaseService.instance.loadSessionSummaries();
    if (!mounted) {
      return;
    }

    if (summaries.isEmpty) {
      setState(() {
        _activeSession = null;
        _activeCharacter = null;
        _messages = [];
        _selectedUserSettingId = null;
        _selectedPresetId = null;
        _selectedWorldBookIds.clear();
        _isLoading = false;
      });
      return;
    }

    final targetSummary = summaries.firstWhere(
      (item) => item.id == preferredSessionId,
      orElse: () => summaries.first,
    );
    final bundle = await ChatDatabaseService.instance.loadSessionBundle(
      targetSummary.id,
    );
    if (!mounted || bundle == null) {
      return;
    }

    final resolvedCharacter = await ChatCharacterResolver.instance.resolveById(
      bundle.session.characterId,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _activeSession = bundle.session;
      _activeCharacter = resolvedCharacter;
      _messages = bundle.activeMessages;
      _selectedUserSettingId = bundle.session.selectedUserSettingId;
      _selectedPresetId = bundle.session.selectedPresetId;
      _selectedWorldBookIds
        ..clear()
        ..addAll(bundle.session.selectedWorldBookIds);
      _isLoading = false;
    });
    _scheduleScrollToBottom();
  }

  Future<void> _persistSessionConfig() async {
    final session = _activeSession;
    if (session == null) {
      return;
    }

    await ChatDatabaseService.instance.updateSessionConfig(
      sessionId: session.id,
      selectedUserSettingId: _selectedUserSettingId,
      selectedWorldBookIds: _selectedWorldBookIds.toList(),
      selectedPresetId: _selectedPresetId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _activeSession = session.copyWith(
        selectedUserSettingId: _selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds.toList(),
        selectedPresetId: _selectedPresetId,
      );
    });
  }

  List<ChatMessage> get _visibleMessages {
    final items = List<ChatMessage>.from(_messages);
    final regeneratingUserMessageId = _regeneratingUserMessageId;
    if (regeneratingUserMessageId != null &&
        items.isNotEmpty &&
        !items.last.isMe &&
        items.last.parentId == regeneratingUserMessageId) {
      items.removeLast();
    }
    final pendingUserMessage = _pendingUserMessage;
    if (pendingUserMessage != null) {
      items.add(pendingUserMessage);
    }

    if (_isSending &&
        (_useStreaming ||
            _streamingAssistantText.isNotEmpty ||
            _streamingThinkingChain.isNotEmpty) &&
        _activeCharacter != null) {
      items.add(
        ChatMessage(
          text:
              _streamingAssistantText.isEmpty && _streamingThinkingChain.isEmpty
              ? '...'
              : _streamingAssistantText,
          isMe: false,
          thinkingChain: _streamingThinkingChain.isEmpty
              ? null
              : _streamingThinkingChain,
        ),
      );
    }
    return items;
  }

  void _resetPendingMessages() {
    _pendingUserMessage = null;
    _regeneratingUserMessageId = null;
    _streamingAssistantText = '';
    _streamingThinkingChain = '';
  }

  String _resolvedUserName() {
    final settings = userSettingsNotifier.value;
    if (settings.isEmpty) {
      return '默认用户';
    }
    final targetId = _selectedUserSettingId;
    if (targetId != null) {
      for (final item in settings) {
        if (item.id == targetId) {
          return item.name;
        }
      }
    }
    return settings.first.name;
  }

  String _replaceChatVariables(String input) {
    return ChatVariableService.replacePlaceholders(
      input,
      characterName: _activeCharacter?.name ?? '角色',
      userName: _resolvedUserName(),
    );
  }

  @override
  void dispose() {
    apiConfigsNotifier.removeListener(_handleApiConfigsChanged);
    ChatDatabaseService.instance.changeNotifier.removeListener(
      _handleChatDatabaseChanged,
    );
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollToBottom({bool animated = false}) {
    if (_scrollToBottomScheduled) {
      return;
    }
    _scrollToBottomScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottomScheduled = false;
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final targetOffset = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(targetOffset);
      }
    });
  }

  void _handleApiConfigsChanged() {
    _refreshEnabledApiStatus();
  }

  void _handleChatDatabaseChanged() {
    final sessionId = _activeSession?.id ?? widget.sessionId;
    if (sessionId == null || _isLoading || _isSending) {
      return;
    }
    _loadSession(preferredSessionId: sessionId);
  }

  void _onChatListPressed() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _refreshEnabledApiStatus() async {
    final config = enabledApiConfig;
    if (config == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCheckingApiStatus = false;
        _apiStatusConfigId = null;
        _apiStatusResult = null;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isCheckingApiStatus = true;
        _apiStatusConfigId = config.id;
      });
    }

    final result = await OpenAICompatibleApiService.instance.testConnection(
      config.copyWith(),
    );
    if (!mounted || enabledApiConfig?.id != config.id) {
      return;
    }

    setState(() {
      _isCheckingApiStatus = false;
      _apiStatusConfigId = config.id;
      _apiStatusResult = result;
    });
  }

  Future<void> _selectApiConfig(ApiConfig target) async {
    final nextConfigs = apiConfigsNotifier.value
        .map((item) => item.copyWith(enabled: item.id == target.id))
        .toList();
    await updateApiConfigs(nextConfigs);
  }

  Future<void> _openApiConfigPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OpenAICompatibleConfigPage()),
    );
    await _refreshEnabledApiStatus();
  }

  Future<void> _openApiRequestLogPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ApiRequestLogPage()));
  }

  Future<void> _showApiSelectorSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final screenHeight = MediaQuery.of(sheetContext).size.height;
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return SafeArea(
              child: ValueListenableBuilder<List<ApiConfig>>(
                valueListenable: apiConfigsNotifier,
                builder: (context, configs, _) {
                  final currentConfig = enabledApiConfig;
                  final settings = appSettingsNotifier.value;
                  return SizedBox(
                    height: screenHeight * 0.6,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'API 选择',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentConfig == null
                                ? '当前未启用 API 配置'
                                : '当前: ${currentConfig.name} · ${_apiStatusLabel(currentConfig)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('流式输出'),
                            subtitle: Text(
                              _useStreaming ? '实时显示回复内容' : '等待完整回复后再显示',
                            ),
                            value: _useStreaming,
                            onChanged: _isSending
                                ? null
                                : (value) {
                                    setState(() {
                                      _useStreaming = value;
                                    });
                                    sheetSetState(() {});
                                  },
                          ),
                          const SizedBox(height: 8),
                          if (configs.isEmpty)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.hub_outlined),
                              title: const Text('暂无 API 配置'),
                              subtitle: const Text('先添加配置后才能切换和检测状态'),
                              trailing: FilledButton.tonal(
                                onPressed: () async {
                                  Navigator.of(sheetContext).pop();
                                  await _openApiConfigPage();
                                },
                                child: const Text('去配置'),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView(
                                children: [
                                  for (final item in configs)
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        item.id == currentConfig?.id
                                            ? Icons.check_circle
                                            : Icons.hub_outlined,
                                        color: item.id == currentConfig?.id
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                      title: Text(
                                        item.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        item.model.trim().isEmpty
                                            ? item.baseUrl
                                            : '${item.model} · ${item.baseUrl}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: item.id == currentConfig?.id
                                          ? _buildApiStatusChip(
                                              colorScheme,
                                              item,
                                            )
                                          : null,
                                      onTap: () async {
                                        Navigator.of(sheetContext).pop();
                                        await _selectApiConfig(item);
                                      },
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 2,
                            runSpacing: 2,
                            children: [
                              TextButton.icon(
                                onPressed: currentConfig == null
                                    ? null
                                    : () async {
                                        Navigator.of(sheetContext).pop();
                                        await _refreshEnabledApiStatus();
                                      },
                                icon: const Icon(Icons.sync),
                                label: const Text('刷新状态'),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  Navigator.of(sheetContext).pop();
                                  await _openApiConfigPage();
                                },
                                icon: const Icon(Icons.settings_outlined),
                                label: const Text('管理配置'),
                              ),
                              if (settings.showApiRequestLogEntry)
                                TextButton.icon(
                                  onPressed: () async {
                                    Navigator.of(sheetContext).pop();
                                    await _openApiRequestLogPage();
                                  },
                                  icon: const Icon(Icons.receipt_long_outlined),
                                  label: const Text('请求日志'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _apiStatusLabel(ApiConfig config) {
    if (_isCheckingApiStatus && _apiStatusConfigId == config.id) {
      return '检查中';
    }
    if (_apiStatusConfigId != config.id || _apiStatusResult == null) {
      return '未检查';
    }
    if (_apiStatusResult!.success) {
      return _apiStatusResult!.isPartial ? '部分可用' : '在线';
    }
    return '异常';
  }

  Color _apiStatusColor(ColorScheme colorScheme, ApiConfig? config) {
    if (config == null) {
      return colorScheme.outline;
    }
    if (_isCheckingApiStatus && _apiStatusConfigId == config.id) {
      return colorScheme.primary;
    }
    if (_apiStatusConfigId != config.id || _apiStatusResult == null) {
      return colorScheme.outline;
    }
    return _apiStatusResult!.success
        ? (_apiStatusResult!.isPartial ? Colors.orange : Colors.green)
        : colorScheme.error;
  }

  IconData _apiStatusIcon(ApiConfig? config) {
    if (config == null) {
      return Icons.hub_outlined;
    }
    if (_isCheckingApiStatus && _apiStatusConfigId == config.id) {
      return Icons.sync;
    }
    if (_apiStatusConfigId != config.id || _apiStatusResult == null) {
      return Icons.help_outline;
    }
    return _apiStatusResult!.success
        ? (_apiStatusResult!.isPartial
              ? Icons.cloud_queue_outlined
              : Icons.cloud_done_outlined)
        : Icons.cloud_off_outlined;
  }

  Widget _buildApiStatusChip(ColorScheme colorScheme, ApiConfig config) {
    final statusColor = _apiStatusColor(colorScheme, config);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _apiStatusLabel(config),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildApiActionButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = enabledApiConfig;
    final statusColor = _apiStatusColor(colorScheme, config);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: _showApiSelectorSheet,
        tooltip: config == null
            ? 'API：未配置'
            : 'API：${config.name}（${_apiStatusLabel(config)}）',
        style: IconButton.styleFrom(
          foregroundColor: statusColor,
          visualDensity: VisualDensity.compact,
        ),
        icon: Icon(_apiStatusIcon(config), size: 20),
      ),
    );
  }

  Future<void> _renameChatTitle() async {
    final session = _activeSession;
    if (session == null) {
      return;
    }

    final controller = TextEditingController(text: session.title);
    final nextTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改聊天名称'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '输入聊天名称'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    final normalizedTitle = nextTitle?.trim();
    if (normalizedTitle == null ||
        normalizedTitle.isEmpty ||
        normalizedTitle == session.title) {
      return;
    }

    await ChatDatabaseService.instance.updateSessionTitle(
      sessionId: session.id,
      title: normalizedTitle,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _activeSession = session.copyWith(title: normalizedTitle);
    });
  }

  void _onUserSettingsPressed(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);
    final Size size = button.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy,
      ),
      items: userSettingsNotifier.value.map((setting) {
        final isSelected = setting.id == _selectedUserSettingId;
        return PopupMenuItem<String>(
          value: setting.id,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: setting.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  setting.avatarText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(setting.name, overflow: TextOverflow.ellipsis),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check, size: 18, color: setting.color),
              ],
            ],
          ),
        );
      }).toList(),
    ).then((value) async {
      if (value != null) {
        setState(() {
          _selectedUserSettingId = value;
        });
        await _persistSessionConfig();
      }
    });
  }

  void _onWorldBookPressed(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);
    final Size size = button.size;
    final colorScheme = Theme.of(context).colorScheme;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy,
      ),
      items: _worldBooks.map((worldBook) {
        final isSelected = _selectedWorldBookIds.contains(worldBook.id);
        return PopupMenuItem<String>(
          value: worldBook.id,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedWorldBookIds.remove(worldBook.id);
              } else {
                _selectedWorldBookIds.add(worldBook.id);
              }
            });
            Future<void>.microtask(_persistSessionConfig);
          },
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(worldBook.name, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _onWorldBookEditPressed(worldBook.id);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _onWorldBookEditPressed(String worldBookId) async {
    final worldBook = await WorldBookService.instance.loadById(worldBookId);
    if (worldBook == null) return;
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorldBookEditPage(worldBook: worldBook),
      ),
    );

    await _loadWorldBooks();
  }

  void _onPresetPressed(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);
    final Size size = button.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy,
      ),
      items: _presets.map((preset) {
        final isSelected = preset.id == _selectedPresetId;
        return PopupMenuItem<String>(
          value: preset.id,
          child: Row(
            children: [
              Expanded(
                child: Text(preset.name, overflow: TextOverflow.ellipsis),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check, size: 18, color: Colors.blue),
              ],
            ],
          ),
        );
      }).toList(),
    ).then((value) async {
      if (value != null) {
        setState(() {
          _selectedPresetId = value;
        });
        await _persistSessionConfig();
      }
    });
  }

  Future<void> _onSendPressed() async {
    final session = _activeSession;
    final character = _activeCharacter;
    final text = _replaceChatVariables(_inputText.trim()).trim();
    if (text.isEmpty || session == null || character == null || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
      _pendingUserMessage = ChatMessage(text: text, isMe: true);
      _streamingAssistantText = '';
      _streamingThinkingChain = '';
    });
    _scheduleScrollToBottom(animated: true);

    _textController.clear();

    try {
      await ChatService.instance.sendMessage(
        session: session,
        character: character,
        chatMessages: _messages,
        input: text,
        selectedPresetId: _selectedPresetId,
        selectedUserSettingId: _selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds,
        useStreaming: _useStreaming,
        onStreamProgress: (progress) {
          if (!mounted) {
            return;
          }
          setState(() {
            if (progress.textDelta.isNotEmpty) {
              _streamingAssistantText += progress.textDelta;
            }
            if (progress.thinkingDelta.isNotEmpty) {
              _streamingThinkingChain += progress.thinkingDelta;
            }
          });
          _scheduleScrollToBottom();
        },
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      _resetPendingMessages();
      await _loadSession(preferredSessionId: session.id);
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
      _scheduleScrollToBottom();
    }
  }

  // 消息操作方法
  void _onCopyMessage(ChatMessage msg) {
    Clipboard.setData(ClipboardData(text: msg.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _onEditMessage(int index) async {
    final session = _activeSession;
    final character = _activeCharacter;
    final message = index >= 0 && index < _messages.length
        ? _messages[index]
        : null;
    if (session == null || message?.id == null || _isSending) {
      return;
    }

    final controller = TextEditingController(text: message!.text);
    final action = await showDialog<_MessageEditAction>(
      context: context,
      builder: (context) {
        final actionButtons = <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_MessageEditAction.save),
            child: const Text('保存'),
          ),
          if (message.isMe && character != null)
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_MessageEditAction.saveAndSend),
              child: const Text('保存并发送'),
            ),
        ];

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  message.isMe ? '编辑用户消息' : '编辑角色消息',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ExpandedTextEditorField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 10,
                  minLines: 3,
                  dialogTitle: message.isMe ? '编辑用户消息' : '编辑角色消息',
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '输入消息内容',
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < actionButtons.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actionButtons[i],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    var normalizedText = controller.text.trim();
    controller.dispose();

    if (action == null) {
      return;
    }
    if (normalizedText.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('消息不能为空')));
      return;
    }

    if (message.isMe) {
      normalizedText = _replaceChatVariables(normalizedText).trim();
    }

    try {
      if (message.isMe) {
        final editedNode = await ChatDatabaseService.instance
            .branchMessageFromEdit(
              sessionId: session.id,
              messageId: message.id!,
              text: normalizedText,
            );

        if (action == _MessageEditAction.saveAndSend) {
          await _regenerateFromUserMessage(
            userMessageIndex: index,
            userMessageOverride: ChatMessage(
              id: editedNode.id,
              sessionId: editedNode.sessionId,
              parentId: editedNode.parentId,
              text: editedNode.text,
              isMe: true,
            ),
            historyBeforeOverride: _messages
                .take(index)
                .toList(growable: false),
          );
          return;
        }

        await _loadSession(preferredSessionId: session.id);
        return;
      }

      await ChatDatabaseService.instance.updateMessage(
        sessionId: session.id,
        messageId: message.id!,
        text: normalizedText,
        thinkingChain: message.thinkingChain,
        clearThinkingChain: message.thinkingChain == null,
      );

      if (action == _MessageEditAction.saveAndSend) {
        await _regenerateFromUserMessage(
          userMessageIndex: index,
          editedText: normalizedText,
        );
        return;
      }

      await _loadSession(preferredSessionId: session.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _onDeleteMessage(int index) async {
    final session = _activeSession;
    final message = index >= 0 && index < _messages.length
        ? _messages[index]
        : null;
    if (session == null || message?.id == null || _isSending) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除消息'),
          content: Text(message!.isMe ? '确定删除这条用户消息吗？' : '确定删除这条角色消息吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    await ChatDatabaseService.instance.deleteMessageBranch(
      sessionId: session.id,
      messageId: message!.id!,
    );
    await _loadSession(preferredSessionId: session.id);
  }

  Future<void> _onRegenerateMessage(int assistantMessageIndex) async {
    if (_isSending) {
      return;
    }
    final session = _activeSession;
    final character = _activeCharacter;
    if (session == null || character == null) {
      return;
    }
    if (assistantMessageIndex <= 0 ||
        assistantMessageIndex >= _messages.length) {
      return;
    }

    final userMessage = _messages[assistantMessageIndex - 1];
    if (!userMessage.isMe || userMessage.id == null) {
      return;
    }

    await _regenerateFromUserMessage(
      userMessageIndex: assistantMessageIndex - 1,
    );
  }

  Future<void> _regenerateFromUserMessage({
    required int userMessageIndex,
    String? editedText,
    ChatMessage? userMessageOverride,
    List<ChatMessage>? historyBeforeOverride,
  }) async {
    final session = _activeSession;
    final character = _activeCharacter;
    if (session == null || character == null || _isSending) {
      return;
    }
    if (userMessageIndex < 0 || userMessageIndex >= _messages.length) {
      return;
    }

    final originalUserMessage =
        userMessageOverride ?? _messages[userMessageIndex];
    if (!originalUserMessage.isMe || originalUserMessage.id == null) {
      return;
    }

    final userMessage = ChatMessage(
      id: originalUserMessage.id,
      sessionId: originalUserMessage.sessionId,
      parentId: originalUserMessage.parentId,
      text: editedText ?? originalUserMessage.text,
      isMe: true,
      index: originalUserMessage.index,
      total: originalUserMessage.total,
      siblingIds: originalUserMessage.siblingIds,
    );
    final historyBeforeUserMessage =
        historyBeforeOverride ??
        _messages.take(userMessageIndex).toList(growable: false);

    setState(() {
      _isSending = true;
      _pendingUserMessage = null;
      _regeneratingUserMessageId = userMessage.id;
      _streamingAssistantText = '';
      _streamingThinkingChain = '';
    });
    _scheduleScrollToBottom(animated: true);

    try {
      await ChatService.instance.regenerateAssistantResponse(
        session: session,
        character: character,
        historyBeforeUserMessage: historyBeforeUserMessage,
        userMessage: userMessage,
        selectedPresetId: _selectedPresetId,
        selectedUserSettingId: _selectedUserSettingId,
        selectedWorldBookIds: _selectedWorldBookIds,
        useStreaming: _useStreaming,
        onStreamProgress: (progress) {
          if (!mounted) {
            return;
          }
          setState(() {
            if (progress.textDelta.isNotEmpty) {
              _streamingAssistantText += progress.textDelta;
            }
            if (progress.thinkingDelta.isNotEmpty) {
              _streamingThinkingChain += progress.thinkingDelta;
            }
          });
          _scheduleScrollToBottom();
        },
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      _resetPendingMessages();
      await _loadSession(preferredSessionId: session.id);
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
      _scheduleScrollToBottom();
    }
  }

  Future<void> _onSwitchMessageVariant(ChatMessage message, int delta) async {
    final session = _activeSession;
    if (session == null || message.id == null || message.siblingIds.isEmpty) {
      return;
    }

    final currentIndex = message.index - 1;
    final nextIndex = currentIndex + delta;
    if (nextIndex < 0 || nextIndex >= message.siblingIds.length) {
      return;
    }

    await ChatDatabaseService.instance.switchActiveBranch(
      sessionId: session.id,
      parentMessageId: message.parentId,
      childMessageId: message.siblingIds[nextIndex],
    );
    await _loadSession(preferredSessionId: session.id);
  }

  @override
  Widget build(BuildContext context) {
    final visibleMessages = _visibleMessages;
    final isSendEnabled =
        !_isSending && _inputText.trim().isNotEmpty && _activeSession != null;
    final session = _activeSession;
    final character = _activeCharacter;
    final drawerEdgeDragWidth = (MediaQuery.sizeOf(context).width * 0.18).clamp(
      72.0,
      120.0,
    );

    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawer: const Drawer(child: SafeArea(child: ChatSidebarPage())),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.format_list_bulleted),
          onPressed: _onChatListPressed,
          tooltip: '聊天列表',
        ),
        title: InkWell(
          onTap: session == null ? null : _renameChatTitle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    session?.title ?? '聊天',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [_buildApiActionButton(context)],
      ),
      body: ValueListenableBuilder<AppSettings>(
        valueListenable: appSettingsNotifier,
        builder: (context, settings, _) {
          final backgroundPath = character?.imagePath ?? '';
          final hasBackground = backgroundPath.isNotEmpty;
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (session == null) {
            return const Center(child: Text('暂无聊天记录'));
          }
          return Stack(
            children: [
              if (hasBackground)
                Positioned.fill(
                  child: character?.isAssetImage == true
                      ? Image.asset(
                          backgroundPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        )
                      : Image.file(
                          File(backgroundPath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                ),
              if (hasBackground)
                Positioned.fill(
                  child: Container(
                    color: Theme.of(context).colorScheme.surface.withValues(
                      alpha: settings.backgroundOpacity,
                    ),
                  ),
                ),
              Column(
                children: [
                  Expanded(
                    child: visibleMessages.isEmpty
                        ? const Center(child: Text('这段聊天还没有消息'))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: visibleMessages.length,
                            itemBuilder: (context, index) {
                              final msg = visibleMessages[index];
                              final isLastMessage =
                                  index == visibleMessages.length - 1;
                              final isLastUserMessageWithoutReply =
                                  isLastMessage && msg.isMe;
                              final isLastCharacterMessage =
                                  isLastMessage && !msg.isMe;
                              final isRegeneratingUserMessage =
                                  _regeneratingUserMessageId != null &&
                                  msg.id == _regeneratingUserMessageId;
                              final showActions =
                                  msg.id != null &&
                                  (!_isSending || isRegeneratingUserMessage);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _MessageBubble(
                                  message: msg,
                                  userSetting: _currentUserSetting(),
                                  character: _activeCharacter,
                                  isLastUserMessageWithoutReply:
                                      isLastUserMessageWithoutReply,
                                  isLastCharacterMessage:
                                      isLastCharacterMessage,
                                  showActions: showActions,
                                  isBusyRegenerating: isRegeneratingUserMessage,
                                  onCopy: () => _onCopyMessage(msg),
                                  onEdit: () => _onEditMessage(index),
                                  onDelete: () => _onDeleteMessage(index),
                                  onGenerate:
                                      isLastUserMessageWithoutReply &&
                                          showActions &&
                                          !isRegeneratingUserMessage
                                      ? () => _regenerateFromUserMessage(
                                          userMessageIndex: index,
                                        )
                                      : null,
                                  onRegenerate:
                                      isLastCharacterMessage && showActions
                                      ? () => _onRegenerateMessage(index)
                                      : null,
                                  onSelectPreviousVariant: msg.hasMultiple
                                      ? () => _onSwitchMessageVariant(msg, -1)
                                      : null,
                                  onSelectNextVariant: msg.hasMultiple
                                      ? () => _onSwitchMessageVariant(msg, 1)
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                  _buildInputArea(isSendEnabled, settings, hasBackground),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputArea(
    bool isSendEnabled,
    AppSettings settings,
    bool hasBackground,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasWorldBooks = _worldBooks.isNotEmpty;
    // 获取所有选中的世界书
    final selectedWorldBooks = _worldBooks
        .where((item) => _selectedWorldBookIds.contains(item.id))
        .toList();
    // 显示文本：多个世界书时显示数量，单个时显示名称
    final worldBookDisplayText = selectedWorldBooks.isEmpty
        ? '世界书'
        : selectedWorldBooks.length == 1
        ? selectedWorldBooks.first.name
        : '${selectedWorldBooks.length} 本世界书';
    final worldBookColor = selectedWorldBooks.isNotEmpty
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    // 是否启用毛玻璃效果（有背景且设置开启）
    final useGlassEffect = hasBackground && settings.inputGlassEffect;

    // 输入框内容
    Widget inputContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: TextField(
            controller: _textController,
            maxLines: 5,
            minLines: 1,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: '输入消息',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 12, 8),
          child: Row(
            children: [
              Builder(
                builder: (context) => ValueListenableBuilder<List<UserSetting>>(
                  valueListenable: userSettingsNotifier,
                  builder: (context, settings, _) {
                    if (settings.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final selectedSetting = settings.firstWhere(
                      (item) => item.id == _selectedUserSettingId,
                      orElse: () => settings.first,
                    );

                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 148),
                      child: TextButton.icon(
                        onPressed: () => _onUserSettingsPressed(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: const Size(40, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: selectedSetting.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selectedSetting.avatarText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        label: Text(
                          selectedSetting.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Builder(
                builder: (context) => ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 148),
                  child: TextButton.icon(
                    onPressed: hasWorldBooks
                        ? () => _onWorldBookPressed(context)
                        : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: const Size(40, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      Icons.menu_book_rounded,
                      size: 20,
                      color: worldBookColor,
                    ),
                    label: Text(
                      worldBookDisplayText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.tune, size: 24),
                  onPressed: () => _onPresetPressed(context),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  tooltip: '预设',
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: isSendEnabled ? _onSendPressed : null,
                color: _isSending || isSendEnabled
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                icon: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isSendEnabled
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : const Icon(Icons.send, size: 24),
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                tooltip: _isSending ? '发送中' : '发送',
              ),
            ],
          ),
        ),
      ],
    );

    // 毛玻璃效果容器
    if (useGlassEffect) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: colorScheme.surface.withValues(alpha: 0.4),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: inputContent,
            ),
          ),
        ),
      );
    }

    // 普通容器
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: inputContent,
    );
  }

  UserSetting? _currentUserSetting() {
    final settings = userSettingsNotifier.value;
    if (settings.isEmpty) {
      return null;
    }
    final selectedId = _selectedUserSettingId;
    if (selectedId != null) {
      for (final item in settings) {
        if (item.id == selectedId) {
          return item;
        }
      }
    }
    return settings.first;
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.userSetting,
    required this.character,
    required this.isLastUserMessageWithoutReply,
    required this.isLastCharacterMessage,
    required this.showActions,
    required this.isBusyRegenerating,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    this.onGenerate,
    this.onRegenerate,
    this.onSelectPreviousVariant,
    this.onSelectNextVariant,
  });

  final ChatMessage message;
  final UserSetting? userSetting;
  final ResolvedChatCharacter? character;
  final bool isLastUserMessageWithoutReply;
  final bool isLastCharacterMessage;
  final bool showActions;
  final bool isBusyRegenerating;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onGenerate;
  final VoidCallback? onRegenerate;
  final VoidCallback? onSelectPreviousVariant;
  final VoidCallback? onSelectNextVariant;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final colorScheme = Theme.of(context).colorScheme;
    final markdownText = _formatMessageForMarkdown(message.text);

    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, _) {
        final showAvatar = settings.showAvatar;

        if (isMe) {
          // 用户消息：保持原有气泡样式
          return _buildUserBubble(
            context,
            colorScheme,
            showAvatar,
            markdownText,
          );
        } else {
          // 角色消息：全宽无背景
          return _buildCharacterBubble(
            context,
            colorScheme,
            showAvatar,
            markdownText,
          );
        }
      },
    );
  }

  /// 构建用户消息气泡
  Widget _buildUserBubble(
    BuildContext context,
    ColorScheme colorScheme,
    bool showAvatar,
    String markdownText,
  ) {
    final bubbleColor = colorScheme.primaryContainer;
    final textColor = colorScheme.onPrimaryContainer;
    final inlineCodeColor = colorScheme.primary.withValues(alpha: 0.12);
    final codeBlockColor = colorScheme.primary.withValues(alpha: 0.08);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Semantics(
                  container: true,
                  child: MarkdownBody(
                    data: markdownText,
                    styleSheet: _buildMarkdownStyleSheet(
                      textColor: textColor,
                      emphasisColor: colorScheme.primary,
                      inlineCodeColor: inlineCodeColor,
                      codeBlockColor: codeBlockColor,
                    ),
                    selectable: true,
                  ),
                ),
              ),
              if (showActions) _buildActionButtons(context, colorScheme),
            ],
          ),
        ),
        if (showAvatar) ...[
          const SizedBox(width: 8),
          _buildUserAvatar(colorScheme),
        ],
      ],
    );
  }

  /// 构建角色消息气泡（全宽无背景）
  Widget _buildCharacterBubble(
    BuildContext context,
    ColorScheme colorScheme,
    bool showAvatar,
    String markdownText,
  ) {
    final textColor = colorScheme.onSurface;
    final inlineCodeColor = colorScheme.surfaceContainerHigh;
    final codeBlockColor = colorScheme.surfaceContainerLow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatar) ...[
              _buildCharacterAvatar(colorScheme),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 思考链（如果有）
                  if (message.hasThinkingChain)
                    _buildThinkingChain(context, colorScheme),
                  // 消息内容
                  Semantics(
                    container: true,
                    child: MarkdownBody(
                      data: markdownText,
                      styleSheet: _buildMarkdownStyleSheet(
                        textColor: textColor,
                        emphasisColor: colorScheme.primary,
                        inlineCodeColor: inlineCodeColor,
                        codeBlockColor: codeBlockColor,
                      ),
                      selectable: true,
                    ),
                  ),
                  // 操作按钮行（包含索引按钮在右下角）
                  _buildActionButtons(context, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet({
    required Color textColor,
    required Color emphasisColor,
    required Color inlineCodeColor,
    required Color codeBlockColor,
  }) {
    const baseTextStyle = TextStyle(fontSize: 15, height: 1.5);

    return MarkdownStyleSheet(
      p: baseTextStyle.copyWith(color: textColor),
      em: baseTextStyle.copyWith(
        color: emphasisColor,
        fontStyle: FontStyle.normal,
      ),
      strong: baseTextStyle.copyWith(
        color: emphasisColor.withValues(alpha: 0.68),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      del: baseTextStyle.copyWith(
        // 添加这一项
        color: textColor,
        decoration: TextDecoration.none,
      ),
      code: TextStyle(
        fontSize: 14,
        color: textColor,
        backgroundColor: inlineCodeColor,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBlockColor,
        borderRadius: BorderRadius.circular(8),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: textColor.withValues(alpha: 0.25), width: 0.3),
        ),
      ),
    );
  }

  /// 构建折叠的思考链
  Widget _buildThinkingChain(BuildContext context, ColorScheme colorScheme) {
    return _ThinkingChainWidget(
      thinkingChain: message.thinkingChain!,
      colorScheme: colorScheme,
    );
  }

  /// 构建用户头像
  Widget _buildUserAvatar(ColorScheme colorScheme) {
    final currentUser = userSetting;
    if (currentUser != null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: currentUser.color,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          currentUser.avatarText.isEmpty ? '我' : currentUser.avatarText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.person, size: 20, color: colorScheme.onPrimary),
    );
  }

  /// 构建角色头像
  Widget _buildCharacterAvatar(ColorScheme colorScheme) {
    final imagePath = character?.thumbnailPath ?? character?.imagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      final imageProvider = imagePath.startsWith('assets/')
          ? AssetImage(imagePath) as ImageProvider
          : FileImage(File(imagePath));
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image(
            image: imageProvider,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.smart_toy_outlined,
                size: 20,
                color: colorScheme.onSecondaryContainer,
              );
            },
          ),
        ),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.smart_toy_outlined,
        size: 20,
        color: colorScheme.onSecondaryContainer,
      ),
    );
  }

  String _formatMessageForMarkdown(String input) {
    if (input.isEmpty) {
      return input;
    }

    final protectedPattern = RegExp(r'```[\s\S]*?```|`[^`\n]+`', dotAll: true);
    final buffer = StringBuffer();
    var cursor = 0;

    for (final match in protectedPattern.allMatches(input)) {
      if (match.start > cursor) {
        buffer.write(
          _emphasizeBracketSegments(input.substring(cursor, match.start)),
        );
      }
      buffer.write(match.group(0));
      cursor = match.end;
    }

    if (cursor < input.length) {
      buffer.write(_emphasizeBracketSegments(input.substring(cursor)));
    }

    return buffer.toString();
  }

  String _emphasizeBracketSegments(String input) {
    final pattern = RegExp(r'[（(][^()（）\n]+[)）]');
    return input.replaceAllMapped(pattern, (match) {
      final segment = match.group(0)!;
      final content = segment.substring(1, segment.length - 1).trim();
      final start = match.start;
      final end = match.end;
      final previous = start > 0 ? input[start - 1] : '';
      final next = end < input.length ? input[end] : '';
      if (content.isEmpty || previous == '*' || next == '*') {
        return segment;
      }
      return '**$content**';
    });
  }

  /// 构建操作按钮行
  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    if (!showActions) {
      return const SizedBox.shrink();
    }

    final actionWidgets = <Widget>[
      _buildActionButton(
        icon: Icons.copy_outlined,
        tooltip: '复制',
        onPressed: onCopy,
        colorScheme: colorScheme,
      ),
      _buildActionButton(
        icon: Icons.edit_outlined,
        tooltip: '编辑',
        onPressed: onEdit,
        colorScheme: colorScheme,
      ),
      _buildActionButton(
        icon: Icons.delete_outline,
        tooltip: '删除',
        onPressed: onDelete,
        colorScheme: colorScheme,
      ),
      if (isLastUserMessageWithoutReply && onGenerate != null)
        _buildActionButton(
          icon: isBusyRegenerating ? Icons.hourglass_top : Icons.auto_awesome,
          tooltip: isBusyRegenerating ? '生成中' : '生成回复',
          onPressed: onGenerate!,
          colorScheme: colorScheme,
        ),
      if (isLastCharacterMessage && onRegenerate != null)
        _buildActionButton(
          icon: Icons.refresh,
          tooltip: '重新生成',
          onPressed: onRegenerate!,
          colorScheme: colorScheme,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          if (message.isMe) const Spacer(),
          ...actionWidgets,
          if (!message.isMe) const Spacer(),
          if (message.hasMultiple) _buildIndexSelector(colorScheme),
        ],
      ),
    );
  }

  /// 构建消息索引选择器 < 1/x >
  Widget _buildIndexSelector(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSmallActionButton(
          icon: Icons.chevron_left,
          tooltip: '上一条',
          onPressed: message.index > 1 ? onSelectPreviousVariant : null,
          colorScheme: colorScheme,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${message.index}/${message.total}',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildSmallActionButton(
          icon: Icons.chevron_right,
          tooltip: '下一条',
          onPressed: message.index < message.total ? onSelectNextVariant : null,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  /// 构建小型操作按钮（用于索引选择器）
  Widget _buildSmallActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required ColorScheme colorScheme,
  }) {
    return IconButton(
      icon: Icon(icon, size: 16),
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      style: IconButton.styleFrom(
        foregroundColor: onPressed != null
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  /// 构建单个操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// 思考链组件 - 文字加展开符样式，无底板
class _ThinkingChainWidget extends StatefulWidget {
  const _ThinkingChainWidget({
    required this.thinkingChain,
    required this.colorScheme,
  });

  final String thinkingChain;
  final ColorScheme colorScheme;

  @override
  State<_ThinkingChainWidget> createState() => _ThinkingChainWidgetState();
}

class _ThinkingChainWidgetState extends State<_ThinkingChainWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.colorScheme.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '思考过程',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: widget.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 6),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: SizedBox(
                    width: 10,
                    child: Column(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: accentColor.withValues(alpha: 0.7),
                          ),
                        ),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.thinkingChain,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
