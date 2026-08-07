// P5c 个人生活专家 HTTP：Intent / InputJson / IdempotencyKey 请求体、
// confirm 路径与幂等键、PascalCase 响应映射、错误传递。

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/life/http_life_expert_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpLifeExpertRepository', () {
    test('recommend posts Intent and InputJson with idempotency key', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [_recommendJson()]);

      final result = await repository.recommend(
        time: 'evening',
        location: '城西',
        taste: '面',
        idempotencyKey: 'key-1',
      );

      expect(result.status, 'completed');
      expect(result.resultSummary, '推荐 2 家面馆');
      expect(result.recommendations, hasLength(1));
      expect(result.recommendations.single.favoriteId, 501);
      expect(result.recommendations.single.name, '老王面馆');
      expect(result.recommendations.single.reason, '口味匹配');
      expect(result.recommendations.single.tags, ['面']);

      expect(requests.single.path, '/experts/personal-life-expert/runs');
      expect(requests.single.data, {
        'Intent': 'recommend',
        'InputJson': jsonEncode({
          'time': 'evening',
          'location': '城西',
          'taste': '面',
        }),
        'IdempotencyKey': 'key-1',
      });
    });

    test('planTrip posts plan Intent with destination and days', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [_planJson()]);

      final result = await repository.planTrip(
        destination: '杭州',
        days: 2,
        idempotencyKey: 'key-2',
      );

      expect(result.status, 'pending_actions');
      expect(result.actions, hasLength(1));
      expect(result.actions.single.actionType, 'calendar_create_event');
      expect(result.actions.single.riskLevel, 'L1');
      expect(result.actions.single.title, '杭州 行程 D1');

      expect(requests.single.data, {
        'Intent': 'plan',
        'InputJson': jsonEncode({'destination': '杭州', 'days': 2}),
        'IdempotencyKey': 'key-2',
      });
    });

    test('confirmPlanAction posts only idempotency key', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [_confirmedActionJson()]);

      final action = await repository.confirmPlanAction(
        runId: 7,
        actionId: 11,
        idempotencyKey: 'key-3',
      );

      expect(action.status, 'completed');
      expect(action.title, '杭州 行程 D1');

      expect(
        requests.single.path,
        '/experts/personal-life-expert/runs/7/actions/11/confirm',
      );
      expect(requests.single.data, {'IdempotencyKey': 'key-3'});
    });

    test('propagates a 409 terminal-state failure', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, const [], code: 409);

      await expectLater(
        repository.confirmPlanAction(
          runId: 7,
          actionId: 11,
          idempotencyKey: 'key-3',
        ),
        throwsA(
          isA<ApiException>().having((error) => error.msg, 'msg', '状态冲突'),
        ),
      );
    });
  });
}

Map<String, dynamic> _recommendJson() => {
  'Status': 'completed',
  'ResultSummary': '推荐 2 家面馆',
  'Recommendations': [
    {
      'FavoriteId': 501,
      'Name': '老王面馆',
      'Reason': '口味匹配',
      'Tags': ['面'],
    },
  ],
};

Map<String, dynamic> _planJson() => {
  'Status': 'pending_actions',
  'ResultSummary': '2 天行程已生成',
  'Actions': [
    {
      'Id': 11,
      'ActionType': 'calendar_create_event',
      'Status': 'pending',
      'Title': '杭州 行程 D1',
      'Description': '第一天：西湖漫步',
      'RiskLevel': 'L1',
    },
  ],
};

Map<String, dynamic> _confirmedActionJson() => {
  'Id': 11,
  'ActionType': 'calendar_create_event',
  'Status': 'completed',
  'Title': '杭州 行程 D1',
  'Description': '第一天：西湖漫步',
  'RiskLevel': 'L1',
};

Future<HttpLifeExpertRepository> _repository(
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
              'Msg': code == 0 ? 'ok' : '状态冲突',
              'Data': code == 0 ? responses.removeAt(0) : null,
            },
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return HttpLifeExpertRepository(api);
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
