import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/dashboard/http_dashboard_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpDashboardRepository', () {
    test('maps all dashboard modules with PascalCase fields', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [_dashboardJson()]);

      final dashboard = await repository.list();

      expect(requests.single.path, '/dashboard');
      expect(dashboard.partialFailure, isFalse);
      expect(dashboard.home.data!.deviceCount, 12);
      expect(dashboard.home.data!.onlineDeviceCount, 10);
      expect(dashboard.home.data!.offlineDeviceCount, 2);
      expect(dashboard.home.data!.spaces, hasLength(1));
      expect(dashboard.home.data!.spaces.single.spaceType, 'living_room');
      expect(dashboard.pendingConfirmations.data, hasLength(1));
      expect(dashboard.pendingConfirmations.data!.single.riskLevel, 'L1');
      expect(dashboard.stewardActivities.data!.single.category, 'reporting');
      expect(dashboard.scenes.data!.single.key, 'arrive_home');
      expect(dashboard.todos.data!.single.title, '整理客厅');
      expect(dashboard.calendar.data!.single.allDay, isFalse);
      expect(dashboard.suggestion.data!.runId, 42);
    });

    test('keeps other modules when one module is unavailable', () async {
      final requests = <RequestOptions>[];
      final json = _dashboardJson();
      json['PartialFailure'] = true;
      (json['PendingConfirmations'] as Map<String, dynamic>)
        ..['Status'] = 'unavailable'
        ..['Data'] = null
        ..['Message'] = '确认服务暂不可用';
      final repository = await _repository(requests, [json]);

      final dashboard = await repository.list();

      expect(dashboard.pendingConfirmations.isAvailable, isFalse);
      expect(dashboard.pendingConfirmations.data, isNull);
      expect(dashboard.pendingConfirmations.message, '确认服务暂不可用');
      expect(dashboard.home.isAvailable, isTrue);
      expect(dashboard.home.data, isNotNull);
      expect(dashboard.partialFailure, isTrue);
    });

    test('propagates an API failure', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, const [], code: 422);

      await expectLater(
        repository.list(),
        throwsA(
          isA<ApiException>().having((error) => error.msg, 'msg', '无效请求'),
        ),
      );
    });
  });
}

Map<String, dynamic> _dashboardJson() => {
  'GeneratedAt': '2026-08-05T10:00:00Z',
  'PartialFailure': false,
  'Home': _module(_homeJson()),
  'PendingConfirmations': _module([
    {
      'Id': 101,
      'RiskLevel': 'L1',
      'Title': '开阳台灯',
      'ImpactSummary': null,
      'Status': 'pending',
      'ExpiresAt': '2026-08-06T10:00:00Z',
      'UpdatedAt': '2026-08-05T10:00:00Z',
    },
  ]),
  'StewardActivities': _module([
    {
      'Id': 1,
      'Category': 'reporting',
      'Title': '已确认：调低热水器温度',
      'RiskLevel': 'L2',
      'Status': 'confirmed',
      'ResultSummary': null,
      'CreatedAt': '2026-08-05T10:00:00Z',
    },
  ]),
  'Scenes': _module([
    {
      'Id': 1,
      'Key': 'arrive_home',
      'Name': '回家',
      'Summary': null,
      'Status': 'available',
      'UpdatedAt': '2026-08-05T10:00:00Z',
    },
  ]),
  'Todos': _module([
    {
      'Id': 5,
      'Title': '整理客厅',
      'Status': 'pending',
      'Priority': 'high',
      'DueAt': null,
      'Pinned': false,
      'UpdatedAt': '2026-08-05T10:00:00Z',
    },
  ]),
  'Calendar': _module([
    {
      'Id': 9,
      'Title': '家庭会议',
      'StartAt': '2026-08-06T09:00:00Z',
      'EndAt': '2026-08-06T10:00:00Z',
      'AllDay': false,
      'UpdatedAt': '2026-08-05T10:00:00Z',
    },
  ]),
  'Suggestion': _module({
    'RunId': 42,
    'Summary': '建议今晚 21:00 关闭卧室照明',
    'Status': 'completed',
    'CreatedAt': '2026-08-05T10:00:00Z',
  }),
};

Map<String, dynamic> _homeJson() => {
  'SpaceCount': 1,
  'DeviceCount': 12,
  'OnlineDeviceCount': 10,
  'OfflineDeviceCount': 2,
  'Spaces': [
    {
      'Id': 1,
      'Name': '客厅',
      'SpaceType': 'living_room',
      'Summary': null,
      'DeviceCount': 5,
      'OnlineDeviceCount': 4,
      'OfflineDeviceCount': 1,
      'StateUpdatedAt': '2026-08-05T09:00:00Z',
      'UpdatedAt': '2026-08-05T10:00:00Z',
    },
  ],
};

Map<String, dynamic> _module(Object data) => {
  'Status': 'available',
  'Data': data,
  'UpdatedAt': '2026-08-05T10:00:00Z',
  'Message': null,
};

Future<HttpDashboardRepository> _repository(
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
              'Msg': code == 0 ? 'ok' : '无效请求',
              'Data': code == 0 ? responses.removeAt(0) : null,
            },
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return HttpDashboardRepository(api);
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
