import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/steward/http_steward_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpStewardRepository', () {
    test('maps activities endpoints with PascalCase fields', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        {
          'Items': [_activityJson()],
          'Cursor': 'abc123',
        },
        _activityJson(),
        _undoneActivityJson(),
      ]);

      final page = await repository.listActivities(limit: 10);
      final detail = await repository.getActivity(1);
      final undone = await repository.undoActivity(1);

      expect(page.items, hasLength(1));
      expect(page.items.single.category, 'reporting');
      expect(page.cursor, 'abc123');
      expect(detail.undoable, isTrue);
      expect(undone.undoneAt, isNotNull);

      expect(requests.map((request) => request.path), [
        '/homes/1234/activities',
        '/homes/1234/activities/1',
        '/homes/1234/activities/1/undo',
      ]);
      expect(requests[0].queryParameters, {'limit': 10});
    });

    test('maps confirmation endpoints and request bodies', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        [_confirmationJson()],
        _confirmationJson(),
        _confirmationJson(),
        {
          'ConfirmedCount': 2,
          'Items': [_confirmationJson()],
        },
      ]);

      final pending = await repository.listConfirmations(
        riskLevel: 'L1',
        status: 'pending',
      );
      await repository.confirm(
        101,
        idempotencyKey: 'bc20666d-1639-420f-94d4-f5acb45762e1',
      );
      await repository.deny(101, reason: '重复建议');
      final batch = await repository.batchConfirm([
        101,
        102,
      ], idempotencyKey: 'bc20666d-1639-420f-94d4-f5acb45762e1');

      expect(pending, hasLength(1));
      expect(pending.single.riskLevel, 'L1');
      expect(batch.confirmedCount, 2);
      expect(batch.items, hasLength(1));

      expect(requests.map((request) => request.path), [
        '/homes/1234/confirmations',
        '/homes/1234/confirmations/101/confirm',
        '/homes/1234/confirmations/101/deny',
        '/homes/1234/confirmations/batch-confirm',
      ]);
      expect(requests[0].queryParameters, {
        'riskLevel': 'L1',
        'status': 'pending',
      });
      expect(requests[1].data, {
        'idempotencyKey': 'bc20666d-1639-420f-94d4-f5acb45762e1',
      });
      expect(requests[2].data, {'reason': '重复建议'});
      // 批量确认请求体只含契约字段，不含客户端猜测字段。
      expect(requests[3].data, {
        'confirmationIds': [101, 102],
        'idempotencyKey': 'bc20666d-1639-420f-94d4-f5acb45762e1',
      });
    });

    test(
      'propagates a 422 API failure without converting it to empty data',
      () async {
        final requests = <RequestOptions>[];
        final repository = await _repository(requests, const [], code: 422);

        await expectLater(
          repository.listConfirmations(),
          throwsA(
            isA<ApiException>().having((error) => error.msg, 'msg', '无效请求'),
          ),
        );
      },
    );
  });
}

Map<String, dynamic> _activityJson() => {
  'Id': 1,
  'RunId': 42,
  'Category': 'reporting',
  'Title': '已确认：调低热水器温度',
  'Description': null,
  'RiskLevel': 'L2',
  'Status': 'confirmed',
  'ResultSummary': null,
  'Undoable': true,
  'UndoneAt': null,
  'CreatedAt': '2026-08-05T10:00:00Z',
  'UpdatedAt': '2026-08-05T10:00:00Z',
};

Map<String, dynamic> _undoneActivityJson() => {
  ..._activityJson(),
  'Undoable': false,
  'UndoneAt': '2026-08-05T11:00:00Z',
};

Map<String, dynamic> _confirmationJson() => {
  'Id': 101,
  'ActivityId': null,
  'RiskLevel': 'L1',
  'Title': '开阳台灯',
  'Description': null,
  'ImpactSummary': null,
  'SuggestedAction': null,
  'Status': 'pending',
  'ExpiresAt': '2026-08-06T10:00:00Z',
  'ConfirmedAt': null,
  'DeniedAt': null,
  'ExpiredAt': null,
  'UpdatedAt': '2026-08-05T10:00:00Z',
};

Future<HttpStewardRepository> _repository(
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
  return HttpStewardRepository(api, homeIdOf: () => 1234);
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
