import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/analytics/track.dart';
import '../core/ui/nexus_theme.dart';
import '../experts/domain.dart';
import '../experts/expert_repository.dart';
import '../features/auth/auth_controller.dart';
import '../features/calendar/calendar_repository.dart';
import '../features/calendar/dto.dart';
import '../features/smart_home/dto.dart';
import '../features/smart_home/smart_home_repository.dart';
import '../features/todo/dto.dart';
import '../features/todo/todo_repository.dart';

class NexusHomePage extends StatefulWidget {
  const NexusHomePage({super.key});

  @override
  State<NexusHomePage> createState() => _NexusHomePageState();
}

class _NexusHomePageState extends State<NexusHomePage> {
  late Future<_HomeDashboardData> _home;
  late Future<_PlanDashboardData> _plan;
  late Future<List<Expert>> _experts;
  bool _suggestionVisible = true;

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  void _reloadAll() {
    _home = _loadHome();
    _plan = _loadPlan();
    _experts = context.read<ExpertRepository>().listExperts();
  }

  Future<_HomeDashboardData> _loadHome() async {
    final repository = context.read<SmartHomeRepository>();
    final data = await Future.wait<Object>([
      repository.listSpaces(),
      repository.listDevices(),
      repository.listScenes(),
    ]);
    final devices = data[1] as List<SmartHomeDeviceDto>;
    return _HomeDashboardData(
      spaces: data[0] as List<SmartHomeSpaceDto>,
      devices: devices,
      scenes: data[2] as List<SmartSceneDto>,
      updatedAt: _latestUpdate(
        devices.map((device) => device.updatedAt),
        fallback: DateTime.now(),
      ),
    );
  }

  Future<_PlanDashboardData> _loadPlan() async {
    final data = await Future.wait<Object>([
      context.read<TodoRepository>().list(),
      context.read<CalendarRepository>().listEvents(),
    ]);
    final todos = data[0] as List<TodoDto>;
    final events = data[1] as List<CalendarEventDto>;
    return _PlanDashboardData(
      todos: data[0] as List<TodoDto>,
      events: events,
      updatedAt: _latestUpdate([
        ...todos.map((todo) => todo.updatedAt),
        ...events.map((event) => event.updatedAt),
      ], fallback: DateTime.now()),
    );
  }

  Future<void> _refresh() async {
    setState(_reloadAll);
    await Future.wait([_home, _plan, _experts]);
  }

  void _reloadHome() => setState(() {
    _home = _loadHome();
  });

  void _reloadPlan() => setState(() {
    _plan = _loadPlan();
  });

  void _reloadExperts() => setState(() {
    _experts = context.read<ExpertRepository>().listExperts();
  });

