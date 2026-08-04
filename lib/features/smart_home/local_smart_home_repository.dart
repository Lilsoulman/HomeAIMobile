import 'dto.dart';
import 'smart_home_repository.dart';

class LocalSmartHomeRepository implements SmartHomeRepository {
  LocalSmartHomeRepository() : _updatedAt = DateTime.now();

  final DateTime _updatedAt;
  late final List<SmartHomeSpaceDto> _spaces = [
    const SmartHomeSpaceDto(
      id: 'living-room',
      name: '客厅',
      type: 'living_room',
      summary: '灯光舒适，空气状态良好',
      sortOrder: 1,
    ),
    const SmartHomeSpaceDto(
      id: 'main-bedroom',
      name: '主卧',
      type: 'bedroom',
      summary: '睡眠环境已准备就绪',
      sortOrder: 2,
    ),
    const SmartHomeSpaceDto(
      id: 'elder-room',
      name: '长辈房',
      type: 'bedroom',
      summary: '环境稳定，守护设备在线',
      sortOrder: 3,
    ),
  ];
  late final List<SmartHomeDeviceDto> _devices = [
    SmartHomeDeviceDto(
      id: 'living-room-climate',
      spaceId: 'living-room',
      name: '环境状态',
      type: 'climate',
      statusText: '24°C · 湿度 48%',
      isOnline: true,
      updatedAt: _updatedAt,
    ),
    SmartHomeDeviceDto(
      id: 'living-room-light',
      spaceId: 'living-room',
      name: '主灯',
      type: 'light',
      statusText: '已开启 · 60%',
      isOnline: true,
      updatedAt: _updatedAt,
    ),
    SmartHomeDeviceDto(
      id: 'bedroom-climate',
      spaceId: 'main-bedroom',
      name: '空调',
      type: 'climate',
      statusText: '睡眠模式 · 25°C',
      isOnline: true,
      updatedAt: _updatedAt,
    ),
    SmartHomeDeviceDto(
      id: 'elder-room-safety',
      spaceId: 'elder-room',
      name: '守护状态',
      type: 'safety',
      statusText: '正常',
      isOnline: true,
      updatedAt: _updatedAt,
    ),
  ];
  final List<SmartSceneDto> _scenes = [
    const SmartSceneDto(
      key: 'arrive-home',
      name: '回家',
      description: '点亮玄关并恢复舒适环境',
      requiresConfirmation: true,
    ),
    const SmartSceneDto(
      key: 'leave-home',
      name: '离家',
      description: '关闭不必要设备并进入守护状态',
      requiresConfirmation: true,
    ),
    const SmartSceneDto(
      key: 'sleep',
      name: '睡眠',
      description: '调暗灯光并准备夜间环境',
      requiresConfirmation: true,
    ),
  ];

  @override
  Future<List<SmartHomeSpaceDto>> listSpaces() async => List.unmodifiable(
    _spaces..sort((left, right) => left.sortOrder.compareTo(right.sortOrder)),
  );

  @override
  Future<List<SmartHomeDeviceDto>> listDevices({String? spaceId}) async {
    final devices = spaceId == null
        ? _devices
        : _devices.where((device) => device.spaceId == spaceId).toList();
    return List.unmodifiable(devices);
  }

  @override
  Future<List<SmartSceneDto>> listScenes() async => List.unmodifiable(_scenes);

  @override
  Future<SmartSceneDto> runScene(String key) async {
    final index = _scenes.indexWhere((scene) => scene.key == key);
    if (index < 0) throw StateError('未找到场景');
    final updated = _scenes[index].copyWith(lastRunAt: DateTime.now());
    _scenes[index] = updated;
    return updated;
  }
}
