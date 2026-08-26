import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/smart_home/http_smart_home_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpSmartHomeRepository', () {
    test(
      'maps SmartHome read endpoints and submits a scene run safely',
      () async {
        final requests = <RequestOptions>[];
        final repository = await _repository(requests, [
          [
            {
              'Id': 12,
              'Name': '客厅',
              'SpaceType': 'living_room',
              'Summary': '环境舒适。',
            },
          ],
          [
            {
              'Id': 34,
              'SpaceId': 12,
              'Name': '客厅主灯',
              'DeviceType': 'light',
              'OnlineStatus': 'online',
              'StateSummary': '已开启，亮度 60%。',
              'StateUpdatedAt': '2026-08-04T09:00:00Z',
            },
          ],
          [
            {
              'Key': 'sleep',
              'Name': '睡眠',
              'Summary': '调暗灯光。',
              'Status': 'active',
              'UpdatedAt': '2026-08-04T09:00:00Z',
            },
          ],
          {'RunId': 88, 'Status': 'queued'},
          [
            {
              'Key': 'sleep',
              'Name': '睡眠',
              'Summary': '调暗灯光。',
              'Status': 'active',
              'UpdatedAt': '2026-08-04T10:00:00Z',
            },
          ],
        ]);

        final spaces = await repository.listSpaces();
        final devices = await repository.listDevices(spaceId: spaces.single.id);
        final scenes = await repository.listScenes();
        final updatedScene = await repository.runScene('sleep');

        expect(spaces.single.id, '12');
        expect(spaces.single.sortOrder, 0);
        expect(devices.single.spaceId, '12');
        expect(devices.single.isOnline, isTrue);
        expect(devices.single.updatedAt.toUtc().hour, 9);
        expect(scenes.single.requiresConfirmation, isTrue);
        expect(updatedScene.lastRunAt?.toUtc().hour, 10);
        expect(requests.map((request) => request.path), [
          '/smart-home/spaces',
          '/smart-home/devices',
          '/smart-home/scenes',
          '/smart-home/scenes/sleep/run',
          '/smart-home/scenes',
        ]);
        expect(requests[1].queryParameters, {'spaceId': '12'});
        expect(requests[3].data['idempotencyKey'], isA<String>());
        expect((requests[3].data['idempotencyKey'] as String).length, 36);
      },
    );

    test(
      'uses safe defaults when optional response fields are missing',
      () async {
        final repository = await _repository(<RequestOptions>[], [
          [{}],
          [{}],
          [{}],
        ]);

        final spaces = await repository.listSpaces();
        final devices = await repository.listDevices();
        final scenes = await repository.listScenes();

        expect(spaces.single.name, isEmpty);
        expect(spaces.single.sortOrder, 0);
        expect(devices.single.isOnline, isFalse);
        expect(
          devices.single.updatedAt.isAtSameMomentAs(DateTime.utc(1970)),
          isTrue,
        );
        expect(scenes.single.description, isEmpty);
        expect(scenes.single.requiresConfirmation, isTrue);
        expect(scenes.single.lastRunAt, isNull);
      },
    );

    test('maps device health summary and detail endpoints (B10/B14)', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        {
          'Total': 3,
          'Healthy': 1,
          'Degraded': 1,
          'Offline': 1,
          'LowBattery': 1,
          'DominantStatus': 'degraded',
        },
        {
          'Id': 34,
          'SpaceId': 12,
          'Name': '卧室空调',
          'DeviceType': 'air_conditioner',
          'OnlineStatus': 'online',
          'ZigbeeRole': 'router',
          'BatteryLevel': 15,
          'SignalLqi': 90,
          'HealthStatus': 'low_battery',
          'StateUpdatedAt': '2026-08-04T09:00:00Z',
        },
      ]);

      final summary = await repository.fetchDeviceHealthSummary(spaceId: '12');
      final detail = await repository.fetchDeviceHealth(34);

      expect(summary.total, 3);
      expect(summary.offline, 1);
      expect(summary.lowBattery, 1);
      expect(summary.dominantStatus, 'degraded');
      expect(detail.id, 34);
      expect(detail.spaceId, 12);
      expect(detail.healthStatus, 'low_battery');
      expect(detail.batteryLevel, 15);
      expect(detail.isLowBattery, isTrue);
      expect(detail.isWeakSignal, isFalse);
      expect(detail.healthLabel, '电量不足');
      expect(detail.stateUpdatedAt?.toUtc().hour, 9);
      expect(requests.map((request) => request.path), [
        '/smart-home/devices/health',
        '/smart-home/devices/34/health',
      ]);
      expect(requests[0].queryParameters, {'spaceId': '12'});
    });

    test(
      'maps development mock bootstrap without exposing provider fields',
      () async {
        final requests = <RequestOptions>[];
        final repository = await _repository(requests, [
          {
            'IsMock': true,
            'Disclaimer': '仅用于开发，不代表真实状态。',
            'GeneratedAt': '2026-08-24T01:00:00Z',
            'Spaces': [
              {
                'Id': -101,
                'Name': '客厅',
                'SpaceType': 'living_room',
                'Summary': '舒适',
                'DeviceCount': 1,
                'UpdatedAt': '2026-08-24T01:00:00Z',
              },
            ],
            'Devices': [
              {
                'Id': -201,
                'SpaceId': -101,
                'Name': '主灯',
                'DeviceType': 'light',
                'OnlineStatus': 'online',
                'StateSummary': '已开启',
                'HealthStatus': 'healthy',
                'StateUpdatedAt': '2026-08-24T01:00:00Z',
              },
            ],
            'Scenes': [
              {
                'Key': 'sleep',
                'Name': '睡眠',
                'Summary': '调暗灯光',
                'Status': 'active',
                'UpdatedAt': '2026-08-24T01:00:00Z',
              },
            ],
            'DeviceHealth': {
              'Total': 1,
              'Healthy': 1,
              'Degraded': 0,
              'Offline': 0,
              'LowBattery': 0,
              'DominantStatus': 'healthy',
            },
          },
        ], useMockBootstrap: true);

        final bootstrap = await repository.loadBootstrap();

        expect(bootstrap.isMock, isTrue);
        expect(bootstrap.disclaimer, contains('不代表真实'));
        expect(bootstrap.spaces.single.id, '-101');
        expect(bootstrap.devices.single.healthStatus, 'healthy');
        expect(bootstrap.deviceHealth.healthy, 1);
        expect(requests.map((request) => request.path), [
          '/smart-home/mock/bootstrap',
        ]);
      },
    );

    test('health detail falls back safely when fields are absent', () async {
      final repository = await _repository(<RequestOptions>[], [
        {'Id': 7},
      ]);

      final detail = await repository.fetchDeviceHealth(7);

      expect(detail.name, isEmpty);
      expect(detail.healthStatus, isNull);
      expect(detail.isLowBattery, isFalse);
      expect(detail.isWeakSignal, isFalse);
      expect(detail.healthLabel, '已离线');
    });
  });
}

Future<HttpSmartHomeRepository> _repository(
  List<RequestOptions> requests,
  List<Object?> responses, {
  bool useMockBootstrap = false,
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
            data: {'Code': 0, 'Msg': 'ok', 'Data': responses.removeAt(0)},
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return HttpSmartHomeRepository(api, useMockBootstrap: useMockBootstrap);
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
