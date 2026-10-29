import 'chat_variables.dart';

/// 变量网格的固定列数（不再提供列数配置）。
const int kVariablePanelColumns = 4;

/// 组件最小占格。
const int kVariablePanelMinSpan = 1;

/// 组件最大宽度（列数）。
const int kVariablePanelMaxWidth = kVariablePanelColumns;

/// 组件最大高度（行数）。
const int kVariablePanelMaxHeight = 4;

/// 变量面板可用的组件类型。
///
/// 组件只读消费状态变量，不写回；[blank] 不绑定变量，仅用于占位。
enum VariablePanelComponentType {
  capsule('胶囊'),
  text('单行文本'),
  multilineText('多行文本'),
  progress('进度条'),
  cursor('游标'),
  blank('空白块');

  const VariablePanelComponentType(this.label);

  final String label;

  String get value => name;

  /// 是否需要绑定变量（空白块不需要）。
  bool get bindsVariable => this != VariablePanelComponentType.blank;

  /// 组件能否消费指定类型的变量。
  bool accepts(ChatVariableType type) {
    switch (this) {
      case VariablePanelComponentType.capsule:
        return type == ChatVariableType.enumType;
      case VariablePanelComponentType.text:
        return true;
      case VariablePanelComponentType.multilineText:
        return type == ChatVariableType.text;
      case VariablePanelComponentType.progress:
      case VariablePanelComponentType.cursor:
        return type == ChatVariableType.number;
      case VariablePanelComponentType.blank:
        return false;
    }
  }

  /// 解析组件类型；未知/缺失返回 null（由调用方决定跳过）。
  static VariablePanelComponentType? tryParse(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    for (final type in VariablePanelComponentType.values) {
      if (type.value == normalized ||
          type.name == normalized ||
          type.label == normalized) {
        return type;
      }
    }
    return null;
  }
}

/// 面板内的一个组件配置（不可变）。
///
/// 尺寸为占格的行列数：宽度 1~[kVariablePanelMaxWidth]，
/// 高度 1~[kVariablePanelMaxHeight]。
class VariablePanelItem {
  const VariablePanelItem({
    required this.id,
    required this.type,
    this.width = 1,
    this.height = 1,
    this.variableName,
    this.showTitle = true,
    this.title,
  });

  static const Object _unset = Object();

  final String id;
  final VariablePanelComponentType type;

  /// 占格宽度（列数）。
  final int width;

  /// 占格高度（行数）。
  final int height;

  /// 绑定的变量名；[VariablePanelComponentType.blank] 为 null。
  final String? variableName;

  /// 是否显示标题。
  final bool showTitle;

  /// 自定义标题；为空时展示变量名。
  final String? title;

  /// 收敛到合法范围的宽度。
  int get columnSpan =>
      width.clamp(kVariablePanelMinSpan, kVariablePanelMaxWidth).toInt();

  /// 收敛到合法范围的高度。
  int get rowSpan =>
      height.clamp(kVariablePanelMinSpan, kVariablePanelMaxHeight).toInt();

  /// 实际展示的标题文案（空标题回落到变量名）。
  String get displayTitle {
    final custom = title?.trim() ?? '';
    if (custom.isNotEmpty) {
      return custom;
    }
    return variableName?.trim() ?? '';
  }

  bool get isBound =>
      type.bindsVariable &&
      variableName != null &&
      variableName!.trim().isNotEmpty;

  VariablePanelItem copyWith({
    VariablePanelComponentType? type,
    int? width,
    int? height,
    Object? variableName = _unset,
    bool? showTitle,
    Object? title = _unset,
  }) {
    return VariablePanelItem(
      id: id,
      type: type ?? this.type,
      width: _clampInt(
        width ?? this.width,
        kVariablePanelMinSpan,
        kVariablePanelMaxWidth,
        this.width,
      ),
      height: _clampInt(
        height ?? this.height,
        kVariablePanelMinSpan,
        kVariablePanelMaxHeight,
        this.height,
      ),
      variableName: identical(variableName, _unset)
          ? this.variableName
          : variableName as String?,
      showTitle: showTitle ?? this.showTitle,
      title: identical(title, _unset) ? this.title : title as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'w': columnSpan,
      'h': rowSpan,
      'showTitle': showTitle,
      if (variableName != null && variableName!.isNotEmpty)
        'var': variableName,
      if (title != null && title!.isNotEmpty) 'title': title,
    };
  }

