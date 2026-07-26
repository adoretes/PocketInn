import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/world_book.dart';
import '../services/world_book_service.dart';
import '../widgets/expanded_text_editor_field.dart';
import 'world_book_edit_page.dart';

class RoleEditPage extends StatefulWidget {
  const RoleEditPage({
    super.key,
    required this.characterData,
    this.imagePath = '',
    this.onSave,
    this.closeAfterSave = false,
    this.initialWorldBookId,
  });

  final Map<String, dynamic> characterData;
  final String imagePath;
  final Future<void> Function(RoleEditSavePayload payload)? onSave;
  final bool closeAfterSave;
  final String? initialWorldBookId;

  @override
  State<RoleEditPage> createState() => _RoleEditPageState();
}

class _RoleEditPageState extends State<RoleEditPage> {
  late Map<String, dynamic> data;

  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController personalityController;
  late TextEditingController scenarioController;
  late TextEditingController firstMesController;
  late TextEditingController mesExampleController;
  late TextEditingController creatorNotesController;
  late TextEditingController systemPromptController;
  late TextEditingController postHistoryInstructionsController;

  late List<String> alternateGreetings;
  late List<TextEditingController> _greetingControllers;
  int _currentGreetingIndex = 0;
  late List<String> tags;

  final TextEditingController _newTagController = TextEditingController();
  bool _showValidationError = false;
  String? _pendingImagePath;
  bool _removeImage = false;
  late final ImageProvider? _initialBackgroundImage;
  List<WorldBook> _worldBooks = [];
  String? _selectedWorldBookId;

  @override
  void initState() {
    super.initState();
    data = Map<String, dynamic>.from(
      widget.characterData['data'] as Map<String, dynamic>,
    );

    nameController = TextEditingController(text: data['name'] ?? '');
    descriptionController = TextEditingController(
      text: data['description'] ?? '',
    );
    personalityController = TextEditingController(
      text: data['personality'] ?? '',
    );
    scenarioController = TextEditingController(text: data['scenario'] ?? '');
    firstMesController = TextEditingController(text: data['first_mes'] ?? '');
    mesExampleController = TextEditingController(
      text: data['mes_example'] ?? '',
    );
    creatorNotesController = TextEditingController(
      text: data['creator_notes'] ?? '',
    );
    systemPromptController = TextEditingController(
      text: data['system_prompt'] ?? '',
    );
    postHistoryInstructionsController = TextEditingController(
      text: data['post_history_instructions'] ?? '',
    );

    alternateGreetings = List<String>.from(
      data['alternate_greetings'] as List? ?? const [],
    );
    _greetingControllers = alternateGreetings
        .map((greeting) => TextEditingController(text: greeting))
        .toList();
    if (_greetingControllers.isEmpty) {
      _greetingControllers = [TextEditingController()];
      alternateGreetings = [''];
    }
    tags = List<String>.from(data['tags'] as List? ?? const []);
    _selectedWorldBookId = widget.initialWorldBookId;
    _initialBackgroundImage = _imageProviderForPath(widget.imagePath);
    _loadWorldBooks();
  }

