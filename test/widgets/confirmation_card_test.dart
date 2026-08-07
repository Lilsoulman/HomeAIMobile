// P5 公共确认卡片组件用例：L1/L2/L3 按钮形态、已解决状态只读、回调触发。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_mind_mobile/core/ui/nexus_theme.dart';
import 'package:nexus_mind_mobile/features/steward/dto.dart';
import 'package:nexus_mind_mobile/widgets/confirmation_card.dart';

ConfirmationItemDto _item({
  int id = 1,
  String riskLevel = 'L1',
  String status = 'pending',
  String? impactSummary = '影响范围：客厅灯光',
}) => ConfirmationItemDto(
  id: id,
  riskLevel: riskLevel,
  title: '开阳台灯',
  description: null,
  impactSummary: impactSummary,
  suggestedAction: null,
  status: status,
  expiresAt: null,
  confirmedAt: null,
  deniedAt: null,
  expiredAt: null,
  updatedAt: DateTime.utc(2026, 8, 7, 10),
);

Widget wrap(ConfirmationCard card) => MaterialApp(
  theme: NexusTheme.light(NexusPalette.aiAccent),
  home: Scaffold(body: card),
);

void main() {
  testWidgets('L1 pending shows text confirm/deny buttons', (tester) async {
    await tester.pumpWidget(
      wrap(
        ConfirmationCard(
          item: _item(riskLevel: 'L1'),
          busy: false,
          onConfirm: () {},
          onDeny: () {},
        ),
      ),
    );
    expect(find.text('L1'), findsOneWidget);
    expect(find.text('开阳台灯'), findsOneWidget);
    expect(find.text('影响范围：客厅灯光'), findsOneWidget);
    expect(find.text('确认'), findsOneWidget);
    expect(find.text('拒绝'), findsOneWidget);
  });

  testWidgets('L3 pending shows tonal confirm and outlined deny', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ConfirmationCard(
          item: _item(riskLevel: 'L3'),
          busy: false,
          onConfirm: () {},
          onDeny: () {},
        ),
      ),
    );
    expect(find.widgetWithText(FilledButton, '确认'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '拒绝'), findsOneWidget);
  });

  testWidgets('resolved item is read-only and shows status label', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ConfirmationCard(
          item: _item(riskLevel: 'L2', status: 'confirmed'),
          busy: false,
          onConfirm: () {},
          onDeny: () {},
        ),
      ),
    );
    expect(find.text('已确认'), findsOneWidget);
    expect(find.text('确认'), findsNothing);
    expect(find.text('拒绝'), findsNothing);
  });

  testWidgets('confirm callback fires on L1 confirm tap', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(
      wrap(
        ConfirmationCard(
          item: _item(),
          busy: false,
          onConfirm: () => confirmed = true,
          onDeny: () {},
        ),
      ),
    );
    await tester.tap(find.text('确认'));
    expect(confirmed, isTrue);
  });

  testWidgets('busy disables actions', (tester) async {
    await tester.pumpWidget(
      wrap(
        ConfirmationCard(
          item: _item(),
          busy: true,
          onConfirm: () {},
          onDeny: () {},
        ),
      ),
    );
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '确认'),
    );
    expect(button.onPressed, isNull);
  });
}
