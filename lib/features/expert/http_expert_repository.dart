import '../../core/api/api_client.dart';
import '../../experts/domain.dart';
import '../../experts/expert_repository.dart';

class HttpExpertRepository implements ExpertRepository {
  HttpExpertRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Expert>> listExperts({String query = '', String? scope}) async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/experts',
      query: {
        if (query.trim().isNotEmpty) 'query': query.trim(),
        'scope': ?scope,
      },
      parseData: (value) => value,
    );
    return _items(
      raw,
    ).map(ExpertDto.fromJson).map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<Expert?> getExpert(
    String id, {
    required ExpertSourceType sourceType,
  }) async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/experts/$id',
      query: {'type': sourceType.apiValue},
      parseData: (value) => value,
    );
    if (raw is! Map) return null;
    return ExpertDto.fromJson(
      raw.cast<String, dynamic>(),
    ).toDomain(sourceType: sourceType);
  }

  @override
  Future<ExpertDetail?> getExpertDetail(
    String id, {
    required ExpertSourceType sourceType,
  }) async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/experts/$id',
      query: {'type': sourceType.apiValue},
      parseData: (value) => value,
    );
    if (raw is! Map) return null;
    return ExpertDetailDto.fromJson(raw.cast<String, dynamic>()).toDomain();
  }

  @override
  Future<Expert> createExpert({
    required String name,
    required String category,
    String description = '',
    required String persona,
    String methodology = '',
    required String promptTemplate,
    String toolPolicyJson = '{"skills":[]}',
    int estimatedCredits = 1,
  }) async {
    final raw = await _api.request<dynamic>(
      method: 'POST',
      path: '/experts',
      body: {
        'name': name,
        'category': category,
        if (description.isNotEmpty) 'description': description,
        'persona': persona,
        if (methodology.isNotEmpty) 'methodology': methodology,
        'promptTemplate': promptTemplate,
        'toolPolicyJson': toolPolicyJson,
        'estimatedCredits': estimatedCredits,
      },
      parseData: (value) => value,
    );
    if (raw is! Map) {
      throw StateError('创建自建专家未返回详情');
    }
    return ExpertDetailDto.fromJson(
      raw.cast<String, dynamic>(),
    ).toDomain().toExpert();
  }

  @override
  Future<Expert> updateExpert({
    required String id,
    required int rowVersion,
    required String name,
    required String category,
    String description = '',
    required String persona,
    String methodology = '',
    required String promptTemplate,
    String toolPolicyJson = '{"skills":[]}',
    int estimatedCredits = 1,
  }) async {
    final raw = await _api.request<dynamic>(
      method: 'PUT',
      path: '/experts/$id',
      body: {
        'name': name,
        'category': category,
        if (description.isNotEmpty) 'description': description,
        'persona': persona,
        if (methodology.isNotEmpty) 'methodology': methodology,
        'promptTemplate': promptTemplate,
        'toolPolicyJson': toolPolicyJson,
        'estimatedCredits': estimatedCredits,
        'rowVersion': rowVersion,
      },
      parseData: (value) => value,
    );
    if (raw is! Map) {
      throw StateError('更新自建专家未返回详情');
    }
    return ExpertDetailDto.fromJson(
      raw.cast<String, dynamic>(),
    ).toDomain().toExpert();
  }

  @override
  Future<void> deleteExpert(String id) => _api.request<dynamic>(
    method: 'DELETE',
    path: '/experts/$id',
    parseData: (_) => null,
  );

  List<Map<String, dynamic>> _items(dynamic raw) => raw is List
      ? raw
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList()
      : const [];
}

class ExpertDto {
  const ExpertDto({
    required this.id,
    required this.sourceType,
    required this.name,
    required this.category,
    required this.description,
    required this.estimatedCredits,
    required this.source,
  });

