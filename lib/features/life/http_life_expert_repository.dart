// P5c 个人生活专家：HTTP 实现（后端 §8.21 翻牌 / §8.22 行程，B16/B17 发布）。
// 两个端点均同步返回结果；幂等键由调用方生成（每次新键，确认复用同键可重入恢复）。

import 'dart:convert';

import '../../../core/api/api_client.dart';
import 'dto.dart';
import 'life_expert_repository.dart';

class HttpLifeExpertRepository implements LifeExpertRepository {
  HttpLifeExpertRepository(this._api);

  static const _runsPath = '/experts/personal-life-expert/runs';

  final ApiClient _api;

  @override
  Future<LifeRecommendResultDto> recommend({
    required String time,
    required String location,
    required String taste,
    required String idempotencyKey,
  }) async {
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: _runsPath,
      body: {
        'Intent': 'recommend',
        'InputJson': jsonEncode({
          'time': time,
          'location': location,
          'taste': taste,
        }),
        'IdempotencyKey': idempotencyKey,
      },
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return LifeRecommendResultDto.fromJson(json);
  }

  @override
  Future<LifePlanResultDto> planTrip({
    required String destination,
    required int days,
    required String idempotencyKey,
  }) async {
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: _runsPath,
      body: {
        'Intent': 'plan',
        'InputJson': jsonEncode({'destination': destination, 'days': days}),
        'IdempotencyKey': idempotencyKey,
      },
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return LifePlanResultDto.fromJson(json);
  }

  @override
  Future<LifePlanActionDto> confirmPlanAction({
    required int runId,
    required int actionId,
    required String idempotencyKey,
  }) async {
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '$_runsPath/$runId/actions/$actionId/confirm',
      body: {'IdempotencyKey': idempotencyKey},
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return LifePlanActionDto.fromJson(json);
  }
}
