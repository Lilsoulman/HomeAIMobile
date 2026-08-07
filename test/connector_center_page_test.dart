// 连接中心：家庭连接五态 + P8 个人连接区块（授权发起/等待/完成/撤销/错误）。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/api/api_exception.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/connector/connector_repository.dart';
import 'package:nexus_mind_mobile/pages/connector_center_page.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/method_channel_url_launcher.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

final _now = DateTime.now();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('家庭连接', () {
    testWidgets('distinguishes each household connection state', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(tester, _StubConnectorRepo());

      expect(find.text('在线'), findsOneWidget);
      expect(find.text('授权中'), findsOneWidget);
      expect(find.text('发现中'), findsOneWidget);
      expect(find.text('未连接'), findsOneWidget);
      expect(find.text('需重试'), findsOneWidget);
      expect(find.text('管理你的个人连接与家庭服务的数据访问。凭据不会显示在这里。'), findsOneWidget);
      expect(find.text('家庭连接'), findsOneWidget);
      expect(find.text('家庭'), findsNWidgets(5));
    });
  });

  group('我的个人连接', () {
    testWidgets('renders each personal auth state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 3200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = _StubConnectorRepo()
        ..personal = [
          _summary(
            connectorId: 8,
            providerCode: 'notes',
            name: '个人笔记',
            authStatus: PersonalAuthStatus.connected,
            sessionStatus: AuthorizationSessionStatus.completed,
            expiresAt: _now,
          ),
          _summary(
            connectorId: 9,
            providerCode: 'cal',
            name: '个人日历',
            authStatus: PersonalAuthStatus.revoked,
            sessionStatus: AuthorizationSessionStatus.revoked,
          ),
          _summary(
            connectorId: 10,
            providerCode: 'weather',
            name: '个人天气',
            authStatus: PersonalAuthStatus.none,
            sessionStatus: AuthorizationSessionStatus.completed,
          ),
          _summary(
            connectorId: 11,
            providerCode: 'health',
            name: '健康追踪',
            authStatus: PersonalAuthStatus.authorizing,
            sessionStatus: AuthorizationSessionStatus.pending,
            expiresAt: _now.add(const Duration(minutes: 5)),
          ),
        ];
      await _pump(tester, repo);

      expect(find.text('我的个人连接'), findsOneWidget);
      expect(find.text('已连接'), findsOneWidget);
      expect(find.text('已撤销'), findsOneWidget);
      expect(find.text('未授权'), findsOneWidget);
      expect(find.text('等待完成授权'), findsOneWidget);
      expect(find.text('授权中'), findsOneWidget);
      expect(find.text('个人'), findsNWidgets(4));
    });

    testWidgets('shows empty state when no personal connections', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(tester, _StubConnectorRepo());

      expect(find.text('还没有个人连接。你可以在下方添加服务。'), findsOneWidget);
    });

    testWidgets(
      'full authorization flow opens browser and polls to completion',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repo = _StubConnectorRepo();
        final launcher = _FakeUrlLauncher();
        UrlLauncherPlatform.instance = launcher;
        addTearDown(_restoreUrlLauncher);

        await _pump(tester, repo);

        // 可添加的服务中点击「连接」→ 创建会话并打开浏览器。
        await tester.tap(find.byTooltip('连接笔记服务'));
        await tester.pump();
        await tester.pump();

        expect(repo.createdProviderCode, 'notes');
        expect(launcher.launchedUrls, hasLength(1));
        expect(launcher.launchedUrls.single, contains('/authorize?state='));

        // 创建后汇总立即出现 pending → 等待完成授权。
        await tester.pump();
        expect(find.text('等待完成授权'), findsOneWidget);

        // 轮询：首个 tick 仍 pending，第二个 tick 翻转 completed。
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(find.text('等待完成授权'), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(find.text('已连接'), findsOneWidget);
        expect(find.text('等待完成授权'), findsNothing);

        // 无残留 Timer。
        expect(repo.fetchCount, greaterThanOrEqualTo(2));
      },
    );

    testWidgets('revoke asks confirmation then revokes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = _StubConnectorRepo()
        ..personal = [
          _summary(
            connectorId: 8,
            providerCode: 'notes',
            name: '个人笔记',
            authStatus: PersonalAuthStatus.connected,
            sessionStatus: AuthorizationSessionStatus.completed,
            expiresAt: _now,
          ),
        ];
      await _pump(tester, repo);

      // 个人卡的主按钮是 OutlinedButton「断开」，家庭卡的「断开」是 TextButton。
      await tester.tap(find.widgetWithText(OutlinedButton, '断开'));
      await tester.pumpAndSettle();
      expect(find.text('撤销"个人笔记"'), findsOneWidget);

      await tester.tap(find.text('撤销'));
      await tester.pumpAndSettle();

      expect(repo.revokedSessionId, 101);
      expect(find.text('已撤销'), findsOneWidget);
      expect(find.text('已连接'), findsNothing);
    });

    testWidgets('creation failure shows error and does not poll', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = _StubConnectorRepo()..failCreate = true;
      await _pump(tester, repo);

      await tester.tap(find.byTooltip('连接笔记服务'));
      await tester.pump();
      await tester.pump();

      expect(find.text('回调地址不在白名单'), findsOneWidget);
      expect(repo.fetchCount, 0);
      expect(find.text('等待完成授权'), findsNothing);
    });

    testWidgets(
      'expired pending session offers re-authorize instead of waiting',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repo = _StubConnectorRepo()
          ..personal = [
            _summary(
              connectorId: 11,
              providerCode: 'notes',
              name: '个人笔记',
              authStatus: PersonalAuthStatus.none,
              sessionStatus: AuthorizationSessionStatus.pending,
              expiresAt: _now.subtract(const Duration(minutes: 1)),
            ),
          ];
        await _pump(tester, repo);

        expect(find.text('授权已过期'), findsOneWidget);
        expect(find.text('重新授权'), findsOneWidget);
        expect(find.text('等待完成授权'), findsNothing);
      },
    );
  });
}

