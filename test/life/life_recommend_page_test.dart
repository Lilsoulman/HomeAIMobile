// P5c 探店翻牌页：输入校验 / 提交建议卡渲染 / 时间快捷值 / 再翻一张新幂等键 / 错误重试 / 空建议。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/life/dto.dart';
import 'package:nexus_mind_mobile/features/life/life_expert_repository.dart';
import 'package:nexus_mind_mobile/pages/life_recommend_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('requires time, location and taste', (tester) async {
    final stub = _StubLifeRepo();

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.text('翻一张'));
    await tester.pump();

    expect(find.text('请填写时间、位置与口味'), findsOneWidget);
    expect(stub.recommendCalls, isEmpty);
  });

  testWidgets('submits recommend and renders suggestion cards', (tester) async {
    final stub = _StubLifeRepo(recommendResult: _recommendResult());

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, '时间'), 'evening');
    await tester.enterText(find.widgetWithText(TextField, '位置'), '城西');
    await tester.enterText(find.widgetWithText(TextField, '口味'), '面');
    await tester.tap(find.text('翻一张'));
    await tester.pump();
    await tester.pump();

    expect(stub.recommendCalls, hasLength(1));
    expect(stub.recommendCalls.single.$1, 'evening');
    expect(stub.recommendCalls.single.$2, '城西');
    expect(stub.recommendCalls.single.$3, '面');
    expect(find.text('老王面馆'), findsOneWidget);
    expect(find.text('口味匹配“面”，位置匹配“城西”'), findsOneWidget);
    expect(find.text('面'), findsWidgets);
  });

  testWidgets('time preset chip fills contract value', (tester) async {
    final stub = _StubLifeRepo(recommendResult: _recommendResult());

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.text('中午'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, '位置'), '城西');
    await tester.enterText(find.widgetWithText(TextField, '口味'), '面');
    await tester.tap(find.text('翻一张'));
    await tester.pump();
    await tester.pump();

    expect(stub.recommendCalls.single.$1, 'noon');
  });

  testWidgets('flip again uses a new idempotency key', (tester) async {
    final stub = _StubLifeRepo(recommendResult: _recommendResult());

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, '时间'), 'evening');
    await tester.enterText(find.widgetWithText(TextField, '位置'), '城西');
    await tester.enterText(find.widgetWithText(TextField, '口味'), '面');
    await tester.tap(find.text('翻一张'));
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('再翻一张'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('再翻一张'));
    await tester.pump();
    await tester.tap(find.text('再翻一张'));
    await tester.pump();
    await tester.pump();

    expect(stub.recommendCalls, hasLength(2));
    expect(stub.recommendKeys, hasLength(2));
    expect(stub.recommendKeys[0], isNot(stub.recommendKeys[1]));
  });

  testWidgets('shows empty message when no recommendations', (tester) async {
    final stub = _StubLifeRepo(
      recommendResult: const LifeRecommendResultDto(
        status: 'completed',
        recommendations: [],
      ),
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, '时间'), 'evening');
    await tester.enterText(find.widgetWithText(TextField, '位置'), '城西');
    await tester.enterText(find.widgetWithText(TextField, '口味'), '面');
    await tester.tap(find.text('翻一张'));
    await tester.pump();
    await tester.pump();

    expect(find.text('没有翻到合适的店，换个条件再试试。'), findsOneWidget);
  });

  testWidgets('shows error and retries', (tester) async {
    final stub = _StubLifeRepo(
      recommendResult: _recommendResult(),
      failRecommend: true,
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, '时间'), 'evening');
    await tester.enterText(find.widgetWithText(TextField, '位置'), '城西');
    await tester.enterText(find.widgetWithText(TextField, '口味'), '面');
    await tester.tap(find.text('翻一张'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('推荐失败'), findsOneWidget);

    stub.failRecommend = false;
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

    expect(find.text('老王面馆'), findsOneWidget);
  });
}

Widget _wrap(LifeExpertRepository repository) =>
    Provider<LifeExpertRepository>.value(
      value: repository,
      child: MaterialApp(
        theme: NexusTheme.light(NexusPalette.aiAccent),
        home: const LifeRecommendPage(),
      ),
    );

LifeRecommendResultDto _recommendResult() => const LifeRecommendResultDto(
  status: 'completed',
  resultSummary: '为你推荐 2 家店铺。',
  recommendations: [
    LifeRecommendationDto(
      favoriteId: 501,
      name: '老王面馆',
      reason: '口味匹配“面”，位置匹配“城西”',
      tags: ['面', '晚餐'],
    ),
  ],
);

class _StubLifeRepo implements LifeExpertRepository {
  _StubLifeRepo({this.recommendResult, this.failRecommend = false});

  final LifeRecommendResultDto? recommendResult;
  bool failRecommend;
  final recommendCalls = <(String, String, String)>[];
  final recommendKeys = <String>[];

  @override
  Future<LifeRecommendResultDto> recommend({
    required String time,
    required String location,
    required String taste,
    required String idempotencyKey,
  }) async {
    recommendCalls.add((time, location, taste));
    recommendKeys.add(idempotencyKey);
    if (failRecommend) throw StateError('推荐失败');
    return recommendResult ?? const LifeRecommendResultDto(status: 'completed');
  }

  @override
  Future<LifePlanResultDto> planTrip({
    required String destination,
    required int days,
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<LifePlanActionDto> confirmPlanAction({
    required int runId,
    required int actionId,
    required String idempotencyKey,
  }) => throw UnimplementedError();
}
