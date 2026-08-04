import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/settings/app_settings.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/auth/auth_controller.dart';
import 'package:nexus_mind_mobile/features/auth/http_auth_repository.dart';
import 'package:nexus_mind_mobile/main.dart';

class _MemoryTokens implements TokenStorage {
  String? access;
  String? refresh;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> write({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
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
      NexusMindApp(
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
}
