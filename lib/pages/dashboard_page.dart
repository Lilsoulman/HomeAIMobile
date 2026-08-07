import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/analytics/track.dart';
import '../core/ui/nexus_theme.dart';
import '../features/auth/auth_controller.dart';
import '../features/dashboard/dashboard_repository.dart';
import '../features/dashboard/dto.dart';
import '../features/steward/steward_repository.dart';
import '../widgets/confirmation_section.dart';
import '../widgets/steward_timeline_tile.dart';

class NexusHomePage extends StatefulWidget {
  const NexusHomePage({super.key});

  @override
  State<NexusHomePage> createState() => _NexusHomePageState();
}

class _NexusHomePageState extends State<NexusHomePage> {
  late Future<DashboardDto> _dashboard;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _dashboard = context.read<DashboardRepository>().list();
    });
  }

  Future<void> _refresh() async {
    _reload();
    await _dashboard;
  }

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
                now: DateTime.now(),
                onNotifications: () => _showMessage('当前没有新的提醒'),
              ),
              const SizedBox(height: NexusLayout.sectionGap),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConfirmationSection(
                    repository: context.read<StewardRepository>(),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.push('/plan/confirmations'),
                      icon: const Icon(Icons.open_in_full_rounded),
                      label: const Text('查看全部待确认'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NexusLayout.sectionGap),
              _StewardActivitySection(future: _dashboard, onRetry: _reload),
              const SizedBox(height: NexusLayout.sectionGap),
              _FamilyOverviewSection(
                future: _dashboard,
                onOpenHome: () => _goTo('/home-plus'),
                onRetry: _reload,
              ),
              const SizedBox(height: NexusLayout.sectionGap),
              _QuickEntrySection(
                onPlan: () => _goTo('/plan'),
                onExpert: () => _goTo('/ai'),
                onHome: () => _goTo('/home-plus'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 管家动态：聚合视图 StewardActivities 模块，独立降级。
class _StewardActivitySection extends StatelessWidget {
  const _StewardActivitySection({required this.future, required this.onRetry});

  final Future<DashboardDto> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FutureBuilder<DashboardDto>(
    future: future,
    builder: (context, snapshot) {
      final module = snapshot.data?.stewardActivities;
      if (snapshot.hasError || module == null || !module.isAvailable) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(title: '管家动态', action: '重试', onAction: onRetry),
            const SizedBox(height: 12),
            _DashboardCardError(message: '管家动态暂时无法加载', onRetry: onRetry),
          ],
        );
      }
      final activities = (module.data ?? const []).toList()
        ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
      if (activities.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(title: '管家动态'),
            const SizedBox(height: 12),
            const _DashboardEmptyCard(message: '还没有管家动态'),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: '管家动态',
            action: '查看全部',
            onAction: () => context.push('/home-plus/timeline'),
          ),
          const SizedBox(height: 12),
          ...activities
              .take(3)
              .map(
                (activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StewardTimelineTile(
                    category: activity.category,
                    title: activity.title,
                    summary: activity.resultSummary,
                    time: activity.createdAt,
                    riskLevel: activity.riskLevel,
                    onTap: () => context.push('/home-plus/timeline'),
                  ),
                ),
              ),
        ],
      );
    },
  );
}

/// 家庭概览：聚合视图 Home 与 Scenes 模块，独立降级。
class _FamilyOverviewSection extends StatelessWidget {
  const _FamilyOverviewSection({
    required this.future,
    required this.onOpenHome,
    required this.onRetry,
  });

