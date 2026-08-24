import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/api_configs.dart';
import '../models/api_config.dart';
import '../models/chat_message.dart';
import '../models/chat_variables.dart';
import 'api_request_log_service.dart';
import 'chat_database_service.dart';
import 'openai_compatible_api_service.dart';
import 'post_task_scheduler.dart';
import 'storage_service.dart';
import 'variable_state_service.dart';

/// 状态提取设置。
class StatusExtractionConfig {
  const StatusExtractionConfig({
    this.enabled = false,
    this.extractionModelId,
    this.recentMessages = 6,
    this.customPrompt = '',
  });

  /// 是否在角色回复完成后自动发起状态提取调用。
  final bool enabled;

  /// 提取专用模型 id；null/空表示跟随当前选中的 API 模型。
  final String? extractionModelId;

  /// 参与提取的最近消息条数（不含最新回复本身）。
  final int recentMessages;

  /// 自定义提取提示词（空串使用内置默认）。
  final String customPrompt;

  StatusExtractionConfig copyWith({
    bool? enabled,
    Object? extractionModelId = _unset,
    int? recentMessages,
    String? customPrompt,
  }) {
    return StatusExtractionConfig(
      enabled: enabled ?? this.enabled,
      extractionModelId: extractionModelId == _unset
          ? this.extractionModelId
          : extractionModelId as String?,
      recentMessages: recentMessages ?? this.recentMessages,
      customPrompt: customPrompt ?? this.customPrompt,
    );
  }
}

const Object _unset = Object();

/// 最近消息条数取值范围。
const int kStatusExtractionRecentMessagesMin = 2;
const int kStatusExtractionRecentMessagesMax = 20;

/// 内置默认提取提示词。{{state}} 由调用方替换为当前变量 JSON。
const String kDefaultStatusExtractionPrompt =
    '你是一个视觉小说游戏的状态跟踪器。请根据最新剧情进展，'
    '对下面的状态变量计算变化。\n\n'
    '当前状态变量（JSON）：\n{{state}}\n\n'
    '输出规则：\n'
    '- 只输出严格的 JSON，格式：{"ops": [{"op": "set", "var": "变量名", '
    '"value": 新值, "reason": "一句话原因"}]}；\n'
    '- 数值变量的增减用 "add"（value 为增量，可为负数），直接改写用 "set"；\n'
    '- 文本或状态类变量一律用 "set"，新值使用与剧情一致的语言；\n'
    '- 只根据剧情中实际发生的变化输出操作，没有变化输出 {"ops": []}；\n'
    '- 不要发明当前状态之外的变量，除非剧情确实引入了新的持久状态；\n'
    '- 不要输出 JSON 以外的任何内容。';

ValueNotifier<StatusExtractionConfig> statusExtractionNotifier = ValueNotifier(
  const StatusExtractionConfig(),
);

void updateStatusExtractionConfig({
  bool? enabled,
  Object? extractionModelId = _unset,
  int? recentMessages,
  String? customPrompt,
}) {
  final current = statusExtractionNotifier.value;
  final next = current.copyWith(
    enabled: enabled ?? current.enabled,
    extractionModelId: extractionModelId,
    recentMessages: recentMessages == null
        ? current.recentMessages
        : recentMessages.clamp(
            kStatusExtractionRecentMessagesMin,
            kStatusExtractionRecentMessagesMax,
          ),
    customPrompt: customPrompt ?? current.customPrompt,
  );
  statusExtractionNotifier.value = next;
  _persistStatusExtractionConfig(next);
}

Future<void> initializeStatusExtractionConfig() async {
  final storage = StorageService.instance;
  final enabled = storage.getBool('status_extraction_enabled');
  final extractionModelId = storage.getString(
    'status_extraction_model_id',
  );
  final recentMessages = storage.getInt('status_extraction_recent_messages');
  final customPrompt = storage.getString('status_extraction_custom_prompt');
  statusExtractionNotifier.value = StatusExtractionConfig(
    enabled: enabled ?? false,
    extractionModelId: extractionModelId,
    recentMessages: recentMessages ?? 6,
    customPrompt: customPrompt ?? '',
  );
}

void _persistStatusExtractionConfig(StatusExtractionConfig config) {
  final storage = StorageService.instance;
  unawaited(storage.setBool('status_extraction_enabled', config.enabled));
  if (config.extractionModelId != null &&
      config.extractionModelId!.isNotEmpty) {
    unawaited(
      storage.setString(
        'status_extraction_model_id',
        config.extractionModelId!,
      ),
    );
  } else {
    unawaited(storage.remove('status_extraction_model_id'));
  }
  unawaited(
    storage.setInt('status_extraction_recent_messages', config.recentMessages),
  );
  if (config.customPrompt.trim().isNotEmpty) {
    unawaited(
      storage.setString('status_extraction_custom_prompt', config.customPrompt),
    );
  } else {
    unawaited(storage.remove('status_extraction_custom_prompt'));
  }
}

