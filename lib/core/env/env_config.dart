// API 根地址 — 编译期默认 + 运行时覆盖（双源）。
//
// 编译期：`flutter build apk --dart-define=API_BASE_URL=https://api.example.com`
// 运行时：通过 setBaseUrl() 写入 SharedPreferences（kIsWeb 走 localStorage），
//        启动时优先读运行时值。
//
// 切地址时调用 notifyListeners()，AuthController 监听后会清空 token 与内存态并跳登录。

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnvConfig extends ChangeNotifier {
  EnvConfig._();

  static const _prefsKey = 'env.baseUrl';
  static const _fallbackBaseUrl = 'http://localhost:5280';
  static const _compileBaseUrl = String.fromEnvironment('API_BASE_URL');

  static EnvConfig? _instance;

  static EnvConfig get instance {
    final i = _instance;
    if (i != null) return i;
    throw StateError('EnvConfig 尚未初始化，请先调用 EnvConfig.init()');
  }

  static Future<EnvConfig> init({Map<String, String>? fileValues}) async {
    final prefs = await SharedPreferences.getInstance();
    final values = fileValues ?? await _loadFileValues();
    final defaultBaseUrl = _normalizeBaseUrl(
      _compileBaseUrl.isNotEmpty
          ? _compileBaseUrl
          : values['API_BASE_URL'] ?? _fallbackBaseUrl,
    );
    final instance = EnvConfig._()
      .._prefs = prefs
      .._defaultBaseUrl = defaultBaseUrl
      .._baseUrl = _normalizeBaseUrl(
        prefs.getString(_prefsKey) ?? defaultBaseUrl,
      );
    _instance = instance;
    return instance;
  }

  static Future<Map<String, String>> _loadFileValues() async {
    try {
      return parseDotEnv(await rootBundle.loadString('env/.env'));
    } on FlutterError {
      return const {};
    }
  }

  @visibleForTesting
  static Map<String, String> parseDotEnv(String content) {
    final values = <String, String>{};
    for (final rawLine in content.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final separator = line.indexOf('=');
      if (separator < 1) continue;

      final key = line.substring(0, separator).trim();
      var value = line.substring(separator + 1).trim();
      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }
      if (key.isNotEmpty) values[key] = value;
    }
    return values;
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return _fallbackBaseUrl;
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  late final SharedPreferences _prefs;
  late final String _defaultBaseUrl;
  late String _baseUrl;

  String get baseUrl => _baseUrl;
  String get apiPrefix => '$baseUrl/api/v1';

  Future<void> setBaseUrl(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _baseUrl) return;
    _baseUrl = _normalizeBaseUrl(trimmed);
    await _prefs.setString(_prefsKey, _baseUrl);
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    await _prefs.remove(_prefsKey);
    _baseUrl = _defaultBaseUrl;
    notifyListeners();
  }
}
