import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/family_schedule/dto.dart';
import 'package:nexus_mind_mobile/features/family_schedule/http_family_schedule_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps B46 PascalCase responses and camelCase requests', () async {
    SharedPreferences.setMockInitialValues({});
    final paths = <String>[];
    Map<String, dynamic>? requestBody;
    final api = ApiClient(tokenStorage: _Tokens(), env: await EnvConfig.init());
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          paths.add(options.path);
          if (options.data is Map) {
            requestBody = (options.data as Map).cast<String, dynamic>();
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'Code': 0, 'Msg': 'ok', 'Data': _dataFor(options)},
            ),
          );
        },
      ),
    );
    final repository = HttpFamilyScheduleRepository(api, homeIdOf: () => 42);
    final from = DateTime.utc(2026, 8, 20);
    final to = from.add(const Duration(days: 7));

    expect(
      (await repository.listEvents(from: from, to: to)).single.memberName,
      '小明',
    );
    expect((await repository.listConflicts()).single.first.title, '家长会');
    expect((await repository.listAvailability()).single.endAt.hour, 11);
    expect(
      (await repository.listDocumentDeadlines()).single.displayName,
      '妈妈护照',
    );
    expect((await repository.listReminders()).single.daysRemaining, 2);
    expect((await repository.tomorrowPreview()).events.single.title, '家长会');
    await repository.createDocumentDeadline(
      FamilyDocumentDeadlineCreateDto(
        documentType: 'passport',
        displayName: '妈妈护照',
        expiresOn: DateTime.utc(2027, 8, 20),
      ),
    );

    expect(paths, contains('/homes/42/schedule/availability'));
    expect(requestBody, containsPair('documentType', 'passport'));
    expect(requestBody, containsPair('displayName', '妈妈护照'));
    expect(requestBody, containsPair('expiresOn', '2027-08-20T00:00:00.000Z'));
  });

  test('forwards API failures', () async {
    SharedPreferences.setMockInitialValues({});
    final api = ApiClient(tokenStorage: _Tokens(), env: await EnvConfig.init());
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 422,
            data: {'Code': 422, 'Msg': '日期范围无效', 'Data': null},
          ),
        ),
      ),
    );
    final repository = HttpFamilyScheduleRepository(api, homeIdOf: () => 42);

    await expectLater(repository.listEvents(), throwsA(isA<ApiException>()));
  });
}

Object _dataFor(RequestOptions options) => switch (options.path) {
  '/homes/42/schedule/events' => [_event()],
  '/homes/42/schedule/conflicts' => [
    {
      'First': _event(),
      'Second': {..._event(), 'Id': 2, 'MemberName': '小红', 'Title': '钢琴课'},
      'OverlapStartAt': '2026-08-21T09:30:00Z',
      'OverlapEndAt': '2026-08-21T10:00:00Z',
    },
  ],
  '/homes/42/schedule/availability' => [
    {'StartAt': '2026-08-22T09:00:00Z', 'EndAt': '2026-08-22T11:00:00Z'},
  ],
  '/homes/42/schedule/document-deadlines' when options.method == 'GET' => [
    _deadline(),
  ],
  '/homes/42/schedule/document-deadlines' => _deadline(),
  '/homes/42/schedule/reminders' => [
    {
      'Type': 'document_deadline',
      'SourceId': 8,
      'Title': '妈妈护照即将到期',
      'DueDate': '2026-08-22T00:00:00Z',
      'DaysRemaining': 2,
      'ConfirmationId': 11,
    },
  ],
  '/homes/42/schedule/tomorrow-preview' => {
    'Date': '2026-08-21T00:00:00Z',
    'Events': [_event()],
    'Conflicts': const [],
    'Reminders': const [],
  },
  _ => const [],
};

Map<String, dynamic> _event() => {
  'Id': 1,
  'UserId': 3,
  'MemberName': '小明',
  'Title': '家长会',
  'StartAt': '2026-08-21T09:00:00Z',
  'EndAt': '2026-08-21T10:00:00Z',
  'AllDay': false,
};

Map<String, dynamic> _deadline() => {
  'Id': 8,
  'DocumentType': 'passport',
  'DisplayName': '妈妈护照',
  'HolderUserId': 3,
  'HolderName': '妈妈',
  'ExpiresOn': '2026-08-22T00:00:00Z',
  'IsActive': true,
};

class _Tokens implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> write({
    required String accessToken,
    required String refreshToken,
  }) async {}
}