  /// 解析单个组件；类型未知或绑定缺失时返回 null。
  static VariablePanelItem? fromJson(dynamic json, {required int index}) {
    if (json is! Map) {
      return null;
    }
    final type = VariablePanelComponentType.tryParse(
      json['type']?.toString(),
    );
    if (type == null) {
      return null;
    }

    final rawName = json['var'] ?? json['variable'] ?? json['name'];
    final variableName = rawName?.toString().trim() ?? '';
    if (type.bindsVariable && variableName.isEmpty) {
      return null;
    }

    // 兼容旧的固定尺寸命名；新数据直接写 w/h。
    final legacy = _legacySpan(json['size']?.toString());
    final width = _clampInt(
      json['w'] ?? json['width'],
      kVariablePanelMinSpan,
      kVariablePanelMaxWidth,
      legacy.$1,
    );
    final height = _clampInt(
      json['h'] ?? json['height'],
      kVariablePanelMinSpan,
      kVariablePanelMaxHeight,
      legacy.$2,
    );
    final rawId = json['id']?.toString().trim() ?? '';
    final rawTitle = json['title']?.toString().trim() ?? '';

    return VariablePanelItem(
      id: rawId.isEmpty ? 'item_$index' : rawId,
      type: type,
      width: width,
      height: height,
      variableName: type.bindsVariable ? variableName : null,
      showTitle: json['showTitle'] is bool
          ? json['showTitle'] as bool
          : json['show_title'] is bool
          ? json['show_title'] as bool
          : true,
      title: rawTitle.isEmpty ? null : rawTitle,
    );
  }

  /// 为某个变量生成默认组件。
  static VariablePanelItem defaultFor(
    ChatVariable variable, {
    required String id,
  }) {
    return VariablePanelItem(
      id: id,
      type: defaultTypeFor(variable),
      width: defaultWidthFor(variable),
      height: defaultHeightFor(variable),
      variableName: variable.name,
    );
  }

  static VariablePanelComponentType defaultTypeFor(ChatVariable variable) {
    switch (variable.type) {
      case ChatVariableType.number:
        final metadata = variable.metadata;
        if (metadata?.minValue != null && metadata?.maxValue != null) {
          return VariablePanelComponentType.progress;
        }
        return VariablePanelComponentType.text;
      case ChatVariableType.enumType:
        final options = variable.metadata?.enumOptions ?? const <String>[];
        return options.isEmpty
            ? VariablePanelComponentType.text
            : VariablePanelComponentType.capsule;
      case ChatVariableType.text:
        return VariablePanelComponentType.multilineText;
    }
  }

  static int defaultWidthFor(ChatVariable variable) {
    switch (defaultTypeFor(variable)) {
      case VariablePanelComponentType.progress:
      case VariablePanelComponentType.capsule:
      case VariablePanelComponentType.multilineText:
        return 2;
      case VariablePanelComponentType.text:
      case VariablePanelComponentType.cursor:
      case VariablePanelComponentType.blank:
        return 1;
    }
  }

  static int defaultHeightFor(ChatVariable variable) {
    return defaultTypeFor(variable) == VariablePanelComponentType.multilineText
        ? 2
        : 1;
  }
}

/// 角色卡中的变量面板布局配置（不可变）。
///
/// [items] 为空表示作者有意不展示任何组件；而配置整体缺失用 null 表示
/// 「未配置」，由运行时按变量自动生成默认布局。
class VariablePanelConfig {
  const VariablePanelConfig({
    this.version = 1,
    this.items = const <VariablePanelItem>[],
  });

  static const int kVersion = 1;

  final int version;
  final List<VariablePanelItem> items;

  bool get isEmpty => items.isEmpty;

  int get length => items.length;

  VariablePanelConfig copyWith({
    int? version,
    List<VariablePanelItem>? items,
  }) {
    return VariablePanelConfig(
      version: version ?? this.version,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'items': [for (final item in items) item.toJson()],
    };
  }

