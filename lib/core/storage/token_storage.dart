// 执行模式 5：Token 持久化抽象。
// 原生平台（iOS/Android/macOS/Windows）走 flutter_secure_storage（Keychain/Keystore）；
// Web（H5）降级为 SharedPreferences（localStorage），有 XSS 风险，仅 dev 期间可接受。

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> write({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  static const _accessKey = 'auth.accessToken';
  static const _refreshKey = 'auth.refreshToken';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> write({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

class SharedPrefsTokenStorage implements TokenStorage {
  static const _accessKey = 'auth.accessToken';
  static const _refreshKey = 'auth.refreshToken';
  late final SharedPreferences _prefs;

  Future<SharedPrefsTokenStorage> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  @override
  Future<String?> readAccessToken() =>
      Future.value(_prefs.getString(_accessKey));

  @override
  Future<String?> readRefreshToken() =>
      Future.value(_prefs.getString(_refreshKey));

  @override
  Future<void> write({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_accessKey, accessToken);
    await _prefs.setString(_refreshKey, refreshToken);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_accessKey);
    await _prefs.remove(_refreshKey);
  }
}

Future<TokenStorage> createTokenStorage() async {
  if (kIsWeb) {
    return await SharedPrefsTokenStorage().init();
  }
  return SecureTokenStorage();
}
