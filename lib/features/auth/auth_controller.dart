// 执行模式 11：AuthController —— 唯一的登录态真理源。
// 持有 accessToken / refreshToken / 用户资料；所有 Repository 通过它取 token，
// 由它负责 401 后清场 + 跳登录（GoRouter 通过 redirect 监听）。

import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'dto.dart';
import 'auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required this.repository,
  }) : _api = apiClient,
       _storage = tokenStorage {
    _api.setOnSessionExpired(handleSessionExpired);
  }

  final ApiClient _api;
  final TokenStorage _storage;
  final AuthRepository repository;

  UserProfile? _profile;
  bool _initialized = false;
  int? _userId;
  int? _tenantId;

  UserProfile? get profile => _profile;
  int? get userId => _userId;
  int? get tenantId => _tenantId;
  bool get isLoggedIn => _userId != null;
  bool get isInitialized => _initialized;

  /// 启动时调用：尝试用已持久化的 token + 拉取 /me 还原登录态。
  Future<void> bootstrap() async {
    final access = await _storage.readAccessToken();
    final refresh = await _storage.readRefreshToken();
    if (access != null && access.isNotEmpty) {
      _api.setAccessToken(access);
    }
    if (access != null &&
        access.isNotEmpty &&
        refresh != null &&
        refresh.isNotEmpty) {
      try {
        final me = await repository.me();
        _profile = me;
        _userId = me.id;
        _initialized = true;
        notifyListeners();
        return;
      } catch (_) {
        await clearAndLogout(silent: true);
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> login({required String phone, required String password}) async {
    final session = await repository.login(phone: phone, password: password);
    await _applySession(session);
    final me = await repository.me();
    _profile = me;
    notifyListeners();
  }

  Future<void> register({
    required String phone,
    required String password,
    required String displayName,
  }) async {
    final session = await repository.register(
      phone: phone,
      password: password,
      displayName: displayName,
    );
    await _applySession(session);
    final me = await repository.me();
    _profile = me;
    notifyListeners();
  }

  Future<void> logout() async {
    await repository.logout();
    await clearAndLogout();
  }

  Future<void> clearAndLogout({bool silent = false}) async {
    await _storage.clear();
    _api.setAccessToken(null);
    _profile = null;
    _userId = null;
    _tenantId = null;
    if (!silent) notifyListeners();
  }

  Future<void> handleSessionExpired() async {
    await clearAndLogout();
  }

  Future<void> _applySession(AuthSession session) async {
    await _storage.write(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    _api.setAccessToken(session.accessToken);
    _userId = session.userId;
    _tenantId = session.tenantId;
  }
}
