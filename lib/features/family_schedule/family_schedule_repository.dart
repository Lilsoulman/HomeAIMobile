import 'dto.dart';

abstract class FamilyScheduleRepository {
  Future<List<FamilyScheduleEventDto>> listEvents({
    DateTime? from,
    DateTime? to,
  });

  Future<List<FamilyScheduleConflictDto>> listConflicts({
    DateTime? from,
    DateTime? to,
  });

  Future<List<FamilyScheduleAvailabilityDto>> listAvailability({
    DateTime? from,
    DateTime? to,
    int durationMinutes = 60,
  });

  Future<FamilyDocumentDeadlineDto> createDocumentDeadline(
    FamilyDocumentDeadlineCreateDto request,
  );

  Future<List<FamilyDocumentDeadlineDto>> listDocumentDeadlines();

  Future<List<FamilyScheduleReminderDto>> listReminders({DateTime? asOf});

  Future<FamilyTomorrowPreviewDto> tomorrowPreview({DateTime? asOf});
}
