import 'package:flutter/material.dart';

void main() => runApp(const HomeMindApp());

enum TodoPriority { high, medium, low }

class Todo {
  Todo({
    required this.id,
    required this.title,
    this.dueDate,
    this.done = false,
    this.priority = TodoPriority.medium,
    this.category = '工作',
    this.pinned = false,
  });

  final String id;
  final String title;
  final DateTime? dueDate;
  bool done;
  final TodoPriority priority;
  final String category;
  final bool pinned;
}

class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.color,
    this.allDay = false,
  });

  final String id;
  final String title;
  final DateTime date;
  final Color color;
  final bool allDay;
}

class HomeMindApp extends StatefulWidget {
  const HomeMindApp({super.key});

  @override
  State<HomeMindApp> createState() => _HomeMindAppState();
}

class _HomeMindAppState extends State<HomeMindApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  Color _accent = const Color(0xffa6d7c7);
  final DateTime _now = DateTime.now();
  late final List<Todo> _todos = [
    Todo(
      id: '1',
      title: '整理本周会议纪要',
      dueDate: _now.add(const Duration(hours: 2)),
      priority: TodoPriority.high,
      pinned: true,
    ),
    Todo(
      id: '2',
      title: '完成季度报告',
      dueDate: _now.add(const Duration(days: 1)),
      priority: TodoPriority.high,
    ),
    Todo(
      id: '3',
      title: '阅读产品设计文档',
      dueDate: _now.add(const Duration(days: 2)),
      category: '学习',
    ),
    Todo(
      id: '4',
      title: '运动 30 分钟',
      dueDate: _now.subtract(const Duration(days: 1)),
      category: '健康',
    ),
    Todo(
      id: '5',
      title: '回复客户邮件',
      done: true,
      dueDate: _now.subtract(const Duration(hours: 3)),
    ),
    Todo(id: '6', title: '复盘本月目标', done: true, category: '工作'),
  ];
  late final List<CalendarEvent> _events = [
    CalendarEvent(
      id: 'e1',
      title: '团队周会',
      date: _at(_now, 10),
      color: const Color(0xffa6d7c7),
    ),
    CalendarEvent(
      id: 'e2',
      title: '产品评审',
      date: _at(_now, 14),
      color: const Color(0xffe6d2a9),
    ),
    CalendarEvent(
      id: 'e3',
      title: '提交季度报告',
      date: _now.add(const Duration(days: 2)),
      color: const Color(0xffef8f92),
      allDay: true,
    ),
  ];

  static DateTime _at(DateTime d, int hour) =>
      DateTime(d.year, d.month, d.day, hour);

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      brightness: _themeMode == ThemeMode.dark
          ? Brightness.dark
          : Brightness.light,
      useMaterial3: true,
      fontFamily: 'Microsoft YaHei',
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: base.brightness,
    ).copyWith(primary: _accent, secondary: const Color(0xffd8c9a8));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HomeMind',
      theme: base.copyWith(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xff0d0d0f),
        cardColor: const Color(0xff17171b),
      ),
      home: HomeMindShell(
        todos: _todos,
        events: _events,
        themeMode: _themeMode,
        accent: _accent,
        onToggleTodo: (todo) => setState(() => todo.done = !todo.done),
        onAddTodo: (title) => setState(
          () => _todos.insert(
            0,
            Todo(
              id: '${DateTime.now().microsecondsSinceEpoch}',
              title: title,
              dueDate: DateTime.now().add(const Duration(days: 1)),
              priority: TodoPriority.medium,
            ),
          ),
        ),
        onAddEvent: (title, date) => setState(
          () => _events.add(
            CalendarEvent(
              id: '${DateTime.now().microsecondsSinceEpoch}',
              title: title,
              date: date,
              color: _accent,
            ),
          ),
        ),
        onThemeChanged: (mode, accent) => setState(() {
          _themeMode = mode;
          _accent = accent;
        }),
      ),
    );
  }
}

class HomeMindShell extends StatefulWidget {
  const HomeMindShell({
    super.key,
    required this.todos,
    required this.events,
    required this.themeMode,
    required this.accent,
    required this.onToggleTodo,
    required this.onAddTodo,
    required this.onAddEvent,
    required this.onThemeChanged,
  });
  final List<Todo> todos;
  final List<CalendarEvent> events;
  final ThemeMode themeMode;
  final Color accent;
  final ValueChanged<Todo> onToggleTodo;
  final ValueChanged<String> onAddTodo;
  final void Function(String, DateTime) onAddEvent;
  final void Function(ThemeMode, Color) onThemeChanged;

  @override
  State<HomeMindShell> createState() => _HomeMindShellState();
}

