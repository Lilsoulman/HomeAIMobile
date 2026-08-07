// B20×B21 选择专家弹窗：scope=all 拉取基础 + 本人自建，按来源分组展示
// （契约 §8.1：选择专家时以 scope=all 分组展示基础/自建来源）。

import 'package:flutter/material.dart';

import '../experts/domain.dart';
import '../experts/expert_repository.dart';

/// 展示专家选择弹窗；返回选中的 [Expert]；取消/跳过返回 null。
class ExpertPickerDialog extends StatefulWidget {
  const ExpertPickerDialog({super.key, required this.repository});

  final ExpertRepository repository;

  @override
  State<ExpertPickerDialog> createState() => _ExpertPickerDialogState();
}

class _ExpertPickerDialogState extends State<ExpertPickerDialog> {
  late Future<List<Expert>> _experts;

  @override
  void initState() {
    super.initState();
    _experts = widget.repository.listExperts(scope: 'all');
  }

  void _reload() => setState(() {
    _experts = widget.repository.listExperts(scope: 'all');
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择专家'),
      content: SizedBox(
        width: 360,
        height: 420,
        child: FutureBuilder<List<Expert>>(
          future: _experts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('专家列表加载失败。'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              );
            }
            final experts = snapshot.data ?? const <Expert>[];
            if (experts.isEmpty) {
              return const Center(child: Text('暂无可用专家。'));
            }
            final basics = experts
                .where((item) => item.source == ExpertSource.basic)
                .toList();
            final mine = experts
                .where((item) => item.source == ExpertSource.mine)
                .toList();
            return ListView(
              children: [
                if (basics.isNotEmpty) ...[
                  _sectionLabel('基础专家'),
                  ...basics.map((expert) => _tile(expert, tag: '基础')),
                ],
                if (mine.isNotEmpty) ...[
                  _sectionLabel('我的专家'),
                  ...mine.map((expert) => _tile(expert, tag: '我的')),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('暂不选择'),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _tile(Expert expert, {required String tag}) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Chip(
      label: Text(tag),
      visualDensity: VisualDensity.compact,
      labelStyle: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(fontSize: 11),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    title: Text(expert.name),
    subtitle: Text(expert.category),
    onTap: () => Navigator.pop(context, expert),
  );
}
