// P4 家庭知识库页：列表 / 分类筛选 / 搜索 / 新建 / 删除二次确认 / 错误重试。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/family/dto.dart';
import 'package:nexus_mind_mobile/features/family/family_repository.dart';
import 'package:nexus_mind_mobile/pages/family/family_knowledge_page.dart';
import 'package:provider/provider.dart';

final _now = DateTime.now();

void main() {
  testWidgets('shows empty state', (tester) async {
    final stub = _StubFamilyRepo(items: []);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('还没有家庭知识，点击右下角添加。'), findsOneWidget);
  });

  testWidgets('filters by category and searches locally', (tester) async {
    final stub = _StubFamilyRepo(
      items: [
        _knowledge(id: 1, category: '生活', key: '睡眠习惯', value: '早睡'),
        _knowledge(id: 2, category: '健康', key: '过敏源', value: '花生'),
      ],
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('睡眠习惯'), findsOneWidget);
    expect(find.text('过敏源'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, '健康'));
    await tester.pump();

    expect(find.text('过敏源'), findsOneWidget);
    expect(find.text('睡眠习惯'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, '全部'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '花生');
    await tester.pump();

    expect(find.text('过敏源'), findsOneWidget);
    expect(find.text('睡眠习惯'), findsNothing);
  });

  testWidgets('shows AI source and conflict resolution', (tester) async {
    final stub = _StubFamilyRepo(
      items: [
        _knowledge(
          id: 1,
          category: '生活',
          key: '作息',
          value: '22:30 前就寝',
          sourceType: 'ai',
          confidenceScore: 0.6,
          resolutionSummary: '采纳最新写入',
        ),
      ],
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('AI 提取'), findsOneWidget);
    expect(find.text('冲突解决：采纳最新写入'), findsOneWidget);
  });

  testWidgets('adds knowledge via form', (tester) async {
    final stub = _StubFamilyRepo(items: []);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, '分类'), '生活');
    await tester.enterText(find.widgetWithText(TextField, '键'), '饮水习惯');
    await tester.enterText(find.widgetWithText(TextField, '值'), '每天 8 杯');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump();

    expect(stub.writeCalls, hasLength(1));
    expect(stub.writeCalls.single.category, '生活');
    expect(stub.writeCalls.single.key, '饮水习惯');
    expect(stub.writeCalls.single.value, '每天 8 杯');
    expect(stub.writeCalls.single.sourceType, 'manual');
  });

  testWidgets('delete requires confirmation', (tester) async {
    final stub = _StubFamilyRepo(
      items: [_knowledge(id: 1, category: '生活', key: '旧知识', value: '旧值')],
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.byTooltip('删除'));
    await tester.pump();
    await tester.pump();

    expect(find.text('删除知识'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pump();
    await tester.pump();

    expect(stub.deleteIds, [1]);
  });

  testWidgets('shows error state and retries loading', (tester) async {
    final stub = _StubFamilyRepo(items: [], failList: true);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('家庭知识暂时无法加载。'), findsOneWidget);

    stub.failList = false;
    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump();

    expect(find.text('还没有家庭知识，点击右下角添加。'), findsOneWidget);
  });
}

Widget _wrap(FamilyRepository repository) => Provider<FamilyRepository>.value(
  value: repository,
  child: MaterialApp(
    theme: NexusTheme.light(NexusPalette.aiAccent),
    home: const FamilyKnowledgePage(),
  ),
);

FamilyKnowledgeDto _knowledge({
  required int id,
  required String category,
  required String key,
  required String value,
  String sourceType = 'manual',
  double confidenceScore = 1.0,
  String? resolutionSummary,
}) => FamilyKnowledgeDto(
  id: id,
  category: category,
  key: key,
  value: value,
  sourceType: sourceType,
  confidenceScore: confidenceScore,
  conflictResolutionStrategy: 'latest',
  resolutionSummary: resolutionSummary,
  createdAt: _now,
  updatedAt: _now,
);

class _StubFamilyRepo implements FamilyRepository {
  _StubFamilyRepo({required this.items, this.failList = false});

  List<FamilyKnowledgeDto> items;
  bool failList;
  final writeCalls =
      <({String category, String key, String value, String sourceType})>[];
  final deleteIds = <int>[];

  @override
  Future<List<FamilyKnowledgeDto>> listKnowledge({String? category}) async {
    if (failList) throw StateError('unavailable');
    return items;
  }

  @override
  Future<FamilyKnowledgeWriteResultDto> writeKnowledge({
    required String category,
    required String key,
    required String value,
    String? notes,
    String? sourceType,
    int? sourceMemberId,
    double? confidenceScore,
    String? conflictResolutionStrategy,
  }) async {
    writeCalls.add((
      category: category,
      key: key,
      value: value,
      sourceType: sourceType ?? 'manual',
    ));
    return FamilyKnowledgeWriteResultDto(
      knowledge: _knowledge(
        id: 99,
        category: category,
        key: key,
        value: value,
        sourceType: sourceType ?? 'manual',
      ),
    );
  }

  @override
  Future<void> deleteKnowledge(int id) async {
    deleteIds.add(id);
    items = items.where((item) => item.id != id).toList();
  }

  @override
  Future<List<FamilyMemberDto>> listMembers() async => [];

  @override
  Future<FamilyMemberDto> createMember({
    required String name,
    required String relation,
    DateTime? birthday,
    bool? isElderly,
    bool? isChild,
    bool? isPrimary,
    String? memberStatus,
    String? preferences,
  }) => throw UnimplementedError();

  @override
  Future<FamilyMemberDto> updateMember(int id, Map<String, dynamic> patch) =>
      throw UnimplementedError();

  @override
  Future<FamilyMemberDto> correctMember(
    int id, {
    required String memberStatus,
    String? reason,
  }) => throw UnimplementedError();

  @override
  Future<FamilyDecisionPageDto> listDecisions({
    int? memberId,
    int limit = 20,
    String? cursor,
  }) => throw UnimplementedError();

  @override
  Future<FamilyDecisionDto> recordDecision({
    required String scenario,
    required String decisionMade,
    String? rationale,
    String? alternatives,
    int? madeByMemberId,
    DateTime? decidedAt,
  }) => throw UnimplementedError();
}
