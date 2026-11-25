/// 上下文片段的来源类型。
///
/// 请求日志的「上下文」视图按提示词组装顺序展示这些片段，
/// 让阅读时能直接辨认每段内容来自预设、世界书、记忆还是角色卡等。
enum PromptContextSource {
  preset('预设'),
  worldBook('世界书'),
  memory('记忆'),
  characterCard('角色卡'),
  history('对话历史'),
  userSetting('用户设定'),
  postInstruction('设定后指令'),
  request('请求消息'),
  other('其他');

  const PromptContextSource(this.label);

  final String label;

  /// 兼容按枚举名或中文标签序列化的旧数据。
  static PromptContextSource fromJson(Object? value) {
    if (value is String) {
      for (final source in values) {
        if (source.name == value || source.label == value) {
          return source;
        }
      }
    }
    return other;
  }
}

/// 一条上下文片段：来源 + role + 名称 + 正文。
///
/// 仅用于请求日志的展示与持久化；[name] 可以为空。
class PromptContextEntry {
  const PromptContextEntry({
    required this.source,
    required this.role,
    required this.name,
    required this.content,
  });

  final PromptContextSource source;
  final String role;
  final String name;
  final String content;

  factory PromptContextEntry.fromJson(Map<String, dynamic> json) {
    return PromptContextEntry(
      source: PromptContextSource.fromJson(json['source']),
      role: json['role']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source.name,
      'role': role,
      'name': name,
      'content': content,
    };
  }
}