  void _goTo(String location) {
    track('dashboard_quick_entry', {'target': location});
    context.go(location);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final displayName = profile?.displayName.trim();
    final name = displayName == null || displayName.isEmpty ? '你' : displayName;
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: NexusLayout.pagePadding.copyWith(bottom: 36),
            children: [
              _HomeHeader(
                name: name,
                now: now,
                onNotifications: () => _showMessage('当前没有新的提醒'),
              ),
              const SizedBox(height: NexusLayout.sectionGap),
              _PlanDashboardSection(
                future: _plan,
                now: now,
                suggestionVisible: _suggestionVisible,
                onDismissSuggestion: () =>
                    setState(() => _suggestionVisible = false),
                onOpenPlan: () => _goTo('/plan'),
                onOpenExpert: () => _goTo('/ai'),
                onRetry: _reloadPlan,
              ),
              const SizedBox(height: NexusLayout.sectionGap),
              _HomeDashboardSection(
                future: _home,
                onOpenHome: () => _goTo('/home-plus'),
                onRetry: _reloadHome,
              ),
              const SizedBox(height: NexusLayout.sectionGap),
              _ExpertDashboardSection(
                future: _experts,
                onOpenAi: () => _goTo('/ai'),
                onRetry: _reloadExperts,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeDashboardData {
  const _HomeDashboardData({
    required this.spaces,
    required this.devices,
    required this.scenes,
    required this.updatedAt,
  });

  final List<SmartHomeSpaceDto> spaces;
  final List<SmartHomeDeviceDto> devices;
  final List<SmartSceneDto> scenes;
  final DateTime updatedAt;
}

class _PlanDashboardData {
  const _PlanDashboardData({
    required this.todos,
    required this.events,
    required this.updatedAt,
  });

  final List<TodoDto> todos;
  final List<CalendarEventDto> events;
  final DateTime updatedAt;
}

class _PlanDashboardSection extends StatelessWidget {
  const _PlanDashboardSection({
    required this.future,
    required this.now,
    required this.suggestionVisible,
    required this.onDismissSuggestion,
    required this.onOpenPlan,
    required this.onOpenExpert,
    required this.onRetry,
  });

  final Future<_PlanDashboardData> future;
  final DateTime now;
  final bool suggestionVisible;
  final VoidCallback onDismissSuggestion;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenExpert;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FutureBuilder<_PlanDashboardData>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(title: '今日计划', action: '重试', onAction: onRetry),
            const SizedBox(height: 12),
            _DashboardCardError(message: '计划数据暂时无法加载', onRetry: onRetry),
          ],
        );
      }
      if (!snapshot.hasData) {
        return const _DashboardCardLoading(title: '今日计划');
      }

      final data = snapshot.data!;
      final pending = data.todos
          .where((todo) => todo.status != TodoStatus.completed)
          .length;
      final todayEvents =
          data.events
              .where((event) => DateUtils.isSameDay(event.startAt, now))
              .toList()
            ..sort((left, right) => left.startAt.compareTo(right.startAt));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (suggestionVisible) ...[
            _TodaySuggestionCard(
              pendingTodos: pending,
              todayEvents: todayEvents.length,
              onExecute: onOpenPlan,
              onDismiss: onDismissSuggestion,
              onExpert: onOpenExpert,
            ),
            const SizedBox(height: NexusLayout.sectionGap),
          ],
          _SectionHeading(
            title: '今日计划',
            action: '$pending 项待处理',
            onAction: onOpenPlan,
          ),
          const SizedBox(height: 12),
          _TodayPlanCard(
            pendingTodos: pending,
            events: todayEvents,
            updatedAt: data.updatedAt,
            onTap: onOpenPlan,
          ),
        ],
      );
    },
  );
}

class _HomeDashboardSection extends StatelessWidget {
  const _HomeDashboardSection({
    required this.future,
    required this.onOpenHome,
    required this.onRetry,
  });

  final Future<_HomeDashboardData> future;
  final VoidCallback onOpenHome;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FutureBuilder<_HomeDashboardData>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(
              title: '家庭状态',
              action: '重试',
              actionColor: Theme.of(context).colorScheme.secondary,
              onAction: onRetry,
            ),
            const SizedBox(height: 12),
            _DashboardCardError(message: '家庭状态暂时无法加载', onRetry: onRetry),
          ],
        );
      }
      if (!snapshot.hasData) {
        return const _DashboardCardLoading(title: '家庭状态');
      }

      final data = snapshot.data!;
      final online = data.devices.where((device) => device.isOnline).length;
      final summary = SmartHomeSummary(
        location: data.spaces.length == 1 ? data.spaces.first.name : '我的家',
        headline: data.devices.isEmpty
            ? '已连接 ${data.spaces.length} 个家庭空间'
            : '$online / ${data.devices.length} 台设备在线',
        devices: data.devices
            .take(3)
            .map(
              (device) => SmartHomeDevice(
                icon: _dashboardDeviceIcon(device.type),
                label: device.name,
                detail: device.statusText,
                active: device.isOnline,
              ),
            )
            .toList(growable: false),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: '家庭状态',
            action: '查看家庭',
            actionColor: Theme.of(context).colorScheme.secondary,
            onAction: onOpenHome,
          ),
          const SizedBox(height: 12),
          if (data.spaces.isEmpty)
            _DashboardEmptyCard(message: '还没有可显示的家庭空间', onOpen: onOpenHome)
          else
            NexusSmartHomeCard(
              summary: summary,
              updatedAt: data.updatedAt,
              onTap: onOpenHome,
            ),
          const SizedBox(height: NexusLayout.sectionGap),
          _SectionHeading(title: '智能场景', action: '查看全部', onAction: onOpenHome),
          const SizedBox(height: 12),
          if (data.scenes.isEmpty)
            _DashboardEmptyCard(message: '暂时没有可用的智能场景', onOpen: onOpenHome)
          else
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.scenes.length.clamp(0, 3).toInt(),
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final scene = data.scenes[index];
                  return _SmartSceneCard(
                    icon: _sceneIcon(scene.key),
                    label: scene.name,
                    description: scene.description,
                    onTap: onOpenHome,
                  );
                },
              ),
            ),
        ],
      );
    },
  );
}

