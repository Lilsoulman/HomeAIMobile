import 'dart:convert';

import '../../core/api/api_client.dart';
import 'dto.dart';
import 'expert_run_repository.dart';

class HttpExpertRunRepository implements ExpertRunRepository {
  HttpExpertRunRepository(this._api);

  final ApiClient _api;

  @override
  Future<ExpertRunDto> start({
    required ExpertRunSourceType sourceType,
    required int sourceId,
    required String inputJson,
    required String idempotencyKey,
  }) {
    return _api
        .request<Map<String, dynamic>>(
          method: 'POST',
          path: '/expert-runs',
          body: {
            'sourceType': sourceType.apiValue,
            'sourceId': sourceId,
            'inputJson': inputJson,
            'idempotencyKey': idempotencyKey,
          },
          parseData: _map,
        )
        .then(ExpertRunDto.fromJson);
  }

  @override
  Future<ExpertRunDto> get(int runId) => _api
      .request<Map<String, dynamic>>(
        method: 'GET',
        path: '/expert-runs/$runId',
        parseData: _map,
      )
      .then(ExpertRunDto.fromJson);

  @override
  Future<List<ExpertRunDto>> listRuns({int? expertId, int limit = 10}) async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/expert-runs',
      query: {
        if (expertId != null) 'expertId': expertId,
        'limit': limit,
      },
      parseData: (value) => value,
    );
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ExpertRunDto.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<ExpertRunEventDto>> listEvents(int runId) async {
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/expert-runs/$runId/events',
      parseData: (value) => value,
    );
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ExpertRunEventDto.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<void> cancel(int runId) => _api.request<dynamic>(
    method: 'POST',
    path: '/expert-runs/$runId/cancel',
    parseData: (_) => null,
  );

  @override
  Future<void> retry(int runId) => _api.request<dynamic>(
    method: 'POST',
    path: '/expert-runs/$runId/retry',
    parseData: (_) => null,
  );

  @override
  Future<ExpertRunActionDto> confirmAction({
    required int runId,
    required ExpertRunActionType actionType,
    required String idempotencyKey,
    int? deviceId,
    String? deviceName,
    String? capability,
    Object? targetValue,
    String? spaceName,
    String? actionTitle,
    String? actionDescription,
  }) {
    final body = <String, dynamic>{
      'actionType': actionType.apiValue,
      'idempotencyKey': idempotencyKey,
    };
    if (actionType == ExpertRunActionType.smartHomeDevices) {
      body['requestJson'] = _encodeActionPayload(
        deviceId: deviceId,
        deviceName: deviceName,
        capability: capability,
        targetValue: targetValue,
        spaceName: spaceName,
        actionTitle: actionTitle,
        actionDescription: actionDescription,
      );
    }
    return _api
        .request<Map<String, dynamic>>(
          method: 'POST',
          path: '/expert-runs/$runId/actions',
          body: body,
          parseData: _map,
        )
        .then(ExpertRunActionDto.fromJson);
  }

  static Map<String, dynamic> _map(dynamic raw) =>
      (raw as Map).cast<String, dynamic>();

  String _encodeActionPayload({
    int? deviceId,
    String? deviceName,
    String? capability,
    Object? targetValue,
    String? spaceName,
    String? actionTitle,
    String? actionDescription,
  }) {
    if (deviceId == null &&
        deviceName == null &&
        capability == null &&
        targetValue == null &&
        spaceName == null &&
        actionTitle == null &&
        actionDescription == null) {
      return '{}';
    }
    final payload = <String, dynamic>{};
    if (deviceId != null) payload['deviceId'] = deviceId;
    if (deviceName != null) payload['deviceName'] = deviceName;
    if (capability != null) payload['capability'] = capability;
    if (targetValue != null) payload['targetValue'] = targetValue;
    if (spaceName != null) payload['spaceName'] = spaceName;
    if (actionTitle != null) payload['actionTitle'] = actionTitle;
    if (actionDescription != null) {
      payload['actionDescription'] = actionDescription;
    }
    return jsonEncode(payload);
  }
}
