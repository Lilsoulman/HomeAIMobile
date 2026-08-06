// P3 管家工作台与确认中心：确认组件用例。
// 覆盖 L1 批量确认、L2/L3 逐项确认/拒绝、重入恢复（失败重试复用同一幂等键）、
// 成功后续操作用新键、批量局部失败仅更新成功项。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/steward/dto.dart';
import 'package:nexus_mind_mobile/features/steward/steward_repository.dart';
import 'package:nexus_mind_mobile/widgets/confirmation_section.dart';

final _now = DateTime.now();

void main() {
  testWidgets('shows empty state without pending confirmations', (
    tester,
  ) async {
    final stub = _StubStewardRepo(items: []);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    expect(find.text('没有待确认的事项'), findsOneWidget);
  });

  testWidgets('L1 items are batch confirmed with an idempotency key', (
    tester,
  ) async {
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
    expect(stub.batchCalls.single.key, isNotEmpty);
    // 确认后待确认列表清空。
    expect(find.text('没有待确认的事项'), findsOneWidget);
    expect(find.text('全部确认（2）'), findsNothing);
  });

  testWidgets('batch failure keeps the same key for retry and succeeds', (
    tester,
  ) async {
    final stub = _StubStewardRepo(
      items: [_item(id: 1), _item(id: 2)],
      failBatch: true,
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.text('全部确认（2）'));
    await tester.pump();
    await tester.pump();
    expect(find.text('确认失败，请重试'), findsOneWidget);
    expect(stub.batchCalls, hasLength(1));

    // 失败后保留幂等键，重试复用同一键（重入恢复）。
    stub.failBatch = false;
    await tester.tap(find.text('全部确认（2）'));
    await tester.pump();
    await tester.pump();

    expect(stub.batchCalls, hasLength(2));
    expect(stub.batchCalls[0].key, stub.batchCalls[1].key);
    expect(find.text('没有待确认的事项'), findsOneWidget);
  });

  testWidgets('a successful batch uses a fresh key for the next operation', (
    tester,
  ) async {
    final stub = _StubStewardRepo(items: [_item(id: 1), _item(id: 2)]);

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.text('全部确认（2）'));
    await tester.pump();
    await tester.pump();
    final firstKey = stub.batchCalls.single.key;

    // 新一批待确认项到达后刷新，再次批量应使用新幂等键。
    stub.items = [_item(id: 3), _item(id: 4)];
    await tester.tap(find.text('刷新'));
    await tester.pump();
    await tester.pump();
    expect(find.text('全部确认（2）'), findsOneWidget);

    await tester.tap(find.text('全部确认（2）'));
    await tester.pump();
    await tester.pump();

    expect(stub.batchCalls, hasLength(2));
    expect(stub.batchCalls[1].key, isNot(firstKey));
  });

  testWidgets('partial batch failure updates only the confirmed items', (
    tester,
  ) async {
    final stub = _StubStewardRepo(
      items: [_item(id: 1), _item(id: 2)],
      onBatch: (ids) => ConfirmationBatchResultDto(
        confirmedCount: 1,
        // 仅第 1 项确认成功，第 2 项保持 pending（局部失败）。
        items: [
          _item(id: 1, status: 'confirmed'),
          _item(id: 2, status: 'pending'),
        ],
      ),
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    await tester.tap(find.text('全部确认（2）'));
    await tester.pump();
    await tester.pump();

    // 剩余 1 项仍 pending，转为逐项操作。
    expect(find.text('全部确认（2）'), findsNothing);
    expect(find.text('确认'), findsOneWidget);
  });

  testWidgets('L2/L3 items are confirmed and denied one by one without batch', (
    tester,
  ) async {
    final stub = _StubStewardRepo(
      items: [
        _item(id: 5, riskLevel: 'L2', title: '中风险操作'),
        _item(id: 6, riskLevel: 'L3', title: '高风险操作'),
      ],
    );

    await tester.pumpWidget(_wrap(stub));
    await tester.pump();

    // L2/L3 无批量确认按钮。
    expect(find.textContaining('全部确认'), findsNothing);

    await tester.tap(find.text('确认').first);
    await tester.pump();
    await tester.pump();
    expect(stub.confirmCalls, hasLength(1));
    expect(stub.confirmCalls.single.id, 5);
    expect(stub.confirmCalls.single.key, isNotEmpty);

    // 拒绝第 2 项：输入理由后提交。
    await tester.tap(find.text('拒绝').first);
    await tester.pump();
    await tester.pump();
    await tester.enterText(find.byType(TextField), '风险过高');
    await tester.tap(find.text('确认拒绝'));
    await tester.pump();
    await tester.pump();

    expect(stub.denyCalls, hasLength(1));
    expect(stub.denyCalls.single.id, 6);
    expect(stub.denyCalls.single.reason, '风险过高');
    // 全部处理完成后显示空态。
    expect(find.text('没有待确认的事项'), findsOneWidget);
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

Widget _wrap(StewardRepository repository) => MaterialApp(
  theme: NexusTheme.light(NexusPalette.aiAccent),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConfirmationSection(repository: repository),
      ),
    ),
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
  _StubStewardRepo({
    required this.items,
    this.failBatch = false,
    this.failList = false,
    this.onBatch,
  });

  List<ConfirmationItemDto> items;
  bool failBatch;
  bool failList;
  ConfirmationBatchResultDto Function(List<int> ids)? onBatch;
  final batchCalls = <({List<int> ids, String key})>[];
  final confirmCalls = <({int id, String key})>[];
  final denyCalls = <({int id, String reason})>[];

  @override
  Future<List<ConfirmationItemDto>> listConfirmations({
    String? riskLevel,
    String? status,
  }) async {
    if (failList) throw StateError('unavailable');
    return items;
  }

  @override
  Future<ConfirmationBatchResultDto> batchConfirm(
    List<int> confirmationIds, {
    required String idempotencyKey,
  }) async {
    batchCalls.add((ids: List.of(confirmationIds), key: idempotencyKey));
    if (failBatch) throw StateError('network');
    if (onBatch != null) return onBatch!(confirmationIds);
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
  }) async {
    confirmCalls.add((id: id, key: idempotencyKey));
    return _item(id: id, status: 'confirmed');
  }

  @override
  Future<ConfirmationItemDto> deny(int id, {required String reason}) async {
    denyCalls.add((id: id, reason: reason));
    return _item(id: id, status: 'denied');
  }

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
