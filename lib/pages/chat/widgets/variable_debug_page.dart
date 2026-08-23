import 'package:flutter/material.dart';

import '../../../data/api_configs.dart';
import '../../../models/chat_variables.dart';
import '../../../services/status_extraction_service.dart';
import '../../../services/variable_state_service.dart';

/// 状态变量调试页（计划 A 验收工具）。
///
/// 展示当前分支叶子时刻的变量状态、会话初始变量编辑、
/// 以及状态提取调用的设置。计划 B 的可视化浮窗落地后，
/// 本页保留作为调试/管理入口。
class VariableDebugPage extends StatefulWidget {
  const VariableDebugPage({
    super.key,
    required this.sessionId,
    this.leafMessageId,
  });

  final String sessionId;
  final String? leafMessageId;

  @override
  State<VariableDebugPage> createState() => _VariableDebugPageState();
}

class _VariableDebugPageState extends State<VariableDebugPage> {
  VariableState? _leafState;
  List<ChatVariable> _initVariables = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final service = VariableStateService.instance;
    final init = await service.loadInitState(widget.sessionId);
    final leaf = await service.resolveState(
      sessionId: widget.sessionId,
      messageId: widget.leafMessageId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _initVariables = init.variables.toList(growable: true);
      _leafState = leaf;
      _loading = false;
    });
  }

  Future<void> _saveInitVariables() async {
    final state = VariableState.fromVariables({
      for (final variable in _initVariables) variable.name: variable,
    });
    await VariableStateService.instance.saveInitState(
      widget.sessionId,
      state,
    );
    await _reload();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('初始变量已保存')));
  }

  Future<void> _editInitVariable([ChatVariable? existing]) async {
    final result = await showDialog<ChatVariable>(
      context: context,
      builder: (_) => _VariableEditDialog(initial: existing),
    );
    if (result == null) {
      return;
    }
    setState(() {
      _initVariables
        ..removeWhere((item) => item.name == result.name)
        ..add(result);
    });
    await _saveInitVariables();
  }

  Future<void> _removeInitVariable(String name) async {
    setState(() {
      _initVariables.removeWhere((item) => item.name == name);
    });
    await _saveInitVariables();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('状态变量'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _buildCurrentStateSection(colorScheme),
                const SizedBox(height: 16),
                _buildExtractionSettingsSection(colorScheme),
                const SizedBox(height: 16),
                _buildInitSection(colorScheme),
              ],
            ),
    );
  }

  Widget _buildCurrentStateSection(ColorScheme colorScheme) {
    final state = _leafState ?? VariableState.empty();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('当前状态', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  '分支叶子时刻',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.isEmpty)
              Text(
                '暂无变量。角色回复后（开启提取）会自动产生变化，'
                '或在下方手动添加初始变量。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...state.variables.map(
                (variable) => _VariableRow(
                  variable: variable,
                  dense: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractionSettingsSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_fix_high_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('状态提取', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '开启后每条角色回复完成后，会用一次轻量调用从剧情中提取变量变化。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            ValueListenableBuilder<StatusExtractionConfig>(
              valueListenable: statusExtractionNotifier,
              builder: (context, config, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('自动提取'),
                      value: config.enabled,
                      onChanged: (value) => updateStatusExtractionConfig(
                        enabled: value,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('提取模型'),
                      subtitle: Text(
                        _resolveExtractionModelLabel(config),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showModelPicker(config),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('参与提取的最近消息数'),
                      subtitle: Slider(
                        value: config.recentMessages.toDouble(),
                        min: kStatusExtractionRecentMessagesMin.toDouble(),
                        max: kStatusExtractionRecentMessagesMax.toDouble(),
                        divisions:
                            kStatusExtractionRecentMessagesMax -
                            kStatusExtractionRecentMessagesMin,
                        label: '${config.recentMessages}',
                        onChanged: (value) => updateStatusExtractionConfig(
                          recentMessages: value.round(),
                        ),
                      ),
                      trailing: Text('${config.recentMessages}'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('自定义提示词'),
                      subtitle: Text(
                        config.customPrompt.trim().isEmpty
                            ? '使用内置默认'
                            : '已自定义（{{state}} 会替换为当前变量 JSON）',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _showCustomPromptEditor(config),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _resolveExtractionModelLabel(StatusExtractionConfig config) {
    final modelId = config.extractionModelId;
    if (modelId == null || modelId.isEmpty) {
      final tuple = selectedApiModelTuple;
      return tuple == null ? '跟随当前模型（未选择）' : '跟随当前模型（${tuple.model.modelId}）';
    }
    for (final provider in apiConfigsNotifier.value) {
      for (final model in provider.models) {
        if (model.id == modelId) {
          return '${provider.name} · ${model.modelId}';
        }
      }
    }
    return '未知模型';
  }

  Future<void> _showModelPicker(StatusExtractionConfig config) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            children: [
              ListTile(
                title: const Text('跟随当前模型'),
                trailing: (config.extractionModelId == null ||
                        config.extractionModelId!.isEmpty)
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(''),
              ),
              for (final provider in apiConfigsNotifier.value)
                for (final model in provider.models)
                  ListTile(
                    title: Text(model.modelId),
                    subtitle: Text(provider.name),
                    trailing: config.extractionModelId == model.id
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(model.id),
                  ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      updateStatusExtractionConfig(
        extractionModelId: selected.isEmpty ? null : selected,
      );
    }
  }

  Future<void> _showCustomPromptEditor(StatusExtractionConfig config) async {
    final controller = TextEditingController(text: config.customPrompt);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('自定义提取提示词'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '{{state}} 会被替换为当前变量 JSON；留空恢复内置默认。',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      updateStatusExtractionConfig(customPrompt: controller.text);
    }
    controller.dispose();
  }

  Widget _buildInitSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('初始变量', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: '添加变量',
                  icon: const Icon(Icons.add),
                  onPressed: () => _editInitVariable(),
                ),
              ],
            ),
            Text(
              '会话起点的变量值（如生命 100、好感 0）。删除分支或重置聊天后，'
              '状态都从这里重新开始。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (_initVariables.isEmpty)
              Text(
                '尚未设置初始变量。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...[
                for (final variable in _initVariables)
                  _VariableRow(
                    variable: variable,
                    onEdit: () => _editInitVariable(variable),
                    onRemove: () => _removeInitVariable(variable.name),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

class _VariableRow extends StatelessWidget {
  const _VariableRow({
    required this.variable,
    this.dense = false,
    this.onEdit,
    this.onRemove,
  });

  final ChatVariable variable;
  final bool dense;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final metadata = variable.metadata;
    final rangeParts = <String>[];
    if (metadata?.minValue != null || metadata?.maxValue != null) {
      rangeParts.add('${metadata?.minValue ?? '-∞'} ~ '
          '${metadata?.maxValue ?? '+∞'}');
    }
    if (metadata?.unit != null && metadata!.unit!.isNotEmpty) {
      rangeParts.add(metadata.unit!);
    }
    final subtitle = [
      variable.type.label,
      if (rangeParts.isNotEmpty) rangeParts.join(' · '),
      if (variable.type == ChatVariableType.enumType &&
          metadata != null &&
          metadata.enumOptions.isNotEmpty)
        '选项: ${metadata.enumOptions.join('/')}',
    ].join(' · ');

    return ListTile(
      dense: dense,
      contentPadding: EdgeInsets.zero,
      title: Text(variable.name),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            variable.value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: '编辑',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
          ],
          if (onRemove != null) ...[
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}

class _VariableEditDialog extends StatefulWidget {
  const _VariableEditDialog({this.initial});

  final ChatVariable? initial;

  @override
  State<_VariableEditDialog> createState() => _VariableEditDialogState();
}

class _VariableEditDialogState extends State<_VariableEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final TextEditingController _unitController;
  late final TextEditingController _enumOptionsController;
  ChatVariableType _type = ChatVariableType.number;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _valueController = TextEditingController(text: initial?.value ?? '');
    _minController = TextEditingController(
      text: initial?.metadata?.minValue?.toStringAsFixed(0) ?? '',
    );
    _maxController = TextEditingController(
      text: initial?.metadata?.maxValue?.toStringAsFixed(0) ?? '',
    );
    _unitController = TextEditingController(text: initial?.metadata?.unit ?? '');
    _enumOptionsController = TextEditingController(
      text: initial?.metadata?.enumOptions.join(',') ?? '',
    );
    _type = initial?.type ?? ChatVariableType.number;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _unitController.dispose();
    _enumOptionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '添加变量' : '编辑变量'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '变量名',
                  hintText: '如：好感度、生命、状态',
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<ChatVariableType>(
                segments: [
                  for (final type in ChatVariableType.values)
                    ButtonSegment(value: type, label: Text(type.label)),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: '初始值',
                  hintText: '数值或文本',
                ),
              ),
              if (_type == ChatVariableType.number) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minController,
                        decoration: const InputDecoration(labelText: '最小值'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxController,
                        decoration: const InputDecoration(labelText: '最大值'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(labelText: '单位（可选）'),
                ),
              ],
              if (_type == ChatVariableType.enumType) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _enumOptionsController,
                  decoration: const InputDecoration(
                    labelText: '枚举选项（逗号分隔）',
                    hintText: '如：平静,动摇,心动',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final metadata = ChatVariableMetadata(
      minValue: _type == ChatVariableType.number
          ? double.tryParse(_minController.text.trim())
          : null,
      maxValue: _type == ChatVariableType.number
          ? double.tryParse(_maxController.text.trim())
          : null,
      unit: _unitController.text.trim().isEmpty
          ? null
          : _unitController.text.trim(),
      enumOptions: _type == ChatVariableType.enumType
          ? _enumOptionsController.text
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
    );
    Navigator.of(context).pop(
      ChatVariable(
        name: name,
        type: _type,
        value: _valueController.text.trim(),
        metadata: metadata,
      ),
    );
  }
}