  /// 按变量声明顺序生成默认布局。
  static VariablePanelConfig defaultForVariables(
    Iterable<ChatVariable> variables,
  ) {
    var index = 0;
    return VariablePanelConfig(
      items: [
        for (final variable in variables)
          VariablePanelItem.defaultFor(variable, id: 'auto_${index++}'),
      ],
    );
  }

  /// 从角色卡 JSON 解析面板配置。
  ///
  /// 返回 null 表示卡里没有该扩展键（运行时自动生成默认布局）；
  /// 返回 items 为空的配置表示作者显式清空了面板。
  /// 旧的 `columns` 字段被忽略：网格列数已固定。
  static VariablePanelConfig? decode(Map<String, dynamic> cardJson) {
    final data = cardJson['data'];
    if (data is! Map) {
      return null;
    }
    final extensions = data['extensions'];
    if (extensions is! Map) {
      return null;
    }
    if (!extensions.containsKey(kCardVariablePanelExtensionKey)) {
      return null;
    }
    final raw = extensions[kCardVariablePanelExtensionKey];
    if (raw is! Map) {
      return null;
    }

    final rawItems = raw['items'];
    final items = <VariablePanelItem>[];
    final usedIds = <String>{};
    if (rawItems is List) {
      for (var index = 0; index < rawItems.length; index++) {
        final item = VariablePanelItem.fromJson(
          rawItems[index],
          index: index,
        );
        if (item == null) {
          continue;
        }
        var id = item.id;
        if (usedIds.contains(id)) {
          id = '${id}_$index';
        }
        usedIds.add(id);
        items.add(
          id == item.id
              ? item
              : VariablePanelItem(
                  id: id,
                  type: item.type,
                  width: item.columnSpan,
                  height: item.rowSpan,
                  variableName: item.variableName,
                  showTitle: item.showTitle,
                  title: item.title,
                ),
        );
      }
    }

    return VariablePanelConfig(
      version: _clampInt(raw['version'], 1, 99, kVersion),
      items: List<VariablePanelItem>.unmodifiable(items),
    );
  }

  /// 去掉绑定变量已不存在的组件（空白块保留）。
  VariablePanelConfig withoutMissingVariables(
    Iterable<ChatVariable> variables,
  ) {
    final names = {
      for (final variable in variables) variable.name.trim().toLowerCase(),
    };
    final next = [
      for (final item in items)
        if (!item.isBound ||
            names.contains(item.variableName!.trim().toLowerCase()))
          item,
    ];
    if (next.length == items.length) {
      return this;
    }
    return copyWith(items: List<VariablePanelItem>.unmodifiable(next));
  }

  /// 变量新增 / 改名 / 改类型后的同步。
  ///
  /// - 新增：追加该变量的默认组件（保持声明顺序）；
  /// - 改名：更新全部绑定；
  /// - 改类型：把不再兼容的组件替换为该类型的默认组件，保留 id、尺寸与标题设置。
  VariablePanelConfig afterVariableUpdated({
    ChatVariable? previous,
    required ChatVariable current,
  }) {
    if (previous == null) {
      // 显式空面板表示作者有意不展示任何组件，新增变量时不自动追加。
      if (items.isEmpty) {
        return this;
      }
      if (items.any((item) => _sameName(item.variableName, current.name))) {
        return this;
      }
      return copyWith(
        items: List<VariablePanelItem>.unmodifiable([
          ...items,
          VariablePanelItem.defaultFor(
            current,
            id: _nextItemId(),
          ),
        ]),
      );
    }

    final renamed = previous.name != current.name;
    final typeChanged = previous.type != current.type;
    if (!renamed && !typeChanged) {
      return this;
    }

    var changed = false;
    final next = <VariablePanelItem>[];
    for (final item in items) {
      var updated = item;
      if (item.isBound && _sameName(item.variableName, previous.name)) {
        if (renamed) {
          updated = updated.copyWith(variableName: current.name);
        }
        if (!updated.type.accepts(current.type)) {
          updated = updated.copyWith(
            type: VariablePanelItem.defaultTypeFor(current),
          );
        }
      }
      if (!identical(updated, item)) {
        changed = true;
      }
      next.add(updated);
    }
    if (!changed) {
      return this;
    }
    return copyWith(items: List<VariablePanelItem>.unmodifiable(next));
  }

