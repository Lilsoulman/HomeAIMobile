import 'dto.dart';

abstract class LifeExpertRepository {
  /// 探店翻牌（Intent: recommend，只读 L1，无确认动作）。
  Future<LifeRecommendResultDto> recommend({
    required String time,
    required String location,
    required String taste,
    required String idempotencyKey,
  });

  /// 行程规划（Intent: plan）；destination 1-64 字符必填，days 1-7 默认 1。
  Future<LifePlanResultDto> planTrip({
    required String destination,
    required int days,
    required String idempotencyKey,
  });

  /// 确认行程动作（calendar_create_event，L1）；确认前 UI 须展示影响范围，
  /// 提交中禁用按钮并使用新的幂等键；动作已终态返回 409。
  Future<LifePlanActionDto> confirmPlanAction({
    required int runId,
    required int actionId,
    required String idempotencyKey,
  });
}