  final Future<DashboardDto> future;
  final VoidCallback onOpenHome;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FutureBuilder<DashboardDto>(
    future: future,
    builder: (context, snapshot) {
      final module = snapshot.data?.home;
      final scenes = snapshot.data?.scenes;
      if (snapshot.hasError || module == null || !module.isAvailable) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(title: '家庭状态', action: '重试', onAction: onRetry),
            const SizedBox(height: 12),
            _DashboardCardError(message: '家庭状态暂时无法加载', onRetry: onRetry),
          ],
        );
      }
      final home = module.data!;
      if (home.spaces.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(title: '家庭状态'),
            const SizedBox(height: 12),
            _DashboardEmptyCard(message: '还没有可显示的家庭空间', onOpen: onOpenHome),
          ],
        );
      }
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
          NexusSmartHomeCard(
            summary: SmartHomeSummary(
              location: home.spaces.length == 1
                  ? home.spaces.first.name
                  : '我的家',
              headline: home.deviceCount == 0
                  ? '已连接 ${home.spaceCount} 个家庭空间'
                  : '${home.onlineDeviceCount} / ${home.deviceCount} 台设备在线',
              devices: home.spaces
                  .take(3)
                  .map(
                    (space) => SmartHomeDevice(
                      icon: _dashboardSpaceIcon(space.spaceType),
                      label: space.name,
                      detail:
                          space.summary ??
                          '${space.onlineDeviceCount} / ${space.deviceCount} 台设备在线',
                      active: space.onlineDeviceCount > 0,
                    ),
                  )
                  .toList(growable: false),
            ),
            updatedAt: module.updatedAt ?? DateTime.now(),
            onTap: onOpenHome,
          ),
          if (scenes != null && scenes.isAvailable) ...[
            const SizedBox(height: NexusLayout.sectionGap),
            _SectionHeading(
              title: '智能场景',
              action: '查看全部',
              onAction: onOpenHome,
            ),
            const SizedBox(height: 12),
            if (scenes.data?.isEmpty ?? true)
              const _DashboardEmptyCard(message: '暂时没有可用的智能场景')
            else
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: scenes.data!.length.clamp(0, 3).toInt(),
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final scene = scenes.data![index];
                    return _SmartSceneCard(
                      icon: _sceneIcon(scene.key),
                      label: scene.name,
                      description: scene.summary ?? '',
                      onTap: onOpenHome,
                    );
                  },
                ),
              ),
          ],
        ],
      );
    },
  );
}

class _QuickEntrySection extends StatelessWidget {
  const _QuickEntrySection({
    required this.onPlan,
    required this.onExpert,
    required this.onHome,
  });

  final VoidCallback onPlan;
  final VoidCallback onExpert;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('快捷入口', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Row(
        children: [
          _QuickEntryCard(
            icon: Icons.checklist_rounded,
            label: '今日计划',
            onTap: onPlan,
          ),
          const SizedBox(width: 12),
          _QuickEntryCard(
            icon: Icons.psychology_outlined,
            label: 'AI 专家',
            onTap: onExpert,
          ),
          const SizedBox(width: 12),
          _QuickEntryCard(
            icon: Icons.home_work_outlined,
            label: '家庭',
            onTap: onHome,
          ),
        ],
      ),
    ],
  );
}

class _QuickEntryCard extends StatelessWidget {
  const _QuickEntryCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
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
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(height: 10),
                Text(label, style: theme.textTheme.titleSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.action,
    this.actionColor,
    this.onAction,
  });

  final String title;
  final String? action;
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
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: color),
            child: Text(action!),
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
  const _DashboardEmptyCard({required this.message, this.onOpen});

  final String message;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => NexusSurface(
    child: Row(
      children: [
        const Icon(Icons.inbox_outlined),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
        if (onOpen != null)
          IconButton(
            tooltip: '查看家庭',
            onPressed: onOpen,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
      ],
    ),
  );
}

IconData _dashboardSpaceIcon(String type) => switch (type) {
  'living_room' => Icons.weekend_outlined,
  'bedroom' => Icons.bed_outlined,
  'kitchen' => Icons.kitchen_outlined,
  'bathroom' => Icons.bathtub_outlined,
  'office' => Icons.computer_outlined,
  _ => Icons.home_outlined,
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
