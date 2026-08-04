// 执行模式 17：Calendar 仓储接口。

import 'dto.dart';

abstract class CalendarRepository {
  Future<List<CalendarEventDto>> listEvents({DateTime? from, DateTime? to});
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
  });
  Future<CalendarEventDto> updateEvent(int id, Map<String, dynamic> patch);
  Future<void> deleteEvent(int id);

  Future<List<CalendarSubscriptionDto>> listSubscriptions();
  Future<CalendarSubscriptionDto> createSubscription({
    required String url,
    String? name,
    bool? enabled,
    int? refreshIntervalMin,
  });
  Future<CalendarSubscriptionDto> updateSubscription(
    int id,
    Map<String, dynamic> patch,
  );
  Future<void> deleteSubscription(int id);
}
