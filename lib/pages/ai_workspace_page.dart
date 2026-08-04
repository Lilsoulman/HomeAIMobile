import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/ai/ai_repository.dart';
import '../features/skill/dto.dart';
import '../features/skill/skill_repository.dart';
import '../features/todo/dto.dart';
import '../features/todo/todo_repository.dart';

class SkillsPage extends StatefulWidget {
  const SkillsPage({super.key, required this.repository});
  final SkillRepository repository;
  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  late Future<List<SkillDto>> _skills = widget.repository.list();
  void _reload() => setState(() => _skills = widget.repository.list());

  Future<void> _edit([SkillDto? skill]) async {
    final name = TextEditingController(text: skill?.name ?? '');
    final prompt = TextEditingController(text: skill?.prompt ?? '');
    final scopes = TextEditingController(
      text: skill?.scopes ?? '["day","week"]',
    );
    final draft = await showDialog<_SkillDraft>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(skill == null ? '新建 Skill' : '编辑 Skill'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              TextField(
                controller: scopes,
                decoration: const InputDecoration(
                  labelText: '适用范围 JSON',
                  hintText: '["day", "week", "import"]',
                ),
              ),
              TextField(
                controller: prompt,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(labelText: '提示词模板'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _SkillDraft(name.text, prompt.text, scopes.text),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    name.dispose();
    prompt.dispose();
    scopes.dispose();
    if (draft == null ||
        draft.name.trim().isEmpty ||
        draft.prompt.trim().isEmpty)
      return;
    try {
      if (skill == null) {
        await widget.repository.create(
          name: draft.name.trim(),
          prompt: draft.prompt.trim(),
          scopes: draft.scopes.trim(),
        );
      } else {
        await widget.repository.update(skill.id, {
          'name': draft.name.trim(),
          'prompt': draft.prompt.trim(),
          'scopes': draft.scopes.trim(),
        });
      }
      _reload();
    } catch (error) {
      _notice('保存失败：$error');
    }
  }

  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI Skills')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _edit(),
      child: const Icon(Icons.add),
    ),
    body: FutureBuilder<List<SkillDto>>(
      future: _skills,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('加载失败：${snapshot.error}'));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final skills = snapshot.data!;
        if (skills.isEmpty)
          return const Center(child: Text('还没有 Skill，可创建日报、周报或导入模板。'));
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          itemCount: skills.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final skill = skills[index];
            return Card(
              child: ListTile(
                onTap: () => _edit(skill),
                title: Text(skill.name),
                subtitle: Text(skill.scopes),
                trailing: skill.isBuiltin
                    ? const Chip(label: Text('内置'))
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await widget.repository.delete(skill.id);
                          _reload();
                        },
                      ),
              ),
            );
          },
        );
      },
    ),
  );
}

class _SkillDraft {
  const _SkillDraft(this.name, this.prompt, this.scopes);
  final String name;
  final String prompt;
  final String scopes;
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({
    super.key,
    required this.todoRepository,
    required this.skillRepository,
    required this.aiRepository,
  });
  final TodoRepository todoRepository;
  final SkillRepository skillRepository;
  final AiRepository aiRepository;
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _week = false;
  bool _generating = false;
  String? _content;
  int? _skillId;
  late Future<List<SkillDto>> _skills = widget.skillRepository.list();

  Future<void> _generate(List<SkillDto> skills) async {
    setState(() => _generating = true);
    final now = DateTime.now();
    final from = _week
        ? now.subtract(Duration(days: now.weekday - 1))
        : DateUtils.dateOnly(now);
    final to = _week
        ? from.add(const Duration(days: 7))
        : from.add(const Duration(days: 1));
    try {
      final todos = await widget.todoRepository.list(from: from, to: to);
      final completed = todos
          .where(
            (todo) =>
                todo.status == TodoStatus.completed && todo.completedAt != null,
          )
          .toList();
      final skill = skills.where((item) => item.id == _skillId).firstOrNull;
      final prompt =
          skill?.prompt ??
          (_week ? '请生成简洁的本周工作复盘，包含成果、风险和下周行动。' : '请生成简洁的今日日报，包含完成事项、阻塞和明日行动。');
      final input = const JsonEncoder.withIndent('  ').convert({
        'period': '${from.toLocal()} - ${to.toLocal()}',
        'completedTodos': completed
            .map(
              (todo) => {
                'title': todo.title,
                'completedAt': todo.completedAt?.toIso8601String(),
              },
            )
            .toList(),
      });
      final result = await widget.aiRepository.generate(
        scope: _week ? 'week' : 'day',
        prompt: prompt,
        input: input,
      );
      if (mounted) setState(() => _content = result.content);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('生成失败：$error')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('日报与周报')),
    body: FutureBuilder<List<SkillDto>>(
      future: _skills,
      builder: (context, snapshot) {
        final skills = snapshot.data ?? const <SkillDto>[];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('日报')),
                ButtonSegment(value: true, label: Text('周报')),
              ],
              selected: {_week},
              onSelectionChanged: (value) => setState(() {
                _week = value.single;
                _content = null;
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              value: _skillId,
              decoration: const InputDecoration(
                labelText: '生成 Skill（可选）',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('使用默认模板'),
                ),
                ...skills.map(
                  (skill) => DropdownMenuItem<int?>(
                    value: skill.id,
                    child: Text(skill.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _skillId = value),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _generating || !snapshot.hasData
                  ? null
                  : () => _generate(skills),
              icon: _generating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(_generating ? '正在生成…' : '生成${_week ? '周报' : '日报'}'),
            ),
            if (_content != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(_content!),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _content!));
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Markdown 已复制到剪贴板')),
                    );
                },
                icon: const Icon(Icons.content_copy_outlined),
                label: const Text('复制 Markdown'),
              ),
            ],
          ],
        );
      },
    ),
  );
}
