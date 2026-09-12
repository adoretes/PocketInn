import 'package:flutter/material.dart';

import '../../../models/chat_variables.dart';

/// 单个状态变量的展示行。
///
/// 副标题由类型、数值范围/单位、枚举选项拼装，右侧显示当前值；
/// 状态变量页与聊天页侧边栏共用，保证同一变量在两处呈现一致。
class ChatVariableRow extends StatelessWidget {
  const ChatVariableRow({
    super.key,
    required this.variable,
    this.dense = false,
  });

  final ChatVariable variable;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final metadata = variable.metadata;
    final rangeParts = <String>[];
    if (metadata?.minValue != null || metadata?.maxValue != null) {
      rangeParts.add(
        '${metadata?.minValue ?? '-∞'} ~ ${metadata?.maxValue ?? '+∞'}',
      );
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
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: colorScheme.primary),
      ),
    );
  }
}

/// 状态变量的取值列表：有值时逐行展示，无值时展示 [emptyHint]。
class ChatVariableList extends StatelessWidget {
  const ChatVariableList({
    super.key,
    required this.state,
    required this.emptyHint,
    this.dense = true,
    this.padding = EdgeInsets.zero,
  });

  final VariableState state;
  final String emptyHint;
  final bool dense;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (state.isEmpty) {
      return Padding(
        padding: padding,
        child: Text(
          emptyHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final variable in state.variables)
            ChatVariableRow(variable: variable, dense: dense),
        ],
      ),
    );
  }
}