class _ExpertDashboardSection extends StatelessWidget {
  const _ExpertDashboardSection({
    required this.future,
    required this.onOpenAi,
    required this.onRetry,
  });

  final Future<List<Expert>> future;
  final VoidCallback onOpenAi;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Expert>>(
    future: future,
    builder: (context, snapshot) {
      final content = switch (snapshot) {
        AsyncSnapshot(hasError: true) => _DashboardCardError(
          message: '专家数据暂时无法加载',
          onRetry: onRetry,
        ),
        AsyncSnapshot(hasData: false) => const _DashboardCardLoading(
          title: '我的专家',
        ),
        AsyncSnapshot(:final data?) when data.isEmpty => _EmptyExpertCard(
          onCreate: onOpenAi,
        ),
        AsyncSnapshot(:final data?) => NexusExpertCard(
          expert: data.first,
          onTap: () => context.push('/ai/${data.first.id}'),
        ),
        _ => const _DashboardCardLoading(title: '我的专家'),
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(title: '我的专家', action: '全部专家', onAction: onOpenAi),
          const SizedBox(height: 12),
          content,
        ],
      );
    },
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.now,
    required this.onNotifications,
  });

  final String name;
  final DateTime now;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final subtitle = '${now.month}月${now.day}日 星期${weekdays[now.weekday - 1]}';
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('你好，$name', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton.outlined(
          tooltip: '通知',
          onPressed: onNotifications,
          icon: const Icon(Icons.notifications_outlined),
        ),
      ],
    );
  }
}

class _TodaySuggestionCard extends StatelessWidget {
  const _TodaySuggestionCard({
    required this.pendingTodos,
    required this.todayEvents,
    required this.onExecute,
    required this.onDismiss,
    required this.onExpert,
  });

  final int pendingTodos;
  final int todayEvents;
  final VoidCallback onExecute;
  final VoidCallback onDismiss;
  final VoidCallback onExpert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 20,
            bottom: 20,
            child: Container(width: 3, color: theme.colorScheme.primary),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.auto_awesome_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('今日建议', style: theme.textTheme.titleLarge),
                    ),
                    IconButton(
                      tooltip: '忽略建议',
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  pendingTodos == 0
                      ? '今天的计划已经很清晰，留一段专注时间给最重要的事。'
                      : '先完成 $pendingTodos 项待办中的优先事项，再安排${todayEvents == 0 ? '一段专注时间' : '今天的 $todayEvents 个日程'}。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: onExecute,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text('查看计划'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.outlined(
                      tooltip: '交给专家',
                      onPressed: onExpert,
                      icon: const Icon(Icons.psychology_outlined),
                    ),
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.action,
    this.actionColor,
    this.onAction,
  });

  final String title;
  final String action;
  final Color? actionColor;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final color = actionColor ?? Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: color),
          child: Text(action),
        ),
      ],
    );
  }
}

class SmartHomeSummary {
  const SmartHomeSummary({
    required this.location,
    required this.headline,
    required this.devices,
  });

  final String location;
  final String headline;
  final List<SmartHomeDevice> devices;
}

class SmartHomeDevice {
  const SmartHomeDevice({
    required this.icon,
    required this.label,
    required this.detail,
    required this.active,
  });

  final IconData icon;
  final String label;
  final String detail;
  final bool active;
}

class NexusSmartHomeCard extends StatelessWidget {
  const NexusSmartHomeCard({
    super.key,
    required this.summary,
    required this.updatedAt,
    required this.onTap,
  });

