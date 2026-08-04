import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _data = _load();

  Future<_HomePlusData> _load() async {
    final repository = context.read<SmartHomeRepository>();
    final results = await Future.wait<Object>([
      repository.listSpaces(),
      repository.listDevices(),
      repository.listScenes(),
    ]);
    return _HomePlusData(
      spaces: results[0] as List<SmartHomeSpaceDto>,
      devices: results[1] as List<SmartHomeDeviceDto>,
      scenes: results[2] as List<SmartSceneDto>,
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
                  onTap: () {},
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
                      child: _DeviceStatusCard(device: device),
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
  });

  final List<SmartHomeSpaceDto> spaces;
  final List<SmartHomeDeviceDto> devices;
  final List<SmartSceneDto> scenes;
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
  });

  final SmartHomeSpaceDto space;
  final List<SmartHomeDeviceDto> devices;
  final VoidCallback onTap;

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
                    Row(
                      children: [
                        _RoomStat(
                          icon: Icons.sensors_rounded,
                          label: '$online 在线',
                        ),
                        const SizedBox(width: 10),
                        _RoomStat(
                          icon: Icons.thermostat_rounded,
                          label: _temperatureLabel(devices),
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
  });

  final SmartHomeSpaceDto space;
  final List<SmartHomeDeviceDto> devices;
  final VoidCallback onTap;

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

  @override
  Widget build(BuildContext context) => Image.network(
    _roomImageUrl(space.type),
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => _RoomImageFallback(type: space.type),
    loadingBuilder: (context, child, loadingProgress) =>
        loadingProgress == null ? child : _RoomImageFallback(type: space.type),
  );
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
  const _DeviceStatusCard({required this.device});

  final SmartHomeDeviceDto device;

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

String _temperatureLabel(List<SmartHomeDeviceDto> devices) {
  final climate = devices.where((device) => device.type == 'climate');
  if (climate.isEmpty) return '环境正常';
  final detail = climate.first.statusText;
  final match = RegExp(r'\d+°C').firstMatch(detail);
  return match?.group(0) ?? '环境正常';
}

String _roomImageUrl(String type) => switch (type) {
  'living_room' =>
    'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=1200&q=85',
  'bedroom' =>
    'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=1200&q=85',
  _ =>
    'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?auto=format&fit=crop&w=1200&q=85',
};
