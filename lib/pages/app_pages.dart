import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/analytics/track.dart';
import '../core/api/api_client.dart';
import '../core/settings/app_settings.dart';
import '../features/auth/auth_controller.dart';
import '../features/ai/ai_repository.dart';
import '../features/skill/skill_repository.dart';
import '../features/calendar/calendar_repository.dart';
import '../features/calendar/dto.dart';
import '../features/todo/dto.dart';
import '../features/todo/todo_repository.dart';
import 'profile/developer_settings_page.dart';
import 'profile/ai_config_page.dart';
import 'ai_workspace_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('首页')),
    body: FutureBuilder<List<TodoDto>>(
      future: context.read<TodoRepository>().list(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _LoadError(error: snapshot.error);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final todos = snapshot.data!;
        final completed = todos
            .where((todo) => todo.status == TodoStatus.completed)
            .length;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('欢迎回来', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('待办和日程已连接到你的 NexusMind 账户。'),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('待办完成情况'),
                subtitle: Text('已完成 $completed / ${todos.length}'),
                onTap: () {
                  track('dashboard_quick_entry', {'target': 'todo'});
                  context.go('/todo');
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('日历'),
                subtitle: const Text('查看月视图与即将到来的安排'),
                onTap: () {
                  track('dashboard_quick_entry', {'target': 'calendar'});
                  context.go('/calendar');
                },
              ),
            ),
            const SizedBox(height: 10),
            const _DashboardMiniMonth(),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: const Text('专家工作台'),
                subtitle: const Text('创建可追踪的建议草稿'),
                onTap: () {
                  track('dashboard_quick_entry', {'target': 'expert'});
                  context.go('/expert');
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _DashboardMiniMonth extends StatefulWidget {
  const _DashboardMiniMonth();

  @override
  State<_DashboardMiniMonth> createState() => _DashboardMiniMonthState();
}

class _DashboardMiniMonthState extends State<_DashboardMiniMonth> {
  late final Future<List<CalendarEventDto>> _events;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _events = context.read<CalendarRepository>().listEvents(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month + 1, 1),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: () => context.go('/calendar'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: FutureBuilder<List<CalendarEventDto>>(
          future: _events,
          builder: (context, snapshot) {
            final events = snapshot.data ?? const <CalendarEventDto>[];
            return TableCalendar<CalendarEventDto>(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2100),
              focusedDay: DateTime.now(),
              headerVisible: false,
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: '月'},
              eventLoader: (day) => events
                  .where((event) => DateUtils.isSameDay(event.startAt, day))
                  .toList(),
              calendarStyle: const CalendarStyle(
                markersMaxCount: 2,
                outsideDaysVisible: false,
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 11),
                weekendStyle: TextStyle(fontSize: 11),
              ),
              onDaySelected: (_, __) => context.go('/calendar'),
            );
          },
        ),
      ),
    ),
  );
}

class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  late Future<List<TodoDto>> _todos;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _todos = context.read<TodoRepository>().list();

  Future<void> _createTodo() async {
    final title = await _showTitleDialog(context, '新建待办');
    if (title == null || title.trim().isEmpty || !mounted) return;
    try {
      await context.read<TodoRepository>().create(title: title.trim());
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  Future<void> _toggle(TodoDto todo) async {
    final next = todo.status == TodoStatus.completed ? 'pending' : 'completed';
    try {
      await context.read<TodoRepository>().update(todo.id, {'status': next});
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('待办'),
      actions: [
        IconButton(
          tooltip: '刷新',
          onPressed: () => setState(_reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      tooltip: '新建待办',
      onPressed: _createTodo,
      child: const Icon(Icons.add),
    ),
    body: FutureBuilder<List<TodoDto>>(
      future: _todos,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _LoadError(error: snapshot.error);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final todos = snapshot.data!;
        if (todos.isEmpty) return const _EmptyState(text: '还没有待办');
        return RefreshIndicator(
          onRefresh: () async => setState(_reload),
          child: ListView.builder(
            itemCount: todos.length,
            itemBuilder: (_, index) {
              final todo = todos[index];
              final done = todo.status == TodoStatus.completed;
              return CheckboxListTile(
                value: done,
                onChanged: (_) => _toggle(todo),
                title: Text(todo.title),
                subtitle: todo.dueAt == null
                    ? null
                    : Text('截止：${_formatDate(todo.dueAt!)}'),
              );
            },
          ),
        );
      },
    ),
  );
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Future<List<CalendarEventDto>> _events;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _events = context.read<CalendarRepository>().listEvents();

  Future<void> _createEvent() async {
    final title = await _showTitleDialog(context, '新建日程');
    if (title == null || title.trim().isEmpty || !mounted) return;
    try {
      final start = DateTime.now().add(const Duration(hours: 1));
      await context.read<CalendarRepository>().createEvent(
        title: title.trim(),
        startAt: start,
        endAt: start.add(const Duration(hours: 1)),
        timezone: 'Asia/Shanghai',
      );
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('日历'),
      actions: [
        IconButton(
          tooltip: '刷新',
          onPressed: () => setState(_reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      tooltip: '新建日程',
      onPressed: _createEvent,
      child: const Icon(Icons.add),
    ),
    body: FutureBuilder<List<CalendarEventDto>>(
      future: _events,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _LoadError(error: snapshot.error);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snapshot.data!;
        if (events.isEmpty) return const _EmptyState(text: '还没有日程');
        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (_, index) {
            final event = events[index];
            return ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(event.title),
              subtitle: Text(_formatDate(event.startAt)),
            );
          },
        );
      },
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
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(profile?.displayName ?? 'NexusMind 用户'),
            subtitle: Text(profile?.timezone ?? ''),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('深色模式'),
            value: themeMode == ThemeMode.dark,
            onChanged: (dark) =>
                onThemeChanged(dark ? ThemeMode.dark : ThemeMode.light, accent),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('语言'),
            subtitle: Text(
              context.watch<AppSettings>().language == 'en'
                  ? 'English'
                  : '简体中文',
            ),
            trailing: DropdownButton<String>(
              value: context.watch<AppSettings>().language,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'zh-CN', child: Text('简体中文')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) {
                if (value != null)
                  context.read<AppSettings>().setLanguage(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.hub_outlined),
            title: const Text('连接服务'),
            subtitle: const Text('管理家庭服务的数据访问与连接状态'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/connectors'),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: const Text('AI 配置'),
            subtitle: const Text('模型、Endpoint 与安全密钥'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AiConfigPage(repository: context.read<AiRepository>()),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sync_outlined),
            title: const Text('同步设置'),
            subtitle: const Text('按最后修改时间合并当前主题与语言'),
            onTap: () async {
              try {
                await context.read<AppSettings>().sync(
                  context.read<ApiClient>(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('设置同步完成')));
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('同步失败：$error')));
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.summarize_outlined),
            title: const Text('日报与周报'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReportsPage(
                  todoRepository: context.read<TodoRepository>(),
                  skillRepository: context.read<SkillRepository>(),
                  aiRepository: context.read<AiRepository>(),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.psychology_outlined),
            title: const Text('AI Skills'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    SkillsPage(repository: context.read<SkillRepository>()),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.developer_mode_outlined),
            title: const Text('开发者设置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DeveloperSettingsPage(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            onTap: () async {
              await context.read<AuthController>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('加载失败：$error', textAlign: TextAlign.center),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(child: Text(text));
}

Future<String?> _showTitleDialog(BuildContext context, String title) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: '标题'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('创建'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('操作失败：$error')));
}
