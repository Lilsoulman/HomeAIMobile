import 'dto.dart';
import 'expert_run_repository.dart';

class LocalExpertRunRepository implements ExpertRunRepository {
  final Map<int, _StoredRun> _runs = {};
  final Map<int, ExpertRunActionDto> _actions = {};
  final Map<String, int> _runIdsByIdempotencyKey = {};
  final Map<String, int> _actionIdsByIdempotencyKey = {};
  int _nextId = 1;
  int _nextActionId = 1;

  @override
  Future<ExpertRunDto> start({
    required ExpertRunSourceType sourceType,
    required int sourceId,
    required String inputJson,
    required String idempotencyKey,
  }) async {
    final existingRunId = _runIdsByIdempotencyKey[idempotencyKey];
    if (existingRunId != null) return _required(existingRunId).snapshot();
    final now = DateTime.now();
    final stored = _StoredRun(
      id: _nextId++,
      sourceType: sourceType,
      sourceId: sourceId,
      createdAt: now,
      mode: sourceType == ExpertRunSourceType.group ? 'team' : 'single',
      inputJson: inputJson,
    );
    _runs[stored.id] = stored;
    _runIdsByIdempotencyKey[idempotencyKey] = stored.id;
    stored.pendingDeviceAction = const ExpertRunActionDto(
      id: 0,
      status: 'pending',
      actionType: ExpertRunActionType.smartHomeDevices,
      deviceId: 34,
      deviceName: '卧室主灯',
      capability: 'power',
      targetValue: false,
      spaceName: '主卧',
      actionTitle: '关闭卧室照明',
      actionDescription: '睡眠准备建议关闭卧室照明。',
    );
    return stored.snapshot();
  }

  @override
  Future<ExpertRunDto> get(int runId) async {
    final run = _required(runId);
    if (run.status == ExpertRunStatus.queued) {
      run.status = ExpertRunStatus.running;
      run.startedAt = DateTime.now();
    } else if (run.status == ExpertRunStatus.running) {
      run.status = ExpertRunStatus.completed;
      run.finishedAt = DateTime.now();
      if (run.pendingDeviceAction != null && run.pendingDeviceAction!.id == 0) {
        final actionId = _nextActionId++;
        final action = ExpertRunActionDto(
          id: actionId,
          status: 'pending',
          actionType: run.pendingDeviceAction!.actionType,
          deviceId: run.pendingDeviceAction!.deviceId,
          deviceName: run.pendingDeviceAction!.deviceName,
          capability: run.pendingDeviceAction!.capability,
          targetValue: run.pendingDeviceAction!.targetValue,
          spaceName: run.pendingDeviceAction!.spaceName,
          actionTitle: run.pendingDeviceAction!.actionTitle,
          actionDescription: run.pendingDeviceAction!.actionDescription,
        );
        _actions[actionId] = action;
        run.pendingDeviceAction = action;
      }
    }
    return run.snapshot();
  }

  @override
  Future<List<ExpertRunEventDto>> listEvents(int runId) async {
    final run = _required(runId);
    final events = <ExpertRunEventDto>[
      ExpertRunEventDto(
        id: 1,
        sequence: 1,
        eventType: 'queued',
        createdAt: run.createdAt,
      ),
    ];
    if (run.startedAt != null) {
      events.add(
        ExpertRunEventDto(
          id: 2,
          sequence: 2,
          eventType: 'planning',
          createdAt: run.startedAt!,
        ),
      );
    }
    if (run.status == ExpertRunStatus.completed) {
      events.add(
        ExpertRunEventDto(
          id: 3,
          sequence: 3,
          eventType: 'completed',
          createdAt: run.finishedAt!,
        ),
      );
    }
    if (run.status == ExpertRunStatus.cancelled) {
      events.add(
        ExpertRunEventDto(
          id: 4,
          sequence: 3,
          eventType: 'cancelled',
          createdAt: run.finishedAt!,
        ),
      );
    }
    return events;
  }

  @override
  Future<void> cancel(int runId) async {
    final run = _required(runId);
    if (!run.status.isTerminal) {
      run.status = ExpertRunStatus.cancelled;
      run.finishedAt = DateTime.now();
    }
  }

  @override
  Future<void> retry(int runId) async {
    final run = _required(runId);
    if (run.status == ExpertRunStatus.failed ||
        run.status == ExpertRunStatus.cancelled) {
      run.status = ExpertRunStatus.queued;
      run.startedAt = null;
      run.finishedAt = null;
    }
  }

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
  }) async {
    final run = _required(runId);
    final actionKey = '$runId:$idempotencyKey';
    final existingActionId = _actionIdsByIdempotencyKey[actionKey];
    if (existingActionId != null) return _actions[existingActionId]!;
    if (run.status != ExpertRunStatus.completed) {
      throw StateError('建议尚未生成，暂不能确认。');
    }
    if (actionType == ExpertRunActionType.smartHomeDevices) {
      final draft = run.pendingDeviceAction;
      if (draft != null && draft.id > 0) {
        final executed = ExpertRunActionDto(
          id: draft.id,
          status: 'completed',
          actionType: draft.actionType,
          deviceId: deviceId ?? draft.deviceId,
          deviceName: deviceName ?? draft.deviceName,
          capability: capability ?? draft.capability,
          targetValue: targetValue ?? draft.targetValue,
          spaceName: spaceName ?? draft.spaceName,
          actionTitle: actionTitle ?? draft.actionTitle,
          actionDescription: actionDescription ?? draft.actionDescription,
        );
        _actions[draft.id] = executed;
        _actionIdsByIdempotencyKey[actionKey] = draft.id;
        run.pendingDeviceAction = executed;
        return executed;
      }
      final id = _nextActionId++;
      final action = ExpertRunActionDto(
        id: id,
        status: 'completed',
        actionType: actionType,
        deviceId: deviceId,
        deviceName: deviceName,
        capability: capability,
        targetValue: targetValue,
        spaceName: spaceName,
        actionTitle: actionTitle,
        actionDescription: actionDescription,
      );
      _actions[id] = action;
      _actionIdsByIdempotencyKey[actionKey] = id;
      return action;
    }
    final id = _nextActionId++;
    final action = ExpertRunActionDto(
      id: id,
      status: 'completed',
      actionType: actionType,
    );
    _actions[id] = action;
    _actionIdsByIdempotencyKey[actionKey] = id;
    return action;
  }

  _StoredRun _required(int runId) {
    final run = _runs[runId];
    if (run == null) throw StateError('未找到运行记录');
    return run;
  }
}

class _StoredRun {
  _StoredRun({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.createdAt,
    required this.mode,
    required this.inputJson,
  });

  final int id;
  final ExpertRunSourceType sourceType;
  final int sourceId;
  final DateTime createdAt;
  final String mode;
  final String inputJson;
  ExpertRunStatus status = ExpertRunStatus.queued;
  DateTime? startedAt;
  DateTime? finishedAt;
  ExpertRunActionDto? pendingDeviceAction;

  ExpertRunDto snapshot() => ExpertRunDto(
    id: id,
    sourceType: sourceType,
    status: status,
    resultSummary: status == ExpertRunStatus.completed
        ? '已生成一份可由你确认后落实的家庭建议。'
        : null,
    estimatedCredits: 1,
    actualCredits: status == ExpertRunStatus.completed ? 1 : null,
    createdAt: createdAt,
    startedAt: startedAt,
    finishedAt: finishedAt,
    mode: mode,
    inputJson: inputJson,
    actions: pendingDeviceAction == null ? const [] : [pendingDeviceAction!],
  );
}
