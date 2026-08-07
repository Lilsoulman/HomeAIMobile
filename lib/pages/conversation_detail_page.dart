// B20 会话聊天页：消息流 + 发送（幂等键）→ 轮询 ExpertRun 七态 → 终态刷新消息
// （assistant 摘要由服务端自动追加；客户端不缓存会话上下文、不渲染 prompt/思考链）。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../features/conversation/conversation_repository.dart';
import '../features/conversation/dto.dart';
import '../features/expert/expert_run_repository.dart';

class ConversationDetailPage extends StatefulWidget {
  const ConversationDetailPage({
    super.key,
    required this.conversationId,
    this.title,
  });

  final int conversationId;
  final String? title;

  @override
  State<ConversationDetailPage> createState() => _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<ConversationDetailPage> {
  // 消息列表，最新在前（reverse ListView 底部保持最新）。
  final List<ConversationMessageDto> _messages = [];
  String? _cursor;
  bool _loading = false;
  bool _loadingHistory = false;
  String? _error;

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;
  Timer? _poller;
  String? _runStatus;
  String? _runError;

  ConversationRepository get _repository =>
      context.read<ConversationRepository>();

  ExpertRunRepository get _runRepository => context.read<ExpertRunRepository>();

  @override
  void initState() {
    super.initState();
    _reload();
    _scroll.addListener(_maybeLoadHistory);
  }

  @override
  void dispose() {
    _poller?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repository.listMessages(
        conversationId: widget.conversationId,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(page.items);
        _cursor = page.cursor;
        _loading = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  void _maybeLoadHistory() {
    if (_cursor == null ||
        _loadingHistory ||
        !_scroll.hasClients ||
        _scroll.position.pixels > 200) {
      return;
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final page = await _repository.listMessages(
        conversationId: widget.conversationId,
        limit: 20,
        cursor: _cursor,
      );
      if (!mounted) return;
      final previousLength = _messages.length;
      setState(() {
        _messages.addAll(page.items);
        _cursor = page.cursor;
        _loadingHistory = false;
      });
      // 追加旧消息后保持视口位置不变。
      if (_scroll.hasClients && page.items.isNotEmpty) {
        final offset = _scroll.position.maxScrollExtent;
        _scroll.jumpTo(offset - page.items.length * 72.0);
      }
      if (previousLength == 0 && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _send() async {
    final content = _input.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _runStatus = null;
      _runError = null;
    });
    try {
      final result = await _repository.sendMessage(
        conversationId: widget.conversationId,
        content: content,
        idempotencyKey: const Uuid().v4(),
      );
      if (!mounted) return;
      _input.clear();
      setState(() => _runStatus = '排队中');
      await _refreshMessages();
      _beginPolling(result.runId);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _runError = '$error';
      });
      _showMessage('发送失败：$error');
    }
  }

  void _beginPolling(int runId) {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 2), (_) {
      _refreshRun(runId);
    });
  }

  Future<void> _refreshRun(int runId) async {
    try {
      final run = await _runRepository.get(runId);
      if (!mounted) return;
      setState(() {
        _runStatus = run.status.label;
        _sending = !run.status.isTerminal;
      });
      if (run.status.isTerminal) {
        _poller?.cancel();
        await _refreshMessages();
        if (!mounted) return;
        setState(() => _sending = false);
      }
    } catch (error) {
      if (!mounted) return;
      _poller?.cancel();
      setState(() {
        _runError = '$error';
        _sending = false;
      });
    }
  }

  Future<void> _refreshMessages() async {
    final page = await _repository.listMessages(
      conversationId: widget.conversationId,
      limit: 20,
    );
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(page.items);
      _cursor = page.cursor;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? '专家会话'),
        actions: [
          if (_runError != null)
            IconButton(
              tooltip: '会话出错，请重试',
              icon: const Icon(Icons.error_outline),
              onPressed: _reload,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [_buildBody(), _buildComposer()]),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _messages.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 36),
              const SizedBox(height: 12),
              const Text('消息暂时无法加载。'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Expanded(child: Center(child: Text('还没有消息，发送第一条消息开始对话。')));
    }
    return Expanded(
      child: ListView.builder(
        controller: _scroll,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _messages.length + (_cursor != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _messages.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _MessageBubble(message: _messages[index]);
        },
      ),
    );
  }

  Widget _buildComposer() {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_runStatus != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('专家处理中：$_runStatus')),
              ],
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: !_sending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: '输入消息…',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: '发送',
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ConversationMessageDto message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ConversationMessageRole.user;
    final time = message.createdAt.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    final timeText = '${two(time.hour)}:${two(time.minute)}';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content.isEmpty ? '（空消息）' : message.content,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(
              timeText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