  Future<void> _loadWorldBooks() async {
    final books = await WorldBookService.instance.loadAll();
    if (!mounted) return;
    setState(() {
      _worldBooks = books;
      if (_selectedWorldBookId != null &&
          !_worldBooks.any((book) => book.id == _selectedWorldBookId)) {
        _selectedWorldBookId = null;
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    personalityController.dispose();
    scenarioController.dispose();
    firstMesController.dispose();
    mesExampleController.dispose();
    creatorNotesController.dispose();
    systemPromptController.dispose();
    postHistoryInstructionsController.dispose();
    for (final controller in _greetingControllers) {
      controller.dispose();
    }
    _newTagController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final trimmedName = nameController.text.trim();
    final trimmedDescription = descriptionController.text.trim();
    final trimmedFirstMes = firstMesController.text.trim();

    if (trimmedName.isEmpty ||
        trimmedDescription.isEmpty ||
        trimmedFirstMes.isEmpty) {
      setState(() {
        _showValidationError = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名字、设定、第一条消息为必填项')));
      return;
    }

    final alternateGreetings = _greetingControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    final normalizedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    final updatedData = {
      ...data,
      'name': trimmedName,
      'description': trimmedDescription,
      'personality': personalityController.text.trim(),
      'scenario': scenarioController.text.trim(),
      'first_mes': trimmedFirstMes,
      'mes_example': mesExampleController.text.trim(),
      'creator_notes': creatorNotesController.text.trim(),
      'system_prompt': systemPromptController.text.trim(),
      'post_history_instructions': postHistoryInstructionsController.text
          .trim(),
      'alternate_greetings': alternateGreetings,
      'tags': normalizedTags,
      'character_book':
          data['character_book'] ??
          <String, dynamic>{'entries': {}, 'extensions': {}},
      'extensions': data['extensions'] ?? <String, dynamic>{},
    };

    final updatedCard = {
      'spec': widget.characterData['spec'] ?? 'chara_card_v2',
      'spec_version': widget.characterData['spec_version'] ?? '2.0',
      'data': updatedData,
    };

    if (widget.onSave != null) {
      await widget.onSave!(
        RoleEditSavePayload(
          cardJson: updatedCard,
          imageSourcePath: _pendingImagePath,
          removeImage: _removeImage,
          selectedWorldBookId: _selectedWorldBookId,
        ),
      );
    }

    setState(() {
      data = Map<String, dynamic>.from(updatedData);
      _showValidationError = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('角色已保存')));

    if (widget.closeAfterSave) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickWorldBook() async {
    final selectedId = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.link_off_outlined),
                  title: const Text('不关联世界书'),
                  onTap: () => Navigator.pop(context, ''),
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('创建新世界书'),
                  onTap: () => _createAndBindWorldBook(),
                ),
                const Divider(height: 1),
                Flexible(
                  child: _worldBooks.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('暂无可选世界书')),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _worldBooks.length,
                          itemBuilder: (context, index) {
                            final book = _worldBooks[index];
                            return ListTile(
                              leading: Icon(
                                _selectedWorldBookId == book.id
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: book.color,
                              ),
                              title: Text(book.name),
                              subtitle: Text('${book.entries.length} 个条目'),
                              onTap: () => Navigator.pop(context, book.id),
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

    if (!mounted || selectedId == null) return;
    setState(() {
      _selectedWorldBookId = selectedId.isEmpty ? null : selectedId;
    });
  }

  Future<void> _createAndBindWorldBook() async {
    final controller = TextEditingController(
      text: '${nameController.text.trim()}-世界书',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建世界书'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '世界书名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    final book = await WorldBookService.instance.create(name: name);
    if (!mounted) return;

    setState(() {
      _worldBooks.add(book);
    });
    if (context.mounted) {
      Navigator.pop(context, book.id);
    }
  }

  Future<void> _editWorldBook(String worldBookId) async {
    final book = await WorldBookService.instance.loadById(worldBookId);
    if (!mounted || book == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorldBookEditPage(worldBook: book),
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      dialogTitle: '选择角色立绘',
    );
    final files = result?.files;
    if (files == null || files.isEmpty) {
      return;
    }
    final path = files.first.path;
    if (path == null || path.isEmpty) {
      return;
    }
    setState(() {
      _pendingImagePath = path;
      _removeImage = false;
    });
  }

  void _removePortrait() {
    setState(() {
      _pendingImagePath = null;
      _removeImage = widget.imagePath.isNotEmpty;
    });
  }

  void _removeCurrentGreeting() {
    if (_greetingControllers.isEmpty) return;
    setState(() {
      _greetingControllers[_currentGreetingIndex].dispose();
      _greetingControllers.removeAt(_currentGreetingIndex);
      alternateGreetings.removeAt(_currentGreetingIndex);
      if (_greetingControllers.isEmpty) {
        alternateGreetings = [''];
        _greetingControllers = [TextEditingController()];
        _currentGreetingIndex = 0;
      } else if (_currentGreetingIndex >= _greetingControllers.length) {
        _currentGreetingIndex = _greetingControllers.length - 1;
      }
    });
  }

  void _addNewGreeting() {
    setState(() {
      alternateGreetings.add('');
      _greetingControllers.add(TextEditingController());
      _currentGreetingIndex = _greetingControllers.length - 1;
    });
  }

  void _previousGreeting() {
    if (_currentGreetingIndex <= 0) return;
    setState(() {
      _currentGreetingIndex--;
    });
  }

  void _nextGreeting() {
    if (_currentGreetingIndex >= _greetingControllers.length - 1) return;
    setState(() {
      _currentGreetingIndex++;
    });
  }

  void _addTag() {
    final text = _newTagController.text.trim();
    if (text.isNotEmpty && !tags.contains(text)) {
      setState(() {
        tags.add(text);
        _newTagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      tags.remove(tag);
    });
  }

  ImageProvider? _imageProviderForPath(String path) {
    if (path.isEmpty) {
      return null;
    }
    return path.startsWith('assets/')
        ? AssetImage(path) as ImageProvider
        : FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surface = colorScheme.surface;
    final hasPortrait = _hasPortrait;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: TextField(
          controller: nameController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
          decoration: InputDecoration(
            hintText: '角色名称',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorText:
                _showValidationError && nameController.text.trim().isEmpty
                ? '必填'
                : null,
            errorStyle: const TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _pickImage,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(
              Icons.image_outlined,
              color: Colors.white,
              size: 18,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
            label: const Text(
              '设置立绘',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          if (hasPortrait)
            IconButton(
              tooltip: '移除立绘',
              onPressed: _removePortrait,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 18,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          TextButton(
            onPressed: _onSave,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '保存',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: surface,
        child: Stack(
          children: [
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildBackgroundImage(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          surface.withValues(alpha: 0),
                          surface.withValues(alpha: 0.94),
                          surface,
                        ],
                        stops: [0.0, 0.65, 0.85],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: colorScheme.surfaceContainerLow.withValues(
                    alpha: colorScheme.brightness == Brightness.dark
                        ? 0.94
                        : 0.9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ExpandedTextEditorField(
                          controller: descriptionController,
                          maxLines: 8,
                          dialogTitle: '编辑角色设定',
                          decoration: InputDecoration(
                            labelText: '角色设定',
                            border: const OutlineInputBorder(),
                            errorText:
                                _showValidationError &&
                                    descriptionController.text.trim().isEmpty
                                ? '必填'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: personalityController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: '性格、好恶',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ExpandedTextEditorField(
                          controller: scenarioController,
                          maxLines: 5,
                          dialogTitle: '编辑当前场景',
                          decoration: const InputDecoration(
                            labelText: '当前场景',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ExpandedTextEditorField(
                          controller: firstMesController,
                          maxLines: 12,
                          dialogTitle: '编辑初见开场',
                          decoration: InputDecoration(
                            labelText: '初见开场',
                            border: const OutlineInputBorder(),
                            errorText:
                                _showValidationError &&
                                    firstMesController.text.trim().isEmpty
                                ? '必填'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.58),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                12,
                                0,
                                12,
                                12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide.none,
                              ),
                              collapsedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide.none,
                              ),
                              title: const Text(
                                '高级设置',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              children: [
                                TextFormField(
                                  controller: mesExampleController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: '对话示例',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Text(
                                      '替代问候语',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_currentGreetingIndex + 1} / ${_greetingControllers.length}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller:
                                      _greetingControllers[_currentGreetingIndex],
                                  maxLines: 5,
                                  minLines: 5,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    suffixIconConstraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 0,
                                    ),
                                    suffixIcon: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.keyboard_arrow_up,
                                              size: 20,
                                            ),
                                            onPressed: _currentGreetingIndex > 0
                                                ? _previousGreeting
                                                : null,
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 20,
                                            ),
                                            onPressed:
                                                _currentGreetingIndex <
                                                    _greetingControllers
                                                            .length -
                                                        1
                                                ? _nextGreeting
                                                : null,
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 20,
                                            ),
                                            onPressed: _addNewGreeting,
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                            ),
                                            onPressed: _removeCurrentGreeting,
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: creatorNotesController,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: '创作者注释',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: systemPromptController,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: '系统提示词',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: postHistoryInstructionsController,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: '对话历史后指令',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '标签',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: tags.map((tag) {
                                    return Chip(
                                      label: Text(tag),
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: 18,
                                      ),
                                      onDeleted: () => _removeTag(tag),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _newTagController,
                                        decoration: const InputDecoration(
                                          hintText: '新标签',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle),
                                      onPressed: _addTag,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.menu_book_outlined),
                          title: const Text('选择世界书'),
                          subtitle: Text(_selectedWorldBookLabel),
                          trailing: _selectedWorldBookId != null
                              ? IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: '编辑世界书',
                                  onPressed: () => _editWorldBook(_selectedWorldBookId!),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: _pickWorldBook,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    final resolvedPath = _currentImagePath;
    final imageProvider = _removeImage
        ? null
        : _pendingImagePath != null
        ? _imageProviderForPath(_pendingImagePath!)
        : _initialBackgroundImage;

    if (resolvedPath.isEmpty || imageProvider == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    }

    return Image(
      image: imageProvider,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  String get _currentImagePath {
    if (_removeImage) {
      return '';
    }
    return _pendingImagePath ?? widget.imagePath;
  }

  bool get _hasPortrait => _currentImagePath.isNotEmpty;

  String get _selectedWorldBookLabel {
    if (_selectedWorldBookId == null) {
      return '未关联';
    }
    final book = _worldBooks.cast<WorldBook?>().firstWhere(
      (item) => item?.id == _selectedWorldBookId,
      orElse: () => null,
    );
    return book?.name ?? '未关联';
  }
}

class RoleEditSavePayload {
  const RoleEditSavePayload({
    required this.cardJson,
    this.imageSourcePath,
    this.removeImage = false,
    this.selectedWorldBookId,
  });

  final Map<String, dynamic> cardJson;
  final String? imageSourcePath;
  final bool removeImage;
  final String? selectedWorldBookId;
}
