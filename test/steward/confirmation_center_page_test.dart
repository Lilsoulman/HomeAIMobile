// P3 确认中心页面：风险过滤 + 复用 ConfirmationSection 交互。
// 覆盖空态、L1 批量确认、风险过滤透传、错误重试。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/steward/dto.dart';
import 'package:nexus_mind_mobile/features/steward/steward_repository.dart';
import 'package:nexus_mind_mobile/pages/confirmation_center_page.dart';
import 'package:provider/provider.dart';

final _now = DateTime.now();

void main() {
  testWidgets('shows empty state without pending confirmations', (
    tester,
  ) async {
    final stub = _StubStewardRepo(items: []);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('确认中心'), findsOneWidget);
    expect(find.text('没有待确认的事项'), findsOneWidget);
  });

  testWidgets('L1 items are batch confirmed', (tester) async {
    final stub = _StubStewardRepo(
      items: [
        _item(id: 1),
        _item(id: 2, title: '确认事项二'),
      ],
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('全部确认（2）'), findsOneWidget);

    await tester.tap(find.text('全部确认（2）'));
    await tester.pump();
    await tester.pump();

    expect(stub.batchCalls, hasLength(1));
    expect(stub.batchCalls.single.ids, [1, 2]);
    expect(find.text('没有待确认的事项'), findsOneWidget);
  });

  testWidgets('risk filter passes level to repository and reloads', (
    tester,
  ) async {
    final stub = _StubStewardRepo(items: [_item(id: 1, riskLevel: 'L1')]);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(stub.listLevels, [null]);

    await tester.tap(find.text('L2'));
    await tester.pump();
    await tester.pump();

    expect(stub.listLevels, [null, 'L2']);
  });

  testWidgets('shows error state and retries loading', (tester) async {
    final stub = _StubStewardRepo(items: [], failList: true);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('确认中心暂时无法加载'), findsOneWidget);

    stub.failList = false;
    await tester.tap(find.byTooltip('重试'));
    await tester.pump();
    await tester.pump();

    expect(find.text('没有待确认的事项'), findsOneWidget);
  });
}

Widget _wrap(StewardRepository repository) => Provider<StewardRepository>.value(
  value: repository,
  child: MaterialApp(
    theme: NexusTheme.light(NexusPalette.aiAccent),
    home: const ConfirmationCenterPage(),
  ),
);

ConfirmationItemDto _item({
  required int id,
  String riskLevel = 'L1',
  String status = 'pending',
  String title = '',
}) => ConfirmationItemDto(
  id: id,
  riskLevel: riskLevel,
  title: title.isEmpty ? '待确认事项 $id' : title,
  impactSummary: '影响摘要 $id',
  status: status,
  updatedAt: _now,
);

class _StubStewardRepo implements StewardRepository {
  _StubStewardRepo({required this.items, this.failList = false});

  List<ConfirmationItemDto> items;
  bool failList;
  final listLevels = <String?>[];
  final batchCalls = <({List<int> ids, String key})>[];

  @override
  Future<List<ConfirmationItemDto>> listConfirmations({
    String? riskLevel,
    String? status,
  }) async {
    listLevels.add(riskLevel);
    if (failList) throw StateError('unavailable');
    return items;
  }

  @override
  Future<ConfirmationBatchResultDto> batchConfirm(
    List<int> confirmationIds, {
    required String idempotencyKey,
  }) async {
    batchCalls.add((ids: List.of(confirmationIds), key: idempotencyKey));
    return ConfirmationBatchResultDto(
      confirmedCount: confirmationIds.length,
      items: [
        for (final id in confirmationIds) _item(id: id, status: 'confirmed'),
      ],
    );
  }

  @override
  Future<ConfirmationItemDto> confirm(
    int id, {
    required String idempotencyKey,
  }) async => _item(id: id, status: 'confirmed');

  @override
  Future<ConfirmationItemDto> deny(int id, {required String reason}) async =>
      _item(id: id, status: 'denied');

  @override
  Future<StewardActivityPageDto> listActivities({
    int limit = 20,
    String? cursor,
  }) => throw UnimplementedError();

  @override
  Future<StewardActivityDto> getActivity(int id) => throw UnimplementedError();

  @override
  Future<StewardActivityDto> undoActivity(int id) => throw UnimplementedError();
}
