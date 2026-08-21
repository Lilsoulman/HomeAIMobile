import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api/api_exception.dart';
import '../core/ui/nexus_theme.dart';
import '../features/smart_home/dto.dart';
import '../features/smart_home/smart_home_repository.dart';

class HomePlusPage extends StatefulWidget {
  const HomePlusPage({super.key});

  @override
  State<HomePlusPage> createState() => _HomePlusPageState();
}

class _HomePlusPageState extends State<HomePlusPage> {
  late Future<_HomePlusData> _data;
  String? _runningSceneKey;
  String? _selectedSpaceId;

  // 设备健康详情缓存（spaceId -> deviceId -> detail），按空间惰性加载。
  final Map<String, Map<String, DeviceHealthDetailDto>> _deviceHealthCache = {};
  String? _healthRequestedSpace;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  Future<_HomePlusData> _load() async {
    final repository = context.read<SmartHomeRepository>();
    final spaces = await repository.listSpaces();
    final results = await Future.wait<Object>([
      repository.listDevices(),
      repository.listScenes(),
      _fetchSpaceHealth(repository, spaces),
    ]);
    return _HomePlusData(
      spaces: spaces,
      devices: results[0] as List<SmartHomeDeviceDto>,
      scenes: results[1] as List<SmartSceneDto>,
      healthBySpace: (results[2] as Map<Object, Object>)
          .cast<String, DeviceHealthSummaryDto>(),
    );
  }

  /// 各空间健康聚合（B10）；单个空间失败时以空摘要兜底，不阻塞页面。
  Future<Map<String, DeviceHealthSummaryDto>> _fetchSpaceHealth(
    SmartHomeRepository repository,
    List<SmartHomeSpaceDto> spaces,
  ) async {
    final entries = await Future.wait(
      spaces.map(
        (space) async => MapEntry(
          space.id,
          await _safe(
                () => repository.fetchDeviceHealthSummary(spaceId: space.id),
              ) ??
              const DeviceHealthSummaryDto(
                total: 0,
                healthy: 0,
                degraded: 0,
                offline: 0,
                lowBattery: 0,
              ),
        ),
      ),
    );
    return Map.fromEntries(entries);
  }

