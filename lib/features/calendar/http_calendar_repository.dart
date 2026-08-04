// 执行模式 18：Calendar HTTP 实现。

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import 'calendar_repository.dart';
import 'dto.dart';

class HttpCalendarRepository implements CalendarRepository {
  HttpCalendarRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<CalendarEventDto>> listEvents({
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, dynamic>{};
    if (from != null) query['from'] = from.toUtc().toIso8601String();
    if (to != null) query['to'] = to.toUtc().toIso8601String();
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/calendar/events',
      query: query,
      parseData: (raw) => raw,
    );
    return _asList(raw)
        .map(
          (e) => CalendarEventDto.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  @override
  Future<CalendarEventDto> createEvent({
    required String title,
    String? description,
    String? location,
    required DateTime startAt,
    DateTime? endAt,
    String? timezone,
    bool? allDay,
    String? color,
    double? opacity,
    String? repeatRule,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'startAt': startAt.toUtc().toIso8601String(),
    };
    if (description != null) body['description'] = description;
    if (location != null) body['location'] = location;
    if (endAt != null) body['endAt'] = endAt.toUtc().toIso8601String();
    if (timezone != null) body['timezone'] = timezone;
    if (allDay != null) body['allDay'] = allDay;
    if (color != null) body['color'] = color;
    if (opacity != null) body['opacity'] = opacity;
    if (repeatRule != null) body['repeatRule'] = repeatRule;
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/calendar/events',
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return CalendarEventDto.fromJson(json);
  }

  @override
  Future<CalendarEventDto> updateEvent(
    int id,
    Map<String, dynamic> patch,
  ) async {
    final body = <String, dynamic>{};
    if (patch.containsKey('title')) body['title'] = patch['title'];
    if (patch.containsKey('description')) {
      body['description'] = patch['description'];
    }
    if (patch.containsKey('location')) {
      body['location'] = patch['location'];
    }
    if (patch.containsKey('startAt')) {
      final v = patch['startAt'];
      body['startAt'] = v is DateTime ? v.toUtc().toIso8601String() : v;
    }
    if (patch.containsKey('endAt')) {
      final v = patch['endAt'];
      body['endAt'] = v is DateTime ? v.toUtc().toIso8601String() : v;
    }
    if (patch.containsKey('allDay')) body['allDay'] = patch['allDay'];
    if (patch.containsKey('color')) body['color'] = patch['color'];
    if (patch.containsKey('repeatRule')) {
      body['repeatRule'] = patch['repeatRule'];
    }
    final json = await _api.request<Map<String, dynamic>>(
      method: 'PUT',
      path: '/calendar/events/$id',
      body: body,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return CalendarEventDto.fromJson(json);
  }

  @override
  Future<void> deleteEvent(int id) async {
    await _api.request<dynamic>(
      method: 'DELETE',
      path: '/calendar/events/$id',
      parseData: (_) => null,
    );
  }

  @override
  Future<List<CalendarSubscriptionDto>> listSubscriptions() async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/calendar/subscriptions',
      parseData: (raw) => raw,
    );
    return _asList(raw)
        .map(
          (e) => CalendarSubscriptionDto.fromJson(
            (e as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  @override
  Future<CalendarSubscriptionDto> createSubscription({
    required String url,
    String? name,
    bool? enabled,
    int? refreshIntervalMin,
  }) async {
    final body = <String, dynamic>{'url': url};
    if (name != null) body['name'] = name;
    if (enabled != null) body['enabled'] = enabled;
    if (refreshIntervalMin != null) {
      body['refreshIntervalMin'] = refreshIntervalMin;
    }
    final raw = await _api.request<dynamic>(
      method: 'POST',
      path: '/calendar/subscriptions',
      body: body,
      parseData: (raw) => raw,
    );
    if (raw is! Map) {
      throw ApiException(-1, '订阅创建失败：后端未返回订阅详情');
    }
    return CalendarSubscriptionDto.fromJson(raw.cast<String, dynamic>());
  }

  @override
  Future<CalendarSubscriptionDto> updateSubscription(
    int id,
    Map<String, dynamic> patch,
  ) async {
    final body = <String, dynamic>{};
    if (patch.containsKey('name')) body['name'] = patch['name'];
    if (patch.containsKey('enabled')) body['enabled'] = patch['enabled'];
    if (patch.containsKey('refreshIntervalMin')) {
      body['refreshIntervalMin'] = patch['refreshIntervalMin'];
    }
    final raw = await _api.request<dynamic>(
      method: 'PUT',
      path: '/calendar/subscriptions/$id',
      body: body,
      parseData: (raw) => raw,
    );
    if (raw is! Map) {
      throw ApiException(-1, '订阅更新失败：后端未返回订阅详情');
    }
    return CalendarSubscriptionDto.fromJson(raw.cast<String, dynamic>());
  }

  @override
  Future<void> deleteSubscription(int id) async {
    await _api.request<dynamic>(
      method: 'DELETE',
      path: '/calendar/subscriptions/$id',
      parseData: (_) => null,
    );
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['items'] is List) return raw['items'] as List;
    return const [];
  }
}
