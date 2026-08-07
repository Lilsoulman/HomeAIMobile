// P5 公共风险徽标：L1 低风险（绿）/ L2 建议确认（橙）/ L3 需你决定（红）。
// 颜色来自 NexusPalette 风险语义 token，浅深色模式共用。

import 'package:flutter/material.dart';

import '../core/ui/nexus_theme.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      'L1' => NexusPalette.riskL1,
      'L2' => NexusPalette.riskL2,
      'L3' => NexusPalette.riskL3,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