  Future<T?> _safe<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }

  /// 按空间加载设备健康详情（B14，逐设备拉取）；失败项跳过。
  Future<void> _refreshDeviceHealth(
    String spaceId,
    List<SmartHomeDeviceDto> devices,
  ) async {
    if (_healthRequestedSpace == spaceId) return;
    _healthRequestedSpace = spaceId;
    final repository = context.read<SmartHomeRepository>();
    final results = await Future.wait(
      devices.map((device) async {
        final id = int.tryParse(device.id);
        if (id == null) return <String, DeviceHealthDetailDto>{};
        final detail = await _safe(() => repository.fetchDeviceHealth(id));
        return detail == null
            ? <String, DeviceHealthDetailDto>{}
            : <String, DeviceHealthDetailDto>{device.id: detail};
      }),
    );
    final merged = <String, DeviceHealthDetailDto>{};
    for (final map in results) {
      merged.addAll(map);
    }
    if (!mounted) return;
    setState(() {
      _deviceHealthCache[spaceId] = merged;
      _healthRequestedSpace = null;
    });
  }

  /// 打开空间详情：设备健康列表 + 该空间的管家动态入口。
  /// 返回 true 表示用户请求跳转管家动态页（sheet 关闭后再导航）。
  Future<bool?> _openSpaceDetail(
    SmartHomeSpaceDto space,
    List<SmartHomeDeviceDto> devices,
    Map<String, DeviceHealthDetailDto> healthById,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                space.name,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                space.summary,
                style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (devices.isEmpty)
                const Text('这个房间还没有已连接的设备。')
              else
                ...devices.map(
                  (device) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SpaceDetailDeviceRow(
                      device: device,
                      health: healthById[device.id],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  icon: const Icon(Icons.timeline_rounded),
                  label: const Text('查看管家动态'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runScene(SmartSceneDto scene) async {
    if (scene.requiresConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('确认执行“${scene.name}”'),
          content: Text(scene.description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('确认执行'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _runningSceneKey = scene.key);
    try {
      await context.read<SmartHomeRepository>().runScene(scene.key);
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('“${scene.name}”已提交，等待确认')));
    } on ApiException catch (error) {
      if (mounted) _showFailure(error.msg);
    } catch (_) {
      if (mounted) _showFailure('场景暂时无法执行，请稍后重试。');
    } finally {
      if (mounted) setState(() => _runningSceneKey = null);
    }
  }

  void _showFailure(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('家庭'),
      actions: [
        IconButton.filledTonal(
          tooltip: '家庭财务',
          onPressed: () => context.push('/home-plus/finance'),
          icon: const Icon(Icons.account_balance_wallet_outlined),
        ),
        IconButton.filledTonal(
          tooltip: '快递管家',
          onPressed: () => context.push('/home-plus/courier'),
          icon: const Icon(Icons.local_shipping_outlined),
        ),
        IconButton.filledTonal(
          tooltip: 'Pet steward',
          onPressed: () => context.push('/home-plus/pets'),
          icon: const Icon(Icons.pets_outlined),
        ),
        IconButton.filledTonal(
          tooltip: '刷新',
          onPressed: () => setState(_reload),
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 16),
      ],
    ),
    body: SafeArea(
      top: false,
      child: FutureBuilder<_HomePlusData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _HomePlusError(onRetry: () => setState(_reload));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data.spaces.isEmpty) return const _HomePlusEmpty();
          final currentSpace = data.spaces.firstWhere(
            (space) => space.id == _selectedSpaceId,
            orElse: () => data.spaces.first,
          );
          final currentDevices = data.devices
              .where((device) => device.spaceId == currentSpace.id)
              .toList(growable: false);
          final otherSpaces = data.spaces
              .where((space) => space.id != currentSpace.id)
              .toList(growable: false);
          final onlineDevices = data.devices
              .where((device) => device.isOnline)
              .length;
          final currentHealth = _deviceHealthCache[currentSpace.id];

          // 首次展示该空间时惰性加载设备健康详情。
          if (currentHealth == null && currentDevices.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _refreshDeviceHealth(currentSpace.id, currentDevices);
              }
            });
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _data;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: NexusLayout.pagePadding.copyWith(bottom: 36),
              children: [
                Text(
                  '舒适，如你所愿',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${data.spaces.length} 个房间 · $onlineDevices 台设备在线',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                NexusSurface(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('家庭日程'),
                    subtitle: const Text('查看冲突、共同空档与到期提醒'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/home-plus/schedule'),
                  ),
                ),
                const SizedBox(height: 20),
                _RoomFilters(
                  spaces: data.spaces,
                  selectedSpaceId: _selectedSpaceId,
                  onSelected: (spaceId) =>
                      setState(() => _selectedSpaceId = spaceId),
                ),
                const SizedBox(height: 20),
                _RoomImageCard(
                  space: currentSpace,
                  devices: currentDevices,
                  health: data.healthBySpace[currentSpace.id],
                  onTap: () async {
                    final goTimeline = await _openSpaceDetail(
                      currentSpace,
                      currentDevices,
                      currentHealth ?? const {},
                    );
                    if (goTimeline == true && context.mounted) {
                      context.push('/home-plus/timeline');
                    }
                  },
                ),
                if (otherSpaces.isNotEmpty) ...[
                  const SizedBox(height: NexusLayout.sectionGap),
                  const _SectionTitle(title: '其他房间'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 164,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: otherSpaces.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => _RoomPreviewCard(
                        space: otherSpaces[index],
                        devices: data.devices
                            .where(
                              (device) =>
                                  device.spaceId == otherSpaces[index].id,
                            )
                            .toList(growable: false),
                        health: data.healthBySpace[otherSpaces[index].id],
                        onTap: () => setState(
                          () => _selectedSpaceId = otherSpaces[index].id,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: NexusLayout.sectionGap),
                const _SectionTitle(title: '快捷场景'),
                const SizedBox(height: 12),
                ...data.scenes.map(
                  (scene) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SceneActionCard(
                      scene: scene,
                      busy: _runningSceneKey == scene.key,
                      onRun: () => _runScene(scene),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionTitle(
                  title: '${currentSpace.name}设备',
                  trailing: '${currentDevices.length} 台已连接',
                ),
                const SizedBox(height: 12),
                if (currentDevices.isEmpty)
                  const NexusSurface(child: Text('这个房间还没有已连接的设备。'))
                else
                  ...currentDevices.map(
                    (device) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DeviceStatusCard(
                        device: device,
                        health: currentHealth?[device.id],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _HomePlusData {
  const _HomePlusData({
    required this.spaces,
    required this.devices,
    required this.scenes,
    required this.healthBySpace,
  });

  final List<SmartHomeSpaceDto> spaces;
  final List<SmartHomeDeviceDto> devices;
  final List<SmartSceneDto> scenes;

  /// 各空间设备健康聚合（spaceId -> 摘要）。
  final Map<String, DeviceHealthSummaryDto> healthBySpace;
}

class _RoomFilters extends StatelessWidget {
  const _RoomFilters({
    required this.spaces,
    required this.selectedSpaceId,
    required this.onSelected,
  });

  final List<SmartHomeSpaceDto> spaces;
  final String? selectedSpaceId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _RoomFilter(
          label: '全部',
          selected: selectedSpaceId == null,
          onTap: () => onSelected(null),
        ),
        ...spaces.map(
          (space) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _RoomFilter(
              label: space.name,
              selected: selectedSpaceId == space.id,
              onTap: () => onSelected(space.id),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoomFilter extends StatelessWidget {
  const _RoomFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomImageCard extends StatelessWidget {
  const _RoomImageCard({
    required this.space,
    required this.devices,
    required this.onTap,
    this.health,
  });

  final SmartHomeSpaceDto space;
  final List<SmartHomeDeviceDto> devices;
  final VoidCallback onTap;
  final DeviceHealthSummaryDto? health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final online = devices.where((device) => device.isOnline).length;
    return Material(
      color: theme.cardColor,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 248,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _RoomImage(space: space),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x05000000), Color(0xD9000000)],
                    stops: [0.28, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RoomIcon(icon: _spaceIcon(space.type)),
                    const Spacer(),
                    Text(
                      space.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      space.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFE2E2E5),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _RoomStat(
                          icon: Icons.sensors_rounded,
                          label: '$online 在线',
                        ),
                        _RoomStat(
                          icon: Icons.thermostat_rounded,
                          label: _temperatureLabel(devices),
                        ),
                        if (_healthBadgeLabel(health) != null)
                          _RoomStat(
                            icon: Icons.health_and_safety_outlined,
                            label: _healthBadgeLabel(health)!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomPreviewCard extends StatelessWidget {
  const _RoomPreviewCard({
    required this.space,
    required this.devices,
    required this.onTap,
    this.health,
  });

  final SmartHomeSpaceDto space;
  final List<SmartHomeDeviceDto> devices;
  final VoidCallback onTap;
  final DeviceHealthSummaryDto? health;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 172,
    child: Material(
      color: Theme.of(context).cardColor,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _RoomImage(space: space),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xE6000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    space.name,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${devices.where((device) => device.isOnline).length} 台设备在线',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFD4D4D8),
                    ),
                  ),
                  if (_healthBadgeLabel(health) != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      _healthBadgeLabel(health)!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFFFD9A8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RoomImage extends StatelessWidget {
  const _RoomImage({required this.space});

  final SmartHomeSpaceDto space;

  // P1 收口：客户端不直连第三方 Endpoint，房间图统一使用本地渐变占位。
  @override
  Widget build(BuildContext context) => _RoomImageFallback(type: space.type);
}

class _RoomImageFallback extends StatelessWidget {
  const _RoomImageFallback({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: switch (type) {
          'living_room' => const [Color(0xFF6B4739), Color(0xFF1B2020)],
          'bedroom' => const [Color(0xFF40434F), Color(0xFF17181D)],
          _ => const [Color(0xFF384548), Color(0xFF181B1E)],
        },
      ),
    ),
    child: Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Icon(_spaceIcon(type), color: Colors.white24, size: 72),
      ),
    ),
  );
}

class _RoomIcon extends StatelessWidget {
  const _RoomIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.26),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white24),
    ),
    child: Icon(icon, color: Colors.white, size: 22),
  );
}

class _RoomStat extends StatelessWidget {
  const _RoomStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0x66303030),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (trailing != null)
        Text(
          trailing!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
    ],
  );
}

class _SceneActionCard extends StatelessWidget {
  const _SceneActionCard({
    required this.scene,
    required this.busy,
    required this.onRun,
  });

  final SmartSceneDto scene;
  final bool busy;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: '执行${scene.name}',
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
        child: InkWell(
          onTap: busy ? null : onRun,
          borderRadius: BorderRadius.circular(NexusLayout.controlRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(_sceneIcon(scene.key), color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scene.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        scene.description,
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
                  Icons.arrow_forward_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceStatusCard extends StatelessWidget {
  const _DeviceStatusCard({required this.device, this.health});

  final SmartHomeDeviceDto device;
  final DeviceHealthDetailDto? health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = device.isOnline;
    return NexusSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.primary.withValues(alpha: 0.16)
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _deviceIcon(device.type),
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  device.statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (health != null) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (health!.healthStatus != null &&
                          health!.healthStatus != 'healthy')
                        _HealthTag(label: health!.healthLabel),
                      if (health!.isLowBattery)
                        _HealthTag(label: '低电量 ${health!.batteryLevel}%'),
                      if (health!.isWeakSignal)
                        _HealthTag(label: '弱信号 LQI ${health!.signalLqi}'),
                      if (health!.stateUpdatedAt != null)
                        Text(
                          '采样 ${_sampleTime(health!.stateUpdatedAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// 空间详情底部面板中的设备健康行：名称 + 健康语义标签 + 采样时间。
class _SpaceDetailDeviceRow extends StatelessWidget {
  const _SpaceDetailDeviceRow({required this.device, this.health});

  final SmartHomeDeviceDto device;
  final DeviceHealthDetailDto? health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = device.isOnline;
    return Row(
      children: [
        Icon(
          _deviceIcon(device.type),
          size: 20,
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(device.name, style: theme.textTheme.titleSmall)),
        if (health != null && health!.healthStatus != 'healthy') ...[
          _HealthTag(label: health!.healthLabel),
          const SizedBox(width: 6),
        ],
        if (health?.stateUpdatedAt != null) ...[
          Text(
            _sampleTime(health!.stateUpdatedAt!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Icon(
          active ? Icons.circle : Icons.circle_outlined,
          size: 10,
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

/// 设备健康语义标签（颜色走主题 token，不暴露原始数值/协议字段）。
class _HealthTag extends StatelessWidget {
  const _HealthTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      '状态正常' => NexusPalette.healthHealthy,
      '性能降级' => NexusPalette.healthDegraded,
      '电量不足' => NexusPalette.healthLowBattery,
      _ => NexusPalette.healthOffline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HomePlusEmpty extends StatelessWidget {
  const _HomePlusEmpty();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: NexusLayout.pagePadding,
      child: const Text('还没有可显示的家庭空间。'),
    ),
  );
}

class _HomePlusError extends StatelessWidget {
  const _HomePlusError({required this.onRetry});

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
          const Text('家庭状态暂时无法加载。'),
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

IconData _spaceIcon(String type) => switch (type) {
  'living_room' => Icons.weekend_outlined,
  'bedroom' => Icons.bed_outlined,
  _ => Icons.home_outlined,
};

IconData _deviceIcon(String type) => switch (type) {
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

/// 空间健康徽标文案：有离线/低电量/降级设备时给出语义摘要，否则为 null。
String? _healthBadgeLabel(DeviceHealthSummaryDto? health) {
  if (health == null || health.total == 0) return null;
  final parts = <String>[
    if (health.offline > 0) '${health.offline} 离线',
    if (health.lowBattery > 0) '${health.lowBattery} 低电量',
    if (health.degraded > 0) '${health.degraded} 降级',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

String _sampleTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _temperatureLabel(List<SmartHomeDeviceDto> devices) {
  final climate = devices.where((device) => device.type == 'climate');
  if (climate.isEmpty) return '环境正常';
  final detail = climate.first.statusText;
  final match = RegExp(r'\d+°C').firstMatch(detail);
  return match?.group(0) ?? '环境正常';
}
