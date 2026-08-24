class SmartHomeSpaceDto {
  const SmartHomeSpaceDto({
    required this.id,
    required this.name,
    required this.type,
    required this.summary,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String type;
  final String summary;
  final int sortOrder;

  factory SmartHomeSpaceDto.fromJson(Map<String, dynamic> json) =>
      SmartHomeSpaceDto(
        id: _stringValue(json, 'Id'),
        name: _stringValue(json, 'Name'),
        type: _stringValue(json, 'SpaceType'),
        summary: _stringValue(json, 'Summary'),
        sortOrder: _intValue(json, 'SortOrder'),
      );
}

/// 家庭首页一次性读模型；`isMock` 仅表示开发期只读模拟数据。
class SmartHomeBootstrapDto {
  const SmartHomeBootstrapDto({
    required this.isMock,
    required this.disclaimer,
    required this.generatedAt,
    required this.spaces,
    required this.devices,
    required this.scenes,
    required this.deviceHealth,
  });

  factory SmartHomeBootstrapDto.fromJson(Map<String, dynamic> json) {
    final spaces = _mapList(
      json,
      'Spaces',
    ).map(SmartHomeSpaceDto.fromJson).toList(growable: false);
    final devices = _mapList(
      json,
      'Devices',
    ).map(SmartHomeDeviceDto.fromJson).toList(growable: false);
    final scenes = _mapList(
      json,
      'Scenes',
    ).map(SmartSceneDto.fromJson).toList(growable: false);
    final health = json['DeviceHealth'] ?? json['deviceHealth'];
    return SmartHomeBootstrapDto(
      isMock: _boolValue(json, 'IsMock', fallback: false),
      disclaimer: _nullableString(json, 'Disclaimer'),
      generatedAt:
          _dateValue(json, 'GeneratedAt') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      spaces: spaces,
      devices: devices,
      scenes: scenes,
      deviceHealth: health is Map
          ? DeviceHealthSummaryDto.fromJson(health.cast<String, dynamic>())
          : const DeviceHealthSummaryDto(
              total: 0,
              healthy: 0,
              degraded: 0,
              offline: 0,
              lowBattery: 0,
            ),
    );
  }

  final bool isMock;
  final String? disclaimer;
  final DateTime generatedAt;
  final List<SmartHomeSpaceDto> spaces;
  final List<SmartHomeDeviceDto> devices;
  final List<SmartSceneDto> scenes;
  final DeviceHealthSummaryDto deviceHealth;
}

class SmartHomeDeviceDto {
  const SmartHomeDeviceDto({
    required this.id,
    required this.spaceId,
    required this.name,
    required this.type,
    required this.statusText,
    required this.isOnline,
    required this.updatedAt,
    this.healthStatus,
    this.batteryLevel,
  });

  final String id;
  final String spaceId;
  final String name;
  final String type;
  final String statusText;
  final bool isOnline;
  final DateTime updatedAt;
  final String? healthStatus;
  final int? batteryLevel;

  factory SmartHomeDeviceDto.fromJson(Map<String, dynamic> json) =>
      SmartHomeDeviceDto(
        id: _stringValue(json, 'Id'),
        spaceId: _stringValue(json, 'SpaceId'),
        name: _stringValue(json, 'Name'),
        type: _stringValue(json, 'DeviceType'),
        statusText: _stringValue(json, 'StateSummary'),
        isOnline: _isOnline(json),
        updatedAt:
            _dateValue(json, 'StateUpdatedAt') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        healthStatus: _nullableString(json, 'HealthStatus'),
        batteryLevel: _nullableInt(json, 'BatteryLevel'),
      );
}

/// 设备健康聚合（B10 发布）：`GET /api/v1/smart-home/devices/health`。
/// DominantStatus 取值 healthy | degraded | offline | low_battery。
class DeviceHealthSummaryDto {
  const DeviceHealthSummaryDto({
    required this.total,
    required this.healthy,
    required this.degraded,
    required this.offline,
    required this.lowBattery,
    this.dominantStatus,
  });

  factory DeviceHealthSummaryDto.fromJson(Map<String, dynamic> json) =>
      DeviceHealthSummaryDto(
        total: _intValue(json, 'Total'),
        healthy: _intValue(json, 'Healthy'),
        degraded: _intValue(json, 'Degraded'),
        offline: _intValue(json, 'Offline'),
        lowBattery: _intValue(json, 'LowBattery'),
        dominantStatus: _stringValue(json, 'DominantStatus').isEmpty
            ? null
            : _stringValue(json, 'DominantStatus'),
      );

  final int total;
  final int healthy;
  final int degraded;
  final int offline;
  final int lowBattery;
  final String? dominantStatus;
}

/// 单台设备健康详情（B14 发布）：`GET /api/v1/smart-home/devices/{id}/health`。
/// HealthStatus 取值 healthy | degraded | offline | low_battery；
/// StateUpdatedAt 是最近采样时间，过期状态不得描述为实时。
class DeviceHealthDetailDto {
  const DeviceHealthDetailDto({
    required this.id,
    this.spaceId,
    required this.name,
    required this.deviceType,
    required this.onlineStatus,
    this.zigbeeRole,
    this.batteryLevel,
    this.signalLqi,
    this.healthStatus,
    this.stateUpdatedAt,
  });

  factory DeviceHealthDetailDto.fromJson(Map<String, dynamic> json) =>
      DeviceHealthDetailDto(
        id: _intValue(json, 'Id'),
        spaceId: _nullableInt(json, 'SpaceId'),
        name: _stringValue(json, 'Name'),
        deviceType: _stringValue(json, 'DeviceType'),
        onlineStatus: _stringValue(json, 'OnlineStatus'),
        zigbeeRole: _nullableString(json, 'ZigbeeRole'),
        batteryLevel: _nullableInt(json, 'BatteryLevel'),
        signalLqi: _nullableInt(json, 'SignalLqi'),
        healthStatus: _nullableString(json, 'HealthStatus'),
        stateUpdatedAt: _dateValue(json, 'StateUpdatedAt'),
      );

  final int id;
  final int? spaceId;
  final String name;
  final String deviceType;
  final String onlineStatus;
  final String? zigbeeRole;
  final int? batteryLevel;
  final int? signalLqi;
  final String? healthStatus;
  final DateTime? stateUpdatedAt;

  /// 健康语义标签（中文），用于 UI 展示而非原始值。
  String get healthLabel => switch (healthStatus) {
    'healthy' => '状态正常',
    'degraded' => '性能降级',
    'offline' => '已离线',
    'low_battery' => '电量不足',
    _ => onlineStatus == 'online' ? '状态正常' : '已离线',
  };

  /// 是否低电量（≤ 20%），UI 叠加"低电量"徽标。
  bool get isLowBattery =>
      healthStatus != 'offline' && (batteryLevel ?? 100) <= 20;

  /// 是否弱信号（LQI < 60），UI 叠加"弱信号"徽标。
  bool get isWeakSignal => (signalLqi ?? 128) < 60;
}

class SmartSceneDto {
  const SmartSceneDto({
    required this.key,
    required this.name,
    required this.description,
    required this.requiresConfirmation,
    this.lastRunAt,
  });

  final String key;
  final String name;
  final String description;
  final bool requiresConfirmation;
  final DateTime? lastRunAt;

  SmartSceneDto copyWith({DateTime? lastRunAt}) => SmartSceneDto(
    key: key,
    name: name,
    description: description,
    requiresConfirmation: requiresConfirmation,
    lastRunAt: lastRunAt ?? this.lastRunAt,
  );

  factory SmartSceneDto.fromJson(Map<String, dynamic> json) => SmartSceneDto(
    key: _stringValue(json, 'Key'),
    name: _stringValue(json, 'Name'),
    description: _stringValue(json, 'Summary'),
    requiresConfirmation: _boolValue(
      json,
      'RequiresConfirmation',
      fallback: true,
    ),
    lastRunAt: _dateValue(json, 'LastRunAt') ?? _dateValue(json, 'UpdatedAt'),
  );
}

String _stringValue(Map<String, dynamic> json, String key) =>
    (json[key] ?? json[_camelCase(key)])?.toString() ?? '';

String? _nullableString(Map<String, dynamic> json, String key) =>
    (json[key] ?? json[_camelCase(key)])?.toString();

int _intValue(Map<String, dynamic> json, String key) {
  final value = json[key] ?? json[_camelCase(key)];
  return value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(Map<String, dynamic> json, String key) {
  final value = json[key] ?? json[_camelCase(key)];
  return value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
}

bool _boolValue(
  Map<String, dynamic> json,
  String key, {
  required bool fallback,
}) {
  final value = json[key] ?? json[_camelCase(key)];
  if (value is bool) return value;
  if (value is num) return value != 0;
  return switch (value?.toString().toLowerCase()) {
    'true' || '1' => true,
    'false' || '0' => false,
    _ => fallback,
  };
}

bool _isOnline(Map<String, dynamic> json) {
  final status = _stringValue(json, 'OnlineStatus').toLowerCase();
  if (status.isNotEmpty) return status == 'online';
  return _boolValue(json, 'IsOnline', fallback: false);
}

DateTime? _dateValue(Map<String, dynamic> json, String key) {
  final value = json[key] ?? json[_camelCase(key)];
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}

List<Map<String, dynamic>> _mapList(Map<String, dynamic> json, String key) {
  final raw = json[key] ?? json[_camelCase(key)];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList(growable: false);
}

String _camelCase(String value) =>
    value.isEmpty ? value : '${value[0].toLowerCase()}${value.substring(1)}';
