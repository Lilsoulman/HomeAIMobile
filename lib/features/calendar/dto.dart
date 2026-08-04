// 执行模式 16：Calendar 事件 / 订阅 DTO。

class CalendarEventDto {
  CalendarEventDto({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startAt,
    this.endAt,
    required this.timezone,
    required this.allDay,
    this.color,
    required this.opacity,
    this.repeatRule,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEventDto.fromJson(Map<String, dynamic> json) =>
      CalendarEventDto(
        id: (json['id'] as num).toInt(),
        title: (json['title'] ?? '').toString(),
        description: json['description'] as String?,
        location: json['location'] as String?,
        startAt: DateTime.parse(json['StartAt'] as String),
        endAt: json['EndAt'] == null
            ? null
            : DateTime.parse(json['EndAt'] as String),
        timezone: (json['timezone'] ?? 'UTC').toString(),
        allDay: (json['AllDay'] as bool?) ?? false,
        color: json['color'] as String?,
        opacity: ((json['opacity'] as num?) ?? 1.0).toDouble(),
        repeatRule: json['RepeatRule'] as String?,
        createdAt: DateTime.parse(json['CreatedAt'] as String),
        updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      );

  final int id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startAt;
  final DateTime? endAt;
  final String timezone;
  final bool allDay;
  final String? color;
  final double opacity;
  final String? repeatRule;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CalendarSubscriptionDto {
  CalendarSubscriptionDto({
    required this.id,
    required this.name,
    required this.enabled,
    required this.refreshIntervalMin,
    this.lastFetchAt,
    this.lastError,
    required this.createdAt,
  });

  factory CalendarSubscriptionDto.fromJson(Map<String, dynamic> json) =>
      CalendarSubscriptionDto(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '').toString(),
        enabled: (json['enabled'] as bool?) ?? true,
        refreshIntervalMin: ((json['RefreshIntervalMin'] as num?) ?? 60)
            .toInt(),
        lastFetchAt: json['LastFetchAt'] == null
            ? null
            : DateTime.parse(json['LastFetchAt'] as String),
        lastError: json['LastError'] as String?,
        createdAt: DateTime.parse(json['CreatedAt'] as String),
      );

  final int id;
  final String name;
  final bool enabled;
  final int refreshIntervalMin;
  final DateTime? lastFetchAt;
  final String? lastError;
  final DateTime createdAt;
}
