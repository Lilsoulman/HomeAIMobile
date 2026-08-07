// B21 我的专家页：scope=mine 列表（loading/empty/error/retry）+ 新建/编辑表单
// （同页切换状态）+ 删除二次确认。自建/维护仅创建者本人可见可维护。

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ui/nexus_theme.dart';
import '../experts/domain.dart';
import '../experts/expert_repository.dart';

class MyExpertsPage extends StatefulWidget {
  const MyExpertsPage({super.key});

  @override
  State<MyExpertsPage> createState() => _MyExpertsPageState();
}

class _MyExpertsPageState extends State<MyExpertsPage> {
  final List<Expert> _items = [];
  bool _loading = false;
  String? _error;

  // 表单状态：_editing == null 时显示列表；否则显示表单（null = 新建）。
  ExpertDetail? _editing;
  bool _form = false;

  ExpertRepository get _repository => context.read<ExpertRepository>();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final experts = await _repository.listExperts(scope: 'mine');
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(experts);
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

  void _openCreate() {
    setState(() {
      _editing = null;
      _form = true;
    });
  }

  Future<void> _openEdit(Expert expert) async {
    try {
      final detail = await _repository.getExpertDetail(
        expert.id,
        sourceType: ExpertSourceType.expert,
      );
      if (!mounted) return;
      if (detail == null) {
        _showMessage('专家不存在或已删除');
        return;
      }
      setState(() {
        _editing = detail;
        _form = true;
      });
    } catch (error) {
      if (mounted) _showMessage('加载专家详情失败：$error');
    }
  }

  Future<void> _deleteExpert(Expert expert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除专家'),
        content: Text('确定删除「${expert.name}」吗？删除后该专家将从目录、运行创建与会话发送中消失。'),
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
      await _repository.deleteExpert(expert.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((item) => item.id == expert.id));
    } catch (error) {
      if (mounted) _showMessage('删除失败：$error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的专家')),
      body: SafeArea(top: false, child: _form ? _buildForm() : _buildList()),
      floatingActionButton: _form
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('新建专家'),
            ),
    );
  }

  Widget _buildList() {
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
            const Text('自建专家暂时无法加载。'),
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
      return const Center(child: Text('还没有自建专家，点击「新建专家」创建。'));
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: NexusLayout.pagePadding.copyWith(bottom: 36),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final expert = _items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: NexusLayout.itemGap),
            child: NexusSurface(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(expert.name),
                  subtitle: Text(expert.category),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '编辑',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openEdit(expert),
                      ),
                      IconButton(
                        tooltip: '删除',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteExpert(expert),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm() {
    return _ExpertForm(
      key: ValueKey(_editing?.id ?? 'new'),
      initial: _editing,
      onCancel: () => setState(() => _form = false),
      onSaved: (expert) {
        setState(() {
          _form = false;
          final index = _items.indexWhere((item) => item.id == expert.id);
          if (index >= 0) {
            _items[index] = expert;
          } else {
            _items.insert(0, expert);
          }
        });
      },
    );
  }
}

class _ExpertForm extends StatefulWidget {
  const _ExpertForm({
    super.key,
    this.initial,
    required this.onCancel,
    required this.onSaved,
  });

  final ExpertDetail? initial;
  final VoidCallback onCancel;
  final ValueChanged<Expert> onSaved;

  @override
  State<_ExpertForm> createState() => _ExpertFormState();
}

class _ExpertFormState extends State<_ExpertForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _persona;
  late final TextEditingController _methodology;
  late final TextEditingController _promptTemplate;
  late final TextEditingController _toolPolicy;
  late final TextEditingController _estimatedCredits;
  int? _rowVersion;
  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final expert = widget.initial;
    _name = TextEditingController(text: expert?.name ?? '');
    _category = TextEditingController(text: expert?.category ?? '');
    _description = TextEditingController(text: expert?.description ?? '');
    _persona = TextEditingController(text: expert?.persona ?? '');
    _methodology = TextEditingController(text: expert?.methodology ?? '');
    _promptTemplate = TextEditingController(text: expert?.promptTemplate ?? '');
    _toolPolicy = TextEditingController(
      text: expert?.toolPolicy ?? '{"skills":[]}',
    );
    _estimatedCredits = TextEditingController(
      text: (expert?.estimatedCredits ?? 1).toString(),
    );
    _rowVersion = expert?.rowVersion;
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _description.dispose();
    _persona.dispose();
    _methodology.dispose();
    _promptTemplate.dispose();
    _toolPolicy.dispose();
    _estimatedCredits.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    var toolPolicy = _toolPolicy.text.trim();
    if (toolPolicy.isEmpty) toolPolicy = '{"skills":[]}';
    try {
      // 非法 JSON 本地校验（服务端同样 422）。
      jsonDecode(toolPolicy);
    } catch (_) {
      _showMessage('工具策略必须是合法 JSON');
      return;
    }
    setState(() => _saving = true);
    final repository = context.read<ExpertRepository>();
    final credits = int.tryParse(_estimatedCredits.text.trim()) ?? 1;
    try {
      final expert = _isEditing
          ? await repository.updateExpert(
              id: widget.initial!.id,
              rowVersion: _rowVersion ?? 0,
              name: _name.text.trim(),
              category: _category.text.trim(),
              description: _description.text.trim(),
              persona: _persona.text.trim(),
              methodology: _methodology.text.trim(),
              promptTemplate: _promptTemplate.text.trim(),
              toolPolicyJson: toolPolicy,
              estimatedCredits: credits,
            )
          : await repository.createExpert(
              name: _name.text.trim(),
              category: _category.text.trim(),
              description: _description.text.trim(),
              persona: _persona.text.trim(),
              methodology: _methodology.text.trim(),
              promptTemplate: _promptTemplate.text.trim(),
              toolPolicyJson: toolPolicy,
              estimatedCredits: credits,
            );
      if (!mounted) return;
      widget.onSaved(expert);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('保存失败（内容可能已更新，请返回后重试）：$error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: NexusLayout.pagePadding.copyWith(bottom: 36),
        children: [
          Text(
            _isEditing ? '编辑专家' : '新建专家',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: '名称',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? '请填写名称' : null,
          ),
          const SizedBox(height: NexusLayout.itemGap),
          TextFormField(
            controller: _category,
            decoration: const InputDecoration(
              labelText: '分类',
              hintText: '例如 travel / writing / research',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? '请填写分类' : null,
          ),
          const SizedBox(height: NexusLayout.itemGap),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(
              labelText: '描述（可选）',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: NexusLayout.itemGap),
          TextFormField(
            controller: _persona,
            decoration: const InputDecoration(
              labelText: '人格设定',
              hintText: '例如：你是我的旅行助手…',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? '请填写人格设定' : null,
          ),
          const SizedBox(height: NexusLayout.itemGap),
          TextFormField(
            controller: _methodology,
            decoration: const InputDecoration(
              labelText: '方法论（可选）',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: NexusLayout.itemGap),
          TextFormField(
            controller: _promptTemplate,
            decoration: const InputDecoration(
              labelText: '提示词模板',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? '请填写提示词模板' : null,
          ),
          const SizedBox(height: NexusLayout.itemGap),
          TextFormField(
            controller: _toolPolicy,
            decoration: const InputDecoration(
              labelText: '工具策略（JSON）',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: NexusLayout.itemGap),
          TextFormField(
            controller: _estimatedCredits,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '预估消耗（积分）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : widget.onCancel,
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? '保存中…' : '保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
