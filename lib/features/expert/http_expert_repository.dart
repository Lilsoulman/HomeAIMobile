import '../../core/api/api_client.dart';
import '../../experts/domain.dart';
import '../../experts/expert_repository.dart';

class HttpExpertRepository implements ExpertRepository {
  HttpExpertRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Expert>> listExperts({String query = ''}) async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/experts',
      query: query.trim().isEmpty ? const {} : {'query': query.trim()},
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
  );

  final String id;
  final ExpertSourceType sourceType;
  final String name;
  final String category;
  final String description;
  final int estimatedCredits;

  Expert toDomain({ExpertSourceType? sourceType}) => Expert(
    id: id,
    sourceType: sourceType ?? this.sourceType,
    name: name,
    category: category,
    description: description,
    estimatedCredits: estimatedCredits,
  );
}
