// B20 专家会话列表页：游标分页 + 新建/重命名/软删（loading/empty/error/retry）。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/ui/nexus_theme.dart';
import '../experts/domain.dart';
import '../experts/expert_repository.dart';
import '../features/conversation/conversation_repository.dart';
import '../features/conversation/dto.dart';
import 'expert_picker_dialog.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final List<ConversationDto> _items = [];
  String? _cursor;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  final ScrollController _scroll = ScrollController();

  ConversationRepository get _repository =>
      context.read<ConversationRepository>();

  @override
  void initState() {
    super.initState();
    _reload();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.removeListener(_maybeLoadMore);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repository.listConversations(limit: 20);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _cursor = page.cursor;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  void _maybeLoadMore() {
    if (_cursor == null ||
        _loadingMore ||
        !_scroll.hasClients ||
        _scroll.position.extentAfter > 200) {
      return;
    }
    _loadMore();
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final page = await _repository.listConversations(
        limit: 20,
        cursor: _cursor,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _cursor = page.cursor;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _createConversation() async {
    final expert = await showDialog<Expert?>(
      context: context,
      builder: (_) =>
          ExpertPickerDialog(repository: context.read<ExpertRepository>()),
    );
    if (!mounted) return;
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新建会话'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: expert == null ? '会话标题' : '会话标题（可选）',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (!mounted || title == null) return;
    try {
      final conversation = await _repository.createConversation(
        title: title,
        expertId: expert == null ? null : int.tryParse(expert.id),
      );
      if (!mounted) return;
      _openConversation(conversation);
    } catch (error) {
      if (mounted) _showMessage('新建失败：$error');
    }
  }

  Future<void> _renameConversation(ConversationDto conversation) async {
    final controller = TextEditingController(text: conversation.title);
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重命名会话'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '会话标题'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (!mounted || title == null || title.isEmpty) return;
    try {
      await _repository.updateConversation(
        id: conversation.id,
        title: title,
        rowVersion: conversation.rowVersion,
      );
      await _reload();
    } catch (error) {
      if (mounted) _showMessage('重命名失败（内容可能已更新，请刷新重试）：$error');
    }
  }

  Future<void> _deleteConversation(ConversationDto conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确定删除「${conversation.title}」吗？消息历史将保留留档。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repository.deleteConversation(conversation.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((item) => item.id == conversation.id));
    } catch (error) {
      if (mounted) _showMessage('删除失败：$error');
    }
  }

  void _openConversation(ConversationDto conversation) {
    context.push(
      '/ai/conversations/${conversation.id}?title=${Uri.encodeComponent(conversation.title)}',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('专家会话')),
      body: SafeArea(top: false, child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createConversation,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('新建会话'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 36),
            const SizedBox(height: 12),
            const Text('会话暂时无法加载。'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('还没有专家会话。'));
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: NexusLayout.pagePadding.copyWith(bottom: 36),
        itemCount: _items.length + (_cursor != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final conversation = _items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: NexusLayout.itemGap),
            child: NexusSurface(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    conversation.title.isEmpty ? '未命名会话' : conversation.title,
                  ),
                  subtitle: Text(_formatTime(conversation.updatedAt)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '重命名',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _renameConversation(conversation),
                      ),
                      IconButton(
                        tooltip: '删除',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteConversation(conversation),
                      ),
                    ],
                  ),
                  onTap: () => _openConversation(conversation),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
