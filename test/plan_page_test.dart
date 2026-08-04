import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/calendar/calendar_repository.dart';
import 'package:nexus_mind_mobile/features/calendar/local_calendar_repository.dart';
import 'package:nexus_mind_mobile/features/todo/local_todo_repository.dart';
import 'package:nexus_mind_mobile/features/todo/todo_repository.dart';
import 'package:nexus_mind_mobile/pages/plan_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('plan switches from task summary to calendar summary', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TodoRepository>.value(value: LocalTodoRepository()),
          Provider<CalendarRepository>.value(value: LocalCalendarRepository()),
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
}
