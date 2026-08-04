import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/experts/domain.dart';
import 'package:nexus_mind_mobile/experts/mock_expert_repository.dart';
import 'package:nexus_mind_mobile/features/expert/dto.dart';
import 'package:nexus_mind_mobile/features/expert/local_expert_run_repository.dart';

void main() {
  test('家庭管家可按目录查询并保留专家类型', () async {
    final repository = MockExpertRepository();

    final experts = await repository.listExperts(query: '家庭');
    final expert = await repository.getExpert(
      '1',
      sourceType: ExpertSourceType.expert,
    );

    expect(experts, hasLength(1));
    expect(expert!.name, '家庭管家');
    expect(expert.estimatedCredits, 1);
  });

  test('本地运行在终态停止并仅产生可展示进度', () async {
    final repository = LocalExpertRunRepository();
    final created = await repository.start(
      sourceType: ExpertRunSourceType.expert,
      sourceId: 1,
      inputJson: '{"request":"安排晚间计划"}',
      idempotencyKey: 'run-1',
    );

    final running = await repository.get(created.id);
    final completed = await repository.get(created.id);
    final events = await repository.listEvents(created.id);

    expect(created.status, ExpertRunStatus.queued);
    expect(running.status, ExpertRunStatus.running);
    expect(completed.status, ExpertRunStatus.completed);
    expect(completed.status.isTerminal, isTrue);
    expect(events.map((event) => event.displayText), everyElement(isNotNull));
  });

  test('仅完成的运行可确认一次行动', () async {
    final repository = LocalExpertRunRepository();
    final run = await repository.start(
      sourceType: ExpertRunSourceType.expert,
      sourceId: 1,
      inputJson: '{}',
      idempotencyKey: 'run-2',
    );
    await repository.get(run.id);
    await repository.get(run.id);

    final action = await repository.confirmAction(
      runId: run.id,
      actionType: ExpertRunActionType.todos,
      idempotencyKey: 'action-1',
    );

    expect(action.status, 'completed');
  });

  test('本地设备行动可确认，并按幂等键复用结果', () async {
    final repository = LocalExpertRunRepository();
    final run = await repository.start(
      sourceType: ExpertRunSourceType.expert,
      sourceId: 1,
      inputJson: '{}',
      idempotencyKey: 'device-run',
    );
    await repository.get(run.id);
    final completed = await repository.get(run.id);
    final proposedAction = completed.actions.single;

    final first = await repository.confirmAction(
      runId: run.id,
      actionType: ExpertRunActionType.smartHomeDevices,
      idempotencyKey: 'device-action',
      deviceId: proposedAction.deviceId,
    );
    final repeated = await repository.confirmAction(
      runId: run.id,
      actionType: ExpertRunActionType.smartHomeDevices,
      idempotencyKey: 'device-action',
      deviceId: proposedAction.deviceId,
    );

    expect(first.status, 'completed');
    expect(repeated.id, first.id);
    expect((await repository.get(run.id)).actions.single.status, 'completed');
  });
}
