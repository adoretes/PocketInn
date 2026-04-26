import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mock_user_settings.dart';
import '../models/chat_session.dart';
import '../models/preset.dart';
import '../models/prompt_assembly.dart';
import '../models/world_book.dart';
import '../services/chat_character_resolver.dart';
import '../services/chat_database_service.dart';
import '../services/preset_service.dart';
import '../services/prompt_assembler.dart';
import '../services/world_book_service.dart';

class PromptPreviewPage extends StatefulWidget {
  const PromptPreviewPage({
    super.key,
    this.initialSessionId,
    this.initialInput = '',
  });

  final String? initialSessionId;
  final String initialInput;

  @override
  State<PromptPreviewPage> createState() => _PromptPreviewPageState();
}

class _PromptPreviewPageState extends State<PromptPreviewPage> {
  final TextEditingController _inputController = TextEditingController();

  late Future<_PreviewData> _previewDataFuture;
  String? _selectedSessionId;
  String? _selectedCharacterId;
  String? _selectedPresetId;
  String? _selectedUserSettingId;
  late Set<String> _selectedWorldBookIds;

  @override
  void initState() {
    super.initState();
    _selectedSessionId = widget.initialSessionId;
    _selectedWorldBookIds = <String>{};
    _inputController.text = widget.initialInput;
    _previewDataFuture = _loadPreviewData();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<_PreviewData> _loadPreviewData() async {
    final presetSummaries = await PresetService.instance.loadAllSummaries();
    final presets = <Preset>[];
    for (final summary in presetSummaries) {
      final preset = await PresetService.instance.loadById(summary.id);
      if (preset != null) {
        presets.add(preset);
      }
    }

    final characterOptions = await ChatCharacterResolver.instance.loadAllOptions();
    final worldBooks = await _loadWorldBooks();
    final userSettings = userSettingsNotifier.value;
    final sessionSummaries = await ChatDatabaseService.instance.loadSessionSummaries();
    final sessions = <_PreviewSession>[];
    for (final summary in sessionSummaries) {
      final bundle = await ChatDatabaseService.instance.loadSessionBundle(summary.id);
      if (bundle == null) {
        continue;
      }
      sessions.add(_PreviewSession(summary: summary, bundle: bundle));
    }

    final data = _PreviewData(
      characters: characterOptions,
      sessions: sessions,
      presets: presets,
      worldBooks: worldBooks,
      userSettings: userSettings,
    );
    _applyDefaultsFromSession(data);
    return data;
  }

  Future<List<WorldBook>> _loadWorldBooks() async {
    final books = await WorldBookService.instance.loadAll();
    books.sort((a, b) => a.name.compareTo(b.name));
    return books;
  }

  void _applyDefaultsFromSession(_PreviewData data) {
    if (data.sessions.isEmpty) {
      return;
    }
    final session = _resolveSession(data);
    _selectedSessionId = session.summary.id;
    _selectedCharacterId ??= session.bundle.session.characterId;
    _selectedUserSettingId ??= session.bundle.session.selectedUserSettingId;
    _selectedPresetId ??= session.bundle.session.selectedPresetId;
    if (_selectedWorldBookIds.isEmpty) {
      _selectedWorldBookIds = {...session.bundle.session.selectedWorldBookIds};
    }
  }

  void _applySessionSelections(_PreviewSession session) {
    _selectedSessionId = session.summary.id;
    _selectedCharacterId = session.bundle.session.characterId;
    _selectedUserSettingId = session.bundle.session.selectedUserSettingId;
    _selectedPresetId = session.bundle.session.selectedPresetId;
    _selectedWorldBookIds = {...session.bundle.session.selectedWorldBookIds};
  }

  PromptAssemblyResult _buildResult(_PreviewData data) {
    final character = _resolveCharacter(data);
    final preset = _resolvePreset(data);
    final userSetting = _resolveUserSetting(data);
    final session = _resolveSession(data);
    final selectedWorldBooks = data.worldBooks
        .where((item) => _selectedWorldBookIds.contains(item.id))
        .toList();

    return PromptAssembler.build(
      PromptAssemblyContext(
        characterName: character.name,
        characterCardData: character.cardJson,
        userName: userSetting.name,
        userSettingPrompt: userSetting.prompt,
        preset: preset,
        selectedWorldBooks: selectedWorldBooks,
        chatMessages: session.bundle.activeMessages,
        currentInput: _inputController.text,
      ),
    );
  }

  ResolvedChatCharacter _resolveCharacter(_PreviewData data) {
    final targetId = _selectedCharacterId ?? _resolveSession(data).bundle.session.characterId;
    for (final item in data.characters) {
      if (item.id == targetId) {
        return item;
      }
    }
    return data.characters.first;
  }

  _PreviewSession _resolveSession(_PreviewData data) {
    if (_selectedSessionId != null) {
      for (final item in data.sessions) {
        if (item.summary.id == _selectedSessionId) {
          return item;
        }
      }
    }
    return data.sessions.first;
  }

  Preset _resolvePreset(_PreviewData data) {
    final targetId = _selectedPresetId ?? _resolveSession(data).bundle.session.selectedPresetId;
    if (targetId != null) {
      for (final item in data.presets) {
        if (item.id == targetId) {
          return item;
        }
      }
    }
    return data.presets.first;
  }

  UserSetting _resolveUserSetting(_PreviewData data) {
    final targetId =
        _selectedUserSettingId ?? _resolveSession(data).bundle.session.selectedUserSettingId;
    if (targetId != null) {
      for (final item in data.userSettings) {
        if (item.id == targetId) {
          return item;
        }
      }
    }
    return data.userSettings.first;
  }

  void _refreshPreview() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt 预览'),
      ),
      body: FutureBuilder<_PreviewData>(
        future: _previewDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null ||
              data.characters.isEmpty ||
              data.sessions.isEmpty ||
              data.presets.isEmpty ||
              data.userSettings.isEmpty) {
            return const Center(child: Text('缺少可用于预览的数据'));
          }

