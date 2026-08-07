import '../../core/api/api_client.dart';
import 'conversation_repository.dart';
import 'dto.dart';

class HttpConversationRepository implements ConversationRepository {
  HttpConversationRepository(this._api);

  final ApiClient _api;

  @override
  Future<ConversationPageDto> listConversations({
    int limit = 20,
    String? cursor,
  }) {
    return _api
        .request<Map<String, dynamic>>(
          method: 'GET',
          path: '/conversations',
          query: {'limit': limit, 'cursor': ?cursor},
          parseData: _map,
        )
        .then(ConversationPageDto.fromJson);
  }

  @override
  Future<ConversationDto> createConversation({String? title, int? expertId}) {
    final body = <String, dynamic>{
      if (title != null && title.isNotEmpty) 'title': title,
      'expertId': ?expertId,
    };
    return _api
        .request<Map<String, dynamic>>(
          method: 'POST',
          path: '/conversations',
          body: body,
          parseData: _map,
        )
        .then(ConversationDto.fromJson);
  }

  @override
  Future<ConversationDto> updateConversation({
    required int id,
    String? title,
    int? expertId,
    required int rowVersion,
  }) {
    return _api
        .request<Map<String, dynamic>>(
          method: 'PUT',
          path: '/conversations/$id',
          body: {
            if (title != null && title.isNotEmpty) 'title': title,
            // 解绑语义要求显式传 null（不能用 null-aware marker 省略 key）。
            'expertId': expertId,
            'workspaceConnectorId': null,
            'rowVersion': rowVersion,
          },
          parseData: _map,
        )
        .then(ConversationDto.fromJson);
  }

  @override
  Future<void> deleteConversation(int id) => _api.request<dynamic>(
    method: 'DELETE',
    path: '/conversations/$id',
    parseData: (_) => null,
  );

  @override
  Future<MessagePageDto> listMessages({
    required int conversationId,
    int limit = 20,
    String? cursor,
  }) {
    return _api
        .request<Map<String, dynamic>>(
          method: 'GET',
          path: '/conversations/$conversationId/messages',
          query: {'limit': limit, 'cursor': ?cursor},
          parseData: _map,
        )
        .then(MessagePageDto.fromJson);
  }

  @override
  Future<SendMessageResultDto> sendMessage({
    required int conversationId,
    required String content,
    required String idempotencyKey,
  }) {
    return _api
        .request<Map<String, dynamic>>(
          method: 'POST',
          path: '/conversations/$conversationId/messages',
          body: {'content': content, 'idempotencyKey': idempotencyKey},
          parseData: _map,
        )
        .then(SendMessageResultDto.fromJson);
  }

  static Map<String, dynamic> _map(dynamic raw) =>
      (raw as Map).cast<String, dynamic>();
}
