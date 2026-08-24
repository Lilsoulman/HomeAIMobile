import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/settings/app_settings.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/features/auth/auth_controller.dart';
import 'package:nexus_mind_mobile/features/auth/http_auth_repository.dart';
import 'package:nexus_mind_mobile/pages/daily_control_pages.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders the controlled daily control tabs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            Expanded(child: HomeOverviewPage()),
            Expanded(child: ScenesPage()),
            Expanded(child: DevicesPage()),
          ],
        ),
      ),
    );

    expect(find.text('等待家庭状态'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-status-card')), findsOneWidget);
    expect(find.text('服务端状态契约发布后，将在这里呈现家庭环境与设备摘要。'), findsOneWidget);
  });

  testWidgets('renders account controls without legacy entries', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    final env = await EnvConfig.init();
    final storage = _MemoryTokens();
    final api = ApiClient(tokenStorage: storage, env: env);
    final auth = AuthController(
      apiClient: api,
      tokenStorage: storage,
      repository: HttpAuthRepository(api),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<AppSettings>.value(value: settings),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    expect(find.text('管理你的使用偏好。'), findsOneWidget);
    expect(find.text('HomeMind 用户'), findsOneWidget);
    expect(find.text('深色模式'), findsOneWidget);
    expect(find.text('退出登录'), findsOneWidget);
    expect(find.text('我的专家'), findsNothing);
    expect(find.text('连接服务'), findsNothing);
  });
}

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
