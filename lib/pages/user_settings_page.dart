import 'package:flutter/material.dart';

import '../data/mock_user_settings.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({
    super.key,
    required this.initialSettings,
    required this.initialSelectedId,
  });

  final List<UserSetting> initialSettings;
  final String? initialSelectedId;

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  late final List<UserSetting> _settings;
  late String? _selectedId;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings.map((item) => item.copyWith()).toList();
    _selectedId = widget.initialSelectedId;

    // 如果选中的ID无效，默认选择第一个
    if (_selectedId != null &&
        !_settings.any((item) => item.id == _selectedId)) {
      _selectedId = _settings.isNotEmpty ? _settings.first.id : null;
    }
  }

  Future<void> _onBack() async {
    Navigator.of(context).pop(
      UserSettingsPageResult(
        settings: List<UserSetting>.unmodifiable(_settings),
        selectedId: _selectedId,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onCreateRequested() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    Color selectedColor = const Color(0xFF5C6BC0);

    await showDialog<void>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('新建用户设定'),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '名字',
                          hintText: '请输入名字',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '名字不能为空';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        maxLines: 5,
                        minLines: 4,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          labelText: '描述',
                          hintText: '请输入用户设定描述',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('颜色：'),
                          const SizedBox(width: 8),
                          ...[
                            const Color(0xFF5C6BC0),
                            const Color(0xFF00897B),
                            const Color(0xFFD81B60),
                            const Color(0xFFE76F51),
                            const Color(0xFF277DA1),
                          ].map(
                            (color) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedColor = color;
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(8),
                                    border: selectedColor == color
                                        ? Border.all(
                                            color: colorScheme.onSurface,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final newSetting = UserSetting(
                        id: generateUserSettingId(),
                        name: nameController.text.trim(),
                        prompt: descriptionController.text.trim(),
                        colorValue: selectedColor.toARGB32(),
                      );

                      setState(() {
                        _settings.add(newSetting);
                        _selectedId ??= newSetting.id;
                      });

                      Navigator.of(context).pop();
                      _showMessage('已创建用户设定');
                    }
                  },
                  child: const Text('创建'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openEditDialog(UserSetting setting) async {
    final result = await showEditUserSettingDialog(context, setting);
    if (result == null) return;

    if (result.deleted) {
      setState(() {
        _settings.removeWhere((s) => s.id == setting.id);
        if (_selectedId == setting.id) {
          _selectedId = _settings.isNotEmpty ? _settings.first.id : null;
        }
      });
      _showMessage('已删除用户设定');
    } else {
      setState(() {
        final index = _settings.indexWhere((s) => s.id == setting.id);
        if (index != -1) {
          _settings[index] = result.setting;
        }
      });
      _showMessage('已保存');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBack,
          ),
          title: const Text('用户设定管理'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _onCreateRequested,
              tooltip: '新建',
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = switch (constraints.maxWidth) {
              < 640 => 2,
              < 920 => 2,
              < 1200 => 3,
              _ => 4,
            };

            if (_settings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.55,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无用户设定',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _onCreateRequested,
                      icon: const Icon(Icons.add),
                      label: const Text('创建用户设定'),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: _settings.length,
              itemBuilder: (context, index) {
                final setting = _settings[index];
                return _UserSettingGridCard(
                  setting: setting,
                  isSelected: setting.id == _selectedId,
                  onEdit: () => _openEditDialog(setting),
                  onSelect: () {
                    setState(() {
                      _selectedId = setting.id;
                    });
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class UserSettingsPageResult {
  const UserSettingsPageResult({
    required this.settings,
    required this.selectedId,
  });

  final List<UserSetting> settings;
  final String? selectedId;
}

/// 编辑用户设定弹窗的结果
class UserSettingEditDialogResult {
  const UserSettingEditDialogResult({
    required this.setting,
    this.deleted = false,
  });

  final UserSetting setting;
  final bool deleted;
}

/// 显示编辑用户设定弹窗（可复用于 chat_page 等场景）
Future<UserSettingEditDialogResult?> showEditUserSettingDialog(
  BuildContext context,
  UserSetting setting,
) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: setting.name);
  final descriptionController = TextEditingController(text: setting.prompt);
  Color selectedColor = setting.color;

  final result = await showDialog<UserSettingEditDialogResult>(
    context: context,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('编辑用户设定'),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '名字',
                        hintText: '请输入名字',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '名字不能为空';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 5,
                      minLines: 4,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        labelText: '描述',
                        hintText: '请输入用户设定描述',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('颜色：'),
                        const SizedBox(width: 8),
                        ...[
                          const Color(0xFF5C6BC0),
                          const Color(0xFF00897B),
                          const Color(0xFFD81B60),
                          const Color(0xFFE76F51),
                          const Color(0xFF277DA1),
                        ].map(
                          (color) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                  border: selectedColor == color
                                      ? Border.all(
                                          color: colorScheme.onSurface,
                                          width: 2,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认删除'),
                      content: Text('确定要删除「${setting.name}」吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    Navigator.of(context).pop(
                      UserSettingEditDialogResult(
                        setting: setting,
                        deleted: true,
                      ),
                    );
                  }
                },
                child: Text('删除', style: TextStyle(color: colorScheme.error)),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    final updatedSetting = setting
                        .copyWith(
                          name: nameController.text.trim(),
                          prompt: descriptionController.text.trim(),
                        )
                        .copyWithColor(selectedColor);
                    Navigator.of(
                      context,
                    ).pop(UserSettingEditDialogResult(setting: updatedSetting));
                  }
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      );
    },
  );

  return result;
}

class _UserSettingGridCard extends StatelessWidget {
  const _UserSettingGridCard({
    required this.setting,
    required this.isSelected,
    required this.onEdit,
    required this.onSelect,
  });

  final UserSetting setting;
  final bool isSelected;
  final VoidCallback onEdit;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? setting.color.withValues(alpha: 0.8)
                  : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                setting.color.withValues(alpha: 0.16),
                colorScheme.surfaceContainerLow,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: colorScheme.brightness == Brightness.dark
                      ? 0.16
                      : 0.04,
                ),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _UserSettingAvatar(setting: setting, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        setting.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      tooltip: '编辑',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    setting.prompt.trim().isEmpty ? '暂无描述内容' : setting.prompt,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
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

class _UserSettingAvatar extends StatelessWidget {
  const _UserSettingAvatar({required this.setting, required this.size});

  final UserSetting setting;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: setting.color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        setting.avatarText,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
