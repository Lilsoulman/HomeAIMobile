// P4 家庭设置：家庭知识库页。
// 列表 / 分类筛选 / 本地搜索 / 新建与编辑（writeKnowledge，同 key 重写产生新版本并解决冲突）/
// 删除（二次确认）。AI 来源条目展示来源与置信度；写失败展示无权限/错误。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/ui/nexus_theme.dart';
import '../../features/family/dto.dart';
import '../../features/family/family_repository.dart';

class FamilyKnowledgePage extends StatefulWidget {
  const FamilyKnowledgePage({super.key});

  @override
  State<FamilyKnowledgePage> createState() => _FamilyKnowledgePageState();
}

class _FamilyKnowledgePageState extends State<FamilyKnowledgePage> {
  List<FamilyKnowledgeDto>? _items;
  String? _error;
  String? _category;
  String _query = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _error = null);
    try {
      final items = await context.read<FamilyRepository>().listKnowledge();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  List<FamilyKnowledgeDto> get _filtered {
    final items =
        _items
            ?.where((item) => _category == null || item.category == _category)
            .toList() ??
        const [];
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.key.toLowerCase().contains(query) ||
              item.value.toLowerCase().contains(query) ||
              (item.notes?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  Future<void> _openForm({FamilyKnowledgeDto? existing}) async {
    final data = await _KnowledgeFormDialog.show(context, existing: existing);
    if (data == null || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      await context.read<FamilyRepository>().writeKnowledge(
        category: data.category,
        key: data.key,
        value: data.value,
        notes: data.notes,
        sourceType: 'manual',
      );
      if (!mounted) return;
      await _reload();
    } catch (error) {
      if (!mounted) return;
      _showError('保存失败：${_friendly(error)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(FamilyKnowledgeDto item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除知识'),
        content: Text('确定删除「${item.key}」吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      await context.read<FamilyRepository>().deleteKnowledge(item.id);
      if (!mounted) return;
      await _reload();
    } catch (error) {
      if (!mounted) return;
      _showError('删除失败：${_friendly(error)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>{
      for (final item in _items ?? const <FamilyKnowledgeDto>[]) item.category,
    }.toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: const Text('家庭知识'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : () => _openForm(),
        icon: const Icon(Icons.add_outlined),
        label: const Text('添加知识'),
      ),
      body: SafeArea(
        top: false,
        child: _error != null
            ? _KnowledgeLoadError(onRetry: _reload)
            : _items == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: NexusLayout.pagePadding,
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: '搜索知识',
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  if (categories.isNotEmpty)
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        // 只保留水平 padding，垂直留给 48 高的分类行。
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('全部'),
                              selected: _category == null,
                              onSelected: (_) =>
                                  setState(() => _category = null),
                            ),
                          ),
                          for (final category in categories)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: _category == category,
                                onSelected: (_) =>
                                    setState(() => _category = category),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _filtered.isEmpty
                        ? const _KnowledgeEmpty()
                        : RefreshIndicator(
                            onRefresh: _reload,
                            child: ListView.separated(
                              padding: NexusLayout.pagePadding.copyWith(
                                bottom: 96,
                              ),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: NexusLayout.itemGap),
                              itemBuilder: (context, index) {
                                final item = _filtered[index];
                                return _KnowledgeTile(
                                  item: item,
                                  onTap: () => _openForm(existing: item),
                                  onDelete: () => _confirmDelete(item),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _KnowledgeTile extends StatelessWidget {
  const _KnowledgeTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final FamilyKnowledgeDto item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAi = item.sourceType == 'ai';
    final pendingConfidence = item.confidenceScore < 1.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
      child: NexusSurface(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.key,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (isAi || pendingConfidence) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0862D).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isAi ? 'AI 提取' : '待确认',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE0862D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    tooltip: '删除',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(item.value, style: theme.textTheme.bodyMedium),
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (item.resolutionSummary != null &&
                  item.resolutionSummary!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.merge_type_rounded,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '冲突解决：${item.resolutionSummary}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KnowledgeLoadError extends StatelessWidget {
  const _KnowledgeLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: NexusLayout.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36),
          const SizedBox(height: 12),
          const Text('家庭知识暂时无法加载。'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        ],
      ),
    ),
  );
}

class _KnowledgeEmpty extends StatelessWidget {
  const _KnowledgeEmpty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text('还没有家庭知识，点击右下角添加。'),
    ),
  );
}

class _KnowledgeFormData {
  const _KnowledgeFormData({
    required this.category,
    required this.key,
    required this.value,
    this.notes,
  });

  final String category;
  final String key;
  final String value;
  final String? notes;
}

class _KnowledgeFormDialog extends StatefulWidget {
  const _KnowledgeFormDialog({this.existing});

  final FamilyKnowledgeDto? existing;

  static Future<_KnowledgeFormData?> show(
    BuildContext context, {
    FamilyKnowledgeDto? existing,
  }) {
    return showDialog<_KnowledgeFormData>(
      context: context,
      builder: (_) => _KnowledgeFormDialog(existing: existing),
    );
  }

  @override
  State<_KnowledgeFormDialog> createState() => _KnowledgeFormDialogState();
}

class _KnowledgeFormDialogState extends State<_KnowledgeFormDialog> {
  final _category = TextEditingController();
  final _key = TextEditingController();
  final _value = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _category.text = existing.category;
      _key.text = existing.key;
      _value.text = existing.value;
      _notes.text = existing.notes ?? '';
    }
  }

  @override
  void dispose() {
    _category.dispose();
    _key.dispose();
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    final category = _category.text.trim();
    final key = _key.text.trim();
    final value = _value.text.trim();
    if (category.isEmpty || key.isEmpty || value.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分类、键与值均为必填项')));
      return;
    }
    final notes = _notes.text.trim();
    Navigator.of(context).pop(
      _KnowledgeFormData(
        category: category,
        key: key,
        value: value,
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? '添加知识' : '编辑知识'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _category,
              decoration: const InputDecoration(
                labelText: '分类',
                hintText: '例如：生活 / 健康 / 安全',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _key,
              decoration: const InputDecoration(
                labelText: '键',
                hintText: '例如：睡眠习惯',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _value,
              decoration: const InputDecoration(labelText: '值'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: '备注（可选）'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}

String _friendly(Object error) =>
    error is ApiException && error.msg.isNotEmpty ? error.msg : '$error';
