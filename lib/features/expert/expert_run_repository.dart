import 'dto.dart';

abstract class ExpertRunRepository {
  Future<ExpertRunDto> start({
    required ExpertRunSourceType sourceType,
    required int sourceId,
    required String inputJson,
    required String idempotencyKey,
  });

  Future<ExpertRunDto> get(int runId);

  /// 列出当前用户的运行记录，可按专家与来源筛选。
  Future<List<ExpertRunDto>> listRuns({int? expertId, int limit = 10});

  Future<List<ExpertRunEventDto>> listEvents(int runId);

  Future<void> cancel(int runId);

  Future<void> retry(int runId);

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
  });
}
