// 出行推荐仓储接口：周末自然出行推荐与三选一反馈。

class TravelRecommendationDto {
  const TravelRecommendationDto({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.durationHours,
    required this.costLevel,
    this.weatherTag,
    this.tags = const [],
    this.description,
    this.reason,
  });

  factory TravelRecommendationDto.fromJson(
    Map<String, dynamic> json,
  ) => TravelRecommendationDto(
    id: (json['Id'] ?? json['id'] as num?)?.toInt() ?? 0,
    name: (json['Name'] ?? json['name'] ?? '').toString(),
    city: (json['City'] ?? json['city'] ?? '').toString(),
    category: (json['Category'] ?? json['category'] ?? '').toString(),
    durationHours:
        (json['DurationHours'] ?? json['durationHours'] as num?)?.toDouble() ??
        0,
    costLevel: (json['CostLevel'] ?? json['costLevel'] as num?)?.toInt() ?? 1,
    weatherTag: (json['WeatherTag'] ?? json['weatherTag'])?.toString(),
    tags: _asStringList(json['Tags'] ?? json['tags']),
    description: (json['Description'] ?? json['description'])?.toString(),
    reason: (json['Reason'] ?? json['reason'])?.toString(),
  );

  final int id;
  final String name;
  final String city;
  final String category;
  final double durationHours;
  final int costLevel;
  final String? weatherTag;
  final List<String> tags;
  final String? description;
  final String? reason;
}

List<String> _asStringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

abstract class TravelRepository {
  Future<List<TravelRecommendationDto>> getRecommendations();
  Future<void> submitFeedback(int attractionId, String choice);
}
