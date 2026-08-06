// P3 管家工作台与确认中心：确认中心独立页面。
// 按风险（全部/L1/L2/L3）过滤待确认事项，交互复用 ConfirmationSection
// （L1 批量确认、L2/L3 逐项确认、重入恢复、局部失败）。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ui/nexus_theme.dart';
import '../features/steward/steward_repository.dart';
import '../widgets/confirmation_section.dart';

class ConfirmationCenterPage extends StatefulWidget {
  const ConfirmationCenterPage({super.key});

  @override
  State<ConfirmationCenterPage> createState() => _ConfirmationCenterPageState();
}

class _ConfirmationCenterPageState extends State<ConfirmationCenterPage> {
  String? _riskLevel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('确认中心')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: NexusLayout.pagePadding,
          children: [
            SegmentedButton<String?>(
              segments: const [
                ButtonSegment(value: null, label: Text('全部')),
                ButtonSegment(value: 'L1', label: Text('L1')),
                ButtonSegment(value: 'L2', label: Text('L2')),
                ButtonSegment(value: 'L3', label: Text('L3')),
              ],
              selected: {_riskLevel},
              onSelectionChanged: (value) =>
                  setState(() => _riskLevel = value.single),
            ),
            const SizedBox(height: NexusLayout.sectionGap),
            // key 变化强制重建，riskLevel 切换后重新拉取。
            ConfirmationSection(
              key: ValueKey(_riskLevel),
              repository: context.read<StewardRepository>(),
              riskLevel: _riskLevel,
            ),
          ],
        ),
      ),
    );
  }
}
