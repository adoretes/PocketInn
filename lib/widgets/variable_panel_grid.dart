import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/chat_variables.dart';
import '../models/variable_panel.dart';

/// 组件之间的间距。
const double kVariablePanelGap = 8;

/// 单个组件在网格中的落位（单位：格）。
class VariablePanelPlacement {
  const VariablePanelPlacement({
    required this.item,
    required this.column,
    required this.row,
    required this.width,
    required this.height,
  });

  final VariablePanelItem item;
  final int column;
  final int row;
  final int width;
  final int height;
}

/// 面板装箱结果。
class VariablePanelLayout {
  const VariablePanelLayout({
    required this.placements,
    required this.rows,
  });

  final List<VariablePanelPlacement> placements;
  final int rows;

  bool get isEmpty => placements.isEmpty;
}

/// 按列表顺序做二维 first-fit 装箱：行优先扫描空格，放置第一个能容纳
/// 宽乘高的空矩形。网格列数固定为 [kVariablePanelColumns]，组件尺寸
/// 由自身的行列数决定。
VariablePanelLayout packVariablePanelItems(List<VariablePanelItem> items) {
  const colCount = kVariablePanelColumns;
  final occupied = <List<bool>>[];
  final placements = <VariablePanelPlacement>[];

  bool isFree(int row, int column, int width, int height) {
    for (var y = row; y < row + height; y++) {
      if (y >= occupied.length) {
        continue;
      }
      final line = occupied[y];
      for (var x = column; x < column + width; x++) {
        if (line[x]) {
          return false;
        }
      }
    }
    return true;
  }

  void occupy(int row, int column, int width, int height) {
    while (occupied.length < row + height) {
      occupied.add(List<bool>.filled(colCount, false));
    }
    for (var y = row; y < row + height; y++) {
      for (var x = column; x < column + width; x++) {
        occupied[y][x] = true;
      }
    }
  }

  // 每个组件最多占 kVariablePanelMaxHeight 行，按列表长度给足扫描行数。
  final rowLimit = items.length * kVariablePanelMaxHeight + 2;
  for (final item in items) {
    final width = item.columnSpan;
    final height = item.rowSpan;
    var placed = false;
    for (var row = 0; row < rowLimit && !placed; row++) {
      for (var column = 0; column + width <= colCount; column++) {
        if (isFree(row, column, width, height)) {
          occupy(row, column, width, height);
          placements.add(
            VariablePanelPlacement(
              item: item,
              column: column,
              row: row,
              width: width,
              height: height,
            ),
          );
          placed = true;
          break;
        }
      }
    }
  }

  var rows = 0;
  for (final placement in placements) {
    final bottom = placement.row + placement.height;
    if (bottom > rows) {
      rows = bottom;
    }
  }
  return VariablePanelLayout(placements: placements, rows: rows);
}

