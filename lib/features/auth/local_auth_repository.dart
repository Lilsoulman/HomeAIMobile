import 'auth_repository.dart';
import 'dto.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository() : _createdAt = DateTime.now().toUtc();

  final DateTime _createdAt;
  String _displayName = '本地用户';
  String _phone = '13800000000';

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async {
    _phone = phone.trim().isEmpty ? _phone : phone.trim();
    return AuthSession(
      accessToken: 'local-access-token',
      refreshToken: 'local-refresh-token',
      userId: 1,
      tenantId: 1,
    );
  }

  @override
  Future<UserProfile> me() async => UserProfile(
    id: 1,
    displayName: _displayName,
    status: 'active',
    timezone: 'Asia/Shanghai',
    locale: 'zh-CN',
    createdAt: _createdAt,
  );

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession> register({
    required String phone,
    required String password,
    required String displayName,
  }) async {
    _phone = phone.trim().isEmpty ? _phone : phone.trim();
    _displayName = displayName.trim().isEmpty ? '本地用户' : displayName.trim();
    return login(phone: _phone, password: password);
  }
}
