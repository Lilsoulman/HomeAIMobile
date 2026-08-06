// P2 家庭协同数据层：Dashboard 聚合视图 DTO。
// 字段依据服务端 DashboardViewModels.cs 与 frontend-api-integration.md §8.13（B12/B14 已发布契约），PascalCase 键。
// 各模块独立降级：Status=available/unavailable，Data 可为空（unavailable 时）。

class DashboardModuleDto<T> {
  const DashboardModuleDto({
    required this.status,
    this.data,
    this.updatedAt,
    this.message,
  });

  factory DashboardModuleDto.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw) parseData,
  ) => DashboardModuleDto<T>(
    status: (json['Status'] ?? '').toString(),
    data: json['Data'] == null ? null : parseData(json['Data']),
    updatedAt: json['UpdatedAt'] == null
        ? null
        : DateTime.parse(json['UpdatedAt'] as String),
    message: json['Message'] as String?,
  );

  final String status;
  final T? data;
  final DateTime? updatedAt;
  final String? message;

  bool get isAvailable => status == 'available';
}

class DashboardSpaceSummaryDto {
  const DashboardSpaceSummaryDto({
    required this.id,
    required this.name,
    required this.spaceType,
    this.summary,
    required this.deviceCount,
    required this.onlineDeviceCount,
    required this.offlineDeviceCount,
    this.stateUpdatedAt,
    required this.updatedAt,
  });

  factory DashboardSpaceSummaryDto.fromJson(Map<String, dynamic> json) =>
      DashboardSpaceSummaryDto(
        id: (json['Id'] as num).toInt(),
        name: (json['Name'] ?? '').toString(),
        spaceType: (json['SpaceType'] ?? '').toString(),
        summary: json['Summary'] as String?,
        deviceCount: ((json['DeviceCount'] as num?) ?? 0).toInt(),
        onlineDeviceCount: ((json['OnlineDeviceCount'] as num?) ?? 0).toInt(),
        offlineDeviceCount: ((json['OfflineDeviceCount'] as num?) ?? 0).toInt(),
        stateUpdatedAt: json['StateUpdatedAt'] == null
            ? null
            : DateTime.parse(json['StateUpdatedAt'] as String),
        updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      );

  final int id;
  final String name;
  final String spaceType;
  final String? summary;
  final int deviceCount;
  final int onlineDeviceCount;
  final int offlineDeviceCount;
  final DateTime? stateUpdatedAt;
  final DateTime updatedAt;
}

class DashboardHomeDto {
  const DashboardHomeDto({
    required this.spaceCount,
    required this.deviceCount,
    required this.onlineDeviceCount,
    required this.offlineDeviceCount,
    required this.spaces,
  });

  factory DashboardHomeDto.fromJson(
    Map<String, dynamic> json,
  ) => DashboardHomeDto(
    spaceCount: ((json['SpaceCount'] as num?) ?? 0).toInt(),
    deviceCount: ((json['DeviceCount'] as num?) ?? 0).toInt(),
    onlineDeviceCount: ((json['OnlineDeviceCount'] as num?) ?? 0).toInt(),
    offlineDeviceCount: ((json['OfflineDeviceCount'] as num?) ?? 0).toInt(),
    spaces: (json['Spaces'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (entry) =>
              DashboardSpaceSummaryDto.fromJson(entry.cast<String, dynamic>()),
        )
        .toList(growable: false),
  );

  final int spaceCount;
  final int deviceCount;
  final int onlineDeviceCount;
  final int offlineDeviceCount;
  final List<DashboardSpaceSummaryDto> spaces;
}

class DashboardConfirmationDto {
  const DashboardConfirmationDto({
    required this.id,
    required this.riskLevel,
    required this.title,
    this.impactSummary,
    required this.status,
    this.expiresAt,
    required this.updatedAt,
  });

  factory DashboardConfirmationDto.fromJson(Map<String, dynamic> json) =>
      DashboardConfirmationDto(
        id: (json['Id'] as num).toInt(),
        riskLevel: (json['RiskLevel'] ?? '').toString(),
        title: (json['Title'] ?? '').toString(),
        impactSummary: json['ImpactSummary'] as String?,
        status: (json['Status'] ?? '').toString(),
        expiresAt: json['ExpiresAt'] == null
            ? null
            : DateTime.parse(json['ExpiresAt'] as String),
        updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      );

  final int id;
  final String riskLevel;
  final String title;
  final String? impactSummary;
  final String status;
  final DateTime? expiresAt;
  final DateTime updatedAt;
}

class DashboardStewardActivityDto {
  const DashboardStewardActivityDto({
    required this.id,
    required this.category,
    required this.title,
    required this.riskLevel,
    required this.status,
    this.resultSummary,
    required this.createdAt,
  });

  factory DashboardStewardActivityDto.fromJson(Map<String, dynamic> json) =>
      DashboardStewardActivityDto(
        id: (json['Id'] as num).toInt(),
        category: (json['Category'] ?? '').toString(),
        title: (json['Title'] ?? '').toString(),
        riskLevel: (json['RiskLevel'] ?? '').toString(),
        status: (json['Status'] ?? '').toString(),
        resultSummary: json['ResultSummary'] as String?,
        createdAt: DateTime.parse(json['CreatedAt'] as String),
      );

  final int id;
  final String category;
  final String title;
  final String riskLevel;
  final String status;
  final String? resultSummary;
  final DateTime createdAt;
}

class DashboardSceneDto {
  const DashboardSceneDto({
    required this.id,
    required this.key,
    required this.name,
    this.summary,
    required this.status,
    required this.updatedAt,
  });

