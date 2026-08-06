// P4 家庭设置：家庭成员页。
// 列表 / 新建 / 编辑 / 生命周期状态。状态值域按服务端 FamilyMemberStatus：
// active（在册）、away（离开）、permanently_left（永久离开）、deceased（已故）。
// 涉及终态（permanently_left/deceased）的状态变更走受控更正流程 correctMember（必填理由）。

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/ui/nexus_theme.dart';
import '../../features/family/dto.dart';
import '../../features/family/family_repository.dart';

class FamilyMembersPage extends StatefulWidget {
  const FamilyMembersPage({super.key});

  @override
  State<FamilyMembersPage> createState() => _FamilyMembersPageState();
}

class _FamilyMembersPageState extends State<FamilyMembersPage> {
  List<FamilyMemberDto>? _members;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _error = null);
    try {
      final members = await context.read<FamilyRepository>().listMembers();
      if (!mounted) return;
      setState(() => _members = members);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  Future<void> _openForm({FamilyMemberDto? existing}) async {
    final data = await _MemberFormDialog.show(context, existing: existing);
    if (data == null || !mounted) return;
    try {
      final repository = context.read<FamilyRepository>();
      if (existing == null) {
        await repository.createMember(
          name: data.name,
          relation: data.relation,
          birthday: data.birthday,
          isElderly: data.isElderly,
          isChild: data.isChild,
          isPrimary: data.isPrimary,
          memberStatus: data.memberStatus,
        );
      } else {
        await _saveChanges(repository, existing, data);
      }
      if (!mounted) return;
      await _reload();
    } catch (error) {
      if (!mounted) return;
      _showError('保存失败：${_friendly(error)}');
    }
  }

  Future<void> _saveChanges(
    FamilyRepository repository,
    FamilyMemberDto existing,
    _MemberFormData data,
  ) async {
    final statusChanged = data.memberStatus != existing.memberStatus;
    if (statusChanged) {
      final involvesTerminal =
          _isTerminal(data.memberStatus) || _isTerminal(existing.memberStatus);
      if (involvesTerminal) {
        // 受控更正流程：服务端审计记录，理由必填。
        await repository.correctMember(
          existing.id,
          memberStatus: data.memberStatus,
          reason: data.reason?.trim(),
        );
      } else {
        await repository.updateMember(existing.id, {
          'memberStatus': data.memberStatus,
        });
      }
    }
    final patch = <String, dynamic>{};
    if (data.name != existing.name) patch['name'] = data.name;
    if (data.relation != existing.relation) patch['relation'] = data.relation;
    if (data.birthday != existing.birthday) {
      patch['birthday'] = data.birthday?.toUtc().toIso8601String();
    }
    if (data.isElderly != existing.isElderly) {
      patch['isElderly'] = data.isElderly;
    }
    if (data.isChild != existing.isChild) patch['isChild'] = data.isChild;
    if (data.isPrimary != existing.isPrimary) {
      patch['isPrimary'] = data.isPrimary;
    }
    if (patch.isNotEmpty) await repository.updateMember(existing.id, patch);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final members = _members;
    return Scaffold(
      appBar: AppBar(
        title: const Text('家庭成员'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('添加成员'),
      ),
      body: SafeArea(
        top: false,
        child: _error != null
            ? _MemberLoadError(onRetry: _reload)
            : members == null
            ? const Center(child: CircularProgressIndicator())
            : members.isEmpty
            ? _MemberEmpty(onAdd: () => _openForm())
            : RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: NexusLayout.pagePadding.copyWith(bottom: 96),
                  itemCount: members.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: NexusLayout.itemGap),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return _MemberTile(
                      member: member,
                      onTap: () => _openForm(existing: member),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onTap});

  final FamilyMemberDto member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = <String>[
      if (member.isPrimary) '主要成员',
      if (member.isElderly) '老人',
      if (member.isChild) '儿童',
    ];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NexusLayout.contentRadius),
      child: NexusSurface(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MemberStatusBadge(status: member.memberStatus),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        member.relation,
                        if (member.birthday != null)
                          _formatBirthday(member.birthday!),
                        ...tags,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberStatusBadge extends StatelessWidget {
  const _MemberStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      'active' => ('在册', const Color(0xFF2E9E6B)),
      'away' => ('离开', const Color(0xFFE0862D)),
      'permanently_left' => ('永久离开', theme.colorScheme.onSurfaceVariant),
      'deceased' => ('已故', theme.colorScheme.error),
      _ => (status, theme.colorScheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MemberLoadError extends StatelessWidget {
  const _MemberLoadError({required this.onRetry});

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
          const Text('成员列表暂时无法加载。'),
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

class _MemberEmpty extends StatelessWidget {
  const _MemberEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.group_outlined, size: 36),
        const SizedBox(height: 12),
        const Text('还没有家庭成员'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('添加成员'),
        ),
      ],
    ),
  );
}

class _MemberFormData {
  const _MemberFormData({
    required this.name,
    required this.relation,
    required this.birthday,
    required this.isElderly,
    required this.isChild,
    required this.isPrimary,
    required this.memberStatus,
    this.reason,
  });

  final String name;
  final String relation;
  final DateTime? birthday;
  final bool isElderly;
  final bool isChild;
  final bool isPrimary;
  final String memberStatus;
  final String? reason;
}

class _MemberFormDialog extends StatefulWidget {
  const _MemberFormDialog({this.existing});

  final FamilyMemberDto? existing;

  static Future<_MemberFormData?> show(
    BuildContext context, {
    FamilyMemberDto? existing,
  }) {
    return showDialog<_MemberFormData>(
      context: context,
      builder: (_) => _MemberFormDialog(existing: existing),
    );
  }

  @override
  State<_MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<_MemberFormDialog> {
  final _name = TextEditingController();
  final _relation = TextEditingController();
  final _reason = TextEditingController();

  DateTime? _birthday;
  bool _isElderly = false;
  bool _isChild = false;
  bool _isPrimary = false;
  String _memberStatus = 'active';
  bool _showReason = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _name.text = existing.name;
      _relation.text = existing.relation;
      _birthday = existing.birthday;
      _isElderly = existing.isElderly;
      _isChild = existing.isChild;
      _isPrimary = existing.isPrimary;
      _memberStatus = existing.memberStatus;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null && mounted) setState(() => _birthday = picked);
  }

  void _submit() {
    final name = _name.text.trim();
    final relation = _relation.text.trim();
    if (name.isEmpty || relation.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('姓名与关系为必填项')));
      return;
    }
    if (_showReason && _reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('变更终态状态需填写理由')));
      return;
    }
    Navigator.of(context).pop(
      _MemberFormData(
        name: name,
        relation: relation,
        birthday: _birthday,
        isElderly: _isElderly,
        isChild: _isChild,
        isPrimary: _isPrimary,
        memberStatus: _memberStatus,
        reason: _showReason ? _reason.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return AlertDialog(
      title: Text(_isEditing ? '编辑成员' : '添加成员'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '姓名'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _relation,
              decoration: const InputDecoration(
                labelText: '关系',
                hintText: '例如：父亲 / 女儿',
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake_outlined),
              title: Text(
                _birthday == null
                    ? '未设置生日'
                    : '生日：${_formatBirthday(_birthday!)}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _pickBirthday,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isElderly,
              onChanged: (value) => setState(() => _isElderly = value ?? false),
              title: const Text('老人'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isChild,
              onChanged: (value) => setState(() => _isChild = value ?? false),
              title: const Text('儿童'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isPrimary,
              onChanged: (value) => setState(() => _isPrimary = value ?? false),
              title: const Text('主要成员'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _memberStatus,
              decoration: const InputDecoration(labelText: '状态'),
              items: [
                for (final (value, label) in const [
                  ('active', '在册'),
                  ('away', '离开'),
                  ('permanently_left', '永久离开'),
                  ('deceased', '已故'),
                ])
                  DropdownMenuItem(value: value, child: Text(label)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _memberStatus = value;
                  final involvesTerminal =
                      _isTerminal(value) ||
                      (existing != null && _isTerminal(existing.memberStatus));
                  _showReason =
                      value != existing?.memberStatus && involvesTerminal;
                });
              },
            ),
            if (_showReason) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _reason,
                decoration: const InputDecoration(
                  labelText: '更正理由（必填）',
                  hintText: '说明状态变更原因，将记入审计',
                ),
              ),
            ],
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

bool _isTerminal(String status) =>
    status == 'permanently_left' || status == 'deceased';

String _formatBirthday(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _friendly(Object error) =>
    error is ApiException && error.msg.isNotEmpty ? error.msg : '$error';
