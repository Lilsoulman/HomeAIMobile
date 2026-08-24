import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/settings/app_settings.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/auth/auth_controller.dart';
import 'package:nexus_mind_mobile/features/auth/http_auth_repository.dart';
import 'package:nexus_mind_mobile/main.dart';
import 'package:nexus_mind_mobile/pages/daily_control_pages.dart';

class _MemoryTokens implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> write({
    required String accessToken,
    required String refreshToken,
  }) async {}
}

void main() {
  testWidgets('unauthenticated users are sent to login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final env = await EnvConfig.init();
    final settings = await AppSettings.load();
    final storage = _MemoryTokens();
    final api = ApiClient(tokenStorage: storage, env: env);
    final auth = AuthController(
      apiClient: api,
      tokenStorage: storage,
      repository: HttpAuthRepository(api),
    );
    await auth.bootstrap();

    await tester.pumpWidget(
      HomeMindApp(
        auth: auth,
        env: env,
        tokenStorage: storage,
        api: api,
        settings: settings,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('登录'), findsAtLeastNWidgets(1));
    expect(find.text('还没有账号？立即注册'), findsOneWidget);
  });

  testWidgets('daily control placeholders explain unavailable contracts', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ScenesPage()));
    expect(find.text('场景正在等待接入'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: DevicesPage()));
    expect(find.text('尚无可显示设备'), findsOneWidget);
  });
}
