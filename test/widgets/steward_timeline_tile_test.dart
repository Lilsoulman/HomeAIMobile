// P5 公共管家动态时间线条目组件用例：标题/摘要/时间/风险徽标/点击回调。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/widgets/steward_timeline_tile.dart';

void main() {
  Widget wrap(Widget tile) => MaterialApp(
    theme: NexusTheme.light(NexusPalette.homeAccent),
    home: Scaffold(body: tile),
  );

  testWidgets('renders title, summary, time and risk badge', (tester) async {
    await tester.pumpWidget(
      wrap(
        StewardTimelineTile(
          category: 'confirmation',
          title: '已确认：调低热水器温度',
          summary: '客厅热水器',
          time: DateTime(2026, 8, 7, 10, 30),
          riskLevel: 'L2',
        ),
      ),
    );
    expect(find.text('已确认：调低热水器温度'), findsOneWidget);
    expect(find.text('客厅热水器'), findsOneWidget);
    expect(find.text('10:30'), findsOneWidget);
    expect(find.text('L2'), findsOneWidget);
  });

  testWidgets('onTap fires', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        StewardTimelineTile(
          category: 'scene',
          title: '动态标题',
          time: DateTime(2026, 8, 7, 10),
          onTap: () => tapped = true,
        ),
      ),
    );
    await tester.tap(find.text('动态标题'));
    expect(tapped, isTrue);
  });
}