/// 状态提取服务：角色回复完成后的一次轻量二次调用。
///
/// 请求包含「分支点时刻」的变量快照与最近对话，要求模型输出
/// 变量差量 ops；结果作为 diff 挂到该助手消息上（事件溯源）。
/// 解析失败或接口异常时静默跳过，绝不阻断聊天主流程。
class StatusExtractionService {
  StatusExtractionService._();

  static final StatusExtractionService instance = StatusExtractionService._();

  ResolvedApiConfig? get _extractionConfig {
    final configs = apiConfigsNotifier.value;
    final extractionModelId = statusExtractionNotifier
        .value
        .extractionModelId;
    ApiConfig? provider;
    ApiModel? model;
    if (extractionModelId != null && extractionModelId.isNotEmpty) {
      outer:
      for (final c in configs) {
        for (final m in c.models) {
          if (m.id == extractionModelId) {
            provider = c;
            model = m;
            break outer;
          }
        }
      }
    }
    // 未显式指定时，回退到当前选中的模型（及其 provider）。
    if (provider == null || model == null) {
      final tuple = selectedApiModelTuple;
      if (tuple == null) return null;
      provider = tuple.provider;
      model = tuple.model;
    }
    return provider.resolve(model);
  }

  /// 为一条已落库的助手消息提取变量差量（经后台调度器排队执行）。
  ///
  /// [recentMessages] 为该消息之前的路径消息（时间序）。
  /// 消息上如已有旧差量（原地编辑后重提）会先清空；提取失败则保持清空。
  /// 任务执行前与写库前会校验消息文本仍与 [assistantText] 一致，不一致
  /// （消息已被编辑/替换）时丢弃，防止过期差量落库。
  Future<void> extractForAssistantMessage({
    required String sessionId,
    required String assistantMessageId,
    required String assistantText,
    required List<ChatMessage> recentMessages,
    String characterName = '角色',
    String userName = '用户',
  }) async {
    PostTaskScheduler.instance.schedule(
      kind: PostTaskKind.statusExtraction,
      sessionId: sessionId,
      anchorKey: 'status:$assistantMessageId',
      isStale: () async =>
          await ChatDatabaseService.instance.loadMessageTextById(
            assistantMessageId,
          ) !=
          assistantText,
      run: (ensureFresh) async {
        await ensureFresh();
        final config = statusExtractionNotifier.value;
        if (!config.enabled) {
          return;
        }
        if (assistantText.trim().isEmpty) {
          return;
        }

        // 原地编辑后的重提：旧差量随旧文本作废。
        final existingOps = await VariableStateService.instance.readDiff(
          assistantMessageId,
        );
        if (existingOps.isNotEmpty) {
          await VariableStateService.instance.clearDiff(assistantMessageId);
        }

        // 分支点状态：不含该消息自身（其差量尚未写入/已清空）。
        final parentState = await VariableStateService.instance.resolveState(
          sessionId: sessionId,
          messageId: assistantMessageId,
          includeSelf: false,
        );
        // 角色卡未声明初始变量（状态系统未启用）时不发起提取调用。
        if (parentState.isEmpty) {
          return;
        }

        final apiConfig = _extractionConfig;
        if (apiConfig == null) {
          return;
        }

        final prompt = _buildExtractionPrompt(parentState);
        final userContent = _buildDialogueContext(
          recentMessages: recentMessages,
          assistantText: assistantText,
          characterName: characterName,
          userName: userName,
          recentCount: config.recentMessages,
        );

        final requestMessages = [
          {'role': 'system', 'content': prompt},
          {'role': 'user', 'content': userContent},
        ];

        final stopwatch = Stopwatch()..start();
        try {
          final result = await OpenAICompatibleApiService.instance
              .createChatCompletion(apiConfig, messages: requestMessages);
          stopwatch.stop();
          final ops = parseVariableOps(result.text);
          if (ops.isEmpty) {
            return;
          }
          await ensureFresh();
          await VariableStateService.instance.writeDiff(
            messageId: assistantMessageId,
            ops: ops,
          );
        } on PostTaskStaleException {
          rethrow;
        } catch (error, stack) {
          debugPrint('状态提取失败: $error\n$stack');
          unawaited(
            ApiRequestLogService.appendExtractionFailure(
              label: '状态提取失败',
              configName: apiConfig.name,
              model: apiConfig.model,
              baseUrl: apiConfig.baseUrl,
              error: error,
              durationMs: stopwatch.elapsedMilliseconds,
            ),
          );
        }
      },
    );
  }