  factory ExpertDto.fromJson(Map<String, dynamic> json) => ExpertDto(
    id: (json['id'] ?? json['Id'] ?? '').toString(),
    sourceType: ExpertSourceType.fromApiValue(
      json['CatalogType'] ?? json['catalogType'],
    ),
    name: (json['name'] ?? json['Name'] ?? '').toString(),
    category: (json['category'] ?? json['Category'] ?? '').toString(),
    description: (json['description'] ?? json['Description'] ?? '').toString(),
    estimatedCredits:
        (json['EstimatedCredits'] ?? json['estimatedCredits'] as num?)
            ?.toInt() ??
        0,
    source: ExpertSource.fromApiValue(json['Source'] ?? json['source']),
  );

  final String id;
  final ExpertSourceType sourceType;
  final String name;
  final String category;
  final String description;
  final int estimatedCredits;
  final ExpertSource source;

  Expert toDomain({ExpertSourceType? sourceType}) => Expert(
    id: id,
    sourceType: sourceType ?? this.sourceType,
    name: name,
    category: category,
    description: description,
    estimatedCredits: estimatedCredits,
    source: source,
  );
}

/// B21 类型化详情（§8.2/§8.28）：目录字段 + 编辑字段；RowVersion 详情未列则 null。
class ExpertDetailDto {
  const ExpertDetailDto({
    required this.id,
    required this.sourceType,
    required this.name,
    required this.category,
    required this.description,
    required this.estimatedCredits,
    required this.source,
    this.persona,
    this.methodology,
    this.promptTemplate,
    this.toolPolicy,
    this.outputSchema,
    this.version,
    this.versionId,
    this.rowVersion,
  });

  factory ExpertDetailDto.fromJson(
    Map<String, dynamic> json,
  ) => ExpertDetailDto(
    id: (json['id'] ?? json['Id'] ?? '').toString(),
    sourceType: ExpertSourceType.fromApiValue(
      json['CatalogType'] ?? json['catalogType'],
    ),
    name: (json['name'] ?? json['Name'] ?? '').toString(),
    category: (json['category'] ?? json['Category'] ?? '').toString(),
    description: (json['description'] ?? json['Description'] ?? '').toString(),
    estimatedCredits:
        (json['EstimatedCredits'] ?? json['estimatedCredits'] as num?)
            ?.toInt() ??
        0,
    source: ExpertSource.fromApiValue(json['Source'] ?? json['source']),
    persona: _stringOrNull(json['Persona'] ?? json['persona']),
    methodology: _stringOrNull(json['Methodology'] ?? json['methodology']),
    promptTemplate: _stringOrNull(
      json['PromptTemplate'] ?? json['promptTemplate'],
    ),
    toolPolicy: _stringOrNull(json['ToolPolicy'] ?? json['toolPolicy']),
    outputSchema: _stringOrNull(json['OutputSchema'] ?? json['outputSchema']),
    version: (json['Version'] ?? json['version'] as num?)?.toInt(),
    versionId: (json['VersionId'] ?? json['versionId'] as num?)?.toInt(),
    rowVersion: (json['RowVersion'] ?? json['rowVersion'] as num?)?.toInt(),
  );

  final String id;
  final ExpertSourceType sourceType;
  final String name;
  final String category;
  final String description;
  final int estimatedCredits;
  final ExpertSource source;
  final String? persona;
  final String? methodology;
  final String? promptTemplate;
  final String? toolPolicy;
  final String? outputSchema;
  final int? version;
  final int? versionId;
  final int? rowVersion;

  ExpertDetail toDomain() => ExpertDetail(
    id: id,
    name: name,
    category: category,
    description: description,
    estimatedCredits: estimatedCredits,
    source: source,
    persona: persona,
    methodology: methodology,
    promptTemplate: promptTemplate,
    toolPolicy: toolPolicy,
    outputSchema: outputSchema,
    version: version,
    versionId: versionId,
    rowVersion: rowVersion,
  );
}

String? _stringOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}