Future<void> _pump(WidgetTester tester, _StubConnectorRepo repo) async {
  await tester.pumpWidget(
    Provider<ConnectorRepository>.value(
      value: repo,
      child: MaterialApp(
        theme: NexusTheme.light(NexusPalette.aiAccent),
        home: const ConnectorCenterPage(),
      ),
    ),
  );
  await tester.pump();
}

void _restoreUrlLauncher() {
  UrlLauncherPlatform.instance = MethodChannelUrlLauncher();
}

PersonalConnectionSummaryDto _summary({
  required int connectorId,
  required String providerCode,
  required String name,
  required PersonalAuthStatus authStatus,
  required AuthorizationSessionStatus sessionStatus,
  DateTime? expiresAt,
}) => PersonalConnectionSummaryDto(
  connectorId: connectorId,
  providerId: connectorId,
  providerCode: providerCode,
  providerName: name,
  name: name,
  status: ConnectorConnectionStatus.connected,
  authStatus: authStatus,
  lastSyncAt: null,
  lastHealthAt: null,
  lastSessionId: 101,
  lastSessionStatus: sessionStatus,
  lastSessionExpiresAt: expiresAt,
);

class _FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final List<String> launchedUrls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }
}

class _StubConnectorRepo implements ConnectorRepository {
  List<PersonalConnectionSummaryDto> personal = [];
  bool failCreate = false;
  String? createdProviderCode;
  int fetchCount = 0;
  int? revokedSessionId;

  @override
  Future<List<ConnectorProviderDto>> listProviders() async => [
    ConnectorProviderDto(
      id: 1,
      code: 'ha',
      name: 'Home Assistant',
      connectorType: 'smart_home',
      description: '',
    ),
    ConnectorProviderDto(
      id: 6,
      code: 'notes',
      name: '笔记服务',
      connectorType: 'notes',
      description: '',
    ),
  ];

  @override
  Future<List<ConnectorDto>> listConnectors() async => [
    ConnectorDto(
      id: 1,
      providerId: 1,
      providerCode: 'ha',
      providerName: 'Home Assistant',
      name: 'Home Assistant',
      status: ConnectorConnectionStatus.connected,
      createdAt: _now,
      updatedAt: _now,
    ),
    ConnectorDto(
      id: 2,
      providerId: 2,
      providerCode: 'cal',
      providerName: '家庭日历',
      name: '家庭日历',
      status: ConnectorConnectionStatus.authorizing,
      createdAt: _now,
      updatedAt: _now,
    ),
    ConnectorDto(
      id: 3,
      providerId: 3,
      providerCode: 'weather',
      providerName: '天气服务',
      name: '天气服务',
      status: ConnectorConnectionStatus.discovering,
      createdAt: _now,
      updatedAt: _now,
    ),
    ConnectorDto(
      id: 4,
      providerId: 4,
      providerCode: 'device',
      providerName: '家庭设备',
      name: '家庭设备',
      status: ConnectorConnectionStatus.disconnected,
      createdAt: _now,
      updatedAt: _now,
    ),
    ConnectorDto(
      id: 5,
      providerId: 5,
      providerCode: 'health',
      providerName: '健康日历',
      name: '健康日历',
      status: ConnectorConnectionStatus.failed,
      createdAt: _now,
      updatedAt: _now,
    ),
  ];

