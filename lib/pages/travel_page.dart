// 周末出行推荐页面：推荐卡片 + 三选一反馈 + 推送设置 + 最新推荐语。

import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/ui/nexus_theme.dart';
import '../experts/expert_repository.dart';
import '../features/automation/automation_repository.dart';
import '../features/expert/dto.dart';
import '../features/expert/expert_run_repository.dart';
import '../features/travel/travel_repository.dart';

class TravelPage extends StatefulWidget {
  const TravelPage({
    super.key,
    required this.travelRepository,
    required this.expertRepository,
    required this.runRepository,
    required this.automationRepository,
  });

  final TravelRepository travelRepository;
  final ExpertRepository expertRepository;
  final ExpertRunRepository runRepository;
  final AutomationRepository automationRepository;

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  static const _expertCode = 'travel-recommender';

  List<TravelRecommendationDto> _items = const [];
  bool _loading = true;
  String? _error;
  AutomationRuleDto? _pushRule;
  bool _savingPush = false;
  TimeOfDay _pushTime = const TimeOfDay(hour: 9, minute: 0);
  final Set<int> _weekdays = {5, 6, 7};
  String? _latestReason;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _reload();
    await _loadPushRule();
    await _loadLatestReason();
  }

  Future<void> _reload() async {
    try {
      final items = await widget.travelRepository.getRecommendations();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '推荐加载失败，请稍后重试。';
        });
      }
    }
  }

  Future<void> _loadPushRule() async {
    try {
      final rules = await widget.automationRepository.list();
      final rule = rules.where((r) => r.name == '周末出行推荐推送').firstOrNull;
      if (!mounted) return;
      setState(() {
        _pushRule = rule;
        if (rule != null) {
          final time = rule.triggerConfig['time']?.toString() ?? '';
          final parts = time.split(':');
          if (parts.length == 2) {
            _pushTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 9,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
          final days = rule.triggerConfig['daysOfWeek'];
          if (days is List) {
            _weekdays
              ..clear()
              ..addAll(days.whereType<num>().map((d) => d.toInt()));
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _loadLatestReason() async {
    try {
      final runs = await widget.runRepository.listRuns(limit: 5);
      for (final run in runs) {
        if (run.status != ExpertRunStatus.completed) continue;
        final parsed = _reasonOf(run);
        if (parsed != null) {
          if (mounted) setState(() => _latestReason = parsed);
          return;
        }
      }
    } catch (_) {}
  }

  String? _reasonOf(ExpertRunDto run) {
    final result = run.result;
    if (result == null || result.isEmpty) return null;
    try {
      final decoded = jsonDecode(result);
      if (decoded is Map<String, dynamic>) {
        final title = decoded['title']?.toString() ?? '';
        final reason = decoded['reason']?.toString() ?? '';
        final tip = decoded['tip']?.toString() ?? '';
        if (title.isNotEmpty)
          return '《$title》 $reason ${tip.isNotEmpty ? '小贴士：$tip' : ''}';
      }
    } catch (_) {}
    return null;
  }

  Future<void> _submitFeedback(int attractionId, String choice) async {
    try {
      await widget.travelRepository.submitFeedback(attractionId, choice);
      await _reload();
    } catch (_) {
      _toast('反馈提交失败，请稍后重试。');
    }
  }

  Future<void> _savePushRule() async {
    if (_savingPush) return;
    setState(() => _savingPush = true);
    final trigger = <String, dynamic>{
      'kind': 'fixed_time',
      'time':
          '${_pushTime.hour.toString().padLeft(2, '0')}:${_pushTime.minute.toString().padLeft(2, '0')}',
      'daysOfWeek': _weekdays.toList()..sort(),
      'timeZone': 'Asia/Shanghai',
    };
    try {
      if (_pushRule == null) {
        await widget.automationRepository.create(
          name: '周末出行推荐推送',
          trigger: trigger,
          actions: [
            {'type': 'agent_run', 'expertCode': _expertCode},
          ],
        );
      } else {
        await widget.automationRepository.patch(
          id: _pushRule!.id,
          rowVersion: _pushRule!.rowVersion,
          trigger: trigger,
        );
      }
      await _loadPushRule();
      await _loadLatestReason();
      _toast('推送设置已保存');
    } catch (_) {
      _toast('保存失败，请稍后重试。');
    } finally {
      if (mounted) setState(() => _savingPush = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: NexusLayout.pagePadding.copyWith(
              bottom: NexusLayout.bottomContentPadding,
            ),
            children: [
              NexusPageHeader(title: '周末出行', description: '按你们的偏好，推荐周末自然好去处。'),
              const SizedBox(height: NexusLayout.sectionGap),
              if (_latestReason != null) _ReasonBanner(text: _latestReason!),
              const SizedBox(height: NexusLayout.sectionGap),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                NexusSurface(
                  padding: const EdgeInsets.all(20),
                  child: Text(_error!),
                )
              else if (_items.isEmpty)
                NexusSurface(
                  padding: const EdgeInsets.all(20),
                  child: const Text('暂无可推荐的目的地。'),
                )
              else
                ..._items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: NexusLayout.itemGap),
                    child: _RecommendationCard(
                      item: item,
                      onFeedback: (choice) => _submitFeedback(item.id, choice),
                    ),
                  ),
                ),
              const SizedBox(height: NexusLayout.sectionGap),
              _pushSettingsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pushSettingsCard() {
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('推送设置', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '定时推送周末出行推荐，时间与星期由你配置。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_rounded),
            title: Text('推送时间：${_pushTime.format(context)}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _pushTime,
              );
              if (picked != null && mounted) {
                setState(() => _pushTime = picked);
              }
            },
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final day in const [1, 2, 3, 4, 5, 6, 7])
                FilterChip(
                  label: Text('周${'一二三四五六日'[day - 1]}'),
                  selected: _weekdays.contains(day),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _weekdays.add(day);
                    } else {
                      _weekdays.remove(day);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: _savingPush ? null : _savePushRule,
              child: Text(_savingPush ? '保存中…' : '保存推送设置'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonBanner extends StatelessWidget {
  const _ReasonBanner({required this.text});

  final String text;

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
              Icon(Icons.campaign_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('最新推荐语', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item, required this.onFeedback});

  final TravelRecommendationDto item;
  final ValueChanged<String> onFeedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = <String>[
      item.category,
      '约 ${item.durationHours} 小时',
      '消费 ${item.costLevel}/5',
      if (item.weatherTag != null && item.weatherTag!.isNotEmpty)
        item.weatherTag!,
      ...item.tags,
    ];
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.name, style: theme.textTheme.titleLarge),
              ),
              Icon(Icons.landscape_outlined, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${item.city} · ${meta.join(' · ')}',
            style: theme.textTheme.bodySmall,
          ),
          if (item.reason != null && item.reason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(item.reason!),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => onFeedback('selected'),
                  child: const Text('选这个'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onFeedback('alternative'),
                  child: const Text('换一个'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: () => onFeedback('not_interested'),
                  child: const Text('不感兴趣'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
