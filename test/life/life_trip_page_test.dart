// P5c 行程规划页：目的地校验 / 生成与影响范围展示 / 确认提交（幂等键、禁用中）/
// runId 缺失禁用确认 / 错误重试。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/life/dto.dart';
import 'package:nexus_mind_mobile/features/life/life_expert_repository.dart';
import 'package:nexus_mind_mobile/pages/life_trip_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('requires destination', (tester) async {
    final stub = _StubLifeRepo(
      planResult: _planResult(runId: 7, actionCount: 1),
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.text('生成行程'));
    await tester.pump();

    expect(find.text('请填写目的地（1-64 字符）'), findsOneWidget);
    expect(stub.planCalls, isEmpty);
  });

  testWidgets('generates plan and shows impact scope', (tester) async {
    final stub = _StubLifeRepo(
      planResult: _planResult(runId: 7, actionCount: 2),
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, '目的地（1-64 字符）'),
      '杭州',
    );
    await tester.tap(find.text('生成行程'));
    await tester.pump();
    await tester.pump();

    expect(stub.planCalls, hasLength(1));
    expect(stub.planCalls.single.$1, '杭州');
    expect(stub.planCalls.single.$2, 1);
    expect(find.text('杭州 行程 D1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('杭州 行程 D2'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('杭州 行程 D2'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('确认并同步日历'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('确认并同步日历'));
    await tester.pump();
    expect(
      find.text('确认后将在日历创建 2 个事件（标题：杭州 行程 D1-D2），每个事件对应一天行程。'),
      findsOneWidget,
    );
    expect(find.text('L1'), findsNWidgets(2));
    expect(find.text('确认并同步日历'), findsOneWidget);
  });

  testWidgets(
    'confirm posts each action with a fresh idempotency key and disables button',
    (tester) async {
      final stub = _StubLifeRepo(
        planResult: _planResult(runId: 7, actionCount: 2),
      );

      await tester.pumpWidget(_wrap(stub));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, '目的地（1-64 字符）'),
        '杭州',
      );
      await tester.tap(find.text('生成行程'));
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('确认并同步日历'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('确认并同步日历'));
      await tester.pump();
      await tester.tap(find.text('确认并同步日历'));
      await tester.pump();
      await tester.pump();

      expect(stub.confirmCalls, hasLength(2));
      expect(stub.confirmCalls[0].$1, 7);
      expect(stub.confirmCalls[0].$2, 11);
      expect(stub.confirmCalls[1].$1, 7);
      expect(stub.confirmCalls[1].$2, 12);
      expect(stub.confirmKeys[0], isNot(stub.confirmKeys[1]));
      expect(find.text('已同步到日历'), findsWidgets);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '已同步到日历'),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('disables confirm when run id is missing', (tester) async {
    final stub = _StubLifeRepo(
      planResult: _planResult(runId: 0, actionCount: 1),
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, '目的地（1-64 字符）'),
      '杭州',
    );
    await tester.tap(find.text('生成行程'));
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('确认并同步日历'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('确认并同步日历'));
    await tester.pump();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '确认并同步日历'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('shows error when confirm fails', (tester) async {
    final stub = _StubLifeRepo(
      planResult: _planResult(runId: 7, actionCount: 1),
      failConfirm: true,
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, '目的地（1-64 字符）'),
      '杭州',
    );
    await tester.tap(find.text('生成行程'));
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('确认并同步日历'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('确认并同步日历'));
    await tester.pump();
    await tester.tap(find.text('确认并同步日历'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('同步失败'), findsOneWidget);
  });

  testWidgets('shows plan error and retries', (tester) async {
    final stub = _StubLifeRepo(
      planResult: _planResult(runId: 7, actionCount: 1),
      failPlan: true,
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, '目的地（1-64 字符）'),
      '杭州',
    );
    await tester.tap(find.text('生成行程'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('生成失败'), findsOneWidget);

    stub.failPlan = false;
    await tester.scrollUntilVisible(
      find.text('重试'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('重试'));
    await tester.pump();
    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump();

    expect(find.text('杭州 行程 D1'), findsOneWidget);
  });
}

Widget _wrap(LifeExpertRepository repository) =>
    Provider<LifeExpertRepository>.value(
      value: repository,
      child: MaterialApp(
        theme: NexusTheme.light(NexusPalette.aiAccent),
        home: const LifeTripPage(),
      ),
    );

LifePlanResultDto _planResult({required int runId, required int actionCount}) =>
    LifePlanResultDto(
      runId: runId,
      status: 'pending_actions',
      resultSummary: '$actionCount 天行程已生成',
      actions: [
        for (var i = 1; i <= actionCount; i++)
          LifePlanActionDto(
            id: 10 + i,
            actionType: 'calendar_create_event',
            status: 'pending',
            title: '杭州 行程 D$i',
            description: '第 $i 天：西湖漫步',
            riskLevel: 'L1',
          ),
      ],
    );

class _StubLifeRepo implements LifeExpertRepository {
  _StubLifeRepo({
    this.planResult,
    this.failPlan = false,
    this.failConfirm = false,
  });

  final LifePlanResultDto? planResult;
  bool failPlan;
  bool failConfirm;
  final planCalls = <(String, int)>[];
  final planKeys = <String>[];
  final confirmCalls = <(int, int)>[];
  final confirmKeys = <String>[];

  @override
  Future<LifeRecommendResultDto> recommend({
    required String time,
    required String location,
    required String taste,
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<LifePlanResultDto> planTrip({
    required String destination,
    required int days,
    required String idempotencyKey,
  }) async {
    planCalls.add((destination, days));
    planKeys.add(idempotencyKey);
    if (failPlan) throw StateError('生成失败');
    return planResult ?? LifePlanResultDto(runId: 0, status: 'pending_actions');
  }

  @override
  Future<LifePlanActionDto> confirmPlanAction({
    required int runId,
    required int actionId,
    required String idempotencyKey,
  }) async {
    confirmCalls.add((runId, actionId));
    confirmKeys.add(idempotencyKey);
    if (failConfirm) throw StateError('同步失败');
    return LifePlanActionDto(
      id: actionId,
      actionType: 'calendar_create_event',
      status: 'completed',
      title: '杭州 行程 D$actionId',
    );
  }
}
