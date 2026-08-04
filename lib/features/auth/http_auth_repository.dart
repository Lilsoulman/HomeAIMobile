// 执行模式 12：Auth HTTP 仓库。负责注册 / 登录 / 拉自己资料。
// refresh 由 ApiClient 拦截器内部完成，此处不重复。

import '../../../core/api/api_client.dart';
import '../../../core/installation.dart';
import 'auth_repository.dart';
import 'dto.dart';

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._api);
  final ApiClient _api;

  @override
  Future<AuthSession> register({
    required String phone,
    required String password,
    required String displayName,
    String platform = 'android',
  }) async {
    final installationId = await Installation.getOrCreate();
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/auth/register',
      body: {
        'phone': phone,
        'password': password,
        'displayName': displayName,
        'installationId': installationId,
        'platform': platform,
      },
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return AuthSession.fromJson(json);
  }

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
    String platform = 'android',
  }) async {
    final installationId = await Installation.getOrCreate();
    final json = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/auth/login',
      body: {
        'phone': phone,
        'password': password,
        'installationId': installationId,
        'platform': platform,
      },
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return AuthSession.fromJson(json);
  }

  @override
  Future<UserProfile> me() async {
    final json = await _api.request<Map<String, dynamic>>(
      method: 'GET',
      path: '/auth/me',
      parseData: (raw) => (raw as Map).cast<String, dynamic>(),
    );
    return UserProfile.fromJson(json);
  }

  @override
  Future<void> logout() async {
    try {
      await _api.request<dynamic>(
        method: 'POST',
        path: '/auth/logout',
        parseData: (_) => null,
      );
    } catch (_) {
      // 登出失败也允许本地清空。
    }
  }
}
