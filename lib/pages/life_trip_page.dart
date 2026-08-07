// P5c 行程规划页（B17，Intent: plan + calendar_create_event L1 确认与幂等提交）。
// 确认前展示影响范围（N 个动作 → N 个日历事件，标题 {目的地} 行程 D{n}）；
// 提交中禁用按钮并使用新的幂等键；runId 缺失时禁用确认（契约未提供的安全降级）；
// 不渲染提示或思考链。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/api/api_exception.dart';
import '../core/ui/nexus_theme.dart';
import '../features/life/dto.dart';
import '../features/life/life_expert_repository.dart';
import '../widgets/risk_badge.dart';

class LifeTripPage extends StatefulWidget {
  const LifeTripPage({super.key});

  @override
  State<LifeTripPage> createState() => _LifeTripPageState();
}

class _LifeTripPageState extends State<LifeTripPage> {
  final _destination = TextEditingController();
  int _days = 1;
  bool _loading = false;
  bool _confirming = false;
  bool _confirmed = false;
  String? _error;
  LifePlanResultDto? _result;

  @override
  void dispose() {
    _destination.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final destination = _destination.text.trim();
    if (destination.isEmpty || destination.length > 64) {
      _showError('请填写目的地（1-64 字符）');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _confirmed = false;
    });
    try {
      final result = await context.read<LifeExpertRepository>().planTrip(
        destination: destination,
        days: _days,
        idempotencyKey: const Uuid().v4(),
      );
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendly(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final result = _result;
    if (result == null ||
        result.runId <= 0 ||
        result.actions.isEmpty ||
        _confirming) {
      return;
    }
    setState(() => _confirming = true);
    try {
      final repo = context.read<LifeExpertRepository>();
      for (final action in result.actions) {
        await repo.confirmPlanAction(
          runId: result.runId,
          actionId: action.id,
          idempotencyKey: const Uuid().v4(),
        );
      }
      if (!mounted) return;
      setState(() => _confirmed = true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('已同步到日历')));
    } catch (error) {
      if (!mounted) return;
      _showError('同步失败：${_friendly(error)}');
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    final actions = result?.actions ?? const <LifePlanActionDto>[];
    return Scaffold(
      appBar: AppBar(title: const Text('行程规划')),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: NexusLayout.pagePadding.copyWith(
            bottom: NexusLayout.bottomContentPadding,
          ),
          children: [
            NexusPageHeader(
              title: '行程规划',
              description: '输入目的地与天数，生成每日安排并同步到日历。',
            ),
            const SizedBox(height: NexusLayout.sectionGap),
            NexusSurface(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _destination,
                    decoration: const InputDecoration(
                      labelText: '目的地（1-64 字符）',
                      hintText: '例如：杭州',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: _days,
                    decoration: const InputDecoration(labelText: '天数'),
                    items: [
                      for (var days = 1; days <= 7; days++)
                        DropdownMenuItem(value: days, child: Text('$days 天')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _days = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _generate,
                      child: Text(_loading ? '生成中…' : '生成行程'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NexusLayout.sectionGap),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              NexusSurface(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _generate,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              )
            else if (result == null)
              const SizedBox.shrink()
            else if (actions.isEmpty)
              NexusSurface(
                padding: const EdgeInsets.all(20),
                child: const Text('没有生成日程安排，请调整目的地与天数后重试。'),
              )
            else ...[
              if (result.resultSummary != null &&
                  result.resultSummary!.isNotEmpty) ...[
                NexusSurface(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    result.resultSummary!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: NexusLayout.sectionGap),
              ],
              ...actions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: NexusLayout.itemGap),
                  child: _PlanActionCard(action: action),
                ),
              ),
              const SizedBox(height: NexusLayout.sectionGap),
              _ConfirmationCard(
                actionCount: actions.length,
                destination: _destination.text.trim(),
                confirming: _confirming,
                confirmed: _confirmed,
                enabled: result.runId > 0 && !_confirmed,
                onConfirm: _confirm,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanActionCard extends StatelessWidget {
  const _PlanActionCard({required this.action});

  final LifePlanActionDto action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_available_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action.title ?? '日程安排',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (action.riskLevel != null) RiskBadge(level: action.riskLevel!),
            ],
          ),
          if (action.description != null && action.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(action.description!),
          ],
        ],
      ),
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({
    required this.actionCount,
    required this.destination,
    required this.confirming,
    required this.confirmed,
    required this.enabled,
    required this.onConfirm,
  });

  final int actionCount;
  final String destination;
  final bool confirming;
  final bool confirmed;
  final bool enabled;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = destination.isEmpty
        ? '{目的地} 行程 D1-D$actionCount'
        : '$destination 行程 D1-D$actionCount';
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('确认同步', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '确认后将在日历创建 $actionCount 个事件（标题：$title），每个事件对应一天行程。',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: confirmed
                  ? null
                  : (enabled && !confirming ? onConfirm : null),
              child: Text(
                confirmed
                    ? '已同步到日历'
                    : confirming
                    ? '同步中…'
                    : '确认并同步日历',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _friendly(Object error) =>
    error is ApiException && error.msg.isNotEmpty ? error.msg : '$error';
