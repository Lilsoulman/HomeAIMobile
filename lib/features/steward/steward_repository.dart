// P2 家庭协同数据层：Steward 仓储接口（管家动态 / 确认中心）。

import 'dto.dart';

abstract class StewardRepository {
  Future<StewardActivityPageDto> listActivities({
    int limit = 20,
    String? cursor,
  });

  Future<StewardActivityDto> getActivity(int id);

  Future<StewardActivityDto> undoActivity(int id);

  Future<List<ConfirmationItemDto>> listConfirmations({
    String? riskLevel,
    String? status,
  });

  Future<ConfirmationItemDto> confirm(int id, {required String idempotencyKey});

  Future<ConfirmationItemDto> deny(int id, {required String reason});

  Future<ConfirmationBatchResultDto> batchConfirm(
    List<int> confirmationIds, {
    required String idempotencyKey,
  });
}
