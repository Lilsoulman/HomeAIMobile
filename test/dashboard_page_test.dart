import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/experts/expert_repository.dart';
import 'package:nexus_mind_mobile/experts/mock_expert_repository.dart';
import 'package:nexus_mind_mobile/features/auth/auth_controller.dart';
import 'package:nexus_mind_mobile/features/auth/local_auth_repository.dart';
import 'package:nexus_mind_mobile/features/calendar/calendar_repository.dart';
import 'package:nexus_mind_mobile/features/calendar/local_calendar_repository.dart';
import 'package:nexus_mind_mobile/features/smart_home/dto.dart';
import 'package:nexus_mind_mobile/features/smart_home/local_smart_home_repository.dart';
import 'package:nexus_mind_mobile/features/smart_home/smart_home_repository.dart';
import 'package:nexus_mind_mobile/features/todo/local_todo_repository.dart';
import 'package:nexus_mind_mobile/features/todo/todo_repository.dart';
import 'package:nexus_mind_mobile/pages/dashboard_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'keeps plan data available when the home card fails and retries it independently',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final smartHome = _RetryingSmartHomeRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(
              value: await _signedInAuth(),
            ),
            Provider<TodoRepository>.value(value: LocalTodoRepository()),
            Provider<CalendarRepository>.value(
              value: LocalCalendarRepository(),
            ),
            Provider<SmartHomeRepository>.value(value: smartHome),
            Provider<ExpertRepository>.value(value: MockExpertRepository()),
          ],
          child: MaterialApp(
            theme: NexusTheme.light(NexusPalette.aiAccent),
            home: const NexusHomePage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('家庭状态暂时无法加载'), findsOneWidget);
      expect(find.text('今日计划'), findsOneWidget);
      expect(find.textContaining('更新于'), findsOneWidget);

      smartHome.shouldFail = false;
      await tester.tap(find.byTooltip('重试').first);
      await tester.pump();
      await tester.pump();

      expect(find.text('家庭状态暂时无法加载'), findsNothing);
      expect(find.textContaining('更新于'), findsNWidgets(2));
    },
  );
}

Future<AuthController> _signedInAuth() async {
  SharedPreferences.setMockInitialValues({});
  final env = await EnvConfig.init();
  final storage = _MemoryTokens();
  final repository = LocalAuthRepository();
  final auth = AuthController(
    apiClient: ApiClient(tokenStorage: storage, env: env),
    tokenStorage: storage,
    repository: repository,
  );
  await auth.register(
    phone: '13800138000',
    password: 'offline-password',
    displayName: 'Dashboard tester',
  );
  return auth;
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

class _RetryingSmartHomeRepository implements SmartHomeRepository {
  final LocalSmartHomeRepository _delegate = LocalSmartHomeRepository();
  bool shouldFail = true;

  void _throwWhenFailing() {
    if (shouldFail) throw StateError('home unavailable');
  }

  @override
  Future<List<SmartHomeDeviceDto>> listDevices({String? spaceId}) async {
    _throwWhenFailing();
    return _delegate.listDevices(spaceId: spaceId);
  }

  @override
  Future<List<SmartSceneDto>> listScenes() async {
    _throwWhenFailing();
    return _delegate.listScenes();
  }

  @override
  Future<List<SmartHomeSpaceDto>> listSpaces() async {
    _throwWhenFailing();
    return _delegate.listSpaces();
  }

  @override
  Future<SmartSceneDto> runScene(String key) => _delegate.runScene(key);
}
