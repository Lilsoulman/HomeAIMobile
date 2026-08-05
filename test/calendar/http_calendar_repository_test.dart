import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/calendar/http_calendar_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpCalendarRepository', () {
    test(
      'maps Calendar event and subscription endpoints with PascalCase fields',
      () async {
        final requests = <RequestOptions>[];
        final repository = await _repository(requests, [
          [_eventJson()],
          _eventJson(),
          _eventJson(),
          null,
          [_subscriptionJson()],
          _subscriptionJson(),
          _subscriptionJson(),
          null,
        ]);

        final from = DateTime.utc(2026, 8, 1);
        final to = DateTime.utc(2026, 8, 31);
        final events = await repository.listEvents(from: from, to: to);
        final created = await repository.createEvent(
          title: '深度工作',
          description: '专注时段',
          location: '主卧',
          startAt: from,
          endAt: to,
          timezone: 'Asia/Shanghai',
          allDay: false,
          color: '#5B8DEF',
          opacity: 0.8,
          repeatRule: 'weekly',
        );
        await repository.updateEvent(1, {
          'title': '深度复盘',
          'color': '#3DD6A0',
          'allDay': true,
        });
        await repository.deleteEvent(1);

        final subscriptions = await repository.listSubscriptions();
        final newSub = await repository.createSubscription(
          url: 'https://example.com/cal.ics',
          name: '工作日历',
          enabled: true,
          refreshIntervalMin: 30,
        );
        await repository.updateSubscription(1, {
          'enabled': false,
          'name': '备用',
        });
        await repository.deleteSubscription(1);

        expect(events, hasLength(1));
        expect(created.id, 1);
        expect(subscriptions, hasLength(1));
        expect(newSub.id, 1);
        expect(requests.map((request) => request.path), [
          '/calendar/events',
          '/calendar/events',
          '/calendar/events/1',
          '/calendar/events/1',
          '/calendar/subscriptions',
          '/calendar/subscriptions',
          '/calendar/subscriptions/1',
          '/calendar/subscriptions/1',
        ]);
        expect(requests.first.queryParameters, {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
        });
        expect(requests[1].data, containsPair('repeatRule', 'weekly'));
        expect(requests[2].data, {
          'title': '深度复盘',
          'color': '#3DD6A0',
          'allDay': true,
        });
        expect(requests[5].data, containsPair('refreshIntervalMin', 30));
        expect(requests[6].data, containsPair('enabled', false));
      },
    );

    test(
      'propagates an API failure without converting it to empty data',
      () async {
        final repository = await _repository(
          <RequestOptions>[],
          const [],
          code: 422,
        );

        await expectLater(
          repository.listEvents(),
          throwsA(
            isA<ApiException>().having((error) => error.msg, 'msg', '无效日程'),
          ),
        );
      },
    );
  });
}

Map<String, dynamic> _eventJson() => {
  'id': 1,
  'title': '本周规划',
  'description': '复盘上周并确定本周重点',
  'location': '书房',
  'StartAt': '2026-08-04T09:00:00Z',
  'EndAt': '2026-08-04T10:00:00Z',
  'timezone': 'Asia/Shanghai',
  'AllDay': false,
  'color': '#5B8DEF',
  'opacity': 1,
  'RepeatRule': 'weekly',
  'CreatedAt': '2026-08-01T03:11:22Z',
  'UpdatedAt': '2026-08-02T03:11:22Z',
};

Map<String, dynamic> _subscriptionJson() => {
  'id': 1,
  'name': '工作日历',
  'enabled': true,
  'RefreshIntervalMin': 60,
  'LastFetchAt': '2026-08-04T08:00:00Z',
  'LastError': null,
  'CreatedAt': '2026-08-01T03:11:22Z',
};

Future<HttpCalendarRepository> _repository(
  List<RequestOptions> requests,
  List<Object?> responses, {
  int code = 0,
}) async {
  SharedPreferences.setMockInitialValues({});
  final api = ApiClient(
    tokenStorage: _MemoryTokens(),
    env: await EnvConfig.init(),
  );
  api.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: {
              'Code': code,
              'Msg': code == 0 ? 'ok' : '无效日程',
              'Data': code == 0 ? responses.removeAt(0) : null,
            },
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return HttpCalendarRepository(api);
}

class _MemoryTokens implements TokenStorage {
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
