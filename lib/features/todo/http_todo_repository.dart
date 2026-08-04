// 执行模式 15：Todo HTTP 实现。

import '../../../core/api/api_client.dart';
import 'dto.dart';
import 'todo_repository.dart';

class HttpTodoRepository implements TodoRepository {
  HttpTodoRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<TodoDto>> list({
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (from != null) query['from'] = from.toUtc().toIso8601String();
    if (to != null) query['to'] = to.toUtc().toIso8601String();
    final json = await _api.request<dynamic>(
      method: 'GET',
      path: '/todos',
      query: query,
      parseData: (raw) => raw,
    );
    return _asList(
      json,
    ).map((e) => TodoDto.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<TodoDto> create({
    required String title,
    String? description,
    String? type,
    String? priority,
    String? color,
    String? status,
    DateTime? dueAt,
    DateTime? remindAt,
    bool? pinned,
    int? sortOrder,
    String? repeatRule,
    int? parentId,
  }) async {
    final body = <String, dynamic>{'title': title};
    if (description != null) body['description'] = description;
    if (type != null) body['type'] = type;
    if (priority != null) body['priority'] = priority;
    if (color != null) body['color'] = color;
    if (status != null) body['status'] = status;
    if (dueAt != null) body['dueAt'] = dueAt.toUtc().toIso8601String();
    if (remindAt != null) body['remindAt'] = remindAt.toUtc().toIso8601String();
    if (pinned != null) body['pinned'] = pinned;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    if (repeatRule != null) body['repeatRule'] = repeatRule;
    if (parentId != null) body['parentId'] = parentId;
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/todos',
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return TodoDto.fromJson(json);
  }

  @override
  Future<TodoDto> update(int id, Map<String, dynamic> patch) async {
    final body = <String, dynamic>{};
    if (patch.containsKey('title')) body['title'] = patch['title'];
    if (patch.containsKey('description')) {
      body['description'] = patch['description'];
    }
    if (patch.containsKey('type')) body['type'] = patch['type'];
    if (patch.containsKey('status')) body['status'] = patch['status'];
    if (patch.containsKey('dueAt')) {
      final v = patch['dueAt'];
      body['dueAt'] = v is DateTime ? v.toUtc().toIso8601String() : v;
    }
    if (patch.containsKey('remindAt')) {
      final v = patch['remindAt'];
      body['remindAt'] = v is DateTime ? v.toUtc().toIso8601String() : v;
    }
    if (patch.containsKey('pinned')) body['pinned'] = patch['pinned'];
    if (patch.containsKey('priority')) body['priority'] = patch['priority'];
    if (patch.containsKey('color')) body['color'] = patch['color'];
    if (patch.containsKey('sortOrder')) {
      body['sortOrder'] = patch['sortOrder'];
    }
    if (patch.containsKey('repeatRule')) {
      body['repeatRule'] = patch['repeatRule'];
    }
    if (patch.containsKey('parentId')) body['parentId'] = patch['parentId'];
    final json = await _api.request<Map<String, dynamic>>(
      method: 'PUT',
      path: '/todos/$id',
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return TodoDto.fromJson(json);
  }

  @override
  Future<void> delete(int id) async {
    await _api.request<dynamic>(
      method: 'DELETE',
      path: '/todos/$id',
      parseData: (_) => null,
    );
  }

  @override
  Future<List<SubtaskDto>> listSubtasks(int todoId) async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/todos/$todoId/subtasks',
      parseData: (raw) => raw,
    );
    return _asList(raw)
        .map(
          (item) => SubtaskDto.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  @override
  Future<SubtaskDto> addSubtask(
    int todoId, {
    required String text,
    int? seq,
  }) async {
    final body = <String, dynamic>{'text': text};
    if (seq != null) body['seq'] = seq;
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/todos/$todoId/subtasks',
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return SubtaskDto.fromJson(json);
  }

  @override
  Future<SubtaskDto> updateSubtask(
    int todoId,
    int subId,
    Map<String, dynamic> patch,
  ) async {
    final body = <String, dynamic>{};
    if (patch.containsKey('text')) body['text'] = patch['text'];
    if (patch.containsKey('done')) body['done'] = patch['done'];
    if (patch.containsKey('seq')) body['seq'] = patch['seq'];
    final json = await _api.request<Map<String, dynamic>>(
      method: 'PUT',
      path: '/todos/$todoId/subtasks/$subId',
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return SubtaskDto.fromJson(json);
  }

  @override
  Future<void> deleteSubtask(int todoId, int subId) async {
    await _api.request<dynamic>(
      method: 'DELETE',
      path: '/todos/$todoId/subtasks/$subId',
      parseData: (_) => null,
    );
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['items'] is List) return raw['items'] as List;
    return const [];
  }
}