  @override
  Future<ConnectorDto> beginAuthorization(String providerKey) async =>
      ConnectorDto(
        id: 99,
        providerId: 99,
        providerCode: providerKey,
        providerName: providerKey,
        name: providerKey,
        status: ConnectorConnectionStatus.authorizing,
        createdAt: _now,
        updatedAt: _now,
      );

  @override
  Future<ConnectorDto> retry(String connectorId) async => ConnectorDto(
    id: int.parse(connectorId),
    providerId: 1,
    providerCode: 'ha',
    providerName: 'HA',
    name: 'HA',
    status: ConnectorConnectionStatus.connected,
    createdAt: _now,
    updatedAt: _now,
  );

  @override
  Future<ConnectorDto> discover(String connectorId) async => ConnectorDto(
    id: int.parse(connectorId),
    providerId: 1,
    providerCode: 'ha',
    providerName: 'HA',
    name: 'HA',
    status: ConnectorConnectionStatus.discovering,
    createdAt: _now,
    updatedAt: _now,
  );

  @override
  Future<ConnectorDto> disconnect(String connectorId) async => ConnectorDto(
    id: int.parse(connectorId),
    providerId: 1,
    providerCode: 'ha',
    providerName: 'HA',
    name: 'HA',
    status: ConnectorConnectionStatus.disconnected,
    createdAt: _now,
    updatedAt: _now,
  );

  @override
  Future<AuthorizationSessionDto> createAuthorizationSession(
    String providerCode,
  ) async {
    if (failCreate) throw ApiException(422, '回调地址不在白名单');
    createdProviderCode = providerCode;
    personal = [
      _summary(
        connectorId: 8,
        providerCode: providerCode,
        name: '个人笔记',
        authStatus: PersonalAuthStatus.authorizing,
        sessionStatus: AuthorizationSessionStatus.pending,
        expiresAt: _now.add(const Duration(minutes: 10)),
      ),
    ];
    return AuthorizationSessionDto(
      sessionId: 101,
      providerCode: providerCode,
      providerName: '笔记服务',
      status: AuthorizationSessionStatus.pending,
      expiresAt: _now.add(const Duration(minutes: 10)),
      authorizationUrl:
          'https://auth.example.com/api/v1/connector-providers/'
          '$providerCode/authorize?state=abc',
    );
  }

  @override
  Future<AuthorizationSessionDto> fetchAuthorizationSession(
    int sessionId,
  ) async {
    fetchCount++;
    final completed = fetchCount >= 2;
    if (completed) {
      personal = [
        _summary(
          connectorId: 8,
          providerCode: createdProviderCode ?? 'notes',
          name: '个人笔记',
          authStatus: PersonalAuthStatus.connected,
          sessionStatus: AuthorizationSessionStatus.completed,
          expiresAt: _now,
        ),
      ];
    }
    return AuthorizationSessionDto(
      sessionId: sessionId,
      providerCode: createdProviderCode ?? 'notes',
      providerName: '笔记服务',
      status: completed
          ? AuthorizationSessionStatus.completed
          : AuthorizationSessionStatus.pending,
      expiresAt: _now.add(const Duration(minutes: 10)),
    );
  }

  @override
  Future<void> revokeAuthorization(int sessionId) async {
    revokedSessionId = sessionId;
    personal = [
      _summary(
        connectorId: 8,
        providerCode: 'notes',
        name: '个人笔记',
        authStatus: PersonalAuthStatus.revoked,
        sessionStatus: AuthorizationSessionStatus.revoked,
        expiresAt: _now,
      ),
    ];
  }

  @override
  Future<List<PersonalConnectionSummaryDto>>
  listMyPersonalConnections() async => personal;
}