  String _buildExtractionPrompt(VariableState state) {
    final config = statusExtractionNotifier.value;
    final rawPrompt = config.customPrompt.trim().isNotEmpty
        ? config.customPrompt
        : kDefaultStatusExtractionPrompt;

    final buffer = StringBuffer();
    for (final variable in state.variables) {
      if (buffer.isNotEmpty) {
        buffer.write(', ');
      }
      buffer.write('${jsonEncode(variable.name)}: ${jsonEncode(variable.value)}');
    }
    final stateJson = '{${buffer.toString()}}';

    var prompt = rawPrompt.replaceAll('{{state}}', stateJson);
    final rangeHints = _rangeHints(state);
    if (rangeHints.isNotEmpty) {
      prompt = '$prompt\n数值范围（越界会被钳制）：$rangeHints';
    }
    return prompt;
  }

  String _rangeHints(VariableState state) {
    final hints = <String>[];
    for (final variable in state.variables) {
      final metadata = variable.metadata;
      if (metadata == null) {
        continue;
      }
      if (metadata.minValue != null || metadata.maxValue != null) {
        final min = metadata.minValue;
        final max = metadata.maxValue;
        hints.add('${variable.name} ${min?.toStringAsFixed(0) ?? "-∞"}'
            '~${max?.toStringAsFixed(0) ?? "+∞"}');
      }
    }
    return hints.join('；');
  }

  String _buildDialogueContext({
    required List<ChatMessage> recentMessages,
    required String assistantText,
    required String characterName,
    required String userName,
    required int recentCount,
  }) {
    final recent = recentMessages.length > recentCount
        ? recentMessages.sublist(recentMessages.length - recentCount)
        : recentMessages;
    final dialogue = recent
        .map((m) => '${m.isMe ? userName : characterName}: ${m.text}')
        .join('\n');
    return '$dialogue\n\n————最新回复————\n$characterName: $assistantText';
  }
}

/// 解析模型输出的变量差量 JSON。
///
/// 容错策略与 gal 选项解析一致：剥离 Markdown 围栏后逐个尝试
/// 文中的平衡 JSON 块，首个能解出 ops 的块生效。
List<VariableOp> parseVariableOps(String raw) {
  var text = raw.trim();
  if (text.isEmpty) {
    return const [];
  }

  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false);
  final fenceMatch = fence.firstMatch(text);
  if (fenceMatch != null) {
    text = fenceMatch.group(1)!.trim();
  }

  for (final jsonText in _extractJsonCandidates(text)) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      continue;
    }
    final ops = _opsFromDecoded(decoded);
    if (ops != null) {
      return ops;
    }
  }
  return const [];
}

List<VariableOp>? _opsFromDecoded(dynamic decoded) {
  List<dynamic>? items;
  if (decoded is List) {
    items = decoded;
  } else if (decoded is Map) {
    for (final key in const ['ops', 'operations', 'changes', '变量', '操作']) {
      final value = decoded[key];
      if (value is List) {
        items = value;
        break;
      }
    }
  }
  if (items == null) {
    return null;
  }

  final ops = <VariableOp>[];
  for (final item in items) {
    final op = VariableOp.fromJson(item);
    if (op != null) {
      ops.add(op);
    }
  }
  return ops;
}

/// 收集文中最多 [maxCandidates] 个平衡的 JSON 对象/数组块。
Iterable<String> _extractJsonCandidates(
  String text, {
  int maxCandidates = 4,
}) sync* {
  var produced = 0;
  var attempts = 0;
  var i = 0;
  while (i < text.length && produced < maxCandidates) {
    final open = text[i];
    if (open != '{' && open != '[') {
      i++;
      continue;
    }
    attempts++;
    if (attempts > maxCandidates * 2) {
      return;
    }
    final end = _balancedEnd(text, i);
    if (end == null) {
      i++;
      continue;
    }
    yield text.substring(i, end + 1);
    produced++;
    i = end + 1;
  }
}

/// 返回以 [start] 处 `{`/`[` 为开括号的平衡块结束下标；未闭合返回 null。
int? _balancedEnd(String text, int start) {
  final open = text[start];
  final close = open == '{' ? '}' : ']';
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var j = start; j < text.length; j++) {
    final ch = text[j];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (ch == r'\') {
        escaped = true;
      } else if (ch == '"') {
        inString = false;
      }
      continue;
    }
    if (ch == '"') {
      inString = true;
    } else if (ch == open) {
      depth++;
    } else if (ch == close) {
      depth--;
      if (depth == 0) {
        return j;
      }
    }
  }
  return null;
}
