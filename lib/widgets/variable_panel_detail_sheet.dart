import 'package:flutter/material.dart';

import '../models/chat_variables.dart';
import '../models/variable_panel.dart';
import 'variable_panel_grid.dart';

/// 弹出组件详情（只读）。
Future<void> showVariablePanelDetail(
  BuildContext context, {
  required VariablePanelItem item,
  required ChatVariable? variable,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _VariablePanelDetailSheet(
      item: item,
      variable: variable,
    ),
  );
}

class _VariablePanelDetailSheet extends StatelessWidget {
  const _VariablePanelDetailSheet({
    required this.item,
    required this.variable,
  });

  final VariablePanelItem item;
  final ChatVariable? variable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final variable = this.variable;
    final title = variable != null && variable.name.trim().isNotEmpty
        ? variable.name
        : item.displayTitle.isNotEmpty
        ? item.displayTitle
        : '变量详情';
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                  _TypeBadge(label: variable?.type.label ?? '未定义'),
                ],
              ),
              const SizedBox(height: 16),
              if (variable == null)
                _InfoRow(
                  label: '状态',
                  child: Text(
                    '未定义（变量可能已被删除）',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                )
              else ...[
                _InfoRow(
                  label: '当前值',
                  child: SelectableText(
                    displayVariableValue(variable),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                if (variable.type == ChatVariableType.number)
                  ..._buildNumberRows(context, variable),
                if (variable.type == ChatVariableType.enumType)
                  _buildEnumRow(context, variable),
                if (variable.changeHint?.trim().isNotEmpty == true)
                  _InfoRow(
                    label: '变化说明',
                    child: SelectableText(variable.changeHint!.trim()),
                  ),
              ],
              const SizedBox(height: 8),
              Text(
                '只读展示：变量值由状态提取更新，不能在此修改。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNumberRows(
    BuildContext context,
    ChatVariable variable,
  ) {
    final metadata = variable.metadata;
    final hasRange = metadata?.minValue != null || metadata?.maxValue != null;
    final unit = metadata?.unit?.trim() ?? '';
    final rows = <Widget>[];

    if (hasRange) {
      final range = VariableNumberRange.fromMetadata(metadata);
      rows.add(
        _InfoRow(
          label: '范围',
          child: Text('${range.minLabel} ~ ${range.maxLabel}'),
        ),
      );
      final numeric = double.tryParse(variable.value.trim());
      if (numeric != null) {
        rows.add(
          _InfoRow(
            label: '进度',
            child: Text('${(range.fractionOf(numeric) * 100).round()}%'),
          ),
        );
      }
    } else {
      rows.add(const _InfoRow(label: '范围', child: Text('未设置')));
    }

    if (unit.isNotEmpty) {
      rows.add(_InfoRow(label: '单位', child: Text(unit)));
    }
    return rows;
  }

  Widget _buildEnumRow(BuildContext context, ChatVariable variable) {
    final current = variable.value.trim();
    final options = [
      for (final option in variable.metadata?.enumOptions ?? const <String>[])
        if (option.trim().isNotEmpty) option.trim(),
    ];
    if (options.isEmpty) {
      return const _InfoRow(label: '可选值', child: Text('未设置'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    return _InfoRow(
      label: '可选值',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final option in options)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: option == current
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                option,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: option == current
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
