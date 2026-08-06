// P2 家庭协同数据层：Steward HTTP 实现。
// 路由 `api/v1/homes/{homeId}/activities|confirmations`；homeId 必须等于 JWT tenant_id，由服务端校验。

import '../../../core/api/api_client.dart';
import 'dto.dart';
import 'steward_repository.dart';

class HttpStewardRepository implements StewardRepository {
  HttpStewardRepository(this._api, {required this.homeIdOf});

  final ApiClient _api;
  final int Function() homeIdOf;

  int get _homeId => homeIdOf();

  @override
  Future<StewardActivityPageDto> listActivities({
    int limit = 20,
    String? cursor,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (cursor != null) query['cursor'] = cursor;
    final json = await _api.request<Map<String, dynamic>>(
      method: 'GET',
      path: '/homes/$_homeId/activities',
      query: query,
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return StewardActivityPageDto.fromJson(json);
  }

  @override
  Future<StewardActivityDto> getActivity(int id) async {
    final json = await _api.request<Map<String, dynamic>>(
      method: 'GET',
      path: '/homes/$_homeId/activities/$id',
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return StewardActivityDto.fromJson(json);
  }

  @override
  Future<StewardActivityDto> undoActivity(int id) async {
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/homes/$_homeId/activities/$id/undo',
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return StewardActivityDto.fromJson(json);
  }

  @override
  Future<List<ConfirmationItemDto>> listConfirmations({
    String? riskLevel,
    String? status,
  }) async {
    final query = <String, dynamic>{};
    if (riskLevel != null) query['riskLevel'] = riskLevel;
    if (status != null) query['status'] = status;
    final raw = await _api.request<dynamic>(
      method: 'GET',
      path: '/homes/$_homeId/confirmations',
      query: query,
      parseData: (raw) => raw,
    );
    return _asList(raw)
        .map(
          (entry) => ConfirmationItemDto.fromJson(
            (entry as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  @override
  Future<ConfirmationItemDto> confirm(
    int id, {
    required String idempotencyKey,
  }) async {
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/homes/$_homeId/confirmations/$id/confirm',
      body: {'idempotencyKey': idempotencyKey},
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return ConfirmationItemDto.fromJson(json);
  }

  @override
  Future<ConfirmationItemDto> deny(int id, {required String reason}) async {
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/homes/$_homeId/confirmations/$id/deny',
      body: {'reason': reason},
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return ConfirmationItemDto.fromJson(json);
  }

  @override
  Future<ConfirmationBatchResultDto> batchConfirm(
    List<int> confirmationIds, {
    required String idempotencyKey,
  }) async {
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/homes/$_homeId/confirmations/batch-confirm',
      body: {
        'confirmationIds': confirmationIds,
        'idempotencyKey': idempotencyKey,
      },
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return ConfirmationBatchResultDto.fromJson(json);
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['items'] is List) return raw['items'] as List;
    return const [];
  }
}
