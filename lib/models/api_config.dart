import 'dart:convert';

class ApiConfig {
  ApiConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.customBody = '',
    this.enabled = false,
  });

  final String id;
  String name;
  String baseUrl;
  String apiKey;
  String model;
  String customBody;
  bool enabled;

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '未命名配置',
      baseUrl: json['baseUrl'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? '',
      customBody: json['customBody'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'customBody': customBody,
      'enabled': enabled,
    };
  }

  ApiConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
    String? customBody,
    bool? enabled,
  }) {
    return ApiConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      customBody: customBody ?? this.customBody,
      enabled: enabled ?? this.enabled,
    );
  }

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
