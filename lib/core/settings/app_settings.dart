import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs)
    : _darkMode = _prefs.getBool(_darkKey) ?? true,
      _language = _prefs.getString(_languageKey) ?? 'zh-CN',
      _updatedAt =
          DateTime.tryParse(_prefs.getString(_updatedKey) ?? '') ??
          DateTime.now();

  static const _darkKey = 'settings.darkMode';
  static const _languageKey = 'settings.language';
  static const _updatedKey = 'settings.updatedAt';

  final SharedPreferences _prefs;
  bool _darkMode;
  String _language;
  DateTime _updatedAt;

  bool get darkMode => _darkMode;
  String get language => _language;
  DateTime get updatedAt => _updatedAt;

  static Future<AppSettings> load() async =>
      AppSettings._(await SharedPreferences.getInstance());

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _persist();
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    await _persist();
    notifyListeners();
  }

  Future<void> sync(ApiClient api) async {
    final local = _payload();
    final pulled = await api.request<dynamic>(
      method: 'POST',
      path: '/sync/pull',
      body: {
        'entity': 'settings',
        'since': _updatedAt.toUtc().toIso8601String(),
      },
      parseData: (raw) => raw,
    );
    final items = pulled is Map && pulled['items'] is List
        ? pulled['items'] as List
        : const [];
    for (final item in items.whereType<Map>()) {
      final remote = item.cast<String, dynamic>();
      final remoteTime = DateTime.tryParse(
        remote['updatedAt']?.toString() ?? '',
      );
      if (remoteTime != null && remoteTime.isAfter(_updatedAt)) {
        _darkMode = remote['darkMode'] == true;
        _language = remote['language']?.toString() ?? _language;
        _updatedAt = remoteTime.toLocal();
        await _persist(markUpdated: false);
      }
    }
    await api.request<dynamic>(
      method: 'POST',
      path: '/sync/push',
      body: {
        'entity': 'settings',
        'items': [local],
      },
      parseData: (raw) => raw,
    );
    notifyListeners();
  }

  Map<String, dynamic> _payload() => {
    'darkMode': _darkMode,
    'language': _language,
    'updatedAt': _updatedAt.toUtc().toIso8601String(),
  };

  Future<void> _persist({bool markUpdated = true}) async {
    if (markUpdated) _updatedAt = DateTime.now();
    await Future.wait([
      _prefs.setBool(_darkKey, _darkMode),
      _prefs.setString(_languageKey, _language),
      _prefs.setString(_updatedKey, _updatedAt.toIso8601String()),
    ]);
  }
}
