import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preserves the API Msg from a 401 login response', () async {
    final api = await _apiClient();
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 401,
                data: {'Code': 401, 'Msg': '手机号或密码错误。', 'Data': null},
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    await expectLater(
      api.post<dynamic>(
        '/auth/login',
        body: {'phone': '13800000000', 'password': 'password'},
        parseData: (_) => null,
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 401)
            .having((error) => error.msg, 'msg', '手机号或密码错误。'),
      ),
    );
  });

  test('post delegates method, body, and parser to request', () async {
    final api = await _apiClient();
    late RequestOptions request;
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'Code': 0,
                'Msg': 'ok',
                'Data': {'id': 7},
              },
            ),
          );
        },
      ),
    );

    final id = await api.post<int>(
      '/protected-resource',
      body: {'title': 'Buy milk'},
      parseData: (raw) => (raw as Map<String, dynamic>)['id'] as int,
    );

    expect(id, 7);
    expect(request.method, 'POST');
    expect(request.path, '/protected-resource');
    expect(request.data, {'title': 'Buy milk'});
  });
}

Future<ApiClient> _apiClient() async {
  SharedPreferences.setMockInitialValues({});
  return ApiClient(tokenStorage: _MemoryTokens(), env: await EnvConfig.init());
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
