import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../features/calendar/calendar_repository.dart';
import '../features/calendar/dto.dart';
import '../features/todo/dto.dart';
import '../features/todo/todo_repository.dart';

enum _CalendarView { month, week, day, year }

class CalendarWorkspacePage extends StatefulWidget {
  const CalendarWorkspacePage({
    super.key,
    required this.repository,
    required this.todoRepository,
  });
  final CalendarRepository repository;
  final TodoRepository todoRepository;

  @override
  State<CalendarWorkspacePage> createState() => _CalendarWorkspacePageState();
}

class _CalendarWorkspacePageState extends State<CalendarWorkspacePage> {
  late DateTime _focused = DateUtils.dateOnly(DateTime.now());
  late Future<_CalendarData> _data = _load();
  _CalendarView _view = _CalendarView.month;

  Future<_CalendarData> _load() async {
    final from = DateTime(_focused.year, _focused.month - 1, 1);
    final to = DateTime(_focused.year, _focused.month + 2, 1);
    final results = await Future.wait([
      widget.repository.listEvents(from: from, to: to),
      widget.todoRepository.list(from: from, to: to),
    ]);
    return _CalendarData(
      results[0] as List<CalendarEventDto>,
      results[1] as List<TodoDto>,
    );
  }

  void _reload() => setState(() => _data = _load());
  void _shift(int amount) {
    setState(() {
      _focused = switch (_view) {
        _CalendarView.day => _focused.add(Duration(days: amount)),
        _CalendarView.week => _focused.add(Duration(days: amount * 7)),
        _CalendarView.month => DateTime(
          _focused.year,
          _focused.month + amount,
          1,
        ),
        _CalendarView.year => DateTime(
          _focused.year + amount,
          _focused.month,
          1,
        ),
      };
      _data = _load();
    });
  }

