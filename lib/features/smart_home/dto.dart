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

class SmartHomeDeviceDto {
  const SmartHomeDeviceDto({
    required this.id,
    required this.spaceId,
    required this.name,
    required this.type,
    required this.statusText,
    required this.isOnline,
    required this.updatedAt,
  });

  final String id;
  final String spaceId;
  final String name;
  final String type;
  final String statusText;
  final bool isOnline;
  final DateTime updatedAt;

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
      );
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

int _intValue(Map<String, dynamic> json, String key) {
  final value = json[key] ?? json[_camelCase(key)];
  return value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? 0;
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

String _camelCase(String value) =>
    value.isEmpty ? value : '${value[0].toLowerCase()}${value.substring(1)}';
