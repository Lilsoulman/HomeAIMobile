// 每日知识管家页面：最新知识卡片 + 历史列表 + 推送设置 + 添加知识条目。

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/ui/nexus_theme.dart';
import '../experts/domain.dart';
import '../experts/expert_repository.dart';
import '../features/automation/automation_repository.dart';
import '../features/expert/dto.dart';
import '../features/expert/expert_run_repository.dart';
import '../features/knowledge/knowledge_repository.dart';

class DailyKnowledgePage extends StatefulWidget {
  const DailyKnowledgePage({
    super.key,
    required this.expertRepository,
    required this.runRepository,
    required this.knowledgeRepository,
    required this.automationRepository,
  });

  final ExpertRepository expertRepository;
  final ExpertRunRepository runRepository;
  final KnowledgeRepository knowledgeRepository;
  final AutomationRepository automationRepository;

  @override
  State<DailyKnowledgePage> createState() => _DailyKnowledgePageState();
}

class _DailyKnowledgePageState extends State<DailyKnowledgePage> {
  static const _expertCode = 'daily-knowledge-steward';

  Expert? _knowledgeExpert;
  List<ExpertRunDto> _runs = const [];
  bool _loadingRuns = true;
  AutomationRuleDto? _pushRule;
  bool _savingPush = false;
  TimeOfDay _pushTime = const TimeOfDay(hour: 8, minute: 30);
  final Set<int> _weekdays = {1, 2, 3, 4, 5};
  String _category = 'general';
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _addingItem = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final experts = await widget.expertRepository.listExperts(
        query: _expertCode,
      );
      if (mounted) {
        setState(() => _knowledgeExpert = experts.isEmpty ? null : experts.first);
      }
    } catch (_) {}
    await _reloadRuns();
    await _loadPushRule();
  }

  Future<void> _reloadRuns() async {
    try {
      final runs = await widget.runRepository.listRuns(limit: 20);
      if (!mounted) return;
      setState(() {
        _runs = runs;
        _loadingRuns = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() {
        _loadingRuns = false;
        _error = '历史记录加载失败，请稍后重试。';
      });
    }
  }

  Future<void> _loadPushRule() async {
    try {
      final rules = await widget.automationRepository.list();
      final rule = rules.where((r) => r.name == '工作日早晨知识推送').firstOrNull;
      if (!mounted) return;
      setState(() {
        _pushRule = rule;
        if (rule != null) {
          final time = rule.triggerConfig['time']?.toString() ?? '';
          final parts = time.split(':');
          if (parts.length == 2) {
            _pushTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 8,
              minute: int.tryParse(parts[1]) ?? 30,
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
          name: '工作日早晨知识推送',
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
      _toast('推送时间已保存');
    } catch (_) {
      _toast('保存失败，请稍后重试。');
    } finally {
      if (mounted) setState(() => _savingPush = false);
    }
  }

  Future<void> _addKnowledgeItem() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty || _addingItem) {
      if (title.isEmpty || content.isEmpty) _toast('请填写标题和内容。');
      return;
    }
    setState(() => _addingItem = true);
    try {
      await widget.knowledgeRepository.create(
        category: _category,
        title: title,
        content: content,
      );
      _titleController.clear();
      _contentController.clear();
      _toast('知识条目已添加');
    } catch (_) {
      _toast('添加失败，请稍后重试。');
    } finally {
      if (mounted) setState(() => _addingItem = false);
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
          onRefresh: () async {
            await _reloadRuns();
            await _loadPushRule();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: NexusLayout.pagePadding.copyWith(
              bottom: NexusLayout.bottomContentPadding,
            ),
            children: [
              NexusPageHeader(
                title: '每日知识',
                description: '每天一条新知识，晨会灵感随手取。',
              ),
              const SizedBox(height: NexusLayout.sectionGap),
              _latestCard(),
              const SizedBox(height: NexusLayout.sectionGap),
              _generateButton(),
              const SizedBox(height: NexusLayout.sectionGap),
              _pushSettingsCard(),
              const SizedBox(height: NexusLayout.sectionGap),
              _addItemCard(),
              const SizedBox(height: NexusLayout.sectionGap),
              _historyCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _latestCard() {
    final card = _latestKnowledge();
    if (card == null) {
      return NexusSurface(
        padding: const EdgeInsets.all(20),
        child: Text(
          _loadingRuns ? '正在加载…' : '还没有知识卡片，点击下方按钮生成第一张。',
        ),
      );
    }
    final topic = card['topic']?.toString() ?? '';
    final category = card['category']?.toString();
    final content = card['content']?.toString() ?? '';
    final why = card['whyItMatters']?.toString();
    final tip = card['actionTip']?.toString();
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category != null && category.isNotEmpty)
            Text(
              category,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          const SizedBox(height: 4),
          Text(topic, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(content, style: Theme.of(context).textTheme.bodyMedium),
          if (why != null && why.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('为什么有用：$why'),
          ],
          if (tip != null && tip.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '今天可以做：$tip',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic>? _latestKnowledge() {
    for (final run in _runs) {
      if (run.status != ExpertRunStatus.completed) continue;
      final result = run.result;
      if (result == null || result.isEmpty) continue;
      try {
        final decoded = jsonDecode(result);
        if (decoded is Map<String, dynamic> && decoded['topic'] != null) {
          return decoded;
        }
      } catch (_) {}
    }
    return null;
  }

  Widget _generateButton() {
    final expert = _knowledgeExpert;
    if (expert == null) {
      return NexusSurface(
        padding: const EdgeInsets.all(20),
        child: Text(
          _error ?? '未找到每日知识管家，请先应用数据库种子脚本。',
        ),
      );
    }
    return FilledButton.icon(
      onPressed: () => context.push('/ai/${expert.id}'),
      icon: const Icon(Icons.auto_awesome_rounded),
      label: const Text('去生成今日知识'),
    );
  }

  Widget _pushSettingsCard() {
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('推送设置', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (_pushRule != null)
                Text(
                  _pushRule!.enabled ? '已启用' : '已停用',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '每天定时推送一张知识卡片，时间与星期由你配置。',
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

  Widget _addItemCard() {
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('添加知识条目', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '把你看到的好内容存进知识库，管家会优先推送它。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: '分类'),
            items: const [
              DropdownMenuItem(value: 'yunhe_tcm', child: Text('芸和中医')),
              DropdownMenuItem(value: 'management', child: Text('管理方法')),
              DropdownMenuItem(value: 'general', child: Text('通用知识')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: '标题'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: '内容',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: _addingItem ? null : _addKnowledgeItem,
              child: Text(_addingItem ? '保存中…' : '保存到知识库'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard() {
    final history = _runs.where((r) => r.status == ExpertRunStatus.completed);
    return NexusSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('历史知识', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const Text('暂无历史记录。')
          else
            ...history.map(
              (run) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryTile(run: run),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.run});

  final ExpertRunDto run;

  @override
  Widget build(BuildContext context) {
    final topic = _topicOf(run.result);
    final date = run.finishedAt ?? run.createdAt;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.auto_stories_outlined,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic ?? run.resultSummary ?? '知识卡片',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _topicOf(String? result) {
    if (result == null || result.isEmpty) return null;
    try {
      final decoded = jsonDecode(result);
      if (decoded is Map<String, dynamic>) {
        return decoded['topic']?.toString();
      }
    } catch (_) {}
    return null;
  }
}