  /// 变量删除后移除其绑定组件。
  VariablePanelConfig afterVariableRemoved(String name) {
    final next = [
      for (final item in items)
        if (!(item.isBound && _sameName(item.variableName, name))) item,
    ];
    if (next.length == items.length) {
      return this;
    }
    return copyWith(items: List<VariablePanelItem>.unmodifiable(next));
  }

  /// 移动组件顺序；越界时原样返回。
  VariablePanelConfig moveItem(int from, int to) {
    if (from == to ||
        from < 0 ||
        to < 0 ||
        from >= items.length ||
        to >= items.length) {
      return this;
    }
    final next = List<VariablePanelItem>.from(items);
    final item = next.removeAt(from);
    next.insert(to, item);
    return copyWith(items: List<VariablePanelItem>.unmodifiable(next));
  }

  /// 生成配置内唯一的组件 id。
  String _nextItemId() {
    var index = items.length;
    while (items.any((item) => item.id == 'item_$index')) {
      index++;
    }
    return 'item_$index';
  }

  static bool _sameName(String? left, String? right) {
    if (left == null || right == null) {
      return false;
    }
    return left.trim().toLowerCase() == right.trim().toLowerCase();
  }
}

/// 运行时生效的面板配置。
///
/// 卡里没有布局（null）时按变量自动生成默认布局；显式空配置保持为空，
/// 表示作者有意清空面板。
VariablePanelConfig resolveVariablePanelConfig(
  VariablePanelConfig? config,
  Iterable<ChatVariable> variables,
) {
  return config ?? VariablePanelConfig.defaultForVariables(variables);
}

/// 在显式布局末尾追加「聊天过程中新出现、卡里未声明」的变量。
///
/// - 显式空布局保持为空（作者有意不展示）；
/// - 角色卡已声明但没出现在布局里的变量视为作者有意隐藏，不追加；
/// - 仅状态里新出现、且不在 [declaredVariableNames] 中的变量按默认组件
///   追加到末尾。追加只影响本次渲染，不写回角色卡。
List<VariablePanelItem> appendRuntimeVariables(
  VariablePanelConfig config,
  Iterable<ChatVariable> stateVariables, {
  Iterable<String> declaredVariableNames = const <String>[],
}) {
  if (config.items.isEmpty) {
    return config.items;
  }

  final bound = <String>{
    for (final item in config.items)
      if (item.isBound) _normalizeVariableName(item.variableName!),
  };
  final declared = <String>{
    for (final name in declaredVariableNames) _normalizeVariableName(name),
  };

  final items = List<VariablePanelItem>.from(config.items);
  var index = 0;
  String nextId() {
    while (items.any((item) => item.id == 'runtime_$index')) {
      index++;
    }
    return 'runtime_${index++}';
  }

  for (final variable in stateVariables) {
    final normalized = _normalizeVariableName(variable.name);
    if (normalized.isEmpty ||
        bound.contains(normalized) ||
        declared.contains(normalized)) {
      continue;
    }
    items.add(VariablePanelItem.defaultFor(variable, id: nextId()));
  }
  return items;
}

String _normalizeVariableName(String name) => name.trim().toLowerCase();

/// 角色卡中变量面板布局的扩展键（与 `variables` 并列）。
const String kCardVariablePanelExtensionKey = 'variablePanel';

/// 序列化为 `data.extensions.variablePanel` 的取值。
Map<String, dynamic> encodeVariablePanelConfig(VariablePanelConfig config) {
  return config.toJson();
}

/// 从角色卡 JSON（含 `data.extensions.variablePanel`）解析布局配置。
VariablePanelConfig? decodeVariablePanelConfig(Map<String, dynamic> cardJson) {
  return VariablePanelConfig.decode(cardJson);
}

/// 旧版尺寸预设到行列数的映射；未知值回落到 1x1。
(int, int) _legacySpan(String? value) {
  switch (value?.trim()) {
    case 'wide':
      return (2, 1);
    case 'tall':
      return (1, 2);
    case 'large':
      return (2, 2);
    default:
      return (1, 1);
  }
}

int _clampInt(dynamic raw, int min, int max, int fallback) {
  final value = raw is num ? raw.toInt() : int.tryParse('$raw');
  if (value == null) {
    return fallback;
  }
  return value.clamp(min, max).toInt();
}
