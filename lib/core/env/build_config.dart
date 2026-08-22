import 'package:flutter/foundation.dart';

enum AppEnvironment { test, production }

class BuildConfig {
  BuildConfig._();

  static const _compiledEnvironment = String.fromEnvironment('APP_ENV');

  static late final AppEnvironment environment;

  static bool get isTest => environment == AppEnvironment.test;

  static void initialize({
    required String? nativeFlavor,
    bool releaseMode = kReleaseMode,
  }) {
    environment = resolveEnvironment(
      compiledEnvironment: _compiledEnvironment,
      nativeFlavor: nativeFlavor,
      releaseMode: releaseMode,
    );
  }

  @visibleForTesting
  static AppEnvironment resolveEnvironment({
    required String compiledEnvironment,
    required String? nativeFlavor,
    required bool releaseMode,
  }) {
    final normalizedDefine = compiledEnvironment.trim().toLowerCase();
    var normalizedFlavor = nativeFlavor?.trim().toLowerCase() ?? '';
    if (normalizedFlavor == 'staging') {
      normalizedFlavor = 'test';
    }

    if (normalizedDefine.isEmpty) {
      if (releaseMode) {
        throw StateError('Release 构建必须通过 --dart-define-from-file 指定 APP_ENV。');
      }
      return _parseEnvironment(
        normalizedFlavor.isEmpty ? 'test' : normalizedFlavor,
        source: 'native flavor',
      );
    }

    final environment = _parseEnvironment(normalizedDefine, source: 'APP_ENV');
    if (normalizedFlavor.isNotEmpty && normalizedFlavor != environment.name) {
      throw StateError(
        'APP_ENV=$normalizedDefine 与 Android flavor=$normalizedFlavor 不一致。',
      );
    }
    return environment;
  }

  static AppEnvironment _parseEnvironment(
    String value, {
    required String source,
  }) {
    return switch (value) {
      'test' => AppEnvironment.test,
      'production' => AppEnvironment.production,
      _ => throw StateError('$source 只允许 test 或 production，当前为：$value。'),
    };
  }
}
