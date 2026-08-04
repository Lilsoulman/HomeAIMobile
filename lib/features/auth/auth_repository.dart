import 'dto.dart';

abstract class AuthRepository {
  Future<AuthSession> register({
    required String phone,
    required String password,
    required String displayName,
  });

  Future<AuthSession> login({required String phone, required String password});
  Future<UserProfile> me();
  Future<void> logout();
}