  Future<void> _edit([CalendarEventDto? event]) async {
    final draft = await showModalBottomSheet<_EventDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EventEditor(event: event),
    );
    if (draft == null) return;
    try {
      if (event == null) {
        await widget.repository.createEvent(
          title: draft.title,
          description: draft.description,
          location: draft.location,
          startAt: draft.startAt,
          endAt: draft.endAt,
          timezone: 'Asia/Shanghai',
          allDay: draft.allDay,
          color: draft.color,
          opacity: draft.opacity,
          repeatRule: draft.repeatRule,
        );
      } else {
        await widget.repository.updateEvent(event.id, draft.toPatch());
      }
      _reload();
    } catch (error) {
      _notice('保存失败：$error');
    }
  }

  Future<void> _eventMenu(CalendarEventDto event) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑事件'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('删除事件'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'edit') _edit(event);
    if (action == 'delete') {
      try {
        await widget.repository.deleteEvent(event.id);
        _reload();
      } catch (error) {
        _notice('删除失败：$error');
      }
    }
  }

  Future<void> _subscriptions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _Subscriptions(repository: widget.repository),
    );
  }

  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('日历'),
      actions: [
        IconButton(
          tooltip: 'iCal 订阅',
          onPressed: _subscriptions,
          icon: const Icon(Icons.rss_feed_outlined),
        ),
        IconButton(
          tooltip: '今天',
          onPressed: () {
            setState(() {
              _focused = DateUtils.dateOnly(DateTime.now());
              _data = _load();
            });
          },
          icon: const Icon(Icons.today_outlined),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _edit(),
      child: const Icon(Icons.add),
    ),
    body: FutureBuilder<_CalendarData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('加载失败：${snapshot.error}'));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: SegmentedButton<_CalendarView>(
                segments: const [
                  ButtonSegment(value: _CalendarView.month, label: Text('月')),
                  ButtonSegment(value: _CalendarView.week, label: Text('周')),
                  ButtonSegment(value: _CalendarView.day, label: Text('日')),
                  ButtonSegment(value: _CalendarView.year, label: Text('年')),
                ],
                selected: {_view},
                onSelectionChanged: (value) =>
                    setState(() => _view = value.single),
              ),
            ),
            _CalendarHeader(focused: _focused, view: _view, onShift: _shift),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: switch (_view) {
                  _CalendarView.month => _MonthView(
                    key: const ValueKey('month'),
                    focused: _focused,
                    data: data,
                    onDaySelected: (day) => setState(() {
                      _focused = day;
                      _view = _CalendarView.day;
                    }),
                    onEvent: _eventMenu,
                  ),
                  _CalendarView.week => _WeekView(
                    key: const ValueKey('week'),
                    focused: _focused,
                    data: data,
                    onEvent: _eventMenu,
                  ),
                  _CalendarView.day => _DayView(
                    key: const ValueKey('day'),
                    focused: _focused,
                    data: data,
                    onEvent: _eventMenu,
                  ),
                  _CalendarView.year => _YearView(
                    key: const ValueKey('year'),
                    focused: _focused,
                    data: data,
                    onMonth: (month) => setState(() {
                      _focused = month;
                      _view = _CalendarView.month;
                    }),
                  ),
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _CalendarData {
  const _CalendarData(this.events, this.todos);
  final List<CalendarEventDto> events;
  final List<TodoDto> todos;
  List<CalendarEventDto> eventsOn(DateTime day) => events
      .where((event) => DateUtils.isSameDay(event.startAt.toLocal(), day))
      .toList();
  List<TodoDto> todosOn(DateTime day) => todos
      .where(
        (todo) =>
            todo.dueAt != null &&
            DateUtils.isSameDay(todo.dueAt!.toLocal(), day) &&
            todo.status != TodoStatus.completed,
      )
      .toList();
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.focused,
    required this.view,
    required this.onShift,
  });
  final DateTime focused;
  final _CalendarView view;
  final ValueChanged<int> onShift;
  @override
  Widget build(BuildContext context) {
    final label = switch (view) {
      _CalendarView.day => '${focused.year}年${focused.month}月${focused.day}日',
      _CalendarView.week => '第 ${_weekOfYear(focused)} 周 · ${focused.year}',
      _CalendarView.month => '${focused.year}年${focused.month}月',
      _CalendarView.year => '${focused.year}年',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => onShift(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: () => onShift(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  static int _weekOfYear(DateTime day) =>
      ((day.difference(DateTime(day.year, 1, 1)).inDays +
                  DateTime(day.year, 1, 1).weekday -
                  1) /
              7)
          .ceil();
}

class _MonthView extends StatelessWidget {
  const _MonthView({
    super.key,
    required this.focused,
    required this.data,
    required this.onDaySelected,
    required this.onEvent,
  });
  final DateTime focused;
  final _CalendarData data;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<CalendarEventDto> onEvent;
  @override
  Widget build(BuildContext context) => TableCalendar<CalendarEventDto>(
    firstDay: DateTime.utc(2020),
    lastDay: DateTime.utc(2100),
    focusedDay: focused,
    calendarFormat: CalendarFormat.month,
    headerVisible: false,
    startingDayOfWeek: StartingDayOfWeek.monday,
    eventLoader: data.eventsOn,
    onDaySelected: (selected, _) => onDaySelected(selected),
    calendarBuilders: CalendarBuilders(
      markerBuilder: (context, day, events) {
        final due = data.todosOn(day).length;
        if (events.isEmpty && due == 0) return null;
        return Positioned(
          bottom: 3,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...events
                  .take(3)
                  .map(
                    (event) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _parseColor(event.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              if (due > 0)
                Container(
                  margin: const EdgeInsets.only(left: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    due > 3 ? '+$due' : '$due',
                    style: const TextStyle(fontSize: 8),
                  ),
                ),
            ],
          ),
        );
      },
    ),
    calendarStyle: const CalendarStyle(
      markersMaxCount: 0,
      outsideDaysVisible: false,
    ),
    daysOfWeekStyle: const DaysOfWeekStyle(
      weekdayStyle: TextStyle(fontSize: 12),
      weekendStyle: TextStyle(fontSize: 12),
    ),
  );
}

class _WeekView extends StatelessWidget {
  const _WeekView({
    super.key,
    required this.focused,
    required this.data,
    required this.onEvent,
  });
  final DateTime focused;
  final _CalendarData data;
  final ValueChanged<CalendarEventDto> onEvent;
  @override
  Widget build(BuildContext context) {
    final monday = focused.subtract(Duration(days: focused.weekday - 1));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = monday.add(Duration(days: index));
        final events = data.eventsOn(day);
        final todos = data.todosOn(day);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${['周一', '周二', '周三', '周四', '周五', '周六', '周日'][index]} ${day.month}/${day.day}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...events.map(
                  (event) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 5,
                      backgroundColor: _parseColor(event.color),
                    ),
                    title: Text(event.title),
                    subtitle: Text(_time(event.startAt)),
                    onTap: () => onEvent(event),
                  ),
                ),
                ...todos.map(
                  (todo) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.check_box_outline_blank,
                      size: 18,
                    ),
                    title: Text(todo.title),
                    subtitle: const Text('到期待办'),
                  ),
                ),
                if (events.isEmpty && todos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('暂无安排'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DayView extends StatelessWidget {
  const _DayView({
    super.key,
    required this.focused,
    required this.data,
    required this.onEvent,
  });
  final DateTime focused;
  final _CalendarData data;
  final ValueChanged<CalendarEventDto> onEvent;
  @override
  Widget build(BuildContext context) {
    final events = data.eventsOn(focused);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      children: [
        for (var hour = 0; hour < 24; hour++)
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...events
                            .where(
                              (event) => event.startAt.toLocal().hour == hour,
                            )
                            .map(
                              (event) => InkWell(
                                onTap: () => onEvent(event),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _parseColor(
                                      event.color,
                                    ).withValues(alpha: event.opacity),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${_time(event.startAt)} ${event.title}',
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _YearView extends StatelessWidget {
  const _YearView({
    super.key,
    required this.focused,
    required this.data,
    required this.onMonth,
  });
  final DateTime focused;
  final _CalendarData data;
  final ValueChanged<DateTime> onMonth;
  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      childAspectRatio: 1.25,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    ),
    itemCount: 12,
    itemBuilder: (context, index) {
      final month = DateTime(focused.year, index + 1);
      final count = data.events
          .where(
            (event) =>
                event.startAt.toLocal().year == month.year &&
                event.startAt.toLocal().month == month.month,
          )
          .length;
      return InkWell(
        onTap: () => onMonth(month),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1} 月',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '$count 个日程',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (count / 12).clamp(0.0, 1.0),
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _EventDraft {
  const _EventDraft({
    required this.title,
    this.description,
    this.location,
    required this.startAt,
    this.endAt,
    required this.allDay,
    required this.color,
    required this.opacity,
    required this.repeatRule,
  });
  final String title;
  final String? description;
  final String? location;
  final DateTime startAt;
  final DateTime? endAt;
  final bool allDay;
  final String color;
  final double opacity;
  final String repeatRule;
  Map<String, dynamic> toPatch() => {
    'title': title,
    'description': description,
    'location': location,
    'startAt': startAt,
    'endAt': endAt,
    'allDay': allDay,
    'color': color,
    'repeatRule': repeatRule,
  };
}

class _EventEditor extends StatefulWidget {
  const _EventEditor({this.event});
  final CalendarEventDto? event;
  @override
  State<_EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<_EventEditor> {
  late final TextEditingController _title = TextEditingController(
    text: widget.event?.title ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.event?.description ?? '',
  );
  late final TextEditingController _location = TextEditingController(
    text: widget.event?.location ?? '',
  );
  late DateTime _start =
      widget.event?.startAt.toLocal() ??
      DateTime.now().add(const Duration(hours: 1));
  late DateTime _end =
      widget.event?.endAt?.toLocal() ?? _start.add(const Duration(hours: 1));
  late bool _allDay = widget.event?.allDay ?? false;
  late String _color = widget.event?.color ?? '#5B8DEF';
  late double _opacity = widget.event?.opacity ?? 1;
  late String _repeat = widget.event?.repeatRule ?? 'none';
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<DateTime?> _selectDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (date == null || !mounted) return null;
    if (_allDay) return date;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    return time == null
        ? null
        : DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.event == null ? '新建日程' : '编辑日程',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: '描述',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: '地点',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('全天'),
              value: _allDay,
              onChanged: (value) => setState(() => _allDay = value),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final value = await _selectDateTime(_start);
                    if (value != null) setState(() => _start = value);
                  },
                  child: Text('开始 ${_time(_start)}'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final value = await _selectDateTime(_end);
                    if (value != null) setState(() => _end = value);
                  },
                  child: Text('结束 ${_time(_end)}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _repeat,
              decoration: const InputDecoration(
                labelText: '重复',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('不重复')),
                DropdownMenuItem(value: 'daily', child: Text('每天')),
                DropdownMenuItem(value: 'weekly', child: Text('每周')),
                DropdownMenuItem(value: 'monthly', child: Text('每月')),
                DropdownMenuItem(value: 'yearly', child: Text('每年')),
              ],
              onChanged: (v) => setState(() => _repeat = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _color,
              decoration: const InputDecoration(
                labelText: '颜色',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '#5B8DEF', child: Text('蓝')),
                DropdownMenuItem(value: '#E57373', child: Text('红')),
                DropdownMenuItem(value: '#81C784', child: Text('绿')),
                DropdownMenuItem(value: '#FFB74D', child: Text('橙')),
              ],
              onChanged: (v) => setState(() => _color = v!),
            ),
            Text('透明度 ${_opacity.toStringAsFixed(1)}'),
            Slider(
              value: _opacity,
              min: .2,
              max: 1,
              divisions: 8,
              onChanged: (v) => setState(() => _opacity = v),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _title.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(
                        context,
                        _EventDraft(
                          title: _title.text.trim(),
                          description: _description.text.trim().isEmpty
                              ? null
                              : _description.text.trim(),
                          location: _location.text.trim().isEmpty
                              ? null
                              : _location.text.trim(),
                          startAt: _start,
                          endAt: _end,
                          allDay: _allDay,
                          color: _color,
                          opacity: _opacity,
                          repeatRule: _repeat,
                        ),
                      ),
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Subscriptions extends StatefulWidget {
  const _Subscriptions({required this.repository});
  final CalendarRepository repository;
  @override
  State<_Subscriptions> createState() => _SubscriptionsState();
}

class _SubscriptionsState extends State<_Subscriptions> {
  late Future<List<CalendarSubscriptionDto>> _items = widget.repository
      .listSubscriptions();
  void _reload() =>
      setState(() => _items = widget.repository.listSubscriptions());
  Future<void> _add() async {
    final c = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加 iCal 订阅'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://example.com/calendar.ics',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    c.dispose();
    if (url == null || url.trim().isEmpty) return;
    try {
      await widget.repository.createSubscription(url: url.trim());
      _reload();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('添加失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Text('iCal 订阅', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(onPressed: _add, icon: const Icon(Icons.add)),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<CalendarSubscriptionDto>>(
              future: _items,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final items = snapshot.data!;
                if (items.isEmpty) return const Center(child: Text('暂无订阅'));
                return ListView(
                  children: items
                      .map(
                        (item) => SwitchListTile(
                          title: Text(item.name.isEmpty ? '未命名订阅' : item.name),
                          subtitle: Text(
                            item.lastError ??
                                '每 ${item.refreshIntervalMin} 分钟刷新',
                          ),
                          value: item.enabled,
                          onChanged: (value) async {
                            await widget.repository.updateSubscription(
                              item.id,
                              {'enabled': value},
                            );
                            _reload();
                          },
                          secondary: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await widget.repository.deleteSubscription(
                                item.id,
                              );
                              _reload();
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Color _parseColor(String? raw) {
  final value = (raw ?? '#5B8DEF').replaceFirst('#', '');
  final parsed = int.tryParse(value, radix: 16) ?? 0xff5b8def;
  return Color(0xff000000 | parsed);
}

String _time(DateTime value) {
  final local = value.toLocal();
  return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
