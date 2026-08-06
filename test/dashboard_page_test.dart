// P3 管家工作台与确认中心：Dashboard 页用例。
// 结构为 待确认 → 管家动态 → 家庭概览 → 快捷入口；
// 聚合视图各模块独立降级，重试互不影响。

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_client.dart';
import 'package:nexus_mind_mobile/core/env/env_config.dart';
import 'package:nexus_mind_mobile/core/storage/token_storage.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/auth/auth_controller.dart';
import 'package:nexus_mind_mobile/features/auth/http_auth_repository.dart';
import 'package:nexus_mind_mobile/features/dashboard/dashboard_repository.dart';
import 'package:nexus_mind_mobile/features/dashboard/dto.dart';
import 'package:nexus_mind_mobile/features/steward/dto.dart';
import 'package:nexus_mind_mobile/features/steward/steward_repository.dart';
import 'package:nexus_mind_mobile/pages/dashboard_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime.now();

void main() {
  testWidgets(
    'dashboard renders confirmations, steward activity, family overview and quick entries',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final env = await EnvConfig.init(
        fileValues: const {'API_BASE_URL': 'https://api.example.com'},
      );
      final dashboard = _StubDashboardRepo(value: _fullDashboard());
      final steward = _StubStewardRepo(
        items: [
          ConfirmationItemDto(
            id: 1,
            riskLevel: 'L1',
            title: '确认自动化规则',
            impactSummary: '将开启离家模式',
            status: 'pending',
            updatedAt: _now,
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(
              value: await _signedInAuth(env),
            ),
            Provider<DashboardRepository>.value(value: dashboard),
            Provider<StewardRepository>.value(value: steward),
          ],
          child: MaterialApp(
            theme: NexusTheme.light(NexusPalette.aiAccent),
            home: const NexusHomePage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // 待确认
      expect(find.text('待确认'), findsWidgets);
      expect(find.text('确认自动化规则'), findsOneWidget);
      // 管家动态
      expect(find.text('管家动态'), findsOneWidget);
      expect(find.text('离家模式已执行'), findsOneWidget);
      // 家庭概览
      expect(find.text('家庭状态'), findsOneWidget);
      expect(find.text('2 / 3 台设备在线'), findsOneWidget);
      expect(find.text('智能场景'), findsOneWidget);
      // 快捷入口
      expect(find.text('快捷入口'), findsOneWidget);
      expect(find.text('今日计划'), findsOneWidget);
      expect(find.text('AI 专家'), findsOneWidget);
      expect(find.text('家庭'), findsOneWidget);
    },
  );

  testWidgets('dashboard modules degrade independently and retry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferences.setMockInitialValues({});
    final env = await EnvConfig.init(
      fileValues: const {'API_BASE_URL': 'https://api.example.com'},
    );
    // 家庭模块不可用，管家动态正常。
    final dashboard = _StubDashboardRepo(
      value: _fullDashboard(
        home: const DashboardModuleDto(status: 'unavailable'),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(
            value: await _signedInAuth(env),
          ),
          Provider<DashboardRepository>.value(value: dashboard),
          Provider<StewardRepository>.value(value: _StubStewardRepo(items: [])),
        ],
        child: MaterialApp(
          theme: NexusTheme.light(NexusPalette.aiAccent),
          home: const NexusHomePage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('家庭状态暂时无法加载'), findsOneWidget);
    expect(find.text('管家动态'), findsOneWidget);
    expect(find.text('快捷入口'), findsOneWidget);

    // 单独重试家庭模块：聚合数据恢复后仅家庭区块更新。
    dashboard.value = _fullDashboard();
    await tester.tap(find.byTooltip('重试').first);
    await tester.pump();
    await tester.pump();

    expect(find.text('家庭状态暂时无法加载'), findsNothing);
    expect(find.text('2 / 3 台设备在线'), findsOneWidget);
    expect(find.text('管家动态'), findsOneWidget);
  });
}

DashboardDto _fullDashboard({DashboardModuleDto<DashboardHomeDto>? home}) =>
    DashboardDto(
      generatedAt: _now,
      partialFailure: false,
      home:
          home ??
          DashboardModuleDto(
            status: 'available',
            updatedAt: _now,
            data: DashboardHomeDto(
              spaceCount: 2,
              deviceCount: 3,
              onlineDeviceCount: 2,
              offlineDeviceCount: 1,
              spaces: [
                DashboardSpaceSummaryDto(
                  id: 1,
                  name: '客厅',
                  spaceType: 'living_room',
                  summary: '25°C',
                  deviceCount: 2,
                  onlineDeviceCount: 2,
                  offlineDeviceCount: 0,
                  updatedAt: _now,
                ),
              ],
            ),
          ),
      pendingConfirmations: DashboardModuleDto(
        status: 'available',
        data: [
          DashboardConfirmationDto(
            id: 1,
            riskLevel: 'L1',
            title: '确认自动化规则',
            status: 'pending',
            updatedAt: _now,
          ),
        ],
      ),
      stewardActivities: DashboardModuleDto(
        status: 'available',
        data: [
          DashboardStewardActivityDto(
            id: 1,
            category: 'automation',
            title: '离家模式已执行',
            riskLevel: 'L1',
            status: 'succeeded',
            createdAt: _now,
          ),
        ],
      ),
      scenes: DashboardModuleDto(
        status: 'available',
        data: [
          DashboardSceneDto(
            id: 1,
            key: 'sleep',
            name: '睡眠',
            status: 'enabled',
            updatedAt: _now,
          ),
        ],
      ),
      todos: DashboardModuleDto(status: 'available', data: const []),
      calendar: DashboardModuleDto(status: 'available', data: const []),
      suggestion: const DashboardModuleDto(status: 'unavailable'),
    );

Future<AuthController> _signedInAuth(EnvConfig env) async {
  final storage = _MemTokens();
  final api = ApiClient(tokenStorage: storage, env: env);
  api.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'Code': 0,
              'Msg': 'ok',
              'Data': {'Id': 1, 'DisplayName': 'Tester'},
            },
          ),
        );
      },
    ),
  );
  final auth = AuthController(
    apiClient: api,
    tokenStorage: storage,
    repository: HttpAuthRepository(api),
  );
  storage.access = 'a';
  storage.refresh = 'r';
  api.setAccessToken('a');
  return auth;
}

class _StubDashboardRepo implements DashboardRepository {
  _StubDashboardRepo({required this.value});

  DashboardDto value;

  @override
  Future<DashboardDto> list() async => value;
}

class _StubStewardRepo implements StewardRepository {
  _StubStewardRepo({required this.items});

  final List<ConfirmationItemDto> items;

  @override
  Future<List<ConfirmationItemDto>> listConfirmations({
    String? riskLevel,
    String? status,
  }) async => items;

  @override
  Future<ConfirmationBatchResultDto> batchConfirm(
    List<int> confirmationIds, {
    required String idempotencyKey,
  }) async => ConfirmationBatchResultDto(confirmedCount: 0, items: const []);

  @override
  Future<ConfirmationItemDto> confirm(
    int id, {
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<ConfirmationItemDto> deny(int id, {required String reason}) =>
      throw UnimplementedError();

  @override
  Future<StewardActivityPageDto> listActivities({
    int limit = 20,
    String? cursor,
  }) => throw UnimplementedError();

  @override
  Future<StewardActivityDto> getActivity(int id) => throw UnimplementedError();

  @override
  Future<StewardActivityDto> undoActivity(int id) => throw UnimplementedError();
}

class _MemTokens implements TokenStorage {
  String? access, refresh;
  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }

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
}
