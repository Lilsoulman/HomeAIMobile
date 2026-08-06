// 知识条目 HTTP 实现：GET/POST/DELETE /api/v1/knowledge-items。

import '../../../core/api/api_client.dart';
import 'knowledge_repository.dart';

class HttpKnowledgeRepository implements KnowledgeRepository {
  HttpKnowledgeRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<KnowledgeItemDto>> list({String? category}) async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/knowledge-items',
      query: {if (category != null) 'category': category},
      parseData: (value) => value,
    );
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => KnowledgeItemDto.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<void> create({
    required String category,
    required String title,
    required String content,
    String? source,
  }) async {
    await _api.request<dynamic>(
      method: 'POST',
      path: '/knowledge-items',
      body: {
        'category': category,
        'title': title,
        'content': content,
        if (source != null) 'source': source,
      },
      parseData: (_) => null,
    );
  }

  @override
  Future<void> delete(int id) async {
    await _api.request<dynamic>(
      method: 'DELETE',
      path: '/knowledge-items/$id',
      parseData: (_) => null,
    );
  }
}
