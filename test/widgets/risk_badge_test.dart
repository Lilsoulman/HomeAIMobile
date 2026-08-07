// P5 公共风险徽标组件用例：L1/L2/L3/未知等级渲染与语义色。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/widgets/risk_badge.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: NexusTheme.light(NexusPalette.aiAccent),
    home: Scaffold(body: child),
  );

  testWidgets('renders L1/L2/L3 labels', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Column(
          children: [
            RiskBadge(level: 'L1'),
            RiskBadge(level: 'L2'),
            RiskBadge(level: 'L3'),
          ],
        ),
      ),
    );
    expect(find.text('L1'), findsOneWidget);
    expect(find.text('L2'), findsOneWidget);
    expect(find.text('L3'), findsOneWidget);
  });

  testWidgets('uses semantic colors from the palette', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Column(
          children: [
            RiskBadge(level: 'L1'),
            RiskBadge(level: 'L2'),
            RiskBadge(level: 'L3'),
          ],
        ),
      ),
    );
    final l1 = tester.widget<Text>(find.text('L1'));
    final l2 = tester.widget<Text>(find.text('L2'));
    final l3 = tester.widget<Text>(find.text('L3'));
    expect(l1.style?.color, NexusPalette.riskL1);
    expect(l2.style?.color, NexusPalette.riskL2);
    expect(l3.style?.color, NexusPalette.riskL3);
  });

  testWidgets('renders unknown level with neutral color', (tester) async {
    await tester.pumpWidget(wrap(const RiskBadge(level: 'X')));
    expect(find.text('X'), findsOneWidget);
  });
}