  final SmartHomeSummary summary;
  final DateTime updatedAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
      child: NexusSurface(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.home_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.location,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        summary.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.verified_rounded,
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
            if (summary.devices.isEmpty) ...[
              const SizedBox(height: 18),
              Text(
                '暂时没有可显示的设备摘要',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              const SizedBox(height: 18),
              Row(
                children: summary.devices
                    .map(
                      (device) => Expanded(child: _HomeMetric(device: device)),
                    )
                    .toList(),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12),
              child: Divider(height: 1, color: theme.dividerColor),
            ),
            Row(
              children: [
                Icon(
                  Icons.update_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '更新于 ${_formatFreshness(updatedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeMetric extends StatelessWidget {
  const _HomeMetric({required this.device});

  final SmartHomeDevice device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = device.active
        ? theme.colorScheme.secondary
        : theme.colorScheme.onSurfaceVariant;
    return Column(
      children: [
        Icon(device.icon, color: color, size: 20),
        const SizedBox(height: 7),
        Text(
          device.detail,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          device.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  const _TodayPlanCard({
    required this.pendingTodos,
    required this.events,
    required this.updatedAt,
    required this.onTap,
  });

  final int pendingTodos;
  final List<CalendarEventDto> events;
  final DateTime updatedAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = events.isEmpty ? null : events.first;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
      child: NexusSurface(
        child: Column(
          children: [
            Row(
              children: [
                _PlanCount(
                  icon: Icons.checklist_rounded,
                  count: pendingTodos,
                  label: '待办',
                ),
                Container(width: 1, height: 42, color: theme.dividerColor),
                _PlanCount(
                  icon: Icons.calendar_today_outlined,
                  count: events.length,
                  label: '日程',
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: theme.dividerColor),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  event == null
                      ? Icons.wb_sunny_outlined
                      : Icons.schedule_outlined,
                  size: 19,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    event == null
                        ? '今天暂时没有日程，留给重要的事。'
                        : '${_formatTime(event.startAt)}  ${event.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.update_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '更新于 ${_formatFreshness(updatedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCount extends StatelessWidget {
  const _PlanCount({
    required this.icon,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$count', style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    ),
  );
}

class _SmartSceneCard extends StatelessWidget {
  const _SmartSceneCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 130,
      child: Material(
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const Spacer(),
                Text(label, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NexusExpertCard extends StatelessWidget {
  const NexusExpertCard({super.key, required this.expert, required this.onTap});

  final Expert expert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
      child: NexusSurface(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.psychology_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          expert.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    expert.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '可随时协作',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyExpertCard extends StatelessWidget {
  const _EmptyExpertCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => NexusSurface(
    child: Row(
      children: [
        const Icon(Icons.person_add_alt_1_outlined),
        const SizedBox(width: 12),
        const Expanded(child: Text('创建一位专家，开始长期协作。')),
        TextButton(onPressed: onCreate, child: const Text('创建')),
      ],
    ),
  );
}

class _DashboardCardLoading extends StatelessWidget {
  const _DashboardCardLoading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionHeading(title: title, action: '加载中'),
      const SizedBox(height: 12),
      const NexusSurface(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    ],
  );
}

class _DashboardCardError extends StatelessWidget {
  const _DashboardCardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => NexusSurface(
    child: Row(
      children: [
        Icon(
          Icons.cloud_off_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
        IconButton(
          tooltip: '重试',
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
  );
}

class _DashboardEmptyCard extends StatelessWidget {
  const _DashboardEmptyCard({required this.message, required this.onOpen});

  final String message;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => NexusSurface(
    child: Row(
      children: [
        const Icon(Icons.inbox_outlined),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
        IconButton(
          tooltip: '查看家庭',
          onPressed: onOpen,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    ),
  );
}

DateTime _latestUpdate(
  Iterable<DateTime> values, {
  required DateTime fallback,
}) {
  DateTime? latest;
  for (final value in values) {
    if (latest == null || value.isAfter(latest)) latest = value;
  }
  return latest ?? fallback;
}

IconData _dashboardDeviceIcon(String type) => switch (type) {
  'climate' => Icons.thermostat_outlined,
  'light' => Icons.lightbulb_outline,
  'safety' => Icons.shield_outlined,
  _ => Icons.sensors_outlined,
};

IconData _sceneIcon(String key) => switch (key) {
  'arrive-home' => Icons.home_outlined,
  'leave-home' => Icons.directions_walk_outlined,
  'sleep' => Icons.bedtime_outlined,
  _ => Icons.auto_awesome_outlined,
};

String _formatFreshness(DateTime dateTime) => _formatTime(dateTime);

String _formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
