import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/ui/nexus_theme.dart';
import '../features/calendar/calendar_repository.dart';
import '../features/calendar/dto.dart';
import '../features/steward/steward_repository.dart';
import '../features/todo/dto.dart';
import '../features/todo/todo_repository.dart';
import '../widgets/confirmation_section.dart';

enum _PlanMode { confirmations, tasks, calendar, travel }

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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_PlanMode>(
                  segments: const [
                    ButtonSegment(
                      value: _PlanMode.confirmations,
                      icon: Icon(Icons.verified_user_outlined),
                      label: Text('待确认'),
                    ),
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
                    ButtonSegment(
                      value: _PlanMode.travel,
                      icon: Icon(Icons.luggage_outlined),
                      label: Text('旅行'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (value) =>
                      setState(() => _mode = value.single),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_mode) {
                  _PlanMode.confirmations => Column(
                    key: const ValueKey('confirmations'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConfirmationSection(
                        repository: context.read<StewardRepository>(),
                      ),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.push('/plan/confirmations'),
                          icon: const Icon(Icons.open_in_full_rounded),
                          label: const Text('查看全部'),
                        ),
                      ),
                    ],
                  ),
                  _PlanMode.tasks => _TaskSummary(
                    key: const ValueKey('tasks'),
                    todos: summary.todos,
                    onOpen: () => context.push('/plan/todos'),
                  ),
                  _PlanMode.calendar => _CalendarSummary(
                    key: const ValueKey('calendar'),
                    events: summary.events,
                    onOpen: () => context.push('/plan/calendar'),
                  ),
                  _PlanMode.travel => _TravelPlanSummary(
                    key: const ValueKey('travel'),
                    events: summary.events,
                    onCreate: () => context.push('/ai/life-trip'),
                    onOpenCalendar: () => context.push('/plan/calendar'),
                  ),
                },
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

class _TravelPlanSummary extends StatelessWidget {
  const _TravelPlanSummary({
    super.key,
    required this.events,
    required this.onCreate,
    required this.onOpenCalendar,
  });

  final List<CalendarEventDto> events;
  final VoidCallback onCreate;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final tripEvents = events.where(_isTripEvent).toList()
      ..sort((left, right) => left.startAt.compareTo(right.startAt));
    if (tripEvents.isEmpty) {
      return _TravelPlanEmpty(onCreate: onCreate);
    }

    final theme = Theme.of(context);
    final first = tripEvents.first;
    final last = tripEvents.last;
    final today = DateUtils.dateOnly(DateTime.now());
    final completed = tripEvents
        .where((event) => event.startAt.isBefore(today))
        .length;
    final destination = _tripDestination(first.title);
    final status = completed >= tripEvents.length
        ? '已结束'
        : completed > 0
        ? '进行中'
        : '即将开始';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NexusSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.luggage_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(destination, style: theme.textTheme.titleLarge),
                  ),
                  _TripStatus(status: status),
                ],
              ),
              const SizedBox(height: 14),
              _TravelMetaRow(
                icon: Icons.date_range_outlined,
                text:
                    '${_dateLabel(first.startAt)} - ${_dateLabel(last.startAt)}',
              ),
              const SizedBox(height: 10),
              _TravelMetaRow(
                icon: Icons.route_outlined,
                text: '${tripEvents.length} 段行程 · 已完成 $completed 段',
              ),
            ],
          ),
        ),
        const SizedBox(height: NexusLayout.sectionGap),
        Row(
          children: [
            Expanded(child: Text('行程安排', style: theme.textTheme.titleLarge)),
            TextButton.icon(
              onPressed: onOpenCalendar,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('日历'),
            ),
          ],
        ),
        const SizedBox(height: NexusLayout.controlGap),
        ...tripEvents.map(
          (event) => _TravelTimelineItem(event: event, today: today),
        ),
      ],
    );
  }
}

class _TravelPlanEmpty extends StatelessWidget {
  const _TravelPlanEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => NexusSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.luggage_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text('还没有旅行计划', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('生成行程后，已确认的日程会在这里以时间线呈现。'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('创建旅行计划'),
        ),
      ],
    ),
  );
}

class _TravelTimelineItem extends StatelessWidget {
  const _TravelTimelineItem({required this.event, required this.today});

  final CalendarEventDto event;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = event.startAt.isBefore(today);
    final isToday = DateUtils.isSameDay(event.startAt, today);
    final color = isPast
        ? theme.colorScheme.secondary
        : isToday
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    final time = event.allDay
        ? '全天'
        : '${event.startAt.toLocal().hour.toString().padLeft(2, '0')}:${event.startAt.toLocal().minute.toString().padLeft(2, '0')}';
    final location = event.location;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 54,
            child: Text(time, style: theme.textTheme.bodySmall),
          ),
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: theme.dividerColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: NexusLayout.itemGap),
              child: NexusSurface(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.place_outlined, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    if (location != null && location.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(location, style: theme.textTheme.bodySmall),
                    ],
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        event.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripStatus extends StatelessWidget {
  const _TripStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = status == '进行中';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (active
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: active ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TravelMetaRow extends StatelessWidget {
  const _TravelMetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}

bool _isTripEvent(CalendarEventDto event) =>
    RegExp(r'(^|\s)行程(\s|$)|旅行|出行|旅程').hasMatch(event.title);

String _tripDestination(String title) {
  final match = RegExp(r'^(.+?)\s*行程').firstMatch(title);
  return match?.group(1)?.trim().isNotEmpty == true
      ? match!.group(1)!.trim()
      : '旅行计划';
}

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
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
