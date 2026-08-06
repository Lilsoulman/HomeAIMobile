// 出行推荐 HTTP 实现：GET/POST /api/v1/travel/recommendations。

import '../../../core/api/api_client.dart';
import 'travel_repository.dart';

class HttpTravelRepository implements TravelRepository {
  HttpTravelRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<TravelRecommendationDto>> getRecommendations() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/travel/recommendations',
      parseData: (value) => value,
    );
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) =>
              TravelRecommendationDto.fromJson(item.cast<String, dynamic>()),
        )
        .toList();
  }

  @override
  Future<void> submitFeedback(int attractionId, String choice) async {
    await _api.request<dynamic>(
      method: 'POST',
      path: '/travel/recommendations/$attractionId/feedback',
      body: {'choice': choice},
      parseData: (_) => null,
    );
  }
}
