// P5 管家动态时间线页用例：列表渲染、空态、错误重试、加载更多。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/steward/dto.dart';
import 'package:nexus_mind_mobile/features/steward/steward_repository.dart';
import 'package:nexus_mind_mobile/pages/steward_timeline_page.dart';
import 'package:provider/provider.dart';

class _Repo implements StewardRepository {
  _Repo({this.fail = false, this.pages = const [[]], this.cursors = const []});

  bool fail;
  List<List<StewardActivityDto>> pages;
  List<String?> cursors;
  int calls = 0;

  @override
  Future<StewardActivityPageDto> listActivities({
    int limit = 20,
    String? cursor,
  }) async {
    if (fail) throw Exception('boom');
    final index = calls < pages.length ? calls : pages.length - 1;
    calls++;
    return StewardActivityPageDto(
      items: pages[index],
      cursor: cursors.length > index ? cursors[index] : null,
    );
  }

  @override
  Future<StewardActivityDto> getActivity(int id) async =>
      throw UnimplementedError();

  @override
  Future<StewardActivityDto> undoActivity(int id) async =>
      throw UnimplementedError();

  @override
  Future<List<ConfirmationItemDto>> listConfirmations({
    String? riskLevel,
    String? status,
  }) async => throw UnimplementedError();

  @override
  Future<ConfirmationItemDto> confirm(
    int id, {
    required String idempotencyKey,
  }) async => throw UnimplementedError();

  @override
  Future<ConfirmationItemDto> deny(int id, {required String reason}) async =>
      throw UnimplementedError();

  @override
  Future<ConfirmationBatchResultDto> batchConfirm(
    List<int> confirmationIds, {
    required String idempotencyKey,
  }) async => throw UnimplementedError();
}

StewardActivityDto _activity(int id, String title) => StewardActivityDto(
  id: id,
  category: 'expert',
  title: title,
  description: null,
  riskLevel: 'L1',
  status: 'completed',
  resultSummary: null,
  undoable: false,
  createdAt: DateTime.utc(2026, 8, 7, 10),
  updatedAt: DateTime.utc(2026, 8, 7, 10),
);

Widget wrap(StewardRepository repository) => Provider<StewardRepository>.value(
  value: repository,
  child: MaterialApp(
    theme: NexusTheme.light(NexusPalette.aiAccent),
    home: const StewardTimelinePage(),
  ),
);

void main() {
  testWidgets('renders activity list with titles', (tester) async {
    await tester.pumpWidget(
      wrap(
        _Repo(
          pages: [
            [_activity(1, '已确认：开阳台灯'), _activity(2, '任务已创建')],
          ],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('已确认：开阳台灯'), findsOneWidget);
    expect(find.text('任务已创建'), findsOneWidget);
  });

  testWidgets('shows empty state', (tester) async {
    await tester.pumpWidget(wrap(_Repo()));
    await tester.pump();
    expect(find.text('还没有管家动态。'), findsOneWidget);
  });

  testWidgets('shows error with retry', (tester) async {
    final repository = _Repo(fail: true);
    await tester.pumpWidget(wrap(repository));
    await tester.pump();
    expect(find.text('管家动态暂时无法加载。'), findsOneWidget);

    // 重试成功后恢复列表
    repository.fail = false;
    repository.pages = [
      [_activity(1, '恢复后的动态')],
    ];
    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump();
    expect(find.text('恢复后的动态'), findsOneWidget);
  });

  testWidgets('loads more when cursor is present', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _Repo(
      pages: [
        List.generate(20, (i) => _activity(i, '动态 $i')),
        [_activity(99, '第二页动态')],
      ],
      cursors: ['next', null],
    );
    await tester.pumpWidget(wrap(repository));
    await tester.pump();
    expect(find.text('动态 0'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(repository.calls, greaterThanOrEqualTo(2));
    expect(find.text('第二页动态'), findsOneWidget);
  });
}
