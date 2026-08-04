import '../../core/api/api_client.dart';

class AiConfig {
  const AiConfig({
    this.endpoint,
    this.model,
    this.temperature = .7,
    this.hasApiKey = false,
  });

  factory AiConfig.fromJson(Map<String, dynamic> json) => AiConfig(
    endpoint: json['endpoint']?.toString(),
    model: json['model']?.toString(),
    temperature: (json['temperature'] as num?)?.toDouble() ?? .7,
    hasApiKey:
        (json['hasApiKey'] as bool?) ??
        ((json['apiKeyMasked']?.toString().isNotEmpty ?? false)),
  );

  final String? endpoint;
  final String? model;
  final double temperature;
  final bool hasApiKey;

  AiConfig copyWith({
    String? endpoint,
    String? model,
    double? temperature,
    bool? hasApiKey,
  }) => AiConfig(
    endpoint: endpoint ?? this.endpoint,
    model: model ?? this.model,
    temperature: temperature ?? this.temperature,
    hasApiKey: hasApiKey ?? this.hasApiKey,
  );
}

class AiGenerateResult {
  const AiGenerateResult({required this.content, this.totalTokens});

  final String content;
  final int? totalTokens;
}

abstract class AiRepository {
  Future<AiConfig> getConfig();
  Future<AiConfig> updateConfig({
    required String endpoint,
    required String model,
    required double temperature,
    String? apiKey,
  });
  Future<AiGenerateResult> generate({
    required String scope,
    required String prompt,
    required String input,
  });
  Future<void> testConnection();
}

class HttpAiRepository implements AiRepository {
  HttpAiRepository(this._api);
  final ApiClient _api;

  @override
  Future<AiConfig> getConfig() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/ai/config',
      parseData: (raw) => raw,
    );
    return raw is Map
        ? AiConfig.fromJson(raw.cast<String, dynamic>())
        : const AiConfig();
  }

  @override
  Future<AiConfig> updateConfig({
    required String endpoint,
    required String model,
    required double temperature,
    String? apiKey,
  }) async {
    final body = <String, dynamic>{
      'endpoint': endpoint,
      'model': model,
      'temperature': temperature,
    };
    if (apiKey != null && apiKey.trim().isNotEmpty) body['apiKey'] = apiKey;
    final raw = await _api.request<dynamic>(
      method: 'PUT',
      path: '/ai/config',
      body: body,
      parseData: (raw) => raw,
    );
    return raw is Map
        ? AiConfig.fromJson(raw.cast<String, dynamic>())
        : AiConfig(
            endpoint: endpoint,
            model: model,
            temperature: temperature,
            hasApiKey: apiKey?.trim().isNotEmpty ?? false,
          );
  }

  @override
  Future<AiGenerateResult> generate({
    required String scope,
    required String prompt,
    required String input,
  }) async {
    final raw = await _api.request<dynamic>(
      method: 'POST',
      path: '/ai/generate',
      body: {'scope': scope, 'prompt': prompt, 'input': input},
      parseData: (raw) => raw,
    );
    if (raw is! Map) return const AiGenerateResult(content: '');
    final map = raw.cast<String, dynamic>();
    final usage = map['usage'];
    return AiGenerateResult(
      content: (map['content'] ?? '').toString(),
      totalTokens: usage is Map
          ? (usage['totalTokens'] as num?)?.toInt()
          : null,
    );
  }

  @override
  Future<void> testConnection() async {
    await generate(
      scope: 'connection_test',
      prompt: 'Reply with the word connected.',
      input: 'Connection test',
    );
  }
}
