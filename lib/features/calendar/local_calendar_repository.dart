import 'calendar_repository.dart';
import 'dto.dart';

class LocalCalendarRepository implements CalendarRepository {
  LocalCalendarRepository() {
    final now = DateTime.now();
    _events.addAll([
      _EventRecord(
        id: _nextEventId++,
        title: '本周规划',
        startAt: DateTime(now.year, now.month, now.day, 9),
        endAt: DateTime(now.year, now.month, now.day, 10),
        color: '#4F8BFF',
        createdAt: now,
      ),
      _EventRecord(
        id: _nextEventId++,
        title: '深度工作',
        startAt: DateTime(now.year, now.month, now.day + 1, 14),
        endAt: DateTime(now.year, now.month, now.day + 1, 16),
        color: '#7B61FF',
        repeatRule: 'weekly',
        createdAt: now,
      ),
    ]);
  }

  final List<_EventRecord> _events = [];
  final List<_SubscriptionRecord> _subscriptions = [];
  int _nextEventId = 1;
  int _nextSubscriptionId = 1;

  @override
  Future<CalendarEventDto> createEvent({
    required String title,
    String? description,
    String? location,
    required DateTime startAt,
    DateTime? endAt,
    String? timezone,
    bool? allDay,
    String? color,
    double? opacity,
    String? repeatRule,
  }) async {
    final now = DateTime.now();
    final event = _EventRecord(
      id: _nextEventId++,
      title: title.trim(),
      description: description,
      location: location,
      startAt: startAt,
      endAt: endAt,
      timezone: timezone ?? 'Asia/Shanghai',
      allDay: allDay ?? false,
      color: color,
      opacity: opacity ?? 1,
      repeatRule: repeatRule,
      createdAt: now,
    );
    _events.add(event);
    return event.toDto();
  }

  @override
  Future<void> deleteEvent(int id) async {
    _events.removeWhere((event) => event.id == id);
  }

  @override
  Future<List<CalendarEventDto>> listEvents({
    DateTime? from,
    DateTime? to,
  }) async => _events
      .where((event) => _overlaps(event, from: from, to: to))
      .map((event) => event.toDto())
      .toList(growable: false);

  bool _overlaps(_EventRecord event, {DateTime? from, DateTime? to}) {
    final end = event.endAt ?? event.startAt;
    if (from != null && end.isBefore(from)) return false;
    if (to != null && event.startAt.isAfter(to)) return false;
    return true;
  }

  @override
  Future<CalendarEventDto> updateEvent(
    int id,
    Map<String, dynamic> patch,
  ) async {
    final event = _events.where((item) => item.id == id).firstOrNull;
    if (event == null) throw StateError('未找到日程');
    event.apply(patch);
    return event.toDto();
  }

  @override
  Future<CalendarSubscriptionDto> createSubscription({
    required String url,
    String? name,
    bool? enabled,
    int? refreshIntervalMin,
  }) async {
    final trimmedUrl = url.trim();
    final parsed = Uri.tryParse(trimmedUrl);
    if (parsed == null || !parsed.hasScheme || !parsed.hasAuthority) {
      throw ArgumentError.value(url, 'url', '请输入完整订阅地址');
    }
    final item = _SubscriptionRecord(
      id: _nextSubscriptionId++,
      url: trimmedUrl,
      name: name?.trim().isEmpty ?? true ? parsed.host : name!.trim(),
      enabled: enabled ?? true,
      refreshIntervalMin: refreshIntervalMin ?? 60,
      createdAt: DateTime.now(),
    );
    _subscriptions.add(item);
    return item.toDto();
  }

  @override
  Future<void> deleteSubscription(int id) async {
    _subscriptions.removeWhere((subscription) => subscription.id == id);
  }

  @override
  Future<List<CalendarSubscriptionDto>> listSubscriptions() async =>
      _subscriptions
          .map((subscription) => subscription.toDto())
          .toList(growable: false);

  @override
  Future<CalendarSubscriptionDto> updateSubscription(
    int id,
    Map<String, dynamic> patch,
  ) async {
    final subscription = _subscriptions
        .where((item) => item.id == id)
        .firstOrNull;
    if (subscription == null) throw StateError('未找到订阅');
    subscription.name = patch['name']?.toString().trim() ?? subscription.name;
    subscription.enabled = patch['enabled'] as bool? ?? subscription.enabled;
    subscription.refreshIntervalMin =
        patch['refreshIntervalMin'] as int? ?? subscription.refreshIntervalMin;
    return subscription.toDto();
  }
}

class _EventRecord {
  _EventRecord({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startAt,
    this.endAt,
    this.timezone = 'Asia/Shanghai',
    this.allDay = false,
    this.color,
    this.opacity = 1,
    this.repeatRule,
    required this.createdAt,
  }) : updatedAt = createdAt;

  final int id;
  String title;
  String? description;
  String? location;
  DateTime startAt;
  DateTime? endAt;
  String timezone;
  bool allDay;
  String? color;
  double opacity;
  String? repeatRule;
  final DateTime createdAt;
  DateTime updatedAt;

  void apply(Map<String, dynamic> patch) {
    title = patch['title']?.toString() ?? title;
    description = patch.containsKey('description')
        ? patch['description']?.toString()
        : description;
    location = patch.containsKey('location')
        ? patch['location']?.toString()
        : location;
    startAt = patch['startAt'] as DateTime? ?? startAt;
    endAt = patch.containsKey('endAt') ? patch['endAt'] as DateTime? : endAt;
    timezone = patch['timezone']?.toString() ?? timezone;
    allDay = patch['allDay'] as bool? ?? allDay;
    color = patch.containsKey('color') ? patch['color']?.toString() : color;
    opacity = patch['opacity'] as double? ?? opacity;
    repeatRule = patch.containsKey('repeatRule')
        ? patch['repeatRule']?.toString()
        : repeatRule;
    updatedAt = DateTime.now();
  }

  CalendarEventDto toDto() => CalendarEventDto(
    id: id,
    title: title,
    description: description,
    location: location,
    startAt: startAt,
    endAt: endAt,
    timezone: timezone,
    allDay: allDay,
    color: color,
    opacity: opacity,
    repeatRule: repeatRule,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class _SubscriptionRecord {
  _SubscriptionRecord({
    required this.id,
    required this.url,
    required this.name,
    required this.enabled,
    required this.refreshIntervalMin,
    required this.createdAt,
  });

  final int id;
  final String url;
  String name;
  bool enabled;
  int refreshIntervalMin;
  final DateTime createdAt;

  CalendarSubscriptionDto toDto() => CalendarSubscriptionDto(
    id: id,
    name: name,
    enabled: enabled,
    refreshIntervalMin: refreshIntervalMin,
    createdAt: createdAt,
  );
}
