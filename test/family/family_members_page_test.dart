// P4 家庭成员页：列表 / 新建 / 编辑 / 生命周期状态变更 / 错误重试。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/family/dto.dart';
import 'package:nexus_mind_mobile/features/family/family_repository.dart';
import 'package:nexus_mind_mobile/pages/family/family_members_page.dart';
import 'package:provider/provider.dart';

final _now = DateTime.now();

void main() {
  testWidgets('shows empty state and adds a member', (tester) async {
    final stub = _StubFamilyRepo(members: []);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('还没有家庭成员'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, '姓名'), '妈妈');
    await tester.enterText(find.widgetWithText(TextField, '关系'), '母亲');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump();

    expect(stub.createCalls, hasLength(1));
    expect(stub.createCalls.single.name, '妈妈');
    expect(stub.createCalls.single.relation, '母亲');
    expect(stub.createCalls.single.memberStatus, 'active');
  });

  testWidgets('shows member list with status badge', (tester) async {
    final stub = _StubFamilyRepo(
      members: [
        _member(id: 1, name: '爸爸', relation: '父亲', memberStatus: 'active'),
        _member(id: 2, name: '奶奶', relation: '母亲', memberStatus: 'away'),
      ],
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('爸爸'), findsOneWidget);
    expect(find.text('在册'), findsOneWidget);
    expect(find.text('奶奶'), findsOneWidget);
    expect(find.text('离开'), findsOneWidget);
  });

  testWidgets('editing to a terminal status requires reason and corrects', (
    tester,
  ) async {
    final stub = _StubFamilyRepo(
      members: [
        _member(id: 1, name: '奶奶', relation: '母亲', memberStatus: 'active'),
      ],
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.text('奶奶'));
    await tester.pump();
    await tester.pump();

    // 状态改为终态（永久离开）：打开状态下拉。
    await tester.ensureVisible(find.byType(DropdownButton<String>));
    await tester.pump();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pump();
    await tester.tap(find.text('永久离开').last);
    await tester.pump();

    expect(find.text('更正理由（必填）'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '已随子女同住');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump();

    expect(stub.correctCalls, hasLength(1));
    expect(stub.correctCalls.single.id, 1);
    expect(stub.correctCalls.single.memberStatus, 'permanently_left');
    expect(stub.correctCalls.single.reason, '已随子女同住');
  });

  testWidgets('shows error state and retries loading', (tester) async {
    final stub = _StubFamilyRepo(members: [], failList: true);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('成员列表暂时无法加载。'), findsOneWidget);

    stub.failList = false;
    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump();

    expect(find.text('还没有家庭成员'), findsOneWidget);
  });
}

Widget _wrap(FamilyRepository repository) => Provider<FamilyRepository>.value(
  value: repository,
  child: MaterialApp(
    theme: NexusTheme.light(NexusPalette.aiAccent),
    home: const FamilyMembersPage(),
  ),
);

FamilyMemberDto _member({
  required int id,
  required String name,
  required String relation,
  String memberStatus = 'active',
}) => FamilyMemberDto(
  id: id,
  name: name,
  relation: relation,
  isElderly: false,
  isChild: false,
  isPrimary: false,
  memberStatus: memberStatus,
  createdAt: _now,
  updatedAt: _now,
);

class _StubFamilyRepo implements FamilyRepository {
  _StubFamilyRepo({required this.members, this.failList = false});

  List<FamilyMemberDto> members;
  bool failList;
  final createCalls = <({String name, String relation, String memberStatus})>[];
  final correctCalls = <({int id, String memberStatus, String? reason})>[];

  @override
  Future<List<FamilyMemberDto>> listMembers() async {
    if (failList) throw StateError('unavailable');
    return members;
  }

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
  }) async {
    createCalls.add((
      name: name,
      relation: relation,
      memberStatus: memberStatus ?? 'active',
    ));
    return _member(
      id: 99,
      name: name,
      relation: relation,
      memberStatus: memberStatus ?? 'active',
    );
  }

  @override
  Future<FamilyMemberDto> updateMember(
    int id,
    Map<String, dynamic> patch,
  ) async {
    return _member(
      id: id,
      name: patch['name']?.toString() ?? '成员',
      relation: patch['relation']?.toString() ?? '',
      memberStatus: patch['memberStatus']?.toString() ?? 'active',
    );
  }

  @override
  Future<FamilyMemberDto> correctMember(
    int id, {
    required String memberStatus,
    String? reason,
  }) async {
    correctCalls.add((id: id, memberStatus: memberStatus, reason: reason));
    return _member(
      id: id,
      name: '成员',
      relation: '',
      memberStatus: memberStatus,
    );
  }

  @override
  Future<List<FamilyKnowledgeDto>> listKnowledge({String? category}) async =>
      [];

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
  }) => throw UnimplementedError();

  @override
  Future<void> deleteKnowledge(int id) async {}

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
