import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_config.freezed.dart';
part 'api_config.g.dart';

/// 由应用内部管理、禁止在自定义 body 中出现的请求字段。
///
/// - `model`：由所选模型决定；
/// - `stream`：由调用方（流式 / 非流式接口）决定，用户覆盖会破坏响应解析；
/// - `include_usage`：始终由应用强制注入。
///
/// 用户在自定义 body 中填写这些字段时会直接报错，而不是被静默忽略。
const Set<String> kReservedCustomBodyKeys = <String>{
  'model',
  'stream',
  'include_usage',
};

/// 解析自定义 body 文本。
///
/// 空文本返回空 Map；不是 JSON 对象、包含 [kReservedCustomBodyKeys] 中的保留
/// 字段、或 `messages` 不是数组时抛出 [FormatException]。
Map<String, dynamic> parseCustomBodyText(String source) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) {
    return <String, dynamic>{};
  }
  final decoded = jsonDecode(trimmed);
  if (decoded is! Map) {
    throw const FormatException('自定义 body 必须是 JSON 对象');
  }
  final body = Map<String, dynamic>.from(decoded);
  final conflicts = body.keys
      .where(kReservedCustomBodyKeys.contains)
      .toList(growable: false)
    ..sort();
  if (conflicts.isNotEmpty) {
    throw FormatException(
      '自定义 body 不能包含保留字段：${conflicts.join('、')}，'
      '这些字段由应用内部管理',
    );
  }
  if (body.containsKey('messages') && body['messages'] is! List) {
    throw const FormatException('自定义 body 的 messages 必须是数组');
  }
  return body;
}

/// 单个模型条目。一个 [ApiConfig]（Provider）下可包含多个模型，
/// 每个模型携带自己的 [customBody]，跟随模型本身。
@freezed
abstract class ApiModel with _$ApiModel {
  const ApiModel._();

  const factory ApiModel({
    @JsonKey(defaultValue: '') required String id,
    @JsonKey(defaultValue: '') required String modelId,
    @JsonKey(defaultValue: '') @Default('') String customBody,
  }) = _ApiModel;

  factory ApiModel.fromJson(Map<String, dynamic> json) =>
      _$ApiModelFromJson(json);

  Map<String, dynamic> parseCustomBody() => parseCustomBodyText(customBody);
}

/// API 提供方。持有 baseUrl / apiKey 与一组模型列表。
///
/// 选择状态由全局 [lib/data/api_configs.dart] 中的
/// `selectedApiModelIdNotifier` 维护，本类不持有任何"激活"标志。
@freezed
abstract class ApiConfig with _$ApiConfig {
  const ApiConfig._();

  const factory ApiConfig({
    @JsonKey(defaultValue: '') required String id,
    @JsonKey(defaultValue: '未命名配置') required String name,
    @JsonKey(defaultValue: '') required String baseUrl,
    @JsonKey(defaultValue: '') required String apiKey,
    @JsonKey(defaultValue: <ApiModel>[])
    @Default(<ApiModel>[])
    List<ApiModel> models,
  }) = _ApiConfig;

  factory ApiConfig.fromJson(Map<String, dynamic> json) =>
      _$ApiConfigFromJson(json);

  /// 将本 provider 与指定 [model] 组合成 [ResolvedApiConfig]，供 service 层调用。
  ResolvedApiConfig resolve(ApiModel model) => ResolvedApiConfig(
        id: id,
        name: name,
        baseUrl: baseUrl,
        apiKey: apiKey,
        model: model.modelId,
        customBody: model.customBody,
      );

  /// 用于仅需 provider 信息（如 fetchModels）的场景：取首个 model，
  /// 若列表为空则用空 model 占位，service 内部会处理空 model 情况。
  ResolvedApiConfig resolveFirstOrEmpty() => models.isEmpty
      ? resolve(const ApiModel(id: '', modelId: '', customBody: ''))
      : resolve(models.first);
}

/// Provider + 选定 model 的组合，作为 [OpenAICompatibleApiService] 的统一入参。
@freezed
abstract class ResolvedApiConfig with _$ResolvedApiConfig {
  const ResolvedApiConfig._();

  const factory ResolvedApiConfig({
    @JsonKey(defaultValue: '') required String id,
    @JsonKey(defaultValue: '未命名配置') required String name,
    @JsonKey(defaultValue: '') required String baseUrl,
    @JsonKey(defaultValue: '') required String apiKey,
    @JsonKey(defaultValue: '') required String model,
    @JsonKey(defaultValue: '') @Default('') String customBody,
  }) = _ResolvedApiConfig;

  factory ResolvedApiConfig.fromJson(Map<String, dynamic> json) =>
      _$ResolvedApiConfigFromJson(json);

  Map<String, dynamic> parseCustomBody() => parseCustomBodyText(customBody);

  Map<String, dynamic> buildRequestBody({
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? defaults,
  }) {
    final body = <String, dynamic>{
      if (defaults != null) ...defaults,
      'model': model,
      'messages': messages,
    };
    // parseCustomBody 已拒绝 model / stream / include_usage 等保留字段，
    // 因此合并自定义 body 不会覆盖系统设定的值。
    final customBody = parseCustomBody();
    if (customBody['messages'] is List) {
      final customMessages = customBody.remove('messages') as List;
      body['messages'] = [
        ...messages,
        ...customMessages.cast<Map<String, dynamic>>(),
      ];
    }
    body.addAll(customBody);
    // 始终请求返回 token 用量，供请求日志展示。
    body['include_usage'] = true;
    return body;
  }
}
