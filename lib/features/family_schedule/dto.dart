class FamilyScheduleEventDto {
  const FamilyScheduleEventDto({
    required this.id,
    required this.userId,
    required this.memberName,
    required this.title,
    required this.startAt,
    this.endAt,
    required this.allDay,
  });

  factory FamilyScheduleEventDto.fromJson(Map<String, dynamic> json) =>
      FamilyScheduleEventDto(
        id: _int(json['Id'] ?? json['id']),
        userId: _int(json['UserId'] ?? json['userId']),
        memberName: _string(json['MemberName'] ?? json['memberName']),
        title: _string(json['Title'] ?? json['title']),
        startAt:
            _date(json['StartAt'] ?? json['startAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        endAt: _date(json['EndAt'] ?? json['endAt']),
        allDay: _bool(json['AllDay'] ?? json['allDay']),
      );

  final int id;
  final int userId;
  final String memberName;
  final String title;
  final DateTime startAt;
  final DateTime? endAt;
  final bool allDay;
}

class FamilyScheduleConflictDto {
  const FamilyScheduleConflictDto({
    required this.first,
    required this.second,
    required this.overlapStartAt,
    required this.overlapEndAt,
  });

  factory FamilyScheduleConflictDto.fromJson(Map<String, dynamic> json) =>
      FamilyScheduleConflictDto(
        first: FamilyScheduleEventDto.fromJson(
          _map(json['First'] ?? json['first']),
        ),
        second: FamilyScheduleEventDto.fromJson(
          _map(json['Second'] ?? json['second']),
        ),
        overlapStartAt:
            _date(json['OverlapStartAt'] ?? json['overlapStartAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        overlapEndAt:
            _date(json['OverlapEndAt'] ?? json['overlapEndAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  final FamilyScheduleEventDto first;
  final FamilyScheduleEventDto second;
  final DateTime overlapStartAt;
  final DateTime overlapEndAt;
}

class FamilyScheduleAvailabilityDto {
  const FamilyScheduleAvailabilityDto({
    required this.startAt,
    required this.endAt,
  });

  factory FamilyScheduleAvailabilityDto.fromJson(Map<String, dynamic> json) =>
      FamilyScheduleAvailabilityDto(
        startAt:
            _date(json['StartAt'] ?? json['startAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        endAt:
            _date(json['EndAt'] ?? json['endAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  final DateTime startAt;
  final DateTime endAt;
}

class FamilyDocumentDeadlineCreateDto {
  const FamilyDocumentDeadlineCreateDto({
    required this.documentType,
    required this.displayName,
    required this.expiresOn,
    this.holderUserId,
  });

  final String documentType;
  final String displayName;
  final DateTime expiresOn;
  final int? holderUserId;

  Map<String, dynamic> toJson() => {
    'documentType': documentType,
    'displayName': displayName,
    'expiresOn': expiresOn.toUtc().toIso8601String(),
    if (holderUserId != null) 'holderUserId': holderUserId,
  };
}

class FamilyDocumentDeadlineDto {
  const FamilyDocumentDeadlineDto({
    required this.id,
    required this.documentType,
    required this.displayName,
    this.holderUserId,
    this.holderName,
    required this.expiresOn,
    required this.isActive,
  });

  factory FamilyDocumentDeadlineDto.fromJson(Map<String, dynamic> json) =>
      FamilyDocumentDeadlineDto(
        id: _int(json['Id'] ?? json['id']),
        documentType: _string(json['DocumentType'] ?? json['documentType']),
        displayName: _string(json['DisplayName'] ?? json['displayName']),
        holderUserId: _nullableInt(
          json['HolderUserId'] ?? json['holderUserId'],
        ),
        holderName: _nullableString(json['HolderName'] ?? json['holderName']),
        expiresOn:
            _date(json['ExpiresOn'] ?? json['expiresOn']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        isActive: _bool(json['IsActive'] ?? json['isActive'], fallback: true),
      );

  final int id;
  final String documentType;
  final String displayName;
  final int? holderUserId;
  final String? holderName;
  final DateTime expiresOn;
  final bool isActive;
}

class FamilyScheduleReminderDto {
  const FamilyScheduleReminderDto({
    required this.type,
    required this.sourceId,
    required this.title,
    required this.dueDate,
    required this.daysRemaining,
    required this.confirmationId,
  });

  factory FamilyScheduleReminderDto.fromJson(Map<String, dynamic> json) =>
      FamilyScheduleReminderDto(
        type: _string(json['Type'] ?? json['type']),
        sourceId: _int(json['SourceId'] ?? json['sourceId']),
        title: _string(json['Title'] ?? json['title']),
        dueDate:
            _date(json['DueDate'] ?? json['dueDate']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        daysRemaining: _int(json['DaysRemaining'] ?? json['daysRemaining']),
        confirmationId: _int(json['ConfirmationId'] ?? json['confirmationId']),
      );

  final String type;
  final int sourceId;
  final String title;
  final DateTime dueDate;
  final int daysRemaining;
  final int confirmationId;
}

class FamilyTomorrowPreviewDto {
  const FamilyTomorrowPreviewDto({
    required this.date,
    required this.events,
    required this.conflicts,
    required this.reminders,
  });

  factory FamilyTomorrowPreviewDto.fromJson(Map<String, dynamic> json) =>
      FamilyTomorrowPreviewDto(
        date:
            _date(json['Date'] ?? json['date']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        events: _list(
          json['Events'] ?? json['events'],
        ).map(FamilyScheduleEventDto.fromJson).toList(growable: false),
        conflicts: _list(
          json['Conflicts'] ?? json['conflicts'],
        ).map(FamilyScheduleConflictDto.fromJson).toList(growable: false),
        reminders: _list(
          json['Reminders'] ?? json['reminders'],
        ).map(FamilyScheduleReminderDto.fromJson).toList(growable: false),
      );

  final DateTime date;
  final List<FamilyScheduleEventDto> events;
  final List<FamilyScheduleConflictDto> conflicts;
  final List<FamilyScheduleReminderDto> reminders;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : const <String, dynamic>{};

List<Map<String, dynamic>> _list(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false)
    : const [];

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

int? _nullableInt(Object? value) => value == null ? null : _int(value);

String _string(Object? value) => value?.toString() ?? '';

String? _nullableString(Object? value) => value?.toString();

bool _bool(Object? value, {bool fallback = false}) => value is bool
    ? value
    : value == null
    ? fallback
    : value.toString().toLowerCase() == 'true';

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());
