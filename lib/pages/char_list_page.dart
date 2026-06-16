import 'dart:io';

import 'package:flutter/material.dart';

import '../data/mock_user_settings.dart';
import '../data/preset_selection.dart';
import '../models/character_card.dart';
import '../services/chat_opening_message_builder.dart';
import '../services/character_service.dart';
import 'chat_page.dart';
import 'char_edit_page.dart';

class CharListPage extends StatefulWidget {
  const CharListPage({super.key});

  @override
  State<CharListPage> createState() => _CharListPageState();
}

class _CharListPageState extends State<CharListPage> {
  late Future<List<CharacterSummary>> _charactersFuture;

  @override
  void initState() {
    super.initState();
    _charactersFuture = _loadCharacters();
  }

  Future<List<CharacterSummary>> _loadCharacters() {
    return CharacterService.instance.loadAllSummaries();
  }

  Future<void> _refresh() async {
    final future = _loadCharacters();
    setState(() {
      _charactersFuture = future;
    });
    await future;
  }

  Future<void> _onImport() async {
    try {
      final result = await CharacterService.instance.importFromFile(
        onSameNameConflict: _chooseSameNameImportAction,
      );
      if (result == null || !mounted) return;
      await _refresh();
      if (!mounted) return;
      final message = result.merged
          ? '已合并到已有角色：${result.record.name}'
          : '已导入角色：${result.record.name}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败：$e')));
    }
  }

  Future<CharacterImportConflictChoice> _chooseSameNameImportAction(
    String importedName,
    CharacterSummary existing,
  ) async {
    if (!mounted) {
      return CharacterImportConflictChoice.cancel;
    }

    final choice = await showDialog<CharacterImportConflictChoice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('发现同名角色'),
          content: Text(
            '已存在角色「${existing.name}」。是否将「$importedName」合并到已有角色？'
            '\n\n选择合并会更新已有角色，并保留它的聊天记录。',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, CharacterImportConflictChoice.cancel),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                CharacterImportConflictChoice.createNew,
              ),
              child: const Text('新建副本'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, CharacterImportConflictChoice.merge),
              child: const Text('合并'),
            ),
          ],
        );
      },
    );

    return choice ?? CharacterImportConflictChoice.cancel;
  }

  Future<void> _onCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RoleEditPage(
          characterData: CharacterService.instance.buildEmptyCard(),
          closeAfterSave: true,
          initialWorldBookId: null,
          onSave: (payload) async {
            await CharacterService.instance.createFromCard(
              cardJson: payload.cardJson,
              imageSourcePath: payload.imageSourcePath,
              selectedWorldBookId: payload.selectedWorldBookId,
            );
          },
        ),
      ),
    );

    if (created == true) {
      await _refresh();
    }
  }

  Future<void> _onExport(CharacterSummary summary) async {
    final record = await CharacterService.instance.loadById(summary.id);
    if (record == null || !mounted) return;

    final format = await showModalBottomSheet<_ExportFormat>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.data_object_outlined),
                title: const Text('导出为 JSON'),
                onTap: () => Navigator.pop(context, _ExportFormat.json),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('导出为 PNG'),
                onTap: () => Navigator.pop(context, _ExportFormat.png),
              ),
            ],
          ),
        );
      },
    );

    if (format == null || !mounted) return;

    final outputPath = switch (format) {
      _ExportFormat.json => await CharacterService.instance.exportToJsonFile(
        record,
      ),
      _ExportFormat.png => await CharacterService.instance.exportToPngFile(
        record,
      ),
    };

    if (outputPath == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('导出成功：$outputPath')));
  }

  Future<void> _onDelete(CharacterSummary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除角色'),
          content: Text('确定删除 ${summary.name} 吗？'),
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

    if (confirmed != true) return;

    await CharacterService.instance.delete(summary.id);
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已删除角色：${summary.name}')));
  }

  Future<void> _openEditor(String characterId) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => _CharacterEditorLoader(characterId: characterId),
      ),
    );
  }

  Future<void> _onCreateChat(CharacterSummary summary) async {
    final record = await CharacterService.instance.loadById(summary.id);
    if (record == null) {
      return;
    }
    final userName = _selectedUserName();
    final openingMessages = ChatOpeningMessageBuilder.build(
      characterCardData: record.cardJson,
      characterName: summary.name,
      userName: userName,
    );
    final worldBookIds = record.worldBookId != null
        ? [record.worldBookId!]
        : const <String>[];
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute(
        builder: (context) => ChatPage.draft(
          characterId: summary.id,
          title: summary.name,
          selectedUserSettingId: selectedUserSettingIdNotifier.value,
          selectedPresetId: selectedPresetIdNotifier.value,
          selectedWorldBookIds: worldBookIds,
          openingAssistantMessages: openingMessages,
        ),
      ),
      (_) => false,
    );
  }

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

  Color _fallbackSummaryColor(CharacterSummary summary) {
    const palette = [
      Color(0xFF2E7D32),
      Color(0xFF1565C0),
      Color(0xFF7B1FA2),
      Color(0xFFB56576),
      Color(0xFF264653),
      Color(0xFFE76F51),
    ];
    return palette[summary.id.hashCode.abs() % palette.length];
  }

  Color _summaryColor(CharacterSummary summary) {
    final colorValue = summary.cardColorValue;
    if (colorValue != null) {
      return Color(colorValue);
    }
    return _fallbackSummaryColor(summary);
  }

  ImageProvider? _imageProviderForPath(String path) {
    if (path.isEmpty) {
      return null;
    }
    return path.startsWith('assets/')
        ? AssetImage(path) as ImageProvider
        : FileImage(File(path));
  }

  Widget _buildCharacterImage(String path, Color color) {
    Widget fallback() {
      return Container(
        color: color.withValues(alpha: 0.35),
        child: const Center(
          child: Icon(Icons.person, size: 120, color: Colors.white24),
        ),
      );
    }

    if (path.isEmpty) {
      return fallback();
    }

    final provider = _imageProviderForPath(path)!;

    return Image(
      image: provider,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.5),
      height: double.infinity,
      errorBuilder: (_, _, _) => fallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('角色管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '导入',
            onPressed: _onImport,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建',
            onPressed: _onCreate,
          ),
        ],
      ),
      body: FutureBuilder<List<CharacterSummary>>(
        future: _charactersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final characters = snapshot.data ?? const <CharacterSummary>[];
          if (characters.isEmpty) {
            return const Center(child: Text('还没有角色，先导入一张角色卡吧'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: characters.length,
              itemBuilder: (context, index) {
                final character = characters[index];
                final color = _summaryColor(character);
                return _CharacterCard(
                  name: character.name,
                  description: character.description,
                  color: color,
                  image: _buildCharacterImage(character.thumbnailPath, color),
                  onCreateChat: () => _onCreateChat(character),
                  onExport: () => _onExport(character),
                  onDelete: () => _onDelete(character),
                  onTap: () async {
                    await _openEditor(character.id);
                    await _refresh();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.name,
    required this.description,
    required this.color,
    required this.image,
    required this.onCreateChat,
    required this.onExport,
    required this.onDelete,
    required this.onTap,
  });

  final String name;
  final String description;
  final Color color;
  final Widget image;
  final VoidCallback onCreateChat;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: color,
            child: Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: constraints.maxWidth * 0.55,
                          child: ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.white,
                                  Colors.white,
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.545, 1.0],
                              ).createShader(bounds);
                            },
                            child: image,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 1,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 1,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _ActionButton(
                              icon: Icons.chat_bubble_outline,
                              onPressed: onCreateChat,
                              tooltip: '新建聊天',
                            ),
                            const SizedBox(width: 8),
                            _ActionButton(
                              icon: Icons.file_upload_outlined,
                              onPressed: onExport,
                              tooltip: '导出',
                            ),
                            const SizedBox(width: 8),
                            _ActionButton(
                              icon: Icons.delete_outline,
                              onPressed: onDelete,
                              tooltip: '删除',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: Colors.white,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

enum _ExportFormat { json, png }

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
