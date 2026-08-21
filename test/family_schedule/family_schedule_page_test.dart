import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/features/family_schedule/dto.dart';
import 'package:nexus_mind_mobile/features/family_schedule/family_schedule_repository.dart';
import 'package:nexus_mind_mobile/pages/family_schedule_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows family schedule, conflict and deadline reminder', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<FamilyScheduleRepository>.value(
        value: _Repository(),
        child: const MaterialApp(home: FamilySchedulePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('家庭日程'), findsOneWidget);
    expect(find.text('家长会'), findsOneWidget);
    expect(find.text('小明 与 小红'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('妈妈护照即将到期'), 200);
    expect(find.text('妈妈护照即将到期'), findsOneWidget);
  });
}

class _Repository implements FamilyScheduleRepository {
  @override
  Future<FamilyDocumentDeadlineDto> createDocumentDeadline(
    FamilyDocumentDeadlineCreateDto request,
  ) => throw UnimplementedError();

  @override
  Future<List<FamilyScheduleAvailabilityDto>> listAvailability({
    DateTime? from,
    DateTime? to,
    int durationMinutes = 60,
  }) async => [
    FamilyScheduleAvailabilityDto(
      startAt: DateTime.utc(2026, 8, 22, 9),
      endAt: DateTime.utc(2026, 8, 22, 11),
    ),
  ];

  @override
  Future<List<FamilyScheduleConflictDto>> listConflicts({
    DateTime? from,
    DateTime? to,
  }) async => [
    FamilyScheduleConflictDto(
      first: _event(),
      second: FamilyScheduleEventDto(
        id: 2,
        userId: 4,
        memberName: '小红',
        title: '钢琴课',
        startAt: DateTime.utc(2026, 8, 21, 9, 30),
        allDay: false,
      ),
      overlapStartAt: DateTime.utc(2026, 8, 21, 9, 30),
      overlapEndAt: DateTime.utc(2026, 8, 21, 10),
    ),
  ];

  @override
  Future<List<FamilyDocumentDeadlineDto>> listDocumentDeadlines() async =>
      const [];

  @override
  Future<List<FamilyScheduleEventDto>> listEvents({
    DateTime? from,
    DateTime? to,
  }) async => [_event()];

  @override
  Future<List<FamilyScheduleReminderDto>> listReminders({
    DateTime? asOf,
  }) async => [
    FamilyScheduleReminderDto(
      type: 'document_deadline',
      sourceId: 8,
      title: '妈妈护照即将到期',
      dueDate: DateTime.utc(2026, 8, 22),
      daysRemaining: 2,
      confirmationId: 11,
    ),
  ];

  @override
  Future<FamilyTomorrowPreviewDto> tomorrowPreview({DateTime? asOf}) async =>
      FamilyTomorrowPreviewDto(
        date: DateTime.utc(2026, 8, 21),
        events: [_event()],
        conflicts: const [],
        reminders: const [],
      );
}

FamilyScheduleEventDto _event() => FamilyScheduleEventDto(
  id: 1,
  userId: 3,
  memberName: '小明',
  title: '家长会',
  startAt: DateTime.utc(2026, 8, 21, 9),
  endAt: DateTime.utc(2026, 8, 21, 10),
  allDay: false,
);
