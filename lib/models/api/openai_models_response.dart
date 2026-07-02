import 'package:freezed_annotation/freezed_annotation.dart';

part 'openai_models_response.freezed.dart';
part 'openai_models_response.g.dart';

/// `/models` 接口响应。
@freezed
abstract class OpenAIModelsResponse with _$OpenAIModelsResponse {
  const factory OpenAIModelsResponse({
    @Default([]) List<OpenAIModelInfo> data,
  }) = _OpenAIModelsResponse;

  factory OpenAIModelsResponse.fromJson(Map<String, dynamic> json) =>
      _$OpenAIModelsResponseFromJson(json);
}

@freezed
abstract class OpenAIModelInfo with _$OpenAIModelInfo {
  const factory OpenAIModelInfo({
    required String id,
    String? object,
    @JsonKey(name: 'owned_by') String? ownedBy,
  }) = _OpenAIModelInfo;

  factory OpenAIModelInfo.fromJson(Map<String, dynamic> json) =>
      _$OpenAIModelInfoFromJson(json);
}
