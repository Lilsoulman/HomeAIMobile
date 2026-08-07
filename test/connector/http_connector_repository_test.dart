// P8 我的连接 HTTP：B18 授权会话创建/查询/撤销、
// B19 个人连接汇总、redirectUri 请求体、错误传递。

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/connector/connector_repository.dart';
import 'package:nexus_mind_mobile/features/connector/http_connector_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HttpConnectorRepository personal authorization', () {
    test(
      'createAuthorizationSession posts redirectUri and parses session',
      () async {
        final requests = <RequestOptions>[];
        final repository = await _repository(requests, [_sessionJson()]);

        final session = await repository.createAuthorizationSession(
          'mock_oauth',
        );

        expect(session.sessionId, 101);
        expect(session.providerCode, 'mock_oauth');
        expect(session.providerName, 'Mock OAuth（开发验证）');
        expect(session.status, AuthorizationSessionStatus.pending);
        expect(session.expiresAt, DateTime.parse('2026-08-07T10:10:00Z'));
        expect(session.authorizationUrl, contains('/authorize?state='));
        expect(session.redirectUri, isNull);

        expect(
          requests.single.path,
          '/connector-providers/mock_oauth/authorizations',
        );
        expect(requests.single.data, {
          'redirectUri': 'https://app.example.com/callback',
        });
      },
    );

    test('fetchAuthorizationSession parses desensitized view', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, [
        {
          'SessionId': 101,
          'ProviderCode': 'mock_oauth',
          'ProviderName': 'Mock OAuth（开发验证）',
          'Status': 'completed',
          'ExpiresAt': '2026-08-07T10:10:00Z',
          'RedirectUri': 'https://app.example.com/callback',
        },
      ]);

      final session = await repository.fetchAuthorizationSession(101);

      expect(session.status, AuthorizationSessionStatus.completed);
      expect(session.authorizationUrl, isNull);
      expect(session.redirectUri, 'https://app.example.com/callback');
      expect(requests.single.path, '/connector-authorizations/101');
    });

    test('revokeAuthorization issues DELETE', () async {
      final requests = <RequestOptions>[];
      // 注意不能用 const 列表：拦截器内 removeAt(0) 需要可变列表。
      final repository = await _repository(requests, [null]);

      await repository.revokeAuthorization(101);

      expect(requests.single.method, 'DELETE');
      expect(requests.single.path, '/connector-authorizations/101');
    });

    test(
      'listMyPersonalConnections parses full summary with null branches',
      () async {
        final requests = <RequestOptions>[];
        final repository = await _repository(requests, [
          [
            {
              'ConnectorId': 8,
              'ProviderId': 1,
              'ProviderCode': 'mock_oauth',
              'ProviderName': 'Mock OAuth（开发验证）',
              'Name': '我的日历',
              'Status': 'connected',
              'AuthStatus': 'connected',
              'LastSyncAt': null,
              'LastHealthAt': '2026-08-07T09:00:00Z',
              'LastSessionId': 101,
              'LastSessionStatus': 'completed',
              'LastSessionExpiresAt': '2026-08-07T10:00:00Z',
            },
            {
              'ConnectorId': 9,
              'ProviderId': 2,
              'ProviderCode': 'notes',
              'ProviderName': '个人笔记',
              'Name': '个人笔记',
              'Status': 'disconnected',
              'AuthStatus': 'revoked',
              'LastSyncAt': null,
              'LastHealthAt': null,
              'LastSessionId': null,
              'LastSessionStatus': null,
              'LastSessionExpiresAt': null,
            },
          ],
        ]);

        final items = await repository.listMyPersonalConnections();

        expect(requests.single.path, '/connector-authorizations/my');
        expect(items, hasLength(2));
        final first = items.first;
        expect(first.connectorId, 8);
        expect(first.providerCode, 'mock_oauth');
        expect(first.name, '我的日历');
        expect(first.status, ConnectorConnectionStatus.connected);
        expect(first.authStatus, PersonalAuthStatus.connected);
        expect(first.lastSessionId, 101);
        expect(first.lastSessionStatus, AuthorizationSessionStatus.completed);
        final second = items[1];
        expect(second.authStatus, PersonalAuthStatus.revoked);
        expect(second.lastSessionId, isNull);
        expect(second.lastSessionStatus, isNull);
        expect(second.lastSessionExpiresAt, isNull);
      },
    );

    test('propagates a 422 redirect-uri rejection', () async {
      final requests = <RequestOptions>[];
      final repository = await _repository(requests, const [], code: 422);

      await expectLater(
        repository.createAuthorizationSession('mock_oauth'),
        throwsA(
          isA<ApiException>().having((error) => error.msg, 'msg', '回调地址不在白名单'),
        ),
      );
    });
  });
}

Map<String, dynamic> _sessionJson() => {
  'SessionId': 101,
  'ProviderCode': 'mock_oauth',
  'ProviderName': 'Mock OAuth（开发验证）',
  'Status': 'pending',
  'ExpiresAt': '2026-08-07T10:10:00Z',
  'AuthorizationUrl':
      'http://localhost:5280/api/v1/connector-providers/mock_oauth/authorize?state=abc',
};

Future<HttpConnectorRepository> _repository(
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
              'Msg': code == 0 ? 'ok' : '回调地址不在白名单',
              'Data': code == 0 ? responses.removeAt(0) : null,
            },
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return HttpConnectorRepository(api);
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
