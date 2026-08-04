// 执行模式 4：API 根地址 — 编译期默认 + 运行时覆盖（双源）。
//
// 编译期：`flutter build apk --dart-define=API_BASE_URL=https://api.example.com`
// 运行时：通过 setBaseUrl() 写入 SharedPreferences（kIsWeb 走 localStorage），
//        启动时优先读运行时值。
//
// 切地址时调用 notifyListeners()，AuthController 监听后会清空 token 与内存态并跳登录。

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnvConfig extends ChangeNotifier {
  EnvConfig._();

  static const _prefsKey = 'env.baseUrl';
  static const _compileDefault = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5280',
  );

  static EnvConfig? _instance;

  static EnvConfig get instance {
    final i = _instance;
    if (i != null) return i;
    throw StateError('EnvConfig 尚未初始化，请先调用 EnvConfig.init()');
  }

  static Future<EnvConfig> init() async {
    final prefs = await SharedPreferences.getInstance();
    final instance = EnvConfig._()
      .._prefs = prefs
      .._baseUrl = prefs.getString(_prefsKey) ?? _compileDefault;
    _instance = instance;
    return instance;
  }

  late final SharedPreferences _prefs;
  late String _baseUrl;

  String get baseUrl => _baseUrl;
  String get apiPrefix => '$baseUrl/api/v1';

  Future<void> setBaseUrl(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _baseUrl) return;
    _baseUrl = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    await _prefs.setString(_prefsKey, _baseUrl);
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    await _prefs.remove(_prefsKey);
    _baseUrl = _compileDefault;
    notifyListeners();
  }
}
