// P5b 个人偏好收藏页：分类列表 / 新建 / 编辑 / 软删除（二次确认）/ 对话导入。
// private 项仅归属成员本人可见（服务端按 JWT 过滤，UI 展示"仅本人可见"语义）；
// 破坏性删除必须二次确认；导入的 Source 留痕入审计。

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/ui/nexus_theme.dart';
import '../../features/favorite/dto.dart';
import '../../features/favorite/favorite_repository.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<FavoriteDto>? _items;
  String? _error;
  String? _category;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _error = null);
    try {
      final items = await context.read<FavoriteRepository>().list();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  List<FavoriteDto> get _filtered =>
      _items
          ?.where(
            (item) => _category == null || item.category.apiValue == _category,
          )
          .toList() ??
      const [];

  Future<void> _openForm({FavoriteDto? existing}) async {
    final data = await _FavoriteFormDialog.show(context, existing: existing);
    if (data == null || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final repo = context.read<FavoriteRepository>();
      if (existing == null) {
        await repo.create(
          category: data.category,
          name: data.name,
          detailJson: data.detailJson,
          visibility: data.visibility,
        );
      } else {
        await repo.update(
          existing.id,
          category: data.category,
          name: data.name,
          detailJson: data.detailJson,
          visibility: data.visibility,
        );
      }
      if (!mounted) return;
      await _reload();
    } catch (error) {
      if (!mounted) return;
      _showError('保存失败：${_friendly(error)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openImport() async {
    final data = await _ImportDialog.show(context);
    if (data == null || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      await context.read<FavoriteRepository>().import(
        category: data.category,
        name: data.name,
        detailJson: data.detailJson,
        visibility: data.visibility,
        source: data.source,
        conversationText: data.conversationText,
      );
      if (!mounted) return;
      await _reload();
    } catch (error) {
      if (!mounted) return;
      _showError('导入失败：${_friendly(error)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(FavoriteDto item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除收藏'),
        content: Text('确定删除「${item.name}」吗？此操作不可恢复。'),
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
      await context.read<FavoriteRepository>().delete(item.id);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        actions: [
          IconButton(
            tooltip: '导入',
            onPressed: _busy ? null : _openImport,
            icon: const Icon(Icons.file_download_outlined),
          ),
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
        label: const Text('新建收藏'),
      ),
      body: SafeArea(
        top: false,
        child: _error != null
            ? _FavoritesLoadError(onRetry: _reload)
            : _items == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        for (final entry in const [
                          (null, '全部'),
                          ('restaurant', '餐厅'),
                          ('travel', '旅行'),
                          ('material', '素材'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(entry.$2),
                              selected: _category == entry.$1,
                              onSelected: (_) =>
                                  setState(() => _category = entry.$1),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _filtered.isEmpty
                        ? const _FavoritesEmpty()
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
                                return _FavoriteTile(
                                  item: item,
                                  summary: _detailSummary(item),
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

  String? _detailSummary(FavoriteDto item) {
    final json = item.detailJson;
    if (json == null || json.isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map) {
        final parts = decoded.entries
            .map((entry) => '${entry.key}: ${_plain(entry.value)}')
            .toList();
        return parts.join(' · ');
      }
      return json;
    } catch (_) {
      return json;
    }
  }

  String _plain(Object? value) {
    if (value is List) return value.map((item) => '$item').join('、');
    return value?.toString() ?? '';
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.item,
    required this.summary,
    required this.onTap,
    required this.onDelete,
  });

  final FavoriteDto item;
  final String? summary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      item.category.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.visibility == FavoriteVisibility.private
                          ? '仅本人可见'
                          : '家庭共享',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: '删除',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              if (summary != null && summary!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  summary!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritesLoadError extends StatelessWidget {
  const _FavoritesLoadError({required this.onRetry});

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
          const Text('收藏暂时无法加载。'),
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

class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text('还没有收藏，点击右下角新建，或从对话导入。'),
    ),
  );
}

class _FavoriteFormData {
  const _FavoriteFormData({
    required this.category,
    required this.name,
    required this.detailJson,
    required this.visibility,
  });

  final FavoriteCategory category;
  final String name;
  final String? detailJson;
  final FavoriteVisibility visibility;
}

class _FavoriteFormDialog extends StatefulWidget {
  const _FavoriteFormDialog({this.existing});

  final FavoriteDto? existing;

  static Future<_FavoriteFormData?> show(
    BuildContext context, {
    FavoriteDto? existing,
  }) {
    return showDialog<_FavoriteFormData>(
      context: context,
      builder: (_) => _FavoriteFormDialog(existing: existing),
    );
  }

  @override
  State<_FavoriteFormDialog> createState() => _FavoriteFormDialogState();
}

class _FavoriteFormDialogState extends State<_FavoriteFormDialog> {
  late FavoriteCategory _category;
  late FavoriteVisibility _visibility;
  final _name = TextEditingController();
  final _detail = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _category = existing?.category ?? FavoriteCategory.restaurant;
    _visibility = existing?.visibility ?? FavoriteVisibility.private;
    _name.text = existing?.name ?? '';
    _detail.text = existing?.detailJson ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _detail.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名称为必填项')));
      return;
    }
    final detail = _detail.text.trim();
    if (detail.isNotEmpty) {
      try {
        jsonDecode(detail);
      } catch (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('详情必须是合法 JSON 或留空')));
        return;
      }
    }
    Navigator.of(context).pop(
      _FavoriteFormData(
        category: _category,
        name: name,
        detailJson: detail.isEmpty ? null : detail,
        visibility: _visibility,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? '新建收藏' : '编辑收藏'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<FavoriteCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: '分类'),
              items: [
                for (final category in FavoriteCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _detail,
              decoration: const InputDecoration(
                labelText: '详情（可选）',
                hintText: 'JSON，例如 {"cuisine":"面食","address":"城西"}',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<FavoriteVisibility>(
              initialValue: _visibility,
              decoration: const InputDecoration(labelText: '可见性'),
              items: [
                for (final visibility in FavoriteVisibility.values)
                  DropdownMenuItem(
                    value: visibility,
                    child: Text(visibility.label),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _visibility = value);
              },
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

class _ImportData {
  const _ImportData({
    required this.category,
    required this.name,
    required this.detailJson,
    required this.visibility,
    required this.source,
    this.conversationText,
  });

  final FavoriteCategory category;
  final String name;
  final String? detailJson;
  final FavoriteVisibility visibility;
  final String source;
  final String? conversationText;
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  static Future<_ImportData?> show(BuildContext context) {
    return showDialog<_ImportData>(
      context: context,
      builder: (_) => const _ImportDialog(),
    );
  }

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  FavoriteCategory _category = FavoriteCategory.restaurant;
  FavoriteVisibility _visibility = FavoriteVisibility.private;
  final _name = TextEditingController();
  final _source = TextEditingController();
  final _conversation = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _source.dispose();
    _conversation.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final source = _source.text.trim();
    if (name.isEmpty || source.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名称与来源均为必填项')));
      return;
    }
    final conversation = _conversation.text.trim();
    Navigator.of(context).pop(
      _ImportData(
        category: _category,
        name: name,
        detailJson: null,
        visibility: _visibility,
        source: source,
        conversationText: conversation.isEmpty ? null : conversation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('从对话导入收藏'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '来源将留痕到审计记录；私密收藏仅你本人可见。',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<FavoriteCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: '分类'),
              items: [
                for (final category in FavoriteCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _source,
              decoration: const InputDecoration(
                labelText: '来源（必填）',
                hintText: '例如：小红书 / 对话',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _conversation,
              decoration: const InputDecoration(
                labelText: '对话原文（可选）',
                hintText: '粘贴想要提取的对话内容',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<FavoriteVisibility>(
              initialValue: _visibility,
              decoration: const InputDecoration(labelText: '可见性'),
              items: [
                for (final visibility in FavoriteVisibility.values)
                  DropdownMenuItem(
                    value: visibility,
                    child: Text(visibility.label),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _visibility = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('导入')),
      ],
    );
  }
}

String _friendly(Object error) =>
    error is ApiException && error.msg.isNotEmpty ? error.msg : '$error';