/// 只负责网格定位的容器；[itemBuilder] 决定每个格子里画什么，
/// 展示态与编辑态共用同一套装箱结果。
class VariablePanelGridView extends StatelessWidget {
  const VariablePanelGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.gap = kVariablePanelGap,
  });

  final List<VariablePanelItem> items;
  final Widget Function(BuildContext context, VariablePanelItem item)
  itemBuilder;
  final double gap;

  @override
  Widget build(BuildContext context) {
    const colCount = kVariablePanelColumns;
    final layout = packVariablePanelItems(items);
    if (layout.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 非常规容器（无限宽）时回退到侧边栏抽屉宽度，避免除零。
        final available = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 304.0;
        final cell = math.max(
          0.0,
          (available - gap * (colCount - 1)) / colCount,
        );
        final totalHeight = layout.rows * cell + (layout.rows - 1) * gap;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            children: [
              for (final placement in layout.placements)
                Positioned(
                  key: ValueKey('panel_${placement.item.id}'),
                  left: placement.column * (cell + gap),
                  top: placement.row * (cell + gap),
                  width: placement.width * cell + (placement.width - 1) * gap,
                  height:
                      placement.height * cell + (placement.height - 1) * gap,
                  child: itemBuilder(context, placement.item),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 变量网格面板的只读展示层。
///
/// 只消费 [VariableState]，不写回、不持有控制器；所有文本按纯文本渲染。
/// 显式布局会额外在末尾追加聊天中新出现、卡里未声明的变量。
class VariablePanelGrid extends StatelessWidget {
  const VariablePanelGrid({
    super.key,
    required this.state,
    required this.config,
    this.declaredVariableNames = const <String>[],
    this.onItemTap,
  });

  final VariableState state;
  final VariablePanelConfig config;

  /// 角色卡声明的变量名；用于区分「作者有意隐藏」与「聊天中新出现」。
  final List<String> declaredVariableNames;

  /// 点击组件查看详情；空白块不触发。
  final void Function(VariablePanelItem item, ChatVariable? variable)? onItemTap;

  @override
  Widget build(BuildContext context) {
    final items = appendRuntimeVariables(
      config,
      state.variables,
      declaredVariableNames: declaredVariableNames,
    );

    return VariablePanelGridView(
      items: items,
      itemBuilder: (context, item) {
        final variable = resolvePanelVariable(state, item.variableName);
        final tile = VariablePanelTile(item: item, variable: variable);
        final callback = onItemTap;
        if (callback == null ||
            item.type == VariablePanelComponentType.blank) {
          return tile;
        }
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => callback(item, variable),
            child: tile,
          ),
        );
      },
    );
  }
}

/// 在状态里查找组件绑定的变量（精确命中优先，否则忽略大小写回退）。
ChatVariable? resolvePanelVariable(VariableState state, String? name) {
  final target = name?.trim() ?? '';
  if (target.isEmpty) {
    return null;
  }
  final exact = state[target];
  if (exact != null) {
    return exact;
  }
  final normalized = target.toLowerCase();
  for (final variable in state.variables) {
    if (variable.name.trim().toLowerCase() == normalized) {
      return variable;
    }
  }
  return null;
}

/// 单个组件的只读展示卡片。
class VariablePanelTile extends StatelessWidget {
  const VariablePanelTile({
    super.key,
    required this.item,
    this.variable,
    this.editing = false,
    this.selected = false,
  });

  final VariablePanelItem item;

  /// 绑定变量的当前状态；为空表示变量缺失（展示占位）。
  final ChatVariable? variable;

  /// 编辑态会为空白块显示占位边框，并允许选中高亮。
  final bool editing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (item.type == VariablePanelComponentType.blank) {
      return editing
          ? _buildBlankPlaceholder(context, colorScheme)
          : const SizedBox.expand();
    }

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withValues(alpha: 0.24),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.7),
            width: selected ? 1.6 : 0.8,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.18),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(8),
        child: ClipRect(child: _buildBody(context, colorScheme)),
      ),
    );
  }

  Widget _buildBlankPlaceholder(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.8),
          width: selected ? 1.6 : 1,
        ),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      ),
      alignment: Alignment.center,
      child: Text(
        '空白',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme colorScheme) {
    final rawTitle = item.showTitle ? item.displayTitle : '';
    final variable = this.variable;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 细网格下可能出现很矮的格子：此时优先保证值可见，标题让位。
        final title =
            rawTitle.isNotEmpty &&
                (!constraints.maxHeight.isFinite ||
                    constraints.maxHeight >= 40)
            ? rawTitle
            : '';

        if (variable == null) {
          return _buildMissingContent(context, colorScheme, title);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Expanded(
              child: _buildContent(context, colorScheme, variable),
            ),
          ],
        );
      },
    );
  }

  /// 变量缺失时保持布局稳定：有标题就显示标题 + 「—」，否则显示「未定义」。
  Widget _buildMissingContent(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
  ) {
    final muted = colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: muted,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '—',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: muted,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    ChatVariable variable,
  ) {
    switch (item.type) {
      case VariablePanelComponentType.text:
        return Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              displayVariableValue(variable),
              maxLines: 1,
              style: _valueStyle(context, colorScheme),
            ),
          ),
        );
      case VariablePanelComponentType.multilineText:
        return LayoutBuilder(
          builder: (context, constraints) {
            const lineHeight = 12.0 * 1.45;
            final maxLines = constraints.maxHeight.isFinite
                ? (constraints.maxHeight / lineHeight).floor().clamp(1, 8)
                : 3;
            return Text(
              variable.value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                height: 1.45,
                color: colorScheme.onSurface,
              ),
            );
          },
        );
      case VariablePanelComponentType.progress:
        return _buildProgress(context, colorScheme, variable);
      case VariablePanelComponentType.cursor:
        return _buildCursor(context, colorScheme, variable);
      case VariablePanelComponentType.capsule:
        return _buildCapsule(context, colorScheme, variable);
      case VariablePanelComponentType.blank:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProgress(
    BuildContext context,
    ColorScheme colorScheme,
    ChatVariable variable,
  ) {
    final range = VariableNumberRange.fromMetadata(variable.metadata);
    final numeric = double.tryParse(variable.value.trim());
    final fraction = numeric == null ? 0.0 : range.fractionOf(numeric);
    final rangeStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 9,
      color: colorScheme.onSurfaceVariant,
      height: 1.1,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final tight = !maxHeight.isFinite || maxHeight < 42;
        // 格子太矮时优先保证值与进度条，范围文案按空间裁剪。
        final showRange = !tight && maxHeight >= 46;
        return Semantics(
          container: true,
          label: item.displayTitle.isEmpty ? '进度' : item.displayTitle,
          value:
              '${displayVariableValue(variable)}，${range.minLabel} 到 ${range.maxLabel}',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  displayVariableValue(variable),
                  maxLines: 1,
                  style: _valueStyle(
                    context,
                    colorScheme,
                    fontSize: tight ? 15 : 18,
                  ),
                ),
              ),
              SizedBox(height: tight ? 3 : 6),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(2)),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 4,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: colorScheme.primary,
                ),
              ),
              if (showRange) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        range.minLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: rangeStyle,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        range.maxLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: rangeStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCursor(
    BuildContext context,
    ColorScheme colorScheme,
    ChatVariable variable,
  ) {
    final range = VariableNumberRange.fromMetadata(variable.metadata);
    final numeric = double.tryParse(variable.value.trim());
    final fraction = numeric == null ? 0.0 : range.fractionOf(numeric);
    final rangeStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 9,
      color: colorScheme.onSurfaceVariant,
      height: 1.1,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final tight = !maxHeight.isFinite || maxHeight < 42;
        // 格子太矮时优先保证值与游标轨道，范围文案按空间裁剪。
        final showRange = !tight && maxHeight >= 46;
        return Semantics(
          container: true,
          label: item.displayTitle.isEmpty ? '游标' : item.displayTitle,
          value:
              '${displayVariableValue(variable)}，${range.minLabel} 到 ${range.maxLabel}',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  displayVariableValue(variable),
                  maxLines: 1,
                  style: _valueStyle(
                    context,
                    colorScheme,
                    fontSize: tight ? 15 : 18,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: tight ? 8 : 12,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final trackHeight = tight ? 8.0 : 12.0;
                    final markerSize = tight ? 7.0 : 9.0;
                    final trackTop = (trackHeight - 2) / 2;
                    final markerTop = (trackHeight - markerSize) / 2;
                    final width = constraints.maxWidth;
                    final left = math.max(
                      0.0,
                      fraction * math.max(0.0, width - markerSize),
                    );
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: trackTop,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: trackTop,
                          child: Container(
                            width: math.max(0.0, left),
                            height: 2,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.55,
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        Positioned(
                          left: left,
                          top: markerTop,
                          child: Container(
                            width: markerSize,
                            height: markerSize,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (showRange) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        range.minLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: rangeStyle,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        range.maxLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: rangeStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCapsule(
    BuildContext context,
    ColorScheme colorScheme,
    ChatVariable variable,
  ) {
    // 胶囊只展示当前枚举值，不罗列全部选项。
    final current = variable.value.trim();
    final isEmpty = current.isEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? math.max(0.0, constraints.maxWidth)
            : double.infinity;
        return Align(
          alignment: Alignment.topLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isEmpty
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.75)
                  : colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isEmpty ? '—' : current,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: isEmpty
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  TextStyle? _valueStyle(
    BuildContext context,
    ColorScheme colorScheme, {
    double fontSize = 18,
  }) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: colorScheme.primary,
      height: 1.1,
    );
  }
}

/// 数值变量的展示范围（进度条 / 游标共用）。
class VariableNumberRange {
  const VariableNumberRange(this.min, this.max);

  factory VariableNumberRange.fromMetadata(ChatVariableMetadata? metadata) {
    var min = metadata?.minValue ?? 0;
    if (!min.isFinite) {
      min = 0;
    }
    var max = metadata?.maxValue ?? (min + 100);
    if (!max.isFinite || max <= min) {
      max = min + 1;
    }
    return VariableNumberRange(min, max);
  }

  final double min;
  final double max;

  double get span => max - min;

  /// 比例收敛到 0~1；无法解析时调用方按 0 处理。
  double fractionOf(double value) {
    if (span <= 0) {
      return 0;
    }
    return ((value - min) / span).clamp(0.0, 1.0);
  }

  String get minLabel => formatRangeNumber(min);

  String get maxLabel => formatRangeNumber(max);
}

/// 数值范围文案：整数去掉尾随 `.0`，其余保留原样。
String formatRangeNumber(double value) {
  if (value.isFinite && value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
}

/// 组件展示「值 + 单位」。
String displayVariableValue(ChatVariable variable) {
  final unit = variable.metadata?.unit?.trim() ?? '';
  if (unit.isEmpty) {
    return variable.value;
  }
  return '${variable.value}$unit';
}
