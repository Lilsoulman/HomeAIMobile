import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/calendar/calendar_repository.dart';
import 'package:nexus_mind_mobile/features/calendar/dto.dart';
import 'package:nexus_mind_mobile/features/steward/dto.dart';
import 'package:nexus_mind_mobile/features/steward/steward_repository.dart';
import 'package:nexus_mind_mobile/features/todo/dto.dart';
import 'package:nexus_mind_mobile/features/todo/todo_repository.dart';
import 'package:nexus_mind_mobile/pages/plan_page.dart';
import 'package:provider/provider.dart';

final _now = DateTime.now();

void main() {
  testWidgets('plan switches from task summary to calendar summary', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TodoRepository>.value(value: _StubTodoRepo()),
          Provider<CalendarRepository>.value(value: _StubCalendarRepo()),
          Provider<StewardRepository>.value(value: _StubStewardRepo(items: [])),
        ],
        child: MaterialApp(
          theme: NexusTheme.light(NexusPalette.aiAccent),
          home: const PlanPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2 项待处理'), findsOneWidget);
    expect(find.text('查看全部任务'), findsOneWidget);

    await tester.tap(find.text('日历'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('接下来的日程'), findsOneWidget);
    expect(find.text('查看日历'), findsOneWidget);
  });

  testWidgets('plan switches to the pending confirmations segment', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TodoRepository>.value(value: _StubTodoRepo()),
          Provider<CalendarRepository>.value(value: _StubCalendarRepo()),
          Provider<StewardRepository>.value(
            value: _StubStewardRepo(
              items: [
                ConfirmationItemDto(
                  id: 1,
                  riskLevel: 'L2',
                  title: '中风险确认项',
                  impactSummary: '影响摘要',
                  status: 'pending',
                  updatedAt: _now,
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: NexusTheme.light(NexusPalette.aiAccent),
          home: const PlanPage(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('待确认'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('中风险确认项'), findsOneWidget);
    expect(find.text('L2'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '确认'), findsOneWidget);
  });
}

class _StubTodoRepo implements TodoRepository {
  @override
  Future<List<TodoDto>> list({
    String? status,
    DateTime? from,
    DateTime? to,
  }) async => [
    TodoDto(
      id: 1,
      title: '整理',
      status: TodoStatus.pending,
      pinned: false,
      sortOrder: 0,
      createdAt: _now,
      updatedAt: _now,
    ),
    TodoDto(
      id: 2,
      title: '确认',
      status: TodoStatus.pending,
      pinned: false,
      sortOrder: 0,
      createdAt: _now,
      updatedAt: _now,
    ),
  ];

  @override
  Future<TodoDto> create({
    required String title,
    String? description,
    String? type,
    String? priority,
    String? color,
    String? status,
    DateTime? dueAt,
    DateTime? remindAt,
    bool? pinned,
    int? sortOrder,
    String? repeatRule,
    int? parentId,
  }) async => TodoDto(
    id: 3,
    title: title,
    status: TodoStatus.pending,
    pinned: false,
    sortOrder: 0,
    createdAt: _now,
    updatedAt: _now,
  );

  @override
  Future<TodoDto> update(int id, Map<String, dynamic> patch) async => TodoDto(
    id: id,
    title: '',
    status: TodoStatus.pending,
    pinned: false,
    sortOrder: 0,
    createdAt: _now,
    updatedAt: _now,
  );

  @override
  Future<void> delete(int id) async {}

  @override
  Future<List<SubtaskDto>> listSubtasks(int todoId) async => [];

  @override
  Future<SubtaskDto> addSubtask(
    int todoId, {
    required String text,
    int? seq,
  }) async => SubtaskDto(id: 1, text: text, done: false, seq: 0);

  @override
  Future<SubtaskDto> updateSubtask(
    int todoId,
    int subId,
    Map<String, dynamic> patch,
  ) async => SubtaskDto(id: subId, text: '', done: false, seq: 0);

  @override
  Future<void> deleteSubtask(int todoId, int subId) async {}
}

class _StubCalendarRepo implements CalendarRepository {
  @override
  Future<List<CalendarEventDto>> listEvents({
    DateTime? from,
    DateTime? to,
  }) async => [];

  @override
  Future<CalendarEventDto> createEvent({
    required String title,
    String? description,
    String? location,
    required DateTime startAt,
    DateTime? endAt,
    String? timezone,
    bool? allDay,
    String? color,
    double? opacity,
    String? repeatRule,
  }) async => CalendarEventDto(
    id: 1,
    title: title,
    startAt: startAt,
    endAt: endAt,
    timezone: 'UTC',
    allDay: allDay ?? false,
    opacity: 1.0,
    createdAt: _now,
    updatedAt: _now,
  );

  @override
  Future<CalendarEventDto> updateEvent(
    int id,
    Map<String, dynamic> patch,
  ) async => CalendarEventDto(
    id: id,
    title: '',
    startAt: _now,
    endAt: _now,
    timezone: 'UTC',
    allDay: false,
    opacity: 1.0,
    createdAt: _now,
    updatedAt: _now,
  );

  @override
  Future<void> deleteEvent(int id) async {}

  @override
  Future<List<CalendarSubscriptionDto>> listSubscriptions() async => [];

  @override
  Future<CalendarSubscriptionDto> createSubscription({
    required String url,
    String? name,
    bool? enabled,
    int? refreshIntervalMin,
  }) async => CalendarSubscriptionDto(
    id: 1,
    name: name ?? url,
    enabled: enabled ?? true,
    refreshIntervalMin: refreshIntervalMin ?? 60,
    createdAt: _now,
  );

  @override
  Future<CalendarSubscriptionDto> updateSubscription(
    int id,
    Map<String, dynamic> patch,
  ) async => CalendarSubscriptionDto(
    id: id,
    name: '',
    enabled: false,
    refreshIntervalMin: 60,
    createdAt: _now,
  );

  @override
  Future<void> deleteSubscription(int id) async {}
}

class _StubStewardRepo implements StewardRepository {
  _StubStewardRepo({required this.items});

  final List<ConfirmationItemDto> items;

  @override
  Future<List<ConfirmationItemDto>> listConfirmations({
    String? riskLevel,
    String? status,
  }) async => items;

  @override
  Future<ConfirmationBatchResultDto> batchConfirm(
    List<int> confirmationIds, {
    required String idempotencyKey,
  }) async => ConfirmationBatchResultDto(confirmedCount: 0, items: const []);

  @override
  Future<ConfirmationItemDto> confirm(
    int id, {
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<ConfirmationItemDto> deny(int id, {required String reason}) =>
      throw UnimplementedError();

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
