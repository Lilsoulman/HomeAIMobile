import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/env/build_config.dart';

void main() {
  group('BuildConfig.resolveEnvironment', () {
    test('解析 test 环境', () {
      expect(
        BuildConfig.resolveEnvironment(
          compiledEnvironment: 'test',
          nativeFlavor: 'staging',
          releaseMode: true,
        ),
        AppEnvironment.test,
      );
    });

    test('解析 production 环境', () {
      expect(
        BuildConfig.resolveEnvironment(
          compiledEnvironment: 'production',
          nativeFlavor: 'production',
          releaseMode: true,
        ),
        AppEnvironment.production,
      );
    });

    test('调试构建未指定环境时默认使用 test', () {
      expect(
        BuildConfig.resolveEnvironment(
          compiledEnvironment: '',
          nativeFlavor: null,
          releaseMode: false,
        ),
        AppEnvironment.test,
      );
    });

    test('Release 构建缺少 APP_ENV 时失败', () {
      expect(
        () => BuildConfig.resolveEnvironment(
          compiledEnvironment: '',
          nativeFlavor: 'production',
          releaseMode: true,
        ),
        throwsStateError,
      );
    });

    test('APP_ENV 与原生 flavor 不一致时失败', () {
      expect(
        () => BuildConfig.resolveEnvironment(
          compiledEnvironment: 'test',
          nativeFlavor: 'production',
          releaseMode: true,
        ),
        throwsStateError,
      );
    });
  });
}
