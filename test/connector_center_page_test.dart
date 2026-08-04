import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/connector/connector_repository.dart';
import 'package:nexus_mind_mobile/features/connector/local_connector_repository.dart';
import 'package:nexus_mind_mobile/pages/connector_center_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('connector center distinguishes each connection state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      Provider<ConnectorRepository>.value(
        value: LocalConnectorRepository(),
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
    expect(
      find.text('管理家庭服务的数据访问与连接状态。凭据不会显示在这里。'),
      findsOneWidget,
    );
  });
}
