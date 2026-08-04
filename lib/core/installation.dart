// 执行模式 6：installationId —— 首启写入 secure storage，恒久不变。
// 同时保留在 SharedPreferences（Web 兜底），secure 不可用时回退。

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Installation {
  static const _secureKey = 'installation.id';
  static const _prefsKey = 'installation.id';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String? _cached;

  static Future<String> getOrCreate() async {
    if (_cached != null) return _cached!;
    if (!kIsWeb) {
      final existing = await _storage.read(key: _secureKey);
      if (existing != null && existing.isNotEmpty) {
        _cached = existing;
        return existing;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final existingPrefs = prefs.getString(_prefsKey);
    if (existingPrefs != null && existingPrefs.isNotEmpty) {
      _cached = existingPrefs;
      if (!kIsWeb) await _storage.write(key: _secureKey, value: existingPrefs);
      return existingPrefs;
    }
    final fresh = const Uuid().v4();
    await prefs.setString(_prefsKey, fresh);
    if (!kIsWeb) await _storage.write(key: _secureKey, value: fresh);
    _cached = fresh;
    return fresh;
  }
}
