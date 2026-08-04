import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/ui/nexus_theme.dart';
import '../features/calendar/calendar_repository.dart';
import '../features/calendar/dto.dart';
import '../features/todo/dto.dart';
import '../features/todo/todo_repository.dart';

enum _PlanMode { tasks, calendar }

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  _PlanMode _mode = _PlanMode.tasks;
  late Future<_PlanSummary> _summary;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _summary = _loadSummary();
  }

  Future<_PlanSummary> _loadSummary() async {
    final results = await Future.wait<Object>([
      context.read<TodoRepository>().list(),
      context.read<CalendarRepository>().listEvents(),
    ]);
    return _PlanSummary(
      todos: results[0] as List<TodoDto>,
      events: results[1] as List<CalendarEventDto>,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('计划'),
      actions: [
        IconButton(
          tooltip: '刷新',
          onPressed: () => setState(_reload),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: FutureBuilder<_PlanSummary>(
        future: _summary,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _PlanLoadError(onRetry: () => setState(_reload));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final summary = snapshot.data!;
          return ListView(
            padding: NexusLayout.pagePadding,
            children: [
              Text('今天的安排', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                '把待办、日程和 AI 生成的行动放在同一个清晰视图中。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: NexusLayout.sectionGap),
              SegmentedButton<_PlanMode>(
                segments: const [
                  ButtonSegment(
                    value: _PlanMode.tasks,
                    icon: Icon(Icons.checklist_rounded),
                    label: Text('任务'),
                  ),
                  ButtonSegment(
                    value: _PlanMode.calendar,
                    icon: Icon(Icons.calendar_month_outlined),
                    label: Text('日历'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (value) =>
                    setState(() => _mode = value.single),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _mode == _PlanMode.tasks
                    ? _TaskSummary(
                        key: const ValueKey('tasks'),
                        todos: summary.todos,
                        onOpen: () => context.push('/plan/todos'),
                      )
                    : _CalendarSummary(
                        key: const ValueKey('calendar'),
                        events: summary.events,
                        onOpen: () => context.push('/plan/calendar'),
                      ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _PlanSummary {
  const _PlanSummary({required this.todos, required this.events});

  final List<TodoDto> todos;
  final List<CalendarEventDto> events;
}

class _TaskSummary extends StatelessWidget {
  const _TaskSummary({super.key, required this.todos, required this.onOpen});

  final List<TodoDto> todos;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final pending = todos
        .where((todo) => todo.status != TodoStatus.completed)
        .toList();
    return NexusSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pending.length} 项待处理',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (pending.isEmpty)
            const Text('今天没有待办，可以留出时间做更重要的事。')
          else
            ...pending
                .take(3)
                .map(
                  (todo) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.radio_button_unchecked_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            todo.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.checklist_rounded),
            label: const Text('查看全部任务'),
          ),
        ],
      ),
    );
  }
}

class _CalendarSummary extends StatelessWidget {
  const _CalendarSummary({
    super.key,
    required this.events,
    required this.onOpen,
  });

  final List<CalendarEventDto> events;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming =
        events.where((event) => event.startAt.isAfter(now)).toList()
          ..sort((left, right) => left.startAt.compareTo(right.startAt));
    return NexusSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('接下来的日程', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (upcoming.isEmpty)
            const Text('暂时没有即将开始的日程。')
          else
            ...upcoming
                .take(3)
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${event.startAt.toLocal().hour.toString().padLeft(2, '0')}:${event.startAt.toLocal().minute.toString().padLeft(2, '0')}',
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('查看日历'),
          ),
        ],
      ),
    );
  }
}

class _PlanLoadError extends StatelessWidget {
  const _PlanLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: NexusLayout.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36),
          const SizedBox(height: 12),
          const Text('计划暂时无法加载。'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        ],
      ),
    ),
  );
}
