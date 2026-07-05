import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_config.freezed.dart';
part 'api_config.g.dart';

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

  Map<String, dynamic> parseCustomBody() {
    final source = customBody.trim();
    if (source.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw FormatException('自定义 body 必须是 JSON 对象');
    }
    return Map<String, dynamic>.from(decoded);
  }
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

  Map<String, dynamic> parseCustomBody() {
    final source = customBody.trim();
    if (source.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw FormatException('自定义 body 必须是 JSON 对象');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Map<String, dynamic> buildRequestBody({
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? defaults,
  }) {
    final body = <String, dynamic>{
      if (defaults != null) ...defaults,
      'model': model,
      'messages': messages,
    };
    body.addAll(parseCustomBody());
    return body;
  }
}