class _HomeMindShellState extends State<HomeMindShell> {
  int _index = 0;
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _controller,
          onPageChanged: (v) => setState(() => _index = v),
          children: [
            StatisticsPage(todos: widget.todos),
            TodoPage(
              todos: widget.todos,
              onToggle: widget.onToggleTodo,
              onAdd: widget.onAddTodo,
            ),
            const FeaturePage(
              icon: Icons.timer_outlined,
              title: '番茄',
              subtitle: '把专注变成每天看得见的进步',
              action: '开始专注',
            ),
            const FeaturePage(
              icon: Icons.track_changes_outlined,
              title: '计划',
              subtitle: '把目标拆成今天可以完成的动作',
              action: '创建计划',
            ),
            CalendarPage(events: widget.events, onAdd: widget.onAddEvent),
            const FeaturePage(
              icon: Icons.hourglass_bottom_outlined,
              title: '倒数',
              subtitle: '重要的日子，值得提前准备',
              action: '新建倒数',
            ),
            ProfilePage(
              themeMode: widget.themeMode,
              accent: widget.accent,
              onThemeChanged: widget.onThemeChanged,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onSelect: (i) {
          setState(() => _index = i);
          _controller.jumpToPage(i);
        },
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;
  static const items = [
    (Icons.bar_chart_rounded, '统计'),
    (Icons.checklist_rounded, '待办'),
    (Icons.timer_outlined, '番茄'),
    (Icons.track_changes_outlined, '计划'),
    (Icons.calendar_month_rounded, '日历'),
    (Icons.hourglass_bottom_rounded, '倒数'),
    (Icons.person_rounded, '我的'),
  ];
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xff19191d).withValues(alpha: .98),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xff303037)),
      boxShadow: const [
        BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 7)),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(items.length, (i) {
        final selected = i == index;
        final item = items[i];
        return InkWell(
          onTap: () => onSelect(i),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 45,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.$1,
                  size: 21,
                  color: selected
                      ? const Color(0xff17171b)
                      : const Color(0xffa4a2ad),
                ),
                const SizedBox(height: 3),
                Text(
                  item.$2,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? const Color(0xff17171b)
                        : const Color(0xffaaa8b2),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ),
  );
}

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key, required this.todos});
  final List<Todo> todos;
  @override
  Widget build(BuildContext context) {
    final done = todos.where((t) => t.done).length;
    final total = todos.length;
    final rate = total == 0 ? 0 : (done / total * 100).round();
    final overdue = todos
        .where(
          (t) =>
              !t.done &&
              t.dueDate != null &&
              t.dueDate!.isBefore(DateTime.now()),
        )
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        const Text(
          '统计',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          '看见每一点小小的坚持',
          style: TextStyle(color: Color(0xffaaa8b2), fontSize: 15),
        ),
        const SizedBox(height: 22),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: .86,
          children: [
            _Metric(
              icon: Icons.checklist_rounded,
              value: '$done',
              label: '今日完成',
              color: const Color(0xffa6d7c7),
            ),
            _Metric(
              icon: Icons.add_circle_outline,
              value: '${total - done}',
              label: '今日新增',
              color: const Color(0xfff4f1eb),
            ),
            _Metric(
              icon: Icons.donut_large_rounded,
              value: '${total - done}',
              label: '进行中',
              color: const Color(0xffe6d2a9),
            ),
            _Metric(
              icon: Icons.show_chart_rounded,
              value: '$rate%',
              label: '完成率',
              color: const Color(0xffb9c6db),
            ),
            _Metric(
              icon: Icons.notifications_active_outlined,
              value: '$overdue',
              label: '已逾期',
              color: const Color(0xffef6b70),
            ),
            _Metric(
              icon: Icons.event_available_outlined,
              value: '0',
              label: '今日到期',
              color: const Color(0xffe6d2a9),
            ),
            _Metric(
              icon: Icons.flag_outlined,
              value: '2',
              label: '高优先',
              color: const Color(0xfff4f1eb),
            ),
            _Metric(
              icon: Icons.hourglass_bottom_outlined,
              value: '2.1 小时',
              label: '均完成用时',
              color: const Color(0xffb9c6db),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _CompletionCard(done: done, total: total, rate: rate),
        const SizedBox(height: 16),
        _SevenDayCard(),
        const SizedBox(height: 16),
        _HeatmapCard(),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value, label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(5, 11, 5, 8),
    decoration: BoxDecoration(
      color: const Color(0xff18181c),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xff2d2d34)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xffaaa8b2), fontSize: 10),
        ),
      ],
    ),
  );
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({
    required this.done,
    required this.total,
    required this.rate,
  });
  final int done, total, rate;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Row(
      children: [
        SizedBox(
          width: 128,
          height: 128,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: rate / 100,
                strokeWidth: 11,
                backgroundColor: const Color(0xff2a2c35),
                color: const Color(0xffa6d7c7),
              ),
              Text(
                '$rate%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '待办完成率',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '共 $total 项 · 已完成 $done',
                style: const TextStyle(color: Color(0xffaaa8b2), fontSize: 14),
              ),
              const SizedBox(height: 5),
              const Text(
                '本周完成 12 · 上周 ↑ 4',
                style: TextStyle(color: Color(0xffaaa8b2), fontSize: 14),
              ),
              const SizedBox(height: 5),
              const Text(
                '近 7 天均完成 4.4 项',
                style: TextStyle(color: Color(0xffaaa8b2), fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '⏱ 按时完成率 40% · 8/20 项在截止前完成',
                style: TextStyle(color: Color(0xffef8f92), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SevenDayCard extends StatelessWidget {
  const _SevenDayCard();
  @override
  Widget build(BuildContext context) {
    const values = [0, 0, 0, 0, 1, 17, 13];
    const labels = ['六', '日', '一', '二', '三', '四', '今'];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '近 7 天完成待办',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(values.length, (i) {
                final v = values[i];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      v == 0 ? '' : '$v',
                      style: const TextStyle(
                        color: Color(0xffb9b5c1),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 38,
                      height: v == 0 ? 8 : (v * 6.5).clamp(18, 108).toDouble(),
                      decoration: BoxDecoration(
                        color: i == 6
                            ? const Color(0xffa6d7c7)
                            : i == 5
                            ? const Color(0xffe6d2a9)
                            : const Color(0xff2b2c33),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[i],
                      style: const TextStyle(
                        color: Color(0xffaaa8b2),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard();
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              '近 4 周完成热力',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            Spacer(),
            Text(
              '越亮越努力',
              style: TextStyle(color: Color(0xffaaa8b2), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 28,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
          ),
          itemBuilder: (_, i) {
            final level = (i * 7 + 3) % 5;
            return Container(
              decoration: BoxDecoration(
                color: level == 0
                    ? const Color(0xff24252b)
                    : Color.lerp(
                        const Color(0xff244039),
                        const Color(0xff37c88b),
                        level / 4,
                      ),
                borderRadius: BorderRadius.circular(7),
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xff18181c),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xff2d2d34)),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 5)),
      ],
    ),
    child: child,
  );
}

class TodoPage extends StatefulWidget {
  const TodoPage({
    super.key,
    required this.todos,
    required this.onToggle,
    required this.onAdd,
  });
  final List<Todo> todos;
  final ValueChanged<Todo> onToggle;
  final ValueChanged<String> onAdd;
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  bool board = true;
  int filter = 0;
  @override
  Widget build(BuildContext context) {
    final list = widget.todos
        .where((t) => filter == 0 || (filter == 1 ? !t.done : t.done))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Row(
            children: [
              const Text(
                '待办',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showAdd(context),
                icon: const Icon(Icons.add_circle_outline, size: 28),
                tooltip: '新建待办',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('全部'),
                selected: filter == 0,
                onSelected: (_) => setState(() => filter = 0),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('未完成'),
                selected: filter == 1,
                onSelected: (_) => setState(() => filter = 1),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('已完成'),
                selected: filter == 2,
                onSelected: (_) => setState(() => filter = 2),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => board = !board),
                icon: Icon(
                  board ? Icons.view_kanban_outlined : Icons.view_list_outlined,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: board
              ? _Board(todos: list, onToggle: widget.onToggle)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: list
                      .map(
                        (t) => _TodoTile(
                          todo: t,
                          onToggle: () => widget.onToggle(t),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  void _showAdd(BuildContext context) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新建待办'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如：准备周报'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) widget.onAdd(c.text.trim());
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.todos, required this.onToggle});
  final List<Todo> todos;
  final ValueChanged<Todo> onToggle;
  @override
  Widget build(BuildContext context) {
    final groups = {
      '进行中': todos.where((t) => !t.done).toList(),
      '已完成': todos.where((t) => t.done).toList(),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: groups.entries
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.key}  ${e.value.length}',
                    style: const TextStyle(
                      color: Color(0xffaaa8b2),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...e.value.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TodoTile(todo: t, onToggle: () => onToggle(t)),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({required this.todo, required this.onToggle});
  final Todo todo;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) {
    final color = todo.priority == TodoPriority.high
        ? const Color(0xffef6b70)
        : todo.priority == TodoPriority.medium
        ? const Color(0xffe6d2a9)
        : const Color(0xffa6d7c7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xff18181c),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff2d2d34)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onToggle,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              todo.done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: todo.done ? const Color(0xffa6d7c7) : color,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 15,
                    decoration: todo.done ? TextDecoration.lineThrough : null,
                    color: todo.done ? const Color(0xff777681) : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      todo.category,
                      style: const TextStyle(
                        color: Color(0xffaaa8b2),
                        fontSize: 12,
                      ),
                    ),
                    if (todo.dueDate != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.schedule,
                        size: 13,
                        color: const Color(0xffaaa8b2),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _dueLabel(todo.dueDate!),
                        style: const TextStyle(
                          color: Color(0xffaaa8b2),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.events, required this.onAdd});
  final List<CalendarEvent> events;
  final void Function(String, DateTime) onAdd;
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final selectedEvents = widget.events
        .where((e) => _sameDay(e.date, selected))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Row(
          children: [
            const Text(
              '日历',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showAdd(context),
              icon: const Icon(Icons.add_circle_outline, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Panel(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(
                      () => month = DateTime(month.year, month.month - 1),
                    ),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${month.year}年${month.month}月',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(
                      () => month = DateTime(month.year, month.month + 1),
                    ),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['一', '二', '三', '四', '五', '六', '日']
                    .map(
                      (d) => Text(
                        d,
                        style: const TextStyle(
                          color: Color(0xffaaa8b2),
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 42,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: .92,
                ),
                itemBuilder: (_, i) {
                  final day = i - offset + 1;
                  if (day < 1 || day > days) return const SizedBox();
                  final date = DateTime(month.year, month.month, day);
                  final active = _sameDay(date, selected);
                  final hasEvent = widget.events.any(
                    (e) => _sameDay(e.date, date),
                  );
                  return GestureDetector(
                    onTap: () => setState(() => selected = date),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xffa6d7c7)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              color: active
                                  ? const Color(0xff151619)
                                  : Colors.white,
                              fontWeight: active
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          if (hasEvent)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xff151619)
                                    : const Color(0xffe6d2a9),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${selected.month}月${selected.day}日 · 日程',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        ...selectedEvents.map(
          (e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xff18181c),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xff2d2d34)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 35,
                  decoration: BoxDecoration(
                    color: e.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.allDay ? '全天' : _timeLabel(e.date),
                      style: const TextStyle(
                        color: Color(0xffaaa8b2),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAdd(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新建日程'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '例如：客户回访'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.onAdd(controller.text.trim(), selected);
              }
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class FeaturePage extends StatelessWidget {
  const FeaturePage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });
  final IconData icon;
  final String title, subtitle, action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: _Panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: const Color(0xffa6d7c7)),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xffaaa8b2)),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: Text(action),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.themeMode,
    required this.accent,
    required this.onThemeChanged,
  });
  final ThemeMode themeMode;
  final Color accent;
  final void Function(ThemeMode, Color) onThemeChanged;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
    children: [
      const Text(
        '我的',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 18),
      _Panel(
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xffa6d7c7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xff151619),
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HomeMind 用户',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text('保持专注，持续成长', style: TextStyle(color: Color(0xffaaa8b2))),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _Panel(
        child: Column(
          children: [
            _setting(
              Icons.dark_mode_outlined,
              '深色模式',
              Switch(
                value: themeMode == ThemeMode.dark,
                onChanged: (v) => onThemeChanged(
                  v ? ThemeMode.dark : ThemeMode.light,
                  accent,
                ),
              ),
            ),
            _setting(
              Icons.palette_outlined,
              '强调色',
              Row(
                children: [
                  for (final c in [
                    const Color(0xffa6d7c7),
                    const Color(0xffe6d2a9),
                    const Color(0xffb9c6db),
                  ])
                    GestureDetector(
                      onTap: () => onThemeChanged(themeMode, c),
                      child: Container(
                        margin: const EdgeInsets.only(left: 10),
                        width: 23,
                        height: 23,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c == accent
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _Panel(
        child: Column(
          children: [
            _setting(
              Icons.notifications_none_rounded,
              '提醒设置',
              const Icon(Icons.chevron_right, color: Color(0xffaaa8b2)),
            ),
            _setting(
              Icons.backup_outlined,
              '数据备份',
              const Icon(Icons.chevron_right, color: Color(0xffaaa8b2)),
            ),
            _setting(
              Icons.info_outline_rounded,
              '关于 HomeMind',
              const Icon(Icons.chevron_right, color: Color(0xffaaa8b2)),
            ),
          ],
        ),
      ),
    ],
  );
  Widget _setting(IconData icon, String title, Widget trailing) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xffaaa8b2)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        trailing,
      ],
    ),
  );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String _timeLabel(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
String _dueLabel(DateTime t) {
  final now = DateTime.now();
  if (_sameDay(t, now)) return '今天 ${_timeLabel(t)}';
  if (_sameDay(t, now.add(const Duration(days: 1)))) return '明天';
  return '${t.month}/${t.day}';
}
