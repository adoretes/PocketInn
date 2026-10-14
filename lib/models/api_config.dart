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

/// 由应用内部管理、禁止在自定义请求头中出现的名称（大小写不敏感）。
///
/// - `authorization`：由 `apiKey` 决定；
/// - `accept`：由应用统一设置为 `application/json`；
/// - `content-type`：由应用根据请求体统一设置，覆盖会破坏服务端解析。
///
/// 用户在自定义请求头中填写这些名称时会直接报错，而不是被静默忽略。
const Set<String> kReservedCustomHeaderNames = <String>{
  'authorization',
  'accept',
  'content-type',
};

/// 合法的 HTTP 请求头名称（RFC 7230 token）。
final RegExp _headerNamePattern = RegExp(r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$");

/// 校验并归一化自定义请求头。
///
/// 空列表或名称与值均为空的行返回空 Map（便于表单中存在未填写的占位行）。
/// 逐行按顺序校验：名称为 [kReservedCustomHeaderNames] 中的保留头、
/// 不匹配 HTTP token、只填值未填名称、值为空或包含换行等控制字符、
/// 名称重复（大小写不敏感）时抛出 [FormatException]。
///
/// 返回保留原始大小写的 `Map<String, String>`，键顺序与输入一致。
Map<String, String> resolveCustomHeaders(List<ApiCustomHeader> headers) {
  final result = <String, String>{};
  final seenLower = <String>{};
  for (final header in headers) {
    final name = header.name.trim();
    final value = header.value.trim();
    // 名称与值均为空的整行视为表单占位行，直接忽略；
    // 只填了值却没填名称属于无效输入，报错而非静默丢弃。
    if (name.isEmpty) {
      if (value.isEmpty) {
        continue;
      }
      throw const FormatException('自定义请求头名称不能为空');
    }
    final lowerName = name.toLowerCase();
    if (kReservedCustomHeaderNames.contains(lowerName)) {
      throw FormatException(
        '自定义请求头不能包含内部管理字段：$name，该字段由应用内部管理',
      );
    }
    if (!_headerNamePattern.hasMatch(name)) {
      throw FormatException('自定义请求头名称非法：$name，只能包含字母、数字及部分符号');
    }
    if (seenLower.contains(lowerName)) {
      throw FormatException('自定义请求头名称重复：$name');
    }
    if (value.isEmpty) {
      throw FormatException('自定义请求头「$name」的值不能为空');
    }
    if (value.contains('\r') || value.contains('\n')) {
      throw FormatException('自定义请求头「$name」的值不能包含换行符');
    }
    seenLower.add(lowerName);
    result[name] = value;
  }
  return result;
}

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

/// 单个自定义请求头键值对。
///
/// 用有序列表而非 Map 承载，便于编辑期保留顺序与容纳空名称占位行。
@freezed
abstract class ApiCustomHeader with _$ApiCustomHeader {
  const factory ApiCustomHeader({
    @JsonKey(defaultValue: '') @Default('') String name,
    @JsonKey(defaultValue: '') @Default('') String value,
  }) = _ApiCustomHeader;

  factory ApiCustomHeader.fromJson(Map<String, dynamic> json) =>
      _$ApiCustomHeaderFromJson(json);
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
    @JsonKey(defaultValue: <ApiCustomHeader>[])
    @Default(<ApiCustomHeader>[])
    List<ApiCustomHeader> customHeaders,
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
        customHeaders: customHeaders,
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
    @JsonKey(defaultValue: <ApiCustomHeader>[])
    @Default(<ApiCustomHeader>[])
    List<ApiCustomHeader> customHeaders,
  }) = _ResolvedApiConfig;

  factory ResolvedApiConfig.fromJson(Map<String, dynamic> json) =>
      _$ResolvedApiConfigFromJson(json);

  Map<String, dynamic> parseCustomBody() => parseCustomBodyText(customBody);

  /// 校验并归一化自定义请求头，供 service 合并到内置头之上。
  Map<String, String> customHeadersMap() => resolveCustomHeaders(customHeaders);

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
