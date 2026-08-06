// P3 管家工作台与确认中心：共享确认组件。
// L1 项可批量确认（携带新幂等键）；L2/L3 逐项确认/拒绝；
// 失败重试复用同一幂等键（重入恢复），成功后新操作生成新键；
// 批量确认返回部分成功时按结果逐项更新（局部失败）。

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/ui/nexus_theme.dart';
import '../features/steward/dto.dart';
import '../features/steward/steward_repository.dart';

const _uuid = Uuid();

class ConfirmationSection extends StatefulWidget {
  const ConfirmationSection({
    super.key,
    required this.repository,
    this.riskLevel,
  });

  final StewardRepository repository;

  /// 可选风险等级过滤（L1/L2/L3），透传给服务端查询。
  final String? riskLevel;

  @override
  State<ConfirmationSection> createState() => _ConfirmationSectionState();
}

class _ConfirmationSectionState extends State<ConfirmationSection> {
  List<ConfirmationItemDto>? _items;
  String? _error;
  bool _busy = false;

  // 当前操作的幂等键与签名；失败时保留以便重试复用，成功或换操作后重置。
  String? _operationSignature;
  String? _idempotencyKey;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _error = null);
    try {
      final items = await widget.repository.listConfirmations(
        riskLevel: widget.riskLevel,
      );
      if (!mounted) return;
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  List<ConfirmationItemDto> get _pending =>
      _items?.where((item) => item.status == 'pending').toList() ?? const [];

  List<ConfirmationItemDto> get _l1Pending =>
      _pending.where((item) => item.riskLevel == 'L1').toList();

  String _keyFor(String signature) {
    if (_operationSignature != signature) {
      _operationSignature = signature;
      _idempotencyKey = _uuid.v4();
    }
    return _idempotencyKey!;
  }

  void _finishOperation() {
    _operationSignature = null;
    _idempotencyKey = null;
  }

  void _applyItems(List<ConfirmationItemDto> updated) {
    final byId = {for (final item in updated) item.id: item};
    setState(() {
      _items = (_items ?? const [])
          .map((item) => byId[item.id] ?? item)
          .toList();
    });
  }

  Future<void> _batchConfirm() async {
    final ids = _l1Pending.map((item) => item.id).toList();
    if (ids.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.repository.batchConfirm(
        ids,
        idempotencyKey: _keyFor('batch'),
      );
      if (!mounted) return;
      _applyItems(result.items);
      _finishOperation();
    } catch (_) {
      // 失败保留幂等键，重试复用（重入恢复）。
      if (!mounted) return;
      _showMessage('确认失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmOne(ConfirmationItemDto item) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await widget.repository.confirm(
        item.id,
        idempotencyKey: _keyFor('confirm-${item.id}'),
      );
      if (!mounted) return;
      _applyItems([updated]);
      _finishOperation();
    } catch (_) {
      if (!mounted) return;
      _showMessage('确认失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _denyOne(ConfirmationItemDto item) async {
    final reason = await _askReason(item.title);
    if (reason == null || reason.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final updated = await widget.repository.deny(
        item.id,
        reason: reason.trim(),
      );
      if (!mounted) return;
      _applyItems([updated]);
    } catch (_) {
      if (!mounted) return;
      _showMessage('拒绝失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason(String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('拒绝：$title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '原因',
            hintText: '说明拒绝原因',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('确认拒绝'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(title: '待确认', action: '重试', onAction: _reload),
          const SizedBox(height: 12),
          _MessageCard(
            icon: Icons.cloud_off_outlined,
            message: '确认中心暂时无法加载',
            onRetry: _reload,
          ),
        ],
      );
    }
    if (_items == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(title: '待确认'),
          SizedBox(height: 12),
          _LoadingCard(),
        ],
      );
    }
    final pending = _pending;
    if (pending.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(title: '待确认', action: '刷新', onAction: _reload),
          const SizedBox(height: 12),
          const _MessageCard(icon: Icons.inbox_outlined, message: '没有待确认的事项'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(title: '待确认', action: '刷新', onAction: _reload),
        const SizedBox(height: 12),
        if (_l1Pending.length > 1) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _busy ? null : _batchConfirm,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all_outlined),
              label: Text('全部确认（${_l1Pending.length}）'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...pending.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ConfirmationTile(
              item: item,
              busy: _busy,
              onConfirm: () => _confirmOne(item),
              onDeny: () => _denyOne(item),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class _ConfirmationTile extends StatelessWidget {
  const _ConfirmationTile({
    required this.item,
    required this.busy,
    required this.onConfirm,
    required this.onDeny,
  });

  final ConfirmationItemDto item;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = item.status != 'pending';
    return NexusSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RiskBadge(level: item.riskLevel),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (item.impactSummary != null) ...[
            const SizedBox(height: 8),
            Text(
              item.impactSummary!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.update_rounded,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                _formatTime(item.updatedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (resolved)
                Text(
                  _resolvedLabel(item.status),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else if (item.riskLevel == 'L1') ...[
                TextButton(
                  onPressed: busy ? null : onConfirm,
                  child: const Text('确认'),
                ),
                TextButton(
                  onPressed: busy ? null : onDeny,
                  child: const Text('拒绝'),
                ),
              ] else ...[
                SizedBox(
                  width: 76,
                  child: FilledButton.tonal(
                    onPressed: busy ? null : onConfirm,
                    child: const Text('确认'),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 76,
                  child: OutlinedButton(
                    onPressed: busy ? null : onDeny,
                    child: const Text('拒绝'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _resolvedLabel(String status) => switch (status) {
    'confirmed' => '已确认',
    'denied' => '已拒绝',
    'expired' => '已过期',
    _ => status,
  };
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      'L1' => const Color(0xFF2E9E6B),
      'L2' => const Color(0xFFE0862D),
      'L3' => Theme.of(context).colorScheme.error,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message, this.onRetry});

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => NexusSurface(
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
        if (onRetry != null)
          IconButton(
            tooltip: '重试',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
      ],
    ),
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const NexusSurface(
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(),
      ),
    ),
  );
}

String _formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
