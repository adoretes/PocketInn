import 'package:flutter/material.dart';

import '../../../data/api_configs.dart';
import '../../../models/chat_variables.dart';
import '../../../services/status_extraction_service.dart';
import '../../../services/variable_state_service.dart';

/// 状态变量页（验收/管理工具）。
///
/// 展示当前分支叶子时刻的变量状态、来自角色卡的初始变量（只读）、
/// 状态提取设置与宏用法提示。初始变量的声明在角色卡编辑页进行，
/// 正式开始聊天时应用；角色卡未声明变量时状态系统不启用。
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
  VariableState? _initState;
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
      _initState = init;
      _leafState = leaf;
      _loading = false;
    });
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
                _buildInitSection(colorScheme),
                const SizedBox(height: 16),
                _buildExtractionSettingsSection(colorScheme),
                const SizedBox(height: 16),
                _buildMacroHintSection(colorScheme),
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
                _initState != null && _initState!.isEmpty
                    ? '角色卡未声明初始状态变量，状态系统未启用。'
                          '请在角色卡编辑页的「初始状态变量」中声明。'
                    : '暂无变量（初始变量尚未发生任何变化）。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...state.variables.map(
                (variable) => _VariableRow(variable: variable, dense: true),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitSection(ColorScheme colorScheme) {
    final init = _initState ?? VariableState.empty();
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
                Text(
                  '来自角色卡',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (init.isEmpty)
              Text(
                '角色卡未声明初始变量（状态系统不启用）。'
                '在角色卡编辑页的「初始状态变量」区块声明；'
                '正式开始聊天时应用，重置聊天时按角色卡重新应用。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...init.variables.map(
                (variable) => _VariableRow(variable: variable, dense: true),
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
              '开启后每条角色回复完成后，会用一次轻量调用从剧情中提取变量变化。'
              '需角色卡已声明初始变量，否则不会发起提取。',
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

  Widget _buildMacroHintSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('在提示词中引用', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '· {{getstate}} —— 展开为全部当前变量（名称: 值 逐行）\n'
              '· {{getvar::变量名}} —— 展开为单个变量的当前值\n'
              '两者都随消息分支求值：gal 回复历史、切换版本时自动回到对应时刻的状态。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
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
    final confirmed = await showDialog<String>(
      context: context,
      builder: (_) => _CustomPromptEditorDialog(initial: config.customPrompt),
    );
    if (confirmed != null) {
      updateStatusExtractionConfig(customPrompt: confirmed);
    }
  }
}

/// 自定义提取提示词编辑器：controller 由弹窗自身的 State 持有，
/// 随弹窗卸载释放，避免退出动画期间被输入法回调访问到已释放的 controller。
class _CustomPromptEditorDialog extends StatefulWidget {
  const _CustomPromptEditorDialog({required this.initial});

  final String initial;

  @override
  State<_CustomPromptEditorDialog> createState() => _CustomPromptEditorDialogState();
}

class _CustomPromptEditorDialogState extends State<_CustomPromptEditorDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              controller: _controller,
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _VariableRow extends StatelessWidget {
  const _VariableRow({required this.variable, this.dense = false});

  final ChatVariable variable;
  final bool dense;

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
      trailing: Text(
        variable.value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
