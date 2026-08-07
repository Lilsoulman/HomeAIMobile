// P5 公共管家动态时间线条目：分类图标 + 标题 + 摘要 + 时间，
// 可选风险徽标与点击回调。自 P3 dashboard_page 的私有 _ActivityTile 提取。

import 'package:flutter/material.dart';

import '../core/ui/nexus_theme.dart';
import 'risk_badge.dart';

class StewardTimelineTile extends StatelessWidget {
  const StewardTimelineTile({
    super.key,
    required this.category,
    required this.title,
    this.summary,
    required this.time,
    this.riskLevel,
    this.onTap,
  });

  final String category;
  final String title;
  final String? summary;
  final DateTime time;
  final String? riskLevel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NexusSurface(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _activityIcon(category),
                  size: 19,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (riskLevel != null) ...[
                          const SizedBox(width: 8),
                          RiskBadge(level: riskLevel!),
                        ],
                      ],
                    ),
                    if (summary != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        summary!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(time),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _activityIcon(String category) => switch (category) {
  'automation' => Icons.bolt_outlined,
  'confirmation' => Icons.verified_user_outlined,
  'expert' => Icons.psychology_outlined,
  'life' => Icons.restaurant_outlined,
  _ => Icons.auto_awesome_outlined,
};

String _formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