          final result = _buildResult(data);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSelectors(data),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _inputController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '当前输入',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _refreshPreview(),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '最终 Message 列表',
                      child: Column(
                        children: [
                          for (final message in result.messages)
                            _MessagePreviewCard(message: message),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '已触发世界书条目',
                      child: result.activatedWorldBookEntries.isEmpty
                          ? const Text('无')
                          : Column(
                              children: [
                                for (final entry in result.activatedWorldBookEntries)
                                  ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text('${entry.bookName} / ${entry.entry.title}'),
                                    subtitle: Text(
                                      entry.triggeredByConstant ? 'constant' : '关键词触发',
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '保留未生效角色覆盖',
                      child: result.unusedCharacterOverrides.isEmpty
                          ? const Text('无')
                          : Column(
                              children: [
                                for (final item in result.unusedCharacterOverrides)
                                  ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(item.field),
                                    subtitle: Text('${item.reason}\n\n${item.content}'),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '合并文本预览',
                      trailing: IconButton(
                        icon: const Icon(Icons.copy_outlined),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: result.mergedText),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已复制合并文本')),
                          );
                        },
                      ),
                      child: SelectableText(result.mergedText),
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

  Widget _buildSelectors(_PreviewData data) {
    final selectedCharacter = _resolveCharacter(data);
    final selectedSession = _resolveSession(data);
    final selectedPreset = _resolvePreset(data);
    final selectedUser = _resolveUserSetting(data);
    return _SectionCard(
      title: '上下文选择',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedSession.summary.id,
            decoration: const InputDecoration(
              labelText: '聊天',
              border: OutlineInputBorder(),
            ),
            items: data.sessions
                .map(
                  (item) => DropdownMenuItem(
                    value: item.summary.id,
                    child: Text(item.summary.title),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              final nextSession = data.sessions.firstWhere(
                (item) => item.summary.id == value,
              );
              setState(() {
                _applySessionSelections(nextSession);
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedCharacter.id,
            decoration: const InputDecoration(
              labelText: '角色',
              border: OutlineInputBorder(),
            ),
            items: data.characters
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedCharacterId = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedUser.id,
            decoration: const InputDecoration(
              labelText: '用户设定',
              border: OutlineInputBorder(),
            ),
            items: data.userSettings
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedUserSettingId = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedPreset.id,
            decoration: const InputDecoration(
              labelText: '预设',
              border: OutlineInputBorder(),
            ),
            items: data.presets
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedPresetId = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '世界书',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final worldBook in data.worldBooks)
                FilterChip(
                  label: Text(worldBook.name),
                  selected: _selectedWorldBookIds.contains(worldBook.id),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedWorldBookIds.add(worldBook.id);
                      } else {
                        _selectedWorldBookIds.remove(worldBook.id);
                      }
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MessagePreviewCard extends StatelessWidget {
  const _MessagePreviewCard({
    required this.message,
  });

  final PromptMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(label: Text(message.role)),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final source in message.sources)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(source),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(message.content),
        ],
      ),
    );
  }
}

class _PreviewData {
  const _PreviewData({
    required this.characters,
    required this.sessions,
    required this.presets,
    required this.worldBooks,
    required this.userSettings,
  });

  final List<ResolvedChatCharacter> characters;
  final List<_PreviewSession> sessions;
  final List<Preset> presets;
  final List<WorldBook> worldBooks;
  final List<UserSetting> userSettings;
}

class _PreviewSession {
  const _PreviewSession({
    required this.summary,
    required this.bundle,
  });

  final ChatSessionSummary summary;
  final ChatSessionBundle bundle;
}
