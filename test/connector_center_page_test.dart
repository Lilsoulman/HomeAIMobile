import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/connector/connector_repository.dart';
import 'package:nexus_mind_mobile/pages/connector_center_page.dart';
import 'package:provider/provider.dart';

final _now = DateTime.now();

void main() {
  testWidgets('connector center distinguishes each connection state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      Provider<ConnectorRepository>.value(
        value: _StubConnectorRepo(),
        child: MaterialApp(
          theme: NexusTheme.light(NexusPalette.aiAccent),
          home: const ConnectorCenterPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('在线'), findsOneWidget);
    expect(find.text('授权中'), findsOneWidget);
    expect(find.text('发现中'), findsOneWidget);
    expect(find.text('未连接'), findsOneWidget);
    expect(find.text('需重试'), findsOneWidget);
    expect(find.text('管理家庭服务的数据访问与连接状态。凭据不会显示在这里。'), findsOneWidget);
  });
}

class _StubConnectorRepo implements ConnectorRepository {
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
      name: '家庭笔记',
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
}
