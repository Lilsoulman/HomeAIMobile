// P5 公共确认卡片：展示待确认事项（标题、影响范围、风险等级、时间），
// L1 提供确认/拒绝文本按钮，L2/L3 提供逐项确认/拒绝按钮，已解决项只读。
// 自 P3 confirmation_section 的私有 _ConfirmationTile 提取，颜色走主题语义。

import 'package:flutter/material.dart';

import '../core/ui/nexus_theme.dart';
import '../features/steward/dto.dart';
import 'risk_badge.dart';

class ConfirmationCard extends StatelessWidget {
  const ConfirmationCard({
    super.key,
    required this.item,
    required this.busy,
    required this.onConfirm,
    required this.onDeny,
  });

  final ConfirmationItemDto item;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = item.status != 'pending';
    return NexusSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RiskBadge(level: item.riskLevel),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (item.impactSummary != null) ...[
            const SizedBox(height: 8),
            Text(
              item.impactSummary!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.update_rounded,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                _formatTime(item.updatedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (resolved)
                Text(
                  _resolvedLabel(item.status),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else if (item.riskLevel == 'L1') ...[
                TextButton(
                  onPressed: busy ? null : onConfirm,
                  child: const Text('确认'),
                ),
                TextButton(
                  onPressed: busy ? null : onDeny,
                  child: const Text('拒绝'),
                ),
              ] else ...[
                SizedBox(
                  width: 76,
                  child: FilledButton.tonal(
                    onPressed: busy ? null : onConfirm,
                    child: const Text('确认'),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 76,
                  child: OutlinedButton(
                    onPressed: busy ? null : onDeny,
                    child: const Text('拒绝'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _resolvedLabel(String status) => switch (status) {
    'confirmed' => '已确认',
    'denied' => '已拒绝',
    'expired' => '已过期',
    _ => status,
  };
}

String _formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