  factory DashboardSceneDto.fromJson(Map<String, dynamic> json) =>
      DashboardSceneDto(
        id: (json['Id'] as num).toInt(),
        key: (json['Key'] ?? '').toString(),
        name: (json['Name'] ?? '').toString(),
        summary: json['Summary'] as String?,
        status: (json['Status'] ?? '').toString(),
        updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      );

  final int id;
  final String key;
  final String name;
  final String? summary;
  final String status;
  final DateTime updatedAt;
}

class DashboardTodoDto {
  const DashboardTodoDto({
    required this.id,
    required this.title,
    required this.status,
    this.priority,
    this.dueAt,
    required this.pinned,
    required this.updatedAt,
  });

  factory DashboardTodoDto.fromJson(Map<String, dynamic> json) =>
      DashboardTodoDto(
        id: (json['Id'] as num).toInt(),
        title: (json['Title'] ?? '').toString(),
        status: (json['Status'] ?? '').toString(),
        priority: json['Priority'] as String?,
        dueAt: json['DueAt'] == null
            ? null
            : DateTime.parse(json['DueAt'] as String),
        pinned: (json['Pinned'] as bool?) ?? false,
        updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      );

  final int id;
  final String title;
  final String status;
  final String? priority;
  final DateTime? dueAt;
  final bool pinned;
  final DateTime updatedAt;
}

class DashboardCalendarEventDto {
  const DashboardCalendarEventDto({
    required this.id,
    required this.title,
    required this.startAt,
    this.endAt,
    required this.allDay,
    required this.updatedAt,
  });

  factory DashboardCalendarEventDto.fromJson(Map<String, dynamic> json) =>
      DashboardCalendarEventDto(
        id: (json['Id'] as num).toInt(),
        title: (json['Title'] ?? '').toString(),
        startAt: DateTime.parse(json['StartAt'] as String),
        endAt: json['EndAt'] == null
            ? null
            : DateTime.parse(json['EndAt'] as String),
        allDay: (json['AllDay'] as bool?) ?? false,
        updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      );

  final int id;
  final String title;
  final DateTime startAt;
  final DateTime? endAt;
  final bool allDay;
  final DateTime updatedAt;
}

class DashboardSuggestionDto {
  const DashboardSuggestionDto({
    required this.runId,
    this.summary,
    required this.status,
    required this.createdAt,
  });

  factory DashboardSuggestionDto.fromJson(Map<String, dynamic> json) =>
      DashboardSuggestionDto(
        runId: (json['RunId'] as num).toInt(),
        summary: json['Summary'] as String?,
        status: (json['Status'] ?? '').toString(),
        createdAt: DateTime.parse(json['CreatedAt'] as String),
      );

  final int runId;
  final String? summary;
  final String status;
  final DateTime createdAt;
}

class DashboardDto {
  const DashboardDto({
    required this.generatedAt,
    required this.partialFailure,
    required this.home,
    required this.pendingConfirmations,
    required this.stewardActivities,
    required this.scenes,
    required this.todos,
    required this.calendar,
    required this.suggestion,
  });

  factory DashboardDto.fromJson(Map<String, dynamic> json) => DashboardDto(
    generatedAt: DateTime.parse(json['GeneratedAt'] as String),
    partialFailure: (json['PartialFailure'] as bool?) ?? false,
    home: _module(
      json,
      'Home',
      (raw) => DashboardHomeDto.fromJson(_asMap(raw)),
    ),
    pendingConfirmations: _module(
      json,
      'PendingConfirmations',
      _list(DashboardConfirmationDto.fromJson),
    ),
    stewardActivities: _module(
      json,
      'StewardActivities',
      _list(DashboardStewardActivityDto.fromJson),
    ),
    scenes: _module(json, 'Scenes', _list(DashboardSceneDto.fromJson)),
    todos: _module(json, 'Todos', _list(DashboardTodoDto.fromJson)),
    calendar: _module(
      json,
      'Calendar',
      _list(DashboardCalendarEventDto.fromJson),
    ),
    suggestion: _module(
      json,
      'Suggestion',
      (raw) => DashboardSuggestionDto.fromJson(_asMap(raw)),
    ),
  );

  final DateTime generatedAt;
  final bool partialFailure;
  final DashboardModuleDto<DashboardHomeDto> home;
  final DashboardModuleDto<List<DashboardConfirmationDto>> pendingConfirmations;
  final DashboardModuleDto<List<DashboardStewardActivityDto>> stewardActivities;
  final DashboardModuleDto<List<DashboardSceneDto>> scenes;
  final DashboardModuleDto<List<DashboardTodoDto>> todos;
  final DashboardModuleDto<List<DashboardCalendarEventDto>> calendar;
  final DashboardModuleDto<DashboardSuggestionDto> suggestion;

  static DashboardModuleDto<T> _module<T>(
    Map<String, dynamic> json,
    String key,
    T Function(dynamic raw) parseData,
  ) {
    final raw = json[key];
    return raw is Map
        ? DashboardModuleDto<T>.fromJson(raw.cast<String, dynamic>(), parseData)
        : DashboardModuleDto<T>(status: 'unavailable');
  }

  static List<T> Function(dynamic raw) _list<T>(
    T Function(Map<String, dynamic>) parse,
  ) =>
      (raw) => (raw as List? ?? const [])
          .whereType<Map>()
          .map((entry) => parse(entry.cast<String, dynamic>()))
          .toList(growable: false);

  static Map<String, dynamic> _asMap(dynamic raw) =>
      raw is Map ? raw.cast<String, dynamic>() : <String, dynamic>{};
}
