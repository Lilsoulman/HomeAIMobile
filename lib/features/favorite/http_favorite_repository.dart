// P5b 个人偏好收藏：HTTP 实现（后端 §8.20，B15 发布）。
// 家庭归属由 JWT 推导，客户端不得发送家庭 ID；跨家庭与越权访问一律 404。

import '../../../core/api/api_client.dart';
import 'dto.dart';
import 'favorite_repository.dart';

class HttpFavoriteRepository implements FavoriteRepository {
  HttpFavoriteRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<FavoriteDto>> list({String? category, String? visibility}) async {
    final query = <String, dynamic>{};
    if (category != null) query['category'] = category;
    if (visibility != null) query['visibility'] = visibility;
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/life/favorites',
      query: query,
      parseData: (raw) => raw,
    );
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((entry) => FavoriteDto.fromJson(entry.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<FavoriteDto> create({
    required FavoriteCategory category,
    required String name,
    String? detailJson,
    FavoriteVisibility visibility = FavoriteVisibility.private,
  }) => _write(
    'POST',
    '/life/favorites',
    body: {
      'category': category.apiValue,
      'name': name,
      'detailJson': ?detailJson,
      'visibility': visibility.apiValue,
    },
  );

  @override
  Future<FavoriteDto> update(
    int id, {
    required FavoriteCategory category,
    required String name,
    String? detailJson,
    required FavoriteVisibility visibility,
  }) => _write(
    'PUT',
    '/life/favorites/$id',
    body: {
      'category': category.apiValue,
      'name': name,
      'detailJson': ?detailJson,
      'visibility': visibility.apiValue,
    },
  );

  @override
  Future<void> delete(int id) => _api.request<dynamic>(
    method: 'DELETE',
    path: '/life/favorites/$id',
    parseData: (_) => null,
  );

  @override
  Future<FavoriteDto> import({
    required FavoriteCategory category,
    required String name,
    String? detailJson,
    FavoriteVisibility visibility = FavoriteVisibility.private,
    required String source,
    String? conversationText,
  }) => _write(
    'POST',
    '/life/favorites/import',
    body: {
      'category': category.apiValue,
      'name': name,
      'detailJson': ?detailJson,
      'visibility': visibility.apiValue,
      'source': source,
      'conversationText': ?conversationText,
    },
  );

  Future<FavoriteDto> _write(
    String method,
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final json = await _api.request<Map<String, dynamic>>(
      method: method,
      path: path,
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return FavoriteDto.fromJson(json);
  }
}
