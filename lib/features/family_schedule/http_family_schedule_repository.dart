import '../../core/api/api_client.dart';
import 'dto.dart';
import 'family_schedule_repository.dart';

class HttpFamilyScheduleRepository implements FamilyScheduleRepository {
  HttpFamilyScheduleRepository(this._api, {required this.homeIdOf});

  final ApiClient _api;
  final int Function() homeIdOf;

  String get _path => '/homes/${homeIdOf()}/schedule';

  Future<dynamic> _request({
    required String method,
    required String path,
    Object? body,
    Map<String, dynamic>? query,
  }) => _api.request<dynamic>(
    method: method,
    path: path,
    body: body,
    query: query,
    parseData: (value) => value,
  );

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : const <String, dynamic>{};

  List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList(growable: false)
      : const [];

  Map<String, dynamic>? _rangeQuery(DateTime? from, DateTime? to) {
    if (from == null && to == null) return null;
    return {
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    };
  }

  @override
  Future<List<FamilyScheduleEventDto>> listEvents({
    DateTime? from,
    DateTime? to,
  }) async => _list(
    await _request(
      method: 'GET',
      path: '$_path/events',
      query: _rangeQuery(from, to),
    ),
  ).map(FamilyScheduleEventDto.fromJson).toList(growable: false);

  @override
  Future<List<FamilyScheduleConflictDto>> listConflicts({
    DateTime? from,
    DateTime? to,
  }) async => _list(
    await _request(
      method: 'GET',
      path: '$_path/conflicts',
      query: _rangeQuery(from, to),
    ),
  ).map(FamilyScheduleConflictDto.fromJson).toList(growable: false);

  @override
  Future<List<FamilyScheduleAvailabilityDto>> listAvailability({
    DateTime? from,
    DateTime? to,
    int durationMinutes = 60,
  }) async => _list(
    await _request(
      method: 'GET',
      path: '$_path/availability',
      query: {...?_rangeQuery(from, to), 'durationMinutes': durationMinutes},
    ),
  ).map(FamilyScheduleAvailabilityDto.fromJson).toList(growable: false);

  @override
  Future<FamilyDocumentDeadlineDto> createDocumentDeadline(
    FamilyDocumentDeadlineCreateDto request,
  ) async => FamilyDocumentDeadlineDto.fromJson(
    _map(
      await _request(
        method: 'POST',
        path: '$_path/document-deadlines',
        body: request.toJson(),
      ),
    ),
  );

  @override
  Future<List<FamilyDocumentDeadlineDto>> listDocumentDeadlines() async =>
      _list(
        await _request(method: 'GET', path: '$_path/document-deadlines'),
      ).map(FamilyDocumentDeadlineDto.fromJson).toList(growable: false);

  @override
  Future<List<FamilyScheduleReminderDto>> listReminders({
    DateTime? asOf,
  }) async => _list(
    await _request(
      method: 'GET',
      path: '$_path/reminders',
      query: asOf == null ? null : {'asOf': asOf.toUtc().toIso8601String()},
    ),
  ).map(FamilyScheduleReminderDto.fromJson).toList(growable: false);

  @override
  Future<FamilyTomorrowPreviewDto> tomorrowPreview({DateTime? asOf}) async =>
      FamilyTomorrowPreviewDto.fromJson(
        _map(
          await _request(
            method: 'GET',
            path: '$_path/tomorrow-preview',
            query: asOf == null
                ? null
                : {'asOf': asOf.toUtc().toIso8601String()},
          ),
        ),
      );
}
